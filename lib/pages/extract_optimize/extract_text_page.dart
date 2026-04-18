import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/extract_service.dart';
import '../../services/file_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';

class ExtractTextPage extends StatefulWidget {
  const ExtractTextPage({super.key});
  @override
  State<ExtractTextPage> createState() => _ExtractTextPageState();
}

class _ExtractTextPageState extends State<ExtractTextPage> {
  final ExtractService _extractService = ExtractService();
  final FileService _fileService = FileService();
  String? _pdfPath;
  String? _pdfName;
  bool _isProcessing = false;
  String? _extractedText;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      try {
        final importedPath = await _fileService.importFile(result.files.single.path!);
        setState(() { _pdfPath = importedPath; _pdfName = result.files.single.name; _extractedText = null; });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _extract() async {
    if (_pdfPath == null) return;
    setState(() => _isProcessing = true);
    try {
      final startTime = DateTime.now();
      final text = await _extractService.extractTextFromPdf(_pdfPath!);
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final wordCount = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      setState(() { _extractedText = text; _isProcessing = false; });
      if (mounted) showSpeedReceipt(context, operation: 'Extracted $wordCount words', elapsedMs: elapsed);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Extraction failed: $e'), backgroundColor: Colors.redAccent));
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportTxt() async {
    if (_extractedText == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}/Oqba/extracted');
    if (!await outDir.exists()) await outDir.create(recursive: true);
    final path = '${outDir.path}/text_${DateTime.now().millisecondsSinceEpoch}.txt';
    File(path).writeAsStringSync(_extractedText!);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved: $path'), backgroundColor: AppTheme.primary));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Extract Text', style: TextStyle(fontWeight: FontWeight.w700)), actions: const [OfflineIndicator(), SizedBox(width: 12)]),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: _extractedText != null ? _buildResult() : _buildForm())),
    );
  }

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(onTap: _isProcessing ? null : _pickFile, child: Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primary.withAlpha(60))),
        child: _pdfPath == null
            ? const Column(children: [Icon(Icons.upload_file_rounded, color: AppTheme.primary, size: 40), SizedBox(height: 8), Text('Select PDF', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600))])
            : Row(children: [const Icon(Icons.picture_as_pdf, color: AppTheme.primary, size: 32), const SizedBox(width: 12),
                Expanded(child: Text(_pdfName ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis))]),
      )),
      const Spacer(),
      if (_pdfPath != null) SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
        onPressed: _isProcessing ? null : _extract,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _isProcessing
            ? const Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)), SizedBox(width: 12), Text('Extracting text...', style: TextStyle(color: Colors.white))])
            : const Text('Extract Text', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      )),
    ]);
  }

  Widget _buildResult() {
    final text = _extractedText!;
    final wordCount = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final charCount = text.length;
    final pageCount = RegExp(r'--- Page \d+ ---').allMatches(text).length;

    return Column(children: [
      // Stats row
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _stat('$wordCount', 'words'), _stat('$charCount', 'chars'), _stat('$pageCount', 'pages'),
        ])),
      const SizedBox(height: 12),
      // Low text warning
      if (text.trim().length < 50 && pageCount > 1) ...[
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orangeAccent.withAlpha(30), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 18), const SizedBox(width: 8),
            const Expanded(child: Text('Limited text found. This may be a scanned PDF.', style: TextStyle(color: Colors.orangeAccent, fontSize: 12))),
            TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/convert/ocr'), child: const Text('Try OCR', style: TextStyle(color: AppTheme.primary, fontSize: 12))),
          ])),
        const SizedBox(height: 12),
      ],
      // Text display
      Expanded(child: Container(
        width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
        child: SelectableText(text, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.6)),
      )),
      const SizedBox(height: 12),
      // Action buttons
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: text)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'))); },
          icon: const Icon(Icons.copy), label: const Text('Copy All'), style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: const BorderSide(color: AppTheme.primary)))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton.icon(onPressed: _exportTxt, icon: const Icon(Icons.save_alt, color: Colors.white), label: const Text('Export .txt', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary))),
      ]),
    ]);
  }

  Widget _stat(String value, String label) => Column(children: [
    Text(value, style: const TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.w800)),
    Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
  ]);
}
