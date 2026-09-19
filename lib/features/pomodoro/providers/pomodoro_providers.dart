import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnibrain_ai/core/providers/streak_provider.dart';

class PomodoroState {
  final int focusMinutes;
  final int breakMinutes;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final bool isBreak;
  final String message;
  final int completedSessionsToday;

  PomodoroState({
    required this.focusMinutes,
    required this.breakMinutes,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.isBreak,
    required this.message,
    this.completedSessionsToday = 0,
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
    );
  }
}

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  final Ref _ref;
  Timer? _timer;

  PomodoroNotifier(this._ref)
      : super(PomodoroState(
          focusMinutes: 25,
          breakMinutes: 5,
          remainingSeconds: 25 * 60,
          totalSeconds: 25 * 60,
          isRunning: false,
          isBreak: false,
          message: 'Ne üzerinde çalışacaksın?',
          completedSessionsToday: 0,
        ));

  void setPresetDuration(int focusMins, int breakMins, String label) {
    _timer?.cancel();
    state = state.copyWith(
      focusMinutes: focusMins,
      breakMinutes: breakMins,
      remainingSeconds: focusMins * 60,
      totalSeconds: focusMins * 60,
      isRunning: false,
      isBreak: false,
      message: '$label seansı hazır. Başlamak için oynat butonuna dokun!',
    );
  }

  void setAiSuggestion(int focusMins, int breakMins, String msg) {
    _timer?.cancel();
    state = state.copyWith(
      focusMinutes: focusMins,
      breakMinutes: breakMins,
      remainingSeconds: focusMins * 60,
      totalSeconds: focusMins * 60,
      isRunning: false,
      isBreak: false,
      message: msg,
    );
  }

  void toggleTimer() {
    if (state.isRunning) {
      _timer?.cancel();
      state = state.copyWith(isRunning: false);
    } else {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(isRunning: true);
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (state.remainingSeconds > 0) {
            state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
          } else {
            _timer?.cancel();
            _handleSessionEnd();
          }
        });
      }
    }
  }

  void resetTimer() {
    _timer?.cancel();
    int mins = state.isBreak ? state.breakMinutes : state.focusMinutes;
    state = state.copyWith(
      remainingSeconds: mins * 60,
      totalSeconds: mins * 60,
      isRunning: false,
    );
  }

  void skipSession() {
    _timer?.cancel();
    _handleSessionEnd();
  }

  void _handleSessionEnd() {
    if (state.isBreak) {
      // Break ended, switch to focus
      state = state.copyWith(
        isBreak: false,
        remainingSeconds: state.focusMinutes * 60,
        totalSeconds: state.focusMinutes * 60,
        isRunning: false,
        message: 'Mola bitti! Yeni bir odak seansına hazır mısın?',
      );
    } else {
      // Focus ended, record streak and switch to break
      _ref.read(streakProvider.notifier).recordActivity();

      state = state.copyWith(
        isBreak: true,
        remainingSeconds: state.breakMinutes * 60,
        totalSeconds: state.breakMinutes * 60,
        isRunning: false,
        completedSessionsToday: state.completedSessionsToday + 1,
        message: 'Harika iş çıkardın! Şimdi dinlenme vakti. ☕',
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pomodoroProvider = StateNotifierProvider<PomodoroNotifier, PomodoroState>((ref) {
  return PomodoroNotifier(ref);
});
