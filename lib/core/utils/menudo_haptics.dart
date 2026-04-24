import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

abstract final class MenudoHaptics {
  static Future<void> selection() =>
      _vibrate(HapticsType.selection, fallback: HapticFeedback.selectionClick);

  static Future<void> light() =>
      _vibrate(HapticsType.light, fallback: HapticFeedback.lightImpact);

  static Future<void> medium() =>
      _vibrate(HapticsType.medium, fallback: HapticFeedback.mediumImpact);

  static Future<void> heavy() =>
      _vibrate(HapticsType.heavy, fallback: HapticFeedback.heavyImpact);

  static Future<void> success() =>
      _vibrate(HapticsType.success, fallback: HapticFeedback.mediumImpact);

  static Future<void> warning() =>
      _vibrate(HapticsType.warning, fallback: HapticFeedback.mediumImpact);

  static Future<void> error() =>
      _vibrate(HapticsType.error, fallback: HapticFeedback.heavyImpact);

  static Future<void> _vibrate(
    HapticsType type, {
    required Future<void> Function() fallback,
  }) async {
    try {
      await Haptics.vibrate(type, useAndroidHapticConstants: true);
    } catch (_) {
      await fallback();
    }
  }
}
