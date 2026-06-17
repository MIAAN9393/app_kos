import 'package:flutter/material.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/pengaturan_otomatis_service.dart';
import 'package:kos_management/utils/rapikan_pesan_error_or_sukses.dart';

class PengaturanOtomatisProvider extends ChangeNotifier {
  final PengaturanOtomatisService api = PengaturanOtomatisService(ApiService());

  final Map<int, Map<String, dynamic>?> tagihanByKontrak = {};
  final Map<int, Map<String, dynamic>?> perpanjanganByKontrak = {};
  final Map<int, bool> loadingTagihan = {};
  final Map<int, bool> loadingPerpanjangan = {};

  String? _pesanError;
  String? _pesanSukses;

  String? ambil_pesan_sukses() {
    final msg = rapikanPesan(_pesanSukses);
    _pesanSukses = null;
    return msg.isEmpty ? null : msg;
  }

  String? ambil_pesan_error() {
    final msg = rapikanPesan(_pesanError);
    _pesanError = null;
    return msg.isEmpty ? null : msg;
  }

  Future<void> ambilTagihan(int kontrakId, {bool force = false}) async {
    if (!force && tagihanByKontrak.containsKey(kontrakId)) return;
    try {
      _pesanError = null;
      loadingTagihan[kontrakId] = true;
      notifyListeners();
      tagihanByKontrak[kontrakId] = await api.getTagihan(kontrakId);
    } catch (e) {
      _pesanError = e.toString();
    } finally {
      loadingTagihan[kontrakId] = false;
      notifyListeners();
    }
  }

  Future<bool> simpanTagihan({
    required int kontrakId,
    required int hariSebelumPeriodeMulai,
    required int jatuhTempoSetelahPeriodeMulaiHari,
    required String status,
  }) async {
    try {
      _pesanError = null;
      _pesanSukses = null;
      loadingTagihan[kontrakId] = true;
      notifyListeners();
      tagihanByKontrak[kontrakId] = await api.simpanTagihan(kontrakId, {
        'hari_sebelum_periode_mulai': hariSebelumPeriodeMulai,
        'jatuh_tempo_setelah_periode_mulai_hari':
            jatuhTempoSetelahPeriodeMulaiHari,
        'status': status,
      });
      _pesanSukses = 'Pengaturan tagihan otomatis berhasil disimpan';
      return true;
    } catch (e) {
      _pesanError = e.toString();
      return false;
    } finally {
      loadingTagihan[kontrakId] = false;
      notifyListeners();
    }
  }

  Future<bool> ubahStatusTagihan(int kontrakId, bool aktif) async {
    try {
      _pesanError = null;
      _pesanSukses = null;
      loadingTagihan[kontrakId] = true;
      notifyListeners();
      tagihanByKontrak[kontrakId] = await api.ubahStatusTagihan(
        kontrakId,
        aktif ? 'aktif' : 'nonaktif',
      );
      _pesanSukses = aktif
          ? 'Tagihan otomatis diaktifkan'
          : 'Tagihan otomatis dinonaktifkan';
      return true;
    } catch (e) {
      _pesanError = e.toString();
      return false;
    } finally {
      loadingTagihan[kontrakId] = false;
      notifyListeners();
    }
  }

  Future<void> ambilPerpanjangan(int kontrakId, {bool force = false}) async {
    if (!force && perpanjanganByKontrak.containsKey(kontrakId)) return;
    try {
      _pesanError = null;
      loadingPerpanjangan[kontrakId] = true;
      notifyListeners();
      perpanjanganByKontrak[kontrakId] = await api.getPerpanjangan(kontrakId);
    } catch (e) {
      _pesanError = e.toString();
    } finally {
      loadingPerpanjangan[kontrakId] = false;
      notifyListeners();
    }
  }

  Future<bool> simpanPerpanjangan({
    required int kontrakId,
    required String jenisPerpanjangan,
    required int jumlahPeriodePerpanjangan,
    required int hariSebelumBerakhir,
    required int? hargaPerpanjangan,
    required String status,
  }) async {
    try {
      _pesanError = null;
      _pesanSukses = null;
      loadingPerpanjangan[kontrakId] = true;
      notifyListeners();
      perpanjanganByKontrak[kontrakId] = await api
          .simpanPerpanjangan(kontrakId, {
            'jenis_perpanjangan': jenisPerpanjangan,
            'jumlah_periode_perpanjangan': jumlahPeriodePerpanjangan,
            'hari_sebelum_berakhir': hariSebelumBerakhir,
            'harga_perpanjangan': hargaPerpanjangan,
            'status': status,
          });
      _pesanSukses =
          'Pengaturan perpanjangan kontrak otomatis berhasil disimpan';
      return true;
    } catch (e) {
      _pesanError = e.toString();
      return false;
    } finally {
      loadingPerpanjangan[kontrakId] = false;
      notifyListeners();
    }
  }

  Future<bool> ubahStatusPerpanjangan(int kontrakId, bool aktif) async {
    try {
      _pesanError = null;
      _pesanSukses = null;
      loadingPerpanjangan[kontrakId] = true;
      notifyListeners();
      perpanjanganByKontrak[kontrakId] = await api.ubahStatusPerpanjangan(
        kontrakId,
        aktif ? 'aktif' : 'nonaktif',
      );
      _pesanSukses = aktif
          ? 'Perpanjangan otomatis diaktifkan'
          : 'Perpanjangan otomatis dinonaktifkan';
      return true;
    } catch (e) {
      _pesanError = e.toString();
      return false;
    } finally {
      loadingPerpanjangan[kontrakId] = false;
      notifyListeners();
    }
  }
}
