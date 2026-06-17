import 'package:kos_management/providers/dashboard_provider.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kontrak_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/laporan_kos_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/providers/tagihan_provider.dart';

class AppDataInvalidator {
  AppDataInvalidator._();

  static void dashboard() {
    DashboardProvider.tandaiMuatUlang();
  }

  static void kontrak() {
    KontrakProvider.tandaiSemuaMuatUlang();
  }

  static void tagihan() {
    TagihanProvider.tandaiSemuaMuatUlang();
  }

  static void kos() {
    KosProvider.tandaiMuatUlang();
  }

  static void kamar({int? kosId}) {
    if (kosId != null) {
      KamarProvider.tandaiKosMuatUlang(kosId);
    } else {
      KamarProvider.tandaiSemuaMuatUlang();
    }
  }

  static void laporanKos({int? kosId}) {
    if (kosId != null) {
      LaporanKosProvider.tandaiMuatUlang(kosId);
    } else {
      LaporanKosProvider.tandaiSemuaMuatUlang();
    }
  }

  static void penyewa({int? kosId, int? kamarId}) {
    PenyewaProvider.tandaiSemuaMuatUlang();
    if (kosId != null) PenyewaProvider.tandaiKosMuatUlang(kosId);
    if (kamarId != null) PenyewaProvider.tandaiKamarMuatUlang(kamarId);
  }

  static void setelahKosBerubah() {
    dashboard();
    kos();
    kamar();
    laporanKos();
    penyewa();
  }

  static void setelahKamarBerubah({int? kosId}) {
    dashboard();
    kos();
    kamar(kosId: kosId);
    laporanKos(kosId: kosId);
    penyewa(kosId: kosId);
  }

  static void setelahPenyewaBerubah({int? kosId, int? kamarId}) {
    dashboard();
    kos();
    kamar(kosId: kosId);
    laporanKos(kosId: kosId);
    penyewa(kosId: kosId, kamarId: kamarId);
  }

  static void setelahKontrakBerubah({int? kosId, int? kamarId}) {
    dashboard();
    kos();
    kamar(kosId: kosId);
    laporanKos(kosId: kosId);
    kontrak();
    tagihan();
    penyewa(kosId: kosId, kamarId: kamarId);
  }

  static void setelahTagihanBerubah() {
    dashboard();
    tagihan();
  }

  static void setelahPembayaranBerubah() {
    dashboard();
    tagihan();
  }
}
