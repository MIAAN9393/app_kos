import 'package:kos_management/service/api_service.dart';

class TagihanService {
  ApiService api;

  TagihanService(this.api);

  static String _pesanError(dynamic res, String fallback) {
    final data = res['data'];
    if (data is Map) {
      final p = '${data['pesan'] ?? data['message'] ?? ''}'.trim();
      if (p.isNotEmpty) return p;
    }
    if (data is String && data.trim().isNotEmpty) return data.trim();
    return fallback;
  }

  Future<List<Map<String, dynamic>>> getTagihanList(int kontrakId) async {
    final res = await api.get('tagihan/ambil_tagihan/$kontrakId');
    if (res['statusCode'] != 200) {
      throw Exception(_pesanError(res, 'ambil tagihan gagal'));
    }
    final raw = res['data']['data'] ?? [];
    return (raw as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getSemuaTagihan() async {
    final res = await api.get('tagihan/ambil_semua_tagihan');
    if (res['statusCode'] != 200) {
      throw Exception(_pesanError(res, 'ambil semua tagihan gagal'));
    }
    final raw = res['data']['data'] ?? [];
    return (raw as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<String> createTagihan(Map<String, dynamic> body) async {
    final res = await api.post('tagihan/buat_tagihan/', body);
    if (res['statusCode'] != 200) {
      throw Exception(_pesanError(res, 'buat tagihan gagal'));
    }
    final raw = res['data'];
    final payload = raw is Map ? raw['data'] : null;
    final whatsappStatus = payload is Map
        ? '${payload['whatsapp_invoice_status'] ?? ''}'
        : '';
    if (whatsappStatus == 'sent') {
      return 'Tagihan berhasil dibuat. Invoice otomatis dikirim ke WhatsApp.';
    }
    if (whatsappStatus == 'failed') {
      return 'Tagihan berhasil dibuat, tetapi invoice WhatsApp gagal dikirim.';
    }
    if (raw is Map) return raw['pesan'] ?? 'Tagihan berhasil dibuat';
    return 'Tagihan berhasil dibuat';
  }

  Future<String> updateTagihan(int tagihanId, Map<String, dynamic> body) async {
    final res = await api.put('tagihan/edit_tagihan/$tagihanId', body);
    if (res['statusCode'] != 200) {
      throw Exception(_pesanError(res, 'edit tagihan gagal'));
    }
    return res['data']['pesan'] ?? 'Tagihan berhasil diupdate';
  }

  Future<String> deleteTagihan(int tagihanId) async {
    final res = await api.sdelete('tagihan/shapus_tagihan/$tagihanId');
    if (res['statusCode'] != 200) {
      throw Exception(_pesanError(res, 'hapus tagihan gagal'));
    }
    return res['data']['pesan'] ?? 'Tagihan berhasil dihapus';
  }
}
