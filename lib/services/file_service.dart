import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/pdf_file_model.dart';

class FileService {
  static String? _cachedDocDir;
  static String? _cachedScansDir;

  /// AppDocuments/Oqba/documents/ — all PDF outputs land here.
  Future<String> getOqbaDocumentsDir() async {
    if (_cachedDocDir != null) return _cachedDocDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final docDir = Directory('${appDir.path}/Oqba/documents');
    if (!await docDir.exists()) {
      await docDir.create(recursive: true);
    }
    _cachedDocDir = docDir.path;
    return _cachedDocDir!;
  }

  /// AppDocuments/Oqba/scans/ — raw scan images.
  Future<String> getOqbaScansDir() async {
    if (_cachedScansDir != null) return _cachedScansDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${appDir.path}/Oqba/scans');
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }
    _cachedScansDir = scansDir.path;
    return _cachedScansDir!;
  }

  /// AppDocuments/Oqba/temp/ — transient processing files.
  Future<String> getOqbaTempDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = Directory('${appDir.path}/Oqba/temp');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir.path;
  }

  /// List all PDFs in AppDocuments/Oqba/documents/
  /// Sorted newest-first by modification date.
  Future<List<PdfFileModel>> listDocuments() async {
    final dirPath = await getOqbaDocumentsDir();
    final dir = Directory(dirPath);

    if (!await dir.exists()) return [];

    final List<PdfFileModel> files = [];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
        try {
          final stat = await entity.stat();
          final name = entity.path.split(Platform.pathSeparator).last;
          files.add(PdfFileModel(
            id: entity.path,
            name: name,
            path: entity.path,
            sizeBytes: stat.size,
            formattedSize: formatFileSize(stat.size),
            createdAt: stat.modified,
          ));
        } catch (_) {
          // Skip files with stat errors (e.g., locked by another process)
        }
      }
    }

    // Sort newest first
    files.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return files;
  }

  /// Delete a document by path. No-op if file doesn't exist.
  Future<void> deleteDocument(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Rename a document. Returns the new path.
  Future<String> renameDocument(String oldPath, String newName) async {
    final file = File(oldPath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', oldPath);
    }

    final dir = file.parent.path;
    // Ensure .pdf extension
    final safeName = newName.endsWith('.pdf') ? newName : '$newName.pdf';
    final newPath = '$dir${Platform.pathSeparator}$safeName';

    // Avoid overwriting an existing file
    if (await File(newPath).exists()) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final baseName = safeName.replaceAll('.pdf', '');
      final fallbackPath = '$dir${Platform.pathSeparator}${baseName}_$timestamp.pdf';
      await file.rename(fallbackPath);
      return fallbackPath;
    }

    await file.rename(newPath);
    return newPath;
  }

  /// Import external file → copy to internal AppDocuments/Oqba/documents/ directory.
  /// Returns the path of the imported file.
  Future<String> importFile(String sourcePath) async {
    final destDir = await getOqbaDocumentsDir();
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file not found', sourcePath);
    }

    final fileName = sourcePath.split(Platform.pathSeparator).last;
    final destPath = '$destDir${Platform.pathSeparator}$fileName';

    // Avoid overwriting — append timestamp if file exists
    final destFile = File(destPath);
    if (await destFile.exists()) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nameNoExt = fileName.replaceAll('.pdf', '');
      final newPath = '$destDir${Platform.pathSeparator}${nameNoExt}_$timestamp.pdf';
      await sourceFile.copy(newPath);
      return newPath;
    }

    await sourceFile.copy(destPath);
    return destPath;
  }

  /// Clean up temp directory to reclaim space.
  Future<void> clearTempDir() async {
    final tempPath = await getOqbaTempDir();
    final tempDir = Directory(tempPath);
    if (await tempDir.exists()) {
      await for (final entity in tempDir.list()) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  /// Get formatted file size (e.g., "2.3 MB")
  static String formatFileSize(int bytes) {
    if (bytes < 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
