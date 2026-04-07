import 'package:flutter/material.dart';
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

      // Try to ensure profile has 'user' role, but don't fail if it doesn't work
      if (response.user != null) {
        try {
          await _ensureUserRole(
            response.user!.id,
            email: response.user!.email,
          );
        } catch (e) {
          print('Could not update role on login: $e');
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
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? '',
        },
        emailRedirectTo: null, // No email confirmation redirect needed
      );

      // Note: Supabase might require email confirmation
      // Check if user is created but not confirmed
      if (response.user != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Try to update role and username, but don't fail if it doesn't work
        try {
          await _ensureUserRole(
            response.user!.id,
            email: response.user!.email,
            fullName: fullName,
          );
        } catch (e) {
          print('Could not set role immediately: $e');
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
          await _ensureUserRole(
            response.user!.id,
            email: response.user!.email,
            fullName: response.user!.userMetadata?['full_name'],
          );
        } catch (e) {
          print('Could not update account after Google login: $e');
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

      // Create guest account
      final response = await _supabase.auth.signUp(
        email: guestEmail,
        password: guestPassword,
        data: {
          'full_name': 'Guest User',
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
          );
        } catch (e) {
          print('Could not update account after guest signup: $e');
        }

        // Note: Guest info is stored in user metadata
        // No separate guest_accounts table needed
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Ensure user has 'USER' role and username in accounts table
  Future<void> _ensureUserRole(String userId, {String? email, String? fullName}) async {
    try {
      // Generate username from email or create a random one
      String username;
      if (email != null && !email.startsWith('guest_')) {
        // Use email prefix as username (before @)
        username = email.split('@')[0].toLowerCase();
      } else if (fullName != null && fullName.isNotEmpty) {
        // Use full name as username (remove spaces)
        username = fullName.toLowerCase().replaceAll(' ', '');
      } else {
        // Generate random username for guests
        username = 'user${DateTime.now().millisecondsSinceEpoch}';
      }
      
      print('Creating account for user $userId with username: $username');
      
      // Insert into accounts table (not profiles)
      // Using upsert to create if doesn't exist, or update if it does
      // NOTE: Avoid camelCase column names in JSON payloads.
      // In Postgres, unquoted identifiers are folded to lowercase, so a column
      // declared as `isActive` becomes `isactive`. Sending `isActive` here causes
      // PostgREST to error with "column does not exist" and the upsert fails.
      final result = await _supabase.from('accounts').upsert({
        'auth_user_id': userId, // Link to auth.users
        'username': username,
        'role': 'USER', // Default role (matches your CHECK constraint)
        // Don't send isActive/isactive; rely on DB default.
      }, onConflict: 'auth_user_id').select();

      print('Account created/updated successfully: $result');
    } catch (e) {
      // Let callers decide whether to ignore this (login) or show it (debug).
      print('ERROR creating/updating account: $e');
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

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('accounts')  // Changed from 'profiles' to 'accounts'
          .select()
          .eq('auth_user_id', userId)  // Changed from 'id' to 'auth_user_id'
          .single();

      return response;
    } catch (e) {
      print('Error fetching user account: $e');
      return null;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
