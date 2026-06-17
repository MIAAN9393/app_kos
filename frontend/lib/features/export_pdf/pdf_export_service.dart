import 'dart:typed_data';

import 'package:printing/printing.dart';

typedef PdfBytesBuilder = Future<Uint8List> Function();

class PdfExportService {
  static Future<void> previewPdf({
    required String fileName,
    required PdfBytesBuilder build,
  }) {
    return Printing.layoutPdf(name: fileName, onLayout: (_) => build());
  }

  static Future<void> sharePdf({
    required String fileName,
    required PdfBytesBuilder build,
  }) async {
    final bytes = await build();
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}
