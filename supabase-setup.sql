-- ============================================================
--  GENIUS PARK - Supabase one-time setup (run ONCE)
--  Covers BOTH apps on ONE shared cloud project:
--    * GPOS               -> gpos_state / gpos_profiles / gpos_finance
--    * Head of Ops & QC   -> scos_state / scos_profiles / scos_leads_inbox
--  How: Supabase dashboard -> SQL Editor -> New query -> paste ALL of
--  this -> Run. Safe to run on a fresh project. (If you re-run and see
--  "already member of publication", that line is harmless - ignore it.)
--  The FIRST user you create in Auth becomes Admin/MD automatically.
-- ============================================================


-- ============================================================
--  PART A - GPOS (CEO Command Center)
-- ============================================================

-- A1) Shared team vault (everyone signed in)
create table if not exists public.gpos_state (
  id text primary key default 'main', data jsonb,
  updated_at timestamptz default now(), updated_by uuid);
alter table public.gpos_state enable row level security;
drop policy if exists gpos_state_rw on public.gpos_state;
create policy gpos_state_rw on public.gpos_state
  for all to authenticated using (true) with check (true);

-- A2) Profiles: maps a login to a GPOS role (admin | lead | viewer)
create table if not exists public.gpos_profiles (
  id uuid primary key references auth.users on delete cascade,
  email text, role text not null default 'viewer',
  created_at timestamptz default now());
alter table public.gpos_profiles enable row level security;
create or replace function public.gpos_is_admin() returns boolean
  language sql security definer stable set search_path=public as $$
  select exists(select 1 from public.gpos_profiles where id=auth.uid() and role='admin'); $$;
drop policy if exists gpos_profiles_read on public.gpos_profiles;
create policy gpos_profiles_read on public.gpos_profiles for select to authenticated using (true);
drop policy if exists gpos_profiles_admin_write on public.gpos_profiles;
create policy gpos_profiles_admin_write on public.gpos_profiles for update to authenticated using (public.gpos_is_admin());

-- A3) FINANCE vault - ADMIN ONLY (bank, accounting, P&L). Lead logins cannot read it.
create table if not exists public.gpos_finance (
  id text primary key default 'main', data jsonb,
  updated_at timestamptz default now(), updated_by uuid);
alter table public.gpos_finance enable row level security;
drop policy if exists gpos_finance_admin on public.gpos_finance;
create policy gpos_finance_admin on public.gpos_finance
  for all to authenticated using (public.gpos_is_admin()) with check (public.gpos_is_admin());

-- A4) Auto-create a profile on signup; the FIRST user becomes admin
create or replace function public.handle_new_user() returns trigger
  language plpgsql security definer set search_path=public as $$
declare cnt int;
begin
  select count(*) into cnt from public.gpos_profiles;
  insert into public.gpos_profiles(id,email,role)
    values (new.id, new.email, case when cnt=0 then 'admin' else 'viewer' end)
    on conflict (id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();


-- ============================================================
--  PART B - HEAD OF OPERATIONS & QC COMMAND CENTER
-- ============================================================

-- B1) Live shared vault for the Command Center (all ops users)
create table if not exists public.scos_state (
  id text primary key default 'main', data jsonb,
  updated_at timestamptz default now(), updated_by uuid);
alter table public.scos_state enable row level security;
drop policy if exists scos_state_rw on public.scos_state;
create policy scos_state_rw on public.scos_state for all to authenticated using (true) with check (true);

-- B2) Profiles: maps a cloud login to a SCOS role
create table if not exists public.scos_profiles (
  id uuid primary key references auth.users on delete cascade,
  email text, role text not null default 'reception', created_at timestamptz default now());
alter table public.scos_profiles enable row level security;
drop policy if exists scos_profiles_read on public.scos_profiles;
create policy scos_profiles_read on public.scos_profiles for select to authenticated using (true);

-- B3) Ambassador -> Ops LEAD INBOX (the bridge; GPOS ambassador portal inserts here)
create table if not exists public.scos_leads_inbox (
  id uuid primary key default gen_random_uuid(),
  name text not null, country text, source text default 'ambassador',
  ambassador_id text, campus_id text, note text,
  status text default 'new', created_at timestamptz default now());
alter table public.scos_leads_inbox enable row level security;
drop policy if exists scos_inbox_rw on public.scos_leads_inbox;
create policy scos_inbox_rw on public.scos_leads_inbox for all to authenticated using (true) with check (true);

-- B4) First cloud user becomes MD; others default reception
create or replace function public.scos_new_user() returns trigger
  language plpgsql security definer set search_path=public as $$
declare cnt int;
begin
  select count(*) into cnt from public.scos_profiles;
  insert into public.scos_profiles(id,email,role)
    values (new.id,new.email, case when cnt=0 then 'md' else 'reception' end)
    on conflict (id) do nothing;
  return new;
end; $$;
drop trigger if exists scos_on_new_user on auth.users;
create trigger scos_on_new_user after insert on auth.users
  for each row execute function public.scos_new_user();


-- ============================================================
--  PART C - LIVE SYNC (realtime). Harmless "already member" if re-run.
-- ============================================================
alter publication supabase_realtime add table public.gpos_state;
alter publication supabase_realtime add table public.scos_state;
alter publication supabase_realtime add table public.scos_leads_inbox;
