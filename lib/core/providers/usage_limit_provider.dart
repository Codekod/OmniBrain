import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageLimitState {
  final int remainingCredits;
  final int maxCredits;
  final String lastUsedDate;

  const UsageLimitState({
    required this.remainingCredits,
    this.maxCredits = 5,
    required this.lastUsedDate,
  });

  UsageLimitState copyWith({
    int? remainingCredits,
    int? maxCredits,
    String? lastUsedDate,
  }) {
    return UsageLimitState(
      remainingCredits: remainingCredits ?? this.remainingCredits,
      maxCredits: maxCredits ?? this.maxCredits,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
    );
  }
}

class UsageLimitNotifier extends StateNotifier<UsageLimitState> {
  static const String _keyCredits = 'daily_remaining_credits';
  static const String _keyDate = 'daily_last_used_date';
  static const int _defaultMax = 5;

  UsageLimitNotifier()
      : super(UsageLimitState(
          remainingCredits: _defaultMax,
          lastUsedDate: _getTodayString(),
        )) {
    _loadState();
  }

  static String _getTodayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_keyDate) ?? '';

    if (savedDate != today) {
      // New day: reset credits
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyCredits, _defaultMax);
      state = UsageLimitState(remainingCredits: _defaultMax, lastUsedDate: today);
    } else {
      final credits = prefs.getInt(_keyCredits) ?? _defaultMax;
      state = UsageLimitState(remainingCredits: credits, lastUsedDate: today);
    }
  }

  Future<bool> consumeCredit(bool isPro) async {
    // Pro users have unlimited credits
    if (isPro) return true;

    await _loadState(); // Ensure up-to-date date check

    if (state.remainingCredits <= 0) {
      return false; // No credit left
    }

    final newCredits = state.remainingCredits - 1;
    state = state.copyWith(remainingCredits: newCredits);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCredits, newCredits);
    return true;
  }

  bool hasCredit(bool isPro) {
    if (isPro) return true;
    return state.remainingCredits > 0;
  }
}

final usageLimitProvider = StateNotifierProvider<UsageLimitNotifier, UsageLimitState>((ref) {
  return UsageLimitNotifier();
});
