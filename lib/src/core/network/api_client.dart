import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';
import 'endpoints.dart';

class ApiClient {
  final TokenStorage storage;

  ApiClient(this.storage);

  Future<http.Response> get(String path, {bool auth = false}) async {
    final headers = await _buildHeaders(auth: auth);

    final res = await http.get(
      Uri.parse(Endpoints.baseUrl + path),
      headers: headers,
    );

    if (res.statusCode == 401 && auth) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        final retriedHeaders = await _buildHeaders(auth: auth);
        return http.get(
          Uri.parse(Endpoints.baseUrl + path),
          headers: retriedHeaders,
        );
      }
    }

    return res;
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final headers = await _buildHeaders(auth: auth);

    final res = await http.post(
      Uri.parse(Endpoints.baseUrl + path),
      headers: headers,
      body: jsonEncode(body),
    );

    // 🔁 auto refresh if expired
    if (res.statusCode == 401 && auth) {
      final refreshed = await _refreshToken();

      if (refreshed) {
        final retriedHeaders = await _buildHeaders(auth: auth);

        return await http.post(
          Uri.parse(Endpoints.baseUrl + path),
          headers: retriedHeaders,
          body: jsonEncode(body),
        );
      }
    }

    return res;
  }

  Future<Map<String, String>> _buildHeaders({required bool auth}) async {
    final headers = <String, String>{"Content-Type": "application/json"};

    if (auth) {
      final token = await storage.getAccess();
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    return headers;
  }

  Future<bool> _refreshToken() async {
    final refresh = await storage.getRefresh();
    if (refresh == null) return false;

    final res = await http.post(
      Uri.parse(Endpoints.baseUrl + Endpoints.refresh),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh": refresh}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      await storage.saveTokens(data["access_token"], refresh);

      return true;
    }

    await storage.clear();
    return false;
  }
}
