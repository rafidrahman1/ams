import 'dart:convert';

import 'package:asset_management_system/core/network/api_client.dart';
import 'package:asset_management_system/core/network/endpoints.dart';
import 'package:http/http.dart' as http;

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

  Future<LoginResponse> volunteerQrLogin(String volunteerId) async {
    final cleanedVolunteerId = volunteerId.trim();

    if (cleanedVolunteerId.isEmpty) {
      throw Exception("Volunteer ID is required");
    }

    final res = await client.post(Endpoints.volunteerQrLogin, body: {"volunteer_id": cleanedVolunteerId});

    return _parseLoginResponse(res);
  }

  Future<LoginResponse> _login(String endpoint, String email, String password) async {
    final cleanedEmail = email.trim();
    final cleanedPassword = password.trim();

    if (cleanedEmail.isEmpty || cleanedPassword.isEmpty) {
      throw Exception("Email and password are required");
    }

    final res = await client.post(endpoint, body: {"email": cleanedEmail, "password": cleanedPassword});

    return _parseLoginResponse(res);
  }

  LoginResponse _parseLoginResponse(http.Response res) {
    final data = _decodeJsonMap(res.body);
    if (res.statusCode != 200 || data == null) {
      throw Exception(_readAuthErrorMessage(data) ?? "Login failed");
    }

    final loginResponse = LoginResponse.fromAuthBody(data);
    final hasValidTokens = loginResponse.access.isNotEmpty && loginResponse.refresh.isNotEmpty;
    final hasSuccessCode = loginResponse.code == 200;

    if (hasSuccessCode && hasValidTokens) {
      return loginResponse;
    }

    throw Exception(_readAuthErrorMessage(data) ?? "Login failed");
  }

  Map<String, dynamic>? _decodeJsonMap(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String? _readAuthErrorMessage(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }

    final message = data['message']?.toString().trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }

    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map) {
        final nested = first['message']?.toString().trim();
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return null;
  }
}
