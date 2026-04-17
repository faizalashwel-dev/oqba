import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ToolsPage extends StatelessWidget {
  final VoidCallback? onMergeTap;

  const ToolsPage({super.key, this.onMergeTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                'Oqba PDF Tools Suite',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 4),
          Container(height: 2, color: AppTheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 20),

          // Tools list
          Expanded(
            child: ListView(
              children: [
                _SectionHeader(title: 'Organize PDF'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ToolCard(
                        icon: Icons.merge_rounded,
                        title: 'Merge PDF',
                        description: 'Combine multiple files into one document',
                        onTap: onMergeTap,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ToolCard(
                        icon: Icons.content_cut_rounded,
                        title: 'Split PDF',
                        description: 'Split PDF into smaller files',
                        isComingSoon: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ToolCard(
                        icon: Icons.file_copy_rounded,
                        title: 'Extract Pages',
                        description: 'Extract pages into a new PDF',
                        isComingSoon: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ToolCard(
                        icon: Icons.swap_vert_rounded,
                        title: 'Reorder Pages',
                        description: 'Change the order of pages in your PDF',
                        isComingSoon: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ToolCard(
                        icon: Icons.delete_outline_rounded,
                        title: 'Delete Pages',
                        description: 'Delete unwanted pages from your PDF',
                        isComingSoon: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ToolCard(
                        icon: Icons.rotate_right_rounded,
                        title: 'Rotate Pages',
                        description: 'Rotate your PDF pages',
                        isComingSoon: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
                _SectionHeader(title: 'Convert'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ToolCard(
                        icon: Icons.image_rounded,
                        title: 'PDF to Images',
                        description: 'Convert PDF pages into high-quality images',
                        isComingSoon: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ToolCard(
                        icon: Icons.photo_library_rounded,
                        title: 'Images to PDF',
                        description: 'Combine multiple images into a single PDF',
                        isComingSoon: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ToolCard(
                  icon: Icons.text_snippet_rounded,
                  title: 'Images to Text (OCR)',
                  description: 'Extract and copy text from images using OCR.',
                  isPro: true,
                  isComingSoon: true,
                  fullWidth: true,
                ),

                const SizedBox(height: 28),
                _SectionHeader(title: 'Extract & Optimize'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ToolCard(
                        icon: Icons.image_search_rounded,
                        title: 'Extract Images',
                        description: 'Extract all embedded images from your PDF',
                        isComingSoon: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ToolCard(
                        icon: Icons.text_fields_rounded,
                        title: 'Extract Text',
                        description: 'Convert your PDF content into editable text',
                        isComingSoon: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ToolCard(
                  icon: Icons.compress_rounded,
                  title: 'Compress PDF',
                  description: 'Reduce your PDF file size while keeping good quality.',
                  isPro: true,
                  isComingSoon: true,
                  fullWidth: true,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.primary,
        fontWeight: FontWeight.w700,
        fontSize: 17,
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isPro;
  final bool isComingSoon;
  final bool fullWidth;
  final VoidCallback? onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    this.isPro = false,
    this.isComingSoon = false,
    this.fullWidth = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isComingSoon ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isComingSoon ? 0.45 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isComingSoon
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppTheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isComingSoon
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon,
                        color: isComingSoon
                            ? Colors.white.withValues(alpha: 0.3)
                            : AppTheme.primary,
                        size: 22),
                  ),
                  if (isPro)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  if (isComingSoon && !isPro)
                    Text(
                      'Soon',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  color: isComingSoon
                      ? Colors.white.withValues(alpha: 0.4)
                      : AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: isComingSoon ? 0.2 : 0.4),
                  fontSize: 11,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
