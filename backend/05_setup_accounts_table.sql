-- Setup for accounts table with auto-creation on user signup
-- Run this in Supabase SQL Editor

-- Ensure accounts table exists with correct schema
CREATE TABLE IF NOT EXISTS public.accounts (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    username VARCHAR(255),
    role VARCHAR(50) DEFAULT 'USER' CHECK (role IN ('ADMIN', 'USER', 'CTTMO')),
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
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

-- Function to auto-create account when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user_account()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.accounts (auth_user_id, username, role, isActive)
    VALUES (
        NEW.id,
        COALESCE(
            LOWER(SPLIT_PART(NEW.email, '@', 1)),
            'user' || EXTRACT(EPOCH FROM NOW())::TEXT
        ),
        'USER',
        true
    )
    ON CONFLICT (auth_user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to auto-create account on signup
DROP TRIGGER IF EXISTS on_auth_user_created_account ON auth.users;
CREATE TRIGGER on_auth_user_created_account
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_account();

-- Create accounts for existing users that don't have one
INSERT INTO public.accounts (auth_user_id, username, role, isActive)
SELECT 
    au.id,
    COALESCE(
        LOWER(SPLIT_PART(au.email, '@', 1)),
        'user' || EXTRACT(EPOCH FROM NOW())::TEXT
    ) as username,
    'USER' as role,
    true as isActive
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM public.accounts a WHERE a.auth_user_id = au.id
)
ON CONFLICT (auth_user_id) DO NOTHING;

-- Verify setup
SELECT 
    'Total auth users' as metric,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Total accounts' as metric,
    COUNT(*) as count
FROM public.accounts;
