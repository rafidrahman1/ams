import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/src/features/presentation/providers/auth_provider.dart';
import 'package:asset_management_system/src/features/presentation/screens/home_screen.dart';
import 'package:asset_management_system/src/features/presentation/screens/login_screen.dart';
import 'package:asset_management_system/src/features/presentation/screens/qr_nfc_screen.dart';
import 'package:asset_management_system/src/features/presentation/screens/splash_screen.dart';
import 'package:asset_management_system/src/features/presentation/widgets/square_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _localizedApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('bn')],
    home: child,
  );
}

class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthStatus build() => AuthStatus.unauthenticated;

  @override
  Future<void> login(String email, String password) async {
    state = AuthStatus.authenticated;
  }
}

class _RejectedLoginAuthNotifier extends AuthNotifier {
  @override
  AuthStatus build() => AuthStatus.unauthenticated;

  @override
  Future<void> login(String email, String password) async {}
}

void main() {
  testWidgets('email form only appears after pressing email login', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [authProvider.overrideWith(_TestAuthNotifier.new)], child: _localizedApp(const LoginScreen())));

    expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    expect(find.byIcon(Icons.contactless), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byType(SquareActionButton).first);
    await tester.pump();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('failed login stays on login screen and does not show splash', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [authProvider.overrideWith(_RejectedLoginAuthNotifier.new)], child: _localizedApp(const LoginScreen())));

    await tester.tap(find.byType(SquareActionButton).first);
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'wrong@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Invalid email or password'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('opening an asset checklist goes through QR/NFC first', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(child: _localizedApp(const HomeScreen())));

    expect(find.text('Check List'), findsNWidgets(3));

    await tester.tap(find.text('Check List').first);
    await tester.pumpAndSettle();

    expect(find.byType(QrNfcScreen), findsOneWidget);
    expect(find.text('QR/NFC Scanner'), findsOneWidget);

    await tester.tap(find.text('QR Code'));
    await tester.pumpAndSettle();

    expect(find.text('Checklist for Asset 1'), findsOneWidget);
    expect(find.text('Description of Asset 1'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });
}
