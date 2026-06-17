/// Data statis untuk eksplorasi UI — ganti dengan provider/API nanti.
class DashboardDummy {
  static const String namaPemilik = 'Budi Santoso';
  static const String periodeLabel = 'Juni 2026';

  static const int jumlahKos = 3;
  static const int totalKamar = 24;
  static const int kamarTerisi = 19;
  static const int penyewaAktif = 17;
  static const int kontrakAktif = 17;

  /// 19/24 kamar — sinkronkan jika angka di atas berubah.
  static const int okupansiPersen = 79;

  static const int pendapatanBulanIni = 28500000;
  static const int pendapatanBulanLalu = 24100000;
  static const int tagihanBelumLunas = 8;
  static const int tagihanTelat = 3;
  static const int pembayaranBulanIni = 12;

  static const int deltaPendapatanPersen = 18;

  static const List<DashboardKosOkupansi> okupansiPerKos = [
    DashboardKosOkupansi(nama: 'Kos Melati', terisi: 8, total: 10),
    DashboardKosOkupansi(nama: 'Kos Anggrek', terisi: 6, total: 8),
    DashboardKosOkupansi(nama: 'Kos Mawar', terisi: 5, total: 6),
  ];

  /// Tren pendapatan 6 bulan (juta rupiah) untuk line chart.
  static const List<DashboardTrendBulan> trendPendapatan = [
    DashboardTrendBulan(bulan: 'Jan', nilai: 18),
    DashboardTrendBulan(bulan: 'Feb', nilai: 22),
    DashboardTrendBulan(bulan: 'Mar', nilai: 20),
    DashboardTrendBulan(bulan: 'Apr', nilai: 24),
    DashboardTrendBulan(bulan: 'Mei', nilai: 26),
    DashboardTrendBulan(bulan: 'Jun', nilai: 28),
  ];

  /// Rincian status tagihan periode ini untuk donut chart.
  static const List<DashboardStatusTagihan> statusTagihan = [
    DashboardStatusTagihan(label: 'Lunas', jumlah: 14, status: 'lunas'),
    DashboardStatusTagihan(label: 'Sebagian', jumlah: 3, status: 'sebagian'),
    DashboardStatusTagihan(
      label: 'Belum bayar',
      jumlah: 5,
      status: 'belum_bayar',
    ),
    DashboardStatusTagihan(label: 'Telat', jumlah: 3, status: 'telat'),
  ];

  static const List<DashboardAktivitas> aktivitasTerbaru = [
    DashboardAktivitas(
      judul: 'Pembayaran lunas',
      detail: 'Ahmad — Tagihan Jun/2026',
      waktu: '2 jam lalu',
      ikon: 'pembayaran',
    ),
    DashboardAktivitas(
      judul: 'Kontrak baru',
      detail: 'Siti — Kamar B12, Kos Melati',
      waktu: 'Kemarin',
      ikon: 'kontrak',
    ),
    DashboardAktivitas(
      judul: 'Tagihan terbit',
      detail: '7 tagihan periode Juni',
      waktu: 'Kemarin',
      ikon: 'tagihan',
    ),
    DashboardAktivitas(
      judul: 'Pembayaran sebagian',
      detail: 'Rina — sisa Rp 500.000',
      waktu: '2 hari lalu',
      ikon: 'pembayaran',
    ),
  ];

  static const List<DashboardTagihanPerhatian> tagihanPerhatian = [
    DashboardTagihanPerhatian(
      penyewa: 'Dewi Lestari',
      kos: 'Kos Anggrek',
      jumlah: 1500000,
      status: 'telat',
      jatuhTempo: '25 Mei',
    ),
    DashboardTagihanPerhatian(
      penyewa: 'Joko Prasetyo',
      kos: 'Kos Melati',
      jumlah: 800000,
      status: 'belum_bayar',
      jatuhTempo: '1 Jun',
    ),
    DashboardTagihanPerhatian(
      penyewa: 'Maya Sari',
      kos: 'Kos Mawar',
      jumlah: 1200000,
      status: 'sebagian',
      jatuhTempo: '5 Jun',
    ),
  ];
}

class DashboardKosOkupansi {
  final String nama;
  final int terisi;
  final int total;

  const DashboardKosOkupansi({
    required this.nama,
    required this.terisi,
    required this.total,
  });

  factory DashboardKosOkupansi.fromMap(Map<String, dynamic> map) {
    return DashboardKosOkupansi(
      nama: '${map['nama'] ?? map['nama_kos'] ?? '-'}',
      terisi: _intValue(map['terisi']),
      total: _intValue(map['total']),
    );
  }

  int get persen => total == 0 ? 0 : ((terisi / total) * 100).round();
}

class DashboardTrendBulan {
  final String bulan;

  /// Nilai dalam juta rupiah.
  final double nilai;

  const DashboardTrendBulan({required this.bulan, required this.nilai});

  factory DashboardTrendBulan.fromMap(Map<String, dynamic> map) {
    final nominal = _numValue(map['nominal']);
    return DashboardTrendBulan(
      bulan: '${map['bulan'] ?? '-'}',
      nilai: nominal == null ? _numValue(map['nilai']) ?? 0 : nominal / 1000000,
    );
  }
}

class DashboardStatusTagihan {
  final String label;
  final int jumlah;
  final String status;

  const DashboardStatusTagihan({
    required this.label,
    required this.jumlah,
    required this.status,
  });

  factory DashboardStatusTagihan.fromMap(Map<String, dynamic> map) {
    return DashboardStatusTagihan(
      label: '${map['label'] ?? '-'}',
      jumlah: _intValue(map['jumlah']),
      status: '${map['status'] ?? ''}',
    );
  }
}

class DashboardAktivitas {
  final String judul;
  final String detail;
  final String waktu;
  final String ikon;

  const DashboardAktivitas({
    required this.judul,
    required this.detail,
    required this.waktu,
    required this.ikon,
  });

  factory DashboardAktivitas.fromMap(Map<String, dynamic> map) {
    return DashboardAktivitas(
      judul: '${map['judul'] ?? '-'}',
      detail: '${map['detail'] ?? '-'}',
      waktu: '${map['waktu'] ?? '-'}',
      ikon: '${map['ikon'] ?? 'default'}',
    );
  }
}

class DashboardTagihanPerhatian {
  final String penyewa;
  final String kos;
  final int jumlah;
  final String status;
  final String jatuhTempo;

  const DashboardTagihanPerhatian({
    required this.penyewa,
    required this.kos,
    required this.jumlah,
    required this.status,
    required this.jatuhTempo,
  });

  factory DashboardTagihanPerhatian.fromMap(Map<String, dynamic> map) {
    return DashboardTagihanPerhatian(
      penyewa: '${map['penyewa'] ?? '-'}',
      kos: '${map['kos'] ?? '-'}',
      jumlah: _intValue(map['jumlah']),
      status: '${map['status'] ?? ''}',
      jatuhTempo: '${map['jatuh_tempo'] ?? map['jatuhTempo'] ?? '-'}',
    );
  }
}

int _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}

double? _numValue(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}
