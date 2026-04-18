import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
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

  // Split mode: 0 = By Range, 1 = Every N, 2 = From-to, 3 = Split Half
  int _splitMode = 0;
  
  // Controllers & State
  final TextEditingController _rangeController = TextEditingController();
  int _everyN = 1;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  // Results State
  List<String>? _generatedChunks;
  final Set<int> _selectedChunkIndices = {};

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      try {
        final importedPath = await _fileService.importFile(result.files.single.path!);
        final count = await PageThumbnailService().getPageCount(importedPath);
        setState(() {
          _pdfPath = importedPath;
          _pdfName = result.files.single.name;
          _pageCount = count;
          _generatedChunks = null;
          _selectedChunkIndices.clear();
          _everyN = 1;
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
  
  List<List<int>>? _parseFromTo() {
    final start = int.tryParse(_fromController.text.trim());
    final end = int.tryParse(_toController.text.trim());
    if (start == null || end == null || start < 1 || end < start || end > _pageCount) return null;
    return [[start - 1, end - 1]];
  }

  List<List<int>> _generateHalfRanges() {
    if (_pageCount <= 1) return [[0, 0]];
    final mid = (_pageCount / 2).ceil();
    return [
      [0, mid - 1], // First half
      [mid, _pageCount - 1] // Second half
    ];
  }

  Future<void> _split() async {
    if (_pdfPath == null) return;

    final List<List<int>> ranges;
    if (_splitMode == 0) {
      final parsed = _parseRanges();
      if (parsed == null || parsed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid range format. Use: 1-3, 4-6'), backgroundColor: Colors.orangeAccent));
        return;
      }
      ranges = parsed;
    } else if (_splitMode == 1) {
      ranges = _generateEveryNRanges();
    } else if (_splitMode == 2) {
      final parsed = _parseFromTo();
      if (parsed == null || parsed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid From-To pages.'), backgroundColor: Colors.orangeAccent));
        return;
      }
      ranges = parsed;
    } else {
      ranges = _generateHalfRanges();
    }

    setState(() => _isProcessing = true);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Output chunks to AppDocuments/Oqba/temp/ instead of persistent documents.
      final outputPaths = await _pdfService.splitPdfTemp(_pdfPath!, ranges, 'split_${timestamp}');
      
      setState(() {
        _generatedChunks = outputPaths;
        // Select all by default
        _selectedChunkIndices.addAll(List.generate(outputPaths.length, (i) => i));
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Split failed: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveSelected() async {
    if (_generatedChunks == null) return;
    
    // Check if at least 1 is selected
    if (_selectedChunkIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one chunk to save.'), backgroundColor: Colors.orangeAccent));
      return;
    }
    
    setState(() => _isProcessing = true);
    final startTime = DateTime.now();
    int savedBytes = 0;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final docDir = Directory('${appDir.path}/Oqba/documents');
      
      for (int i = 0; i < _generatedChunks!.length; i++) {
        final file = File(_generatedChunks![i]);
        if (!file.existsSync()) continue;
        
        if (_selectedChunkIndices.contains(i)) {
          // Move from temp to documents
          final baseName = file.uri.pathSegments.last;
          final newPath = '${docDir.path}/$baseName';
          file.renameSync(newPath);
          savedBytes += File(newPath).lengthSync();
        } else {
          // Delete discarded chunks
          file.deleteSync();
        }
      }
      
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (mounted) {
        showSpeedReceipt(context, operation: 'Saved ${_selectedChunkIndices.length} sections', elapsedMs: elapsed, fileSize: _formatSize(savedBytes));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
  
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: Text('Split PDF', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: const [OfflineIndicator(), SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: _generatedChunks != null ? _buildResults() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
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
                color: AppTheme.surf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withAlpha(60)),
              ),
              child: _pdfPath == null
                  ? Column(
                      children: [
                        Icon(Icons.upload_file_rounded, color: AppTheme.primary, size: 40),
                        SizedBox(height: 8),
                        Text('Select PDF', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600)),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: AppTheme.primary, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_pdfName ?? '', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                              Text('$_pageCount pages', style: TextStyle(color: AppTheme.txtSecondary(context), fontSize: 12)),
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Range')),
                  ButtonSegment(value: 1, label: Text('Every N')),
                  ButtonSegment(value: 2, label: Text('From-To')),
                  ButtonSegment(value: 3, label: Text('Half')),
                ],
                selected: {_splitMode},
                onSelectionChanged: (s) => setState(() => _splitMode = s.first),
                style: SegmentedButton.styleFrom(
                  backgroundColor: AppTheme.surf(context),
                  foregroundColor: AppTheme.txtPrimary(context),
                  selectedBackgroundColor: AppTheme.primary,
                  selectedForegroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_splitMode == 0)
              TextField(
                controller: _rangeController,
                style: TextStyle(color: AppTheme.txtPrimary(context)),
                decoration: InputDecoration(
                  hintText: '1-3, 4-6, 7-$_pageCount',
                  hintStyle: TextStyle(color: AppTheme.txtSecondary(context).withAlpha(120)),
                  filled: true,
                  fillColor: AppTheme.surf(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.splitscreen, color: AppTheme.primary),
                ),
              ),

            if (_splitMode == 1)
              Row(
                children: [
                  Text('Split every', style: TextStyle(color: AppTheme.txtPrimary(context))),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _everyN > 1 ? () => setState(() => _everyN--) : null,
                    icon: Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.surf(context), borderRadius: BorderRadius.circular(8)),
                    child: Text('$_everyN', style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: _everyN < _pageCount ? () => setState(() => _everyN++) : null,
                    icon: Icon(Icons.add_circle_outline, color: AppTheme.primary),
                  ),
                  Text('pages', style: TextStyle(color: AppTheme.txtPrimary(context))),
                ],
              ),
              
            if (_splitMode == 2)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fromController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppTheme.txtPrimary(context)),
                      decoration: InputDecoration(
                        labelText: 'From Page',
                        labelStyle: TextStyle(color: AppTheme.txtSecondary(context).withAlpha(120)),
                        filled: true,
                        fillColor: AppTheme.surf(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _toController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppTheme.txtPrimary(context)),
                      decoration: InputDecoration(
                        labelText: 'To Page',
                        labelStyle: TextStyle(color: AppTheme.txtSecondary(context).withAlpha(120)),
                        filled: true,
                        fillColor: AppTheme.surf(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              
            if (_splitMode == 3)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.surf(context), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.pie_chart_outline, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text('Automatically cuts the PDF exactly in double generating two distinct files.', style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 13))),
                  ]
                )
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
                    ? Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)), SizedBox(width: 12), Text('Slicing sections...', style: TextStyle(color: Colors.white))])
                    : Text('Review Split Sections', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Generated ${_generatedChunks!.length} sections', style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 18, fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedChunkIndices.length == _generatedChunks!.length) {
                      _selectedChunkIndices.clear();
                    } else {
                      _selectedChunkIndices.addAll(List.generate(_generatedChunks!.length, (i) => i));
                    }
                  });
                },
                child: Text(
                  _selectedChunkIndices.length == _generatedChunks!.length ? 'Deselect All' : 'Select All',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)
                )
              )
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _generatedChunks!.length,
            itemBuilder: (ctx, i) {
              final file = File(_generatedChunks![i]);
              final isSelected = _selectedChunkIndices.contains(i);
              final sizeStr = file.existsSync() ? _formatSize(file.lengthSync()) : 'Unknown';
              final baseName = file.uri.pathSegments.last;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary.withAlpha(20) : AppTheme.surf(context),
                  border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: CheckboxListTile(
                  value: isSelected,
                  activeColor: AppTheme.primary,
                  checkColor: Colors.white,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) _selectedChunkIndices.add(i);
                      else _selectedChunkIndices.remove(i);
                    });
                  },
                  secondary: Icon(Icons.picture_as_pdf, color: AppTheme.primary, size: 36),
                  title: Text('Section ${i + 1}', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600)),
                  subtitle: Text('$baseName\n$sizeStr', style: TextStyle(color: AppTheme.txtSecondary(context), fontSize: 12)),
                  isThreeLine: true,
                ),
              );
            }
          )
        ),
        
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedChunkIndices.isEmpty || _isProcessing ? null : _saveSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    disabledBackgroundColor: AppTheme.surf(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                      : Text('Save Selected (${_selectedChunkIndices.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _isProcessing ? null : () {
                    // Cleanup unselected/aborted chunks
                    for (final path in _generatedChunks!) {
                      final f = File(path);
                      if (f.existsSync()) f.deleteSync();
                    }
                    setState(() => _generatedChunks = null);
                  },
                  child: Text('Cancel & Start Over', style: TextStyle(color: AppTheme.txtSecondary(context), fontSize: 15)),
                )
              )
            ],
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    _rangeController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }
}
