import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/presentation/providers/auth_provider.dart';
import '../features/presentation/providers/locale_provider.dart';
import '../features/presentation/screens/home_screen.dart';
import '../features/presentation/screens/login_screen.dart';
import '../features/presentation/screens/splash_screen.dart';
import '../theme/colors.dart';
import '../theme/textStyles.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('bn')],
      theme: ThemeData(
        scaffoldBackgroundColor: ThemeColor.backGroundColor,
        colorScheme: ColorScheme.fromSeed(seedColor: ThemeColor.primary, primary: ThemeColor.primary),
        textTheme: TextTheme(titleLarge: ThemeTextStyles.heading, bodyMedium: ThemeTextStyles.values, labelLarge: ThemeTextStyles.label),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        // Avoid AnimatedSwitcher here: it would keep both old+new Navigators
        // during the transition, which triggers duplicate GlobalKey errors.
        return TweenAnimationBuilder<double>(
          key: ValueKey<String>(locale.languageCode),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0.0, end: 1.0),
          child: child,
          builder: (context, value, child) => Opacity(opacity: value, child: child),
        );
      },
      home: switch (auth) {
        AuthStatus.loading => const SplashScreen(),
        AuthStatus.authenticated => const HomeScreen(),
        AuthStatus.unauthenticated => const LoginScreen(),
      },
    );
  }
}
