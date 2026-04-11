-- Quick Fix: Allow users to create accounts
-- Copy this entire script and run it in Supabase SQL Editor

-- Step 1: Disable RLS temporarily to allow inserts
ALTER TABLE public.accounts DISABLE ROW LEVEL SECURITY;

-- Step 2: Create a more permissive policy for testing
DROP POLICY IF EXISTS "Anyone can insert account" ON public.accounts;
CREATE POLICY "Anyone can insert account" ON public.accounts
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Anyone can view accounts" ON public.accounts;
CREATE POLICY "Anyone can view accounts" ON public.accounts
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update their own account" ON public.accounts;
CREATE POLICY "Users can update their own account" ON public.accounts
    FOR UPDATE USING (auth.uid() = auth_user_id);

-- Step 3: Re-enable RLS
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

-- Step 4: Create trigger for auto-account creation
CREATE OR REPLACE FUNCTION public.handle_new_user_account()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.accounts (auth_user_id, username)
    VALUES (
        NEW.id,
        COALESCE(
            NULLIF(NEW.raw_user_meta_data->>'username', ''),
            LOWER(SPLIT_PART(COALESCE(NEW.email, ''), '@', 1)),
            'user' || EXTRACT(EPOCH FROM NOW())::TEXT
        )
    )
    ON CONFLICT (auth_user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created_account ON auth.users;
CREATE TRIGGER on_auth_user_created_account
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_account();

-- Step 5: Verify
SELECT 'Setup complete!' as status;
