import 'package:kos_management/service/api_service.dart';

class PembayaranService {
  ApiService api;

  PembayaranService(this.api);

  Future<List<Map<String, dynamic>>> getPembayaranList(int tagihanId) async {
    final res = await api.get('pembayaran/ambil_pembayaran/$tagihanId');
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'ambil pembayaran gagal');
    }
    final raw = res['data']['data'];
    if (raw is Map && raw['list'] is List) {
      return (raw['list'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getSemuaPembayaran() async {
    final res = await api.get('pembayaran/ambil_semua_pembayaran');
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'ambil semua pembayaran gagal');
    }
    final raw = res['data']['data'] ?? [];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<String> createPembayaran({
    required int tagihanId,
    required int jumlahBayar,
  }) async {
    final res = await api.post('pembayaran/buat_pembayaran/', {
      'tagihan_id': tagihanId,
      'jumlah_bayar': jumlahBayar,
    });
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'buat pembayaran gagal');
    }
    return res['data']['pesan'] ?? 'Pembayaran berhasil';
  }

  Future<String> createRefund({
    required int pembayaranId,
    required int jumlahRefund,
  }) async {
    final res = await api.put('pembayaran/buat_refund_pembayaran/$pembayaranId', {
      'pembayaran_id': pembayaranId,
      'jumlah_refund': jumlahRefund,
    });
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'refund gagal');
    }
    return res['data']['pesan'] ?? 'Refund berhasil';
  }
}
