import 'dart:io';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for saving files to the user's device storage.
///
/// - Images → native Gallery (via `gal` package)
/// - PDFs → public Downloads folder
///
/// Handles Android permission requests automatically (Task 9).
class SaveService {
  /// Request storage/media permissions based on Android version.
  ///
  /// Android 13+ (API 33+): needs READ_MEDIA_IMAGES.
  /// Android 12 and below: needs WRITE_EXTERNAL_STORAGE.
  Future<bool> _ensurePermissions({bool forImages = true}) async {
    if (!Platform.isAndroid) return true;

    // Try the modern photos permission first (Android 13+)
    if (forImages) {
      var status = await Permission.photos.status;
      if (status.isGranted) return true;
      if (!status.isPermanentlyDenied) {
        status = await Permission.photos.request();
        if (status.isGranted) return true;
      }
    }

    // Fallback to legacy storage permission (Android 12 and below)
    var storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) return true;
    if (!storageStatus.isPermanentlyDenied) {
      storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;
    }

    return false;
  }

  /// Save a single image to the device's native Gallery.
  ///
  /// Returns true on success, false on permission denial or error.
  Future<bool> saveImageToGallery(String imagePath) async {
    final hasPermission = await _ensurePermissions(forImages: true);
    if (!hasPermission) return false;

    try {
      await Gal.putImage(imagePath);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Save multiple images to the device's native Gallery.
  ///
  /// Returns the count of successfully saved images.
  Future<int> saveAllImagesToGallery(List<String> imagePaths) async {
    final hasPermission = await _ensurePermissions(forImages: true);
    if (!hasPermission) return 0;

    int saved = 0;
    for (final path in imagePaths) {
      try {
        await Gal.putImage(path);
        saved++;
      } catch (_) {
        // Skip individual failures, continue saving remaining
      }
    }
    return saved;
  }

  /// Save a PDF file to the public Downloads directory.
  ///
  /// On Android, copies to /storage/emulated/0/Download/.
  /// Returns the output path on success, null on failure.
  Future<String?> savePdfToDownloads(String pdfPath) async {
    final hasPermission = await _ensurePermissions(forImages: false);
    if (!hasPermission) return null;

    try {
      final fileName = pdfPath.split(Platform.pathSeparator).last;

      // Android public Downloads directory
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      String destPath = '${downloadsDir.path}/$fileName';

      // Avoid overwriting — append timestamp if file exists
      if (await File(destPath).exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final baseName = fileName.replaceAll('.pdf', '');
        destPath = '${downloadsDir.path}/${baseName}_$timestamp.pdf';
      }

      await File(pdfPath).copy(destPath);
      return destPath;
    } catch (_) {
      return null;
    }
  }
}
