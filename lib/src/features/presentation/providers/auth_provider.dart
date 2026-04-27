import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/auth_service.dart';
import 'asset_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(authServiceProvider), ref.read(tokenStorageProvider), ref.read(assetRepositoryProvider));
});

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthNotifier extends Notifier<AuthStatus> {
  static const _minimumStartupSplash = Duration(seconds: 2);
  Timer? _autoLogoutTimer;

  AuthRepository get repo => ref.read(authRepositoryProvider);

  @override
  AuthStatus build() {
    ref.onDispose(() => _autoLogoutTimer?.cancel());
    Future.microtask(checkLogin);
    return AuthStatus.loading;
  }

  void _startAutoLogoutCheck() {
    _autoLogoutTimer?.cancel();
    unawaited(_performAutoLogoutCheck());
    _autoLogoutTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      unawaited(_performAutoLogoutCheck());
    });
  }

  Future<void> _performAutoLogoutCheck() async {
    final now = DateTime.now();
    if (now.hour == 23 && now.minute == 59) {
      await ref.read(localDatabaseProvider).clearAll();
      await logout();
    }
  }

  void _invalidateSessionScopedProviders() {
    // These providers are effectively session-scoped, but some are keyed only by
    // `astId` (not by user). If the user changes, we must invalidate them to
    // prevent showing stale data from the previous session.
    ref.invalidate(myAssetsProvider);
    ref.invalidate(assetChecklistProvider);
    ref.invalidate(assetChecklistAllTrueProvider);
    ref.invalidate(homeBootstrapProvider);
  }

  Future<void> checkLogin() async {
    final loggedInFuture = repo.isLoggedIn();
    final delayFuture = Future<void>.delayed(_minimumStartupSplash);

    final loggedIn = await loggedInFuture;
    await delayFuture;

    state = loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    if (state == AuthStatus.authenticated) {
      _startAutoLogoutCheck();
    }
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
      _invalidateSessionScopedProviders();
      _startAutoLogoutCheck();
    } catch (_) {
      state = AuthStatus.unauthenticated;
    }
  }

  Future<void> logout() async {
    _autoLogoutTimer?.cancel();
    await repo.logout();
    state = AuthStatus.unauthenticated;
    _invalidateSessionScopedProviders();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(AuthNotifier.new);
