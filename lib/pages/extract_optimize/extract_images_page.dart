import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../services/extract_service.dart';
import '../../services/file_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';

class ExtractImagesPage extends StatefulWidget {
  const ExtractImagesPage({super.key});
  @override
  State<ExtractImagesPage> createState() => _ExtractImagesPageState();
}

class _ExtractImagesPageState extends State<ExtractImagesPage> {
  final ExtractService _extractService = ExtractService();
  final FileService _fileService = FileService();
  String? _pdfPath;
  String? _pdfName;
  bool _isProcessing = false;
  List<String>? _imagePaths;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      try {
        final importedPath = await _fileService.importFile(result.files.single.path!);
        setState(() { _pdfPath = importedPath; _pdfName = result.files.single.name; _imagePaths = null; });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _extract() async {
    if (_pdfPath == null) return;
    setState(() { _isProcessing = true; });
    try {
      final startTime = DateTime.now();
      final paths = await _extractService.extractImagesFromPdf(_pdfPath!);
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      setState(() { _imagePaths = paths; _isProcessing = false; });
      if (mounted) showSpeedReceipt(context, operation: 'Extracted ${paths.length} images', elapsedMs: elapsed);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Extraction failed: $e'), backgroundColor: Colors.redAccent));
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Extract Images', style: TextStyle(fontWeight: FontWeight.w700)), actions: const [OfflineIndicator(), SizedBox(width: 12)]),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: _imagePaths != null ? _buildResults() : _buildForm())),
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
            ? const Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)), SizedBox(width: 12), Text('Scanning document architecture...', style: TextStyle(color: Colors.white))])
            : const Text('Scan for Images', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      )),
    ]);
  }

  Widget _buildResults() {
    if (_imagePaths!.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.image_not_supported, size: 64, color: AppTheme.textSecondary.withAlpha(80)),
        const SizedBox(height: 16),
        const Text('No embedded images found.', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('This PDF may be scanned. Try PDF to Images instead.', style: TextStyle(color: AppTheme.textSecondary.withAlpha(150), fontSize: 13)),
        const SizedBox(height: 16),
        TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/convert/pdf-to-images'), child: const Text('Open PDF to Images', style: TextStyle(color: AppTheme.primary))),
      ]));
    }
    return Column(children: [
      Text('Found ${_imagePaths!.length} images', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      Expanded(child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: _imagePaths!.length,
        itemBuilder: (ctx, i) {
          final file = File(_imagePaths![i]);
          final size = file.existsSync() ? (file.lengthSync() / 1024).toStringAsFixed(0) : '?';
          return Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(file, fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
            Positioned(bottom: 4, left: 4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: AppTheme.background.withAlpha(200), borderRadius: BorderRadius.circular(4)),
              child: Text('${size}KB', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)))),
            Positioned(top: 4, right: 4, child: GestureDetector(
              onTap: () => SharePlus.instance.share(ShareParams(files: [XFile(_imagePaths![i])])),
              child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle), child: const Icon(Icons.share, size: 12, color: Colors.white)))),
          ]);
        },
      )),
    ]);
  }
}
