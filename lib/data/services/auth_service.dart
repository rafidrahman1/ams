import 'dart:convert';

import 'package:asset_management_system/core/network/api_client.dart';
import 'package:asset_management_system/core/network/endpoints.dart';

import '../models/login_response.dart';

class AuthService {
  final ApiClient client;

  AuthService(this.client);

  Future<LoginResponse> login(String email, String password) async {
    return _login(Endpoints.login, email, password);
  }

  Future<LoginResponse> adminLogin(String email, String password) async {
    return _login(Endpoints.adminLogin, email, password);
  }

  Future<LoginResponse> _login(String endpoint, String email, String password) async {
    final cleanedEmail = email.trim();
    final cleanedPassword = password.trim();

    if (cleanedEmail.isEmpty || cleanedPassword.isEmpty) {
      throw Exception("Email and password are required");
    }

    final res = await client.post(endpoint, body: {"email": cleanedEmail, "password": cleanedPassword});

    final data = jsonDecode(res.body);

    if (res.statusCode == 200 && data is Map<String, dynamic>) {
      final loginResponse = LoginResponse.fromJson(data);
      final hasValidTokens = loginResponse.access.isNotEmpty && loginResponse.refresh.isNotEmpty;
      final hasSuccessCode = loginResponse.code == 200;

      if (hasSuccessCode && hasValidTokens) {
        return loginResponse;
      }
    }

    throw Exception("Login failed");
  }
}
