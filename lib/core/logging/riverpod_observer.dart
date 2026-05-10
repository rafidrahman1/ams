import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_log.dart';

final class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderObserverContext context, Object? previousValue, Object? newValue) {
    if (kReleaseMode) return;
    AppLog.info('Provider updated: ${context.provider.name ?? context.provider.runtimeType}', name: 'riverpod');
  }

  @override
  void providerDidFail(ProviderObserverContext context, Object error, StackTrace stackTrace) {
    AppLog.error('Provider failed: ${context.provider.name ?? context.provider.runtimeType}', name: 'riverpod', error: error, stackTrace: stackTrace);
  }
}
