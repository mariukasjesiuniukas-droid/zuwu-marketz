-- ZUWU MARKET: saugus vieno administratoriaus ir užsakymų nustatymas
-- PIRMIAUSIA: Supabase Dashboard -> SQL Editor. Pakeisk UUID žemiau į savo Auth UID.
-- Auth UID rasi: Authentication -> Users -> savo vartotojas -> UID.

-- 1) Sukurk/atnaujink savo administratoriaus ID funkciją.
create or replace function public.zuwu_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() = '760d15f6-6d18-4b40-916b-6473473a66cf'::uuid;
$$;

-- 2) Tik adminas gali kurti, redaguoti ir trinti skelbimus. Visi gali matyti aktyvius.
alter table public.listings enable row level security;
do $$ declare p record; begin
  for p in select policyname from pg_policies where schemaname='public' and tablename='listings'
  loop execute format('drop policy if exists %I on public.listings', p.policyname); end loop;
end $$;
create policy "Public can read active listings" on public.listings
  for select to anon, authenticated using (status = 'active' or public.zuwu_is_admin());
create policy "Only ZUWU admin can insert listings" on public.listings
  for insert to authenticated with check (public.zuwu_is_admin() and seller_id = auth.uid());
create policy "Only ZUWU admin can update listings" on public.listings
  for update to authenticated using (public.zuwu_is_admin()) with check (public.zuwu_is_admin());
create policy "Only ZUWU admin can delete listings" on public.listings
  for delete to authenticated using (public.zuwu_is_admin());

-- 3) Užsakymai: pirkėjas gali pateikti ir matyti savo užsakymus; adminas mato visus ir keičia būsenas.
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete restrict,
  buyer_id uuid not null references auth.users(id) on delete restrict,
  seller_id uuid not null references auth.users(id) on delete restrict,
  amount numeric(10,2) not null check (amount > 0),
  buyer_note text not null default '' check (char_length(buyer_note) <= 500),
  status text not null default 'pending_review'
    check (status in ('pending_review','approved','rejected','fulfilled','refunded')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.orders enable row level security;
drop policy if exists "Buyer or admin can read orders" on public.orders;
drop policy if exists "Admin can update orders" on public.orders;
create policy "Buyer or admin can read orders" on public.orders
  for select to authenticated using (buyer_id = auth.uid() or public.zuwu_is_admin());
create policy "Admin can update orders" on public.orders
  for update to authenticated using (public.zuwu_is_admin()) with check (public.zuwu_is_admin());
-- Nėra tiesioginio INSERT leidimo: užsakymas kuriamas tik saugia RPC funkcija.
revoke insert, update, delete on public.orders from anon, authenticated;
grant select on public.orders to authenticated;
grant update (status, updated_at) on public.orders to authenticated;

create or replace function public.submit_order(p_listing_id uuid, p_buyer_note text default '')
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare v_id uuid; v_seller uuid; v_price numeric(10,2); v_status text;
begin
  if auth.uid() is null then raise exception 'Prisijunkite, kad pateiktumėte užsakymą.'; end if;
  if char_length(coalesce(p_buyer_note,'')) > 500 then raise exception 'Pastaba per ilga.'; end if;
  select seller_id, price, status into v_seller, v_price, v_status
    from public.listings where id = p_listing_id;
  if not found or v_status <> 'active' then raise exception 'Ši prekė šiuo metu nepasiekiama.'; end if;
  if v_seller = auth.uid() then raise exception 'Negalite užsisakyti savo prekės.'; end if;
  insert into public.orders(listing_id,buyer_id,seller_id,amount,buyer_note)
    values(p_listing_id,auth.uid(),v_seller,v_price,coalesce(p_buyer_note,'')) returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.submit_order(uuid,text) from public;
grant execute on function public.submit_order(uuid,text) to authenticated;

-- 4) Nuotraukos. Bucket turi vadintis listing_images ir būti PUBLIC, kad nuotraukos matytųsi kataloge.
insert into storage.buckets (id, name, public)
values ('listing_images', 'listing_images', true)
on conflict (id) do update set public = true;
-- Pridėk ribojančias taisykles, kad net jei liko senų upload policies, tik adminas galėtų keisti šio bucket failus.
drop policy if exists "ZUWU admin upload listing images" on storage.objects;
drop policy if exists "ZUWU admin update listing images" on storage.objects;
drop policy if exists "ZUWU admin delete listing images" on storage.objects;
drop policy if exists "ZUWU restrict listing image inserts" on storage.objects;
drop policy if exists "ZUWU restrict listing image updates" on storage.objects;
drop policy if exists "ZUWU restrict listing image deletes" on storage.objects;
create policy "ZUWU admin upload listing images" on storage.objects
  for insert to authenticated with check (bucket_id='listing_images' and public.zuwu_is_admin());
create policy "ZUWU admin update listing images" on storage.objects
  for update to authenticated using (bucket_id='listing_images' and public.zuwu_is_admin())
  with check (bucket_id='listing_images' and public.zuwu_is_admin());
create policy "ZUWU admin delete listing images" on storage.objects
  for delete to authenticated using (bucket_id='listing_images' and public.zuwu_is_admin());
create policy "ZUWU restrict listing image inserts" on storage.objects as restrictive
  for insert to authenticated with check (bucket_id <> 'listing_images' or public.zuwu_is_admin());
create policy "ZUWU restrict listing image updates" on storage.objects as restrictive
  for update to authenticated using (bucket_id <> 'listing_images' or public.zuwu_is_admin())
  with check (bucket_id <> 'listing_images' or public.zuwu_is_admin());
create policy "ZUWU restrict listing image deletes" on storage.objects as restrictive
  for delete to authenticated using (bucket_id <> 'listing_images' or public.zuwu_is_admin());

-- 5) Saugus viešas nuotraukų skaitymas. Jei jau yra tinkama SELECT policy, šios gali neprireikti.
drop policy if exists "Anyone can view ZUWU listing images" on storage.objects;
create policy "Anyone can view ZUWU listing images" on storage.objects
  for select to anon, authenticated using (bucket_id='listing_images');
