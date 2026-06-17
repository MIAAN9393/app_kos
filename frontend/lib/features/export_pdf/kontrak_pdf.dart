import 'dart:typed_data';

import 'package:kos_management/features/export_pdf/pdf_helpers.dart';
import 'package:kos_management/features/export_pdf/pdf_theme.dart';
import 'package:pdf/widgets.dart' as pw;

class KontrakPdf {
  static Future<Uint8List> build({
    required Map<String, dynamic> kontrak,
    Map<String, dynamic>? penyewa,
    String? namaKos,
    String? nomorKamar,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageTheme: AppPdfTheme.pageTheme(),
        build: (context) => [
          AppPdfTheme.header(
            'Detail Kontrak',
            subtitle: PdfHelpers.text(kontrak['kode_kontrak']),
          ),
          AppPdfTheme.section('Informasi Kontrak', [
            AppPdfTheme.infoRow(
              'Kode kontrak',
              PdfHelpers.text(
                kontrak['kode_kontrak'],
                fallback: 'Kontrak #${kontrak['id']}',
              ),
            ),
            AppPdfTheme.infoRow(
              'Nama penyewa',
              PdfHelpers.text(penyewa?['nama']),
            ),
            AppPdfTheme.infoRow(
              'Nomor HP penyewa',
              PdfHelpers.text(
                penyewa?['no_hp'] ??
                    penyewa?['nomor_hp'] ??
                    penyewa?['telepon'],
              ),
            ),
            AppPdfTheme.infoRow('Nama kos', PdfHelpers.text(namaKos)),
            AppPdfTheme.infoRow('Nomor kamar', PdfHelpers.text(nomorKamar)),
            AppPdfTheme.infoRow(
              'Tanggal mulai',
              PdfHelpers.tanggal(kontrak['tanggal_mulai']),
            ),
            AppPdfTheme.infoRow(
              'Tanggal selesai',
              PdfHelpers.tanggal(kontrak['tanggal_selesai']),
            ),
            AppPdfTheme.infoRow(
              'Durasi/siklus sewa',
              PdfHelpers.status(kontrak['siklus']),
            ),
            AppPdfTheme.infoRow(
              'Harga sewa',
              PdfHelpers.rupiah(kontrak['harga_sewa']),
            ),
            AppPdfTheme.infoRow(
              'Status kontrak',
              PdfHelpers.status(kontrak['status']),
            ),
            AppPdfTheme.infoRow(
              'Tanggal dibuat',
              PdfHelpers.tanggal(
                kontrak['dibuat_pada'] ?? kontrak['createdAt'],
              ),
            ),
            if (PdfHelpers.text(kontrak['catatan'], fallback: '').isNotEmpty)
              AppPdfTheme.infoRow(
                'Catatan',
                PdfHelpers.text(kontrak['catatan']),
              ),
          ]),
          AppPdfTheme.footer(),
        ],
      ),
    );

    return doc.save();
  }
}
