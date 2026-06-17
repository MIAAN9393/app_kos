import 'package:kos_management/service/api_service.dart';

class PengaturanOtomatisService {
  final ApiService api;

  PengaturanOtomatisService(this.api);

  static Map<String, dynamic>? _payload(dynamic res) {
    final raw = res['data'];
    if (raw is! Map) return null;
    final data = raw['data'];
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  static String _pesan(dynamic res, String fallback) {
    final raw = res['data'];
    if (raw is Map) {
      final pesan = '${raw['pesan'] ?? raw['message'] ?? ''}'.trim();
      if (pesan.isNotEmpty) return pesan;
    }
    return fallback;
  }

  Future<Map<String, dynamic>?> getTagihan(int kontrakId) async {
    final res = await api.get('pengaturan-otomatis/tagihan/$kontrakId');
    return _payload(res);
  }

  Future<Map<String, dynamic>> simpanTagihan(
    int kontrakId,
    Map<String, dynamic> body,
  ) async {
    final res = await api.put('pengaturan-otomatis/tagihan/$kontrakId', body);
    final data = _payload(res);
    if (data == null) {
      throw Exception(_pesan(res, 'Gagal menyimpan pengaturan'));
    }
    return data;
  }

  Future<Map<String, dynamic>> ubahStatusTagihan(
    int kontrakId,
    String status,
  ) async {
    final res = await api.put('pengaturan-otomatis/tagihan/$kontrakId/status', {
      'status': status,
    });
    final data = _payload(res);
    if (data == null) {
      throw Exception(_pesan(res, 'Gagal mengubah status'));
    }
    return data;
  }

  Future<Map<String, dynamic>?> getPerpanjangan(int kontrakId) async {
    final res = await api.get(
      'pengaturan-otomatis/perpanjangan-kontrak/$kontrakId',
    );
    return _payload(res);
  }

  Future<Map<String, dynamic>> simpanPerpanjangan(
    int kontrakId,
    Map<String, dynamic> body,
  ) async {
    final res = await api.put(
      'pengaturan-otomatis/perpanjangan-kontrak/$kontrakId',
      body,
    );
    final data = _payload(res);
    if (data == null) {
      throw Exception(_pesan(res, 'Gagal menyimpan pengaturan'));
    }
    return data;
  }

  Future<Map<String, dynamic>> ubahStatusPerpanjangan(
    int kontrakId,
    String status,
  ) async {
    final res = await api.put(
      'pengaturan-otomatis/perpanjangan-kontrak/$kontrakId/status',
      {'status': status},
    );
    final data = _payload(res);
    if (data == null) {
      throw Exception(_pesan(res, 'Gagal mengubah status'));
    }
    return data;
  }
}
