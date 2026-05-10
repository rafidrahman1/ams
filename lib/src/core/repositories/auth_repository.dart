import 'package:asset_management_system/src/core/storage/token_storage.dart';
import 'package:asset_management_system/src/model/login_response.dart';

import '../../services/auth_service.dart';
import 'asset_repository.dart';

class AuthRepository {
  final AuthService service;
  final TokenStorage storage;
  final AssetRepository assetRepository;

  AuthRepository(this.service, this.storage, this.assetRepository);

  Future<LoginResponse> login(String email, String password) async {
    final res = await service.login(email, password);

    return _persistLogin(res, email, role: 'volunteer');
  }

  Future<LoginResponse> adminLogin(String email, String password) async {
    final res = await service.adminLogin(email, password);

    return _persistLogin(res, email, role: 'admin');
  }

  Future<LoginResponse> _persistLogin(LoginResponse res, String email, {required String role}) async {
    if (res.access.isEmpty || res.refresh.isEmpty) {
      throw Exception('Invalid login response');
    }

    await storage.saveTokens(res.access, res.refresh);
    await storage.saveSessionRole(role);

    final cacheKey = _resolveCacheKey(res, email);
    await storage.saveSessionKey(cacheKey);
    await assetRepository.prefetchOfflineData(cacheKey, isAdmin: role == 'admin');

    return res;
  }

  Future<bool> isLoggedIn() async {
    final token = await storage.getAccess();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final userKey = await storage.getSessionKey();
    await storage.clear();
    if (userKey != null) {
      await assetRepository.clearCache(userKey);
    }
  }

  Future<String?> getSessionRole() => storage.getSessionRole();

  String _resolveCacheKey(LoginResponse response, String fallbackEmail) {
    final email = response.userObject?.email ?? '';
    final trimmedEmail = email.trim();
    if (trimmedEmail.isNotEmpty) {
      return trimmedEmail;
    }

    final username = response.userObject?.username ?? '';
    final trimmedUsername = username.trim();
    if (trimmedUsername.isNotEmpty) {
      return trimmedUsername;
    }

    final fallback = fallbackEmail.trim();
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }
}
