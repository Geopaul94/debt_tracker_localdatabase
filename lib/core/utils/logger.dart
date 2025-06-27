import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
    // No logging in release builds to reduce APK size
  }

  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('ERROR: $message${error != null ? ' - $error' : ''}');
    }
    // No error logging in release builds
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('INFO: $message');
    }
    // No info logging in release builds
  }
}
