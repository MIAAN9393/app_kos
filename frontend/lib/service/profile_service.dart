import 'package:dio/dio.dart';
import 'package:kos_management/service/api_service.dart';

class ProfileService {
  final ApiService api;

  ProfileService(this.api);

  static Map<String, dynamic> _mapFrom(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  static String _pesanFrom(dynamic data, String fallback) {
    final m = _mapFrom(data);
    return '${m['pesan'] ?? m['message'] ?? fallback}';
  }

  Future<Map<String, dynamic>> ambilProfile() async {
    final res = await api.get('profile');
    final code = res['statusCode'];
    if (code != 200) {
      throw Exception(_pesanFrom(res['data'], 'Ambil profile gagal'));
    }
    return _mapFrom(_mapFrom(res['data'])['data']);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String nama,
    String? fotoPath,
  }) async {
    final formData = FormData.fromMap({
      'nama': nama,
      if (fotoPath != null && fotoPath.isNotEmpty)
        'foto': await MultipartFile.fromFile(fotoPath),
    });

    final dio = Dio(BaseOptions(validateStatus: (status) => status != null));
    final res = await dio.put(
      '${api.baseUrl}/profile',
      data: formData,
      options: Options(headers: await _multipartHeaders()),
    );
    final code = res.statusCode ?? 0;
    if (code != 200) {
      throw Exception(_pesanFrom(res.data, 'Update profile gagal'));
    }
    return _mapFrom(_mapFrom(res.data)['data']);
  }

  Future<Map<String, String>> _multipartHeaders() async {
    final token = await api.getToken('access_token');
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<String> gantiPassword({
    required String passwordLama,
    required String passwordBaru,
  }) async {
    final res = await api.put('profile/password', {
      'password_lama': passwordLama,
      'password_baru': passwordBaru,
    });
    final code = res['statusCode'];
    if (code != 200) {
      throw Exception(_pesanFrom(res['data'], 'Ganti password gagal'));
    }
    return _pesanFrom(res['data'], 'Password berhasil diperbarui');
  }
}
