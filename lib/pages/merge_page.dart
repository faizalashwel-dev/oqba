import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/pdf_service.dart';
import '../services/file_service.dart';
import 'package:file_picker/file_picker.dart';

class MergePage extends StatefulWidget {
  const MergePage({super.key});

  @override
  State<MergePage> createState() => _MergePageState();
}

class _MergePageState extends State<MergePage> {
  final PdfService _pdfService = PdfService();
  final FileService _fileService = FileService();
  final List<_SelectedFile> _selectedFiles = [];
  bool _isMerging = false;

  Future<void> _addFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      for (final file in result.files) {
        if (file.path == null) continue;

        // Validate it's actually a PDF before adding
        final f = File(file.path!);
        if (!f.existsSync()) continue;

        // Import to internal directory first (path sanitization)
        try {
          final importedPath = await _fileService.importFile(file.path!);
          final stat = f.statSync();

          setState(() {
            _selectedFiles.add(_SelectedFile(
              name: file.name,
              path: importedPath,
              size: FileService.formatFileSize(stat.size),
            ));
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid PDF: ${file.name}'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        }
      }
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  Future<void> _mergeFiles() async {
    if (_selectedFiles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least 2 PDF files to merge'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isMerging = true);

    try {
      final paths = _selectedFiles.map((f) => f.path).toList();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Merge runs in background Isolate via compute()
      final result = await _pdfService.mergePdfs(
        paths,
        'merged_$timestamp',
      );

      if (mounted) {
        Navigator.pop(context, {
          'operation': 'Merged ${_selectedFiles.length} files',
          'elapsedMs': result.elapsedMs,
          'fileSize': result.formattedSize,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Merge failed: $e'),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _mergeFiles,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isMerging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: AppTheme.textPrimary, size: 30),
                  ),
                  const Expanded(
                    child: Text(
                      'Oqba Merge PDF Tool',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Add More button
                    GestureDetector(
                      onTap: _isMerging ? null : _addFiles,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary,
                              AppTheme.primary.withGreen(200),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline_rounded,
                                color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Add Files',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // File list
                    Expanded(
                      child: _selectedFiles.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.merge_rounded,
                                    size: 48,
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tap "Add Files" to select PDFs to merge',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ReorderableListView.builder(
                              itemCount: _selectedFiles.length,
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) newIndex--;
                                  final item =
                                      _selectedFiles.removeAt(oldIndex);
                                  _selectedFiles.insert(newIndex, item);
                                });
                              },
                              itemBuilder: (context, index) {
                                final file = _selectedFiles[index];
                                return Container(
                                  key: ValueKey('${file.path}_$index'),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(18),
                                    border: const Border(
                                      left: BorderSide(
                                          color: AppTheme.primary, width: 4),
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 6),
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            AppTheme.primary.withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      file.name,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      file.size,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.35),
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _removeFile(index),
                                          child: Icon(
                                              Icons.close_rounded,
                                              color: Colors.white
                                                  .withValues(alpha: 0.25),
                                              size: 20),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.drag_handle_rounded,
                                            color:
                                                Colors.white.withValues(alpha: 0.2)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Merge Button
            if (_selectedFiles.length >= 2)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: GestureDetector(
                  onTap: _isMerging ? null : _mergeFiles,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isMerging
                            ? [Colors.grey, Colors.grey.shade600]
                            : [
                                AppTheme.primary,
                                AppTheme.primary.withGreen(200),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isMerging
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Merging...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Merge ${_selectedFiles.length} Files',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectedFile {
  final String name;
  final String path;
  final String size;

  _SelectedFile({
    required this.name,
    required this.path,
    required this.size,
  });
}
