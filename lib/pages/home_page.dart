import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/file_service.dart';
import '../models/pdf_file_model.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/skeleton_loader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onRefresh;

  const HomePage({super.key, this.onRefresh});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final FileService _fileService = FileService();
  List<PdfFileModel> _files = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future<void> loadFiles() async {
    setState(() => _isLoading = true);
    final files = await _fileService.listDocuments();
    if (mounted) {
      setState(() {
        _files = files;
        _isLoading = false;
      });
    }
  }

  List<PdfFileModel> get _filteredFiles {
    if (_searchQuery.isEmpty) return _files;
    return _files
        .where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _importFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      int imported = 0;
      for (final file in result.files) {
        if (file.path != null) {
          try {
            await _fileService.importFile(file.path!);
            imported++;
          } catch (_) {}
        }
      }
      await loadFiles();
      if (mounted && imported > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $imported file${imported > 1 ? 's' : ''}'),
            backgroundColor: AppTheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openPdf(PdfFileModel file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PdfViewerScreen(file: file),
      ),
    );
  }

  Future<void> _shareFile(PdfFileModel file) async {
    final xFile = XFile(file.path);
    await SharePlus.instance.share(
      ShareParams(files: [xFile]),
    );
  }

  Future<void> _deleteFile(PdfFileModel file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete File',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Delete "${file.name}"?\nThis action cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _fileService.deleteDocument(file.path);
      await loadFiles();
    }
  }

  Future<void> _renameFile(PdfFileModel file) async {
    final controller = TextEditingController(
      text: file.name.replaceAll('.pdf', ''),
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rename File',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            suffixText: '.pdf',
            suffixStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await _fileService.renameDocument(file.path, newName);
      await loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Files',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  const OfflineIndicator(),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() => _isSearching = !_isSearching);
                      if (!_isSearching) {
                        setState(() => _searchQuery = '');
                      }
                    },
                    child: Icon(
                      _isSearching
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      color: _isSearching
                          ? AppTheme.primary
                          : Colors.white.withValues(alpha: 0.4),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: _importFiles,
                    child: Icon(Icons.add_circle_outline_rounded,
                        color: Colors.white.withValues(alpha: 0.4), size: 24),
                  ),
                ],
              ),
            ],
          ),

          // Search bar (animated)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isSearching
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      autofocus: true,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search files...',
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25)),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: Colors.white.withValues(alpha: 0.3)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // File count badge
          if (!_isLoading && _files.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${_filteredFiles.length} document${_filteredFiles.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Content
          Expanded(
            child: _isLoading
                ? const SkeletonLoader()
                : _files.isEmpty
                    ? _buildEmptyState()
                    : _filteredFiles.isEmpty
                        ? _buildNoResults()
                        : _buildFileList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(
            'No files matching "$_searchQuery"',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Document icon with "?"
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 52,
                  color: AppTheme.primary.withValues(alpha: 0.6),
                ),
                Positioned(
                  bottom: 20,
                  right: 24,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.question_mark_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Files Yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You don't have any files here. Use the scanner\nor tools to create or import files – they'll\nshow up once added.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _importFiles,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                shadowColor: AppTheme.primary.withValues(alpha: 0.3),
              ),
              child: const Text(
                'Import Files',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    final files = _filteredFiles;
    return RefreshIndicator(
      onRefresh: loadFiles,
      color: AppTheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return Dismissible(
            key: ValueKey(file.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  const Icon(Icons.delete_rounded, color: Colors.redAccent),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.surface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Delete File',
                          style: TextStyle(color: AppTheme.textPrimary)),
                      content: Text('Delete "${file.name}"?',
                          style:
                              const TextStyle(color: AppTheme.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  ) ??
                  false;
            },
            onDismissed: (_) {
              _fileService.deleteDocument(file.path);
              setState(() => _files.removeWhere((f) => f.id == file.id));
            },
            child: GestureDetector(
              onTap: () => _openPdf(file),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: const Border(
                    left: BorderSide(color: AppTheme.primary, width: 4),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded,
                        color: AppTheme.primary, size: 24),
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
                    '${file.formattedSize} · ${_formatDate(file.createdAt)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: Colors.white.withValues(alpha: 0.3)),
                    color: AppTheme.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    onSelected: (action) {
                      switch (action) {
                        case 'open':
                          _openPdf(file);
                          break;
                        case 'share':
                          _shareFile(file);
                          break;
                        case 'rename':
                          _renameFile(file);
                          break;
                        case 'delete':
                          _deleteFile(file);
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_rounded,
                                color: AppTheme.primary, size: 20),
                            SizedBox(width: 8),
                            Text('Open',
                                style:
                                    TextStyle(color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share_rounded,
                                color: AppTheme.textPrimary, size: 20),
                            SizedBox(width: 8),
                            Text('Share',
                                style:
                                    TextStyle(color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded,
                                color: AppTheme.textPrimary, size: 20),
                            SizedBox(width: 8),
                            Text('Rename',
                                style:
                                    TextStyle(color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 20),
                            SizedBox(width: 8),
                            Text('Delete',
                                style:
                                    TextStyle(color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Full-screen PDF viewer with share action.
class _PdfViewerScreen extends StatelessWidget {
  final PdfFileModel file;
  const _PdfViewerScreen({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          file.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppTheme.textPrimary),
            onPressed: () async {
              final xFile = XFile(file.path);
              await SharePlus.instance.share(
                ShareParams(files: [xFile]),
              );
            },
          ),
        ],
      ),
      body: SfPdfViewer.file(
        File(file.path),
        canShowScrollHead: true,
        pageSpacing: 4,
      ),
    );
  }
}
