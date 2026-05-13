import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/home_screen.dart';
import '../pages/login_screen.dart';
import '../pages/splash_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/qr_scanner_provider.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize scanner service listener
    ref.watch(scannerServiceProvider);

    final auth = ref.watch(authProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      home: switch (auth) {
        AuthStatus.loading => const SplashScreen(),
        AuthStatus.authenticatedVolunteer => const HomeScreen(),
        AuthStatus.authenticatedAdmin => const HomeScreen(isAdmin: true),
        AuthStatus.unauthenticated => const LoginScreen(),
      },
    );
  }
}
