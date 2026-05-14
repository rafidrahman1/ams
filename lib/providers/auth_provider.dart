import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/auth_service.dart';
import 'asset_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(authServiceProvider), ref.read(tokenStorageProvider), ref.read(assetRepositoryProvider));
});

enum AuthStatus { loading, authenticatedVolunteer, authenticatedAdmin, unauthenticated }

class AuthNotifier extends Notifier<AuthStatus> {
  static const _minimumStartupSplash = Duration(seconds: 2);
  Timer? _autoLogoutTimer;
  Object? _lastError;

  AuthRepository get repo => ref.read(authRepositoryProvider);

  Object? get lastError => _lastError;

  @override
  AuthStatus build() {
    ref.onDispose(() => _autoLogoutTimer?.cancel());
    Future.microtask(checkLogin);
    return AuthStatus.loading;
  }

  void _startAutoLogoutCheck() {
    _autoLogoutTimer?.cancel();
    _autoLogoutTimer = null;

    if (state != AuthStatus.authenticatedVolunteer) {
      return;
    }

    unawaited(_performAutoLogoutCheck());
    _autoLogoutTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      unawaited(_performAutoLogoutCheck());
    });
  }

  Future<void> _performAutoLogoutCheck() async {
    if (state != AuthStatus.authenticatedVolunteer) {
      return;
    }

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
    ref.invalidate(adminAssetsProvider);
    ref.invalidate(campLocationsProvider);
    ref.invalidate(assetTypesProvider);
    ref.invalidate(blocksProvider);
    ref.invalidate(assetChecklistProvider);
    ref.invalidate(assetChecklistAllTrueProvider);
    ref.invalidate(homeBootstrapProvider);
    ref.invalidate(adminHomeBootstrapProvider);
  }

  Future<void> checkLogin() async {
    _lastError = null;
    final loggedInFuture = repo.isLoggedIn();
    final delayFuture = Future<void>.delayed(_minimumStartupSplash);

    final loggedIn = await loggedInFuture;
    await delayFuture;

    if (!loggedIn) {
      state = AuthStatus.unauthenticated;
      return;
    }

    final role = await repo.getSessionRole();
    state = role == 'admin' ? AuthStatus.authenticatedAdmin : AuthStatus.authenticatedVolunteer;
    if (state != AuthStatus.unauthenticated) {
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
      _lastError = null;
      await repo.login(cleanedEmail, cleanedPassword);
      state = AuthStatus.authenticatedVolunteer;
      _invalidateSessionScopedProviders();
      _startAutoLogoutCheck();
    } catch (error) {
      _lastError = error;
      state = AuthStatus.unauthenticated;
    }
  }

  Future<void> adminLogin(String email, String password) async {
    final cleanedEmail = email.trim();
    final cleanedPassword = password.trim();

    if (cleanedEmail.isEmpty || cleanedPassword.isEmpty) {
      state = AuthStatus.unauthenticated;
      return;
    }

    try {
      _lastError = null;
      await repo.adminLogin(cleanedEmail, cleanedPassword);
      state = AuthStatus.authenticatedAdmin;
      _invalidateSessionScopedProviders();
      _startAutoLogoutCheck();
    } catch (error) {
      _lastError = error;
      state = AuthStatus.unauthenticated;
    }
  }

  Future<void> logout() async {
    _autoLogoutTimer?.cancel();
    _lastError = null;
    await repo.logout();
    state = AuthStatus.unauthenticated;
    _invalidateSessionScopedProviders();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(AuthNotifier.new);
