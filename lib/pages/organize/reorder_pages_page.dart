import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/pdf_service.dart';
import '../../services/file_service.dart';
import '../../services/page_thumbnail_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';

class ReorderPagesPage extends StatefulWidget {
  const ReorderPagesPage({super.key});
  @override
  State<ReorderPagesPage> createState() => _ReorderPagesPageState();
}

class _ReorderPagesPageState extends State<ReorderPagesPage> {
  final PdfService _pdfService = PdfService();
  final FileService _fileService = FileService();
  String? _pdfPath;
  String? _pdfName;
  int _pageCount = 0;
  List<int> _currentOrder = [];
  bool _isProcessing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      try {
        final importedPath = await _fileService.importFile(result.files.single.path!);
        final count = await PageThumbnailService().getPageCount(importedPath);
        setState(() { _pdfPath = importedPath; _pdfName = result.files.single.name; _pageCount = count; _currentOrder = List.generate(count, (i) => i); });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  bool get _orderChanged {
    for (int i = 0; i < _currentOrder.length; i++) {
      if (_currentOrder[i] != i) return true;
    }
    return false;
  }

  Future<void> _save() async {
    if (_pdfPath == null) return;
    if (!_orderChanged) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order unchanged'), backgroundColor: Colors.orangeAccent));
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final result = await _pdfService.reorderPages(_pdfPath!, _currentOrder, 'reorder_$timestamp');
      if (mounted) {
        showSpeedReceipt(context, operation: 'Pages reordered', elapsedMs: result.elapsedMs, fileSize: result.formattedSize);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reorder failed: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Reorder Pages', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: const [OfflineIndicator(), SizedBox(width: 12)],
      ),
      body: _pdfPath == null
          ? Center(child: GestureDetector(onTap: _pickFile, child: Container(
              padding: const EdgeInsets.all(40), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primary.withAlpha(60))),
              child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.upload_file_rounded, color: AppTheme.primary, size: 48), SizedBox(height: 12), Text('Select PDF', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16))]))))
          : Column(children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
                const Icon(Icons.picture_as_pdf, color: AppTheme.primary), const SizedBox(width: 8),
                Expanded(child: Text(_pdfName ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Text('$_pageCount pages', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ])),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Drag to reorder pages', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
              const SizedBox(height: 8),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _currentOrder.length,
                  onReorder: (old, newIdx) {
                    setState(() {
                      if (newIdx > old) newIdx--;
                      final item = _currentOrder.removeAt(old);
                      _currentOrder.insert(newIdx, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final originalPage = _currentOrder[index];
                    return Container(
                      key: ValueKey('page_$originalPage'),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: SizedBox(
                          width: 50, height: 65,
                          child: FutureBuilder<Uint8List?>(
                            future: PageThumbnailService().getThumbnail(_pdfPath!, originalPage, width: 80),
                            builder: (ctx, snap) => snap.hasData && snap.data != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.memory(snap.data!, fit: BoxFit.cover))
                                : Container(decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(4)), child: Center(child: Text('${originalPage + 1}', style: const TextStyle(color: AppTheme.textSecondary)))),
                          ),
                        ),
                        title: Text('Page ${originalPage + 1}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                        subtitle: Text('Position ${index + 1}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        trailing: const Icon(Icons.drag_handle, color: AppTheme.textSecondary),
                      ),
                    );
                  },
                ),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), child: SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
                onPressed: _isProcessing ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isProcessing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : const Text('Save Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              ))),
            ]),
    );
  }
}
