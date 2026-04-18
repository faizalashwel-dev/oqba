import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/pdf_service.dart';
import '../../services/file_service.dart';
import '../../services/page_thumbnail_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';

class SplitPage extends StatefulWidget {
  const SplitPage({super.key});
  @override
  State<SplitPage> createState() => _SplitPageState();
}

class _SplitPageState extends State<SplitPage> {
  final PdfService _pdfService = PdfService();
  final FileService _fileService = FileService();
  String? _pdfPath;
  String? _pdfName;
  int _pageCount = 0;
  bool _isProcessing = false;

  // Split mode: 0 = By Range, 1 = Every N pages
  int _splitMode = 0;
  final TextEditingController _rangeController = TextEditingController();
  int _everyN = 1;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      try {
        // RULE 1: Copy to internal dir before processing
        final importedPath = await _fileService.importFile(result.files.single.path!);
        final count = await PageThumbnailService().getPageCount(importedPath);
        setState(() {
          _pdfPath = importedPath;
          _pdfName = result.files.single.name;
          _pageCount = count;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to import: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  List<List<int>>? _parseRanges() {
    final text = _rangeController.text.trim();
    if (text.isEmpty) return null;
    final ranges = <List<int>>[];
    for (final part in text.split(',')) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        final ends = trimmed.split('-');
        if (ends.length != 2) return null;
        final start = int.tryParse(ends[0].trim());
        final end = int.tryParse(ends[1].trim());
        if (start == null || end == null || start < 1 || end < start || end > _pageCount) return null;
        ranges.add([start - 1, end - 1]); // Convert to 0-based
      } else {
        final page = int.tryParse(trimmed);
        if (page == null || page < 1 || page > _pageCount) return null;
        ranges.add([page - 1, page - 1]);
      }
    }
    return ranges;
  }

  List<List<int>> _generateEveryNRanges() {
    final ranges = <List<int>>[];
    for (int i = 0; i < _pageCount; i += _everyN) {
      final end = (i + _everyN - 1).clamp(0, _pageCount - 1);
      ranges.add([i, end]);
    }
    return ranges;
  }

  Future<void> _split() async {
    if (_pdfPath == null) return;

    final List<List<int>> ranges;
    if (_splitMode == 0) {
      final parsed = _parseRanges();
      if (parsed == null || parsed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid range format. Use: 1-3, 4-6'), backgroundColor: Colors.orangeAccent),
        );
        return;
      }
      ranges = parsed;
    } else {
      ranges = _generateEveryNRanges();
    }

    setState(() => _isProcessing = true);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final result = await _pdfService.splitPdf(_pdfPath!, ranges, 'split_$timestamp');
      if (mounted) {
        showSpeedReceipt(context, operation: 'Split into ${ranges.length} files', elapsedMs: result.elapsedMs, fileSize: result.formattedSize);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Split failed: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Split PDF', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: const [OfflineIndicator(), SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File picker
              GestureDetector(
                onTap: _isProcessing ? null : _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withAlpha(60)),
                  ),
                  child: _pdfPath == null
                      ? const Column(
                          children: [
                            Icon(Icons.upload_file_rounded, color: AppTheme.primary, size: 40),
                            SizedBox(height: 8),
                            Text('Select PDF', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                          ],
                        )
                      : Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: AppTheme.primary, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_pdfName ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                  Text('$_pageCount pages', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              if (_pdfPath != null) ...[
                // Split mode selector
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('By Range')),
                    ButtonSegment(value: 1, label: Text('Every N Pages')),
                  ],
                  selected: {_splitMode},
                  onSelectionChanged: (s) => setState(() => _splitMode = s.first),
                  style: SegmentedButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.textPrimary,
                    selectedBackgroundColor: AppTheme.primary,
                    selectedForegroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                if (_splitMode == 0)
                  TextField(
                    controller: _rangeController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: '1-3, 4-6, 7-$_pageCount',
                      hintStyle: TextStyle(color: AppTheme.textSecondary.withAlpha(120)),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.splitscreen, color: AppTheme.primary),
                    ),
                  ),

                if (_splitMode == 1)
                  Row(
                    children: [
                      const Text('Split every', style: TextStyle(color: AppTheme.textPrimary)),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _everyN > 1 ? () => setState(() => _everyN--) : null,
                        icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
                        child: Text('$_everyN', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        onPressed: _everyN < _pageCount ? () => setState(() => _everyN++) : null,
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                      ),
                      const Text('pages', style: TextStyle(color: AppTheme.textPrimary)),
                    ],
                  ),
              ],

              const Spacer(),

              if (_pdfPath != null)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _split,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isProcessing
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                        : const Text('Split PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rangeController.dispose();
    super.dispose();
  }
}
