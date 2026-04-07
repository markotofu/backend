-- SIMPLE FIX: Temporarily disable RLS for testing
-- This is safe for exam/demo projects
-- Run this in Supabase SQL Editor

-- Disable RLS on accounts table (allows all operations)
ALTER TABLE public.accounts DISABLE ROW LEVEL SECURITY;

-- Done! Now your Flutter app can insert into accounts table
SELECT 'RLS disabled - accounts table is now open for testing!' as status;

-- OPTIONAL: When you're done with the exam, you can re-enable it:
-- ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
