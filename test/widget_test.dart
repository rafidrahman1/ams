import 'package:asset_management_system/features/auth/presentation/providers/auth_provider.dart';
import 'package:asset_management_system/features/auth/presentation/screens/login_screen.dart';
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
}
