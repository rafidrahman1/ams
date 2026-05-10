import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/locale_provider.dart';
import '../theme/colors.dart';

class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        key: const Key('language_toggle_switch_home'),
        onTap: () => ref.read(localeProvider.notifier).toggleLanguage(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 58,
          height: 34,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: ThemeColor.primary.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(999)),
          child: Align(
            alignment: locale.languageCode == 'bn' ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: ThemeColor.white, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                locale.languageCode == 'bn' ? 'বা' : 'EN',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ThemeColor.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
