import 'package:flutter/material.dart';
import 'package:kos_management/providers/app_data_invalidator.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/kontrak_service.dart';
import 'package:kos_management/service/tagihan_service.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/tagihan_item_utils.dart';
import 'package:kos_management/utils/entity_action_rules.dart';
import 'package:kos_management/utils/tagihan_rules.dart';
import 'package:kos_management/providers/laporan_keuangan_provider.dart';
import 'package:kos_management/providers/laporan_kos_provider.dart';
import 'package:kos_management/utils/rapikan_pesan_error_or_sukses.dart';

class TagihanProvider extends ChangeNotifier {
  static TagihanProvider? _instance;

  final TagihanService api_tagihan = TagihanService(ApiService());
  final KontrakService api_kontrak = KontrakService(ApiService());

  Map<int, List<Map<String, dynamic>>> data_tagihan = {};
  Map<int, List<Map<String, dynamic>>> data_tagihan_by_kontrak = {};
  Map<int, Map<String, dynamic>> tagihan_by_id = {};

  // Sumber data Controll tab Tagihan: semua tagihan (key = id tagihan).
  Map<int, Map<String, dynamic>> semua_data_tagihan = {};
  // bool _perubahan_data = false;
  Map<int, bool> perubahan_data = {};
  bool loading = false;
  bool semuaPerluMuatUlang = true;
  String? _pesan_error;
  String? _pesan_sukses;

  TagihanProvider() {
    _instance = this;
  }

  void tandai_semua_perlu_muat_ulang() {
    semuaPerluMuatUlang = true;
    notifyListeners();
  }

  static void tandaiSemuaMuatUlang() {
    _instance?.tandai_semua_perlu_muat_ulang();
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

  //status flag
  void ubah_status_flag_true(int penyewaId) {
    perubahan_data[penyewaId] = true;
    notifyListeners();
  }

  Future<void> _tandai_laporan_kos_perlu_muat_ulang(int penyewaId) async {
    try {
      final kontrak = await api_kontrak.getKontrak(penyewaId);
      if (kontrak == null) return;
      final kamar = kontrak['kamar'];
      final kosId = kamar is Map
          ? intFromJson(kamar['kos_id'])
          : intFromJson(kontrak['kos_id']);
      LaporanKeuanganProvider.tandaiMuatUlang();
      if (kosId != null) {
        LaporanKosProvider.tandaiMuatUlang(kosId);
      }
    } catch (_) {}
  }

  int? cari_penyewa_id_bytagihan(int tagihanId) {
    for (var entry in data_tagihan.entries) {
      for (var tagihan in entry.value) {
        if (idEquals(tagihan['id'], tagihanId)) return entry.key;
      }
    }
    final indexed = tagihan_by_id[tagihanId];
    final penyewaId = indexed == null ? null : entityId(indexed['penyewa_id']);
    if (penyewaId != null) return penyewaId;
    return null;
  }

  Map<String, dynamic>? ambil_datasiap_tagihan_by_id(int tagihanId) {
    final id = entityId(tagihanId);
    if (id != null && tagihan_by_id.containsKey(id)) {
      return tagihan_by_id[id];
    }
    for (var list in data_tagihan.values) {
      for (var tagihan in list) {
        if (idEquals(tagihan['id'], tagihanId)) return tagihan;
      }
    }
    return null;
  }

  int? _kontrakIdDariTagihan(Map<String, dynamic>? tagihan) {
    if (tagihan == null) return null;
    return entityId(tagihan['kontrak_id']);
  }

  Future<Map<String, dynamic>?> _ambilKontrakTagihan({
    required int penyewaId,
    int? kontrakId,
  }) async {
    if (kontrakId != null) {
      final riwayat = await api_kontrak.getKontrakByPenyewa(penyewaId);
      for (final kontrak in riwayat) {
        if (idEquals(kontrak['id'], kontrakId)) return kontrak;
      }
    }
    try {
      return await api_kontrak.getKontrak(penyewaId);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _ambil_tagihan_untuk_aturan_sewa({
    required int penyewaId,
    required int kontrakId,
  }) async {
    await ambil_tagihan_by_kontrak_provider(
      kontrakId,
      penyewa_id: penyewaId,
      force: true,
    );
    return data_tagihan_by_kontrak[kontrakId] ?? [];
  }

  void _indexTagihanList(int penyewaId, List<Map<String, dynamic>> list) {
    for (var tagihan in list) {
      tagihan['penyewa_id'] = penyewaId;
      final id = entityId(tagihan['id']);
      if (id == null) continue;
      tagihan['id'] = id;
      tagihan_by_id[id] = tagihan;
    }
  }

  void _indexTagihanKontrakList(
    int kontrakId,
    int penyewaId,
    List<Map<String, dynamic>> list,
  ) {
    data_tagihan_by_kontrak[kontrakId] = list;
    for (var tagihan in list) {
      tagihan['kontrak_id'] = kontrakId;
      tagihan['penyewa_id'] = penyewaId;
      final id = entityId(tagihan['id']);
      if (id == null) continue;
      tagihan['id'] = id;
      tagihan_by_id[id] = tagihan;
    }
  }

  //FUNGSI API
  Future<void> ambil_data_tagihan_provider(int penyewaId) async {
    if (perubahan_data[penyewaId] == null) perubahan_data[penyewaId] = true;

    if (data_tagihan.containsKey(penyewaId) &&
        perubahan_data[penyewaId] == false) {
      return;
    }
    try {
      _pesan_error = null;
      loading = true;
      notifyListeners();
      //aksi
      data_tagihan[penyewaId] ??= [];
      final kontrak = await api_kontrak.getKontrak(penyewaId);
      if (kontrak == null || kontrak['id'] == null) {
        data_tagihan[penyewaId] = [];
        perubahan_data[penyewaId] = false;
        return;
      }
      final kontrakId = intFromJson(kontrak['id']);
      if (kontrakId == null) {
        data_tagihan[penyewaId] = [];
        perubahan_data[penyewaId] = false;
        return;
      }
      final newData = await api_tagihan.getTagihanList(kontrakId);
      data_tagihan[penyewaId] = newData;
      _indexTagihanList(penyewaId, data_tagihan[penyewaId]!);

      perubahan_data[penyewaId] = false;
      print("flag tagihan false");
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> ambil_tagihan_by_kontrak_provider(
    int kontrakId, {
    required int penyewa_id,
    bool force = false,
  }) async {
    if (!force && data_tagihan_by_kontrak.containsKey(kontrakId)) {
      return;
    }
    try {
      _pesan_error = null;
      loading = true;
      notifyListeners();

      final newData = await api_tagihan.getTagihanList(kontrakId);
      _indexTagihanKontrakList(kontrakId, penyewa_id, newData);
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> ambil_semua_tagihan({bool force = false}) async {
    if (!force && semua_data_tagihan.isNotEmpty && !semuaPerluMuatUlang) {
      return;
    }
    try {
      _pesan_error = null;
      loading = true;
      notifyListeners();

      final list = await api_tagihan.getSemuaTagihan();

      semua_data_tagihan.clear();
      for (final item in list) {
        final id = entityId(item['id']);
        if (id == null) continue;
        final data = Map<String, dynamic>.from(item);
        data['id'] = id;
        semua_data_tagihan[id] = data;
        // Diindeks juga supaya tab Pembayaran bisa resolve konteks tagihan.
        tagihan_by_id[id] = data;
      }
      semuaPerluMuatUlang = false;
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> buat_tagihan_provider({
    required int penyewa_id,
    required DateTime periode_awal,
    required DateTime periode_akhir,
    required DateTime jatuh_tempo,
    required List<Map<String, dynamic>> list_item,
    required String catatan,
  }) async {
    try {
      _pesan_sukses = null;
      _pesan_error = null;
      loading = true;
      notifyListeners();
      final err = TagihanItemUtils.validasiItems(list_item);
      if (err != null) throw Exception(err);
      final errPeriode = TagihanItemUtils.validasiPeriode(
        periodeAwal: periode_awal,
        periodeAkhir: periode_akhir,
        jatuhTempo: jatuh_tempo,
      );
      if (errPeriode != null) throw Exception(errPeriode);
      final kontrak = await api_kontrak.getKontrak(penyewa_id);
      final pesanKontrak = TagihanRules.pesanKontrakUntukBuatTagihan(kontrak);
      if (pesanKontrak != null) throw Exception(pesanKontrak);
      final kontrakId = intFromJson(kontrak!['id']);
      if (kontrakId == null) throw Exception('ID kontrak tidak valid');
      final pesanPeriodeKontrak = TagihanRules.pesanPeriodeDalamKontrak(
        kontrak: kontrak,
        periodeAwal: periode_awal,
        periodeAkhir: periode_akhir,
      );
      if (pesanPeriodeKontrak != null) throw Exception(pesanPeriodeKontrak);
      final tagihanKontrak = await _ambil_tagihan_untuk_aturan_sewa(
        penyewaId: penyewa_id,
        kontrakId: kontrakId,
      );

      final duplikatSewa = TagihanRules.pesanDuplikatSewaPeriode(
        tagihanList: tagihanKontrak,
        periodeAwal: periode_awal,
        periodeAkhir: periode_akhir,
        listItemBaru: list_item,
      );
      if (duplikatSewa != null) throw Exception(duplikatSewa);
      _pesan_sukses = await api_tagihan.createTagihan({
        'kontrak_id': kontrakId,
        'periode_awal': TagihanItemUtils.formatTanggalApi(periode_awal),
        'periode_akhir': TagihanItemUtils.formatTanggalApi(periode_akhir),
        'jatuh_tempo': TagihanItemUtils.formatTanggalApi(jatuh_tempo),
        'catatan': catatan,
        'list_item': TagihanItemUtils.toCreatePayload(list_item),
      });
      ubah_status_flag_true(penyewa_id);
      await ambil_data_tagihan_provider(penyewa_id);
      if (_pesan_error != null) return false;
      AppDataInvalidator.setelahTagihanBerubah();
      await _tandai_laporan_kos_perlu_muat_ulang(penyewa_id);
      return true;
    } catch (e) {
      _pesan_error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> hapus_tagihan_provider(int tagihanId) async {
    try {
      _pesan_sukses = null;
      _pesan_error = null;
      loading = true;
      notifyListeners();
      //ambil kos id
      var penyewaId = cari_penyewa_id_bytagihan(tagihanId);

      if (penyewaId == null) {
        throw Exception("Data tagihan tidak ditemukan");
      }
      //aksi
      _pesan_sukses = await api_tagihan.deleteTagihan(tagihanId);
      ubah_status_flag_true(penyewaId);
      await ambil_data_tagihan_provider(penyewaId);
      AppDataInvalidator.setelahTagihanBerubah();
      await _tandai_laporan_kos_perlu_muat_ulang(penyewaId);
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> edit_tagihan_provider({
    required int tagihan_id,
    required int penyewa_id,
    required DateTime periode_awal,
    required DateTime periode_akhir,
    required DateTime jatuh_tempo,
    required List<Map<String, dynamic>> list_item,
    required String catatan,
  }) async {
    try {
      _pesan_sukses = null;
      _pesan_error = null;
      loading = true;
      notifyListeners();
      final err = TagihanItemUtils.validasiItems(list_item);
      if (err != null) throw Exception(err);
      final errPeriode = TagihanItemUtils.validasiPeriode(
        periodeAwal: periode_awal,
        periodeAkhir: periode_akhir,
        jatuhTempo: jatuh_tempo,
      );
      if (errPeriode != null) throw Exception(errPeriode);
      final existing = ambil_datasiap_tagihan_by_id(tagihan_id);
      if (existing != null && TagihanRules.isCancelled(existing)) {
        throw Exception('Tagihan sudah dibatalkan');
      }
      if (existing != null) {
        final pesanBayar = EntityActionRules.pesanUbahTagihan(existing);
        if (pesanBayar != null) throw Exception(pesanBayar);
      }
      final kontrakIdDariTagihan = _kontrakIdDariTagihan(existing);
      final kontrak = kontrakIdDariTagihan == null
          ? await api_kontrak.getKontrak(penyewa_id)
          : null;
      final kontrakId = kontrakIdDariTagihan ?? intFromJson(kontrak?['id']);
      if (kontrakId == null) {
        throw Exception('Kontrak tidak ditemukan');
      }
      final kontrakTagihan = await _ambilKontrakTagihan(
        penyewaId: penyewa_id,
        kontrakId: kontrakId,
      );
      final pesanPeriodeKontrak = TagihanRules.pesanPeriodeDalamKontrak(
        kontrak: kontrakTagihan,
        periodeAwal: periode_awal,
        periodeAkhir: periode_akhir,
      );
      if (pesanPeriodeKontrak != null) throw Exception(pesanPeriodeKontrak);
      final tagihanKontrak = await _ambil_tagihan_untuk_aturan_sewa(
        penyewaId: penyewa_id,
        kontrakId: kontrakId,
      );
      final duplikatSewa = TagihanRules.pesanDuplikatSewaPeriode(
        tagihanList: tagihanKontrak,
        periodeAwal: periode_awal,
        periodeAkhir: periode_akhir,
        listItemBaru: list_item,
        excludeTagihanId: tagihan_id,
      );
      if (duplikatSewa != null) throw Exception(duplikatSewa);
      _pesan_sukses = await api_tagihan.updateTagihan(tagihan_id, {
        'kontrak_id': kontrakId,
        'periode_awal': TagihanItemUtils.formatTanggalApi(periode_awal),
        'periode_akhir': TagihanItemUtils.formatTanggalApi(periode_akhir),
        'jatuh_tempo': TagihanItemUtils.formatTanggalApi(jatuh_tempo),
        'catatan': catatan,
        'list_item': TagihanItemUtils.toCreatePayload(list_item),
      });
      ubah_status_flag_true(penyewa_id);
      await ambil_data_tagihan_provider(penyewa_id);
      if (_pesan_error != null) return false;
      AppDataInvalidator.setelahTagihanBerubah();
      await _tandai_laporan_kos_perlu_muat_ulang(penyewa_id);
      return true;
    } catch (e) {
      _pesan_error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
