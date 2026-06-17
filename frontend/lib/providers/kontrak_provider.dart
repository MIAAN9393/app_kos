import 'package:flutter/material.dart';
import 'package:kos_management/providers/app_data_invalidator.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/kontrak_service.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/kontrak_status.dart';
import 'package:kos_management/utils/rapikan_pesan_error_or_sukses.dart';

class KontrakProvider extends ChangeNotifier {
  static KontrakProvider? _instance;

  final KontrakService api = KontrakService(ApiService());

  Map<int, Map<String, dynamic>> kontrakByPenyewa = {};
  Map<int, List<Map<String, dynamic>>> kontrakListByPenyewa = {};

  // Sumber data Controll tab Kontrak: semua kontrak (key = id kontrak).
  Map<int, Map<String, dynamic>> semua_data_kontrak = {};

  bool loading = false;
  bool semuaPerluMuatUlang = true;
  String? _pesan_error;
  String? _pesan_sukses;

  KontrakProvider() {
    _instance = this;
  }

  void tandai_semua_perlu_muat_ulang() {
    semuaPerluMuatUlang = true;
    notifyListeners();
  }

  static void tandaiSemuaMuatUlang() {
    _instance?.tandai_semua_perlu_muat_ulang();
  }

  String? ambil_pesan_sukses() {
    final msg = rapikanPesan(_pesan_sukses);
    _pesan_sukses = null;
    return msg.isEmpty ? null : msg;
  }

  String? ambil_pesan_error() {
    final msg = rapikanPesan(_pesan_error);
    _pesan_error = null;
    return msg.isEmpty ? null : msg;
  }

  Future<Map<String, dynamic>?> ambil_kontrak_provider(
    int penyewaId, {
    bool force = false,
  }) async {
    if (!force && kontrakByPenyewa.containsKey(penyewaId)) {
      return kontrakByPenyewa[penyewaId];
    }
    try {
      loading = true;
      _pesan_error = null;
      notifyListeners();

      final data = await api.getKontrak(penyewaId);
      if (data != null) {
        final id = data['id'];
        if (id != null) data['id'] = intFromJson(id) ?? id;
        final kode = data['kode_kontrak'];
        if (kode != null && '$kode'.trim().isNotEmpty) {
          data['kode_kontrak'] = '$kode'.trim();
        }
        data['status'] = KontrakStatus.normalize(data['status']);
        kontrakByPenyewa[penyewaId] = data;
      } else {
        kontrakByPenyewa.remove(penyewaId);
      }
      return data;
    } catch (e) {
      _pesan_error = e.toString();
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> ambil_list_kontrak_penyewa(
    int penyewaId, {
    bool force = false,
  }) async {
    if (!force && kontrakListByPenyewa.containsKey(penyewaId)) {
      return kontrakListByPenyewa[penyewaId]!;
    }
    try {
      loading = true;
      _pesan_error = null;
      notifyListeners();

      final list = await api.getKontrakByPenyewa(penyewaId);
      final normalized = list.map((item) {
        final data = Map<String, dynamic>.from(item);
        final id = data['id'];
        if (id != null) data['id'] = intFromJson(id) ?? id;
        data['status'] = KontrakStatus.normalize(data['status']);
        return data;
      }).toList();

      kontrakListByPenyewa[penyewaId] = normalized;
      if (normalized.isNotEmpty) {
        kontrakByPenyewa[penyewaId] = normalized.first;
      } else {
        kontrakByPenyewa.remove(penyewaId);
      }
      return normalized;
    } catch (e) {
      _pesan_error = e.toString();
      return kontrakListByPenyewa[penyewaId] ?? [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  static String _normTanggal(String s) {
    final parts = s.trim().split('-');
    if (parts.length != 3) return s.trim();
    return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
  }

  Map<String, dynamic>? _cariKontrakById(int kontrakId) {
    final dariSemua = semua_data_kontrak[kontrakId];
    if (dariSemua != null) return dariSemua;

    for (final kontrak in kontrakByPenyewa.values) {
      if (intFromJson(kontrak['id']) == kontrakId) return kontrak;
    }

    for (final list in kontrakListByPenyewa.values) {
      for (final kontrak in list) {
        if (intFromJson(kontrak['id']) == kontrakId) return kontrak;
      }
    }
    return null;
  }

  int? _kamarIdDariKontrak(Map<String, dynamic>? kontrak) {
    if (kontrak == null) return null;
    final kamarId = intFromJson(kontrak['kamar_id']);
    if (kamarId != null) return kamarId;

    final kamar = kontrak['kamar'];
    if (kamar is Map) return intFromJson(kamar['id']);
    return null;
  }

  int? _kosIdDariKontrak(Map<String, dynamic>? kontrak) {
    if (kontrak == null) return null;
    final kosId = intFromJson(kontrak['kos_id']);
    if (kosId != null) return kosId;

    final kamar = kontrak['kamar'];
    if (kamar is Map) return intFromJson(kamar['kos_id']);
    return null;
  }

  void _invalidasiRelasiKontrak({
    int? kosId,
    int? kamarId,
    int? kosIdLama,
    int? kamarIdLama,
  }) {
    AppDataInvalidator.setelahKontrakBerubah(kosId: kosId, kamarId: kamarId);

    final perluInvalidasiKamarLama =
        kamarIdLama != null && kamarIdLama != kamarId;
    final perluInvalidasiKosLama = kosIdLama != null && kosIdLama != kosId;
    if (perluInvalidasiKamarLama || perluInvalidasiKosLama) {
      AppDataInvalidator.setelahKontrakBerubah(
        kosId: kosIdLama,
        kamarId: kamarIdLama,
      );
    }
  }

  Future<bool> buat_kontrak_provider({
    required int penyewaId,
    required int kamarId,
    required String tanggalMulai,
    required String tanggalSelesai,
    required int hargaSewa,
    required String siklus,
  }) async {
    try {
      loading = true;
      _pesan_error = null;
      notifyListeners();

      _pesan_sukses = await api.createKontrak({
        'penyewa_id': penyewaId,
        'kamar_id': kamarId,
        'tanggal_mulai': _normTanggal(tanggalMulai),
        'tanggal_selesai': _normTanggal(tanggalSelesai),
        'harga_sewa': hargaSewa,
        'siklus': siklus,
      });

      await ambil_kontrak_provider(penyewaId, force: true);
      await ambil_list_kontrak_penyewa(penyewaId, force: true);
      final kontrakBaru = kontrakByPenyewa[penyewaId];
      _invalidasiRelasiKontrak(
        kosId: _kosIdDariKontrak(kontrakBaru),
        kamarId: kamarId,
      );
      return true;
    } catch (e) {
      _pesan_error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> edit_kontrak_provider({
    required int kontrakId,
    required int penyewaId,
    required int kamarId,
    required String tanggalMulai,
    required String tanggalSelesai,
    required int hargaSewa,
    required String siklus,
  }) async {
    try {
      loading = true;
      _pesan_error = null;
      notifyListeners();
      final kontrakLama = _cariKontrakById(kontrakId);
      final kosIdLama = _kosIdDariKontrak(kontrakLama);
      final kamarIdLama = _kamarIdDariKontrak(kontrakLama);

      _pesan_sukses = await api.editKontrak(kontrakId, {
        'penyewa_id': penyewaId,
        'kamar_id': kamarId,
        'tanggal_mulai': _normTanggal(tanggalMulai),
        'tanggal_selesai': _normTanggal(tanggalSelesai),
        'harga_sewa': hargaSewa,
        'siklus': siklus,
      });

      await ambil_kontrak_provider(penyewaId, force: true);
      await ambil_list_kontrak_penyewa(penyewaId, force: true);
      final kontrakBaru = kontrakByPenyewa[penyewaId];
      _invalidasiRelasiKontrak(
        kosId: _kosIdDariKontrak(kontrakBaru) ?? kosIdLama,
        kamarId: kamarId,
        kosIdLama: kosIdLama,
        kamarIdLama: kamarIdLama,
      );
      return true;
    } catch (e) {
      _pesan_error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> batalkan_kontrak_provider({
    required int kontrakId,
    required int penyewaId,
  }) async {
    try {
      loading = true;
      _pesan_error = null;
      notifyListeners();
      final kontrakLama = _cariKontrakById(kontrakId);
      final kosIdLama = _kosIdDariKontrak(kontrakLama);
      final kamarIdLama = _kamarIdDariKontrak(kontrakLama);

      _pesan_sukses = await api.batalkanKontrak(kontrakId);
      await ambil_kontrak_provider(penyewaId, force: true);
      await ambil_list_kontrak_penyewa(penyewaId, force: true);
      _invalidasiRelasiKontrak(kosId: kosIdLama, kamarId: kamarIdLama);
      return true;
    } catch (e) {
      _pesan_error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> selesaikan_kontrak_provider({
    required int kontrakId,
    required int penyewaId,
  }) async {
    try {
      loading = true;
      _pesan_error = null;
      notifyListeners();
      final kontrakLama = _cariKontrakById(kontrakId);
      final kosIdLama = _kosIdDariKontrak(kontrakLama);
      final kamarIdLama = _kamarIdDariKontrak(kontrakLama);

      _pesan_sukses = await api.selesaikanKontrak(kontrakId);
      await ambil_kontrak_provider(penyewaId, force: true);
      await ambil_list_kontrak_penyewa(penyewaId, force: true);
      _invalidasiRelasiKontrak(kosId: kosIdLama, kamarId: kamarIdLama);
      return true;
    } catch (e) {
      _pesan_error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void invalidateKontrak(int penyewaId) {
    kontrakByPenyewa.remove(penyewaId);
    kontrakListByPenyewa.remove(penyewaId);
    notifyListeners();
  }

  Future<void> ambil_semua_kontrak({bool force = false}) async {
    if (!force && semua_data_kontrak.isNotEmpty && !semuaPerluMuatUlang) {
      return;
    }
    try {
      loading = true;
      _pesan_error = null;
      notifyListeners();

      final list = await api.getSemuaKontrak();

      semua_data_kontrak.clear();
      for (final item in list) {
        final id = intFromJson(item['id']);
        if (id == null) continue;
        final data = Map<String, dynamic>.from(item);
        data['id'] = id;
        data['status'] = KontrakStatus.normalize(data['status']);
        semua_data_kontrak[id] = data;
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
