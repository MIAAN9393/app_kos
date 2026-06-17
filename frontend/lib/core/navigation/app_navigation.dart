import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_routes.dart';
import 'package:kos_management/core/navigation/app_shell.dart';

class AppNavigation {
  static void goHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  static void goLogin(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  static void switchTab(BuildContext context, int index) {
    context.switchShellTab(index);
  }

  static void toKosDetail(BuildContext context, {required int idKos}) {
    Navigator.pushNamed(
      context,
      AppRoutes.kosDetail,
      arguments: {'idKos': idKos},
    );
  }

  static void toKosStatistik(BuildContext context, {required int idKos}) {
    Navigator.pushNamed(
      context,
      AppRoutes.kosStatistik,
      arguments: {'idKos': idKos},
    );
  }

  static void toKamarDetail(
    BuildContext context, {
    required int idKamar,
    required int idKos,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.kamarDetail,
      arguments: {'idKamar': idKamar, 'idKos': idKos},
    );
  }

  static void toPenyewaList(
    BuildContext context, {
    required int idKamar,
    required int idKos,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.listPenyewa,
      arguments: {'id_kamar': idKamar, 'id_kos': idKos},
    );
  }

  static void toPenyewaDetail(
    BuildContext context, {
    required int idPenyewa,
    int? idKamar,
    int? idKos,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.detailPenyewa,
      arguments: {
        'id_penyewa': idPenyewa,
        'id_kamar': idKamar,
        'id_kos': idKos,
      },
    );
  }

  static void toPenyewaProfile(
    BuildContext context, {
    required int idPenyewa,
    int? idKamar,
    int? idKos,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.profilePenyewa,
      arguments: {
        'id_penyewa': idPenyewa,
        'id_kamar': idKamar,
        'id_kos': idKos,
      },
    );
  }

  static void toTambahPenyewaKontrak(
    BuildContext context, {
    int? idKamar,
    int? idKos,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.tambahPenyewaKontrak,
      arguments: {'idKamar': idKamar, 'idKos': idKos},
    );
  }

  static Future<bool?> toTambahKos(BuildContext context) {
    return Navigator.pushNamed<bool>(context, AppRoutes.kosTambah);
  }

  static Future<bool?> toEditKos(
    BuildContext context, {
    required int idKos,
    required String nama,
    required String alamat,
    String? deskripsi,
  }) {
    return Navigator.pushNamed<bool>(
      context,
      AppRoutes.kosEdit,
      arguments: {
        'idKos': idKos,
        'nama': nama,
        'alamat': alamat,
        'deskripsi': deskripsi ?? '',
      },
    );
  }

  static Future<bool?> toTambahKamar(
    BuildContext context, {
    required int idKos,
  }) {
    return Navigator.pushNamed<bool>(
      context,
      AppRoutes.kamarTambah,
      arguments: {'idKos': idKos},
    );
  }

  static Future<bool?> toEditKamar(
    BuildContext context, {
    required int idKamar,
    required int idKos,
    required String nomor,
    required String harga,
    required String kapasitas,
    List<String>? fasilitas,
  }) {
    return Navigator.pushNamed<bool>(
      context,
      AppRoutes.kamarEdit,
      arguments: {
        'idKamar': idKamar,
        'idKos': idKos,
        'nomor': nomor,
        'harga': harga,
        'kapasitas': kapasitas,
        'fasilitas': fasilitas ?? const [],
      },
    );
  }

  static Future<bool?> toEditKontrak(
    BuildContext context, {
    required int kontrakId,
    required int idPenyewa,
    required int idKamar,
    required String harga,
    required String mulai,
    required String selesai,
    String siklus = 'bulanan',
  }) {
    return Navigator.pushNamed<bool>(
      context,
      AppRoutes.kontrakEdit,
      arguments: {
        'kontrakId': kontrakId,
        'idPenyewa': idPenyewa,
        'idKamar': idKamar,
        'harga': harga,
        'mulai': mulai,
        'selesai': selesai,
        'siklus': siklus,
      },
    );
  }

  static void toKontrakDetail(
    BuildContext context, {
    required int kontrakId,
    required int idPenyewa,
    int? idKamar,
    int? idKos,
    Map<String, dynamic>? kontrak,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.kontrakDetail,
      arguments: {
        'kontrakId': kontrakId,
        'idPenyewa': idPenyewa,
        'idKamar': idKamar,
        'idKos': idKos,
        'kontrak': kontrak,
      },
    );
  }

  static Future<bool?> toEditPenyewa(
    BuildContext context, {
    required int idPenyewa,
    required String nama,
    required String noTelpon,
    required String email,
    String? tanggalLahir,
    String? jenisKelamin,
    String? statusHubungan,
  }) {
    return Navigator.pushNamed<bool>(
      context,
      AppRoutes.editPenyewa,
      arguments: {
        'idPenyewa': idPenyewa,
        'nama': nama,
        'no_telpon': noTelpon,
        'email': email,
        'tanggal_lahir': tanggalLahir ?? '',
        'jenis_kelamin': jenisKelamin ?? '',
        'status_hubungan': statusHubungan ?? '',
      },
    );
  }

  static Future<bool?> toTambahTagihan(
    BuildContext context, {
    required int idPenyewa,
    required int idKamar,
    required int idKos,
  }) {
    return Navigator.pushNamed<bool>(
      context,
      AppRoutes.tagihanTambah,
      arguments: {'idPenyewa': idPenyewa, 'id_kamar': idKamar, 'id_kos': idKos},
    );
  }

  static Future<bool?> toEditTagihan(
    BuildContext context, {
    required int tagihanId,
    required int idPenyewa,
  }) {
    return Navigator.pushNamed<bool>(
      context,
      AppRoutes.tagihanEdit,
      arguments: {'tagihanId': tagihanId, 'idPenyewa': idPenyewa},
    );
  }

  static void toTagihanDetail(
    BuildContext context, {
    required int tagihanId,
    required int penyewaId,
    required int idKamar,
    required int idKos,
    int? kontrakId,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.detailTagihan,
      arguments: {
        'tagihanId': tagihanId,
        'penyewaId': penyewaId,
        'id_kamar': idKamar,
        'id_kos': idKos,
        'kontrakId': kontrakId,
      },
    );
  }

  static void toPembayaranDetail(
    BuildContext context, {
    required Map<String, dynamic> pembayaran,
    Map<String, dynamic>? tagihan,
    int? penyewaId,
    int? idKamar,
    int? idKos,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.pembayaranDetail,
      arguments: {
        'pembayaran': pembayaran,
        'tagihan': tagihan,
        'penyewaId': penyewaId,
        'idKamar': idKamar,
        'idKos': idKos,
      },
    );
  }

  static void toCheckInCepat(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.checkInCepat);
  }

  static void toDashboard(BuildContext context) {
    if (ShellScope.maybeOf(context) != null) {
      switchTab(context, AppShellTabs.dashboard);
      return;
    }
    Navigator.pushNamed(context, AppRoutes.dashboard);
  }

  static void toDashboardTab(BuildContext context) {
    switchTab(context, AppShellTabs.dashboard);
  }

  static void toControllTab(BuildContext context) {
    switchTab(context, AppShellTabs.controll);
  }

  static void toKeuanganTab(BuildContext context) {
    switchTab(context, AppShellTabs.keuangan);
  }

  static void toKeuangan(BuildContext context) {
    if (ShellScope.maybeOf(context) != null) {
      toKeuanganTab(context);
      return;
    }
    Navigator.pushNamed(context, AppRoutes.keuangan);
  }

  static void toProfile(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.profile);
  }

  static void toSettings(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.settings);
  }

  static void toPropertyTab(BuildContext context) {
    switchTab(context, AppShellTabs.property);
  }
}
