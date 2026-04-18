import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

/// PDF Security Service — Full Implementation.
///
/// Provides:
///   - Password protect (AES-256)
///   - Remove password
///   - Add text watermark
///   - Check if password-protected
///   - Sign PDF (stamp signature image)
///
/// All heavy operations run in compute() isolates.
class SecurityService {
  /// Output directory for security-processed PDFs.
  static Future<String> _getDocumentsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/Oqba/documents');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  // ═══════════════════════════════════════════════════════════
  // Password Protect (AES-256)
  // ═══════════════════════════════════════════════════════════

  /// Adds AES-256 password protection to a PDF.
  ///
  /// [pdfPath]       — Source PDF file path.
  /// [userPassword]  — Password required to open the document.
  /// [ownerPassword] — Password for full access (optional, defaults to userPassword).
  /// Returns: Path to the protected PDF.
  Future<String> passwordProtect(
    String pdfPath, {
    required String userPassword,
    String? ownerPassword,
  }) async {
    final outputDir = await _getDocumentsDir();
    return compute(_passwordProtectIsolate, {
      'pdfPath': pdfPath,
      'userPassword': userPassword,
      'ownerPassword': ownerPassword ?? userPassword,
      'outputDir': outputDir,
    });
  }

  static String _passwordProtectIsolate(Map<String, dynamic> params) {
    final String pdfPath = params['pdfPath'];
    final String userPassword = params['userPassword'];
    final String ownerPassword = params['ownerPassword'];
    final String outputDir = params['outputDir'];
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    final Uint8List sourceBytes = File(pdfPath).readAsBytesSync();
    final PdfDocument doc = PdfDocument(inputBytes: sourceBytes);

    // Set AES-256 encryption
    doc.security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
    doc.security.userPassword = userPassword;
    doc.security.ownerPassword = ownerPassword;

    // Set permissions — restrict everything except viewing
    doc.security.permissions.addAll([
      PdfPermissionsFlags.none,
    ]);

    final baseName = _baseName(pdfPath);
    final outPath = '$outputDir/${baseName}_protected_$timestamp.pdf';
    File(outPath).writeAsBytesSync(doc.saveSync());
    doc.dispose();

    return outPath;
  }

  // ═══════════════════════════════════════════════════════════
  // Remove Password
  // ═══════════════════════════════════════════════════════════

  /// Removes password from a protected PDF.
  ///
  /// [pdfPath]  — Source PDF file path.
  /// [password] — Current password to unlock.
  /// Returns: Path to the unprotected PDF.
  /// Throws if password is wrong.
  Future<String> removePassword(
    String pdfPath, {
    required String password,
  }) async {
    final outputDir = await _getDocumentsDir();
    return compute(_removePasswordIsolate, {
      'pdfPath': pdfPath,
      'password': password,
      'outputDir': outputDir,
    });
  }

  static String _removePasswordIsolate(Map<String, dynamic> params) {
    final String pdfPath = params['pdfPath'];
    final String password = params['password'];
    final String outputDir = params['outputDir'];
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    final Uint8List sourceBytes = File(pdfPath).readAsBytesSync();

    // Open with password
    final PdfDocument doc = PdfDocument(
      inputBytes: sourceBytes,
      password: password,
    );

    // Clear security
    doc.security.userPassword = '';
    doc.security.ownerPassword = '';

    final baseName = _baseName(pdfPath);
    final outPath = '$outputDir/${baseName}_unlocked_$timestamp.pdf';
    File(outPath).writeAsBytesSync(doc.saveSync());
    doc.dispose();

    return outPath;
  }

  // ═══════════════════════════════════════════════════════════
  // Add Watermark
  // ═══════════════════════════════════════════════════════════

  /// Adds a text watermark to every page.
  ///
  /// [pdfPath]  — Source PDF file path.
  /// [text]     — Watermark text (e.g., "CONFIDENTIAL").
  /// [opacity]  — Watermark opacity (0.0–1.0).
  /// [rotation] — Rotation angle in degrees.
  /// Returns: Path to the watermarked PDF.
  Future<String> addWatermark(
    String pdfPath, {
    required String text,
    double opacity = 0.3,
    double rotation = -45,
  }) async {
    final outputDir = await _getDocumentsDir();
    return compute(_addWatermarkIsolate, {
      'pdfPath': pdfPath,
      'text': text,
      'opacity': opacity,
      'rotation': rotation,
      'outputDir': outputDir,
    });
  }

  static String _addWatermarkIsolate(Map<String, dynamic> params) {
    final String pdfPath = params['pdfPath'];
    final String text = params['text'];
    final double opacity = params['opacity'];
    final double rotation = params['rotation'];
    final String outputDir = params['outputDir'];
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    final Uint8List sourceBytes = File(pdfPath).readAsBytesSync();
    final PdfDocument doc = PdfDocument(inputBytes: sourceBytes);

    final PdfFont font = PdfStandardFont(
      PdfFontFamily.helvetica,
      48,
      style: PdfFontStyle.bold,
    );

    // Semi-transparent brush
    final int alphaValue = (opacity * 255).round().clamp(0, 255);
    final PdfBrush brush = PdfSolidBrush(
      PdfColor(128, 128, 128, alphaValue),
    );

    for (int i = 0; i < doc.pages.count; i++) {
      final PdfPage page = doc.pages[i];
      final Size pageSize = page.getClientSize();
      final PdfGraphics graphics = page.graphics;

      // Save graphics state
      graphics.save();

      // Move to center of page
      graphics.translateTransform(
        pageSize.width / 2,
        pageSize.height / 2,
      );

      // Apply rotation
      graphics.rotateTransform(rotation);

      // Measure text to center it
      final Size textSize = font.measureString(text);

      // Draw text centered at origin (which is now page center)
      graphics.drawString(
        text,
        font,
        brush: brush,
        bounds: Rect.fromLTWH(
          -textSize.width / 2,
          -textSize.height / 2,
          textSize.width,
          textSize.height,
        ),
      );

      // Restore graphics state
      graphics.restore();
    }

    final baseName = _baseName(pdfPath);
    final outPath = '$outputDir/${baseName}_watermarked_$timestamp.pdf';
    File(outPath).writeAsBytesSync(doc.saveSync());
    doc.dispose();

    return outPath;
  }

  // ═══════════════════════════════════════════════════════════
  // Check if Password Protected
  // ═══════════════════════════════════════════════════════════

  /// Checks if a PDF is password-protected.
  ///
  /// Attempts to open the PDF without a password. If it throws,
  /// the PDF is protected.
  Future<bool> isPasswordProtected(String pdfPath) async {
    return compute(_isPasswordProtectedIsolate, {'pdfPath': pdfPath});
  }

  static bool _isPasswordProtectedIsolate(Map<String, dynamic> params) {
    final String pdfPath = params['pdfPath'];
    try {
      final Uint8List bytes = File(pdfPath).readAsBytesSync();
      final doc = PdfDocument(inputBytes: bytes);
      doc.dispose();
      return false;
    } catch (_) {
      return true;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Sign PDF (Visual Signature Stamp)
  // ═══════════════════════════════════════════════════════════

  /// Stamps a signature image onto a specific page at a specific position.
  ///
  /// [pdfPath]        — Source PDF file path.
  /// [signatureBytes] — PNG bytes of the drawn signature.
  /// [pageIndex]      — Zero-based page index to stamp on.
  /// [xPercent]       — Horizontal position as fraction of page width (0.0–1.0).
  /// [yPercent]       — Vertical position as fraction of page height (0.0–1.0).
  /// [widthPercent]   — Signature width as fraction of page width.
  Future<String> signPdf(
    String pdfPath, {
    required Uint8List signatureBytes,
    required int pageIndex,
    required double xPercent,
    required double yPercent,
    double widthPercent = 0.25,
  }) async {
    final outputDir = await _getDocumentsDir();
    return compute(_signPdfIsolate, {
      'pdfPath': pdfPath,
      'signatureBytes': signatureBytes,
      'pageIndex': pageIndex,
      'xPercent': xPercent,
      'yPercent': yPercent,
      'widthPercent': widthPercent,
      'outputDir': outputDir,
    });
  }

  static String _signPdfIsolate(Map<String, dynamic> params) {
    final String pdfPath = params['pdfPath'];
    final Uint8List signatureBytes = params['signatureBytes'];
    final int pageIndex = params['pageIndex'];
    final double xPercent = params['xPercent'];
    final double yPercent = params['yPercent'];
    final double widthPercent = params['widthPercent'];
    final String outputDir = params['outputDir'];
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    final Uint8List sourceBytes = File(pdfPath).readAsBytesSync();
    final PdfDocument doc = PdfDocument(inputBytes: sourceBytes);

    if (pageIndex < 0 || pageIndex >= doc.pages.count) {
      doc.dispose();
      throw ArgumentError('Page index $pageIndex out of range');
    }

    final PdfPage page = doc.pages[pageIndex];
    final Size pageSize = page.getClientSize();

    // Create signature image
    final PdfBitmap sigImage = PdfBitmap(signatureBytes);

    // Calculate dimensions
    final double sigWidth = pageSize.width * widthPercent;
    final double sigHeight = sigWidth * (sigImage.height / max(sigImage.width, 1));
    final double x = pageSize.width * xPercent;
    final double y = pageSize.height * yPercent;

    // Clamp to page bounds
    final double clampedX = x.clamp(0, pageSize.width - sigWidth);
    final double clampedY = y.clamp(0, pageSize.height - sigHeight);

    page.graphics.drawImage(
      sigImage,
      Rect.fromLTWH(clampedX, clampedY, sigWidth, sigHeight),
    );

    final baseName = _baseName(pdfPath);
    final outPath = '$outputDir/${baseName}_signed_$timestamp.pdf';
    File(outPath).writeAsBytesSync(doc.saveSync());
    doc.dispose();

    return outPath;
  }

  // ═══════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════

  /// Extract basename without extension.
  static String _baseName(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final dotIndex = name.lastIndexOf('.');
    return dotIndex > 0 ? name.substring(0, dotIndex) : name;
  }
}
