import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oqba/services/pdf_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late String tempPdfPath;
  
  setUp(() async {
    // Mock path_provider to output to system temp for unit tests
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });

    // Create a dummy 3-page PDF for testing
    final document = PdfDocument();
    document.pages.add(); // Page 1
    document.pages.add(); // Page 2
    document.pages.add(); // Page 3
    
    final file = File('${Directory.systemTemp.path}/test_source.pdf');
    file.writeAsBytesSync(document.saveSync());
    document.dispose();
    tempPdfPath = file.path;
  });

  group('PdfService Edge Cases Test Suite', () {
    final pdfService = PdfService();

    test('splitPdf with out-of-bounds range does not crash', () async {
      // Issue: range specifies [0, 50] but PDF only has 3 pages
      // Expected: Copies up to pages.count (3 pages) without crashing
      final result = await pdfService.splitPdfPaths(tempPdfPath, [[0, 50]], 'split_test');
      
      expect(result, isNotNull);
      expect(result.length, 1);
      
      final outFile = File(result.first);
      expect(outFile.existsSync(), true);
      
      final outDoc = PdfDocument(inputBytes: outFile.readAsBytesSync());
      expect(outDoc.pages.count, 3);
      outDoc.dispose();
    });

    test('deletePages with empty list works fine (copies all pages)', () async {
      // Issue: Empty delete selection
      // Expected: Returns document with all 3 pages
      final result = await pdfService.deletePages(tempPdfPath, [], 'delete_test');
      
      expect(result, isNotNull);
      
      final outFile = File(result.outputPath);
      expect(outFile.existsSync(), true);
      
      final outDoc = PdfDocument(inputBytes: outFile.readAsBytesSync());
      expect(outDoc.pages.count, 3); 
      outDoc.dispose();
    });

    test('deletePages trying to delete all pages throws ArgumentError', () async {
      // Issue: Trying to delete pages 0, 1, 2 on a 3-page doc
      // Expected: ArgumentError to prevent completely blank output
      bool didThrow = false;
      try {
        await pdfService.deletePages(tempPdfPath, [0, 1, 2], 'delete_all_test');
      } catch (e) {
        didThrow = true;
      }
      expect(didThrow, true);
    });
  });
}
