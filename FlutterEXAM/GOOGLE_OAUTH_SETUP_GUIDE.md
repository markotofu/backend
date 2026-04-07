# 🔐 Google Sign-In Setup - Step by Step

## Your Info (Keep This Handy)
```
Package Name: com.example.flutter_exam
SHA-1 (debug): A0:5A:4F:ED:FA:9A:B1:E2:C2:D2:45:59:A0:08:4D:9D:9A:85:95:2B
Supabase URL: https://wkfbcdpsbjblsflcvcks.supabase.co
Redirect URI: https://wkfbcdpsbjblsflcvcks.supabase.co/auth/v1/callback
```

---

## 📋 Step 1: Google Cloud Console Setup (5 minutes)

### 1.1 Create Project
1. Go to: https://console.cloud.google.com
2. Click **Select a project** (top left) → **NEW PROJECT**
3. Project name: `Flutter Exam App`
4. Click **CREATE**
5. Wait ~10 seconds, then select the new project

### 1.2 Configure OAuth Consent Screen
1. Go to: **APIs & Services** → **OAuth consent screen** (left sidebar)
2. Select **External** → Click **CREATE**
3. Fill in:
   - App name: `Flutter Exam App`
   - User support email: `your.email@example.com`
   - Developer contact: `your.email@example.com`
4. Click **SAVE AND CONTINUE**
5. Skip "Scopes" → **SAVE AND CONTINUE**
6. Add test users → Add your email → **SAVE AND CONTINUE**
7. Click **BACK TO DASHBOARD**

### 1.3 Create Android OAuth Credentials
1. Go to: **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Application type: **Android**
4. Fill in:
   - Name: `Flutter Exam Android`
   - Package name: `com.example.flutter_exam`
   - SHA-1: `A0:5A:4F:ED:FA:9A:B1:E2:C2:D2:45:59:A0:08:4D:9D:9A:85:95:2B`
5. Click **CREATE**
6. Click **OK** (you don't need to download anything)

### 1.4 Create Web OAuth Credentials (For Supabase)
1. Still in **Credentials** page
2. Click **+ CREATE CREDENTIALS** → **OAuth client ID** again
3. Application type: **Web application**
4. Fill in:
   - Name: `Flutter Exam Web`
   - Authorized redirect URIs → Click **+ ADD URI**:
     - `https://wkfbcdpsbjblsflcvcks.supabase.co/auth/v1/callback`
5. Click **CREATE**
6. **⚠️ IMPORTANT**: Copy these and save them:
   ```
   Client ID: [looks like xxx.apps.googleusercontent.com]
   Client Secret: [looks like GOCSPX-xxx]
   ```

---

## 📋 Step 2: Supabase Configuration (2 minutes)

### 2.1 Enable Google Provider
1. Go to: https://supabase.com/dashboard/project/wkfbcdpsbjblsflcvcks
2. Click **Authentication** (left sidebar)
3. Click **Providers** tab
4. Find **Google** and click to expand
5. Toggle **Enable Sign in with Google** to ON
6. Fill in:
   - **Client ID (for OAuth)**: Paste Web Client ID from Step 1.4
   - **Client Secret (for OAuth)**: Paste Web Client Secret from Step 1.4
7. Click **Save**

---

## 📋 Step 3: Update Flutter Code (1 minute)

### Option A: If you want server-side auth (recommended)
No code changes needed! Just restart the app.

### Option B: Provide Web Client ID to Flutter (required for ID token)
This project reads the Web OAuth Client ID at build/run time.

Run:
```bash
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

(Find it in Google Cloud Console → Credentials → OAuth 2.0 Client IDs → Web client.)

---

## 📋 Step 4: Test It! (1 minute)

1. Restart Flutter app:
   ```bash
   flutter run
   ```

2. Tap **"Continue with Google (ADDU)"**

3. Select your Google account

4. ✅ Should log in successfully!

---

## 🐛 Troubleshooting

### Still getting "ApiException: 10"?
- Double-check SHA-1 is exactly: `A0:5A:4F:ED:FA:9A:B1:E2:C2:D2:45:59:A0:08:4D:9D:9A:85:95:2B`
- Verify package name is: `com.example.flutter_exam`
- Wait 5 minutes after creating credentials (Google needs to propagate)

### "Access blocked" or "Authorization Error"?
- Make sure you added your email as a test user in OAuth consent screen
- Make sure app is in "Testing" mode (not published)

### "Network error" or "Failed to connect"?
- Check internet connection
- Make sure Supabase URL is correct in config

---

## 📝 Summary Checklist

- [ ] Create Google Cloud project
- [ ] Configure OAuth consent screen
- [ ] Create Android OAuth client (with SHA-1)
- [ ] Create Web OAuth client (for Supabase)
- [ ] Copy Web Client ID + Secret
- [ ] Enable Google in Supabase Auth Providers
- [ ] Paste Client ID + Secret in Supabase
- [ ] (Optional) Update Flutter code with server client ID
- [ ] Restart Flutter app
- [ ] Test Google Sign-In

---

## 🎯 Expected Result

After setup:
1. Tap "Continue with Google (ADDU)"
2. Google sign-in screen appears
3. Select your account
4. See home screen with your profile ✅
5. Check Supabase → Table Editor → accounts
6. See new account with role='USER' ✅

---

**Estimated Time**: 8-10 minutes total

**Need help?** If you get stuck at any step, tell me which step and what error you're seeing!
