import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PomodoroState {
  final int focusMinutes;
  final int breakMinutes;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final bool isBreak;
  final String message;

  PomodoroState({
    required this.focusMinutes,
    required this.breakMinutes,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.isBreak,
    required this.message,
  });

  PomodoroState copyWith({
    int? focusMinutes,
    int? breakMinutes,
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    bool? isBreak,
    String? message,
  }) {
    return PomodoroState(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      isBreak: isBreak ?? this.isBreak,
      message: message ?? this.message,
    );
  }
}

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  Timer? _timer;

  PomodoroNotifier()
      : super(PomodoroState(
          focusMinutes: 25,
          breakMinutes: 5,
          remainingSeconds: 25 * 60,
          totalSeconds: 25 * 60,
          isRunning: false,
          isBreak: false,
          message: 'Ne üzerinde çalışacaksın?',
        ));

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
      // Mola bitti, çalışmaya dön
      state = state.copyWith(
        isBreak: false,
        remainingSeconds: state.focusMinutes * 60,
        totalSeconds: state.focusMinutes * 60,
        isRunning: false,
        message: 'Mola bitti! Yeni bir odak seansına hazır mısın?',
      );
    } else {
      // Çalışma bitti, molaya geç
      state = state.copyWith(
        isBreak: true,
        remainingSeconds: state.breakMinutes * 60,
        totalSeconds: state.breakMinutes * 60,
        isRunning: false,
        message: 'Harika iş çıkardın! Şimdi dinlenme vakti.',
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
  return PomodoroNotifier();
});
