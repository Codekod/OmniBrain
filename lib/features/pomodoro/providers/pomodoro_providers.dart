import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnibrain_ai/core/providers/streak_provider.dart';
import 'package:omnibrain_ai/core/services/notification_service.dart';
import 'package:omnibrain_ai/features/pomodoro/services/pomodoro_sound_service.dart';

class PomodoroState {
  final int focusMinutes;
  final int breakMinutes;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final bool isBreak;
  final String message;
  final int completedSessionsToday;
  final DateTime? targetEndTime;

  PomodoroState({
    required this.focusMinutes,
    required this.breakMinutes,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.isBreak,
    required this.message,
    this.completedSessionsToday = 0,
    this.targetEndTime,
  });

  PomodoroState copyWith({
    int? focusMinutes,
    int? breakMinutes,
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    bool? isBreak,
    String? message,
    int? completedSessionsToday,
    DateTime? targetEndTime,
    bool clearTargetEndTime = false,
  }) {
    return PomodoroState(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      isBreak: isBreak ?? this.isBreak,
      message: message ?? this.message,
      completedSessionsToday: completedSessionsToday ?? this.completedSessionsToday,
      targetEndTime: clearTargetEndTime ? null : (targetEndTime ?? this.targetEndTime),
    );
  }
}

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  final Ref _ref;
  Timer? _timer;
  static const int _notificationId = 8888;

  PomodoroNotifier(this._ref)
      : super(PomodoroState(
          focusMinutes: 25,
          breakMinutes: 5,
          remainingSeconds: 25 * 60,
          totalSeconds: 25 * 60,
          isRunning: false,
          isBreak: false,
          message: 'Klasik 25 dakikalık odak seansına başla.',
          completedSessionsToday: 0,
        ));

  void setPresetDuration(int focusMins, int breakMins, String label) {
    _cancelTimerAndNotification();
    state = state.copyWith(
      focusMinutes: focusMins,
      breakMinutes: breakMins,
      remainingSeconds: focusMins * 60,
      totalSeconds: focusMins * 60,
      isRunning: false,
      isBreak: false,
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

    // Schedule background notification so user is notified even if screen is locked
    NotificationService().scheduleNotification(
      id: _notificationId,
      title: state.isBreak ? 'Mola Bitti! ⏰' : 'Odaklanma Seansı Tamamlandı! 🎯',
      body: state.isBreak
          ? 'Yeni bir odaklanma seansına hazır mısın? OmniBrain seni bekliyor.'
          : 'Harika bir odak seansı tamamladın! Şimdi hak ettiğin dinlenme vakti. ☕',
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

  /// Synchronize timer when app comes from background to foreground
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
    final int mins = state.isBreak ? state.breakMinutes : state.focusMinutes;
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
      state = state.copyWith(
        isBreak: false,
        remainingSeconds: state.focusMinutes * 60,
        totalSeconds: state.focusMinutes * 60,
        isRunning: false,
        message: 'Mola bitti! Yeni bir odak seansına hazır mısın?',
        clearTargetEndTime: true,
      );
    } else {
      _ref.read(streakProvider.notifier).recordActivity();

      state = state.copyWith(
        isBreak: true,
        remainingSeconds: state.breakMinutes * 60,
        totalSeconds: state.breakMinutes * 60,
        isRunning: false,
        completedSessionsToday: state.completedSessionsToday + 1,
        message: 'Harika iş çıkardın! Şimdi dinlenme vakti. ☕',
        clearTargetEndTime: true,
      );
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
