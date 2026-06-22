import 'package:kos_management/utils/kontrak_status.dart';

/// Aturan tombol aksi kontrak — selaras dengan [kontrak_service.js] backend.
class KontrakAksiRules {
  static DateTime hariIni() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime? parseTanggal(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse('$v'.split('T').first);
  }

  static String status(Map<String, dynamic> kontrak) =>
      KontrakStatus.normalize(kontrak['status']);

  /// Hari ini di dalam periode [mulai, selesai] (inklusif).
  static bool sedangBerjalan(Map<String, dynamic> kontrak) {
    final mulai = parseTanggal(kontrak['tanggal_mulai']);
    final selesai = parseTanggal(kontrak['tanggal_selesai']);
    if (mulai == null || selesai == null) return false;
    final today = hariIni();
    return !today.isBefore(mulai) && !today.isAfter(selesai);
  }

  /// Kontrak belum dimulai (hari ini sebelum tanggal_mulai).
  static bool belumBerjalan(Map<String, dynamic> kontrak) {
    final mulai = parseTanggal(kontrak['tanggal_mulai']);
    if (mulai == null) return false;
    return hariIni().isBefore(mulai);
  }

  /// Edit: backend hanya `status: pending`.
  static bool bolehEdit(Map<String, dynamic> kontrak) =>
      KontrakStatus.isPending(kontrak);

  /// Batalkan: backend hanya `status: pending`.
  static bool bolehHapus(Map<String, dynamic> kontrak) =>
      KontrakStatus.bolehDibatalkan(kontrak);

  /// Selesaikan: hanya status aktif & tanggal_mulai <= hari ini.
  static bool bolehSelesaikan(Map<String, dynamic> kontrak) {
    if (!KontrakStatus.isAktif(kontrak)) return false;
    final mulai = parseTanggal(kontrak['tanggal_mulai']);
    if (mulai == null) return false;
    return !hariIni().isBefore(mulai);
  }

  static String alasanEdit(Map<String, dynamic> kontrak) {
    if (KontrakStatus.isSelesai(kontrak) ||
        KontrakStatus.isDibatalkan(kontrak)) {
      return 'Kontrak sudah selesai atau dibatalkan';
    }
    if (!KontrakStatus.isPending(kontrak)) {
      return 'Edit hanya untuk kontrak pending';
    }
    return '';
  }

  static String alasanHapus(Map<String, dynamic> kontrak) {
    if (KontrakStatus.isSelesai(kontrak) ||
        KontrakStatus.isDibatalkan(kontrak)) {
      return 'Kontrak sudah selesai atau dibatalkan';
    }
    if (!KontrakStatus.isPending(kontrak)) {
      return 'Batalkan hanya untuk kontrak pending';
    }
    return '';
  }

  static String alasanSelesaikan(Map<String, dynamic> kontrak) {
    if (KontrakStatus.isPending(kontrak)) {
      return 'Selesaikan setelah kontrak menjadi aktif';
    }
    if (!KontrakStatus.isAktif(kontrak)) {
      return 'Hanya kontrak aktif yang bisa diselesaikan';
    }
    if (belumBerjalan(kontrak)) {
      return 'Selesaikan setelah tanggal mulai kontrak';
    }
    return '';
  }

  static String labelNomorKamar(Map<String, dynamic> kontrak) {
    final kamar = kontrak['kamar'];
    if (kamar is! Map) return '-';
    final nomor = kamar['nomor'] ?? kamar['nomor_kamar'] ?? kamar['nama_kamar'];
    if (nomor == null || '$nomor'.isEmpty) return '-';
    return 'No. $nomor';
  }
}
