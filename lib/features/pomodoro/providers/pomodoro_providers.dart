import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:omnibrain_ai/core/providers/streak_provider.dart';
import 'package:omnibrain_ai/core/services/notification_service.dart';
import 'package:omnibrain_ai/features/pomodoro/services/pomodoro_sound_service.dart';
import 'package:omnibrain_ai/features/pomodoro/widgets/focus_tree_view.dart';

enum FocusCategory {
  study('Ders & Sınav', Icons.school_rounded, Color(0xFFFBBF24)),
  work('İş & Proje', Icons.work_rounded, Color(0xFF38BDF8)),
  code('Kodlama', Icons.terminal_rounded, Color(0xFF818CF8)),
  reading('Okuma & Kitap', Icons.menu_book_rounded, Color(0xFF4ADE80)),
  creative('Yaratıcılık', Icons.brush_rounded, Color(0xFFA855F7)),
  general('Genel Odak', Icons.flare_rounded, Color(0xFF8A2BE2));

  final String label;
  final IconData icon;
  final Color color;
  const FocusCategory(this.label, this.icon, this.color);
}

class GrownTree {
  final String id;
  final FocusTreeType treeType;
  final FocusCategory category;
  final int focusMinutes;
  final DateTime completedAt;

  GrownTree({
    required this.id,
    required this.treeType,
    required this.category,
    required this.focusMinutes,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'treeType': treeType.name,
        'category': category.name,
        'focusMinutes': focusMinutes,
        'completedAt': completedAt.toIso8601String(),
      };

  factory GrownTree.fromMap(Map<String, dynamic> map) => GrownTree(
        id: map['id']?.toString() ?? '',
        treeType: FocusTreeType.values.firstWhere(
          (t) => t.name == map['treeType'],
          orElse: () => FocusTreeType.pine,
        ),
        category: FocusCategory.values.firstWhere(
          (c) => c.name == map['category'],
          orElse: () => FocusCategory.general,
        ),
        focusMinutes: map['focusMinutes'] as int? ?? 25,
        completedAt: map['completedAt'] != null
            ? DateTime.tryParse(map['completedAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class PomodoroState {
  final int focusMinutes;
  final int breakMinutes;
  final int longBreakMinutes;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final bool isBreak;
  final bool isLongBreak;
  final int currentRound;
  final int totalRounds;
  final String message;
  final int completedSessionsToday;
  final int todayFocusMinutes;
  final List<GrownTree> grownTreesToday;
  final FocusCategory selectedCategory;
  final FocusTreeType selectedTreeType;
  final DateTime? targetEndTime;

  PomodoroState({
    required this.focusMinutes,
    required this.breakMinutes,
    this.longBreakMinutes = 15,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.isBreak,
    this.isLongBreak = false,
    this.currentRound = 1,
    this.totalRounds = 4,
    required this.message,
    this.completedSessionsToday = 0,
    this.todayFocusMinutes = 0,
    this.grownTreesToday = const [],
    this.selectedCategory = FocusCategory.study,
    this.selectedTreeType = FocusTreeType.pine,
    this.targetEndTime,
  });

  PomodoroState copyWith({
    int? focusMinutes,
    int? breakMinutes,
    int? longBreakMinutes,
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    bool? isBreak,
    bool? isLongBreak,
    int? currentRound,
    int? totalRounds,
    String? message,
    int? completedSessionsToday,
    int? todayFocusMinutes,
    List<GrownTree>? grownTreesToday,
    FocusCategory? selectedCategory,
    FocusTreeType? selectedTreeType,
    DateTime? targetEndTime,
    bool clearTargetEndTime = false,
  }) {
    return PomodoroState(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      isBreak: isBreak ?? this.isBreak,
      isLongBreak: isLongBreak ?? this.isLongBreak,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      message: message ?? this.message,
      completedSessionsToday: completedSessionsToday ?? this.completedSessionsToday,
      todayFocusMinutes: todayFocusMinutes ?? this.todayFocusMinutes,
      grownTreesToday: grownTreesToday ?? this.grownTreesToday,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedTreeType: selectedTreeType ?? this.selectedTreeType,
      targetEndTime: clearTargetEndTime ? null : (targetEndTime ?? this.targetEndTime),
    );
  }
}

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  final Ref _ref;
  Timer? _timer;
  static const int _notificationId = 8888;
  static const String _storageKey = 'omnibrain_pomodoro_stats_v2';

  PomodoroNotifier(this._ref)
      : super(PomodoroState(
          focusMinutes: 25,
          breakMinutes: 5,
          longBreakMinutes: 15,
          remainingSeconds: 25 * 60,
          totalSeconds: 25 * 60,
          isRunning: false,
          isBreak: false,
          isLongBreak: false,
          currentRound: 1,
          totalRounds: 4,
          message: 'Klasik 25 dakikalık odak seansına başla.',
        )) {
    _loadDailyStats();
  }

  Future<void> _loadDailyStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr == null) return;

      final data = jsonDecode(jsonStr);
      final savedDate = data['date'] as String?;
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (savedDate == todayStr) {
        final totalMins = data['todayFocusMinutes'] as int? ?? 0;
        final completed = data['completedSessionsToday'] as int? ?? 0;
        final rawTrees = data['grownTrees'] as List<dynamic>? ?? [];
        final trees = rawTrees.map((m) => GrownTree.fromMap(m as Map<String, dynamic>)).toList();

        state = state.copyWith(
          todayFocusMinutes: totalMins,
          completedSessionsToday: completed,
          grownTreesToday: trees,
        );
      }
    } catch (_) {}
  }

  Future<void> _saveDailyStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final payload = {
        'date': todayStr,
        'todayFocusMinutes': state.todayFocusMinutes,
        'completedSessionsToday': state.completedSessionsToday,
        'grownTrees': state.grownTreesToday.map((t) => t.toMap()).toList(),
      };
      await prefs.setString(_storageKey, jsonEncode(payload));
    } catch (_) {}
  }

  void setCategory(FocusCategory category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setTreeType(FocusTreeType treeType) {
    state = state.copyWith(selectedTreeType: treeType);
  }

  void setPresetDuration(int focusMins, int breakMins, String label) {
    _cancelTimerAndNotification();
    state = state.copyWith(
      focusMinutes: focusMins,
      breakMinutes: breakMins,
      remainingSeconds: focusMins * 60,
      totalSeconds: focusMins * 60,
      isRunning: false,
      isBreak: false,
      isLongBreak: false,
      message: '$label seansı hazır. Başlat butonuna dokun!',
      clearTargetEndTime: true,
    );
  }

  void setAiSuggestion(int focusMins, int breakMins, String msg) {
    _cancelTimerAndNotification();
    state = state.copyWith(
      focusMinutes: focusMins,
      breakMinutes: breakMins,
      remainingSeconds: focusMins * 60,
      totalSeconds: focusMins * 60,
      isRunning: false,
      isBreak: false,
      isLongBreak: false,
      message: msg,
      clearTargetEndTime: true,
    );
  }

  void toggleTimer() {
    if (state.isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    if (state.remainingSeconds <= 0) return;

    final targetEnd = DateTime.now().add(Duration(seconds: state.remainingSeconds));

    state = state.copyWith(
      isRunning: true,
      targetEndTime: targetEnd,
    );

    // Audio cue
    PomodoroSoundService.playTimerStart();

    // Background notification
    NotificationService().scheduleNotification(
      id: _notificationId,
      title: state.isBreak
          ? (state.isLongBreak ? 'Uzun Mola Bitti! 🌟' : 'Mola Bitti! ⏰')
          : 'Odaklanma Seansı Tamamlandı! 🎯',
      body: state.isBreak
          ? 'Yeni bir odaklanma seansına hazır mısın? OmniBrain seni bekliyor.'
          : 'Harika bir seans tamamladın! Bir ağaç daha büyüttün 🌲',
      scheduledDate: targetEnd,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  void _pauseTimer() {
    _cancelTimerAndNotification();
    state = state.copyWith(
      isRunning: false,
      clearTargetEndTime: true,
    );
  }

  void _tick() {
    if (state.targetEndTime == null) return;

    final diff = state.targetEndTime!.difference(DateTime.now()).inSeconds;
    if (diff > 0) {
      state = state.copyWith(remainingSeconds: diff);
    } else {
      _timer?.cancel();
      _handleSessionEnd();
    }
  }

  void syncFromBackground() {
    if (!state.isRunning || state.targetEndTime == null) return;

    final diff = state.targetEndTime!.difference(DateTime.now()).inSeconds;
    if (diff > 0) {
      state = state.copyWith(remainingSeconds: diff);
    } else {
      _timer?.cancel();
      _handleSessionEnd();
    }
  }

  void resetTimer() {
    _cancelTimerAndNotification();
    final int mins = state.isBreak
        ? (state.isLongBreak ? state.longBreakMinutes : state.breakMinutes)
        : state.focusMinutes;
    state = state.copyWith(
      remainingSeconds: mins * 60,
      totalSeconds: mins * 60,
      isRunning: false,
      clearTargetEndTime: true,
    );
  }

  void skipSession() {
    _cancelTimerAndNotification();
    _handleSessionEnd();
  }

  void _handleSessionEnd() {
    PomodoroSoundService.playTimerComplete();

    if (state.isBreak) {
      // Finished break -> start new focus round
      state = state.copyWith(
        isBreak: false,
        isLongBreak: false,
        remainingSeconds: state.focusMinutes * 60,
        totalSeconds: state.focusMinutes * 60,
        isRunning: false,
        message: 'Mola bitti! Round ${state.currentRound}/${state.totalRounds} odaklanmaya başla.',
        clearTargetEndTime: true,
      );
    } else {
      // Completed a focus session!
      _ref.read(streakProvider.notifier).recordActivity();

      final newTree = GrownTree(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        treeType: state.selectedTreeType,
        category: state.selectedCategory,
        focusMinutes: state.focusMinutes,
        completedAt: DateTime.now(),
      );

      final updatedTrees = [newTree, ...state.grownTreesToday];
      final newCompletedCount = state.completedSessionsToday + 1;
      final newTotalMins = state.todayFocusMinutes + state.focusMinutes;

      final bool isCycleDone = state.currentRound >= state.totalRounds;
      final int nextBreakMins = isCycleDone ? state.longBreakMinutes : state.breakMinutes;
      final int nextRound = isCycleDone ? 1 : state.currentRound + 1;

      state = state.copyWith(
        isBreak: true,
        isLongBreak: isCycleDone,
        remainingSeconds: nextBreakMins * 60,
        totalSeconds: nextBreakMins * 60,
        isRunning: false,
        currentRound: nextRound,
        completedSessionsToday: newCompletedCount,
        todayFocusMinutes: newTotalMins,
        grownTreesToday: updatedTrees,
        message: isCycleDone
            ? '🎉 4 Seanslık Tam Döngü Bitti! 15 dk Uzun Mola kazandın!'
            : 'Harika odaklandın! Ağacın büyüdü 🌲 Şimdi dinlenme zamanı.',
        clearTargetEndTime: true,
      );

      _saveDailyStats();
    }
  }

  void _cancelTimerAndNotification() {
    _timer?.cancel();
    NotificationService().cancelNotification(_notificationId);
  }

  @override
  void dispose() {
    _cancelTimerAndNotification();
    super.dispose();
  }
}

final pomodoroProvider = StateNotifierProvider<PomodoroNotifier, PomodoroState>((ref) {
  return PomodoroNotifier(ref);
});
