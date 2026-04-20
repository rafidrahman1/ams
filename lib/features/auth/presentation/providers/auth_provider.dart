import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/auth_service.dart';

final tokenStorageProvider = Provider((ref) => TokenStorage());

final apiClientProvider = Provider((ref) {
  return ApiClient(ref.read(tokenStorageProvider));
});

final authServiceProvider = Provider((ref) {
  return AuthService(ref.read(apiClientProvider));
});

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(ref.read(authServiceProvider), ref.read(tokenStorageProvider));
});

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthNotifier extends Notifier<AuthStatus> {
  static const _minimumStartupSplash = Duration(seconds: 2);

  AuthRepository get repo => ref.read(authRepositoryProvider);

  @override
  AuthStatus build() {
    Future.microtask(checkLogin);
    return AuthStatus.loading;
  }

  Future<void> checkLogin() async {
    final loggedInFuture = repo.isLoggedIn();
    final delayFuture = Future<void>.delayed(_minimumStartupSplash);

    final loggedIn = await loggedInFuture;
    await delayFuture;

    state = loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }

  Future<void> login(String email, String password) async {
    final cleanedEmail = email.trim();
    final cleanedPassword = password.trim();

    if (cleanedEmail.isEmpty || cleanedPassword.isEmpty) {
      state = AuthStatus.unauthenticated;
      return;
    }

    try {
      await repo.login(cleanedEmail, cleanedPassword);
      state = AuthStatus.authenticated;
    } catch (_) {
      state = AuthStatus.unauthenticated;
    }
  }

  Future<void> logout() async {
    await repo.logout();
    state = AuthStatus.unauthenticated;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(AuthNotifier.new);
