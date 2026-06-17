import 'dart:typed_data';

import 'package:kos_management/features/export_pdf/pdf_helpers.dart';
import 'package:kos_management/features/export_pdf/pdf_theme.dart';
import 'package:pdf/widgets.dart' as pw;

class TagihanPdf {
  static Future<Uint8List> build({
    required Map<String, dynamic> tagihan,
    Map<String, dynamic>? penyewa,
    List<Map<String, dynamic>> pembayaran = const [],
    String? lokasi,
  }) async {
    final doc = pw.Document();
    final total = PdfHelpers.angka(tagihan['total_tagihan']);
    final dibayar = PdfHelpers.angka(tagihan['total_dibayar']);
    final items = PdfHelpers.listMap(tagihan['items']);

    doc.addPage(
      pw.MultiPage(
        pageTheme: AppPdfTheme.pageTheme(),
        build: (context) => [
          AppPdfTheme.header(
            'Invoice Tagihan',
            subtitle: PdfHelpers.text(tagihan['kode_tagihan']),
          ),
          AppPdfTheme.section('Informasi Tagihan', [
            AppPdfTheme.infoRow(
              'Kode tagihan',
              PdfHelpers.text(tagihan['kode_tagihan']),
            ),
            AppPdfTheme.infoRow(
              'Nama penyewa',
              PdfHelpers.text(penyewa?['nama']),
            ),
            AppPdfTheme.infoRow('Kos dan kamar', PdfHelpers.text(lokasi)),
            AppPdfTheme.infoRow(
              'Periode tagihan',
              PdfHelpers.periode(
                tagihan['periode_awal'],
                tagihan['periode_akhir'],
              ),
            ),
            AppPdfTheme.infoRow(
              'Jatuh tempo',
              PdfHelpers.tanggal(tagihan['jatuh_tempo']),
            ),
            AppPdfTheme.infoRow(
              'Status pembayaran',
              PdfHelpers.status(tagihan['status_pembayaran']),
            ),
          ]),
          AppPdfTheme.section('Daftar Item Tagihan', [
            AppPdfTheme.table(
              headers: const ['Item', 'Nominal'],
              rows: items
                  .map(
                    (item) => [
                      PdfHelpers.text(
                        item['nama'] ?? item['nama_item'] ?? item['label'],
                      ),
                      PdfHelpers.rupiah(item['nominal'] ?? item['jumlah']),
                    ],
                  )
                  .toList(),
            ),
          ]),
          AppPdfTheme.section('Ringkasan Pembayaran', [
            AppPdfTheme.infoRow('Total tagihan', PdfHelpers.rupiah(total)),
            AppPdfTheme.infoRow('Total dibayar', PdfHelpers.rupiah(dibayar)),
            AppPdfTheme.infoRow(
              'Sisa bayar',
              PdfHelpers.rupiah(total - dibayar),
            ),
            AppPdfTheme.infoRow(
              'Tanggal cetak',
              PdfHelpers.tanggal(DateTime.now()),
            ),
          ]),
          AppPdfTheme.section('Riwayat Pembayaran', [
            AppPdfTheme.table(
              headers: const ['Tanggal', 'Nominal', 'Status'],
              rows: pembayaran
                  .map(
                    (item) => [
                      PdfHelpers.tanggal(item['dibuat_pada']),
                      PdfHelpers.rupiah(item['jumlah_bayar']),
                      PdfHelpers.status(item['status']),
                    ],
                  )
                  .toList(),
            ),
          ]),
          AppPdfTheme.footer(),
        ],
      ),
    );

    return doc.save();
  }
}
