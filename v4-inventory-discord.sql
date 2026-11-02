-- ZUWU MARKET V4: inventory and Discord automations
-- Run AFTER setup.sql, upgrade-cart-promotions.sql and previous V3 migrations.
alter table public.listings add column if not exists stock integer not null default 0 check(stock between 0 and 100000);
-- Preserve availability of already-published products: admin can set their real stock after migration.
-- New products start with zero unless the admin enters a quantity in the listing form.

create or replace function public.zuwu_submit_cart(p_items jsonb, p_buyer_note text default '')
returns jsonb language plpgsql security definer set search_path=public as $$
declare item jsonb; v_listing_id uuid; v_qty integer; v_seller uuid; v_price numeric(10,2); v_status text; v_stock integer; v_discount numeric(10,2):=0; v_unit numeric(10,2); v_order_id uuid; v_ids jsonb:='[]'::jsonb; v_promo public.zuwu_promotions%rowtype; v_now timestamptz:=now();
begin
 if auth.uid() is null then raise exception 'Prisijunkite, kad pateiktumėte užsakymą.'; end if;
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
  if v_promo.enabled then if v_promo.discount_type='percent' then v_unit:=greatest(0.01,v_price-round(v_price*least(v_discount,90)/100,2)); else v_unit:=greatest(0.01,v_price-least(v_price-0.01,v_discount)); end if; else v_unit:=v_price; end if;
  insert into public.orders(listing_id,buyer_id,seller_id,amount,buyer_note,quantity,unit_price) values(v_listing_id,auth.uid(),v_seller,round(v_unit*v_qty,2),coalesce(p_buyer_note,''),v_qty,v_unit) returning id into v_order_id;
  update public.listings set stock=stock-v_qty where id=v_listing_id;
  v_ids:=v_ids||jsonb_build_array(v_order_id);
 end loop;
 return v_ids;
end; $$;
revoke all on function public.zuwu_submit_cart(jsonb,text) from public;
grant execute on function public.zuwu_submit_cart(jsonb,text) to authenticated;
