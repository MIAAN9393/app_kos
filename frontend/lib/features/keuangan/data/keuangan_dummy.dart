/// Data & logika filter dummy modul Keuangan.
class KeuanganDummy {
  static const int semuaId = 0;

  static const String jenisTagihan = 'tagihan';
  static const String jenisPembayaran = 'pembayaran';

  static const List<String> semuaStatusTagihan = [
    'lunas',
    'belum_bayar',
    'sebagian',
    'dibatalkan',
    'telat',
  ];

  static const List<String> semuaStatusPembayaran = ['valid', 'refund'];

  static const List<KeuanganOpsi> opsiKos = [
    KeuanganOpsi(id: semuaId, label: 'Semua kos'),
    KeuanganOpsi(id: 1, label: 'Kos Melati'),
    KeuanganOpsi(id: 2, label: 'Kos Anggrek'),
    KeuanganOpsi(id: 3, label: 'Kos Mawar'),
  ];

  static const List<KeuanganOpsi> opsiBulan = [
    KeuanganOpsi(id: 202604, label: 'Apr 2026'),
    KeuanganOpsi(id: 202605, label: 'Mei 2026'),
    KeuanganOpsi(id: 202606, label: 'Jun 2026'),
  ];

  static const List<KeuanganKamar> kamar = [
    KeuanganKamar(id: 101, kosId: 1, nomor: 'A1'),
    KeuanganKamar(id: 102, kosId: 1, nomor: 'A2'),
    KeuanganKamar(id: 103, kosId: 1, nomor: 'B12'),
    KeuanganKamar(id: 201, kosId: 2, nomor: 'C3'),
    KeuanganKamar(id: 202, kosId: 2, nomor: 'C4'),
    KeuanganKamar(id: 301, kosId: 3, nomor: 'D1'),
    KeuanganKamar(id: 302, kosId: 3, nomor: 'D2'),
  ];

  static const List<KeuanganOpsi> opsiPenyewa = [
    KeuanganOpsi(id: semuaId, label: 'Semua penyewa'),
    KeuanganOpsi(id: 1, label: 'Ahmad Rizki'),
    KeuanganOpsi(id: 2, label: 'Siti Rahayu'),
    KeuanganOpsi(id: 3, label: 'Dewi Lestari'),
    KeuanganOpsi(id: 4, label: 'Rina Wulandari'),
    KeuanganOpsi(id: 5, label: 'Joko Prasetyo'),
    KeuanganOpsi(id: 6, label: 'Maya Sari'),
    KeuanganOpsi(id: 7, label: 'Budi Hartono'),
    KeuanganOpsi(id: 8, label: 'Andi Kusuma'),
  ];

  static const List<KeuanganTransaksi> transaksi = [
    KeuanganTransaksi(
      id: '1',
      jenis: jenisPembayaran,
      status: 'valid',
      kosId: 1,
      kos: 'Kos Melati',
      kamarId: 103,
      kamar: 'B12',
      penyewaId: 1,
      penyewa: 'Ahmad Rizki',
      bulan: 202606,
      tanggal: '2 Jun 2026',
      keterangan: 'Bayar tagihan Jun/2026',
      jumlah: 1500000,
    ),
    KeuanganTransaksi(
      id: '2',
      jenis: jenisPembayaran,
      status: 'valid',
      kosId: 1,
      kos: 'Kos Melati',
      kamarId: 102,
      kamar: 'A2',
      penyewaId: 2,
      penyewa: 'Siti Rahayu',
      bulan: 202606,
      tanggal: '1 Jun 2026',
      keterangan: 'DP kontrak baru',
      jumlah: 500000,
    ),
    KeuanganTransaksi(
      id: '3',
      jenis: jenisTagihan,
      status: 'belum_bayar',
      kosId: 1,
      kos: 'Kos Melati',
      kamarId: 101,
      kamar: 'A1',
      penyewaId: 5,
      penyewa: 'Joko Prasetyo',
      bulan: 202606,
      tanggal: '1 Jun 2026',
      keterangan: 'Tagihan Jun — issued',
      jumlah: 800000,
    ),
    KeuanganTransaksi(
      id: '4',
      jenis: jenisTagihan,
      status: 'telat',
      kosId: 2,
      kos: 'Kos Anggrek',
      kamarId: 201,
      kamar: 'C3',
      penyewaId: 3,
      penyewa: 'Dewi Lestari',
      bulan: 202605,
      tanggal: '28 Mei 2026',
      keterangan: 'Tagihan Mei',
      jumlah: 1500000,
    ),
    KeuanganTransaksi(
      id: '5',
      jenis: jenisPembayaran,
      status: 'refund',
      kosId: 2,
      kos: 'Kos Anggrek',
      kamarId: 202,
      kamar: 'C4',
      penyewaId: 7,
      penyewa: 'Budi Hartono',
      bulan: 202605,
      tanggal: '31 Mei 2026',
      keterangan: 'Refund kelebihan bayar',
      jumlah: 200000,
    ),
    KeuanganTransaksi(
      id: '6',
      jenis: jenisPembayaran,
      status: 'valid',
      kosId: 3,
      kos: 'Kos Mawar',
      kamarId: 301,
      kamar: 'D1',
      penyewaId: 4,
      penyewa: 'Rina Wulandari',
      bulan: 202605,
      tanggal: '27 Mei 2026',
      keterangan: 'Cicilan tagihan Mei',
      jumlah: 700000,
    ),
    KeuanganTransaksi(
      id: '7',
      jenis: jenisTagihan,
      status: 'sebagian',
      kosId: 3,
      kos: 'Kos Mawar',
      kamarId: 301,
      kamar: 'D1',
      penyewaId: 4,
      penyewa: 'Rina Wulandari',
      bulan: 202605,
      tanggal: '1 Mei 2026',
      keterangan: 'Tagihan Mei — sisa Rp 500rb',
      jumlah: 1200000,
    ),
    KeuanganTransaksi(
      id: '8',
      jenis: jenisPembayaran,
      status: 'valid',
      kosId: 3,
      kos: 'Kos Mawar',
      kamarId: 302,
      kamar: 'D2',
      penyewaId: 6,
      penyewa: 'Maya Sari',
      bulan: 202605,
      tanggal: '25 Mei 2026',
      keterangan: 'Pelunasan tagihan Mei',
      jumlah: 1200000,
    ),
    KeuanganTransaksi(
      id: '9',
      jenis: jenisPembayaran,
      status: 'valid',
      kosId: 1,
      kos: 'Kos Melati',
      kamarId: 103,
      kamar: 'B12',
      penyewaId: 1,
      penyewa: 'Ahmad Rizki',
      bulan: 202605,
      tanggal: '3 Mei 2026',
      keterangan: 'Bayar tagihan Mei',
      jumlah: 1500000,
    ),
    KeuanganTransaksi(
      id: '10',
      jenis: jenisPembayaran,
      status: 'refund',
      kosId: 1,
      kos: 'Kos Melati',
      kamarId: 101,
      kamar: 'A1',
      penyewaId: 8,
      penyewa: 'Andi Kusuma',
      bulan: 202605,
      tanggal: '20 Mei 2026',
      keterangan: 'Refund pindah kamar',
      jumlah: 300000,
    ),
    KeuanganTransaksi(
      id: '11',
      jenis: jenisPembayaran,
      status: 'valid',
      kosId: 2,
      kos: 'Kos Anggrek',
      kamarId: 201,
      kamar: 'C3',
      penyewaId: 3,
      penyewa: 'Dewi Lestari',
      bulan: 202604,
      tanggal: '15 Apr 2026',
      keterangan: 'Bayar tagihan Apr',
      jumlah: 1500000,
    ),
    KeuanganTransaksi(
      id: '12',
      jenis: jenisTagihan,
      status: 'belum_bayar',
      kosId: 3,
      kos: 'Kos Mawar',
      kamarId: 302,
      kamar: 'D2',
      penyewaId: 6,
      penyewa: 'Maya Sari',
      bulan: 202604,
      tanggal: '1 Apr 2026',
      keterangan: 'Tagihan Apr',
      jumlah: 1100000,
    ),
    KeuanganTransaksi(
      id: '13',
      jenis: jenisTagihan,
      status: 'belum_bayar',
      kosId: 1,
      kos: 'Kos Melati',
      kamarId: 102,
      kamar: 'A2',
      penyewaId: 2,
      penyewa: 'Siti Rahayu',
      bulan: 202604,
      tanggal: '1 Apr 2026',
      keterangan: 'Tagihan Apr',
      jumlah: 900000,
    ),
    KeuanganTransaksi(
      id: '14',
      jenis: jenisPembayaran,
      status: 'valid',
      kosId: 2,
      kos: 'Kos Anggrek',
      kamarId: 202,
      kamar: 'C4',
      penyewaId: 7,
      penyewa: 'Budi Hartono',
      bulan: 202604,
      tanggal: '10 Apr 2026',
      keterangan: 'Bayar tagihan Apr',
      jumlah: 1300000,
    ),
    KeuanganTransaksi(
      id: '15',
      jenis: jenisTagihan,
      status: 'dibatalkan',
      kosId: 1,
      kos: 'Kos Melati',
      kamarId: 101,
      kamar: 'A1',
      penyewaId: 8,
      penyewa: 'Andi Kusuma',
      bulan: 202605,
      tanggal: '18 Mei 2026',
      keterangan: 'Tagihan Mei — dibatalkan',
      jumlah: 900000,
    ),
    KeuanganTransaksi(
      id: '16',
      jenis: jenisTagihan,
      status: 'lunas',
      kosId: 3,
      kos: 'Kos Mawar',
      kamarId: 302,
      kamar: 'D2',
      penyewaId: 6,
      penyewa: 'Maya Sari',
      bulan: 202606,
      tanggal: '5 Jun 2026',
      keterangan: 'Tagihan Jun — lunas',
      jumlah: 1200000,
    ),
  ];

  static String labelStatusTagihan(String s) => switch (s) {
        'lunas' => 'Lunas',
        'belum_bayar' => 'Belum bayar',
        'sebagian' => 'Sebagian',
        'dibatalkan' => 'Dibatalkan',
        'telat' => 'Telat',
        _ => s,
      };

  static String labelStatusPembayaran(String s) => switch (s) {
        'valid' => 'Valid',
        'refund' => 'Refund',
        _ => s,
      };

  static List<KeuanganOpsi> opsiKamarUntukKos(int kosId) {
    if (kosId == semuaId) {
      return [
        const KeuanganOpsi(id: semuaId, label: 'Semua kamar'),
        ...kamar.map(
          (k) => KeuanganOpsi(
            id: k.id,
            label: '${k.nomor} · ${_namaKos(k.kosId)}',
          ),
        ),
      ];
    }
    return [
      const KeuanganOpsi(id: semuaId, label: 'Semua kamar'),
      ...kamar
          .where((k) => k.kosId == kosId)
          .map((k) => KeuanganOpsi(id: k.id, label: 'Kamar ${k.nomor}')),
    ];
  }

  static String _namaKos(int id) {
    return opsiKos.firstWhere((k) => k.id == id, orElse: () => opsiKos[0]).label;
  }

  static String labelBulan(int bulan) {
    return opsiBulan
        .firstWhere((b) => b.id == bulan, orElse: () => opsiBulan.last)
        .label;
  }

  static List<KeuanganTransaksi> filter(KeuanganQuery q) {
    if (q.jenis.isEmpty) return [];

    return transaksi.where((t) {
      if (q.kosId != semuaId && t.kosId != q.kosId) return false;
      if (q.kamarId != semuaId && t.kamarId != q.kamarId) return false;
      if (q.penyewaId != semuaId && t.penyewaId != q.penyewaId) return false;
      if (t.bulan < q.bulanMulai || t.bulan > q.bulanAkhir) return false;

      if (t.jenis == jenisTagihan) {
        if (!q.jenis.contains(jenisTagihan)) return false;
        final aktif = q.statusTagihanAktif;
        if (aktif.isNotEmpty && !aktif.contains(t.status)) return false;
      } else if (t.jenis == jenisPembayaran) {
        if (!q.jenis.contains(jenisPembayaran)) return false;
        final aktif = q.statusPembayaranAktif;
        if (aktif.isNotEmpty && !aktif.contains(t.status)) return false;
      } else {
        return false;
      }

      return true;
    }).toList();
  }

  static bool _belumLunasTagihan(KeuanganTransaksi t) {
    return t.jenis == jenisTagihan &&
        (t.status == 'belum_bayar' ||
            t.status == 'sebagian' ||
            t.status == 'telat');
  }

  static List<KeuanganTransaksi> filterRentang({
    required int bulanMulai,
    required int bulanAkhir,
  }) {
    return filter(KeuanganQuery(
      bulanMulai: bulanMulai,
      bulanAkhir: bulanAkhir,
    ));
  }

  static KeuanganRingkasan ringkasan(List<KeuanganTransaksi> items) {
    final tagihan = KeuanganTagihanBreakdown();
    final pembayaran = KeuanganPembayaranBreakdown();
    var outstanding = 0;

    for (final t in items) {
      if (t.jenis == jenisTagihan) {
        tagihan.tambah(t.status, t.jumlah);
        if (_belumLunasTagihan(t)) outstanding += t.jumlah;
      } else if (t.jenis == jenisPembayaran) {
        pembayaran.tambah(t.status, t.jumlah);
      }
    }

    return KeuanganRingkasan(
      tagihan: tagihan,
      pembayaran: pembayaran,
      totalOutstanding: outstanding,
      jumlahTagihan: items.where((t) => t.jenis == jenisTagihan).length,
      jumlahPembayaran: items.where((t) => t.jenis == jenisPembayaran).length,
      jumlahItem: items.length,
    );
  }
}

class KeuanganQuery {
  final int kosId;
  final int kamarId;
  final int penyewaId;
  final int bulanMulai;
  final int bulanAkhir;
  final Set<String> jenis;
  final Set<String> statusTagihan;
  final Set<String> statusPembayaran;

  const KeuanganQuery({
    this.kosId = KeuanganDummy.semuaId,
    this.kamarId = KeuanganDummy.semuaId,
    this.penyewaId = KeuanganDummy.semuaId,
    this.bulanMulai = 202604,
    this.bulanAkhir = 202606,
    this.jenis = const {KeuanganDummy.jenisTagihan, KeuanganDummy.jenisPembayaran},
    this.statusTagihan = const {
      'lunas',
      'belum_bayar',
      'sebagian',
      'dibatalkan',
      'telat',
    },
    this.statusPembayaran = const {'valid', 'refund'},
  });

  /// Kosong = tampilkan semua status jenis tersebut.
  Set<String> get statusTagihanAktif =>
      jenis.contains(KeuanganDummy.jenisTagihan) ? statusTagihan : {};

  Set<String> get statusPembayaranAktif =>
      jenis.contains(KeuanganDummy.jenisPembayaran) ? statusPembayaran : {};

  KeuanganQuery copyWith({
    int? kosId,
    int? kamarId,
    int? penyewaId,
    int? bulanMulai,
    int? bulanAkhir,
    Set<String>? jenis,
    Set<String>? statusTagihan,
    Set<String>? statusPembayaran,
  }) {
    return KeuanganQuery(
      kosId: kosId ?? this.kosId,
      kamarId: kamarId ?? this.kamarId,
      penyewaId: penyewaId ?? this.penyewaId,
      bulanMulai: bulanMulai ?? this.bulanMulai,
      bulanAkhir: bulanAkhir ?? this.bulanAkhir,
      jenis: jenis ?? this.jenis,
      statusTagihan: statusTagihan ?? this.statusTagihan,
      statusPembayaran: statusPembayaran ?? this.statusPembayaran,
    );
  }

  String ringkasanFilter() {
    final kos =
        KeuanganDummy.opsiKos.firstWhere((k) => k.id == kosId).label;
    final mulai = KeuanganDummy.labelBulan(bulanMulai);
    final akhir = KeuanganDummy.labelBulan(bulanAkhir);
    final jenisLabel = [
      if (jenis.contains(KeuanganDummy.jenisTagihan)) 'Tagihan',
      if (jenis.contains(KeuanganDummy.jenisPembayaran)) 'Pembayaran',
    ].join(' + ');
    return '$kos · $mulai–$akhir · $jenisLabel';
  }
}

class KeuanganOpsi {
  final int id;
  final String label;

  const KeuanganOpsi({required this.id, required this.label});
}

class KeuanganKamar {
  final int id;
  final int kosId;
  final String nomor;

  const KeuanganKamar({
    required this.id,
    required this.kosId,
    required this.nomor,
  });
}

class KeuanganTransaksi {
  final String id;
  final String jenis;
  final String status;
  final int kosId;
  final String kos;
  final int kamarId;
  final String kamar;
  final int penyewaId;
  final String penyewa;
  final int bulan;
  final String tanggal;
  final String keterangan;
  final int jumlah;

  const KeuanganTransaksi({
    required this.id,
    required this.jenis,
    required this.status,
    required this.kosId,
    required this.kos,
    required this.kamarId,
    required this.kamar,
    required this.penyewaId,
    required this.penyewa,
    required this.bulan,
    required this.tanggal,
    required this.keterangan,
    required this.jumlah,
  });

  bool get isTagihan => jenis == KeuanganDummy.jenisTagihan;
  bool get isPembayaran => jenis == KeuanganDummy.jenisPembayaran;
}

class KeuanganRingkasan {
  final KeuanganTagihanBreakdown tagihan;
  final KeuanganPembayaranBreakdown pembayaran;
  final int totalOutstanding;
  final int jumlahTagihan;
  final int jumlahPembayaran;
  final int jumlahItem;

  const KeuanganRingkasan({
    required this.tagihan,
    required this.pembayaran,
    required this.totalOutstanding,
    required this.jumlahTagihan,
    required this.jumlahPembayaran,
    required this.jumlahItem,
  });

  int get totalUangMasuk => pembayaran.nominalValid;
  int get totalSisa => totalOutstanding;
  int get totalNominalTagihan => tagihan.nominalTotal;
  int get totalNominalPembayaran =>
      pembayaran.nominalValid + pembayaran.nominalRefund;
}

class KeuanganTagihanBreakdown {
  int lunas = 0;
  int nominalLunas = 0;
  int belumBayar = 0;
  int nominalBelumBayar = 0;
  int sebagian = 0;
  int nominalSebagian = 0;
  int dibatalkan = 0;
  int nominalDibatalkan = 0;
  int telat = 0;
  int nominalTelat = 0;

  void tambah(String status, int jumlah) {
    switch (status) {
      case 'lunas':
        lunas++;
        nominalLunas += jumlah;
        break;
      case 'belum_bayar':
        belumBayar++;
        nominalBelumBayar += jumlah;
        break;
      case 'sebagian':
        sebagian++;
        nominalSebagian += jumlah;
        break;
      case 'dibatalkan':
        dibatalkan++;
        nominalDibatalkan += jumlah;
        break;
      case 'telat':
        telat++;
        nominalTelat += jumlah;
        break;
    }
  }

  int get total =>
      lunas + belumBayar + sebagian + dibatalkan + telat;

  int get nominalTotal =>
      nominalLunas +
      nominalBelumBayar +
      nominalSebagian +
      nominalDibatalkan +
      nominalTelat;
}

class KeuanganPembayaranBreakdown {
  int valid = 0;
  int nominalValid = 0;
  int refund = 0;
  int nominalRefund = 0;

  void tambah(String status, int jumlah) {
    switch (status) {
      case 'valid':
        valid++;
        nominalValid += jumlah;
        break;
      case 'refund':
        refund++;
        nominalRefund += jumlah;
        break;
    }
  }

  int get total => valid + refund;
}
