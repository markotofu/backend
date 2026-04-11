# Backend Setup Guide (Supabase)

Run these scripts in **Supabase Dashboard → SQL Editor**.

## 1) Accounts (required)

1. Run `05_setup_accounts_table.sql`
   - Creates `public.accounts`
   - Enables RLS + policies

2. Run `06_accounts_trigger_on_signup.sql`
   - Creates trigger on `auth.users` to auto-create `public.accounts`
   - Backfills existing users missing an account

## 2) Reporting + pins schema (required)

3. Run `09_zones_traffic_incidents.sql`
   - Creates `zones`, `traffic`, `incidents`, `traffic_log` + enums
   - Enables RLS + policies

## 3) Optional: set an account role for testing

To test incident reporting, update your account role to `ADMIN` or `CTTMO`:

```sql
UPDATE public.accounts
SET role = 'ADMIN'
WHERE auth_user_id = auth.uid();
```

Regular `User` accounts can only report traffic.

## Troubleshooting

- If signups don’t create `public.accounts`, run `07_fix_accounts_autocreate.sql`.
- Avoid using `DISABLE_RLS.sql` / `QUICK_FIX_ACCOUNTS.sql` unless you’re only doing local testing.
