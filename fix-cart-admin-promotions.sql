-- ZUWU MARKET V2: krepšelio / admin prekių / akcijų teisių pataisymai
-- Paleisti Supabase SQL Editor po setup.sql ir upgrade-cart-promotions.sql.
-- UID turi sutapti su ADMIN_USER_ID reikšme index.html faile.

create or replace function public.zuwu_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() = '760d15f6-6d18-4b40-916b-6473473a66cf'::uuid;
$$;

grant execute on function public.zuwu_is_admin() to authenticated;

-- Adminas gali peržiūrėti, kurti, redaguoti ir trinti visus skelbimus.
-- Vieši lankytojai gali matyti tik aktyvias prekes.
alter table public.listings enable row level security;
drop policy if exists "Public can read active listings" on public.listings;
drop policy if exists "Only ZUWU admin can insert listings" on public.listings;
drop policy if exists "Only ZUWU admin can update listings" on public.listings;
drop policy if exists "Only ZUWU admin can delete listings" on public.listings;
create policy "Public can read active listings" on public.listings
  for select to anon, authenticated using (status = 'active' or public.zuwu_is_admin());
create policy "Only ZUWU admin can insert listings" on public.listings
  for insert to authenticated with check (public.zuwu_is_admin());
create policy "Only ZUWU admin can update listings" on public.listings
  for update to authenticated using (public.zuwu_is_admin()) with check (public.zuwu_is_admin());
create policy "Only ZUWU admin can delete listings" on public.listings
  for delete to authenticated using (public.zuwu_is_admin());
grant select on public.listings to anon, authenticated;
grant insert, update, delete on public.listings to authenticated;

-- Akcijų lentelė: viešas skaitymas, rašymas tik adminui.
alter table public.zuwu_promotions enable row level security;
drop policy if exists "Public can view ZUWU promotion" on public.zuwu_promotions;
drop policy if exists "Admin can manage ZUWU promotion" on public.zuwu_promotions;
create policy "Public can view ZUWU promotion" on public.zuwu_promotions
  for select to anon, authenticated using (true);
create policy "Admin can manage ZUWU promotion" on public.zuwu_promotions
  for all to authenticated using (public.zuwu_is_admin()) with check (public.zuwu_is_admin());
grant select on public.zuwu_promotions to anon, authenticated;
grant insert, update on public.zuwu_promotions to authenticated;
