import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/pdf_service.dart';
import '../../services/file_service.dart';
import '../../services/page_thumbnail_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';
import '../../widgets/page_selector_grid.dart';

class RotatePagesPage extends StatefulWidget {
  const RotatePagesPage({super.key});
  @override
  State<RotatePagesPage> createState() => _RotatePagesPageState();
}

class _RotatePagesPageState extends State<RotatePagesPage> {
  final PdfService _pdfService = PdfService();
  final FileService _fileService = FileService();
  String? _pdfPath;
  String? _pdfName;
  int _pageCount = 0;
  List<int> _selected = [];
  final Map<int, int> _rotations = {};
  int _selectedAngle = 90;
  bool _isProcessing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      try {
        final importedPath = await _fileService.importFile(result.files.single.path!);
        final count = await PageThumbnailService().getPageCount(importedPath);
        setState(() { _pdfPath = importedPath; _pdfName = result.files.single.name; _pageCount = count; _selected = []; _rotations.clear(); });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  void _rotateSelected() {
    if (_selected.isEmpty) return;
    setState(() {
      for (final idx in _selected) {
        _rotations[idx] = ((_rotations[idx] ?? 0) + _selectedAngle) % 360;
        if (_rotations[idx] == 0) _rotations.remove(idx);
      }
    });
  }

  void _rotateAll() {
    setState(() {
      for (int i = 0; i < _pageCount; i++) {
        _rotations[i] = ((_rotations[i] ?? 0) + _selectedAngle) % 360;
        if (_rotations[i] == 0) _rotations.remove(i);
      }
    });
  }

  Future<void> _save() async {
    if (_pdfPath == null || _rotations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No rotations applied'), backgroundColor: Colors.orangeAccent));
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final result = await _pdfService.rotatePages(_pdfPath!, _rotations, 'rotated_$timestamp');
      if (mounted) {
        showSpeedReceipt(context, operation: 'Rotated ${_rotations.length} pages', elapsedMs: result.elapsedMs, fileSize: result.formattedSize);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rotate failed: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Rotate Pages', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (_pdfPath != null)
            TextButton(onPressed: _rotateAll, child: const Text('Rotate All', style: TextStyle(color: AppTheme.primary))),
          const OfflineIndicator(), const SizedBox(width: 12),
        ],
      ),
      body: _pdfPath == null
          ? Center(child: GestureDetector(onTap: _pickFile, child: Container(
              padding: const EdgeInsets.all(40), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primary.withAlpha(60))),
              child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.upload_file_rounded, color: AppTheme.primary, size: 48), SizedBox(height: 12), Text('Select PDF', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16))]))))
          : Column(children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
                const Icon(Icons.picture_as_pdf, color: AppTheme.primary), const SizedBox(width: 8),
                Expanded(child: Text(_pdfName ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              ])),
              Expanded(child: PageSelectorGrid(pdfPath: _pdfPath!, pageCount: _pageCount, rotationOverrides: _rotations, onSelectionChanged: (s) => setState(() => _selected = s))),
              // Angle selector + rotate button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppTheme.surface,
                child: Row(children: [
                  Expanded(
                    child: SegmentedButton<int>(
                      segments: const [ButtonSegment(value: 90, label: Text('90°')), ButtonSegment(value: 180, label: Text('180°')), ButtonSegment(value: 270, label: Text('270°'))],
                      selected: {_selectedAngle},
                      onSelectionChanged: (s) => setState(() => _selectedAngle = s.first),
                      style: SegmentedButton.styleFrom(backgroundColor: AppTheme.background, foregroundColor: AppTheme.textPrimary, selectedBackgroundColor: AppTheme.primary, selectedForegroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _selected.isEmpty ? null : _rotateSelected,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    child: const Text('Rotate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), child: SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
                onPressed: _isProcessing ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, disabledBackgroundColor: AppTheme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isProcessing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : const Text('Save Rotations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              ))),
            ]),
    );
  }
}
