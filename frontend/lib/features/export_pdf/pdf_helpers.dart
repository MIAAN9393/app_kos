import 'package:intl/intl.dart';

class PdfHelpers {
  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String text(dynamic value, {String fallback = '-'}) {
    final raw = '${value ?? ''}'.trim();
    if (raw.isEmpty || raw == 'null') return fallback;
    return raw;
  }

  static int angka(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }

  static String rupiah(dynamic value) => _rupiah.format(angka(value));

  static String tanggal(dynamic value, {String fallback = '-'}) {
    final raw = text(value, fallback: '');
    if (raw.isEmpty) return fallback;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.split('T').first;
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${parsed.day.toString().padLeft(2, '0')} ${bulan[parsed.month - 1]} ${parsed.year}';
  }

  static String periode(dynamic awal, dynamic akhir) {
    return '${tanggal(awal)} - ${tanggal(akhir)}';
  }

  static String status(dynamic value) {
    final raw = text(value).replaceAll('_', ' ').toLowerCase();
    if (raw == '-') return raw;
    return raw
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String fileName(String prefix, {String? code}) {
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final safeCode = text(code, fallback: '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final parts = [
      prefix.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_'),
      if (safeCode.isNotEmpty) safeCode,
      stamp,
    ];
    return '${parts.join('_')}.pdf';
  }

  static List<Map<String, dynamic>> listMap(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }
}
