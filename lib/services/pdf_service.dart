import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Combines captured images into a single PDF file — used for single-photo
/// steps where the user may take several shots that must upload as one file.
class PdfService {
  const PdfService();

  /// Builds a PDF with one image per page (fit to the page, preserving aspect
  /// ratio) and writes it to a temp file named after [baseName]. Returns the
  /// saved [File]. Throws if [images] is empty.
  Future<File> imagesToPdf(List<File> images, {required String baseName}) async {
    if (images.isEmpty) {
      throw ArgumentError('imagesToPdf requires at least one image');
    }
    final doc = pw.Document();
    for (final file in images) {
      final bytes = await file.readAsBytes();
      final image = pw.MemoryImage(bytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (context) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }
    final dir = await getTemporaryDirectory();
    final safeName = baseName.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final out = File('${dir.path}/$safeName-${DateTime.now().millisecondsSinceEpoch}.pdf');
    await out.writeAsBytes(await doc.save(), flush: true);
    return out;
  }
}
