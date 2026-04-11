# Backend (Supabase SQL)

This folder contains the SQL you run in **Supabase Dashboard → SQL Editor** to create the schema used by the Flutter app.

## What the app uses

### Accounts (auto-created on signup)
- `public.accounts` is linked to `auth.users` via `auth_user_id`
- Trigger on `auth.users` inserts a matching row into `public.accounts`

### Reporting + pins schema
- `public.zones` (district_name + lat/lon)
- `public.traffic`
- `public.incidents`
- `public.traffic_log`
- Enums for roles/status/types

## Run order (recommended)

Run these in Supabase SQL Editor, in order:

1. `05_setup_accounts_table.sql` (accounts table + RLS policies)
2. `06_accounts_trigger_on_signup.sql` (trigger + backfill for accounts)
3. `09_zones_traffic_incidents.sql` (zones/traffic/incidents schema + RLS)

## Legacy / troubleshooting scripts

These exist for older versions or quick testing:
- `07_fix_accounts_autocreate.sql` → emergency fix for account auto-creation (safe to re-run)
- `08_incidents_table.sql` → old single-table incident markers (not used by the new schema)
- `DISABLE_RLS.sql`, `QUICK_FIX_ACCOUNTS.sql` → testing only (not recommended for production)
