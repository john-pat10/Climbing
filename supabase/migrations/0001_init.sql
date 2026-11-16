-- Climb Log: initial schema
-- Run once in the Supabase dashboard: SQL Editor -> paste -> Run.
--
-- Licensing: crags/routes hold only factual fields (names, grades, location,
-- discipline). Never store OpenBeta descriptions or photos here.
-- `source` records where each crag/route came from.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9_]{3,24}$'),
  created_at timestamptz not null default now()
);

-- Shared catalog of crags: OpenBeta areas the app has used, plus user-added crags.
create table public.crags (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 1 and 120),
  source text not null check (source in ('openbeta', 'user')),
  openbeta_id uuid unique,
  path text[] not null default '{}',          -- location breadcrumb, e.g. {USA,Oregon,Smith Rock}
  lat double precision,
  lng double precision,
  created_by uuid default auth.uid() references auth.users on delete set null,
  created_at timestamptz not null default now(),
  check ((source = 'openbeta') = (openbeta_id is not null))
);

-- Shared catalog of routes/problems.
create table public.routes (
  id uuid primary key default gen_random_uuid(),
  crag_id uuid not null references public.crags on delete restrict,
  name text not null check (length(trim(name)) between 1 and 120),
  source text not null check (source in ('openbeta', 'user')),
  openbeta_id uuid unique,
  grade text,
  grade_system text check (grade_system in ('yds', 'vscale')),
  discipline text not null check (discipline in ('boulder', 'sport', 'trad')),
  created_by uuid default auth.uid() references auth.users on delete set null,
  created_at timestamptz not null default now(),
  check ((source = 'openbeta') = (openbeta_id is not null))
);

-- A day out at one crag (private logbook).
create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  climbed_on date not null default current_date,
  crag_id uuid not null references public.crags on delete restrict,
  notes text,
  created_at timestamptz not null default now()
);

-- One climb attempted/sent during a session. Grade is snapshotted at log time.
create table public.ascents (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions on delete cascade,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  route_id uuid not null references public.routes on delete restrict,
  grade text not null,
  grade_system text not null check (grade_system in ('yds', 'vscale')),
  grade_rank smallint not null,               -- sortable number, for "hardest grade"
  discipline text not null check (discipline in ('boulder', 'sport', 'trad')),
  tick_type text not null check (tick_type in ('onsight', 'flash', 'redpoint', 'attempt', 'toprope')),
  notes text,
  created_at timestamptz not null default now()
);

create index sessions_user_date_idx on public.sessions (user_id, climbed_on desc);
create index ascents_session_idx on public.ascents (session_id);
create index routes_crag_idx on public.routes (crag_id);

-- ---------------------------------------------------------------------------
-- Profiles: created automatically on sign-up from the `username` metadata
-- ---------------------------------------------------------------------------

create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, username)
  values (new.id, lower(new.raw_user_meta_data ->> 'username'));
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Lets the sign-up screen check a username before creating the account.
-- Returns only true/false, so it does not expose the profiles table.
create function public.username_available(name text) returns boolean
language sql stable security definer set search_path = '' as $$
  select not exists (select 1 from public.profiles where username = lower(name));
$$;

revoke execute on function public.username_available(text) from public;
grant execute on function public.username_available(text) to anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.crags    enable row level security;
alter table public.routes   enable row level security;
alter table public.sessions enable row level security;
alter table public.ascents  enable row level security;

-- Signed-in users only; signed-out (anon) users get no table access at all.
revoke all on public.profiles, public.crags, public.routes, public.sessions, public.ascents from anon;
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.crags, public.routes, public.sessions, public.ascents to authenticated;

-- Profiles
create policy "profiles: signed-in users can read" on public.profiles
  for select to authenticated using (true);
create policy "profiles: update own" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Catalog: everyone signed in reads; you insert as yourself;
-- you can edit/delete only user-added rows you created.
create policy "crags: read" on public.crags
  for select to authenticated using (true);
create policy "crags: insert as self" on public.crags
  for insert to authenticated with check (created_by = auth.uid());
create policy "crags: edit own user-added" on public.crags
  for update to authenticated
  using (created_by = auth.uid() and source = 'user')
  with check (created_by = auth.uid() and source = 'user');
create policy "crags: delete own user-added" on public.crags
  for delete to authenticated using (created_by = auth.uid() and source = 'user');

create policy "routes: read" on public.routes
  for select to authenticated using (true);
create policy "routes: insert as self" on public.routes
  for insert to authenticated with check (created_by = auth.uid());
create policy "routes: edit own user-added" on public.routes
  for update to authenticated
  using (created_by = auth.uid() and source = 'user')
  with check (created_by = auth.uid() and source = 'user');
create policy "routes: delete own user-added" on public.routes
  for delete to authenticated using (created_by = auth.uid() and source = 'user');

-- Logbook: private to its owner
create policy "sessions: own" on public.sessions
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "ascents: own" on public.ascents
  for all to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.sessions s where s.id = session_id and s.user_id = auth.uid())
  );
