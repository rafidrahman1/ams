import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/locale_provider.dart';
import '../../../theme/colors.dart';

class LanguageToggle extends ConsumerStatefulWidget {
  const LanguageToggle({super.key});

  @override
  ConsumerState<LanguageToggle> createState() => _LanguageToggleState();
}

class _LanguageToggleState extends ConsumerState<LanguageToggle> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        key: const Key('language_toggle_switch_home'),
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () => ref.read(localeProvider.notifier).toggleLanguage(),
        onTapUp: (_) => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 58,
          height: 34,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: ThemeColor.primary.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Align(
            alignment: locale.languageCode == 'bn' ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              scale: _isPressed ? 0.96 : 1,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: ThemeColor.white, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: Tween<double>(begin: 0.94, end: 1).animate(animation), child: child),
                    );
                  },
                  child: Text(
                    locale.languageCode == 'bn' ? 'বা' : 'EN',
                    key: ValueKey<String>(locale.languageCode),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ThemeColor.primary),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
