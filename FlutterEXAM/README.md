# Flutter Exam - Mobile Authentication System

## ✅ Completed Features

This Flutter mobile application integrates with Supabase backend and includes complete authentication functionality:

### 🔐 Authentication Methods
1. **Google Sign-In (ADDU Mail)** - OAuth authentication with Google
2. **Guest Login** - Quick anonymous access
3. **Email/Password** - Traditional sign up and sign in

### 🎯 Key Features
- ✅ All user accounts receive "user" role by default
- ✅ Session persistence across app restarts
- ✅ Secure Supabase backend integration
- ✅ Role-based access control
- ✅ Beautiful, modern UI with Material Design 3
- ✅ Loading states and error handling
- ✅ Profile management

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK installed (3.10.8+)
- Android Studio with Android SDK (for Android)
- Android device or emulator
- Supabase account with configured database

### Installation Steps

1. **Navigate to project directory:**
   ```bash
   cd FlutterEXAM
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Connect Android Device or Start Emulator:**
   ```bash
   # Check connected devices
   flutter devices
   
   # Or start an emulator
   flutter emulators
   flutter emulators --launch <emulator_id>
   ```

4. **Run on Android:**
   ```bash
   flutter run
   ```

   The app will install and launch on your Android device!

5. **Configure Google Sign-In (Optional):**
   
   For Android:
   - Get SHA-1 fingerprint: `cd android && ./gradlew signingReport`
   - Go to Google Cloud Console
   - Create OAuth 2.0 credentials for Android
   - Add SHA-1 and package name: `com.example.flutter_exam`
   - Configure in Supabase Dashboard (Authentication > Providers)

   See `ANDROID_SETUP.md` for detailed instructions.

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point with Supabase initialization
├── supabase_config.dart      # Supabase credentials configuration
├── auth_service.dart         # Authentication service with all auth methods
├── splash_screen.dart        # Initial screen with auth check
├── login_screen.dart         # Main login screen with 3 auth options
├── signup_screen.dart        # Email/password registration screen
└── home_screen.dart          # Authenticated user home screen
```

## 🔧 Configuration

### Supabase Credentials
The app is already configured with Supabase credentials in `lib/supabase_config.dart`:
- URL: https://wkfbcdpsbjblsflcvcks.supabase.co
- Anon Key: (included in config file)

### Database Schema
The backend includes:
- **profiles** table with role field (user, admin, cttmo)
- **guest_accounts** table for tracking guest users
- Row Level Security (RLS) policies enabled
- Automatic profile creation on signup

## 📱 App Flow

1. **Splash Screen** → Checks authentication status
2. **Login Screen** → Choose authentication method:
   - Google Sign-In button
   - Guest Login button
   - Email/Password form
3. **Home Screen** → Displays user profile and role

## 🔑 Authentication Details

### Google Sign-In (ADDU Mail)
- Uses `google_sign_in` package
- Integrates with Supabase OAuth
- Automatically creates profile with "user" role

### Guest Login
- Generates unique guest identifier
- Creates temporary account
- Stored in guest_accounts table
- Assigned "user" role by default

### Email/Password
- Standard email/password authentication
- Includes sign up with name field
- Email validation
- Password strength requirements (min 6 characters)
- Assigned "user" role by default

## 🛡️ Security

- All sensitive credentials in Supabase config
- Row Level Security (RLS) enabled on database
- Secure password hashing by Supabase Auth
- Session tokens managed automatically
- OAuth tokens handled securely

## 📦 Dependencies

```yaml
supabase_flutter: ^2.0.0      # Supabase integration
google_sign_in: ^6.2.1        # Google OAuth
shared_preferences: ^2.2.2    # Local storage
uuid: ^4.3.3                  # UUID generation
```

## 🧪 Testing

### Test Email/Password:
1. Click "Sign Up" on login screen
2. Fill in name, email, password
3. Create account
4. Verify "user" role is assigned

### Test Google Sign-In:
1. Click "Continue with Google (ADDU)"
2. Select ADDU account
3. Grant permissions
4. Verify login and "user" role

### Test Guest Login:
1. Click "Continue as Guest"
2. Verify instant login
3. Check "user" role is assigned
4. Note guest indicator on home screen

## 🎨 UI Features

- Modern Material Design 3
- Responsive layouts
- Loading indicators
- Error messages with SnackBars
- Password visibility toggle
- Form validation
- Profile avatars with initials
- Role badges
- Pull-to-refresh on home screen

## 📝 Notes

- Guest accounts are temporary but persistent
- All authentication methods assign "user" role
- Profile is auto-created on first signup/login
- Session persists across app restarts
- Supports sign out functionality

## ✅ Exam Requirements Met

✔️ Login screen created
✔️ Google Login (ADDU Mail) implemented
✔️ Guest Login implemented  
✔️ Email/Password authentication implemented
✔️ Default role "user" assigned to all accounts
✔️ Backend integration complete
✔️ Working authentication system ready for demonstration

## 🚨 Important Notes for Presentation

1. **Run `flutter pub get` before running the app**
2. **Connect an Android device or start an Android emulator**
3. **Run `flutter run` to launch on Android**
4. **Email/Password and Guest Login work immediately**
5. **Google Sign-In requires OAuth configuration (optional)**
6. **Test on Android 5.0+ devices**

### Quick Android Test:
```bash
cd FlutterEXAM
flutter pub get
flutter devices    # Verify Android device connected
flutter run        # Launch on Android
```

See `ANDROID_RUN.md` for quick instructions or `ANDROID_SETUP.md` for detailed guide.

## 👥 Team Information

- **Project**: Flutter Exam Mobile Team
- **Backend**: Supabase (wkfbcdpsbjblsflcvcks)
- **Platform**: Mobile (Android/iOS)
- **Default Role**: user

---

**Status**: ✅ Ready for demonstration
**Last Updated**: 2026-04-07
