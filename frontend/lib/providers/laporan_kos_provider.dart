import 'package:flutter/material.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/kos_service.dart';
import 'package:kos_management/utils/rapikan_pesan_error_or_sukses.dart';

class LaporanKosProvider extends ChangeNotifier {
  static LaporanKosProvider? _instance;

  final KosService api = KosService(ApiService());
  Map<int, List<Map<String, dynamic>>> data_laporan_kos = {};

  bool loading = false;
  Map<int, bool> _perlu_muat_ulang = {};

  LaporanKosProvider() {
    _instance = this;
  }

  /// Tandai cache laporan kos perlu di-fetch ulang (mis. setelah bayar/refund/tagihan).
  void tandai_perlu_muat_ulang(int kos_id) {
    _perlu_muat_ulang[kos_id] = true;
    notifyListeners();
  }

  /// Dipanggil dari provider lain tanpa [BuildContext].
  static void tandaiMuatUlang(int kos_id) {
    _instance?.tandai_perlu_muat_ulang(kos_id);
  }

  void tandai_semua_perlu_muat_ulang() {
    if (data_laporan_kos.isEmpty) return;
    for (final kosId in data_laporan_kos.keys) {
      _perlu_muat_ulang[kosId] = true;
    }
    notifyListeners();
  }

  static void tandaiSemuaMuatUlang() {
    _instance?.tandai_semua_perlu_muat_ulang();
  }

  String? _pesan_error;
  String? _pesan_sukses;

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

  Future<void> ambil_or_fecth(int kos_id) async {
    final data = data_laporan_kos[kos_id];
    if (data == null || data.isEmpty || _perlu_muat_ulang[kos_id] == true) {
      await ambil_data_kos_provider(kos_id);
    }
  }

  /// Fetch ulang hanya jika sebelumnya ditandai stale (mis. setelah bayar/tagihan).
  Future<void> muat_ulang_jika_perlu(int kos_id) async {
    if (_perlu_muat_ulang[kos_id] == true) {
      await ambil_data_kos_provider(kos_id);
    }
  }

  Future<void> ambil_data_kos_provider(int kos_id) async {
    try {
      loading = true;
      _pesan_error = null;
      notifyListeners();
      try {
        data_laporan_kos[kos_id] = await api.laporan_kos(kos_id);
      } catch (e) {
        data_laporan_kos[kos_id] = [];
        _pesan_error = e.toString();
      }
      _perlu_muat_ulang[kos_id] = false;
    } catch (e) {
      _pesan_error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
