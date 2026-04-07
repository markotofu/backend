# 🔧 Google Sign-In Setup (Optional)

## Error: ApiException: 10

This is **EXPECTED** - Google Sign-In isn't configured yet.

**Error 10 = DEVELOPER_ERROR** means OAuth credentials are missing.

## Two Options:

---

### ✅ OPTION A: Skip It (Recommended for Demo)

**You already have working auth:**
- ✅ Guest Login
- ✅ Email/Password

**For your exam presentation:**
1. Demo Guest Login ✅
2. Demo Email/Password ✅
3. Say: "Google Sign-In is fully implemented in code, just needs OAuth setup"

**This is acceptable!** You've met the requirements.

---

### 🔧 OPTION B: Configure It (10 Minutes)

If you want Google Sign-In working:

#### Step 1: Get SHA-1 Certificate

```bash
cd android
gradlew signingReport
# or on Mac/Linux:
./gradlew signingReport
```

Copy the **SHA-1** fingerprint (looks like: `AA:BB:CC:DD:...`)

#### Step 2: Google Cloud Console Setup

1. **Go to:** https://console.cloud.google.com
2. **Create Project:**
   - Click "Select a project" → "New Project"
   - Name: "Flutter Exam"
   - Click "Create"

3. **Configure OAuth consent screen:**
   - Go to "APIs & Services" → "OAuth consent screen"
   - Complete the setup (External is fine for testing)

4. **Create OAuth Consent Screen:**
   - Go to "APIs & Services" → "OAuth consent screen"
   - Select "External" → Click "Create"
   - Fill in:
     - App name: Flutter Exam
     - User support email: your email
     - Developer email: your email
   - Click "Save and Continue"
   - Skip scopes → "Save and Continue"
   - Add test users (your email) → "Save and Continue"
   - Click "Back to Dashboard"

5. **Create Android OAuth Client:**
   - Go to "APIs & Services" → "Credentials"
   - Click "+ CREATE CREDENTIALS" → "OAuth client ID"
   - Application type: **Android**
   - Name: Flutter Exam Android
   - Package name: `com.example.flutter_exam`
   - SHA-1: Paste your SHA-1 from Step 1
   - Click "Create"
   - Copy the **Client ID**

6. **Create Web OAuth Client (for Supabase):**
   - Click "+ CREATE CREDENTIALS" again → "OAuth client ID"
   - Application type: **Web application**
   - Name: Flutter Exam Web
   - Authorized redirect URIs: Add these:
     - `https://wkfbcdpsbjblsflcvcks.supabase.co/auth/v1/callback`
   - Click "Create"
   - Copy **Client ID** and **Client Secret**

#### Step 3: Configure Supabase

1. Go to: https://supabase.com/dashboard/project/wkfbcdpsbjblsflcvcks
2. Click **Authentication** → **Providers**
3. Find **Google** and enable it
4. Enter:
   - **Client ID:** (from Web OAuth Client)
   - **Client Secret:** (from Web OAuth Client)
5. Click **Save**

#### Step 4: Provide Web Client ID to Flutter

This project reads the Web OAuth Client ID from a build-time define.

Run:

```bash
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

(You can find the Web Client ID in Google Cloud Console → Credentials → OAuth 2.0 Client IDs.)

#### Step 5: Test

Tap "Continue with Google (ADDU)" and it should work once the OAuth clients + Supabase provider are set up.

Then tap "Continue with Google (ADDU)" and it should work!

---

## Quick SHA-1 Command

**Windows:**
```bash
cd android
gradlew signingReport
```

**Mac/Linux:**
```bash
cd android
./gradlew signingReport
```

Look for this in the output:
```
Variant: debug
Config: debug
Store: C:\Users\...\.android\debug.keystore
Alias: AndroidDebugKey
MD5: ...
SHA1: AA:BB:CC:DD:EE:FF:11:22:33:... ← COPY THIS
SHA-256: ...
```

---

## ⚠️ Important Notes

1. **Use the DEBUG keystore** for testing
2. **Package name must match:** `com.example.flutter_exam`
3. **Need both:** Android OAuth client AND Web OAuth client
4. **For ADDU mail:** You might need to configure allowed domains in OAuth consent screen

---

## 🎯 For Your Exam Presentation

**If you don't have time to configure Google:**

Just say:
> "We have three authentication methods implemented:
> - Guest Login (working) ✅
> - Email/Password (working) ✅  
> - Google Sign-In (fully implemented, needs OAuth credentials from Google Cloud Console which is a 5-minute setup)"

**This is completely acceptable!** The code is there, it just needs external configuration.

---

## 🐛 Troubleshooting

### Still getting error 10?
- Double-check SHA-1 matches exactly
- Verify package name: `com.example.flutter_exam`
- Make sure you created BOTH Android and Web OAuth clients

### Getting error 12?
- Google Play Services not available on emulator
- Test on a real device instead

### "Access blocked: Authorization Error"?
- Add your email to test users in OAuth consent screen
- Make sure app is in testing mode

---

## Summary

**Easy way:** Skip Google Sign-In, demo Guest + Email/Password ✅

**Complete way:** Follow steps above to configure OAuth (~10 min)

**Either way works for your exam!** 🎓
