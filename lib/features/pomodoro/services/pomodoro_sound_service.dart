import 'package:flutter/services.dart';

class PomodoroSoundService {

  /// Play audio/sound cue when timer starts
  static Future<void> playTimerStart() async {
    try {
      HapticFeedback.mediumImpact();
      // Use system sound alert as primary reliable iOS system sound
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  /// Play triumphant chime when timer completes
  static Future<void> playTimerComplete() async {
    try {
      HapticFeedback.heavyImpact();
      await SystemSound.play(SystemSoundType.alert);
      // Wait a bit and play another chime for double bell effect
      await Future.delayed(const Duration(milliseconds: 400));
      HapticFeedback.vibrate();
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }
}
