import '../../../../core/storage/token_storage.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService service;
  final TokenStorage storage;

  AuthRepository(this.service, this.storage);

  Future<void> login(String email, String password) async {
    final res = await service.login(email, password);

    await storage.saveTokens(res.access, res.refresh);
  }

  Future<bool> isLoggedIn() async {
    final token = await storage.getAccess();
    return token != null;
  }

  Future<void> logout() async {
    await storage.clear();
  }
}