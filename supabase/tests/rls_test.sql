-- RLS and constraint tests for 0001_init.sql. Run with: npm run test:db
\set ON_ERROR_STOP on
\set QUIET on
create extension if not exists pgcrypto;

-- Helpers: run as a signed-in user, as anon, or assert an error.
create function pg_temp.login(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, false);
  execute 'set role authenticated';
end $$;
create function pg_temp.expect_error(sql text, label text) returns void language plpgsql as $$
begin
  begin execute sql;
  exception when others then raise notice 'PASS: % (blocked: %)', label, sqlerrm; return;
  end;
  raise exception 'FAIL: % (statement succeeded but should not have)', label;
end $$;
create function pg_temp.affected(sql text) returns int language plpgsql as $$
declare n int;
begin execute sql; get diagnostics n = row_count; return n; end $$;
create function pg_temp.expect(cond boolean, label text) returns void language plpgsql as $$
begin
  if cond then raise notice 'PASS: %', label; else raise exception 'FAIL: %', label; end if;
end $$;

-- Sign-up creates profiles via the trigger
insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000000a', 'alice@example.com', '{"username":"Alice"}'),
  ('00000000-0000-0000-0000-00000000000b', 'bob@example.com',   '{"username":"bob"}');
select pg_temp.expect((select username from profiles where id = '00000000-0000-0000-0000-00000000000a') = 'alice',
  'trigger creates profile with lower-cased username');
select pg_temp.expect_error($$insert into auth.users (email, raw_user_meta_data) values ('x@example.com', '{"username":"alice"}')$$,
  'duplicate username rejects sign-up');
select pg_temp.expect_error($$insert into auth.users (email, raw_user_meta_data) values ('y@example.com', '{}')$$,
  'missing username rejects sign-up');
select pg_temp.expect_error($$insert into auth.users (email, raw_user_meta_data) values ('z@example.com', '{"username":"no spaces!"}')$$,
  'invalid username rejects sign-up');

-- Anonymous (signed out)
set role anon;
select pg_temp.expect(public.username_available('carol'), 'anon: username_available true for free name');
select pg_temp.expect(not public.username_available('ALICE'), 'anon: username_available false for taken name (case-insensitive)');
select pg_temp.expect_error('select * from public.profiles', 'anon cannot read profiles');
select pg_temp.expect_error('select * from public.crags', 'anon cannot read crags');
reset role;

-- Alice logs a session
select pg_temp.login('00000000-0000-0000-0000-00000000000a');
insert into crags (id, name, source, openbeta_id, path)
  values ('10000000-0000-0000-0000-000000000001', 'Smith Rock', 'openbeta', 'f3c655b6-9c95-597f-aaa6-fd7d8a4865ec', '{USA,Oregon,Smith Rock}');
insert into crags (id, name, source) values ('10000000-0000-0000-0000-000000000002', 'Secret Boulders', 'user');
select pg_temp.expect((select created_by from crags where id = '10000000-0000-0000-0000-000000000002') = auth.uid(),
  'created_by defaults to the signed-in user');
select pg_temp.expect_error($$insert into crags (name, source) values ('Fake', 'openbeta')$$,
  'openbeta source requires openbeta_id');
select pg_temp.expect_error($$insert into crags (name, source, openbeta_id) values ('Fake', 'user', gen_random_uuid())$$,
  'user source must not have openbeta_id');
select pg_temp.expect_error($$insert into crags (name, source, created_by) values ('Spoof', 'user', '00000000-0000-0000-0000-00000000000b')$$,
  'cannot insert a crag as someone else');
insert into routes (id, crag_id, name, source, grade, grade_system, discipline)
  values ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', 'Mystery Arete', 'user', 'V4', 'vscale', 'boulder');
insert into sessions (id, crag_id, climbed_on) values ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', '2026-11-01');
insert into ascents (session_id, route_id, grade, grade_system, grade_rank, discipline, tick_type)
  values ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'V4', 'vscale', 4, 'boulder', 'flash');
select pg_temp.expect_error($$insert into ascents (session_id, route_id, grade, grade_system, grade_rank, discipline, tick_type)
  values ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'V4', 'vscale', 4, 'boulder', 'sent')$$,
  'invalid tick_type rejected');
select pg_temp.expect(pg_temp.affected($$update crags set name = 'Renamed' where id = '10000000-0000-0000-0000-000000000001'$$) = 0,
  'cannot edit an openbeta crag, even one you inserted');
select pg_temp.expect(pg_temp.affected($$update crags set name = 'Secret Boulders (east)' where id = '10000000-0000-0000-0000-000000000002'$$) = 1,
  'can edit own user-added crag');
reset role;

-- Bob: sees the shared catalog, but not Alice's logbook
select pg_temp.login('00000000-0000-0000-0000-00000000000b');
select pg_temp.expect((select count(*) from crags) = 2, 'bob can read shared crags');
select pg_temp.expect((select count(*) from routes) = 1, 'bob can read shared routes');
select pg_temp.expect((select count(*) from sessions) = 0, 'bob cannot see alice''s sessions');
select pg_temp.expect((select count(*) from ascents) = 0, 'bob cannot see alice''s ascents');
select pg_temp.expect(pg_temp.affected($$update crags set name = 'Hacked' where id = '10000000-0000-0000-0000-000000000002'$$) = 0,
  'bob cannot edit alice''s crag');
select pg_temp.expect(pg_temp.affected($$delete from routes where id = '20000000-0000-0000-0000-000000000001'$$) = 0,
  'bob cannot delete alice''s route');
select pg_temp.expect(pg_temp.affected($$delete from sessions$$) = 0, 'bob cannot delete alice''s sessions');
select pg_temp.expect(pg_temp.affected($$update profiles set username = 'alice2' where id = '00000000-0000-0000-0000-00000000000a'$$) = 0,
  'bob cannot edit alice''s profile');
select pg_temp.expect_error($$insert into ascents (session_id, route_id, grade, grade_system, grade_rank, discipline, tick_type)
  values ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'V4', 'vscale', 4, 'boulder', 'flash')$$,
  'bob cannot add an ascent to alice''s session');
select pg_temp.expect_error($$insert into sessions (user_id, crag_id) values ('00000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-000000000002')$$,
  'bob cannot create a session as alice');
insert into sessions (id, crag_id) values ('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002');
select pg_temp.expect((select count(*) from sessions) = 1, 'bob can log his own session at a shared crag');
reset role;

-- Alice can delete her own session; ascents cascade
select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select pg_temp.expect(pg_temp.affected($$delete from sessions where id = '30000000-0000-0000-0000-000000000001'$$) = 1,
  'alice can delete her own session');
reset role;
select pg_temp.expect((select count(*) from ascents) = 0, 'deleting a session deletes its ascents');

\echo 'ALL DATABASE TESTS PASSED'
