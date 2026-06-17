import 'dart:typed_data';

import 'package:kos_management/features/export_pdf/pdf_helpers.dart';
import 'package:kos_management/features/export_pdf/pdf_theme.dart';
import 'package:pdf/widgets.dart' as pw;

class LaporanPropertyPdf {
  static Future<Uint8List> build({
    required Map<String, dynamic> kos,
    required List<Map<String, dynamic>> statistik,
    int totalKamar = 0,
    int kamarTerisi = 0,
    int kamarKosong = 0,
  }) async {
    final doc = pw.Document();

    String stat(String label) {
      for (final item in statistik) {
        final itemLabel = PdfHelpers.text(
          item['label'] ?? item['nama'],
          fallback: '',
        ).toLowerCase();
        if (itemLabel == label.toLowerCase()) {
          return PdfHelpers.text(item['value'] ?? item['jumlah']);
        }
      }
      return '-';
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: AppPdfTheme.pageTheme(),
        build: (context) => [
          AppPdfTheme.header(
            'Laporan Property',
            subtitle: PdfHelpers.text(kos['nama_kos']),
          ),
          AppPdfTheme.section('Informasi Property', [
            AppPdfTheme.infoRow(
              'Nama kos/property',
              PdfHelpers.text(kos['nama_kos']),
            ),
            AppPdfTheme.infoRow(
              'Alamat/deskripsi',
              PdfHelpers.text(kos['alamat'] ?? kos['deskripsi']),
            ),
            if (PdfHelpers.text(kos['deskripsi'], fallback: '').isNotEmpty)
              AppPdfTheme.infoRow(
                'Deskripsi',
                PdfHelpers.text(kos['deskripsi']),
              ),
            AppPdfTheme.infoRow(
              'Tanggal cetak',
              PdfHelpers.tanggal(DateTime.now()),
            ),
          ]),
          AppPdfTheme.section('Ringkasan Occupancy', [
            AppPdfTheme.infoRow('Total kamar', '$totalKamar'),
            AppPdfTheme.infoRow('Kamar terisi', '$kamarTerisi'),
            AppPdfTheme.infoRow('Kamar kosong', '$kamarKosong'),
            AppPdfTheme.infoRow('Penyewa aktif', stat('Penyewa Aktif')),
            AppPdfTheme.infoRow('Kontrak aktif', stat('Kontrak Aktif')),
          ]),
          AppPdfTheme.section('Ringkasan Keuangan Property', [
            AppPdfTheme.infoRow(
              'Tagihan belum lunas',
              stat('Tagihan Belum Lunas'),
            ),
            AppPdfTheme.infoRow('Total tagihan', stat('Total Tagihan')),
            AppPdfTheme.infoRow('Total terbayar', stat('Total Terbayar')),
            AppPdfTheme.infoRow('Sisa piutang', stat('Sisa Piutang')),
          ]),
          AppPdfTheme.section('Ringkasan Kamar per Status', [
            AppPdfTheme.table(
              headers: const ['Status', 'Jumlah'],
              rows: [
                ['Terisi', '$kamarTerisi'],
                ['Kosong', '$kamarKosong'],
              ],
            ),
          ]),
          AppPdfTheme.section('Data Statistik Backend', [
            AppPdfTheme.table(
              headers: const ['Label', 'Nilai'],
              rows: statistik
                  .map(
                    (item) => [
                      PdfHelpers.text(item['label'] ?? item['nama'] ?? 'Item'),
                      PdfHelpers.text(item['value'] ?? item['jumlah'] ?? item),
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
