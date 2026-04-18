import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/bundle_model.dart';

/// Service for creating, listing, and deleting output bundles.
///
/// Bundles are stored under AppDocuments/Oqba/bundles/{bundleId}/
/// Each bundle has a metadata.json plus the actual output files.
class BundleService {
  static String? _cachedBundlesDir;

  /// Get the bundles root directory.
  Future<String> _getBundlesDir() async {
    if (_cachedBundlesDir != null) return _cachedBundlesDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/Oqba/bundles');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedBundlesDir = dir.path;
    return _cachedBundlesDir!;
  }

  /// Create a new bundle from a list of output file paths.
  ///
  /// Files are MOVED (not copied) into the bundle directory to save space.
  /// Returns the created [BundleModel].
  Future<BundleModel> createBundle({
    required String name,
    required String type,
    required List<String> filePaths,
  }) async {
    final bundlesDir = await _getBundlesDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final bundleId = '${_sanitizeName(name)}_$timestamp';
    final bundleDir = Directory('$bundlesDir/$bundleId');
    await bundleDir.create(recursive: true);

    // Move files into the bundle directory
    final List<String> movedPaths = [];
    int totalSize = 0;

    for (final srcPath in filePaths) {
      final srcFile = File(srcPath);
      if (!await srcFile.exists()) continue;

      final fileName = srcPath.split(Platform.pathSeparator).last;
      final destPath = '${bundleDir.path}/$fileName';

      try {
        // Try rename (move) first — fastest
        await srcFile.rename(destPath);
        movedPaths.add(destPath);
      } catch (_) {
        // Cross-device move: copy + delete
        try {
          await srcFile.copy(destPath);
          await srcFile.delete();
          movedPaths.add(destPath);
        } catch (_) {
          // Fallback: just copy, keep source
          try {
            await srcFile.copy(destPath);
            movedPaths.add(destPath);
          } catch (_) {
            continue;
          }
        }
      }

      try {
        totalSize += File(destPath).lengthSync();
      } catch (_) {}
    }

    final bundle = BundleModel(
      id: bundleId,
      name: name,
      type: type,
      filePaths: movedPaths,
      createdAt: DateTime.now(),
      totalSizeBytes: totalSize,
    );

    // Persist metadata
    final metaFile = File('${bundleDir.path}/metadata.json');
    await metaFile.writeAsString(bundle.toJsonString());

    return bundle;
  }

  /// List all bundles, sorted newest-first.
  Future<List<BundleModel>> listBundles() async {
    final bundlesDir = await _getBundlesDir();
    final dir = Directory(bundlesDir);
    if (!await dir.exists()) return [];

    final List<BundleModel> bundles = [];

    await for (final entity in dir.list()) {
      if (entity is Directory) {
        final metaFile = File('${entity.path}/metadata.json');
        if (await metaFile.exists()) {
          try {
            final json = await metaFile.readAsString();
            final bundle = BundleModel.fromJsonString(json);

            // Verify files still exist, filter out deleted ones
            final existingPaths = <String>[];
            for (final path in bundle.filePaths) {
              if (await File(path).exists()) {
                existingPaths.add(path);
              }
            }

            bundles.add(BundleModel(
              id: bundle.id,
              name: bundle.name,
              type: bundle.type,
              filePaths: existingPaths,
              createdAt: bundle.createdAt,
              totalSizeBytes: bundle.totalSizeBytes,
            ));
          } catch (_) {
            // Skip corrupted metadata
          }
        }
      }
    }

    bundles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bundles;
  }

  /// Delete a bundle and all its files.
  Future<void> deleteBundle(String bundleId) async {
    final bundlesDir = await _getBundlesDir();
    final bundleDir = Directory('$bundlesDir/$bundleId');
    if (await bundleDir.exists()) {
      await bundleDir.delete(recursive: true);
    }
  }

  /// Sanitize a name for use as a directory name.
  static String _sanitizeName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}
