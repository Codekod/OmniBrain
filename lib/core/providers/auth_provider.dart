// lib/core/providers/auth_provider.dart
// Riverpod providers for Supabase authentication state.
// When Supabase is not configured (URL still placeholder), falls back to
// in-memory mock state so the app still works during development.

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omnibrain_ai/core/services/supabase_service.dart';

// ---------------------------------------------------------------------------
// Auth State Model
// ---------------------------------------------------------------------------

class AuthUserState {
  final bool isLoggedIn;
  final String? userId;
  final String? displayName;
  final String? email;
  final String? provider; // 'Apple' | 'Google' | null

  const AuthUserState({
    this.isLoggedIn = false,
    this.userId,
    this.displayName,
    this.email,
    this.provider,
  });

  AuthUserState copyWith({
    bool? isLoggedIn,
    String? userId,
    String? displayName,
    String? email,
    String? provider,
  }) {
    return AuthUserState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      provider: provider ?? this.provider,
    );
  }

  factory AuthUserState.fromUser(User user) {
    final metadata = user.userMetadata ?? {};
    final appMetadata = user.appMetadata;

    final providers = (appMetadata['providers'] as List?)?.cast<String>() ?? [];
    String? provider;
    if (providers.contains('apple')) {
      provider = 'Apple';
    } else if (providers.contains('google')) {
      provider = 'Google';
    }

    return AuthUserState(
      isLoggedIn: true,
      userId: user.id,
      displayName: metadata['full_name'] as String? ?? user.email?.split('@').first,
      email: user.email,
      provider: provider,
    );
  }

  static const guest = AuthUserState(isLoggedIn: false);
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthUserState> {
  AuthNotifier() : super(AuthUserState.guest) {
    _init();
  }

  bool get _supabaseConfigured {
    try {
      Supabase.instance.client;
      final url = dotenv.env['SUPABASE_URL'] ?? '';
      return url.isNotEmpty && !url.contains('your-project-id');
    } catch (_) {
      return false;
    }
  }

  Future<void> _init() async {
    // 1. First restore locally persisted user from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('auth_is_logged_in') ?? false;
      if (isLoggedIn) {
        state = AuthUserState(
          isLoggedIn: true,
          userId: prefs.getString('auth_user_id'),
          displayName: prefs.getString('auth_display_name') ?? 'Kullanıcı',
          email: prefs.getString('auth_email'),
          provider: prefs.getString('auth_provider'),
        );
      }
    } catch (e) {
      debugPrint('Auth init prefs error: $e');
    }

    // 2. Check Supabase session if configured
    if (_supabaseConfigured) {
      try {
        final currentUser = SupabaseService.instance.currentUser;
        if (currentUser != null) {
          state = AuthUserState.fromUser(currentUser);
        }

        SupabaseService.instance.authStateChanges.listen((authState) {
          final user = authState.session?.user;
          if (user != null) {
            state = AuthUserState.fromUser(user);
          }
        });
      } catch (e) {
        debugPrint('Supabase session listener error: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Apple Sign-In
  // ---------------------------------------------------------------------------

  Future<SocialAuthResult> signInWithApple() async {
    final result = await SupabaseService.instance.signInWithApple();
    if (result.success) {
      final displayName = (result.displayName != null && result.displayName!.isNotEmpty)
          ? result.displayName!
          : 'Apple Kullanıcısı';
      final email = result.email ?? 'apple.user@icloud.com';
      final userId = result.userId ?? 'apple_${DateTime.now().millisecondsSinceEpoch}';

      state = AuthUserState(
        isLoggedIn: true,
        userId: userId,
        displayName: displayName,
        email: email,
        provider: 'Apple',
      );

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('auth_is_logged_in', true);
        await prefs.setString('auth_user_id', userId);
        await prefs.setString('auth_display_name', displayName);
        await prefs.setString('auth_email', email);
        await prefs.setString('auth_provider', 'Apple');
      } catch (e) {
        debugPrint('Failed to save auth state: $e');
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  Future<SocialAuthResult> signInWithGoogle() async {
    final result = await SupabaseService.instance.signInWithGoogle();
    if (result.success) {
      final displayName = (result.displayName != null && result.displayName!.isNotEmpty)
          ? result.displayName!
          : 'Google Kullanıcısı';
      final email = result.email ?? 'google.user@gmail.com';
      final userId = result.userId ?? 'google_${DateTime.now().millisecondsSinceEpoch}';

      state = AuthUserState(
        isLoggedIn: true,
        userId: userId,
        displayName: displayName,
        email: email,
        provider: 'Google',
      );

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('auth_is_logged_in', true);
        await prefs.setString('auth_user_id', userId);
        await prefs.setString('auth_display_name', displayName);
        await prefs.setString('auth_email', email);
        await prefs.setString('auth_provider', 'Google');
      } catch (e) {
        debugPrint('Failed to save auth state: $e');
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    if (_supabaseConfigured) {
      try {
        await SupabaseService.instance.signOut();
      } catch (_) {}
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_is_logged_in');
      await prefs.remove('auth_user_id');
      await prefs.remove('auth_display_name');
      await prefs.remove('auth_email');
      await prefs.remove('auth_provider');
    } catch (_) {}

    state = AuthUserState.guest;
  }

  // ---------------------------------------------------------------------------
  // Delete Account
  // ---------------------------------------------------------------------------

  Future<bool> deleteAccount() async {
    if (_supabaseConfigured) {
      try {
        await SupabaseService.instance.deleteAccount();
      } catch (_) {}
    }
    await signOut();
    return true;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authProvider = StateNotifierProvider<AuthNotifier, AuthUserState>(
  (ref) => AuthNotifier(),
);

/// Convenience provider – true when user is signed in.
final isLoggedInProvider = Provider<bool>(
  (ref) => ref.watch(authProvider).isLoggedIn,
);
