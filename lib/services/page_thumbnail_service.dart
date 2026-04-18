import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter/material.dart';

/// Renders PDF pages to PNG bytes using pdfrx (PDFium engine).
///
/// Implements an in-memory LRU cache (60 entries) to avoid re-rendering
/// the same page multiple times. All page-selector UIs share this single
/// service instance.
///
/// Architecture: Instantiated as a global singleton. Do NOT create per-page.
class PageThumbnailService {
  // ── Singleton ──────────────────────────────────────────
  static final PageThumbnailService _instance =
      PageThumbnailService._internal();
  factory PageThumbnailService() => _instance;
  PageThumbnailService._internal();

  // ── LRU Cache ──────────────────────────────────────────
  // Key format: "pdfPath::pageIndex::width"
  final Map<String, Uint8List> _cache = {};
  static const int _maxCacheEntries = 60; // ~12 pages × 5 PDFs

  /// Renders a single PDF page to PNG bytes.
  ///
  /// [pdfPath]   — Absolute file path to the PDF.
  /// [pageIndex] — Zero-based page index.
  /// [width]     — Output width in pixels (height auto-calculated).
  ///
  /// Returns `null` on failure — callers must show a placeholder.
  Future<Uint8List?> getThumbnail(
    String pdfPath,
    int pageIndex, {
    int width = 200,
  }) async {
    final cacheKey = '$pdfPath::$pageIndex::$width';

    // Cache hit → return immediately
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    PdfDocument? doc;
    try {
      doc = await PdfDocument.openFile(pdfPath);

      // Bounds check
      if (pageIndex < 0 || pageIndex >= doc.pages.length) return null;

      final page = doc.pages[pageIndex];
      final fullWidth = width.toDouble();
      final fullHeight = fullWidth * page.height / page.width;

      // Render page to raw pixel data via PDFium
      final PdfImage? pageImage = await page.render(
        fullWidth: fullWidth,
        fullHeight: fullHeight,
        backgroundColor: Colors.white,
      );
      if (pageImage == null) return null;

      // Convert raw pixels → ui.Image → PNG bytes
      final ui.Image image = await pageImage.createImage();
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      pageImage.dispose();

      if (byteData == null) return null;
      final Uint8List bytes = byteData.buffer.asUint8List();

      // Evict oldest entry if over limit (simple LRU)
      if (_cache.length >= _maxCacheEntries) {
        _cache.remove(_cache.keys.first);
      }
      _cache[cacheKey] = bytes;
      return bytes;
    } catch (_) {
      return null;
    } finally {
      await doc?.dispose();
    }
  }

  /// Returns total page count for a given PDF. Used by callers to
  /// provide `pageCount` to PageSelectorGrid without duplicating
  /// the document-open logic.
  Future<int> getPageCount(String pdfPath) async {
    PdfDocument? doc;
    try {
      doc = await PdfDocument.openFile(pdfPath);
      return doc.pages.length;
    } catch (_) {
      return 0;
    } finally {
      await doc?.dispose();
    }
  }

  /// Evict all cached thumbnails for a specific PDF file.
  /// Call after any modification (split, delete, rotate, reorder).
  void evictPdf(String pdfPath) {
    _cache.removeWhere((key, _) => key.startsWith('$pdfPath::'));
  }

  /// Flush entire cache. Called on memory pressure or app lifecycle.
  void clearAll() => _cache.clear();
}
