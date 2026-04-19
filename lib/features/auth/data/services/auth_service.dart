import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../models/login_response.dart';

class AuthService {
  final ApiClient client;

  AuthService(this.client);

  Future<LoginResponse> login(String email, String password) async {
    final res = await client.post(
      Endpoints.login,
      body: {
        "email": email,
        "password": password,
      },
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return LoginResponse.fromJson(data);
    }

    throw Exception("Login failed");
  }
}