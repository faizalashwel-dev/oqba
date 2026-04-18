import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'organize/split_page.dart';
import 'organize/extract_pages_page.dart';
import 'organize/reorder_pages_page.dart';
import 'organize/delete_pages_page.dart';
import 'organize/rotate_pages_page.dart';
import 'convert/pdf_to_images_page.dart';
import 'convert/images_to_pdf_page.dart';
import 'convert/ocr_page.dart';
import 'extract_optimize/extract_images_page.dart';
import 'extract_optimize/extract_text_page.dart';
import 'extract_optimize/compress_page.dart';
import 'security/security_page.dart';

class ToolsPage extends StatelessWidget {
  final VoidCallback? onMergeTap;

  const ToolsPage({super.key, this.onMergeTap});

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

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
              Text(
                'Oqba PDF Tools Suite',
                style: TextStyle(
                  color: AppTheme.txtPrimary(context),
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

          // Tools grid
          Expanded(
            child: ListView(
              children: [
                // ═══════════════════════════════════════
                // ORGANIZE PDF
                // ═══════════════════════════════════════
                const _SectionHeader(title: 'Organize PDF'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _ToolCard(
                    icon: Icons.merge_rounded,
                    title: 'Merge PDF',
                    description: 'Combine multiple files into one',
                    onTap: onMergeTap,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ToolCard(
                    icon: Icons.content_cut_rounded,
                    title: 'Split PDF',
                    description: 'Split into smaller files',
                    onTap: () => _push(context, const SplitPage()),
                  )),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _ToolCard(
                    icon: Icons.file_copy_rounded,
                    title: 'Extract Pages',
                    description: 'Extract pages to new PDF',
                    onTap: () => _push(context, const ExtractPagesPage()),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ToolCard(
                    icon: Icons.swap_vert_rounded,
                    title: 'Reorder Pages',
                    description: 'Change page order',
                    onTap: () => _push(context, const ReorderPagesPage()),
                  )),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _ToolCard(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete Pages',
                    description: 'Remove unwanted pages',
                    onTap: () => _push(context, const DeletePagesPage()),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ToolCard(
                    icon: Icons.rotate_right_rounded,
                    title: 'Rotate Pages',
                    description: 'Rotate PDF pages',
                    onTap: () => _push(context, const RotatePagesPage()),
                  )),
                ]),

                // ═══════════════════════════════════════
                // CONVERT
                // ═══════════════════════════════════════
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Convert'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _ToolCard(
                    icon: Icons.image_rounded,
                    title: 'PDF to Images',
                    description: 'Convert pages to images',
                    onTap: () => _push(context, const PdfToImagesPage()),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ToolCard(
                    icon: Icons.photo_library_rounded,
                    title: 'Images to PDF',
                    description: 'Combine images into PDF',
                    onTap: () => _push(context, const ImagesToPdfPage()),
                  )),
                ]),
                const SizedBox(height: 10),
                _ToolCard(
                  icon: Icons.text_snippet_rounded,
                  title: 'Images to Text (OCR)',
                  description: 'Extract text from images using on-device AI.',
                  fullWidth: true,
                  onTap: () => _push(context, const OcrPage()),
                ),

                // ═══════════════════════════════════════
                // EXTRACT & OPTIMIZE
                // ═══════════════════════════════════════
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Extract & Optimize'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _ToolCard(
                    icon: Icons.image_search_rounded,
                    title: 'Extract Images',
                    description: 'Pull embedded images',
                    onTap: () => _push(context, const ExtractImagesPage()),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ToolCard(
                    icon: Icons.text_fields_rounded,
                    title: 'Extract Text',
                    description: 'Get text from PDF',
                    onTap: () => _push(context, const ExtractTextPage()),
                  )),
                ]),
                const SizedBox(height: 10),
                _ToolCard(
                  icon: Icons.compress_rounded,
                  title: 'Compress PDF',
                  description: 'Reduce file size while keeping quality.',
                  fullWidth: true,
                  onTap: () => _push(context, const CompressPage()),
                ),

                // ═══════════════════════════════════════
                // SECURITY
                // ═══════════════════════════════════════
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Security'),
                const SizedBox(height: 10),
                _ToolCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'PDF Security',
                  description: 'Sign, watermark, protect & unlock PDFs.',
                  fullWidth: true,
                  onTap: () => _push(context, const SecurityPage()),
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
      style: TextStyle(
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
  final bool fullWidth;
  final VoidCallback? onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    this.fullWidth = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surf(context).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.txtPrimary(context),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: TextStyle(
                color: AppTheme.subtleText(context),
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
