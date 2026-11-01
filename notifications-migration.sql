-- ZUWU MARKET: pranešimai apie užsakymų būsenos pakeitimus ir Realtime
-- Paleisk Supabase SQL Editor vieną kartą. Ši migracija nekeičia esamų užsakymų.
alter table public.orders replica identity full;
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'orders'
  ) then
    alter publication supabase_realtime add table public.orders;
  end if;
end $$;
