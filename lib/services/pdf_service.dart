import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

/// Result wrapper that carries output path + elapsed time in ms.
class PdfProcessingResult {
  final String outputPath;
  final int elapsedMs;
  final int fileSizeBytes;

  PdfProcessingResult({
    required this.outputPath,
    required this.elapsedMs,
    required this.fileSizeBytes,
  });

  String get formattedSize => _formatSize(fileSizeBytes);

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class PdfService {
  Future<String> _getOqbaDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final docDir = Directory('${appDir.path}/Oqba/documents');
    if (!await docDir.exists()) {
      await docDir.create(recursive: true);
    }
    return docDir.path;
  }

  /// Convert list of image paths into a single PDF.
  /// Runs in Isolate via compute() to keep UI at 60fps.
  /// Returns [PdfProcessingResult] with path, elapsed ms, and file size.
  Future<PdfProcessingResult> imagesToPdf(
    List<String> imagePaths,
    String outputName,
  ) async {
    final outputDir = await _getOqbaDir();
    final stopwatch = Stopwatch()..start();

    final outputPath = await compute(_imagesToPdfIsolate, {
      'imagePaths': imagePaths,
      'outputDir': outputDir,
      'outputName': outputName,
    });

    stopwatch.stop();
    final file = File(outputPath);

    return PdfProcessingResult(
      outputPath: outputPath,
      elapsedMs: stopwatch.elapsedMilliseconds,
      fileSizeBytes: file.existsSync() ? file.lengthSync() : 0,
    );
  }

  static String _imagesToPdfIsolate(Map<String, dynamic> params) {
    final List<String> imagePaths = List<String>.from(params['imagePaths']);
    final String outputDir = params['outputDir'];
    final String outputName = params['outputName'];

    final outputDoc = PdfDocument();

    for (final path in imagePaths) {
      final File imageFile = File(path);
      if (!imageFile.existsSync()) continue;

      final Uint8List imageBytes = imageFile.readAsBytesSync();
      final PdfBitmap image = PdfBitmap(imageBytes);

      // Scale to A4-ish width (595pt) maintaining aspect ratio.
      const double pageWidth = 595;
      final double aspectRatio = image.height / image.width;
      final double pageHeight = pageWidth * aspectRatio;

      // Create a section with the exact page size for this image
      final PdfSection section = outputDoc.sections!.add();
      section.pageSettings.size = Size(pageWidth, pageHeight);
      section.pageSettings.margins.all = 0;
      final PdfPage page = section.pages.add();

      page.graphics.drawImage(
        image,
        Rect.fromLTWH(0, 0, pageWidth, pageHeight),
      );
    }

    final outputPath = '$outputDir/$outputName.pdf';
    File(outputPath).writeAsBytesSync(outputDoc.saveSync());
    outputDoc.dispose();

    return outputPath;
  }

  /// Merge multiple existing PDFs into one.
  /// Uses Syncfusion's PdfDocument.load() to read existing PDFs.
  /// Processes page-by-page to prevent OOM.
  /// Returns [PdfProcessingResult] with path, elapsed ms, and file size.
  Future<PdfProcessingResult> mergePdfs(
    List<String> pdfPaths,
    String outputName,
  ) async {
    final outputDir = await _getOqbaDir();
    final stopwatch = Stopwatch()..start();

    final outputPath = await compute(_mergePdfsIsolate, {
      'pdfPaths': pdfPaths,
      'outputDir': outputDir,
      'outputName': outputName,
    });

    stopwatch.stop();
    final file = File(outputPath);

    return PdfProcessingResult(
      outputPath: outputPath,
      elapsedMs: stopwatch.elapsedMilliseconds,
      fileSizeBytes: file.existsSync() ? file.lengthSync() : 0,
    );
  }

  static String _mergePdfsIsolate(Map<String, dynamic> params) {
    final List<String> pdfPaths = List<String>.from(params['pdfPaths']);
    final String outputDir = params['outputDir'];
    final String outputName = params['outputName'];

    final outputDoc = PdfDocument();
    // Remove default blank page
    if (outputDoc.pages.count > 0) {
      outputDoc.pages.removeAt(0);
    }

    for (final path in pdfPaths) {
      final file = File(path);
      if (!file.existsSync()) continue;

      final Uint8List bytes = file.readAsBytesSync();

      try {
        final PdfDocument sourceDoc = PdfDocument(inputBytes: bytes);

        // Copy pages one-by-one, preserving source page dimensions
        for (int i = 0; i < sourceDoc.pages.count; i++) {
          final PdfPage sourcePage = sourceDoc.pages[i];
          final Size sourceSize = sourcePage.getClientSize();

          // Create a new section with matching page size
          final PdfSection section = outputDoc.sections!.add();
          section.pageSettings.size = sourceSize;
          section.pageSettings.margins.all = 0;

          final PdfPage destPage = section.pages.add();
          final PdfTemplate template = sourcePage.createTemplate();
          destPage.graphics.drawPdfTemplate(template, Offset.zero);
        }

        sourceDoc.dispose(); // Release memory immediately
      } catch (e) {
        // Skip corrupted/invalid PDFs and continue with the rest
        continue;
      }
    }

    final outputPath = '$outputDir/$outputName.pdf';
    File(outputPath).writeAsBytesSync(outputDoc.saveSync());
    outputDoc.dispose();

    return outputPath;
  }
}
