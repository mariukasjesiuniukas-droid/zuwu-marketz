-- ZUWU V5 checkout + Discord ticket mapping
-- Run ONLY in STAGING, after setup.sql, upgrade-cart-promotions.sql and v4-inventory-discord.sql.

alter table public.orders add column if not exists payment_method text not null default 'paypal'
  check (payment_method in ('paypal','card'));

-- Keep the V4 RPC intact; V5 uses a separate RPC to avoid breaking the live checkout.
create or replace function public.zuwu_submit_cart_v5(
  p_items jsonb,
  p_buyer_note text default '',
  p_payment_method text default 'paypal'
) returns jsonb
language plpgsql security definer set search_path=public as $$
declare
 item jsonb; v_listing_id uuid; v_qty integer; v_seller uuid; v_price numeric(10,2);
 v_status text; v_stock integer; v_discount numeric(10,2):=0; v_unit numeric(10,2);
 v_order_id uuid; v_ids jsonb:='[]'::jsonb; v_promo public.zuwu_promotions%rowtype; v_now timestamptz:=now();
begin
 if auth.uid() is null then raise exception 'Prisijunkite, kad pateiktumėte užsakymą.'; end if;
 if p_payment_method not in ('paypal','card') then raise exception 'Neteisingas mokėjimo būdas.'; end if;
 if jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)<1 or jsonb_array_length(p_items)>25 then raise exception 'Krepšelyje turi būti nuo 1 iki 25 skirtingų prekių.'; end if;
 if char_length(coalesce(p_buyer_note,''))>500 then raise exception 'Pastaba per ilga.'; end if;
 select * into v_promo from public.zuwu_promotions where id=1;
 if found and v_promo.enabled and (v_promo.starts_at is null or v_promo.starts_at<=v_now) and (v_promo.ends_at is null or v_promo.ends_at>=v_now) then v_discount:=v_promo.discount_value; else v_promo.enabled:=false; end if;
 for item in select value from jsonb_array_elements(p_items) loop
  v_listing_id:=(item->>'listing_id')::uuid; v_qty:=greatest(1,least(20,coalesce((item->>'quantity')::integer,1)));
  select seller_id,price,status,stock into v_seller,v_price,v_status,v_stock from public.listings where id=v_listing_id for update;
  if not found or v_status<>'active' then raise exception 'Viena iš prekių nepasiekiama.'; end if;
  if v_seller=auth.uid() then raise exception 'Negalite užsisakyti savo prekės.'; end if;
  if v_stock<v_qty then raise exception 'Nepakanka prekės likučio. Turima: %',v_stock; end if;
  if v_promo.enabled then
   if v_promo.discount_type='percent' then v_unit:=greatest(0.01,v_price-round(v_price*least(v_discount,90)/100,2));
   else v_unit:=greatest(0.01,v_price-least(v_price-0.01,v_discount)); end if;
  else v_unit:=v_price; end if;
  insert into public.orders(listing_id,buyer_id,seller_id,amount,buyer_note,quantity,unit_price,payment_method)
  values(v_listing_id,auth.uid(),v_seller,round(v_unit*v_qty,2),coalesce(p_buyer_note,''),v_qty,v_unit,p_payment_method)
  returning id into v_order_id;
  update public.listings set stock=stock-v_qty where id=v_listing_id;
  v_ids:=v_ids||jsonb_build_array(v_order_id);
 end loop;
 return v_ids;
end; $$;
revoke all on function public.zuwu_submit_cart_v5(jsonb,text,text) from public;
grant execute on function public.zuwu_submit_cart_v5(jsonb,text,text) to authenticated;

create table if not exists public.zuwu_discord_tickets (
 order_id uuid primary key references public.orders(id) on delete cascade,
 discord_channel_id text not null,
 discord_guild_id text not null,
 buyer_id uuid not null references auth.users(id) on delete cascade,
 status text not null default 'open' check(status in ('open','claimed','approved','closed')),
 claimed_by uuid references auth.users(id),
 claimed_at timestamptz,
 approved_at timestamptz,
 closed_at timestamptz,
 created_at timestamptz not null default now()
);
alter table public.zuwu_discord_tickets enable row level security;
drop policy if exists "Buyer or admin reads own Discord ticket mapping" on public.zuwu_discord_tickets;
create policy "Buyer or admin reads own Discord ticket mapping" on public.zuwu_discord_tickets
 for select to authenticated using (buyer_id=auth.uid() or public.zuwu_is_admin());
revoke insert,update,delete on public.zuwu_discord_tickets from anon,authenticated;
grant select on public.zuwu_discord_tickets to authenticated;
