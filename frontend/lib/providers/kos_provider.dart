import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kos_management/providers/app_data_invalidator.dart';
import 'package:kos_management/providers/repository/kos_repository.dart';
// import 'package:kos_management/providers/kamar_provider.dart';
// import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/kos_service.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/rapikan_pesan_error_or_sukses.dart';

class KosProvider extends ChangeNotifier {
  static KosProvider? _instance;

  final KosService api = KosService(ApiService());
  List<Map<String, dynamic>> data_kos = [];
  Map<int, Map<String, dynamic>> dataKosMap = {};
  bool loading = false;
  String? _pesan_error;
  String? _pesan_sukses;
  bool _perlu_muat_ulang = false;

  KosProvider() {
    _instance = this;
  }

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

  void ubah_status_flag_true() {
    _perlu_muat_ulang = true;
    print("flag kos true");
    notifyListeners();
  }

  void tandai_perlu_muat_ulang() {
    _perlu_muat_ulang = true;
    notifyListeners();
  }

  static void tandaiMuatUlang() {
    _instance?.tandai_perlu_muat_ulang();
  }

  Map<String, dynamic>? ambil_datasiap_kos_by_id(int kosId) {
    for (var kos in data_kos) {
      if (idEquals(kos['id'], kosId)) return kos;
    }
    return null;
  }

  void _syncKosMaps() {
    dataKosMap.clear();
    for (var map in data_kos) {
      final id = entityId(map['id']);
      if (id == null) continue;
      map['id'] = id;
      dataKosMap[id] = map;
    }
  }

  Future<void> ambil_or_update_data() async {
    print("STEP 1");
    if (data_kos.isNotEmpty && !_perlu_muat_ulang) return;

    await ambil_data_kos_provider();
    _perlu_muat_ulang = false;
  }

  Future<void> ambil_data_kos_provider() async {
    print("STEP 2");
    try {
      _pesan_error = null;
      loading = true;
      await Future.microtask(() {}); // ⛔ delay build frame
      notifyListeners();
      data_kos = await api.getKosList();
      _syncKosMaps();
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> buat_kos_provider({
    required String nama_kos,
    required String alamat,
    String? deskripsi,
  }) async {
    try {
      _pesan_sukses = null;
      _pesan_error = null;
      loading = true;
      notifyListeners();
      _pesan_sukses = await api.createKos(
        nama_kos: nama_kos,
        alamat: alamat,
        deskripsi: deskripsi ?? "",
      );
      data_kos = await api.getKosList();
      _syncKosMaps();
      AppDataInvalidator.setelahKosBerubah();
      // _perlu_muat_ulang = true;
      return true;
    } catch (e) {
      _pesan_error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> hapus_kos_provider(int idKos) async {
    print("SATU");
    try {
      _pesan_sukses = null;
      _pesan_error = null;
      loading = true;
      notifyListeners();
      //aksi
      _pesan_sukses = await api.hapusKos(idKos);
      //ambil ulang data
      data_kos = await api.getKosList();
      _syncKosMaps();
      AppDataInvalidator.setelahKosBerubah();
      print("DUA");
      return true;
    } catch (e) {
      _pesan_error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> edit_kos_provider({
    required int kos_id,
    required String nama_kos,
    required String alamat,
    String? deskripsi,
  }) async {
    try {
      _pesan_sukses = null;
      _pesan_error = null;
      loading = true;
      notifyListeners();
      _pesan_sukses = await api.editKos(
        kos_id: kos_id,
        nama_kos: nama_kos,
        alamat: alamat,
        deskripsi: deskripsi ?? "",
      );
      data_kos = await api.getKosList();
      _syncKosMaps();
      AppDataInvalidator.setelahKosBerubah();
      // _perlu_muat_ulang = true;
      return true;
    } catch (e) {
      _pesan_error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> tampilkan_data(String kataKunci) {
    return search_data_nama(data_kos, kataKunci);
  }
}
