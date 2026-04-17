import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerService {
  DocumentScanner? _scanner;

  DocumentScanner _getScanner() {
    _scanner ??= DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: {DocumentFormat.jpeg},
        mode: ScannerMode.full,
        pageLimit: 100,
        isGalleryImport: true,
      ),
    );
    return _scanner!;
  }

  /// Check and request camera permission.
  /// Returns true if permission is granted.
  Future<PermissionResult> ensureCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return PermissionResult(granted: true);
    }

    if (status.isPermanentlyDenied) {
      return PermissionResult(
        granted: false,
        permanentlyDenied: true,
        message: 'Camera permission is permanently denied. Please enable it in Settings.',
      );
    }

    final result = await Permission.camera.request();
    if (result.isGranted) {
      return PermissionResult(granted: true);
    }

    return PermissionResult(
      granted: false,
      permanentlyDenied: result.isPermanentlyDenied,
      message: 'Camera permission is required to scan documents.',
    );
  }

  /// Launches ML Kit document scanner.
  /// Returns list of scanned image paths (already edge-corrected).
  /// Throws [ScannerException] on failure.
  Future<List<String>> scanDocument() async {
    try {
      final scanner = _getScanner();
      final DocumentScanningResult result = await scanner.scanDocument();
      final List<String> rawPaths = result.images ?? [];

      if (rawPaths.isEmpty) {
        return [];
      }

      // Haptic Shutter — tactile feedback on successful scan
      await HapticFeedback.mediumImpact();

      return await _sanitizePaths(rawPaths);
    } catch (e) {
      throw ScannerException('Scan failed: $e');
    }
  }

  /// Copies scanned images from temp/cache → app's internal directory.
  /// Implements PATH SANITIZATION rule from the Strategy Report.
  /// All files land in AppDocuments/Oqba/scans/ — 100% offline.
  Future<List<String>> _sanitizePaths(List<String> rawPaths) async {
    final appDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${appDir.path}/Oqba/scans');

    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }

    final List<String> sanitizedPaths = [];

    for (int i = 0; i < rawPaths.length; i++) {
      final File rawFile = File(rawPaths[i]);
      if (await rawFile.exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newPath = '${scansDir.path}/scan_${timestamp}_$i.jpg';
        await rawFile.copy(newPath);
        sanitizedPaths.add(newPath);

        // Attempt cleanup of source file from cache
        try {
          await rawFile.delete();
        } catch (_) {}
      }
    }

    return sanitizedPaths;
  }

  void dispose() {
    _scanner?.close();
    _scanner = null;
  }
}

/// Result of a permission check.
class PermissionResult {
  final bool granted;
  final bool permanentlyDenied;
  final String? message;

  PermissionResult({
    required this.granted,
    this.permanentlyDenied = false,
    this.message,
  });
}

/// Exception thrown by [ScannerService].
class ScannerException implements Exception {
  final String message;
  ScannerException(this.message);

  @override
  String toString() => message;
}
