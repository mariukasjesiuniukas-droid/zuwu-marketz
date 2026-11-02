-- ZUWU MARKET V3 feature migration. Run AFTER setup.sql, upgrade-cart-promotions.sql and fix-cart-admin-promotions.sql.
-- Confirm public.zuwu_is_admin() contains the correct admin UUID before running.
create table if not exists public.zuwu_coupons (
 id uuid primary key default gen_random_uuid(), code text not null unique check (code ~ '^[A-Z0-9_-]{3,24}$'),
 discount_type text not null check(discount_type in ('percent','fixed')), discount_value numeric(10,2) not null check(discount_value>0),
 enabled boolean not null default true, max_uses integer check(max_uses is null or max_uses>0), used_count integer not null default 0 check(used_count>=0),
 starts_at timestamptz, ends_at timestamptz, created_by uuid references auth.users(id), created_at timestamptz not null default now(),
 check(ends_at is null or starts_at is null or ends_at>starts_at));
create table if not exists public.zuwu_categories(id uuid primary key default gen_random_uuid(),name text not null unique,created_at timestamptz not null default now());
insert into public.zuwu_categories(name) values ('Žaidimai'),('Žaidimų valiuta'),('Skinai ir daiktai'),('Žaidimų kodai'),('Kita') on conflict(name) do nothing;
create table if not exists public.zuwu_favorites(user_id uuid not null references auth.users(id) on delete cascade,listing_id uuid not null references public.listings(id) on delete cascade,created_at timestamptz not null default now(),primary key(user_id,listing_id));
create table if not exists public.zuwu_reviews(id uuid primary key default gen_random_uuid(),listing_id uuid not null references public.listings(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,rating int not null check(rating between 1 and 5),comment text not null default '' check(char_length(comment)<=500),created_at timestamptz not null default now(),unique(listing_id,user_id));
create table if not exists public.zuwu_reports(id uuid primary key default gen_random_uuid(),listing_id uuid not null references public.listings(id) on delete cascade,reporter_id uuid not null references auth.users(id) on delete cascade,reason text not null check(char_length(reason) between 3 and 500),created_at timestamptz not null default now());
create table if not exists public.zuwu_notifications(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,title text not null,body text not null,read_at timestamptz,created_at timestamptz not null default now());
DO $$ DECLARE t text; BEGIN FOREACH t IN ARRAY ARRAY['zuwu_coupons','zuwu_categories','zuwu_favorites','zuwu_reviews','zuwu_reports','zuwu_notifications'] LOOP EXECUTE format('alter table public.%I enable row level security',t); END LOOP; END $$;
-- Coupons: public may validate active codes; only admin can manage.
drop policy if exists "coupon public read" on public.zuwu_coupons; create policy "coupon public read" on public.zuwu_coupons for select to anon,authenticated using(enabled=true or public.zuwu_is_admin());
drop policy if exists "coupon admin manage" on public.zuwu_coupons; create policy "coupon admin manage" on public.zuwu_coupons for all to authenticated using(public.zuwu_is_admin()) with check(public.zuwu_is_admin());
-- Categories are public-readable, admin-managed.
drop policy if exists "categories public read" on public.zuwu_categories; create policy "categories public read" on public.zuwu_categories for select to anon,authenticated using(true);
drop policy if exists "categories admin manage" on public.zuwu_categories; create policy "categories admin manage" on public.zuwu_categories for all to authenticated using(public.zuwu_is_admin()) with check(public.zuwu_is_admin());
-- Personal data is private to its owner; admin can moderate reports.
drop policy if exists "favorites own manage" on public.zuwu_favorites; create policy "favorites own manage" on public.zuwu_favorites for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists "reviews public read" on public.zuwu_reviews; create policy "reviews public read" on public.zuwu_reviews for select to anon,authenticated using(true);
drop policy if exists "reviews verified insert" on public.zuwu_reviews; create policy "reviews verified insert" on public.zuwu_reviews for insert to authenticated with check(user_id=auth.uid() and exists(select 1 from public.orders o where o.listing_id=zuwu_reviews.listing_id and o.buyer_id=auth.uid() and o.status='fulfilled'));
drop policy if exists "reports owner insert" on public.zuwu_reports; create policy "reports owner insert" on public.zuwu_reports for insert to authenticated with check(reporter_id=auth.uid());
drop policy if exists "reports admin read" on public.zuwu_reports; create policy "reports admin read" on public.zuwu_reports for select to authenticated using(public.zuwu_is_admin());
drop policy if exists "reports admin delete" on public.zuwu_reports; create policy "reports admin delete" on public.zuwu_reports for delete to authenticated using(public.zuwu_is_admin());
drop policy if exists "notifications own read" on public.zuwu_notifications; create policy "notifications own read" on public.zuwu_notifications for select to authenticated using(user_id=auth.uid());
drop policy if exists "notifications own update" on public.zuwu_notifications; create policy "notifications own update" on public.zuwu_notifications for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
-- Only admin may create notifications; order status trigger creates them automatically.
drop policy if exists "notifications admin insert" on public.zuwu_notifications; create policy "notifications admin insert" on public.zuwu_notifications for insert to authenticated with check(public.zuwu_is_admin());
create or replace function public.zuwu_order_status_notice() returns trigger language plpgsql security definer set search_path=public as $$ begin if new.status is distinct from old.status then insert into public.zuwu_notifications(user_id,title,body) values(new.buyer_id,'Užsakymo atnaujinimas','Užsakymo '||left(new.id::text,8)||' būsena: '||new.status); end if; return new; end $$;
drop trigger if exists zuwu_order_status_notice on public.orders; create trigger zuwu_order_status_notice after update of status on public.orders for each row execute function public.zuwu_order_status_notice();
grant select on public.zuwu_categories,public.zuwu_reviews to anon,authenticated;
grant select,insert,update,delete on public.zuwu_favorites to authenticated;
grant insert on public.zuwu_reviews,public.zuwu_reports to authenticated;
grant select,delete on public.zuwu_reports to authenticated;
grant select,update on public.zuwu_notifications to authenticated;
grant select on public.zuwu_coupons to anon,authenticated; grant insert,update,delete on public.zuwu_coupons to authenticated;
grant insert,update,delete on public.zuwu_categories to authenticated;
-- Note: V3 coupon validation UI is prepared; checkout enforcement/use-count is intentionally NOT client-trusted.
-- Add coupon redemption to the server-side checkout RPC before treating coupon discounts as payable totals.
