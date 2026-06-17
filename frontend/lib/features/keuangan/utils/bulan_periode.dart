/// Opsi bulan untuk filter laporan (format backend YYYY-MM).
class BulanPeriode {
  final String value;
  final String label;

  const BulanPeriode({required this.value, required this.label});

  static List<BulanPeriode> opsiTerakhir({int jumlah = 18}) {
    final now = DateTime.now();
    final list = <BulanPeriode>[];

    for (var i = 0; i < jumlah; i++) {
      final d = DateTime(now.year, now.month - i, 1);
      final value =
          '${d.year}-${d.month.toString().padLeft(2, '0')}';
      final nama = _namaBulan[d.month - 1];
      list.add(BulanPeriode(value: value, label: '$nama ${d.year}'));
    }

    return list;
  }

  static const _namaBulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static String labelDari(String value) {
    try {
      return opsiTerakhir(jumlah: 36)
          .firstWhere((b) => b.value == value)
          .label;
    } catch (_) {
      return value;
    }
  }

  static String bulanIni() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
