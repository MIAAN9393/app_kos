/// Utilitas item tagihan — selaras [tagihan_validator.js].
class TagihanItemUtils {
  static const tipeOptions = [
    ('sewa', 'Sewa'),
    ('insiden', 'Insiden / tambahan'),
    ('denda', 'Denda'),
    ('diskon', 'Diskon'),
  ];

  static String labelTipe(String tipe) {
    for (final o in tipeOptions) {
      if (o.$1 == tipe) return o.$2;
    }
    return tipe;
  }

  /// Total = jumlah (non-diskon) − diskon.
  static int hitungTotal(List<Map<String, dynamic>> items) {
    var total = 0;
    for (final i in items) {
      final nominal = int.tryParse('${i['nominal']}') ?? 0;
      if ('${i['tipe']}' == 'diskon') {
        total -= nominal;
      } else {
        total += nominal;
      }
    }
    return total;
  }

  static List<Map<String, dynamic>> parseItems(dynamic raw) {
    if (raw is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        out.add(_normalizeItem(Map<String, dynamic>.from(e)));
      } catch (_) {
        continue;
      }
    }
    return out;
  }

  static Map<String, dynamic> _normalizeItem(Map<String, dynamic> m) {
    return {
      if (m['id'] != null) 'id': int.tryParse('${m['id']}'),
      'tipe': '${m['tipe'] ?? 'sewa'}',
      'nama_item': '${m['nama_item'] ?? ''}',
      'deskripsi': '${m['deskripsi'] ?? ''}',
      'nominal': int.tryParse('${m['nominal']}') ?? 0,
    };
  }

  /// Kirim ke API tanpa geser timezone (hindari ISO UTC mundur 1 hari).
  static String formatTanggalApi(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static Map<String, dynamic> itemBaru({String tipe = 'sewa'}) => {
        'tipe': tipe,
        'nama_item': tipe == 'sewa' ? 'Sewa' : '',
        'deskripsi': '',
        'nominal': 0,
      };

  /// Payload untuk API create (tanpa id).
  static List<Map<String, dynamic>> toCreatePayload(
    List<Map<String, dynamic>> items,
  ) {
    return items.map((i) {
      return {
        'tipe': i['tipe'],
        'nama_item': i['nama_item'],
        'deskripsi': (i['deskripsi'] as String?)?.trim().isEmpty ?? true
            ? ''
            : i['deskripsi'],
        'nominal': int.tryParse('${i['nominal']}') ?? 0,
      };
    }).toList();
  }

  /// Payload untuk API edit — item dibuat ulang di server (tanpa id).
  static List<Map<String, dynamic>> toEditPayload(
    List<Map<String, dynamic>> items,
  ) =>
      toCreatePayload(items);

  static String? validasiPeriode({
    required DateTime periodeAwal,
    required DateTime periodeAkhir,
    required DateTime jatuhTempo,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final awal = DateTime(periodeAwal.year, periodeAwal.month, periodeAwal.day);
    final akhir = DateTime(periodeAkhir.year, periodeAkhir.month, periodeAkhir.day);
    final jatuh = DateTime(jatuhTempo.year, jatuhTempo.month, jatuhTempo.day);
    if (awal.isAfter(akhir)) {
      return 'Periode awal harus sebelum periode akhir';
    }
    if (!akhir.isAfter(today)) {
      return 'Periode akhir harus setelah hari ini';
    }
    if (jatuh.isBefore(awal) || jatuh.isAfter(akhir)) {
      return 'Jatuh tempo harus di antara periode awal dan akhir';
    }
    return null;
  }

  static String? validasiItems(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 'Minimal satu item tagihan wajib diisi';
    for (var n = 0; n < items.length; n++) {
      final i = items[n];
      final tipe = '${i['tipe']}';
      if (!tipeOptions.any((o) => o.$1 == tipe)) {
        return 'Item ${n + 1}: tipe tidak valid';
      }
      if ('${i['nama_item']}'.trim().isEmpty) {
        return 'Item ${n + 1}: nama wajib diisi';
      }
      final nominal = int.tryParse('${i['nominal']}');
      if (nominal == null || nominal < 0) {
        return 'Item ${n + 1}: nominal tidak valid';
      }
      if (nominal == 0) {
        return 'Item ${n + 1}: nominal harus lebih dari 0';
      }
    }
    final total = hitungTotal(items);
    if (total <= 0) {
      return 'Total tagihan harus lebih dari 0';
    }
    return null;
  }
}
