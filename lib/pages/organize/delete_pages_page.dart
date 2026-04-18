import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/pdf_service.dart';
import '../../services/file_service.dart';
import '../../services/page_thumbnail_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';
import '../../widgets/page_selector_grid.dart';

class DeletePagesPage extends StatefulWidget {
  const DeletePagesPage({super.key});
  @override
  State<DeletePagesPage> createState() => _DeletePagesPageState();
}

class _DeletePagesPageState extends State<DeletePagesPage> {
  final PdfService _pdfService = PdfService();
  final FileService _fileService = FileService();
  String? _pdfPath;
  String? _pdfName;
  int _pageCount = 0;
  List<int> _selected = [];
  bool _isProcessing = false;

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

  Future<void> _confirmDelete() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one page.'), backgroundColor: Colors.orange));
      return;
    }
    if (_selected.length >= _pageCount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete all pages'), backgroundColor: Colors.orangeAccent));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surf(context),
        title: Text('Delete Pages?', style: TextStyle(color: AppTheme.txtPrimary(context))),
        content: Text('Delete ${_selected.length} pages permanently?\nThis will create a new file with those pages removed.', style: TextStyle(color: AppTheme.txtSecondary(context))),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), style: OutlinedButton.styleFrom(foregroundColor: AppTheme.txtSecondary(context)), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: Text('Delete Pages', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm == true) _delete();
  }

  Future<void> _delete() async {
    if (_pdfPath == null) return;
    setState(() => _isProcessing = true);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final result = await _pdfService.deletePages(_pdfPath!, _selected, 'edited_$timestamp');
      if (mounted) {
        showSpeedReceipt(context, operation: 'Deleted ${_selected.length} pages', elapsedMs: result.elapsedMs, fileSize: result.formattedSize);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: Text('Delete Pages', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: const [OfflineIndicator(), SizedBox(width: 12)],
      ),
      body: _pdfPath == null
          ? Center(child: GestureDetector(onTap: _pickFile, child: Container(
              padding: const EdgeInsets.all(40), decoration: BoxDecoration(color: AppTheme.surf(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.redAccent.withAlpha(60))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.upload_file_rounded, color: Colors.redAccent, size: 48), SizedBox(height: 12), Text('Select PDF', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600, fontSize: 16))]))))
          : Column(children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
                Icon(Icons.picture_as_pdf, color: Colors.redAccent), const SizedBox(width: 8),
                Expanded(child: Text(_pdfName ?? '', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Text('$_pageCount pages', style: TextStyle(color: AppTheme.txtSecondary(context), fontSize: 12)),
              ])),
              Expanded(child: PageSelectorGrid(pdfPath: _pdfPath!, pageCount: _pageCount, onSelectionChanged: (s) => setState(() => _selected = s))),
              Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), child: SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
                onPressed: _isProcessing ? null : _confirmDelete,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, disabledBackgroundColor: AppTheme.surf(context), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isProcessing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : Text('Delete ${_selected.length} Pages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              ))),
            ]),
    );
  }
}
