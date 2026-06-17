import 'package:kos_management/utils/json_parse.dart';

class LaporanStatusRingkas {
  final int jumlah;
  final int nominal;

  const LaporanStatusRingkas({required this.jumlah, required this.nominal});

  factory LaporanStatusRingkas.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const LaporanStatusRingkas(jumlah: 0, nominal: 0);
    return LaporanStatusRingkas(
      jumlah: intFromJson(m['jumlah']) ?? 0,
      nominal: intFromJson(m['nominal']) ?? 0,
    );
  }
}

class LaporanTagihanData {
  final int totalTagihan;
  final int totalNominalTagihan;
  /// Jumlah nominal penuh tagihan di periode (sebelum pembayaran).
  final int totalNominalPenuh;
  final LaporanStatusRingkas lunas;
  final LaporanStatusRingkas sebagian;
  final LaporanStatusRingkas belumBayar;
  final LaporanStatusRingkas telat;
  final String? labelPeriode;

  const LaporanTagihanData({
    required this.totalTagihan,
    required this.totalNominalTagihan,
    required this.totalNominalPenuh,
    required this.lunas,
    required this.sebagian,
    required this.belumBayar,
    required this.telat,
    this.labelPeriode,
  });

  factory LaporanTagihanData.fromResponse(Map<String, dynamic> root) {
    final periode = root['periode'] is Map
        ? Map<String, dynamic>.from(root['periode'] as Map)
        : null;
    final t = root['tagihan'] is Map
        ? Map<String, dynamic>.from(root['tagihan'] as Map)
        : <String, dynamic>{};

    final nominalPenuh = intFromJson(t['total_nominal_penuh']);
    final nominalAgregat = intFromJson(t['total_nominal_tagihan']) ?? 0;

    return LaporanTagihanData(
      labelPeriode: periode?['label']?.toString(),
      totalTagihan: intFromJson(t['total_tagihan']) ?? 0,
      totalNominalTagihan: nominalAgregat,
      totalNominalPenuh: nominalPenuh ?? nominalAgregat,
      lunas: LaporanStatusRingkas.fromMap(
        t['lunas'] is Map ? Map<String, dynamic>.from(t['lunas'] as Map) : null,
      ),
      sebagian: LaporanStatusRingkas.fromMap(
        t['sebagian'] is Map
            ? Map<String, dynamic>.from(t['sebagian'] as Map)
            : null,
      ),
      belumBayar: LaporanStatusRingkas.fromMap(
        t['belum_bayar'] is Map
            ? Map<String, dynamic>.from(t['belum_bayar'] as Map)
            : null,
      ),
      telat: LaporanStatusRingkas.fromMap(
        t['telat'] is Map ? Map<String, dynamic>.from(t['telat'] as Map) : null,
      ),
    );
  }

  /// Sisa tagihan aktif di periode (sebagian + belum bayar + telat).
  int get sisaAktualPeriode =>
      sebagian.nominal + belumBayar.nominal + telat.nominal;

  static const kosong = LaporanTagihanData(
    totalTagihan: 0,
    totalNominalTagihan: 0,
    totalNominalPenuh: 0,
    lunas: LaporanStatusRingkas(jumlah: 0, nominal: 0),
    sebagian: LaporanStatusRingkas(jumlah: 0, nominal: 0),
    belumBayar: LaporanStatusRingkas(jumlah: 0, nominal: 0),
    telat: LaporanStatusRingkas(jumlah: 0, nominal: 0),
  );
}

class LaporanKeuanganData {
  final int totalUangBersih;
  final int totalUangMasuk;
  final int totalYangSisa;
  final int totalBayarTagihanMasaPeriode;
  final int totalBayarTagihanBulanDepan;
  final int totalPembayaran;
  final int totalNominalTransansaksi;
  final LaporanStatusRingkas valid;
  final LaporanStatusRingkas refund;
  final String? labelPeriode;

  const LaporanKeuanganData({
    required this.totalUangBersih,
    required this.totalUangMasuk,
    required this.totalYangSisa,
    required this.totalBayarTagihanMasaPeriode,
    required this.totalBayarTagihanBulanDepan,
    required this.totalPembayaran,
    required this.totalNominalTransansaksi,
    required this.valid,
    required this.refund,
    this.labelPeriode,
  });

  factory LaporanKeuanganData.fromResponse(Map<String, dynamic> root) {
    final periode = root['periode'] is Map
        ? Map<String, dynamic>.from(root['periode'] as Map)
        : null;
    final k = _mapKeuangan(root);
    final tr = root['transaksi'] is Map
        ? Map<String, dynamic>.from(root['transaksi'] as Map)
        : <String, dynamic>{};
    
    return LaporanKeuanganData(
      labelPeriode: periode?['label']?.toString(),
      totalUangBersih: intFromJson(k['total_uang_bersih'])??0,
      totalUangMasuk: intFromJson(k['total_uang_masuk']) ?? 0,
      totalYangSisa: intFromJson(
            k['total_yang_sisa'] ?? k['total_sisa_piutang'],
          ) ??
          0,
      totalBayarTagihanMasaPeriode: intFromJson(k['total_bayaran_masa_periode'])??0,
      totalBayarTagihanBulanDepan: intFromJson(k["total_bayaran_bulan_depan"])??0,
      totalPembayaran: intFromJson(tr['total_pembayaran']) ?? 0,
      totalNominalTransansaksi: intFromJson(tr["total_nominal_transaksi"])??0,
      valid: LaporanStatusRingkas.fromMap(
        tr['valid'] is Map ? Map<String, dynamic>.from(tr['valid'] as Map) : null,
      ),
      refund: LaporanStatusRingkas.fromMap(
        tr['refund'] is Map
            ? Map<String, dynamic>.from(tr['refund'] as Map)
            : null,
      ),
    );
  }

  LaporanKeuanganData copyWith({int? totalYangSisa}) {
    return LaporanKeuanganData(
      totalUangBersih: totalUangBersih,
      labelPeriode: labelPeriode,
      totalUangMasuk: totalUangMasuk,
      totalYangSisa: totalYangSisa ?? this.totalYangSisa,
      totalBayarTagihanMasaPeriode: totalBayarTagihanMasaPeriode,
      totalBayarTagihanBulanDepan: totalBayarTagihanBulanDepan,
      totalPembayaran: totalPembayaran,
      totalNominalTransansaksi: totalNominalTransansaksi,
      valid: valid,
      refund: refund,
    );
  }

  static Map<String, dynamic> _mapKeuangan(Map<String, dynamic> root) {
    if (root['keuangan'] is Map) {
      return Map<String, dynamic>.from(root['keuangan'] as Map);
    }
    return <String, dynamic>{};
  }

  static const kosong = LaporanKeuanganData(
    totalUangBersih: 0,
    totalUangMasuk: 0,
    totalYangSisa: 0,
    totalBayarTagihanMasaPeriode: 0,
    totalBayarTagihanBulanDepan: 0,
     totalPembayaran: 0,
    totalNominalTransansaksi: 0,
    valid: LaporanStatusRingkas(jumlah: 0, nominal: 0),
    refund: LaporanStatusRingkas(jumlah: 0, nominal: 0),
  );
}
