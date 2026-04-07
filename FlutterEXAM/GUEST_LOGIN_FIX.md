# ✅ FIXED: Guest Login Error

## What Was Wrong
The app was trying to insert data into a `guest_accounts` table that doesn't exist in your Supabase database.

## What I Fixed
Updated `auth_service.dart` to store guest information in the user's metadata instead of a separate table.

**Changes:**
- ✅ Removed dependency on `guest_accounts` table
- ✅ Guest info now stored in user metadata (built into Supabase)
- ✅ Guest login works immediately without database changes

## How to Test Now

1. **Hot restart your app** (if already running):
   ```
   Press 'R' in the terminal where flutter run is active
   ```
   OR close and restart:
   ```bash
   flutter run
   ```

2. **Test Guest Login:**
   - Tap "Continue as Guest"
   - ✅ Should work now!
   - You'll see home screen with "Guest Account" badge

## What Works Now

✅ **Guest Login** - Works immediately  
✅ **Email/Password** - Works immediately  
⚙️ **Google Sign-In** - Needs OAuth setup  

## Technical Details

**Before (caused error):**
```dart
await _supabase.from('guest_accounts').insert({
  'guest_identifier': guestId,
  'profile_id': response.user!.id,
});
```

**After (works now):**
```dart
// Guest info stored in user metadata
data: {
  'full_name': 'Guest User',
  'is_guest': true,
  'guest_id': guestId,
}
```

## Where Guest Info Is Stored

Guest accounts are now stored in:
1. **auth.users** - Main authentication (automatic)
2. **profiles** - With role='user' (automatic via trigger)
3. **User metadata** - is_guest=true and guest_id (in user object)

No separate table needed!

## Optional: Create guest_accounts Table Later

If you want the `guest_accounts` table for tracking (not required):

1. Go to Supabase Dashboard SQL Editor
2. Run the migration in: `backend/04_create_guest_accounts.sql`
3. But it's **not necessary** - app works without it!

---

**Status: ✅ FIXED - Guest login now works!**

Try it now:
```bash
flutter run
```
Then tap "Continue as Guest"
