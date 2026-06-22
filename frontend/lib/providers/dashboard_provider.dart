import 'package:flutter/material.dart';
import 'package:kos_management/features/dashboard/data/dashboard_dummy.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/dashboard_service.dart';
import 'package:kos_management/utils/rapikan_pesan_error_or_sukses.dart';

class DashboardProvider extends ChangeNotifier {
  static DashboardProvider? _instance;

  final DashboardService _api = DashboardService(ApiService());

  bool loading = false;
  bool loaded = false;
  bool _perluMuatUlang = false;
  String? _pesanError;

  String namaPemilik = DashboardDummy.namaPemilik;
  String periodeLabel = DashboardDummy.periodeLabel;
  int jumlahKos = 0;
  int totalKamar = 0;
  int kamarTerisi = 0;
  int penyewaAktif = 0;
  int kontrakAktif = 0;
  int okupansiPersen = 0;
  int pendapatanBulanIni = 0;
  int pendapatanBulanLalu = 0;
  int deltaPendapatanPersen = 0;
  int tagihanBelumLunas = 0;
  int tagihanTelat = 0;
  int pembayaranBulanIni = 0;

  List<DashboardKosOkupansi> okupansiPerKos = const [];
  List<DashboardTrendBulan> trendPendapatan = const [];
  List<DashboardStatusTagihan> statusTagihan = const [];
  List<DashboardAktivitas> aktivitasTerbaru = const [];
  List<DashboardTagihanPerhatian> tagihanPerhatian = const [];
  bool tampilkanTrendPendapatan = false;
  bool tampilkanHunianDetail = false;
  bool tampilkanTagihanDetail = false;
  bool tampilkanAktivitasDetail = false;

  DashboardProvider() {
    _instance = this;
  }

  bool get perluMuatUlang => _perluMuatUlang;

  void tandai_perlu_muat_ulang() {
    _perluMuatUlang = true;
    loaded = false;
    notifyListeners();
  }

  static void tandaiMuatUlang() {
    _instance?.tandai_perlu_muat_ulang();
  }

  String? get pesanError {
    final msg = rapikanPesan(_pesanError);
    return msg.isEmpty ? null : msg;
  }

  Future<void> muatRingkasan({bool force = false}) async {
    if (loading || loaded && !force && !_perluMuatUlang) return;

    try {
      loading = true;
      _pesanError = null;
      notifyListeners();

      final data = await _api.ambilRingkasan();
      _applyData(data);
      loaded = true;
      _perluMuatUlang = false;
    } catch (e) {
      _pesanError = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _applyData(Map<String, dynamic> data) {
    final pemilik = _map(data['pemilik']);
    final periode = _map(data['periode']);
    final ringkasan = _map(data['ringkasan']);
    final pendapatan = _map(data['pendapatan']);
    final okupansi = _map(data['okupansi']);
    final tagihan = _map(data['tagihan']);
    tampilkanTrendPendapatan = pendapatan.containsKey('trend');
    tampilkanHunianDetail = data.containsKey('okupansi');
    tampilkanTagihanDetail = data.containsKey('tagihan');
    tampilkanAktivitasDetail = data.containsKey('aktivitas');

    namaPemilik = '${pemilik['nama'] ?? DashboardDummy.namaPemilik}';
    periodeLabel = '${periode['label'] ?? DashboardDummy.periodeLabel}';

    jumlahKos = _intValue(ringkasan['jumlah_kos']);
    totalKamar = _intValue(ringkasan['total_kamar']);
    kamarTerisi = _intValue(ringkasan['kamar_terisi']);
    penyewaAktif = _intValue(ringkasan['penyewa_aktif']);
    kontrakAktif = _intValue(ringkasan['kontrak_aktif']);
    okupansiPersen = _intValue(ringkasan['okupansi_persen']);
    tagihanBelumLunas = _intValue(ringkasan['tagihan_belum_lunas']);
    tagihanTelat = _intValue(ringkasan['tagihan_telat']);
    pembayaranBulanIni = _intValue(ringkasan['pembayaran_bulan_ini']);

    pendapatanBulanIni = _intValue(pendapatan['bulan_ini']);
    pendapatanBulanLalu = _intValue(pendapatan['bulan_lalu']);
    deltaPendapatanPersen = _intValue(pendapatan['delta_persen']);

    okupansiPerKos = _list(
      okupansi['per_kos'],
    ).map(DashboardKosOkupansi.fromMap).toList();
    trendPendapatan = _list(
      pendapatan['trend'],
    ).map(DashboardTrendBulan.fromMap).toList();
    statusTagihan = _list(
      tagihan['status'],
    ).map(DashboardStatusTagihan.fromMap).toList();
    tagihanPerhatian = _list(
      tagihan['perhatian'],
    ).map(DashboardTagihanPerhatian.fromMap).toList();
    aktivitasTerbaru = _list(
      data['aktivitas'],
    ).map(DashboardAktivitas.fromMap).toList();
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value') ?? 0;
  }
}
