import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AppPdfTheme {
  static const primary = PdfColor.fromInt(0xFF2563EB);
  static const text = PdfColor.fromInt(0xFF111827);
  static const muted = PdfColor.fromInt(0xFF6B7280);
  static const border = PdfColor.fromInt(0xFFE5E7EB);
  static const soft = PdfColor.fromInt(0xFFF8FAFC);

  static pw.PageTheme pageTheme() {
    return pw.PageTheme(
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(),
    );
  }

  static pw.TextStyle get title =>
      pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: text);

  static pw.TextStyle get sectionTitle => pw.TextStyle(
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
    color: primary,
  );

  static pw.TextStyle get label =>
      const pw.TextStyle(fontSize: 9, color: muted);

  static pw.TextStyle get value =>
      pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: text);

  static pw.Widget header(String title, {String? subtitle}) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: border)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 36,
            height: 36,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: primary,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'MK',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: AppPdfTheme.title),
                if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    subtitle,
                    style: const pw.TextStyle(fontSize: 10, color: muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget section(String title, List<pw.Widget> children) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: soft,
        border: pw.Border.all(color: border),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: sectionTitle),
          pw.SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(flex: 4, child: pw.Text(label, style: AppPdfTheme.label)),
          pw.SizedBox(width: 8),
          pw.Expanded(flex: 6, child: pw.Text(value, style: AppPdfTheme.value)),
        ],
      ),
    );
  }

  static pw.Widget table({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    if (rows.isEmpty) {
      return pw.Text(
        'Tidak ada data.',
        style: const pw.TextStyle(fontSize: 10, color: muted),
      );
    }
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerDecoration: const pw.BoxDecoration(color: primary),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
      ),
      cellStyle: const pw.TextStyle(fontSize: 9, color: text),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      border: pw.TableBorder.all(color: border),
    );
  }

  static pw.Widget footer([String? text]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18),
      child: pw.Text(
        text ?? 'Dokumen ini dibuat otomatis melalui aplikasi Manajemen Kos.',
        style: const pw.TextStyle(fontSize: 8, color: muted),
      ),
    );
  }
}
