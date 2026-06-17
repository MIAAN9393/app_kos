/// Status kontrak — selaras ENUM backend: aktif, pending, selesai, dibatalkan.
class KontrakStatus {
  KontrakStatus._();

  static const String aktif = 'aktif';
  static const String pending = 'pending';
  static const String selesai = 'selesai';
  static const String dibatalkan = 'dibatalkan';

  static const List<String> values = [aktif, pending, selesai, dibatalkan];

  /// Normalisasi typo lama / casing.
  static String normalize(dynamic raw) {
    final s = '${raw ?? ''}'.trim().toLowerCase();
    if (s == 'pandding') return pending;
    if (values.contains(s)) return s;
    return s;
  }

  static String label(dynamic raw) {
    switch (normalize(raw)) {
      case aktif:
        return 'Aktif';
      case pending:
        return 'Pending';
      case selesai:
        return 'Selesai';
      case dibatalkan:
        return 'Dibatalkan';
      default:
        final s = normalize(raw);
        return s.isEmpty ? '—' : s;
    }
  }

  static bool isAktif(Map<String, dynamic> kontrak) =>
      normalize(kontrak['status']) == aktif;

  static bool isPending(Map<String, dynamic> kontrak) =>
      normalize(kontrak['status']) == pending;

  static bool isSelesai(Map<String, dynamic> kontrak) =>
      normalize(kontrak['status']) == selesai;

  static bool isDibatalkan(Map<String, dynamic> kontrak) =>
      normalize(kontrak['status']) == dibatalkan;

  /// Backend: kontrak `aktif` dan `pending` menghalangi hapus penyewa / hitung kapasitas.
  static bool menghalangiHapusPenyewa(Map<String, dynamic> kontrak) =>
      isAktif(kontrak) || isPending(kontrak);

  /// Masih bisa dibatalkan (backend hapus_kontrak).
  static bool bolehDibatalkan(Map<String, dynamic> kontrak) {
    return isPending(kontrak);
  }
}
