import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final _storage = const FlutterSecureStorage();

  static const _access = "access_token";
  static const _refresh = "refresh_token";
  static const _sessionKey = "session_user_key";

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _access, value: access);
    await _storage.write(key: _refresh, value: refresh);
  }

  Future<String?> getAccess() => _storage.read(key: _access);
  Future<String?> getRefresh() => _storage.read(key: _refresh);
  Future<String?> getSessionKey() => _storage.read(key: _sessionKey);

  Future<void> saveSessionKey(String key) async {
    await _storage.write(key: _sessionKey, value: key);
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
