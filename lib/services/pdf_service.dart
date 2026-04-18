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

  // ═══════════════════════════════════════════════════════════
  // ORGANIZE — Split PDF
  // ═══════════════════════════════════════════════════════════

  /// Splits a PDF into multiple files by page ranges.
  ///
  /// [pdfPath]    — Source PDF path (internal app directory).
  /// [ranges]     — List of page ranges, e.g. [[0,2],[3,5]].
  ///                0-based, inclusive on both ends.
  /// [outputName] — Base name for output files.
  ///
  /// Returns [PdfProcessingResult] for the first output (callers
  /// get the full list of paths from the isolate result).
  Future<PdfProcessingResult> splitPdf(
    String pdfPath,
    List<List<int>> ranges,
    String outputName,
  ) async {
    final outputDir = await _getOqbaDir();
    final stopwatch = Stopwatch()..start();

    final outputPaths = await compute(_splitPdfIsolate, {
      'pdfPath': pdfPath,
      'ranges': ranges,
      'outputDir': outputDir,
      'outputName': outputName,
    });

    stopwatch.stop();
    final firstFile = File(outputPaths.first);

    return PdfProcessingResult(
      outputPath: outputPaths.first,
      elapsedMs: stopwatch.elapsedMilliseconds,
      fileSizeBytes: firstFile.existsSync() ? firstFile.lengthSync() : 0,
    );
  }

  /// Returns all output paths from splitPdf. Use when you need
  /// every generated file, not just the first.
  Future<List<String>> splitPdfPaths(
    String pdfPath,
    List<List<int>> ranges,
    String outputName,
  ) async {
    final outputDir = await _getOqbaDir();
    return compute(_splitPdfIsolate, {
      'pdfPath': pdfPath,
      'ranges': ranges,
      'outputDir': outputDir,
      'outputName': outputName,
    });
  }

  static List<String> _splitPdfIsolate(Map<String, dynamic> params) {
    final String pdfPath = params['pdfPath'];
    final List<List<int>> ranges = (params['ranges'] as List)
        .map((r) => List<int>.from(r as List))
        .toList();
    final String outputDir = params['outputDir'];
    final String outputName = params['outputName'];
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    final Uint8List sourceBytes = File(pdfPath).readAsBytesSync();
    final PdfDocument sourceDoc = PdfDocument(inputBytes: sourceBytes);
    final List<String> outputs = [];

    for (final range in ranges) {
      final int startPage = range[0];
      final int endPage = range[1]; // inclusive

      final PdfDocument outDoc = PdfDocument();
      // Remove default blank page
      if (outDoc.pages.count > 0) {
        outDoc.pages.removeAt(0);
      }

      for (int i = startPage; i <= endPage && i < sourceDoc.pages.count; i++) {
        final PdfPage sourcePage = sourceDoc.pages[i];
        final Size sourceSize = sourcePage.getClientSize();

        final PdfSection section = outDoc.sections!.add();
        section.pageSettings.size = sourceSize;
        section.pageSettings.margins.all = 0;

        final PdfPage destPage = section.pages.add();
        final PdfTemplate template = sourcePage.createTemplate();
        destPage.graphics.drawPdfTemplate(template, Offset.zero);
      }

      final outPath =
          '$outputDir/${outputName}_p${startPage + 1}-p${endPage + 1}_$timestamp.pdf';
      File(outPath).writeAsBytesSync(outDoc.saveSync());
      outDoc.dispose();
      outputs.add(outPath);
    }

    sourceDoc.dispose();
    return outputs;
  }

  // ═══════════════════════════════════════════════════════════
  // ORGANIZE — Extract Pages
  // ═══════════════════════════════════════════════════════════

  /// Extracts a non-contiguous list of pages into a new PDF.
  ///
  /// [selectedIndices] — Zero-based page indices to keep (any order,
  ///                      auto-sorted ascending before processing).
  Future<PdfProcessingResult> extractPages(
    String pdfPath,
    List<int> selectedIndices,
    String outputName,
  ) async {
    final outputDir = await _getOqbaDir();
    final stopwatch = Stopwatch()..start();

    final outputPath = await compute(_extractPagesIsolate, {
      'pdfPath': pdfPath,
      'selectedIndices': selectedIndices..sort(),
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

  static String _extractPagesIsolate(Map<String, dynamic> params) {
    final String pdfPath = params['pdfPath'];
    final List<int> selectedIndices = List<int>.from(params['selectedIndices']);
    final String outputDir = params['outputDir'];
    final String outputName = params['outputName'];
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    final Uint8List sourceBytes = File(pdfPath).readAsBytesSync();
    final PdfDocument sourceDoc = PdfDocument(inputBytes: sourceBytes);

    final PdfDocument outDoc = PdfDocument();
    if (outDoc.pages.count > 0) {
      outDoc.pages.removeAt(0);
    }

    for (final idx in selectedIndices) {
      if (idx < 0 || idx >= sourceDoc.pages.count) continue;

      final PdfPage sourcePage = sourceDoc.pages[idx];
      final Size sourceSize = sourcePage.getClientSize();

      final PdfSection section = outDoc.sections!.add();
      section.pageSettings.size = sourceSize;
      section.pageSettings.margins.all = 0;

      final PdfPage destPage = section.pages.add();
      final PdfTemplate template = sourcePage.createTemplate();
      destPage.graphics.drawPdfTemplate(template, Offset.zero);
    }

    final outPath =
        '$outputDir/${outputName}_extracted_$timestamp.pdf';
    File(outPath).writeAsBytesSync(outDoc.saveSync());
    outDoc.dispose();
    sourceDoc.dispose();

    return outPath;
  }

  // ═══════════════════════════════════════════════════════════
  // ORGANIZE — Delete Pages
  // ═══════════════════════════════════════════════════════════

  /// Creates a new PDF with the specified pages REMOVED.
  ///
  /// Strategy: iterate ALL pages, copy to output only if index
  /// is NOT in the deleteSet.
  ///
  /// Guard: if deleteIndices.length >= totalPages → throws
  /// ArgumentError. The UI layer must also prevent this.
  Future<PdfProcessingResult> deletePages(
    String pdfPath,
    List<int> deleteIndices,
    String outputName,
  ) async {
    final outputDir = await _getOqbaDir();
    final stopwatch = Stopwatch()..start();

    final outputPath = await compute(_deletePagesIsolate, {
      'pdfPath': pdfPath,
      'deleteIndices': deleteIndices,
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

  static String _deletePagesIsolate(Map<String, dynamic> params) {
    final String pdfPath = params['pdfPath'];
    final Set<int> deleteSet = Set<int>.from(params['deleteIndices'] as List);
    final String outputDir = params['outputDir'];
    final String outputName = params['outputName'];
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    final Uint8List sourceBytes = File(pdfPath).readAsBytesSync();
    final PdfDocument sourceDoc = PdfDocument(inputBytes: sourceBytes);

    // Guard: cannot delete ALL pages
    if (deleteSet.length >= sourceDoc.pages.count) {
      sourceDoc.dispose();
      throw ArgumentError(
        'Cannot delete all ${sourceDoc.pages.count} pages. '
        'At least one page must remain.',
      );
    }

    final PdfDocument outDoc = PdfDocument();
    if (outDoc.pages.count > 0) {
      outDoc.pages.removeAt(0);
    }

    for (int i = 0; i < sourceDoc.pages.count; i++) {
      if (deleteSet.contains(i)) continue; // skip deleted pages

      final PdfPage sourcePage = sourceDoc.pages[i];
      final Size sourceSize = sourcePage.getClientSize();

      final PdfSection section = outDoc.sections!.add();
      section.pageSettings.size = sourceSize;
      section.pageSettings.margins.all = 0;

      final PdfPage destPage = section.pages.add();
      final PdfTemplate template = sourcePage.createTemplate();
      destPage.graphics.drawPdfTemplate(template, Offset.zero);
    }

    final outPath =
        '$outputDir/${outputName}_edited_$timestamp.pdf';
    File(outPath).writeAsBytesSync(outDoc.saveSync());
    outDoc.dispose();
    sourceDoc.dispose();

    return outPath;
  }

  // ═══════════════════════════════════════════════════════════
  // ORGANIZE — Rotate Pages
  // ═══════════════════════════════════════════════════════════

  /// Rotates specified pages and saves as a new PDF.
  ///
  /// [rotations] — Map of pageIndex → degrees (90, 180, or 270).
  /// Pages not in the map are copied without rotation.
  Future<PdfProcessingResult> rotatePages(
    String pdfPath,
    Map<int, int> rotations,
    String outputName,
  ) async {
    final outputDir = await _getOqbaDir();
    final stopwatch = Stopwatch()..start();

    // Convert Map<int, int> to a List for isolate serialisation
    final rotationEntries = rotations.entries
        .map((e) => [e.key, e.value])
        .toList();

    final outputPath = await compute(_rotatePagesIsolate, {
      'pdfPath': pdfPath,
      'rotations': rotationEntries,
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

  static String _rotatePagesIsolate(Map<String, dynamic> params) {
    final String pdfPath = params['pdfPath'];
    final Map<int, int> rotationMap = {
      for (final entry in params['rotations'] as List)
        (entry as List)[0] as int: entry[1] as int
    };
    final String outputDir = params['outputDir'];
    final String outputName = params['outputName'];
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    final Uint8List sourceBytes = File(pdfPath).readAsBytesSync();
    final PdfDocument sourceDoc = PdfDocument(inputBytes: sourceBytes);

    final PdfDocument outDoc = PdfDocument();
    if (outDoc.pages.count > 0) {
      outDoc.pages.removeAt(0);
    }

    for (int i = 0; i < sourceDoc.pages.count; i++) {
      final PdfPage sourcePage = sourceDoc.pages[i];
      final Size sourceSize = sourcePage.getClientSize();
      final int degrees = rotationMap[i] ?? 0;

      // Determine rotation angle
      final PdfPageRotateAngle angle = switch (degrees) {
        90 => PdfPageRotateAngle.rotateAngle90,
        180 => PdfPageRotateAngle.rotateAngle180,
        270 => PdfPageRotateAngle.rotateAngle270,
        _ => PdfPageRotateAngle.rotateAngle0,
      };

      // Create section with original page size
      final PdfSection section = outDoc.sections!.add();
      section.pageSettings.size = sourceSize;
      section.pageSettings.margins.all = 0;
      section.pageSettings.rotate = angle;

      final PdfPage destPage = section.pages.add();
      final PdfTemplate template = sourcePage.createTemplate();
      destPage.graphics.drawPdfTemplate(template, Offset.zero);
    }

    final outPath =
        '$outputDir/${outputName}_rotated_$timestamp.pdf';
    File(outPath).writeAsBytesSync(outDoc.saveSync());
    outDoc.dispose();
    sourceDoc.dispose();

    return outPath;
  }

  // ═══════════════════════════════════════════════════════════
  // ORGANIZE — Reorder Pages
  // ═══════════════════════════════════════════════════════════

  /// Creates a new PDF with pages in the specified order.
  ///
  /// [newOrder] — List of original 0-based page indices in desired
  ///              output order. e.g. [2,0,1] = page3 first, page1, page2.
  Future<PdfProcessingResult> reorderPages(
    String pdfPath,
    List<int> newOrder,
    String outputName,
  ) async {
    final outputDir = await _getOqbaDir();
    final stopwatch = Stopwatch()..start();

    final outputPath = await compute(_reorderPagesIsolate, {
      'pdfPath': pdfPath,
      'newOrder': newOrder,
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

  static String _reorderPagesIsolate(Map<String, dynamic> params) {
    final String pdfPath = params['pdfPath'];
    final List<int> newOrder = List<int>.from(params['newOrder']);
    final String outputDir = params['outputDir'];
    final String outputName = params['outputName'];
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    final Uint8List sourceBytes = File(pdfPath).readAsBytesSync();
    final PdfDocument sourceDoc = PdfDocument(inputBytes: sourceBytes);

    final PdfDocument outDoc = PdfDocument();
    if (outDoc.pages.count > 0) {
      outDoc.pages.removeAt(0);
    }

    for (final originalIndex in newOrder) {
      if (originalIndex < 0 || originalIndex >= sourceDoc.pages.count) continue;

      final PdfPage sourcePage = sourceDoc.pages[originalIndex];
      final Size sourceSize = sourcePage.getClientSize();

      final PdfSection section = outDoc.sections!.add();
      section.pageSettings.size = sourceSize;
      section.pageSettings.margins.all = 0;

      final PdfPage destPage = section.pages.add();
      final PdfTemplate template = sourcePage.createTemplate();
      destPage.graphics.drawPdfTemplate(template, Offset.zero);
    }

    final outPath =
        '$outputDir/${outputName}_reordered_$timestamp.pdf';
    File(outPath).writeAsBytesSync(outDoc.saveSync());
    outDoc.dispose();
    sourceDoc.dispose();

    return outPath;
  }
}
