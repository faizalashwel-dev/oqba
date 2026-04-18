import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/page_thumbnail_service.dart';
import '../theme/app_theme.dart';

/// Reusable multi-select grid of PDF page thumbnails.
///
/// Used by: extract_pages, delete_pages, rotate_pages.
/// The reorder page uses its own ReorderableListView variant.
///
/// Features:
/// - GridView.builder with crossAxisCount: 3
/// - Thumbnails via FutureBuilder → PageThumbnailService
/// - Loading: shimmer/skeleton placeholder
/// - Error: grey box with page number centered
/// - Selected: green border + checkmark overlay
/// - "Select All / Deselect All" via [selectAll] / [deselectAll]
class PageSelectorGrid extends StatefulWidget {
  final String pdfPath;
  final int pageCount;
  final bool multiSelect;
  final void Function(List<int> selectedIndices) onSelectionChanged;

  /// Optional rotation preview: pageIndex → degrees (0/90/180/270).
  /// Used by rotate_pages to show rotation preview overlays.
  final Map<int, int>? rotationOverrides;

  const PageSelectorGrid({
    super.key,
    required this.pdfPath,
    required this.pageCount,
    this.multiSelect = true,
    required this.onSelectionChanged,
    this.rotationOverrides,
  });

  @override
  State<PageSelectorGrid> createState() => PageSelectorGridState();
}

class PageSelectorGridState extends State<PageSelectorGrid> {
  final Set<int> _selectedIndices = {};

  // ── Public API for parent widgets (AppBar actions) ─────
  List<int> get selectedIndices => _selectedIndices.toList()..sort();

  void selectAll() {
    setState(() {
      _selectedIndices.clear();
      _selectedIndices.addAll(List.generate(widget.pageCount, (i) => i));
    });
    widget.onSelectionChanged(selectedIndices);
  }

  void deselectAll() {
    setState(() => _selectedIndices.clear());
    widget.onSelectionChanged(selectedIndices);
  }
  // ───────────────────────────────────────────────────────

  void _toggleSelection(int index) {
    setState(() {
      if (!widget.multiSelect) {
        _selectedIndices.clear();
        _selectedIndices.add(index);
      } else {
        if (_selectedIndices.contains(index)) {
          _selectedIndices.remove(index);
        } else {
          _selectedIndices.add(index);
        }
      }
    });
    widget.onSelectionChanged(selectedIndices);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: widget.pageCount,
      itemBuilder: (context, index) {
        final isSelected = _selectedIndices.contains(index);
        final rotation = widget.rotationOverrides?[index] ?? 0;

        return GestureDetector(
          onTap: () => _toggleSelection(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppTheme.surf(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.surf(context).withAlpha(80),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(40),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Thumbnail ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: _buildThumbnail(index, rotation),
                ),

                // ── Page Number Badge (bottom-right) ──
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.bg(context).withAlpha(200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: AppTheme.txtPrimary(context),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),

                // ── Rotation Badge Overlay (top-left) ──
                if (rotation != 0)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.premium.withAlpha(200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$rotation°',
                        style: TextStyle(
                          color: AppTheme.bg(context),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // ── Selected Checkmark Overlay (top-right) ──
                if (isSelected && widget.multiSelect)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(int index, int rotation) {
    return FutureBuilder<Uint8List?>(
      future: PageThumbnailService()
          .getThumbnail(widget.pdfPath, index, width: 150),
      builder: (context, snapshot) {
        // ── Loading: skeleton shimmer ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _SkeletonThumbnail(pageNumber: index + 1);
        }

        // ── Error: grey box with page number ──
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data == null) {
          return Container(
            color: AppTheme.surf(context),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insert_drive_file_outlined,
                      color: AppTheme.txtSecondary(context).withAlpha(100),
                      size: 28),
                  const SizedBox(height: 4),
                  Text(
                    'Page ${index + 1}',
                    style: TextStyle(
                      color: AppTheme.txtSecondary(context).withAlpha(150),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ── Success: render thumbnail ──
        Widget img = Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
        );

        // Apply rotation preview if set
        if (rotation != 0) {
          img = RotatedBox(
            quarterTurns: rotation ~/ 90,
            child: img,
          );
        }

        return img;
      },
    );
  }
}

/// Shimmer skeleton placeholder for thumbnail cells.
class _SkeletonThumbnail extends StatefulWidget {
  final int pageNumber;
  const _SkeletonThumbnail({required this.pageNumber});

  @override
  State<_SkeletonThumbnail> createState() => _SkeletonThumbnailState();
}

class _SkeletonThumbnailState extends State<_SkeletonThumbnail>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shimmerValue = (_controller.value * 2 - 1).abs();
        final shimmerOpacity = 0.04 + 0.06 * (0.5 + 0.5 * shimmerValue);
        return Container(
          color: Colors.white.withAlpha((shimmerOpacity * 255).toInt()),
          child: Center(
            child: Text(
              '${widget.pageNumber}',
              style: TextStyle(
                color: AppTheme.txtSecondary(context).withAlpha(80),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
