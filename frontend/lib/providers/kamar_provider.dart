import 'package:flutter/material.dart';
import 'package:kos_management/providers/app_data_invalidator.dart';
import 'package:kos_management/providers/repository/kos_repository.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/kamar_service.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/rapikan_pesan_error_or_sukses.dart';

class KamarProvider extends ChangeNotifier {
  static KamarProvider? _instance;

  final KamarService api_kamar = KamarService(ApiService());

  Map<int, List<Map<String, dynamic>>> data_kamar = {};
  Map<int, Map<String, dynamic>> kamar_by_id = {};
  // bool _perubahan_data = false;
  Map<int, bool> perubahan_data = {};
  bool loading = false;
  String? _pesan_error;
  String? _pesan_sukses;

  KamarProvider() {
    _instance = this;
  }

  void tandai_semua_perlu_muat_ulang() {
    if (data_kamar.isEmpty) return;
    for (final kosId in data_kamar.keys) {
      perubahan_data[kosId] = true;
    }
    notifyListeners();
  }

  void tandai_kos_perlu_muat_ulang(int kosId) {
    perubahan_data[kosId] = true;
    notifyListeners();
  }

  static void tandaiSemuaMuatUlang() {
    _instance?.tandai_semua_perlu_muat_ulang();
  }

  static void tandaiKosMuatUlang(int kosId) {
    _instance?.tandai_kos_perlu_muat_ulang(kosId);
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

  int? cari_kos_id(int kamar_id) {
    for (var element in data_kamar.values) {
      for (var kamar in element) {
        if (idEquals(kamar['id'], kamar_id)) {
          return entityId(kamar['kos_id']);
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? ambil_datasiap_kamar_by_id(int kamar_id) {
    for (var list in data_kamar.values) {
      for (var kamar in list) {
        if (idEquals(kamar['id'], kamar_id)) return kamar;
      }
    }
    return null;
  }

  void _indexKamarList(int kos_id, List<Map<String, dynamic>> list) {
    final staleIds = kamar_by_id.entries
        .where((entry) => entityId(entry.value['kos_id']) == kos_id)
        .map((entry) => entry.key)
        .toList();
    for (final id in staleIds) {
      kamar_by_id.remove(id);
    }

    for (final kamar in list) {
      final id = entityId(kamar['id']);
      if (id == null) continue;
      kamar['id'] = id;
      final kosId = entityId(kamar['kos_id']);
      if (kosId != null) kamar['kos_id'] = kosId;
      kamar_by_id[id] = kamar;
    }
  }

  //FUNGSI API
  Future<void> ambil_data_kamar_provider(int kos_id) async {
    if (perubahan_data[kos_id] == null) perubahan_data[kos_id] = true;

    if (data_kamar.containsKey(kos_id) && perubahan_data[kos_id] == false) {
      return;
    }
    try {
      _pesan_error = null;
      loading = true;
      notifyListeners();
      //aksi
      data_kamar[kos_id] ??= [];
      final new_data = await api_kamar.getKamarList(kos_id);
      data_kamar[kos_id] = new_data ?? [];
      _indexKamarList(kos_id, data_kamar[kos_id]!);
      perubahan_data[kos_id] = false;
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> buat_kamar_provider({
    required int kos_id,
    required String nama_kamar,
    required int harga_kamar,
    required int kapasitas_kamar,
    List<String>? fasilitas,
  }) async {
    try {
      _pesan_sukses = null;
      _pesan_error = null;
      loading = true;
      notifyListeners();
      //aksi
      _pesan_sukses = await api_kamar.createKamar(
        kos_id,
        nama_kamar,
        harga_kamar,
        kapasitas_kamar,
        fasilitas: fasilitas,
      );
      final new_data = await api_kamar.getKamarList(kos_id);
      data_kamar[kos_id] = new_data ?? [];
      _indexKamarList(kos_id, data_kamar[kos_id]!);
      perubahan_data[kos_id] = false;
      AppDataInvalidator.setelahKamarBerubah(kosId: kos_id);
      return true;
    } catch (e) {
      _pesan_error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> hapus_kamar_provider(int kamar_id) async {
    try {
      _pesan_sukses = null;
      _pesan_error = null;
      loading = true;
      notifyListeners();
      //ambil kos id
      var kos_id = cari_kos_id(kamar_id);

      if (kos_id == null) {
        throw Exception("Data kamar tidak ditemukan");
      }
      //aksi
      _pesan_sukses = await api_kamar.deleteKamar(kamar_id);
      final new_data = await api_kamar.getKamarList(kos_id);
      data_kamar[kos_id] = new_data ?? [];
      _indexKamarList(kos_id, data_kamar[kos_id]!);
      perubahan_data[kos_id] = false;
      kamar_by_id.remove(kamar_id);
      AppDataInvalidator.setelahKamarBerubah(kosId: kos_id);
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> edit_kamar_provider({
    required int kamar_id,
    required String nama_kamar,
    required int harga_kamar,
    required int kapasitas_kamar,
    List<String>? fasilitas,
  }) async {
    try {
      _pesan_sukses = null;
      _pesan_error = null;
      loading = true;
      notifyListeners();
      //ambil kos id
      var kos_id = cari_kos_id(kamar_id);
      if (kos_id == null) {
        throw Exception("Data kamar tidak ditemukan");
      }
      //aksi
      _pesan_sukses = await api_kamar.updateKamar(
        kamar_id,
        nama_kamar,
        harga_kamar,
        kapasitas_kamar,
        fasilitas: fasilitas,
      );
      final new_data = await api_kamar.getKamarList(kos_id);
      data_kamar[kos_id] = new_data ?? [];
      _indexKamarList(kos_id, data_kamar[kos_id]!);
      perubahan_data[kos_id] = false;
      AppDataInvalidator.setelahKamarBerubah(kosId: kos_id);
      return true;
    } catch (e) {
      _pesan_error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> tampilkan_data(String kata_kunci, int kos_id) {
    return search_kamar(data_kamar, kata_kunci, kos_id);
  }
}
