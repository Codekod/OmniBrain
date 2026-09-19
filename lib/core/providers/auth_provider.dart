// lib/core/providers/auth_provider.dart
// Riverpod providers for Supabase authentication state.
// When Supabase is not configured (URL still placeholder), falls back to
// in-memory mock state so the app still works during development.

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      // Verify Supabase was actually initialized (no exception thrown)
      Supabase.instance.client;
      // Also check that the URL isn't still the placeholder
      final url = dotenv.env['SUPABASE_URL'] ?? '';
      return url.isNotEmpty && !url.contains('your-project-id');
    } catch (_) {
      return false;
    }
  }

  void _init() {
    if (!_supabaseConfigured) return;

    // Check existing session
    final currentUser = SupabaseService.instance.currentUser;
    if (currentUser != null) {
      state = AuthUserState.fromUser(currentUser);
    }

    // Listen for future auth changes
    SupabaseService.instance.authStateChanges.listen((authState) {
      final user = authState.session?.user;
      if (user != null) {
        state = AuthUserState.fromUser(user);
      } else {
        state = AuthUserState.guest;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Apple Sign-In
  // ---------------------------------------------------------------------------

  Future<bool> signInWithApple() async {
    if (!_supabaseConfigured) {
      // Mock mode for development (Supabase not yet configured)
      state = const AuthUserState(
        isLoggedIn: true,
        userId: 'mock-apple-user',
        displayName: 'OmniBrain Kullanıcısı',
        email: 'user@privaterelay.appleid.com',
        provider: 'Apple',
      );
      return true;
    }

    final user = await SupabaseService.instance.signInWithApple();
    if (user != null) {
      state = AuthUserState.fromUser(user);
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  Future<bool> signInWithGoogle() async {
    if (!_supabaseConfigured) {
      // Mock mode
      state = const AuthUserState(
        isLoggedIn: true,
        userId: 'mock-google-user',
        displayName: 'OmniBrain Kullanıcısı',
        email: 'user@gmail.com',
        provider: 'Google',
      );
      return true;
    }

    final user = await SupabaseService.instance.signInWithGoogle();
    if (user != null) {
      state = AuthUserState.fromUser(user);
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    if (_supabaseConfigured) {
      await SupabaseService.instance.signOut();
    }
    state = AuthUserState.guest;
  }

  // ---------------------------------------------------------------------------
  // Delete Account
  // ---------------------------------------------------------------------------

  Future<bool> deleteAccount() async {
    if (_supabaseConfigured) {
      final success = await SupabaseService.instance.deleteAccount();
      if (success) {
        state = AuthUserState.guest;
        return true;
      }
      return false;
    }
    // Mock mode – just clear local state
    state = AuthUserState.guest;
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
