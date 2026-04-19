import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/colors.dart';
import 'theme/textStyles.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/home_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: ThemeColor.backGroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ThemeColor.primary,
          primary: ThemeColor.primary,
        ),
        textTheme: TextTheme(
          titleLarge: ThemeTextStyles.heading,
          bodyMedium: ThemeTextStyles.values,
          labelLarge: ThemeTextStyles.label,
        ),
      ),
      home: switch (auth) {
        AuthStatus.loading => const Scaffold(
            body: Center(child: CircularProgressIndicator())),
        AuthStatus.authenticated => const HomeScreen(),
        AuthStatus.unauthenticated => const LoginScreen(),
      },
    );
  }
}