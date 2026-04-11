-- Setup for accounts table (schema + RLS only)
-- Run this in Supabase SQL Editor BEFORE 06_accounts_trigger_on_signup.sql

-- Ensure enum exists (for fresh setups)
-- Note: the trigger script inserts only auth_user_id + username, so it works even if
-- your role column is text/enum and regardless of enum casing.
CREATE EXTENSION IF NOT EXISTS pgcrypto;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 'account_role_enum'
      AND n.nspname = 'public'
  ) THEN
    CREATE TYPE public.account_role_enum AS ENUM ('User', 'ADMIN', 'CTTMO');
  END IF;
END $$;

-- Ensure accounts table exists with correct schema
CREATE TABLE IF NOT EXISTS public.accounts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    username TEXT,
    role public.account_role_enum DEFAULT 'User'::public.account_role_enum NOT NULL,
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    isActive BOOLEAN DEFAULT true NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

-- Create policies for accounts table (idempotent)
DROP POLICY IF EXISTS "Users can view their own account" ON public.accounts;
CREATE POLICY "Users can view their own account" ON public.accounts
    FOR SELECT USING (auth.uid() = auth_user_id);

DROP POLICY IF EXISTS "Users can insert their own account" ON public.accounts;
CREATE POLICY "Users can insert their own account" ON public.accounts
    FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

DROP POLICY IF EXISTS "Users can update their own account" ON public.accounts;
CREATE POLICY "Users can update their own account" ON public.accounts
    FOR UPDATE USING (auth.uid() = auth_user_id)
    WITH CHECK (auth.uid() = auth_user_id);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_accounts_auth_user_id ON public.accounts(auth_user_id);

-- NOTE
-- Auto-creation trigger + backfill were moved to:
--   backend/06_accounts_trigger_on_signup.sql
--
-- Keep this file focused on the table + RLS policies.
