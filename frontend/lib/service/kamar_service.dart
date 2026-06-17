import 'package:kos_management/service/api_service.dart';

class KamarService {
  ApiService api;

  KamarService(this.api);
  // =========================
  // KAMAR
  // =========================

  Future<dynamic> getKamarList(int kos_id) async {
    final res = await api.get("kamar/ambil_kamar/$kos_id");
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? "ambil kamar gagal");
    }
    final raw = res['data']['data'] ?? [];

    final data = (raw as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return data;
  }

  Future<dynamic> createKamar(
    int kos_id,
    String nama_kamar,
    int harga_kamar,
    int kapasitas_kamar, {
    List<String>? fasilitas,
  }) async {
    final body = <String, dynamic>{
      'nomor': nama_kamar,
      'harga': harga_kamar,
      'kapasitas': kapasitas_kamar,
    };
    if (fasilitas != null && fasilitas.isNotEmpty) {
      body['fasilitas'] = fasilitas;
    }
    final res = await api.post('kamar/buat_kamar/$kos_id', body);
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? "buat kamar gagal");
    }
    return res['data']['pesan'];
  }

  Future<dynamic> updateKamar(
    int kamarId,
    String nama_kamar,
    int harga_kamar,
    int kapasitas_kamar, {
    List<String>? fasilitas,
  }) async {
    final body = <String, dynamic>{
      'nomor': nama_kamar,
      'harga': harga_kamar,
      'kapasitas': kapasitas_kamar,
      'fasilitas': fasilitas ?? [],
    };
    final res = await api.put('kamar/edit_kamar/$kamarId', body);
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? "edit kamar gagal");
    }
    return res['data']['pesan'];
  }

  Future<dynamic> deleteKamar(int kamarId) async {
    final res = await api.sdelete("kamar/shapus_kamar/$kamarId");
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? "delete kamar gagal");
    }
    return res['data']['pesan'];
  }
}
