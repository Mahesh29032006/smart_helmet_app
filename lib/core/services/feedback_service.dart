import 'package:flutter/services.dart';

/// Helper service for vibration and auditory feedback during emergency states.
class FeedbackService {
  static Future<void> triggerEmergencyAlarm({bool enabled = true}) async {
    if (!enabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // Graceful fallback for test and unsupported environments
    }
  }

  static Future<void> triggerVibration({bool enabled = true}) async {
    if (!enabled) return;
    try {
      await HapticFeedback.vibrate();
    } catch (_) {
      // Graceful fallback
    }
  }

  static Future<void> triggerSelection({bool enabled = true}) async {
    if (!enabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Graceful fallback
    }
  }
}
