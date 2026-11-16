-- Minimal stand-in for the parts of Supabase that 0001_init.sql relies on,
-- so the migration and RLS policies can be tested on plain Postgres.
-- NOT for use on a real Supabase project (these already exist there).
create role anon nologin;
create role authenticated nologin;
create schema auth;
create table auth.users (
  id uuid primary key default gen_random_uuid(),
  email text unique,
  raw_user_meta_data jsonb not null default '{}'
);
-- Supabase reads the user id from the request's JWT; tests set it directly.
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
grant usage on schema auth to anon, authenticated;
grant usage on schema public to anon, authenticated;
-- Hosted Supabase grants these by default; the migration revokes/grants explicitly.
alter default privileges in schema public grant all on tables to anon, authenticated;
