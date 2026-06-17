import 'package:kos_management/utils/kontrak_status.dart';
import 'package:kos_management/utils/tagihan_item_utils.dart';

/// Aturan tagihan — selaras [tagihan_service.js] & [tagihan_validator.js].
class TagihanRules {
  TagihanRules._();

  static const String lifecycleDraft = 'draft';
  static const String lifecycleIssued = 'issued';
  static const String lifecycleCancelled = 'cancelled';

  static const String bayarBelum = 'belum_bayar';
  static const String bayarSebagian = 'sebagian';
  static const String bayarLunas = 'lunas';
  static const String bayarTelat = 'telat';

  static String normalizeLifecycle(dynamic raw) =>
      '${raw ?? lifecycleDraft}'.trim().toLowerCase();

  static String normalizeBayar(dynamic raw) =>
      '${raw ?? bayarBelum}'.trim().toLowerCase();

  /// Status untuk badge/card (prioritas dibatalkan).
  static String badgeStatus(Map<String, dynamic> tagihan) {
    if (isCancelled(tagihan)) return lifecycleCancelled;
    return normalizeBayar(tagihan['status_pembayaran']);
  }

  static String labelBayar(String status) {
    switch (status) {
      case bayarBelum:
        return 'Belum bayar';
      case bayarSebagian:
        return 'Sebagian';
      case bayarLunas:
        return 'Lunas';
      case bayarTelat:
        return 'Telat';
      case lifecycleCancelled:
        return 'Dibatalkan';
      default:
        return status.isEmpty ? '—' : status;
    }
  }

  static bool isCancelled(Map<String, dynamic> tagihan) =>
      normalizeLifecycle(tagihan['lifecycle']) == lifecycleCancelled;

  static bool isAktifUntukTagihan(Map<String, dynamic>? kontrak) {
    if (kontrak == null) return false;
    return KontrakStatus.isAktif(kontrak);
  }

  static String? pesanKontrakUntukBuatTagihan(Map<String, dynamic>? kontrak) {
    if (kontrak == null) return 'Kontrak tidak ditemukan';
    if (KontrakStatus.isPending(kontrak)) {
      return 'Kontrak masih pending. Tagihan hanya untuk kontrak aktif.';
    }
    if (KontrakStatus.isSelesai(kontrak) ||
        KontrakStatus.isDibatalkan(kontrak)) {
      return 'Kontrak sudah selesai atau dibatalkan.';
    }
    if (!KontrakStatus.isAktif(kontrak)) {
      return 'Hanya kontrak berstatus aktif yang bisa ditagih.';
    }
    return null;
  }

  static bool periodeOverlap({
    required DateTime awalA,
    required DateTime akhirA,
    required DateTime awalB,
    required DateTime akhirB,
  }) {
    final a0 = DateTime(awalA.year, awalA.month, awalA.day);
    final a1 = DateTime(akhirA.year, akhirA.month, akhirA.day);
    final b0 = DateTime(awalB.year, awalB.month, awalB.day);
    final b1 = DateTime(akhirB.year, akhirB.month, akhirB.day);
    return !a0.isAfter(b1) && !b0.isAfter(a1);
  }

  static DateTime? parseTanggal(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse('$v'.split('T').first);
  }

  static DateTime tanggalSaja(DateTime d) => DateTime(d.year, d.month, d.day);

  static String? pesanPeriodeDalamKontrak({
    required Map<String, dynamic>? kontrak,
    required DateTime periodeAwal,
    required DateTime periodeAkhir,
  }) {
    if (kontrak == null) return 'Kontrak tidak ditemukan';

    final mulai = parseTanggal(kontrak['tanggal_mulai']);
    final selesai = parseTanggal(kontrak['tanggal_selesai']);
    final awal = tanggalSaja(periodeAwal);

    if (mulai != null && awal.isBefore(tanggalSaja(mulai))) {
      return 'periode awal tidak boleh lebih lama dari periode awal kontrakan';
    }
    if (selesai != null) {
      final batasAkhir = tanggalSaja(selesai);
      if (awal.isAfter(batasAkhir)) {
        return 'periode awal tagihan harus berada di dalam periode kontrak';
      }
    }
    return null;
  }

  /// Cek duplikat item SEWA (backend buat_tagihan / edit_tagihan).
  /// [excludeTagihanId] — saat edit, abaikan tagihan yang sedang diubah.
  static String? pesanDuplikatSewaPeriode({
    required List<Map<String, dynamic>> tagihanList,
    required DateTime periodeAwal,
    required DateTime periodeAkhir,
    required List<Map<String, dynamic>> listItemBaru,
    int? excludeTagihanId,
  }) {
    final adaSewaBaru = listItemBaru.any((i) => '${i['tipe']}' == 'sewa');
    if (!adaSewaBaru) return null;

    for (final t in tagihanList) {
      if (excludeTagihanId != null) {
        final tid = int.tryParse('${t['id']}');
        if (tid != null && tid == excludeTagihanId) continue;
      }
      if (isCancelled(t)) continue;
      final awal = parseTanggal(t['periode_awal']);
      final akhir = parseTanggal(t['periode_akhir']);
      if (awal == null || akhir == null) continue;
      if (!periodeOverlap(
        awalA: periodeAwal,
        akhirA: periodeAkhir,
        awalB: awal,
        akhirB: akhir,
      )) {
        continue;
      }
      final items = TagihanItemUtils.parseItems(t['items']);
      if (items.any((i) => '${i['tipe']}' == 'sewa')) {
        return 'Tagihan SEWA untuk periode ini sudah ada pada kontrak yang sama';
      }
    }
    return null;
  }

  static bool matchFilterBelum(Map<String, dynamic> t) =>
      !isCancelled(t) && normalizeBayar(t['status_pembayaran']) == bayarBelum;

  static bool matchFilterSebagianTelat(Map<String, dynamic> t) {
    if (isCancelled(t)) return false;
    final s = normalizeBayar(t['status_pembayaran']);
    return s == bayarSebagian || s == bayarTelat;
  }

  static bool matchFilterLunas(Map<String, dynamic> t) =>
      !isCancelled(t) && normalizeBayar(t['status_pembayaran']) == bayarLunas;

  static bool matchFilterDibatalkan(Map<String, dynamic> t) => isCancelled(t);
}
