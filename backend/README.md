# Flutter + Supabase Backend

This backend integrates Supabase for authentication and location mapping features.

## Project Structure

```
backend/
├── .env                    # Environment variables (DO NOT COMMIT)
├── .env.example           # Example environment variables
├── supabase/
│   └── migrations/        # Database migrations
│       ├── 20240101_create_locations_table.sql
│       └── 20240102_create_user_profiles_table.sql
└── README.md
```

## Supabase Configuration

**Project URL:** https://wkfbcdpsbjblsflcvcks.supabase.co  
**Project ID:** wkfbcdpsbjblsflcvcks

### Environment Variables

Copy `.env.example` to `.env` and fill in your credentials (already configured).

## Database Schema

### Tables

#### 1. `locations` - Store map locations
- `id` (UUID) - Primary key
- `user_id` (UUID) - Foreign key to auth.users
- `title` (VARCHAR) - Location title
- `description` (TEXT) - Location description
- `latitude` (DOUBLE) - Latitude coordinate
- `longitude` (DOUBLE) - Longitude coordinate
- `address` (TEXT) - Human-readable address
- `category` (VARCHAR) - Location category
- `image_url` (TEXT) - Optional image
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### 2. `profiles` - User profiles
- `id` (UUID) - Primary key (references auth.users)
- `username` (VARCHAR) - Unique username
- `full_name` (VARCHAR) - User's full name
- `avatar_url` (TEXT) - Profile picture URL
- `bio` (TEXT) - User biography
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

## Setting Up Database

### Option 1: Using Supabase Dashboard
1. Go to https://supabase.com/dashboard/project/wkfbcdpsbjblsflcvcks/editor
2. Click on "SQL Editor"
3. Copy and paste each migration file from `supabase/migrations/`
4. Run them in order

### Option 2: Using Supabase CLI
```bash
# Install Supabase CLI
npm install -g supabase

# Link to your project
supabase link --project-ref wkfbcdpsbjblsflcvcks

# Run migrations
supabase db push
```

## Row Level Security (RLS)

All tables have RLS enabled with the following policies:

**Locations:**
- Anyone can view all locations
- Users can only create, update, and delete their own locations

**Profiles:**
- Anyone can view all profiles
- Users can only create and update their own profile

## Authentication

Supabase Auth is configured with:
- Email/Password authentication
- OAuth providers (configure in Supabase Dashboard)
- Automatic profile creation on signup

## Flutter Integration

Add to your Flutter project's `pubspec.yaml`:
```yaml
dependencies:
  supabase_flutter: ^2.0.0
```

Initialize Supabase in your Flutter app:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

await Supabase.initialize(
  url: 'https://wkfbcdpsbjblsflcvcks.supabase.co',
  anonKey: 'your_anon_key_here',
);
```

## API Examples

### Authentication
```dart
// Sign up
await Supabase.instance.client.auth.signUp(
  email: 'user@example.com',
  password: 'password123',
);

// Sign in
await Supabase.instance.client.auth.signInWithPassword(
  email: 'user@example.com',
  password: 'password123',
);

// Sign out
await Supabase.instance.client.auth.signOut();
```

### Locations CRUD
```dart
// Create location
await Supabase.instance.client.from('locations').insert({
  'user_id': Supabase.instance.client.auth.currentUser!.id,
  'title': 'My Location',
  'description': 'A great place',
  'latitude': 40.7128,
  'longitude': -74.0060,
  'address': 'New York, NY',
  'category': 'restaurant',
});

// Read locations
final locations = await Supabase.instance.client
  .from('locations')
  .select()
  .order('created_at', ascending: false);

// Update location
await Supabase.instance.client
  .from('locations')
  .update({'title': 'Updated Title'})
  .eq('id', locationId);

// Delete location
await Supabase.instance.client
  .from('locations')
  .delete()
  .eq('id', locationId);
```

## Next Steps

1. ✅ Set up environment variables
2. ⬜ Run database migrations in Supabase Dashboard
3. ⬜ Configure authentication providers (optional)
4. ⬜ Add storage bucket for location images (optional)
5. ⬜ Integrate with Flutter app

## Security Notes

- `.env` is gitignored to protect your API keys
- Never commit real API keys to version control
- The anon key is safe to use in client applications
- RLS policies protect your data at the database level
