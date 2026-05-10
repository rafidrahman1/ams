import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/logging/app_log.dart';
import 'core/logging/riverpod_observer.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        AppLog.error('FlutterError', error: details.exception, stackTrace: details.stack);
      };

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        AppLog.error('Uncaught platform error', error: error, stackTrace: stackTrace);
        return true;
      };

      runApp(ProviderScope(observers: [AppProviderObserver()], child: const App()));
    },
    (error, stackTrace) {
      AppLog.error('Uncaught zone error', error: error, stackTrace: stackTrace);
    },
  );
}
