# ✅ ACCOUNTS TABLE INTEGRATION

## Your Actual Schema

You have an **`accounts`** table (not profiles) with:
```
id: BIGSERIAL (auto-increment)
created_at: TIMESTAMP
username: VARCHAR(255)
role: ENUM ('ADMIN', 'USER', 'CTTMO')
auth_user_id: UUID (links to auth.users.id)
isactive: BOOLEAN (stored lowercase in Postgres unless quoted)
```

## What I Fixed

### 1. Updated Flutter Code
Changed `auth_service.dart` to use **`accounts`** table instead of `profiles`:
- ✅ Inserts into `accounts` table
- ✅ Uses `auth_user_id` to link to auth.users
- ✅ Sets role to 'USER' (matches your enum)
- ✅ Sets active flag (via DB default true)
- ✅ Generates username from email

### 2. Created SQL Setup Script
File: `backend/05_setup_accounts_table.sql`

Run this in Supabase SQL Editor to:
- ✅ Ensure accounts table has correct structure
- ✅ Create auto-trigger for new signups
- ✅ Create accounts for existing users
- ✅ Set up Row Level Security policies

## 🚀 How to Apply Changes

### Step 1: Run SQL Script in Supabase

1. Go to Supabase Dashboard → **SQL Editor**
2. Copy all contents from `backend/05_setup_accounts_table.sql`
3. Paste and click **Run**
4. ✅ Should see success message

### Step 2: Update Flutter App

```bash
# Press 'R' to hot restart
# OR stop and run:
flutter run
```

### Step 3: Test

1. Sign up with new account
2. Check Supabase → **Table Editor** → **accounts**
3. ✅ Should see new row with:
   - username: (from email)
   - role: USER
   - auth_user_id: (UUID linking to auth.users)
   - active: true (default)

## 📊 Data Flow

### When User Signs Up: `test@example.com`

**Step 1: Auth user created**
```
auth.users:
  id: abc-123-def-456
  email: test@example.com
  created_at: 2026-04-07
```

**Step 2: Trigger fires → Account created**
```
accounts:
  id: 1 (auto-increment)
  auth_user_id: abc-123-def-456
  username: test
  role: USER
  active: true (default)
  created_at: 2026-04-07
```

**Step 3: Flutter app also calls upsert (as backup)**
```dart
await _supabase.from('accounts').upsert({
  'auth_user_id': userId,
  'username': 'test',
  'role': 'USER',
  // active flag uses DB default
});
```

## 🔍 How Tables Link

```
auth.users                   accounts
┌──────────────┐            ┌──────────────────┐
│ id (UUID)    │◄───────────│ auth_user_id     │
│ email        │            │ username         │
│ password     │            │ role (USER)      │
│ created_at   │            │ active (default) │
└──────────────┘            └──────────────────┘
```

## 🔧 Updated Code Behavior

### `_ensureUserRole()` now:
```dart
await _supabase.from('accounts').upsert({
  'auth_user_id': userId,      // Links to auth.users.id
  'username': 'test',          // From email prefix
  'role': 'USER',              // Default role
  // active flag uses DB default
}, onConflict: 'auth_user_id'); // Prevents duplicates
```

### `getUserProfile()` now:
```dart
await _supabase
  .from('accounts')              // Changed from 'profiles'
  .select()
  .eq('auth_user_id', userId)    // Changed from 'id'
  .single();
```

## ✅ What Gets Stored

| Field | Value | Example |
|-------|-------|---------|
| id | Auto-generated | 1, 2, 3... |
| created_at | Current timestamp | 2026-04-07 06:57:20 |
| username | Email prefix | test |
| role | 'USER' (default) | USER |
| auth_user_id | User's UUID | abc-123-def-456 |
| isactive (DB column) | true (default) | true |

## 🧪 Testing

### Test Email/Password:
```
1. Press 'R' to restart app
2. Sign up: test@example.com / password123
3. Go to Supabase → Table Editor → accounts
4. Refresh
5. ✅ See: username='test', role='USER', active=true (default)
```

### Test Guest Login:
```
1. Tap "Continue as Guest"
2. Check accounts table
3. ✅ See: username='user{timestamp}', role='USER'
```

## 📝 Role Values

Your role enum supports:
- **USER** - Default for all signups (mobile requirement ✅)
- **ADMIN** - Admin users
- **CTTMO** - CTTMO users

Flutter app defaults all new accounts to **'USER'** as required.

## 🔒 Security (RLS Policies)

The SQL script creates these policies:
- ✅ Users can view their own account
- ✅ Users can insert their own account
- ✅ Users can update their own account
- ✅ Prevents users from seeing other accounts

## 🐛 Troubleshooting

### "Relation accounts does not exist"
- Run the SQL script to create the table

### "Duplicate key value violates unique constraint"
- The trigger is working! Account already exists
- Code uses `upsert` so it updates instead

### "Permission denied for table accounts"
- Check RLS policies are created
- Make sure user is authenticated

### Accounts not showing up
1. Check **Authentication → Users** (should see auth user)
2. Check **Table Editor → accounts** (should see account)
3. Refresh the table
4. Run: `SELECT * FROM accounts ORDER BY created_at DESC;`

## 🎯 Summary

**Before (wrong):**
```dart
await _supabase.from('profiles').update({...})
```

**After (correct):**
```dart
await _supabase.from('accounts').upsert({
  'auth_user_id': userId,
  'username': username,
  'role': 'USER',
  // active flag uses DB default
})
```

---

**Status: ✅ Updated to use accounts table!**

Steps:
1. Run `backend/05_setup_accounts_table.sql` in Supabase
2. Press 'R' to restart Flutter app
3. Test signup
4. Check accounts table ✅
