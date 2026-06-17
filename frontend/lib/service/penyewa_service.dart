import 'package:kos_management/service/api_service.dart';

class PenyewaService extends ApiService {
  ApiService api;
  PenyewaService(this.api);
  // =========================
  // PENYEWA
  // =========================
  Future<dynamic> getPenyewaList(int kamar_id) async {
    final res = await api.get("penyewa/ambil_penyewa/${kamar_id}");

    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'ambil data penyewa gagal');
    }
    final raw = res['data']['data'] ?? [];

    final data = (raw as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return data;
  }

  Future<dynamic> getPenyewaList_by_kos(int kos_id) async {
    final res = await api.get("penyewa/list_by_kos/${kos_id}");

    if (res['statusCode'] != 200) {
      throw Exception(
        res['data']['pesan'] ?? 'ambil data penyewa by kos gagal',
      );
    }
    final raw = res['data']['data'] ?? [];

    final data = (raw as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return data;
  }

  Future<Map<String, dynamic>> createPenyewa(
    String nama,
    String noTelpon,
    String email, {
    String? tanggalLahir,
    String? jenisKelamin,
    String? statusHubungan,
  }) async {
    final res = await api.post("penyewa/buat_penyewa", {
      "nama": nama,
      "tanggal_lahir": tanggalLahir,
      "jenis_kelamin": jenisKelamin,
      "status_hubungan": statusHubungan,
      "no_telpon": noTelpon,
      "email": email,
    });
    if (res['statusCode'] != 200) {
      throw Exception(
        res['data']['pesan'] ?? res['data']['message'] ?? "buat penyewa gagal",
      );
    }
    final raw = res['data']['data'];
    if (raw == null) {
      throw Exception(
        res['data']['pesan'] ?? 'Data penyewa tidak diterima dari server',
      );
    }
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<dynamic> editPenyewa(
    int penyewa_id,
    String nama,
    String noTelpon,
    String email, {
    String? tanggalLahir,
    String? jenisKelamin,
    String? statusHubungan,
  }) async {
    final res = await api.put("penyewa/edit_penyewa/${penyewa_id}", {
      "nama": nama,
      "tanggal_lahir": tanggalLahir,
      "jenis_kelamin": jenisKelamin,
      "status_hubungan": statusHubungan,
      "no_telpon": noTelpon,
      "email": email,
    });
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? "edit penyewa gagal");
    }
    return res['data']['pesan'];
  }

  Future<dynamic> deletePenyewa(int penyewaId) async {
    final res = await api.sdelete("penyewa/shapus_penyewa/$penyewaId");
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'hapus penyewa gagal');
    }
    return res['data']['pesan'];
  }

  Future<dynamic> getambilSemuaPenyewa() async {
    final res = await api.get("penyewa/ambil_semua_penyewa");
    if (res['statusCode'] != 200) {
      throw Exception(res['data']['pesan'] ?? 'hapus penyewa gagal');
    }

    final raw = res['data']['data'] ?? [];

    final data = (raw as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return data;
  }
}
