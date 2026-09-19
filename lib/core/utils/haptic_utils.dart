import 'package:flutter/services.dart';

/// Convenience wrappers around [HapticFeedback] for OmniBrain AI.
///
/// Call these static methods from gesture callbacks to give the user
/// tactile confirmation of their interactions.
abstract final class HapticUtils {
  /// A subtle tap – used for toggle switches, chip selections, minor taps.
  static Future<void> lightImpact() =>
      HapticFeedback.lightImpact();

  /// A moderate tap – used for button presses, card taps.
  static Future<void> mediumImpact() =>
      HapticFeedback.mediumImpact();

  /// A strong tap – used for destructive actions, long-press confirmations.
  static Future<void> heavyImpact() =>
      HapticFeedback.heavyImpact();

  /// A tiny tick – used for picker scrolls, selection changes.
  static Future<void> selectionClick() =>
      HapticFeedback.selectionClick();
}
