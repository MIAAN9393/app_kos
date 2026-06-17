import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String _truncateMessage(String msg, {int max = 280}) {
    final t = msg.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max)}…';
  }

  /// Jangan kirim HTML / stack trace Node ke UI.
  static String _sanitizeErrorBody(String body) {
    final lower = body.toLowerCase();
    if (lower.contains('<!doctype') ||
        lower.contains('<html') ||
        body.contains('node_modules') ||
        body.contains('at ') && body.contains('.js:')) {
      return 'Terjadi kesalahan pada server. Periksa log backend.';
    }
    return _truncateMessage(body.replaceAll(RegExp(r'\s+'), ' '));
  }

  dynamic _handleResponse(http.Response res) {
    final status = res.statusCode;
    final body = res.body;
    final contentType = res.headers['content-type'] ?? '';

    dynamic decoded;
    if (contentType.contains('application/json') && body.isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        decoded = null;
      }
    }

    if (status < 200 || status >= 300) {
      String message = 'Permintaan gagal (HTTP $status)';
      if (decoded is Map) {
        message = decoded['pesan']?.toString() ??
            decoded['message']?.toString() ??
            message;
      } else if (body.isNotEmpty) {
        message = _sanitizeErrorBody(body);
      }
      throw Exception(_truncateMessage(message));
    }

    if (decoded == null) {
      if (body.isEmpty) return <String, dynamic>{};
      throw Exception('Respon bukan JSON yang valid');
    }

    return decoded;
  }

  Future<void> saveToken(String key, String value) async {
    try {
      final pref = await SharedPreferences.getInstance();
      await pref.setString(key, value);
    } catch (_) {
      rethrow;
    }
  }

  Future<String?> getToken(String key) async {
    try {
      final pref = await SharedPreferences.getInstance();
      return pref.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearToken(String key) async {
    try {
      final pref = await SharedPreferences.getInstance();
      await pref.remove(key);
    } catch (_) {}
  }

  //untuk windowdestop
  // final String baseUrl = "http://localhost:3000/api";

  //device dari virtual android studio
  // final String baseUrl = "http://10.0.2.2:3003/api";

  //untuk perangkat keras android
  final String baseUrl = "http://192.168.100.6:3000/api";

  Future<Map<String, String>> headers() async {
    final token = await getToken("access_token");
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) async {
    final res = await http.get(
      Uri.parse('$baseUrl/$path'),
      headers: await headers(),
    );
    final data = _handleResponse(res);
    var token = await getToken("access_token");
    print("ini TOKEN : ${token}");
    return {
      "statusCode": res.statusCode,
      "data": data,
    };
  }

  Future<dynamic> post(String path, dynamic body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$path'),
      headers: await headers(),
      body: jsonEncode(body),
    );
    final data = _handleResponse(res);
    return {
      "statusCode": res.statusCode,
      "data": data,
    };
  }

  Future<dynamic> put(String path, dynamic body) async {
    final res = await http.put(
      Uri.parse('$baseUrl/$path'),
      headers: await headers(),
      body: jsonEncode(body),
    );
    final data = _handleResponse(res);
    return {
      "statusCode": res.statusCode,
      "data": data,
    };
  }

  /// Soft-delete di backend memakai PUT (bukan DELETE).
  Future<dynamic> sdelete(String path) async {
    final res = await http.put(
      Uri.parse('$baseUrl/$path'),
      headers: await headers(),
    );
    final data = _handleResponse(res);
    return {
      "statusCode": res.statusCode,
      "data": data,
    };
  }
}
