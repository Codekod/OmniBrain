import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omnibrain_ai/core/providers/shared_prefs_provider.dart';

class StreakState {
  final int currentStreak;
  final int bestStreak;
  final String lastActiveDate;
  final List<String> weeklyActivityDays; // e.g. ["Mon", "Tue", "Thu"]

  const StreakState({
    required this.currentStreak,
    required this.bestStreak,
    required this.lastActiveDate,
    required this.weeklyActivityDays,
  });

  StreakState copyWith({
    int? currentStreak,
    int? bestStreak,
    String? lastActiveDate,
    List<String>? weeklyActivityDays,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      weeklyActivityDays: weeklyActivityDays ?? this.weeklyActivityDays,
    );
  }
}

class StreakNotifier extends StateNotifier<StreakState> {
  final SharedPreferences _prefs;

  static const _keyCurrentStreak = 'streak_current_count';
  static const _keyBestStreak = 'streak_best_count';
  static const _keyLastActiveDate = 'streak_last_active_date';
  static const _keyActiveDatesList = 'streak_active_dates_list';

  StreakNotifier(this._prefs)
      : super(
          StreakState(
            currentStreak: _prefs.getInt(_keyCurrentStreak) ?? 1,
            bestStreak: _prefs.getInt(_keyBestStreak) ?? 1,
            lastActiveDate: _prefs.getString(_keyLastActiveDate) ?? '',
            weeklyActivityDays: _prefs.getStringList(_keyActiveDatesList) ?? [],
          ),
        ) {
    recordActivity();
  }

  /// Records an activity for today and updates streaks
  Future<void> recordActivity() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (state.lastActiveDate == todayStr) {
      // Already recorded today
      return;
    }

    int newStreak = state.currentStreak;
    if (state.lastActiveDate.isNotEmpty) {
      final lastDate = DateTime.tryParse(state.lastActiveDate);
      if (lastDate != null) {
        final diff = now.difference(DateTime(lastDate.year, lastDate.month, lastDate.day)).inDays;
        if (diff == 1) {
          // Consecutive day
          newStreak += 1;
        } else if (diff > 1) {
          // Streak broken
          newStreak = 1;
        }
      }
    } else {
      newStreak = 1;
    }

    final newBest = newStreak > state.bestStreak ? newStreak : state.bestStreak;

    // Record weekday abbreviation
    const weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final currentDayAbbr = weekdays[now.weekday - 1];

    final updatedWeekly = List<String>.from(state.weeklyActivityDays);
    if (!updatedWeekly.contains(currentDayAbbr)) {
      updatedWeekly.add(currentDayAbbr);
      // Keep only last 7 items
      if (updatedWeekly.length > 7) {
        updatedWeekly.removeAt(0);
      }
    }

    await _prefs.setInt(_keyCurrentStreak, newStreak);
    await _prefs.setInt(_keyBestStreak, newBest);
    await _prefs.setString(_keyLastActiveDate, todayStr);
    await _prefs.setStringList(_keyActiveDatesList, updatedWeekly);

    state = state.copyWith(
      currentStreak: newStreak,
      bestStreak: newBest,
      lastActiveDate: todayStr,
      weeklyActivityDays: updatedWeekly,
    );
  }
}

final streakProvider = StateNotifierProvider<StreakNotifier, StreakState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StreakNotifier(prefs);
});
