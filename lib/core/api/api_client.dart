import 'package:zenjigodriver/core/friendly_errors.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  /// Default targets the host from an Android emulator. Override at build time:
  ///   flutter run --dart-define=ZENJIGO_API_URL=http://10.0.2.2:5000/api/v1
  /// Android emulator → host machine: 10.0.2.2
  /// iOS simulator → host: 127.0.0.1
  /// Physical device → your PC LAN IP (same Wi‑Fi), e.g. http://192.168.x.x:5000/api/v1
  static const baseUrl = String.fromEnvironment(
    'ZENJIGO_API_URL',
    defaultValue: 'https://zenjigo-backend.onrender.com/api/v1',
  );

  static const Duration requestTimeout = Duration(seconds: 60);

  static Future<String?> get accessToken async => _token();

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  static Future<String?> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  static Exception _mapNetworkError(Object e) {
    // Always surface a short, driver-friendly message (no host URLs / stack traces).
    return Exception(FriendlyErrors.message(e));
  }

  /// Prefer API `message` field; otherwise a friendly status-based text.
  static Exception _mapHttpError(int status, Map<String, dynamic>? json, String body) {
    final msg = (json?['message'] ?? json?['error'] ?? '').toString().trim();
    if (msg.isNotEmpty && msg.length < 200) {
      return Exception(msg);
    }
    return Exception(FriendlyErrors.message('HTTP $status $body'));
  }

  static Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _token();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    Future<http.Response> send() async {
      final uri = Uri.parse('$baseUrl$path');
      final Future<http.Response> future;
      switch (method.toUpperCase()) {
        case 'GET':
          future = http.get(uri, headers: headers);
          break;
        case 'PATCH':
          future = http.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
          break;
        case 'PUT':
          future = http.put(uri, headers: headers, body: jsonEncode(body ?? {}));
          break;
        case 'DELETE':
          future = http.delete(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
          break;
        default:
          future = http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
      }
      return future.timeout(requestTimeout);
    }

    late http.Response response;
    try {
      response = await send();
    } catch (e) {
      throw _mapNetworkError(e);
    }

    // Try refresh once on 401
    if (response.statusCode == 401 && auth) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final token = await _token();
        if (token != null) headers['Authorization'] = 'Bearer $token';
        try {
          response = await send();
        } catch (e) {
          throw _mapNetworkError(e);
        }
      }
    }

    Map<String, dynamic> decoded;
    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(FriendlyErrors.message('Invalid server response ${response.statusCode}'));
    }

    if (response.statusCode < 200 || response.statusCode >= 300 || decoded['success'] == false) {
      final msg = (decoded['message'] ?? decoded['error'] ?? '').toString().trim();
      if (msg.isNotEmpty) throw Exception(msg);
      throw Exception(FriendlyErrors.message('HTTP ${response.statusCode}'));
    }

    return decoded;
  }

  static Future<bool> _tryRefresh() async {
    try {
      final rt = await _refreshToken();
      if (rt == null || rt.isEmpty) return false;
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': rt}),
          )
          .timeout(requestTimeout);
      if (res.statusCode < 200 || res.statusCode >= 300) return false;
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final data = Map<String, dynamic>.from(decoded['data'] ?? decoded);
      await save(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> save(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final access = data['accessToken'] ?? data['access_token'];
    final refresh = data['refreshToken'] ?? data['refresh_token'];
    if (access != null) await prefs.setString('accessToken', access.toString());
    if (refresh != null) await prefs.setString('refreshToken', refresh.toString());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
  }

  /// Returns the unwrapped `data` field from a successful API response.
  static Future<dynamic> data(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final res = await request(method, path, body: body, auth: auth);
    return res['data'];
  }
}
