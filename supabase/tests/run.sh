#!/usr/bin/env bash
# Runs the migration + RLS tests against a throwaway local Postgres.
# Needs PostgreSQL 15+ binaries (initdb, pg_ctl, psql) on PATH or in /usr/lib/postgresql/*/bin.
set -euo pipefail
cd "$(dirname "$0")/../.."
PGBIN=$(dirname "$(command -v initdb 2>/dev/null || ls -d /usr/lib/postgresql/*/bin/initdb | tail -1)")
DIR=$(mktemp -d); PORT=${PGPORT_TEST:-54329}
RUN=""; if [ "$(id -u)" = 0 ]; then chown -R postgres "$DIR"; RUN="runuser -u postgres --"; fi
cleanup() { $RUN "$PGBIN/pg_ctl" -D "$DIR/data" stop -m immediate >/dev/null 2>&1 || true; rm -rf "$DIR"; }
trap cleanup EXIT
$RUN "$PGBIN/initdb" -D "$DIR/data" -U postgres -A trust >/dev/null
$RUN "$PGBIN/pg_ctl" -D "$DIR/data" -o "-p $PORT -k $DIR -c listen_addresses=''" -l "$DIR/log" start -w >/dev/null
PSQL=(psql -h "$DIR" -p "$PORT" -U postgres -d postgres -v ON_ERROR_STOP=1 -q -t -A)
"${PSQL[@]}" -f supabase/tests/supabase_shim.sql
"${PSQL[@]}" -f supabase/migrations/0001_init.sql
"${PSQL[@]}" -f supabase/tests/rls_test.sql 2>&1 | sed "s/^psql:[^ ]* NOTICE:  /  /" | grep -v "^$"
