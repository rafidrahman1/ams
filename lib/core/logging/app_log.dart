import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLog {
  static void info(String message, {String name = 'app', Object? error, StackTrace? stackTrace}) {
    _log(message, level: 800, name: name, error: error, stackTrace: stackTrace);
  }

  static void warn(String message, {String name = 'app', Object? error, StackTrace? stackTrace}) {
    _log(message, level: 900, name: name, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {String name = 'app', Object? error, StackTrace? stackTrace}) {
    _log(message, level: 1000, name: name, error: error, stackTrace: stackTrace);
  }

  static void _log(
    String message, {
    required int level,
    required String name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Avoid noisy logs in release unless explicitly needed later.
    if (kReleaseMode && level < 1000) return;
    developer.log(message, name: name, level: level, error: error, stackTrace: stackTrace);
  }
}

