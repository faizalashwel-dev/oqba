import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/pdf_service.dart';
import '../../services/file_service.dart';
import '../../services/page_thumbnail_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';
import '../../widgets/page_selector_grid.dart';

class ExtractPagesPage extends StatefulWidget {
  const ExtractPagesPage({super.key});
  @override
  State<ExtractPagesPage> createState() => _ExtractPagesPageState();
}

class _ExtractPagesPageState extends State<ExtractPagesPage> {
  final PdfService _pdfService = PdfService();
  final FileService _fileService = FileService();
  String? _pdfPath;
  String? _pdfName;
  int _pageCount = 0;
  List<int> _selected = [];
  bool _isProcessing = false;
  final GlobalKey<PageSelectorGridState> _gridKey = GlobalKey();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      try {
        final importedPath = await _fileService.importFile(result.files.single.path!);
        final count = await PageThumbnailService().getPageCount(importedPath);
        setState(() { _pdfPath = importedPath; _pdfName = result.files.single.name; _pageCount = count; _selected = []; });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _extract() async {
    if (_pdfPath == null) return;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one page.'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final result = await _pdfService.extractPages(_pdfPath!, _selected, 'extract_$timestamp');
      if (mounted) {
        showSpeedReceipt(context, operation: 'Extracted ${_selected.length} pages', elapsedMs: result.elapsedMs, fileSize: result.formattedSize);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Extract failed: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Extract Pages', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (_pdfPath != null)
            TextButton(onPressed: () => _gridKey.currentState?.selectAll(), child: const Text('Select All', style: TextStyle(color: AppTheme.primary))),
          const OfflineIndicator(), const SizedBox(width: 12),
        ],
      ),
      body: _pdfPath == null
          ? Center(
              child: GestureDetector(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primary.withAlpha(60))),
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.upload_file_rounded, color: AppTheme.primary, size: 48),
                    SizedBox(height: 12),
                    Text('Select PDF', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
                  ]),
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    const Icon(Icons.picture_as_pdf, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_pdfName ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    Text('$_pageCount pages', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ]),
                ),
                Expanded(child: PageSelectorGrid(key: _gridKey, pdfPath: _pdfPath!, pageCount: _pageCount, onSelectionChanged: (s) => setState(() => _selected = s))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _extract,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, disabledBackgroundColor: AppTheme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: _isProcessing
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                          : Text('Extract ${_selected.length} Pages', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
