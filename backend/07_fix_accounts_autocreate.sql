-- Legacy helper (cleaned up)
--
-- In this repo, the canonical scripts are:
--   05_setup_accounts_table.sql       (table + RLS)
--   06_accounts_trigger_on_signup.sql (trigger + backfill)
--
-- Keep this file as an "emergency fix" for projects that already ran older versions.
-- It only does safe, focused actions:
-- - remove username uniqueness (clashes allowed)
-- - ensure trigger exists
-- - backfill missing accounts

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Drop any UNIQUE constraint/index on username (older versions sometimes enforced this)
DO $$
DECLARE
  c record;
BEGIN
  FOR c IN
    SELECT conname
    FROM pg_constraint
    WHERE conrelid = 'public.accounts'::regclass
      AND contype = 'u'
      AND pg_get_constraintdef(oid) ILIKE '%(username)%'
  LOOP
    EXECUTE format(
      'ALTER TABLE public.accounts DROP CONSTRAINT IF EXISTS %I',
      c.conname
    );
  END LOOP;
END $$;

DROP INDEX IF EXISTS public.uniq_accounts_username;

-- Ensure unique index exists for ON CONFLICT(auth_user_id)
CREATE UNIQUE INDEX IF NOT EXISTS uniq_accounts_auth_user_id
  ON public.accounts(auth_user_id);

-- Recreate trigger function (same logic as 06)
CREATE OR REPLACE FUNCTION public.handle_new_user_account()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  base_username text;
BEGIN
  base_username := COALESCE(
    NULLIF(NEW.raw_user_meta_data->>'username', ''),
    LOWER(SPLIT_PART(COALESCE(NEW.email, ''), '@', 1)),
    'user' || EXTRACT(EPOCH FROM NOW())::TEXT
  );

  base_username := LOWER(base_username);
  base_username := regexp_replace(base_username, '[^a-z0-9_.-]+', '_', 'g');
  base_username := regexp_replace(base_username, '[_\.\-]{2,}', '_', 'g');
  base_username := regexp_replace(base_username, '^[_\.\-]+', '', 'g');
  base_username := regexp_replace(base_username, '[_\.\-]+$', '', 'g');

  IF base_username IS NULL OR base_username = '' THEN
    base_username := 'user' || EXTRACT(EPOCH FROM NOW())::TEXT;
  END IF;

  base_username := left(base_username, 30);

  INSERT INTO public.accounts (auth_user_id, username)
  VALUES (NEW.id, base_username)
  ON CONFLICT (auth_user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_account ON auth.users;
CREATE TRIGGER on_auth_user_created_account
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user_account();

-- Backfill missing accounts
DO $$
DECLARE
  r record;
  base_username text;
BEGIN
  FOR r IN
    SELECT au.id, au.email, au.raw_user_meta_data
    FROM auth.users au
    LEFT JOIN public.accounts a ON a.auth_user_id = au.id
    WHERE a.auth_user_id IS NULL
  LOOP
    base_username := COALESCE(
      NULLIF(r.raw_user_meta_data->>'username', ''),
      LOWER(SPLIT_PART(COALESCE(r.email, ''), '@', 1)),
      'user' || EXTRACT(EPOCH FROM NOW())::TEXT
    );

    base_username := LOWER(base_username);
    base_username := regexp_replace(base_username, '[^a-z0-9_.-]+', '_', 'g');
    base_username := regexp_replace(base_username, '[_\.\-]{2,}', '_', 'g');
    base_username := regexp_replace(base_username, '^[_\.\-]+', '', 'g');
    base_username := regexp_replace(base_username, '[_\.\-]+$', '', 'g');

    IF base_username IS NULL OR base_username = '' THEN
      base_username := 'user' || EXTRACT(EPOCH FROM NOW())::TEXT;
    END IF;

    base_username := left(base_username, 30);

    INSERT INTO public.accounts (auth_user_id, username)
    VALUES (r.id, base_username)
    ON CONFLICT (auth_user_id) DO NOTHING;
  END LOOP;
END $$;

-- Diagnostics: should return 0 rows
SELECT au.id, au.email, au.created_at
FROM auth.users au
LEFT JOIN public.accounts a ON a.auth_user_id = au.id
WHERE a.auth_user_id IS NULL
ORDER BY au.created_at DESC
LIMIT 20;
