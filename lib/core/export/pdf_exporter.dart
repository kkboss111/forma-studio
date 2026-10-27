import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/models/project_model.dart';
import 'png_exporter.dart';

class PdfExporter {
  PdfExporter._();

  static Future<Uint8List> exportToPdf({
    required ProjectModel project,
    required String pageId,
    String? frameId,
  }) async {
    final pdf = pw.Document();

    // Render frame/page to high-res image
    final imageBytes = await PngExporter.exportToPng(
      project: project,
      pageId: pageId,
      frameId: frameId,
      scale: 2.0,
      transparentBg: false,
    );

    if (imageBytes != null) {
      final image = pw.MemoryImage(imageBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
          },
        ),
      );
    }

    return pdf.save();
  }
}
