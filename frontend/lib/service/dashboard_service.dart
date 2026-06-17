import 'package:kos_management/service/api_service.dart';

class DashboardService {
  final ApiService api;

  DashboardService(this.api);

  static Map<String, dynamic> _bodyMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  static String _pesanFrom(dynamic data, String fallback) {
    final m = _bodyMap(data);
    return '${m['pesan'] ?? m['message'] ?? fallback}';
  }

  Future<Map<String, dynamic>> ambilRingkasan() async {
    final res = await api.get('dashboard/ringkasan');
    final code = res['statusCode'];
    if (code != 200 && code != 201) {
      throw Exception(_pesanFrom(res['data'], 'Ambil dashboard gagal'));
    }

    final body = _bodyMap(res['data']);
    final raw = body['data'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }
}
