import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../services/convert_service.dart';
import '../../services/file_service.dart';
import '../../services/page_thumbnail_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';

class PdfToImagesPage extends StatefulWidget {
  const PdfToImagesPage({super.key});
  @override
  State<PdfToImagesPage> createState() => _PdfToImagesPageState();
}

class _PdfToImagesPageState extends State<PdfToImagesPage> {
  final ConvertService _convertService = ConvertService();
  final FileService _fileService = FileService();
  String? _pdfPath;
  String? _pdfName;
  int _pageCount = 0;
  final String _format = 'png';
  int _dpi = 150;
  bool _isProcessing = false;
  String _progressText = '';
  List<String> _outputPaths = [];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      try {
        final importedPath = await _fileService.importFile(result.files.single.path!);
        final count = await PageThumbnailService().getPageCount(importedPath);
        setState(() { _pdfPath = importedPath; _pdfName = result.files.single.name; _pageCount = count; _outputPaths = []; });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _convert() async {
    if (_pdfPath == null) return;
    setState(() { _isProcessing = true; _progressText = 'Converting...'; });
    try {
      final startTime = DateTime.now();
      final paths = await _convertService.pdfToImages(_pdfPath!, format: _format, qualityDpi: _dpi);
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      setState(() { _outputPaths = paths; _isProcessing = false; });
      if (mounted) showSpeedReceipt(context, operation: 'Converted ${paths.length} pages to $_format', elapsedMs: elapsed);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Conversion failed: $e'), backgroundColor: Colors.redAccent));
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('PDF to Images', style: TextStyle(fontWeight: FontWeight.w700)), actions: const [OfflineIndicator(), SizedBox(width: 12)]),
      body: SafeArea(child: _outputPaths.isNotEmpty ? _buildResults() : _buildForm()),
    );
  }

  Widget _buildForm() {
    return Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(onTap: _isProcessing ? null : _pickFile, child: Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primary.withAlpha(60))),
        child: _pdfPath == null
            ? const Column(children: [Icon(Icons.upload_file_rounded, color: AppTheme.primary, size: 40), SizedBox(height: 8), Text('Select PDF', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600))])
            : Row(children: [const Icon(Icons.picture_as_pdf, color: AppTheme.primary, size: 32), const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_pdfName ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis), Text('$_pageCount pages', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))]))]),
      )),
      if (_pdfPath != null) ...[
        const SizedBox(height: 24),
        const Text('Quality', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [ButtonSegment(value: 72, label: Text('Screen')), ButtonSegment(value: 150, label: Text('Standard')), ButtonSegment(value: 300, label: Text('Print'))],
          selected: {_dpi}, onSelectionChanged: (s) => setState(() => _dpi = s.first),
          style: SegmentedButton.styleFrom(backgroundColor: AppTheme.surface, foregroundColor: AppTheme.textPrimary, selectedBackgroundColor: AppTheme.primary, selectedForegroundColor: Colors.white),
        ),
        if (_pageCount > 20 && _dpi == 300) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orangeAccent.withAlpha(30), borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [Icon(Icons.warning_amber, color: Colors.orangeAccent, size: 20), SizedBox(width: 8), Expanded(child: Text('This may take ~30 seconds. Screen quality is faster.', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)))]))
        ],
      ],
      const Spacer(),
      if (_pdfPath != null) SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
        onPressed: _isProcessing ? null : _convert,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _isProcessing
            ? Row(mainAxisSize: MainAxisSize.min, children: [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)), const SizedBox(width: 12), Text(_progressText, style: const TextStyle(color: Colors.white))])
            : const Text('Convert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      )),
    ]));
  }

  Widget _buildResults() {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Text('${_outputPaths.length} images converted', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700))),
      Expanded(child: GridView.builder(
        padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: _outputPaths.length,
        itemBuilder: (ctx, i) => Stack(children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_outputPaths[i]), fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
          Positioned(bottom: 4, right: 4, child: GestureDetector(
            onTap: () => SharePlus.instance.share(ShareParams(files: [XFile(_outputPaths[i])])),
            child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle), child: const Icon(Icons.share, size: 14, color: Colors.white)),
          )),
        ]),
      )),
    ]);
  }
}
