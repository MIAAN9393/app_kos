import 'package:flutter/material.dart';
import 'package:kos_management/providers/app_data_invalidator.dart';
import 'package:kos_management/providers/repository/kos_repository.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/penyewa_service.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/rapikan_pesan_error_or_sukses.dart';

class PenyewaProvider extends ChangeNotifier {
  static PenyewaProvider? _instance;

  final PenyewaService api_penyewa = PenyewaService(ApiService());

  // key SELALU kamar_id
  Map<int, List<Map<String, dynamic>>> data_penyewa = {};
  Map<int, Map<String, dynamic>> penyewa_by_id = {};
  Map<int, bool> perubahan_data = {};

  // index biar tidak loop cari kamar
  Map<int, int> index_penyewa_kamar = {};

  // penanda load per kos (bukan cache data)
  Map<int, bool> kos_sudah_load = {};
  bool semuaPerluMuatUlang = true;

  bool loading = false;
  String? _pesan_error;
  String? _pesan_sukses;

  PenyewaProvider() {
    _instance = this;
  }

  void tandai_semua_perlu_muat_ulang() {
    semuaPerluMuatUlang = true;
    notifyListeners();
  }

  void tandai_kos_perlu_muat_ulang(int kosId) {
    kos_sudah_load[kosId] = false;
    notifyListeners();
  }

  void tandai_kamar_perlu_muat_ulang(int kamarId) {
    perubahan_data[kamarId] = true;
    notifyListeners();
  }

  static void tandaiSemuaMuatUlang() {
    _instance?.tandai_semua_perlu_muat_ulang();
  }

  static void tandaiKosMuatUlang(int kosId) {
    _instance?.tandai_kos_perlu_muat_ulang(kosId);
  }

  static void tandaiKamarMuatUlang(int kamarId) {
    _instance?.tandai_kamar_perlu_muat_ulang(kamarId);
  }

  //FUNGSI FITUR

  // Ambil + reset pesan sukses (sekali pakai oleh UI).
  String? ambil_pesan_sukses() {
    final msg = rapikanPesan(_pesan_sukses);
    _pesan_sukses = null;
    return msg.isEmpty ? null : msg;
  }

  // Ambil + reset pesan error (sekali pakai oleh UI).
  String? ambil_pesan_error() {
    final msg = rapikanPesan(_pesan_error);
    _pesan_error = null;
    return msg.isEmpty ? null : msg;
  }

  Map<String, dynamic>? ambil_datasiap_penyewa_by_id(int penyewa_id) {
    final kamarId = index_penyewa_kamar[penyewa_id];
    if (kamarId == null) return null;

    final list = data_penyewa[kamarId];
    if (list == null) return null;

    for (var penyewa in list) {
      if (idEquals(penyewa['id'], penyewa_id)) return penyewa;
    }
    return null;
  }

  void _syncKamarPenyewa(int kamar_id, List<Map<String, dynamic>> new_data) {
    final staleIds = index_penyewa_kamar.entries
        .where((e) => e.value == kamar_id)
        .map((e) => e.key)
        .toList();
    for (final id in staleIds) {
      penyewa_by_id.remove(id);
      index_penyewa_kamar.remove(id);
    }
    data_penyewa[kamar_id] = new_data;
    for (final penyewa in new_data) {
      final id = intFromJson(penyewa['id']);
      if (id == null) continue;
      final siap = Map<String, dynamic>.from(penyewa);
      siap['kamar_id'] = kamar_id;
      penyewa_by_id[id] = siap;
      index_penyewa_kamar[id] = kamar_id;
    }
  }

  /// Paksa muat ulang daftar penyewa per kamar (mis. setelah check-in).
  Future<void> refreshKamar(int kamar_id, {int? kos_id}) async {
    perubahan_data[kamar_id] = true;
    if (kos_id != null) kos_sudah_load[kos_id] = false;
    await ambil_data_penyewa_provider(kamar_id);
    if (kos_id != null) {
      await ambil_data_penyewa_by_kos_provider(kos_id);
    }
  }

  //FUNGSI API
  Future<void> ambil_data_penyewa_provider(int kamar_id) async {
    if (perubahan_data[kamar_id] == null) perubahan_data[kamar_id] = true;

    if (data_penyewa.containsKey(kamar_id) &&
        perubahan_data[kamar_id] == false) {
      return;
    }
    try {
      _pesan_error = null;
      loading = true;
      notifyListeners();

      final raw = await api_penyewa.getPenyewaList(kamar_id);
      final new_data = List<Map<String, dynamic>>.from(raw ?? []);
      _syncKamarPenyewa(kamar_id, new_data);
      perubahan_data[kamar_id] = false;
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void paksa_muat_ulang_kos(int kos_id) {
    kos_sudah_load[kos_id] = false;
    for (final entry in data_penyewa.entries) {
      perubahan_data[entry.key] = true;
    }
  }

  Future<void> ambil_data_penyewa_by_kos_provider(int kos_id) async {
    if (kos_sudah_load[kos_id] == true) return;

    try {
      _pesan_error = null;
      loading = true;
      notifyListeners();

      final new_data = await api_penyewa.getPenyewaList_by_kos(kos_id);

      // grouping atomic
      final Map<int, List<Map<String, dynamic>>> grouped = {};

      for (var element in new_data) {
        final kamar_id = intFromJson(element['kamar_id']);
        if (kamar_id == null) continue;
        grouped.putIfAbsent(kamar_id, () => []);
        grouped[kamar_id]!.add(Map<String, dynamic>.from(element));
      }

      for (var entry in grouped.entries) {
        _syncKamarPenyewa(entry.key, entry.value);
        perubahan_data[entry.key] = false;
      }

      kos_sudah_load[kos_id] = true;
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<int?> buat_penyewa_provider({
    required int kamar_id,
    required String nama,
    required String no_telpon,
    required String email,
    String? tanggal_lahir,
    String? jenis_kelamin,
    String? status_hubungan,
  }) async {
    try {
      _pesan_sukses = null;
      _pesan_error = null;
      loading = true;
      notifyListeners();

      final created = await api_penyewa.createPenyewa(
        nama,
        no_telpon,
        email,
        tanggalLahir: tanggal_lahir,
        jenisKelamin: jenis_kelamin,
        statusHubungan: status_hubungan,
      );
      final id = created['id'];
      if (id == null) {
        throw Exception('ID penyewa tidak diterima dari server');
      }

      final penyewaId = id is int ? id : int.parse('$id');
      final siap = Map<String, dynamic>.from(created);
      siap['kamar_id'] = kamar_id;
      penyewa_by_id[penyewaId] = siap;
      index_penyewa_kamar[penyewaId] = kamar_id;
      perubahan_data[kamar_id] = true;
      AppDataInvalidator.setelahPenyewaBerubah(kamarId: kamar_id);

      _pesan_sukses = 'Penyewa berhasil dibuat';
      return penyewaId;
    } catch (e) {
      _pesan_error = e.toString();
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> hapus_penyewa_provider(int penyewa_id) async {
    try {
      _pesan_sukses = null;
      _pesan_error = null;
      loading = true;
      notifyListeners();

      final kamar_id = penyewa_by_id[penyewa_id]?["kamar_id"];

      _pesan_sukses = await api_penyewa.deletePenyewa(penyewa_id);

      // Segarkan daftar per kamar hanya bila konteks kamar diketahui.
      if (kamar_id != null) {
        final raw = await api_penyewa.getPenyewaList(kamar_id);
        final new_data = List<Map<String, dynamic>>.from(raw ?? []);
        _syncKamarPenyewa(kamar_id, new_data);
        perubahan_data[kamar_id] = false;
      }

      // Selalu segarkan master list (sumber Controll tab Penyewa).
      await ambil_semua_penyewa(force: true);
      AppDataInvalidator.setelahPenyewaBerubah(kamarId: kamar_id);
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> edit_penyewa_provider({
    required int penyewa_id,
    required String nama,
    required String no_telpon,
    required String email,
    String? tanggal_lahir,
    String? jenis_kelamin,
    String? status_hubungan,
  }) async {
    try {
      _pesan_sukses = null;
      _pesan_error = null;
      loading = true;
      notifyListeners();

      final kamar_id = penyewa_by_id[penyewa_id]?["kamar_id"];

      _pesan_sukses = await api_penyewa.editPenyewa(
        penyewa_id,
        nama,
        no_telpon,
        email,
        tanggalLahir: tanggal_lahir,
        jenisKelamin: jenis_kelamin,
        statusHubungan: status_hubungan,
      );

      // Segarkan daftar per kamar hanya bila konteks kamar diketahui.
      if (kamar_id != null) {
        final raw = await api_penyewa.getPenyewaList(kamar_id);
        final new_data = List<Map<String, dynamic>>.from(raw ?? []);
        _syncKamarPenyewa(kamar_id, new_data);
        perubahan_data[kamar_id] = false;
      }

      // Master list ikut diperbarui supaya nama/telepon terbaru konsisten.
      await ambil_semua_penyewa(force: true);
      AppDataInvalidator.setelahPenyewaBerubah(kamarId: kamar_id);
      return true;
    } catch (e) {
      _pesan_error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> tampilkan_data(String kata_kunci, int kamar_id) {
    return search_penyewa(data_penyewa, kata_kunci, kamar_id);
  }

  // Sumber data Controll tab Penyewa: semua penyewa (aktif + nonaktif).
  Map<int, Map<String, dynamic>> semua_data_penyewa = {};

  Future<void> ambil_semua_penyewa({bool force = false}) async {
    if (!force && semua_data_penyewa.isNotEmpty && !semuaPerluMuatUlang) {
      return;
    }
    try {
      _pesan_error = null;
      loading = true;
      notifyListeners();

      final new_data = await api_penyewa.getambilSemuaPenyewa();
      final list = List<Map<String, dynamic>>.from(new_data);

      // Bersihkan dulu supaya penyewa yang sudah dihapus tidak nyangkut.
      semua_data_penyewa.clear();

      for (final item in list) {
        final id = intFromJson(item["id"]);
        if (id == null) continue;
        semua_data_penyewa[id] = Map<String, dynamic>.from(item);
      }
      semuaPerluMuatUlang = false;
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
