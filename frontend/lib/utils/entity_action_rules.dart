import 'package:kos_management/utils/kontrak_status.dart';
import 'package:kos_management/utils/tagihan_rules.dart';

/// Aturan tombol edit/hapus di list card — selaras dengan [backend_kos/services].
class EntityActionRules {
  EntityActionRules._();

  static int _angka(dynamic v) => int.tryParse('$v') ?? 0;

  static bool _aktif(Map<String, dynamic> data, {String key = 'status'}) {
    final s = '${data[key] ?? 'aktif'}'.toLowerCase();
    return s == 'aktif' || s.isEmpty;
  }

  static String _statusKondisiKamar(Map<String, dynamic> kamar) =>
      '${kamar['status_kondisi'] ?? 'kosong'}'.toLowerCase();

  // --- Kos (kos_service.js) ---
  // edit_kos: kos milik pemilik (tanpa cek status di query).
  // shapus_kos: kos status aktif; Kamar.count({ kos_id }) > 0 → ditolak.
  // Di list API, jumlah_kamar = hanya kamar status aktif.

  static bool bolehEditKos(Map<String, dynamic> kos) => _aktif(kos);

  static bool bolehHapusKos(Map<String, dynamic> kos) {
    if (!_aktif(kos)) return false;
    return _angka(kos['jumlah_kamar']) == 0;
  }

  static String? pesanEditKos(Map<String, dynamic> kos) {
    if (!_aktif(kos)) return 'Kos tidak aktif';
    return null;
  }

  static String? pesanHapusKos(Map<String, dynamic> kos) {
    if (!_aktif(kos)) return 'Kos tidak aktif';
    if (_angka(kos['jumlah_kamar']) > 0) {
      return 'Kos masih berisi kamar, tidak bisa dihapus';
    }
    return null;
  }

  // --- Kamar (kamar_service.js) ---
  // edit_kamar: kamar ada + milik pemilik (tanpa cek kontrak).
  // shapus_kamar: kamar aktif; Kontrak.count({ kamar_id, status: aktif/pending }) > 0 → ditolak.
  // status_kondisi kosong ≈ tidak ada kontrak aktif/pending yang menghuni (resetStatusKamar).

  static bool bolehEditKamar(Map<String, dynamic> kamar) => _aktif(kamar);

  static bool bolehHapusKamar(Map<String, dynamic> kamar) {
    if (!_aktif(kamar)) return false;
    return _statusKondisiKamar(kamar) == 'kosong';
  }

  static String? pesanEditKamar(Map<String, dynamic> kamar) {
    if (!_aktif(kamar)) return 'Kamar tidak aktif';
    return null;
  }

  static String? pesanHapusKamar(Map<String, dynamic> kamar) {
    if (!_aktif(kamar)) return 'Kamar tidak aktif';
    if (_statusKondisiKamar(kamar) != 'kosong') {
      return 'Masih ada penyewa dan kontrak di kamar ini';
    }
    return null;
  }

  // --- Penyewa (penyewa_service.js) ---
  // edit_penyewa: penyewa status aktif.
  // shapus_penyewa: penyewa aktif; Kontrak.count({ penyewa_id, status: aktif/pending }) > 0 → ditolak.

  static bool bolehEditPenyewa(Map<String, dynamic> penyewa) => _aktif(penyewa);

  static bool bolehHapusPenyewa(
    Map<String, dynamic> penyewa, {
    Map<String, dynamic>? kontrak,
  }) {
    if (!_aktif(penyewa)) return false;
    if (kontrak != null && KontrakStatus.menghalangiHapusPenyewa(kontrak)) {
      return false;
    }
    if (_angka(penyewa['jumlah_kontrak_aktif']) > 0) return false;
    // Di list kamar (tanpa objek kontrak), hapus disembunyikan — gunakan detail
    if (kontrak == null && penyewa['kamar_id'] != null) return false;
    return true;
  }

  static String? pesanEditPenyewa(Map<String, dynamic> penyewa) {
    if (!_aktif(penyewa)) return 'Penyewa tidak aktif';
    return null;
  }

  static String? pesanHapusPenyewa(
    Map<String, dynamic> penyewa, {
    Map<String, dynamic>? kontrak,
  }) {
    if (!_aktif(penyewa)) return 'Penyewa tidak aktif';
    if (!bolehHapusPenyewa(penyewa, kontrak: kontrak)) {
      return 'Penyewa masih memiliki kontrak aktif atau pending, tidak bisa dihapus';
    }
    return null;
  }

  // --- Tagihan (tagihan_helper.js pastikanBolehUbahTagihan, hapus = lifecycle cancelled) ---
  // edit/hapus: total_dibayar harus 0 & lifecycle bukan cancelled.

  static bool bolehUbahTagihan(Map<String, dynamic> tagihan) {
    if (TagihanRules.isCancelled(tagihan)) return false;
    return _angka(tagihan['total_dibayar']) == 0;
  }

  static bool bolehEditTagihan(Map<String, dynamic> tagihan) =>
      bolehUbahTagihan(tagihan);

  static bool bolehHapusTagihan(Map<String, dynamic> tagihan) =>
      bolehUbahTagihan(tagihan);

  static String? pesanUbahTagihan(Map<String, dynamic> tagihan) {
    if (TagihanRules.isCancelled(tagihan)) {
      return 'Tagihan sudah dibatalkan';
    }
    final dibayar = _angka(tagihan['total_dibayar']);
    if (dibayar > 0) {
      final total = _angka(tagihan['total_tagihan']);
      final sisa = total - dibayar;
      return 'Tagihan tidak bisa diubah atau dihapus karena sudah ada pembayaran '
          'Rp $dibayar. Sisa tagihan Rp $sisa.';
    }
    return null;
  }

  static String? pesanEditTagihan(Map<String, dynamic> tagihan) =>
      pesanUbahTagihan(tagihan);

  static String? pesanHapusTagihan(Map<String, dynamic> tagihan) =>
      pesanUbahTagihan(tagihan);

  // --- Pembayaran (pembayaran_service.js buat_refund_pembayaran) ---
  // refund: pembayaran status valid, bukan row refund, belum direfund penuh,
  // dan tagihan terkait belum lunas.

  static int totalRefundPembayaran(
    Map<String, dynamic> pembayaran,
    List<Map<String, dynamic>> semuaPembayaranTagihan,
  ) {
    final id = _angka(pembayaran['id']);
    if (id == 0) return 0;
    return semuaPembayaranTagihan
        .where(
          (row) =>
              '${row['status'] ?? ''}' == 'refund' &&
              _angka(row['pembayaran_ref_id']) == id,
        )
        .fold<int>(0, (total, row) => total + _angka(row['jumlah_bayar']));
  }

  static int sisaRefundPembayaran(
    Map<String, dynamic> pembayaran,
    List<Map<String, dynamic>> semuaPembayaranTagihan,
  ) {
    final jumlah = _angka(pembayaran['jumlah_bayar']);
    final refund = totalRefundPembayaran(pembayaran, semuaPembayaranTagihan);
    final sisa = jumlah - refund;
    return sisa < 0 ? 0 : sisa;
  }

  static bool bolehRefundPembayaran(
    Map<String, dynamic> pembayaran, {
    Map<String, dynamic>? tagihan,
    List<Map<String, dynamic>> semuaPembayaranTagihan = const [],
  }) {
    if ('${pembayaran['status'] ?? 'valid'}' != 'valid') return false;
    if (_angka(pembayaran['pembayaran_ref_id']) > 0) return false;
    if ('${tagihan?['status_pembayaran'] ?? ''}' == 'lunas') return false;
    return sisaRefundPembayaran(pembayaran, semuaPembayaranTagihan) > 0;
  }

  static String? pesanRefundPembayaran(
    Map<String, dynamic> pembayaran, {
    Map<String, dynamic>? tagihan,
    List<Map<String, dynamic>> semuaPembayaranTagihan = const [],
  }) {
    if ('${pembayaran['status'] ?? 'valid'}' != 'valid') {
      return 'Refund hanya bisa dari pembayaran valid';
    }
    if (_angka(pembayaran['pembayaran_ref_id']) > 0) {
      return 'Data ini adalah refund, bukan pembayaran asli';
    }
    if ('${tagihan?['status_pembayaran'] ?? ''}' == 'lunas') {
      return 'Tagihan sudah lunas, refund tidak diizinkan';
    }
    if (sisaRefundPembayaran(pembayaran, semuaPembayaranTagihan) <= 0) {
      return 'Pembayaran ini sudah direfund penuh';
    }
    return null;
  }
}
