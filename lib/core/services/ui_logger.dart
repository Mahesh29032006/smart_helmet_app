import 'package:flutter/foundation.dart';

/// Service to record and notify user interface interactions.
class UiLogger {
  static final List<String> _logs = [];

  static List<String> get logs => List.unmodifiable(_logs);

  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final formatted = '[$timestamp] [UI] $message';
    _logs.insert(0, formatted);
    if (_logs.length > 200) {
      _logs.removeLast();
    }
    if (kDebugMode) {
      print('[UI] $message');
    }
  }

  static void clear() {
    _logs.clear();
  }
}
