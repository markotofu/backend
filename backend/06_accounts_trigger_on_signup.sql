-- Auto-create public.accounts rows when a new auth.users row is created
-- Safe to re-run (idempotent). Run in Supabase SQL Editor AFTER 05_setup_accounts_table.sql.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Ensure ON CONFLICT(auth_user_id) works (older schemas sometimes missed a UNIQUE constraint)
CREATE UNIQUE INDEX IF NOT EXISTS uniq_accounts_auth_user_id
  ON public.accounts(auth_user_id);

-- Trigger function
-- - pulls username from raw_user_meta_data.username OR email prefix
-- - sanitizes (allows a-z 0-9 _ . -)
-- - does NOT enforce uniqueness (clashes allowed)
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

-- Create trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created_account ON auth.users;
CREATE TRIGGER on_auth_user_created_account
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user_account();

-- Backfill for existing users missing accounts
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
