import 'package:kos_management/service/api_service.dart';

class KontrakService {
  final ApiService api;

  KontrakService(this.api);

  Future<Map<String, dynamic>?> getKontrak(int penyewaId) async {
    final res = await api.get('kontrak/ambil_kontrak/$penyewaId');
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'ambil kontrak gagal');
    }
    final body = res['data'];
    if (body is! Map) return null;
    final nested = body['data'];
    final raw = nested ?? (body['id'] != null ? body : null);
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(raw as Map);
    if (map['id'] == null) return null;
    return map;
  }

  Future<List<Map<String, dynamic>>> getSemuaKontrak() async {
    final res = await api.get('kontrak/ambil_semua_kontrak');
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'ambil semua kontrak gagal');
    }
    final raw = res['data']['data'] ?? [];
    return (raw as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getKontrakByPenyewa(int penyewaId) async {
    final res = await api.get('kontrak/list_by_penyewa/$penyewaId');
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'ambil riwayat kontrak gagal');
    }
    final raw = res['data']['data'] ?? [];
    return (raw as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<String> createKontrak(Map<String, dynamic> body) async {
    final res = await api.post('kontrak/buat_kontrak/', body);
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'buat kontrak gagal');
    }
    final raw = res['data'];
    final payload = raw is Map ? raw['data'] : null;
    final whatsappStatus = payload is Map
        ? '${payload['whatsapp_kontrak_status'] ?? ''}'
        : '';
    if (whatsappStatus == 'sent') {
      return 'Kontrak berhasil dibuat. PDF kontrak otomatis dikirim ke WhatsApp.';
    }
    if (whatsappStatus == 'failed') {
      return 'Kontrak berhasil dibuat, tetapi WhatsApp kontrak gagal dikirim.';
    }
    if (raw is Map) return raw['pesan'] ?? 'Kontrak berhasil dibuat';
    return 'Kontrak berhasil dibuat';
  }

  Future<String> editKontrak(int kontrakId, Map<String, dynamic> body) async {
    final res = await api.put('kontrak/edit_kontrak/$kontrakId', body);
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'edit kontrak gagal');
    }
    return res['data']['pesan'] ?? 'Kontrak berhasil diupdate';
  }

  Future<String> batalkanKontrak(int kontrakId) async {
    final res = await api.sdelete('kontrak/shapus_kontrak/$kontrakId');
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'batalkan kontrak gagal');
    }
    return res['data']['pesan'] ?? 'Kontrak berhasil dibatalkan';
  }

  Future<String> selesaikanKontrak(int kontrakId) async {
    final res = await api.put('kontrak/selesaikan_kontrak/$kontrakId', {});
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'selesaikan kontrak gagal');
    }
    return res['data']['pesan'] ?? 'Kontrak berhasil diselesaikan';
  }
}
