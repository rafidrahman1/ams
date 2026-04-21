import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final deviceLanguageCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (deviceLanguageCode == 'bn') {
      return const Locale('bn');
    }
    return const Locale('en');
  }

  void toggleLanguage() {
    state = state.languageCode == 'bn' ? const Locale('en') : const Locale('bn');
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

