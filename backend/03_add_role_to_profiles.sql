-- Add role field to profiles table
-- This migration adds a role column to track user permissions

-- Add role column with default value 'viewer'
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'viewer' NOT NULL;

-- Create index for faster role-based queries
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- Add constraint to ensure valid roles
ALTER TABLE public.profiles 
ADD CONSTRAINT check_valid_role 
CHECK (role IN ('viewer', 'admin', 'editor', 'guest'));

-- Update existing profiles to have 'viewer' role if null
UPDATE public.profiles 
SET role = 'viewer' 
WHERE role IS NULL;

-- Comment on the column
COMMENT ON COLUMN public.profiles.role IS 'User role: viewer (default), admin, editor, or guest';
