import 'dart:typed_data';

import 'package:kos_management/features/export_pdf/pdf_helpers.dart';
import 'package:kos_management/features/export_pdf/pdf_theme.dart';
import 'package:kos_management/features/keuangan/models/laporan_data.dart';
import 'package:pdf/widgets.dart' as pw;

class LaporanKeuanganPdf {
  static Future<Uint8List> build({
    required String periode,
    required LaporanKeuanganData keuangan,
    required LaporanTagihanData tagihan,
    String? filterKos,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageTheme: AppPdfTheme.pageTheme(),
        build: (context) => [
          AppPdfTheme.header('Laporan Keuangan', subtitle: periode),
          AppPdfTheme.section('Filter Laporan', [
            AppPdfTheme.infoRow('Periode laporan', periode),
            AppPdfTheme.infoRow(
              'Kos/property',
              PdfHelpers.text(filterKos, fallback: 'Semua kos'),
            ),
            AppPdfTheme.infoRow(
              'Tanggal cetak',
              PdfHelpers.tanggal(DateTime.now()),
            ),
          ]),
          AppPdfTheme.section('Ringkasan Keuangan', [
            AppPdfTheme.infoRow(
              'Uang bersih',
              PdfHelpers.rupiah(keuangan.totalUangBersih),
            ),
            AppPdfTheme.infoRow(
              'Pembayaran valid',
              PdfHelpers.rupiah(keuangan.totalUangMasuk),
            ),
            AppPdfTheme.infoRow(
              'Refund',
              PdfHelpers.rupiah(keuangan.refund.nominal),
            ),
            AppPdfTheme.infoRow(
              'Bayar untuk periode ini',
              PdfHelpers.rupiah(keuangan.totalBayarTagihanMasaPeriode),
            ),
            AppPdfTheme.infoRow(
              'Bayar di muka',
              PdfHelpers.rupiah(keuangan.totalBayarTagihanBulanDepan),
            ),
            AppPdfTheme.infoRow(
              'Total transaksi',
              '${keuangan.totalPembayaran} transaksi - ${PdfHelpers.rupiah(keuangan.totalNominalTransansaksi)}',
            ),
            AppPdfTheme.infoRow(
              'Total tagihan',
              '${tagihan.totalTagihan} tagihan - ${PdfHelpers.rupiah(tagihan.totalNominalPenuh)}',
            ),
            AppPdfTheme.infoRow(
              'Sisa tagihan/piutang',
              PdfHelpers.rupiah(keuangan.totalYangSisa),
            ),
          ]),
          AppPdfTheme.section('Breakdown Tagihan', [
            AppPdfTheme.table(
              headers: const ['Status', 'Jumlah', 'Nominal'],
              rows: [
                [
                  'Lunas',
                  '${tagihan.lunas.jumlah}',
                  PdfHelpers.rupiah(tagihan.lunas.nominal),
                ],
                [
                  'Sebagian',
                  '${tagihan.sebagian.jumlah}',
                  PdfHelpers.rupiah(tagihan.sebagian.nominal),
                ],
                [
                  'Belum bayar',
                  '${tagihan.belumBayar.jumlah}',
                  PdfHelpers.rupiah(tagihan.belumBayar.nominal),
                ],
                [
                  'Telat',
                  '${tagihan.telat.jumlah}',
                  PdfHelpers.rupiah(tagihan.telat.nominal),
                ],
              ],
            ),
          ]),
          AppPdfTheme.footer(),
        ],
      ),
    );

    return doc.save();
  }
}
