class SisaHari {
  SisaHari._();

  static bool kontrakMasihBerjalan(dynamic status) {
    return '${status ?? ''}'.trim().toLowerCase() == 'aktif';
  }

  static bool tagihanMasihBerjalan({
    dynamic lifecycle,
    dynamic statusPembayaran,
  }) {
    final life = '${lifecycle ?? 'draft'}'.trim().toLowerCase();
    final bayar = '${statusPembayaran ?? 'belum_bayar'}'.trim().toLowerCase();
    if (life == 'cancelled') return false;
    if (bayar == 'lunas') return false;
    return true;
  }

  static DateTime? _parse(dynamic value) {
    final text = '${value ?? ''}'.trim();
    if (text.isEmpty || text == 'null' || text == '-') return null;
    final date = DateTime.tryParse(text.split('T').first);
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static int? hariKe(dynamic tanggal) {
    final target = _parse(tanggal);
    if (target == null) return null;
    return target.difference(_today()).inDays;
  }

  static int? durasiHari(dynamic mulai, dynamic selesai) {
    final start = _parse(mulai);
    final end = _parse(selesai);
    if (start == null || end == null) return null;
    return end.difference(start).inDays + 1;
  }

  static String? labelSisa(
    dynamic tanggal, {
    String prefix = 'Sisa',
    String todayLabel = 'Hari ini',
    String pastPrefix = 'Lewat',
  }) {
    final hari = hariKe(tanggal);
    if (hari == null) return null;
    if (hari > 0) return '$prefix $hari hari';
    if (hari == 0) return todayLabel;
    return '$pastPrefix ${hari.abs()} hari';
  }

  static String? labelKontrak(
    dynamic mulai,
    dynamic selesai, {
    dynamic status,
  }) {
    if (!kontrakMasihBerjalan(status)) return null;
    final parts = <String>[];
    final durasi = durasiHari(mulai, selesai);
    if (durasi != null) parts.add('Durasi $durasi hari');
    final sisa = labelSisa(
      selesai,
      prefix: 'Sisa kontrak',
      todayLabel: 'Kontrak berakhir hari ini',
      pastPrefix: 'Kontrak lewat',
    );
    if (sisa != null) parts.add(sisa);
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String? labelJatuhTempo(
    dynamic jatuhTempo, {
    dynamic lifecycle,
    dynamic statusPembayaran,
  }) {
    if (!tagihanMasihBerjalan(
      lifecycle: lifecycle,
      statusPembayaran: statusPembayaran,
    )) {
      return null;
    }
    return labelSisa(
      jatuhTempo,
      prefix: 'Jatuh tempo',
      todayLabel: 'Jatuh tempo hari ini',
      pastPrefix: 'Telat',
    );
  }
}
