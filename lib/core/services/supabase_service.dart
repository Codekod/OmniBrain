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

class SocialAuthResult {
  final bool success;
  final bool isCancelled;
  final String? userId;
  final String? displayName;
  final String? email;
  final String? errorMessage;

  const SocialAuthResult({
    required this.success,
    this.isCancelled = false,
    this.userId,
    this.displayName,
    this.email,
    this.errorMessage,
  });

  factory SocialAuthResult.cancelled() => const SocialAuthResult(
        success: false,
        isCancelled: true,
      );

  factory SocialAuthResult.failure(String message) => SocialAuthResult(
        success: false,
        errorMessage: message,
      );

  factory SocialAuthResult.success({
    required String userId,
    String? displayName,
    String? email,
  }) =>
      SocialAuthResult(
        success: true,
        userId: userId,
        displayName: displayName,
        email: email,
      );
}

/// Central service for authentication and user data.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Current logged-in user (null if not logged in).
  User? get currentUser {
    try {
      return _client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Stream of auth state changes – subscribe in providers.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  bool get isLoggedIn => currentUser != null;

  // ---------------------------------------------------------------------------
  // Apple Sign-In
  // ---------------------------------------------------------------------------

  /// Signs in with Apple using native iOS credential + Supabase sync if available.
  Future<SocialAuthResult> signInWithApple() async {
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

      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((e) => e != null && e.isNotEmpty).join(' ');

      final userId = credential.userIdentifier ?? 'apple_${DateTime.now().millisecondsSinceEpoch}';
      final email = credential.email;

      // Try Supabase sync in background (if configured and reachable)
      final idToken = credential.identityToken;
      if (idToken != null) {
        try {
          final response = await _client.auth.signInWithIdToken(
            provider: OAuthProvider.apple,
            idToken: idToken,
            nonce: rawNonce,
          );
          if (response.user != null && fullName.isNotEmpty && (response.user!.userMetadata?['full_name'] ?? '').isEmpty) {
            await _client.auth.updateUser(UserAttributes(data: {'full_name': fullName}));
          }
          debugPrint('[Supabase] Apple Sign-In synced with Supabase successfully.');
        } catch (e) {
          debugPrint('[Supabase] Apple sync error (continuing with local auth): $e');
        }
      }

      return SocialAuthResult.success(
        userId: userId,
        displayName: fullName.isNotEmpty ? fullName : 'Apple Kullanıcısı',
        email: email ?? 'apple.user@icloud.com',
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('[Supabase] Apple Sign-In: user cancelled');
        return SocialAuthResult.cancelled();
      }
      debugPrint('[Supabase] Apple Sign-In error: $e');
      return SocialAuthResult.failure(e.message);
    } catch (e) {
      debugPrint('[Supabase] Apple Sign-In error: $e');
      return SocialAuthResult.failure(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  /// Signs in with Google via platform credential + Supabase sync.
  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
      final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';

      GoogleSignInAccount? googleUser;
      try {
        final googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          clientId: iosClientId.isEmpty ? null : iosClientId,
          serverClientId: webClientId.isEmpty ? null : webClientId,
        );
        googleUser = await googleSignIn.signIn();
      } catch (e) {
        debugPrint('[Google Sign-In] with serverClientId failed: $e, trying standalone...');
        try {
          final fallbackGoogleSignIn = GoogleSignIn(
            scopes: ['email', 'profile'],
            clientId: iosClientId.isEmpty ? null : iosClientId,
          );
          googleUser = await fallbackGoogleSignIn.signIn();
        } catch (inner) {
          debugPrint('[Google Sign-In] fallback failed: $inner');
          return SocialAuthResult.failure(inner.toString());
        }
      }

      if (googleUser == null) {
        debugPrint('[Google Sign-In]: user cancelled');
        return SocialAuthResult.cancelled();
      }

      // Try Supabase sync in background
      try {
        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;
        if (idToken != null) {
          await _client.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );
          debugPrint('[Supabase] Google Sign-In synced with Supabase.');
        }
      } catch (e) {
        debugPrint('[Supabase] Google sync error (continuing with local auth): $e');
      }

      return SocialAuthResult.success(
        userId: googleUser.id,
        displayName: googleUser.displayName ?? 'Google Kullanıcısı',
        email: googleUser.email,
      );
    } catch (e) {
      debugPrint('[Google Sign-In error]: $e');
      return SocialAuthResult.failure(e.toString());
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
