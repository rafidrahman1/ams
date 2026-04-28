import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'endpoints.dart';

class ApiClient {
  final TokenStorage storage;
  final http.Client _http;
  final Duration timeout;

  ApiClient(this.storage, {http.Client? httpClient, this.timeout = const Duration(seconds: 20)}) : _http = httpClient ?? http.Client();

  Uri _uri(String path) => AppConfig.apiBaseUri.resolve(path);

  Future<http.Response> get(String path, {bool auth = false}) async {
    final headers = await _buildHeaders(auth: auth);

    final res = await _http.get(_uri(path), headers: headers).timeout(timeout);

    if (res.statusCode == 401 && auth) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        final retriedHeaders = await _buildHeaders(auth: auth);
        return _http.get(_uri(path), headers: retriedHeaders).timeout(timeout);
      }
    }

    return res;
  }

  Future<http.Response> postFormData(String path, {required Map<String, String> fields, Map<String, String>? files, bool auth = false}) async {
    final headers = await _buildHeadersForMultipart(auth: auth);
    final request = http.MultipartRequest('POST', _uri(path));

    request.headers.addAll(headers);
    request.fields.addAll(fields);

    if (files != null) {
      for (final entry in files.entries) {
        final file = http.MultipartFile.fromString(entry.key, entry.value);
        request.files.add(file);
      }
    }

    final response = await request.send().timeout(timeout);
    final res = await http.Response.fromStream(response);

    // 🔁 auto refresh if expired
    if (res.statusCode == 401 && auth) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        final retriedHeaders = await _buildHeadersForMultipart(auth: auth);
        final retriedRequest = http.MultipartRequest('POST', _uri(path));
        retriedRequest.headers.addAll(retriedHeaders);
        retriedRequest.fields.addAll(fields);
        if (files != null) {
          for (final entry in files.entries) {
            final file = http.MultipartFile.fromString(entry.key, entry.value);
            retriedRequest.files.add(file);
          }
        }
        final retriedResponse = await retriedRequest.send().timeout(timeout);
        return await http.Response.fromStream(retriedResponse);
      }
    }

    return res;
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body, bool auth = false}) async {
    final headers = await _buildHeaders(auth: auth);

    final encodedBody = body == null ? null : jsonEncode(body);
    final res = await _http.post(_uri(path), headers: headers, body: encodedBody).timeout(timeout);

    // 🔁 auto refresh if expired
    if (res.statusCode == 401 && auth) {
      final refreshed = await _refreshToken();

      if (refreshed) {
        final retriedHeaders = await _buildHeaders(auth: auth);

        return _http.post(_uri(path), headers: retriedHeaders, body: encodedBody).timeout(timeout);
      }
    }

    return res;
  }

  Future<http.Response> postFormDataWithFile(
    String path, {
    required Map<String, String> fields,
    Map<String, String>? filePaths,
    bool auth = false,
  }) async {
    final headers = await _buildHeadersForMultipart(auth: auth);
    final request = http.MultipartRequest('POST', _uri(path));

    request.headers.addAll(headers);
    request.fields.addAll(fields);

    if (filePaths != null) {
      for (final entry in filePaths.entries) {
        final file = File(entry.value);
        if (await file.exists()) {
          final fileContent = await file.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(entry.key, fileContent, filename: file.path.split('/').last),
          );
        }
      }
    }

    final response = await request.send().timeout(timeout);
    final res = await http.Response.fromStream(response);

    // 🔁 auto refresh if expired
    if (res.statusCode == 401 && auth) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        final retriedHeaders = await _buildHeadersForMultipart(auth: auth);
        final retriedRequest = http.MultipartRequest('POST', _uri(path));
        retriedRequest.headers.addAll(retriedHeaders);
        retriedRequest.fields.addAll(fields);
        if (filePaths != null) {
          for (final entry in filePaths.entries) {
            final file = File(entry.value);
            if (await file.exists()) {
              final fileContent = await file.readAsBytes();
              retriedRequest.files.add(
                http.MultipartFile.fromBytes(entry.key, fileContent, filename: file.path.split('/').last),
              );
            }
          }
        }
        final retriedResponse = await retriedRequest.send().timeout(timeout);
        return await http.Response.fromStream(retriedResponse);
      }
    }

    return res;
  }

  Future<Map<String, String>> _buildHeaders({required bool auth}) async {
    final headers = <String, String>{"Accept": "application/json", "Content-Type": "application/json"};

    if (auth) {
      final token = await storage.getAccess();
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    return headers;
  }

  Future<Map<String, String>> _buildHeadersForMultipart({required bool auth}) async {
    final headers = <String, String>{"Accept": "application/json"};

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

    final res = await _http.post(_uri(Endpoints.refresh), headers: {"Content-Type": "application/json"}, body: jsonEncode({"refresh": refresh})).timeout(timeout);

    if (res.statusCode == 200) {
      final data = _tryDecodeJson(res.body);
      if (data is! Map<String, dynamic>) {
        await storage.clear();
        return false;
      }

      final access = data["access_token"];
      if (access is! String || access.isEmpty) {
        await storage.clear();
        return false;
      }

      await storage.saveTokens(access, refresh);

      return true;
    }

    await storage.clear();
    return false;
  }

  Object? _tryDecodeJson(String source) {
    try {
      return jsonDecode(source);
    } catch (_) {
      return null;
    }
  }
}
