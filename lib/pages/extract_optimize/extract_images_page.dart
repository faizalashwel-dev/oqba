import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../services/extract_service.dart';
import '../../services/file_service.dart';
import '../../services/save_service.dart';
import '../../services/bundle_service.dart';
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
  final SaveService _saveService = SaveService();
  final BundleService _bundleService = BundleService();
  String? _pdfPath;
  String? _pdfName;
  bool _isProcessing = false;
  bool _isSaving = false;
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

      // Auto-bundle if images found
      if (paths.isNotEmpty) {
        final baseName = (_pdfName ?? 'pdf').replaceAll('.pdf', '');
        await _bundleService.createBundle(
          name: '$baseName — Extracted',
          type: 'extracted_images',
          filePaths: List.from(paths), // Don't move — keep originals for display
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Extraction failed: $e'), backgroundColor: Colors.redAccent));
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveAllToGallery() async {
    if (_imagePaths == null || _imagePaths!.isEmpty) return;
    setState(() => _isSaving = true);
    final saved = await _saveService.saveAllImagesToGallery(_imagePaths!);
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(saved > 0 ? 'Saved $saved images to Gallery!' : 'Save failed — check permissions'),
        backgroundColor: saved > 0 ? AppTheme.primary : Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(title: Text('Extract Images', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.txtPrimary(context))), actions: const [OfflineIndicator(), SizedBox(width: 12)]),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: _imagePaths != null ? _buildResults() : _buildForm())),
    );
  }

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Info card explaining the difference
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'This tool finds images embedded inside the PDF structure (logos, photos, etc). For scanned documents, use "PDF to Images" instead.',
                style: TextStyle(color: AppTheme.subtleText(context), fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),

      // File picker
      GestureDetector(onTap: _isProcessing ? null : _pickFile, child: Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.surf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3))),
        child: _pdfPath == null
            ? Column(children: [Icon(Icons.upload_file_rounded, color: AppTheme.primary, size: 40), const SizedBox(height: 8), Text('Select PDF', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600))])
            : Row(children: [Icon(Icons.picture_as_pdf, color: AppTheme.primary, size: 32), const SizedBox(width: 12),
                Expanded(child: Text(_pdfName ?? '', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis))]),
      )),
      const Spacer(),
      if (_pdfPath != null) SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
        onPressed: _isProcessing ? null : _extract,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _isProcessing
            ? Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)), SizedBox(width: 12), Text('Scanning document...', style: TextStyle(color: Colors.white))])
            : Text('Scan for Images', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      )),
    ]);
  }

  Widget _buildResults() {
    if (_imagePaths!.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.image_not_supported_rounded, size: 56, color: Colors.orangeAccent),
        ),
        const SizedBox(height: 20),
        Text('No embedded images found', style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "This PDF doesn't contain embedded images. If this is a scanned document, please use the 'PDF to Images' tool instead to convert each page into an image.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.subtleText(context), fontSize: 13, height: 1.5),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/convert/pdf-to-images'),
            icon: Icon(Icons.image_rounded, color: Colors.white),
            label: Text('Open PDF to Images', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() { _imagePaths = null; _pdfPath = null; _pdfName = null; }),
          child: Text('Try another PDF', style: TextStyle(color: AppTheme.primary)),
        ),
      ]));
    }

    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Found ${_imagePaths!.length} images', style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 20, fontWeight: FontWeight.w800)),
          // Save all button
          GestureDetector(
            onTap: _isSaving ? null : _saveAllToGallery,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_rounded, color: AppTheme.primary, size: 16),
                        const SizedBox(width: 4),
                        Text('Save All', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Expanded(child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: _imagePaths!.length,
        itemBuilder: (ctx, i) {
          final file = File(_imagePaths![i]);
          final size = file.existsSync() ? (file.lengthSync() / 1024).toStringAsFixed(0) : '?';
          return Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(file, fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
            Positioned(bottom: 4, left: 4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: AppTheme.bg(context).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
              child: Text('${size}KB', style: TextStyle(color: AppTheme.subtleText(context), fontSize: 9)))),
            Positioned(top: 4, right: 4, child: GestureDetector(
              onTap: () => SharePlus.instance.share(ShareParams(files: [XFile(_imagePaths![i])])),
              child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle), child: Icon(Icons.share, size: 12, color: Colors.white)))),
          ]);
        },
      )),
    ]);
  }
}
