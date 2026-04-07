# Quick Setup Guide

## 1. Run Database Migrations

Go to your Supabase SQL Editor:
👉 https://supabase.com/dashboard/project/wkfbcdpsbjblsflcvcks/sql/new

### Step 1: Create Locations Table
Copy the contents of `supabase/migrations/20240101_create_locations_table.sql` and run it.

### Step 2: Create Profiles Table
Copy the contents of `supabase/migrations/20240102_create_user_profiles_table.sql` and run it.

## 2. (Optional) Set Up Storage Buckets

If you want to store location images and user avatars:

1. Go to Storage: https://supabase.com/dashboard/project/wkfbcdpsbjblsflcvcks/storage/buckets
2. Create bucket: `location-images` (Public)
3. Create bucket: `avatars` (Public)

### Storage Policies

For each bucket, add these policies:

**Allow public read:**
```sql
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'location-images' );
```

**Allow authenticated users to upload:**
```sql
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'location-images' 
  AND auth.role() = 'authenticated'
);
```

**Allow users to delete their own files:**
```sql
CREATE POLICY "Users can delete own files"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'location-images' 
  AND auth.uid() = owner
);
```

## 3. Configure Authentication (Optional)

Enable additional auth providers:
https://supabase.com/dashboard/project/wkfbcdpsbjblsflcvcks/auth/providers

- Google OAuth
- Apple Sign In
- GitHub
- etc.

## 4. Test Your Setup

Use the Supabase API Explorer:
https://supabase.com/dashboard/project/wkfbcdpsbjblsflcvcks/api

## 5. Flutter Integration

See `README.md` for Flutter code examples.

## Troubleshooting

### Can't insert data?
- Check that migrations ran successfully
- Verify RLS policies are enabled
- Make sure you're authenticated

### Authentication not working?
- Check that email auth is enabled in Supabase Dashboard
- Verify your API keys are correct
- Check if email confirmations are required

### Need help?
- Supabase Docs: https://supabase.com/docs
- Flutter Supabase Package: https://pub.dev/packages/supabase_flutter
