import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void d(final String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  static void i(final String message) {
    debugPrint('[INFO] $message');
  }

  static void w(final String message) {
    debugPrint('[WARNING] $message');
  }

  static void e(
    final String message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    debugPrint('[ERROR] $message');
    if (error != null) {
      debugPrint('Details: $error');
    }
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }
}
