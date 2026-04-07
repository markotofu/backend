-- Create guest accounts table and functions
-- This enables temporary guest user functionality

-- Create a table to track guest accounts
CREATE TABLE IF NOT EXISTS public.guest_accounts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    guest_identifier TEXT UNIQUE NOT NULL,
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_active TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.guest_accounts ENABLE ROW LEVEL SECURITY;

-- Create policy: Users can view their own guest account
CREATE POLICY "Users can view their own guest account" ON public.guest_accounts
    FOR SELECT USING (auth.uid() = profile_id);

-- Create policy: Anyone can create a guest account
CREATE POLICY "Anyone can create a guest account" ON public.guest_accounts
    FOR INSERT WITH CHECK (true);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_guest_accounts_identifier ON public.guest_accounts(guest_identifier);
CREATE INDEX IF NOT EXISTS idx_guest_accounts_profile ON public.guest_accounts(profile_id);

-- Function to create or retrieve guest user
CREATE OR REPLACE FUNCTION public.create_guest_account(guest_id TEXT)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_user_id UUID;
    guest_email TEXT;
    result jsonb;
BEGIN
    -- Generate a unique email for the guest
    guest_email := 'guest_' || guest_id || '@temp.local';
    
    -- Create anonymous user in auth.users
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        recovery_sent_at,
        last_sign_in_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    )
    VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        guest_email,
        crypt('guest_password_' || guest_id, gen_salt('bf')),
        now(),
        now(),
        now(),
        '{"provider":"guest","providers":["guest"]}',
        jsonb_build_object('full_name', 'Guest User', 'is_guest', true),
        now(),
        now(),
        '',
        '',
        '',
        ''
    )
    RETURNING id INTO new_user_id;
    
    -- The profile will be created automatically by the trigger
    -- Update the profile to set role as guest
    UPDATE public.profiles
    SET role = 'viewer'
    WHERE id = new_user_id;
    
    -- Create guest account record
    INSERT INTO public.guest_accounts (guest_identifier, profile_id)
    VALUES (guest_id, new_user_id);
    
    -- Return the result
    SELECT jsonb_build_object(
        'user_id', new_user_id,
        'email', guest_email,
        'is_guest', true
    ) INTO result;
    
    RETURN result;
END;
$$;

-- Function to cleanup old guest accounts (optional - can be run periodically)
CREATE OR REPLACE FUNCTION public.cleanup_old_guest_accounts(days_old INTEGER DEFAULT 30)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete guest accounts older than specified days
    WITH deleted AS (
        DELETE FROM public.guest_accounts
        WHERE last_active < (now() - (days_old || ' days')::INTERVAL)
        RETURNING profile_id
    )
    SELECT COUNT(*) INTO deleted_count FROM deleted;
    
    RETURN deleted_count;
END;
$$;

COMMENT ON TABLE public.guest_accounts IS 'Tracks temporary guest user accounts';
COMMENT ON FUNCTION public.create_guest_account IS 'Creates a new guest account with viewer role';
COMMENT ON FUNCTION public.cleanup_old_guest_accounts IS 'Removes guest accounts inactive for specified days';
