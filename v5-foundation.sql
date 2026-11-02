-- ZUWU MARKET V5 foundation migration
-- Run only on a STAGING database after all V4 migrations.
-- Requires public.zuwu_is_admin() from the existing setup.
create extension if not exists pgcrypto;

create table if not exists public.zuwu_order_events (
 id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade,
 actor_id uuid references auth.users(id) on delete set null, event_type text not null check(event_type in ('created','status_changed','note','fulfilled','refunded')),
 old_status text, new_status text, note text not null default '' check(char_length(note)<=500), created_at timestamptz not null default now()
);
create table if not exists public.zuwu_restock_watchers (
 user_id uuid not null references auth.users(id) on delete cascade, listing_id uuid not null references public.listings(id) on delete cascade,
 created_at timestamptz not null default now(), primary key(user_id,listing_id)
);
create table if not exists public.zuwu_support_tickets (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 subject text not null check(char_length(subject) between 3 and 120), category text not null default 'general',
 status text not null default 'open' check(status in ('open','in_progress','waiting_user','closed')),
 priority text not null default 'normal' check(priority in ('low','normal','high')), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.zuwu_support_replies (
 id uuid primary key default gen_random_uuid(), ticket_id uuid not null references public.zuwu_support_tickets(id) on delete cascade,
 author_id uuid not null references auth.users(id) on delete cascade, body text not null check(char_length(body) between 1 and 4000),
 is_staff boolean not null default false, created_at timestamptz not null default now()
);
create table if not exists public.zuwu_seller_reviews (
 id uuid primary key default gen_random_uuid(), seller_id uuid not null references auth.users(id) on delete cascade,
 buyer_id uuid not null references auth.users(id) on delete cascade, order_id uuid not null references public.orders(id) on delete cascade,
 rating int not null check(rating between 1 and 5), comment text not null default '' check(char_length(comment)<=600), created_at timestamptz not null default now(), unique(order_id,buyer_id), check(seller_id<>buyer_id)
);
create table if not exists public.zuwu_flash_deals (
 id uuid primary key default gen_random_uuid(), listing_id uuid not null references public.listings(id) on delete cascade,
 discount_type text not null check(discount_type in ('percent','fixed')), discount_value numeric(10,2) not null check(discount_value>0),
 starts_at timestamptz not null, ends_at timestamptz not null, enabled boolean not null default false,
 created_by uuid references auth.users(id), created_at timestamptz not null default now(), check(ends_at>starts_at)
);
create table if not exists public.zuwu_loyalty_ledger (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 points integer not null check(points<>0), reason text not null check(char_length(reason) between 2 and 160),
 order_id uuid references public.orders(id) on delete set null, created_at timestamptz not null default now()
);
create table if not exists public.zuwu_fraud_flags (
 id uuid primary key default gen_random_uuid(), reporter_id uuid references auth.users(id) on delete set null,
 subject_user_id uuid references auth.users(id) on delete set null, order_id uuid references public.orders(id) on delete set null,
 reason text not null check(char_length(reason) between 5 and 1000), status text not null default 'new' check(status in ('new','reviewing','resolved','dismissed')),
 created_at timestamptz not null default now(), reviewed_by uuid references auth.users(id), reviewed_at timestamptz
);
create table if not exists public.zuwu_admin_audit (
 id uuid primary key default gen_random_uuid(), admin_id uuid references auth.users(id) on delete set null,
 action text not null check(char_length(action) between 2 and 120), entity_type text not null, entity_id text,
 details jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create table if not exists public.zuwu_discord_links (
 user_id uuid primary key references auth.users(id) on delete cascade, discord_user_id text not null unique,
 guild_id text, linked_at timestamptz not null default now()
);

-- Reuse V4/V3 notification center if present; otherwise create compatible table.
create table if not exists public.zuwu_notifications (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 title text not null, body text not null, read_at timestamptz, created_at timestamptz not null default now()
);

-- Wishlist is additive; V3 favorites remain untouched.
create table if not exists public.zuwu_wishlist (
 user_id uuid not null references auth.users(id) on delete cascade, listing_id uuid not null references public.listings(id) on delete cascade,
 notify_restock boolean not null default true, created_at timestamptz not null default now(), primary key(user_id,listing_id)
);

-- Enable RLS on all V5 tables.
do $$ declare t text; begin foreach t in array array[
'zuwu_order_events','zuwu_restock_watchers','zuwu_support_tickets','zuwu_support_replies','zuwu_seller_reviews',
'zuwu_flash_deals','zuwu_loyalty_ledger','zuwu_fraud_flags','zuwu_admin_audit','zuwu_discord_links','zuwu_notifications','zuwu_wishlist'
] loop execute format('alter table public.%I enable row level security',t); end loop; end $$;

-- User-owned data.
drop policy if exists v5_wishlist_owner on public.zuwu_wishlist;
create policy v5_wishlist_owner on public.zuwu_wishlist for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists v5_restock_owner on public.zuwu_restock_watchers;
create policy v5_restock_owner on public.zuwu_restock_watchers for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists v5_ticket_owner_read on public.zuwu_support_tickets;
create policy v5_ticket_owner_read on public.zuwu_support_tickets for select to authenticated using(user_id=auth.uid() or public.zuwu_is_admin());
drop policy if exists v5_ticket_owner_insert on public.zuwu_support_tickets;
create policy v5_ticket_owner_insert on public.zuwu_support_tickets for insert to authenticated with check(user_id=auth.uid());
drop policy if exists v5_ticket_admin_update on public.zuwu_support_tickets;
create policy v5_ticket_admin_update on public.zuwu_support_tickets for update to authenticated using(public.zuwu_is_admin()) with check(public.zuwu_is_admin());
drop policy if exists v5_replies_read on public.zuwu_support_replies;
create policy v5_replies_read on public.zuwu_support_replies for select to authenticated using(public.zuwu_is_admin() or exists(select 1 from public.zuwu_support_tickets t where t.id=ticket_id and t.user_id=auth.uid()));
drop policy if exists v5_replies_insert on public.zuwu_support_replies;
create policy v5_replies_insert on public.zuwu_support_replies for insert to authenticated with check(author_id=auth.uid() and (public.zuwu_is_admin() or (not is_staff and exists(select 1 from public.zuwu_support_tickets t where t.id=ticket_id and t.user_id=auth.uid()))));
drop policy if exists v5_notifications_owner_read on public.zuwu_notifications;
create policy v5_notifications_owner_read on public.zuwu_notifications for select to authenticated using(user_id=auth.uid());
drop policy if exists v5_notifications_owner_update on public.zuwu_notifications;
create policy v5_notifications_owner_update on public.zuwu_notifications for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists v5_discord_owner_read on public.zuwu_discord_links;
create policy v5_discord_owner_read on public.zuwu_discord_links for select to authenticated using(user_id=auth.uid() or public.zuwu_is_admin());

-- Public read for active deal cards and seller reputation; no client-side writes.
drop policy if exists v5_deals_public_read on public.zuwu_flash_deals;
create policy v5_deals_public_read on public.zuwu_flash_deals for select to anon,authenticated using(enabled and starts_at<=now() and ends_at>=now() or public.zuwu_is_admin());
drop policy if exists v5_seller_reviews_public_read on public.zuwu_seller_reviews;
create policy v5_seller_reviews_public_read on public.zuwu_seller_reviews for select to anon,authenticated using(true);

-- Private/admin-only tables: no user-facing policies are granted here.
drop policy if exists v5_order_events_read on public.zuwu_order_events;
create policy v5_order_events_read on public.zuwu_order_events for select to authenticated using(public.zuwu_is_admin() or exists(select 1 from public.orders o where o.id=order_id and o.buyer_id=auth.uid()));
drop policy if exists v5_loyalty_read on public.zuwu_loyalty_ledger;
create policy v5_loyalty_read on public.zuwu_loyalty_ledger for select to authenticated using(user_id=auth.uid() or public.zuwu_is_admin());
drop policy if exists v5_fraud_admin_read on public.zuwu_fraud_flags;
create policy v5_fraud_admin_read on public.zuwu_fraud_flags for select to authenticated using(public.zuwu_is_admin());
drop policy if exists v5_fraud_user_insert on public.zuwu_fraud_flags;
create policy v5_fraud_user_insert on public.zuwu_fraud_flags for insert to authenticated with check(reporter_id=auth.uid());
drop policy if exists v5_audit_admin_read on public.zuwu_admin_audit;
create policy v5_audit_admin_read on public.zuwu_admin_audit for select to authenticated using(public.zuwu_is_admin());

-- Minimal grants; writes that affect money, stock, points, role sync and fraud decisions
-- must be implemented via validated server-side endpoints/RPCs in a later integration step.
grant select,insert,delete on public.zuwu_wishlist to authenticated;
grant select,insert,delete on public.zuwu_restock_watchers to authenticated;
grant select,insert on public.zuwu_support_tickets to authenticated;
grant select,insert on public.zuwu_support_replies to authenticated;
grant select on public.zuwu_seller_reviews,public.zuwu_flash_deals to anon,authenticated;
grant select on public.zuwu_order_events,public.zuwu_loyalty_ledger,public.zuwu_notifications,public.zuwu_discord_links to authenticated;
grant update on public.zuwu_notifications to authenticated;
grant select,insert on public.zuwu_fraud_flags to authenticated;
grant select on public.zuwu_admin_audit to authenticated;
