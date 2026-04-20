import 'package:asset_management_system/features/auth/presentation/providers/auth_provider.dart';
import 'package:asset_management_system/features/auth/presentation/screens/home_screen.dart';
import 'package:asset_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:asset_management_system/features/auth/presentation/screens/splash_screen.dart';
import 'package:asset_management_system/features/auth/presentation/widgets/square_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_TestAuthNotifier.new)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    expect(find.byIcon(Icons.contactless), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byType(SquareActionButton).first);
    await tester.pump();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('failed login stays on login screen and does not show splash', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_RejectedLoginAuthNotifier.new)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

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

  testWidgets('opening an asset checklist shows the tapped asset', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('Check List'), findsNWidgets(3));

    await tester.tap(find.text('Check List').first);
    await tester.pumpAndSettle();

    expect(find.text('Checklist for Asset 1'), findsOneWidget);
    expect(find.text('Description of Asset 1'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });
}
