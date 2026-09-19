// lib/core/services/supabase_service.dart
// Supabase Auth + Database service for OmniBrain AI
// Handles Apple Sign-In, Google Sign-In, session management, and user profiles.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

/// Initializes Supabase.  Call once from main() before runApp().
Future<void> initSupabase() async {
  final url = dotenv.env['SUPABASE_URL'] ?? '';
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (url.isEmpty || anonKey.isEmpty) {
    debugPrint('[Supabase] SUPABASE_URL or SUPABASE_ANON_KEY missing in .env – skipping init.');
    return;
  }

  await Supabase.initialize(
    url: url,
    anonKey: anonKey, // ignore: deprecated_member_use – required by supabase_flutter API
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.error,
    ),
  );

  debugPrint('[Supabase] Initialized successfully.');
}

/// Central service for authentication and user data.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Current logged-in user (null if not logged in).
  User? get currentUser => _client.auth.currentUser;

  /// Stream of auth state changes – subscribe in providers.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  bool get isLoggedIn => currentUser != null;

  // ---------------------------------------------------------------------------
  // Apple Sign-In
  // ---------------------------------------------------------------------------

  /// Signs in with Apple using OAuth + PKCE.
  /// Returns the [User] on success, null on failure.
  Future<User?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        debugPrint('[Supabase] Apple Sign-In: idToken is null');
        return null;
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      // Update display name on first login
      final user = response.user;
      if (user != null) {
        final fullName = [
          credential.givenName,
          credential.familyName,
        ].where((e) => e != null && e.isNotEmpty).join(' ');

        if (fullName.isNotEmpty && (user.userMetadata?['full_name'] ?? '').isEmpty) {
          await _client.auth.updateUser(UserAttributes(data: {'full_name': fullName}));
        }
      }

      debugPrint('[Supabase] Apple Sign-In success: ${user?.email}');
      return user;
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled – not an error
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('[Supabase] Apple Sign-In: user cancelled');
        return null;
      }
      debugPrint('[Supabase] Apple Sign-In error: $e');
      rethrow;
    } catch (e) {
      debugPrint('[Supabase] Apple Sign-In error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  /// Signs in with Google via platform credential + Supabase.
  Future<User?> signInWithGoogle() async {
    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
      final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';
      
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: iosClientId.isEmpty ? null : iosClientId,
        serverClientId: webClientId.isEmpty ? null : webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[Supabase] Google Sign-In: user cancelled');
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        debugPrint('[Supabase] Google Sign-In: idToken is null');
        return null;
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      debugPrint('[Supabase] Google Sign-In success: ${response.user?.email}');
      return response.user;
    } catch (e) {
      debugPrint('[Supabase] Google Sign-In error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      debugPrint('[Supabase] Signed out.');
    } catch (e) {
      debugPrint('[Supabase] Sign out error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Delete Account
  // ---------------------------------------------------------------------------

  /// Deletes the current user's account via Supabase Edge Function.
  /// Requires a `delete_user` Edge Function deployed on your Supabase project.
  Future<bool> deleteAccount() async {
    try {
      await _client.functions.invoke('delete_user');
      await signOut();
      return true;
    } catch (e) {
      debugPrint('[Supabase] Delete account error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // User Profile (Supabase DB)
  // ---------------------------------------------------------------------------

  /// Upsert user profile row in `public.profiles` table.
  Future<void> upsertProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    String? locale,
  }) async {
    try {
      await _client.from('profiles').upsert({
        'id': userId,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'locale': locale,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Supabase] upsertProfile error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
