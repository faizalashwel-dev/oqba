import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'file_service.dart';

/// Service for calculating and clearing cached/temporary files.
///
/// Tracks usage across Oqba/bundles/, Oqba/extracted/, and Oqba/temp/.
class CleanupService {
  /// Calculate total size of all clearable directories.
  ///
  /// Returns size in bytes.
  Future<int> calculateCacheSize() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dirs = [
      Directory('${appDir.path}/Oqba/bundles'),
      Directory('${appDir.path}/Oqba/extracted'),
      Directory('${appDir.path}/Oqba/temp'),
    ];

    int totalBytes = 0;
    for (final dir in dirs) {
      if (await dir.exists()) {
        totalBytes += await _dirSize(dir);
      }
    }
    return totalBytes;
  }

  /// Clear all cached/temporary files.
  ///
  /// Returns bytes freed.
  Future<int> clearCache() async {
    final before = await calculateCacheSize();
    final appDir = await getApplicationDocumentsDirectory();
    final dirs = [
      Directory('${appDir.path}/Oqba/bundles'),
      Directory('${appDir.path}/Oqba/extracted'),
      Directory('${appDir.path}/Oqba/temp'),
    ];

    for (final dir in dirs) {
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
    }
    return before;
  }

  /// Recursively calculate directory size.
  Future<int> _dirSize(Directory dir) async {
    int size = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            size += await entity.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return size;
  }

  /// Format bytes to human-readable string.
  static String formatSize(int bytes) {
    return FileService.formatFileSize(bytes);
  }
}
