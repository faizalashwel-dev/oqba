import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/bundle_model.dart';
import '../services/bundle_service.dart';
import '../services/save_service.dart';

/// Displays all files within a bundle in a grid layout.
class BundleViewerPage extends StatelessWidget {
  final BundleModel bundle;
  const BundleViewerPage({super.key, required this.bundle});

  @override
  Widget build(BuildContext context) {
    final saveService = SaveService();

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: Text(bundle.name, style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.txtPrimary(context), fontSize: 16)),
        actions: [
          // Save all to device
          IconButton(
            icon: Icon(Icons.download_rounded, color: AppTheme.primary),
            tooltip: 'Save All to Device',
            onPressed: () async {
              final isImage = bundle.filePaths.isNotEmpty &&
                  (bundle.filePaths.first.endsWith('.png') || bundle.filePaths.first.endsWith('.jpg'));

              if (isImage) {
                final saved = await saveService.saveAllImagesToGallery(bundle.filePaths);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Saved $saved images to Gallery!'),
                    backgroundColor: AppTheme.primary,
                  ));
                }
              } else {
                int saved = 0;
                for (final path in bundle.filePaths) {
                  final result = await saveService.savePdfToDownloads(path);
                  if (result != null) saved++;
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Saved $saved files to Downloads!'),
                    backgroundColor: AppTheme.primary,
                  ));
                }
              }
            },
          ),
          // Delete bundle
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Delete Bundle',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surf(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text('Delete Bundle', style: TextStyle(color: AppTheme.txtPrimary(context))),
                  content: Text('Delete "${bundle.name}" and all its files?', style: TextStyle(color: AppTheme.subtleText(context))),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await BundleService().deleteBundle(bundle.id);
                Navigator.pop(context, true); // Signal parent to refresh
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Icon(Icons.folder_rounded, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('${bundle.fileCount} items', style: TextStyle(color: AppTheme.subtleText(context), fontSize: 13)),
                  const Spacer(),
                  Text(bundle.formattedSize, style: TextStyle(color: AppTheme.subtleText(context), fontSize: 13)),
                ],
              ),
            ),

            // File grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: bundle.filePaths.length,
                itemBuilder: (ctx, i) {
                  final path = bundle.filePaths[i];
                  final file = File(path);
                  final isImage = path.endsWith('.png') || path.endsWith('.jpg') || path.endsWith('.jpeg');

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: isImage && file.existsSync()
                            ? Image.file(file, fit: BoxFit.cover)
                            : Container(
                                color: AppTheme.surf(context),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.insert_drive_file, color: AppTheme.primary, size: 28),
                                    const SizedBox(height: 4),
                                    Text(path.split('/').last, style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 8), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                      ),
                      // Save & Share buttons
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (isImage) {
                                  final ok = await saveService.saveImageToGallery(path);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(ok ? 'Saved to Gallery!' : 'Save failed'), backgroundColor: ok ? AppTheme.primary : Colors.redAccent));
                                  }
                                } else {
                                  final out = await saveService.savePdfToDownloads(path);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(out != null ? 'Saved to Downloads!' : 'Save failed'), backgroundColor: out != null ? AppTheme.primary : Colors.redAccent));
                                  }
                                }
                              },
                              child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle), child: Icon(Icons.download_rounded, size: 12, color: Colors.white)),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => SharePlus.instance.share(ShareParams(files: [XFile(path)])),
                              child: Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: AppTheme.surf(context), shape: BoxShape.circle), child: Icon(Icons.share, size: 12, color: AppTheme.txtPrimary(context))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
