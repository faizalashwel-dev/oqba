import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_service.dart';

/// Conversion service: PDF ↔ Images, OCR text extraction.
///
/// - pdfToImages: renders PDF pages to JPEG/PNG via pdfrx (main thread with yields)
/// - pdfToImagesSelected: converts only specified page indices
/// - imagesToPdf: thin wrapper around PdfService.imagesToPdf
/// - extractTextFromImage: on-device OCR via ML Kit (no compute())
class ConvertService {
  /// Output directory for extracted images.
  static Future<String> _getExtractedDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/Oqba/extracted');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  // ═══════════════════════════════════════════════════════════
  // PDF → Images (All Pages)
  // ═══════════════════════════════════════════════════════════

  /// Renders every page of [pdfPath] to an image file.
  ///
  /// [format]     — 'jpg' (default) or 'png'.
  /// [qualityDpi] — Render resolution. 150 = fast, 300 = print-quality.
  /// [onProgress] — Called with (current, total) for UI progress updates.
  ///
  /// Returns list of output image paths in AppDocuments/Oqba/extracted/.
  Future<List<String>> pdfToImages(
    String pdfPath, {
    String format = 'jpg',
    int qualityDpi = 150,
    void Function(int current, int total)? onProgress,
  }) async {
    final outputDir = await _getExtractedDir();
    final baseName = _baseName(pdfPath);

    // pdfrx requires Flutter binding — run on main isolate
    // but yield between pages to keep UI responsive
    final doc = await pdfrx.PdfDocument.openFile(pdfPath);
    final List<String> outputs = [];

    try {
      for (int i = 0; i < doc.pages.length; i++) {
        onProgress?.call(i + 1, doc.pages.length);

        final page = doc.pages[i];
        final double scale = qualityDpi / 72.0;
        final double fullWidth = page.width * scale;
        final double fullHeight = page.height * scale;

        final pdfrx.PdfImage? pdfImage = await page.render(
          fullWidth: fullWidth,
          fullHeight: fullHeight,
          backgroundColor: Colors.white,
        );
        if (pdfImage == null) continue;

        final ui.Image image = await pdfImage.createImage();

        // Flutter's ui.Image only supports PNG encoding
        final ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        image.dispose();
        pdfImage.dispose();

        if (byteData == null) continue;

        final outPath = '$outputDir/${baseName}_page${i + 1}.png';
        File(outPath).writeAsBytesSync(byteData.buffer.asUint8List());
        outputs.add(outPath);

        // Yield to the event loop between pages to prevent UI freeze
        await Future<void>.delayed(Duration.zero);
      }
    } finally {
      await doc.dispose();
    }

    return outputs;
  }

  // ═══════════════════════════════════════════════════════════
  // PDF → Images (Selected Pages Only)
  // ═══════════════════════════════════════════════════════════

  /// Renders only selected pages to image files.
  ///
  /// [pageIndices] — Zero-based page indices to convert.
  /// [onProgress]  — Called with (current, total) for UI progress updates.
  Future<List<String>> pdfToImagesSelected(
    String pdfPath, {
    required List<int> pageIndices,
    String format = 'png',
    int qualityDpi = 150,
    void Function(int current, int total)? onProgress,
  }) async {
    final outputDir = await _getExtractedDir();
    final baseName = _baseName(pdfPath);
    final sorted = List<int>.from(pageIndices)..sort();

    final doc = await pdfrx.PdfDocument.openFile(pdfPath);
    final List<String> outputs = [];

    try {
      for (int idx = 0; idx < sorted.length; idx++) {
        final pageIndex = sorted[idx];
        onProgress?.call(idx + 1, sorted.length);

        if (pageIndex < 0 || pageIndex >= doc.pages.length) continue;

        final page = doc.pages[pageIndex];
        final double scale = qualityDpi / 72.0;
        final double fullWidth = page.width * scale;
        final double fullHeight = page.height * scale;

        final pdfrx.PdfImage? pdfImage = await page.render(
          fullWidth: fullWidth,
          fullHeight: fullHeight,
          backgroundColor: Colors.white,
        );
        if (pdfImage == null) continue;

        final ui.Image image = await pdfImage.createImage();

        final ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        image.dispose();
        pdfImage.dispose();

        if (byteData == null) continue;

        final outPath = '$outputDir/${baseName}_page${pageIndex + 1}.png';
        File(outPath).writeAsBytesSync(byteData.buffer.asUint8List());
        outputs.add(outPath);

        await Future<void>.delayed(Duration.zero);
      }
    } finally {
      await doc.dispose();
    }

    return outputs;
  }

  // ═══════════════════════════════════════════════════════════
  // Images → PDF
  // ═══════════════════════════════════════════════════════════

  /// Converts a list of images to a single PDF.
  ///
  /// Thin wrapper around [PdfService.imagesToPdf] with input validation.
  /// Only accepts .jpg, .jpeg, .png files.
  Future<PdfProcessingResult> imagesToPdf(
    List<String> imagePaths, {
    required String outputName,
  }) async {
    // Validate formats
    final validExtensions = {'.jpg', '.jpeg', '.png'};
    for (final path in imagePaths) {
      final ext = path.toLowerCase().split('.').last;
      if (!validExtensions.contains('.$ext')) {
        throw ArgumentError('Unsupported image format: $path. Only JPG/PNG allowed.');
      }
    }

    // Sort by filename for predictable page order
    final sorted = List<String>.from(imagePaths)..sort();

    return PdfService().imagesToPdf(sorted, outputName);
  }

  // ═══════════════════════════════════════════════════════════
  // OCR — Image → Text (ML Kit, on-device)
  // ═══════════════════════════════════════════════════════════

  /// Extracts text from an image using Google ML Kit on-device OCR.
  ///
  /// ML Kit manages its own threading — do NOT wrap in compute().
  /// Returns empty string if no text is found.
  Future<String> extractTextFromImage(
    String imagePath, {
    TextRecognitionScript script = TextRecognitionScript.latin,
  }) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: script);

    try {
      final RecognizedText result = await recognizer.processImage(inputImage);
      return result.text;
    } catch (_) {
      return '';
    } finally {
      await recognizer.close();
    }
  }

  /// Extract basename without extension from a file path.
  static String _baseName(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final dotIndex = name.lastIndexOf('.');
    return dotIndex > 0 ? name.substring(0, dotIndex) : name;
  }
}
