import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'google_signin_config.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    // Needed for an ID token on Android (used by Supabase signInWithIdToken).
    serverClientId: GoogleSignInConfig.webClientIdOrNull,
  );

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Ensure accounts row exists, but NEVER overwrite username on login
      if (response.user != null) {
        try {
          await _createAccountIfMissing(
            response.user!.id,
            email: response.user!.email,
            username: response.user!.userMetadata?['username'],
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Could not ensure account on login: $e');
          }
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Store username in auth.users.raw_user_meta_data so the DB trigger can use it
      // when creating public.accounts.
      final cleanedUsername = _sanitizeUsername(username);

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': cleanedUsername,
        },
        emailRedirectTo: null, // No email confirmation redirect needed
      );

      // Note: Supabase might require email confirmation
      if (response.user != null) {
        await Future.delayed(const Duration(milliseconds: 500));

        // Best-effort: ensure account exists (but don't fail signup if RLS/schema blocks it)
        try {
          await _ensureUserRole(
            response.user!.id,
            email: response.user!.email,
            username: cleanedUsername,
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Could not create/update account immediately: $e');
          }
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google (ADDU Mail)
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Start Google Sign-In
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      // Get Google authentication
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception(
          'Missing Google ID token. Set GOOGLE_WEB_CLIENT_ID when running the app.',
        );
      }
      if (accessToken == null) {
        throw Exception('Failed to get Google access token');
      }

      // Sign in to Supabase with Google credentials
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // Ensure account row exists, but don't fail auth if it doesn't work (RLS/schema issues).
      if (response.user != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          await _createAccountIfMissing(
            response.user!.id,
            email: response.user!.email,
            username: response.user!.userMetadata?['username'],
            fullName: response.user!.userMetadata?['full_name'],
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Could not update account after Google login: $e');
          }
        }
      }

      return response;
    } on PlatformException catch (e) {
      // Common Android error:
      // PlatformException(sign_in_failed, ... ApiException: 10 ...)
      if ((e.code).toLowerCase() == 'sign_in_failed' &&
          (e.message ?? '').contains('ApiException: 10')) {
        await _googleSignIn.signOut();
        throw Exception(
          'Google Sign-In developer error (ApiException: 10).\n'
          '- Google Cloud Console: create ANDROID OAuth client (package com.example.flutter_exam + your SHA-1)\n'
          '- Create WEB OAuth client and run with: --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>\n'
          '- Supabase: enable Google provider using that WEB client ID/secret',
        );
      }

      // For other sign_in_failed cases, avoid showing a raw PlatformException.
      await _googleSignIn.signOut();
      throw Exception('Google sign-in failed: ${e.message ?? e.code}');
    } catch (e) {
      await _googleSignIn.signOut(); // Clean up on error
      rethrow;
    }
  }

  // Guest login
  Future<AuthResponse> signInAsGuest() async {
    try {
      // Generate unique guest identifier
      const uuid = Uuid();
      final guestId = uuid.v4();
      final guestEmail = 'guest_$guestId@temp.local';
      final guestPassword = 'guest_${uuid.v4()}';

      final guestUsername = 'user${DateTime.now().millisecondsSinceEpoch}';

      // Create guest account
      final response = await _supabase.auth.signUp(
        email: guestEmail,
        password: guestPassword,
        data: {
          'full_name': 'Guest User',
          'username': guestUsername,
          'is_guest': true,
          'guest_id': guestId,
        },
      );

      // Ensure account row exists, but don't fail auth if it doesn't work (RLS/schema issues).
      if (response.user != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          await _ensureUserRole(
            response.user!.id,
            email: guestEmail,
            fullName: 'Guest User',
            username: guestUsername,
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Could not update account after guest signup: $e');
          }
        }

        // Note: Guest info is stored in user metadata
        // No separate guest_accounts table needed
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  String _sanitizeUsername(String input) {
    var u = input.trim().toLowerCase();
    u = u.replaceAll(RegExp(r'[^a-z0-9_.-]+'), '_');
    u = u.replaceAll(RegExp(r'[_\.\-]{2,}'), '_');
    u = u.replaceAll(RegExp(r'^[_\.\-]+'), '');
    u = u.replaceAll(RegExp(r'[_\.\-]+$'), '');

    if (u.isEmpty) {
      u = 'user${DateTime.now().millisecondsSinceEpoch}';
    }

    if (u.length > 30) {
      u = u.substring(0, 30);
    }

    return u;
  }

  // Ensure user has a row in accounts table (signup flow).
  // This MAY update username because the user just chose it.
  Future<void> _ensureUserRole(
    String userId, {
    String? email,
    String? fullName,
    String? username,
  }) async {
    try {
      String finalUsername;
      if (username != null && username.trim().isNotEmpty) {
        finalUsername = _sanitizeUsername(username);
      } else if (email != null && !email.startsWith('guest_')) {
        finalUsername = _sanitizeUsername(email.split('@')[0]);
      } else if (fullName != null && fullName.isNotEmpty) {
        finalUsername = _sanitizeUsername(fullName);
      } else {
        finalUsername = _sanitizeUsername('user${DateTime.now().millisecondsSinceEpoch}');
      }

      await _supabase.from('accounts').upsert({
        'auth_user_id': userId,
        'username': finalUsername,
      }, onConflict: 'auth_user_id');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ERROR creating/updating account: $e');
      }
      rethrow;
    }
  }

  // Login flow: only create the row if it does not exist.
  // This prevents overwriting a previously-chosen username.
  Future<void> _createAccountIfMissing(
    String userId, {
    String? email,
    String? fullName,
    dynamic username,
  }) async {
    try {
      final existing = await _supabase
          .from('accounts')
          .select('auth_user_id')
          .eq('auth_user_id', userId)
          .maybeSingle();

      if (existing != null) return;

      final chosen = (username is String) ? username : null;

      final String finalUsername;
      if (chosen != null && chosen.trim().isNotEmpty) {
        finalUsername = _sanitizeUsername(chosen);
      } else if (email != null && email.isNotEmpty && !email.startsWith('guest_')) {
        finalUsername = _sanitizeUsername(email.split('@')[0]);
      } else if (fullName != null && fullName.isNotEmpty) {
        finalUsername = _sanitizeUsername(fullName);
      } else {
        finalUsername = _sanitizeUsername('user${DateTime.now().millisecondsSinceEpoch}');
      }

      await _supabase.from('accounts').insert({
        'auth_user_id': userId,
        'username': finalUsername,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ERROR ensuring account exists: $e');
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Supabase
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUsername(String username) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    final cleaned = _sanitizeUsername(username);

    await _supabase
        .from('accounts')
        .update({'username': cleaned})
        .eq('auth_user_id', userId);

    // Keep auth metadata in sync (helpful for DB triggers/clients). Best-effort.
    try {
      await _supabase.auth.updateUser(UserAttributes(data: {'username': cleaned}));
    } catch (_) {
      // ignore
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('accounts')
          .select()
          .eq('auth_user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user account: $e');
      }
      return null;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
