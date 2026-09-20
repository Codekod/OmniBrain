import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class PomodoroSoundService {
  static final AudioPlayer _player = AudioPlayer();

  /// Play audio/sound cue when timer starts
  static Future<void> playTimerStart() async {
    try {
      HapticFeedback.mediumImpact();
      await _player.stop();
      await _player.play(AssetSource('audio/bell.mp3'), volume: 0.8);
    } catch (_) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Play triumphant chime when timer completes
  static Future<void> playTimerComplete() async {
    try {
      HapticFeedback.heavyImpact();
      await _player.stop();
      await _player.play(AssetSource('audio/bell.mp3'), volume: 1.0);
      await Future.delayed(const Duration(milliseconds: 600));
      HapticFeedback.vibrate();
      await _player.play(AssetSource('audio/bell.mp3'), volume: 1.0);
    } catch (_) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }
}
