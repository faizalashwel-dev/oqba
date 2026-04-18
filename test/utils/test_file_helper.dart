import 'dart:io';

/// Utility to load real physical PDFs for stress testing.
class TestFileHelper {
  // Using absolute path as requested by the test setup
  static const String testDirPath = r'd:\pdf_pro\pdf_test';

  /// Returns all PDF files in the test directory
  static List<File> getTestPdfs() {
    final dir = Directory(testDirPath);
    if (!dir.existsSync()) {
      print('WARNING: Test directory not found at $testDirPath');
      return [];
    }

    return dir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.pdf'))
        .toList();
  }
}
