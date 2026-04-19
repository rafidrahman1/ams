import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';
import 'endpoints.dart';

class ApiClient {
  final TokenStorage storage;

  ApiClient(this.storage);

  Future<http.Response> post(
      String path, {
        Map<String, dynamic>? body,
        bool auth = false,
      }) async {
    final headers = {
      "Content-Type": "application/json",
    };

    if (auth) {
      final token = await storage.getAccess();
      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    final res = await http.post(
      Uri.parse(Endpoints.baseUrl + path),
      headers: headers,
      body: jsonEncode(body),
    );

    // 🔁 auto refresh if expired
    if (res.statusCode == 401 && auth) {
      final refreshed = await _refreshToken();

      if (refreshed) {
        final newToken = await storage.getAccess();
        headers["Authorization"] = "Bearer $newToken";

        return await http.post(
          Uri.parse(Endpoints.baseUrl + path),
          headers: headers,
          body: jsonEncode(body),
        );
      }
    }

    return res;
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

      await storage.saveTokens(
        data["access_token"],
        refresh,
      );

      return true;
    }

    await storage.clear();
    return false;
  }
}