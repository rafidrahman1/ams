import '../../../../core/storage/token_storage.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService service;
  final TokenStorage storage;

  AuthRepository(this.service, this.storage);

  Future<void> login(String email, String password) async {
    final res = await service.login(email, password);

    if (res.access.isEmpty || res.refresh.isEmpty) {
      throw Exception('Invalid login response');
    }

    await storage.saveTokens(res.access, res.refresh);
  }

  Future<bool> isLoggedIn() async {
    final token = await storage.getAccess();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await storage.clear();
  }
}