import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../services/convert_service.dart';
import '../../services/file_service.dart';
import '../../services/save_service.dart';
import '../../services/bundle_service.dart';
import '../../services/page_thumbnail_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';
import '../../widgets/page_selector_grid.dart';

class PdfToImagesPage extends StatefulWidget {
  const PdfToImagesPage({super.key});
  @override
  State<PdfToImagesPage> createState() => _PdfToImagesPageState();
}

class _PdfToImagesPageState extends State<PdfToImagesPage> {
  final ConvertService _convertService = ConvertService();
  final FileService _fileService = FileService();
  final SaveService _saveService = SaveService();
  final BundleService _bundleService = BundleService();
  String? _pdfPath;
  String? _pdfName;
  int _pageCount = 0;
  int _dpi = 150;
  bool _isProcessing = false;
  bool _isSaving = false;
  String _progressText = '';
  List<String> _outputPaths = [];

  // Page selection
  Set<int> _selectedPages = {};

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      try {
        final importedPath = await _fileService.importFile(result.files.single.path!);
        final count = await PageThumbnailService().getPageCount(importedPath);
        setState(() {
          _pdfPath = importedPath;
          _pdfName = result.files.single.name;
          _pageCount = count;
          _outputPaths = [];
          // Select all pages by default
          _selectedPages = Set<int>.from(List.generate(count, (i) => i));
        });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _convert() async {
    if (_pdfPath == null || _selectedPages.isEmpty) return;
    setState(() { _isProcessing = true; _progressText = 'Starting...'; });
    try {
      final startTime = DateTime.now();
      final paths = await _convertService.pdfToImagesSelected(
        _pdfPath!,
        pageIndices: _selectedPages.toList(),
        qualityDpi: _dpi,
        onProgress: (current, total) {
          if (mounted) setState(() => _progressText = 'Page $current of $total');
        },
      );
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      setState(() { _outputPaths = paths; _isProcessing = false; });

      if (mounted) showSpeedReceipt(context, operation: 'Converted ${paths.length} pages', elapsedMs: elapsed);

      // Auto-bundle
      if (paths.isNotEmpty) {
        final baseName = (_pdfName ?? 'pdf').replaceAll('.pdf', '');
        await _bundleService.createBundle(
          name: '$baseName — Images',
          type: 'pdf_to_images',
          filePaths: List.from(paths),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Conversion failed: $e'), backgroundColor: Colors.redAccent));
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveAllToGallery() async {
    if (_outputPaths.isEmpty) return;
    setState(() => _isSaving = true);
    final saved = await _saveService.saveAllImagesToGallery(_outputPaths);
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
      appBar: AppBar(title: Text('PDF to Images', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.txtPrimary(context))), actions: const [OfflineIndicator(), SizedBox(width: 12)]),
      body: SafeArea(child: _outputPaths.isNotEmpty ? _buildResults() : _buildForm()),
    );
  }

  Widget _buildForm() {
    return Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // File picker
      GestureDetector(onTap: _isProcessing ? null : _pickFile, child: Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.surf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3))),
        child: _pdfPath == null
            ? Column(children: [Icon(Icons.upload_file_rounded, color: AppTheme.primary, size: 40), const SizedBox(height: 8), Text('Select PDF', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600))])
            : Row(children: [Icon(Icons.picture_as_pdf, color: AppTheme.primary, size: 32), const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_pdfName ?? '', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis), Text('$_pageCount pages', style: TextStyle(color: AppTheme.subtleText(context), fontSize: 12))]))]),
      )),

      if (_pdfPath != null) ...[
        const SizedBox(height: 20),

        // Quality selector
        Text('Quality', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [ButtonSegment(value: 72, label: Text('Screen')), ButtonSegment(value: 150, label: Text('Standard')), ButtonSegment(value: 300, label: Text('Print'))],
          selected: {_dpi}, onSelectionChanged: (s) => setState(() => _dpi = s.first),
          style: SegmentedButton.styleFrom(backgroundColor: AppTheme.surf(context), foregroundColor: AppTheme.txtPrimary(context), selectedBackgroundColor: AppTheme.primary, selectedForegroundColor: Colors.white),
        ),

        if (_pageCount > 20 && _dpi == 300) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [Icon(Icons.warning_amber, color: Colors.orangeAccent, size: 20), const SizedBox(width: 8), Expanded(child: Text('This may take ~30 seconds. Screen quality is faster.', style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 12)))]))
        ],

        const SizedBox(height: 20),

        // Page selection
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Select pages (${_selectedPages.length}/$_pageCount)', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600)),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedPages = Set<int>.from(List.generate(_pageCount, (i) => i))),
                  child: Text('All', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _selectedPages.clear()),
                  child: Text('None', style: TextStyle(color: AppTheme.subtleText(context), fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Page selector grid (compact)
        Expanded(
          child: PageSelectorGrid(
            pdfPath: _pdfPath!,
            pageCount: _pageCount,
            onSelectionChanged: (pages) => setState(() => _selectedPages = pages.toSet()),
          ),
        ),

        const SizedBox(height: 16),
      ],

      if (_pdfPath != null) SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
        onPressed: _isProcessing || _selectedPages.isEmpty ? null : _convert,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _isProcessing
            ? Row(mainAxisSize: MainAxisSize.min, children: [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)), const SizedBox(width: 12), Text(_progressText, style: TextStyle(color: Colors.white))])
            : Text('Convert ${_selectedPages.length} Page${_selectedPages.length != 1 ? 's' : ''}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      )),
    ]));
  }

  Widget _buildResults() {
    return Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_outputPaths.length} images', style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 20, fontWeight: FontWeight.w800)),
            GestureDetector(
              onTap: _isSaving ? null : _saveAllToGallery,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          SizedBox(width: 4),
                          Text('Save All', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Grid
      Expanded(child: GridView.builder(
        padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: _outputPaths.length,
        itemBuilder: (ctx, i) => Stack(children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(_outputPaths[i]), fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
          Positioned(bottom: 4, right: 4, child: GestureDetector(
            onTap: () => SharePlus.instance.share(ShareParams(files: [XFile(_outputPaths[i])])),
            child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle), child: Icon(Icons.share, size: 14, color: Colors.white)),
          )),
        ]),
      )),
    ]);
  }
}
