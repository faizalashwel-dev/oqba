/// Security Service — Stub for v2.0.
///
/// Full implementation deferred to v2.0.
/// This file defines the interface contract so that UI pages
/// can reference the service signatures without build errors.
/// All methods throw [UnimplementedError] at runtime.
library;

/// Abstract interface for PDF security operations.
///
/// Planned for v2.0: password protection, watermarking.
abstract class SecurityService {
  /// Adds password protection to a PDF.
  ///
  /// [pdfPath]       — Source PDF file path.
  /// [userPassword]  — Password required to open the document.
  /// [ownerPassword] — Password for full access (optional).
  /// Returns: Path to the protected PDF.
  Future<String> passwordProtect(
    String pdfPath, {
    required String userPassword,
    String? ownerPassword,
  });

  /// Removes password from a protected PDF.
  ///
  /// [pdfPath]  — Source PDF file path.
  /// [password] — Current password to unlock.
  /// Returns: Path to the unprotected PDF.
  Future<String> removePassword(
    String pdfPath, {
    required String password,
  });

  /// Adds a text watermark to every page.
  ///
  /// [pdfPath]  — Source PDF file path.
  /// [text]     — Watermark text (e.g. "CONFIDENTIAL").
  /// [opacity]  — Watermark opacity (0.0–1.0).
  /// [rotation] — Rotation angle in degrees.
  /// Returns: Path to the watermarked PDF.
  Future<String> addWatermark(
    String pdfPath, {
    required String text,
    double opacity = 0.3,
    double rotation = -45,
  });

  /// Checks if a PDF is password-protected.
  ///
  /// Returns true if the PDF requires a password to open.
  Future<bool> isPasswordProtected(String pdfPath);
}

/// Stub implementation — all methods throw [UnimplementedError].
///
/// Full implementation deferred to v2.0.
class SecurityServiceStub implements SecurityService {
  @override
  Future<String> passwordProtect(
    String pdfPath, {
    required String userPassword,
    String? ownerPassword,
  }) {
    throw UnimplementedError(
      'SecurityService.passwordProtect is planned for v2.0',
    );
  }

  @override
  Future<String> removePassword(
    String pdfPath, {
    required String password,
  }) {
    throw UnimplementedError(
      'SecurityService.removePassword is planned for v2.0',
    );
  }

  @override
  Future<String> addWatermark(
    String pdfPath, {
    required String text,
    double opacity = 0.3,
    double rotation = -45,
  }) {
    throw UnimplementedError(
      'SecurityService.addWatermark is planned for v2.0',
    );
  }

  @override
  Future<bool> isPasswordProtected(String pdfPath) {
    throw UnimplementedError(
      'SecurityService.isPasswordProtected is planned for v2.0',
    );
  }
}
