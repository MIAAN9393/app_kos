import 'package:flutter/foundation.dart';

/// Sinyal refresh untuk tab Keuangan (laporan_keuangan + laporan_tagihan API).
class LaporanKeuanganProvider extends ChangeNotifier {
  static LaporanKeuanganProvider? _instance;

  bool _perlu_muat_ulang = false;

  LaporanKeuanganProvider() {
    _instance = this;
  }

  bool get perlu_muat_ulang => _perlu_muat_ulang;

  void tandai_perlu_muat_ulang() {
    _perlu_muat_ulang = true;
    notifyListeners();
  }

  static void tandaiMuatUlang() {
    _instance?.tandai_perlu_muat_ulang();
  }

  void selesai_muat_ulang() {
    if (!_perlu_muat_ulang) return;
    _perlu_muat_ulang = false;
    notifyListeners();
  }
}
