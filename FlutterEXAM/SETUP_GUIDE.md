# 🚀 Quick Start Guide - Flutter Mobile Authentication

## Before Running the App

### Step 1: Install Flutter Dependencies
```bash
cd FlutterEXAM
flutter pub get
```

This will install:
- supabase_flutter
- google_sign_in
- shared_preferences
- uuid

### Step 2: Check Your Flutter Setup
```bash
flutter doctor
```

Make sure you have:
- ✅ Flutter SDK installed
- ✅ Android Studio or Xcode installed
- ✅ Device/Emulator connected

### Step 3: Run the App
```bash
flutter run
```

## 🧪 Testing the Authentication

### 1. Test Email/Password Authentication (Works Immediately!)

**Sign Up:**
1. Launch the app
2. Tap "Sign Up" at the bottom
3. Enter:
   - Full Name: Test User
   - Email: test@example.com
   - Password: password123
4. Tap "Create Account"
5. ✅ You should be logged in and see the home screen

**Sign In:**
1. Sign out from home screen
2. Enter the same email and password
3. Tap "Sign In"
4. ✅ You should be logged in

### 2. Test Guest Login (Works Immediately!)

1. Launch the app
2. Tap "Continue as Guest"
3. ✅ You should be logged in immediately
4. Check home screen - you'll see "Guest Account" badge
5. Check role - should show "user"

### 3. Test Google Sign-In (Requires Setup)

⚠️ Google Sign-In needs additional configuration:

#### For Android:

1. **Get SHA-1 Certificate:**
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Copy the SHA-1 fingerprint

2. **Google Cloud Console:**
   - Go to https://console.cloud.google.com
   - Create a new project or select existing
   - Enable Google+ API
   - Go to Credentials → Create OAuth 2.0 Client ID
   - Select "Android"
   - Paste your SHA-1 fingerprint
   - Package name: `com.example.flutter_exam`
   - Create and download JSON

3. **Supabase Configuration:**
   - Go to your Supabase Dashboard
   - Navigate to Authentication → Providers
   - Enable Google provider
   - Add your OAuth Client ID and Secret
   - Save changes

4. **Test:**
   - Tap "Continue with Google (ADDU)"
   - Select your ADDU Google account
   - ✅ You should be logged in

#### For iOS:

1. **Get OAuth Client ID from Google Cloud Console**

2. **Add to Info.plist:**
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>YOUR_REVERSED_CLIENT_ID</string>
       </array>
     </dict>
   </array>
   ```

3. **Test on real iOS device**

## ✅ Verification Checklist

After testing, verify:
- [ ] Email/Password signup creates account
- [ ] Email/Password login works
- [ ] Guest login creates temporary account
- [ ] Google Sign-In works (if configured)
- [ ] All accounts show "user" role on home screen
- [ ] User profile displays correctly
- [ ] Sign out works
- [ ] Session persists (close and reopen app)

## 🐛 Troubleshooting

### "Flutter command not found"
```bash
# Add Flutter to PATH or use full path
export PATH="$PATH:/path/to/flutter/bin"
```

### "No devices found"
```bash
# Check connected devices
flutter devices

# Start an emulator
flutter emulators
flutter emulators --launch <emulator_id>
```

### "Supabase error" or "Auth error"
- Check internet connection
- Verify Supabase credentials in `lib/supabase_config.dart`
- Check Supabase dashboard for service status

### Google Sign-In not working
- Ensure OAuth is configured in Google Cloud Console
- Verify SHA-1 fingerprint is correct
- Test on a real device with Google Play Services
- Check Supabase Google provider is enabled

### Build errors after `flutter pub get`
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## 📊 Expected Results

### Home Screen Should Show:
1. User's name and email
2. Role badge showing "user"
3. Guest badge (if logged in as guest)
4. User ID
5. Green success message
6. List of implemented features

### Database Should Have:
1. Entry in `profiles` table with `role = 'user'`
2. For guests: entry in `guest_accounts` table
3. Proper user ID linking

## 🎯 Demo Script for Presentation

```
1. Start app → Shows Splash Screen
2. Navigate to Login Screen
3. Demonstrate Guest Login → Show home screen with user role
4. Sign out
5. Demonstrate Email/Password signup → Create new account
6. Show home screen with user role
7. Sign out
8. Demonstrate Email/Password login → Sign in with created account
9. Show home screen again
10. (If configured) Demonstrate Google Sign-In
11. Verify all users have "user" role
```

## 🔗 Resources

- **Supabase Dashboard**: https://supabase.com/dashboard/project/wkfbcdpsbjblsflcvcks
- **Google Cloud Console**: https://console.cloud.google.com
- **Flutter Docs**: https://docs.flutter.dev

## 📝 Notes

- Guest accounts are functional but temporary
- All auth methods assign "user" role by default
- App works offline after initial login (session cached)
- Google Sign-In is optional - Email/Password and Guest work immediately

---

**Ready to present!** ✅
