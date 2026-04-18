import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/convert_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';

class ImagesToPdfPage extends StatefulWidget {
  const ImagesToPdfPage({super.key});
  @override
  State<ImagesToPdfPage> createState() => _ImagesToPdfPageState();
}

class _ImagesToPdfPageState extends State<ImagesToPdfPage> {
  final ConvertService _convertService = ConvertService();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];
  final TextEditingController _nameController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = 'images_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _addImages() async {
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) setState(() => _images.addAll(images));
  }

  Future<void> _create() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one image'), backgroundColor: Colors.orangeAccent));
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final paths = _images.map((x) => x.path).toList();
      final result = await _convertService.imagesToPdf(paths, outputName: _nameController.text.trim().isEmpty ? 'images_${DateTime.now().millisecondsSinceEpoch}' : _nameController.text.trim());
      if (mounted) {
        showSpeedReceipt(context, operation: 'Created PDF from ${_images.length} images', elapsedMs: result.elapsedMs, fileSize: result.formattedSize);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(title: Text('Images to PDF', style: TextStyle(fontWeight: FontWeight.w700)), actions: const [OfflineIndicator(), SizedBox(width: 12)]),
      body: SafeArea(child: Column(children: [
        // Add images button
        Padding(padding: const EdgeInsets.all(16), child: GestureDetector(onTap: _isProcessing ? null : _addImages, child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withGreen(200)]), borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, color: Colors.white), SizedBox(width: 8), Text('Add Images', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))]),
        ))),
        if (_images.length > 50)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orangeAccent.withAlpha(30), borderRadius: BorderRadius.circular(8)),
            child: Text('Large number of images may take longer', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)))),
        // Image list
        Expanded(child: _images.isEmpty
            ? Center(child: Text('Tap "Add Images" to select photos', style: TextStyle(color: AppTheme.txtSecondary(context).withAlpha(120))))
            : ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _images.length,
                onReorder: (old, newIdx) { setState(() { if (newIdx > old) newIdx--; final item = _images.removeAt(old); _images.insert(newIdx, item); }); },
                itemBuilder: (ctx, i) => Container(
                  key: ValueKey('img_${_images[i].path}_$i'),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: AppTheme.surf(context), borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.file(File(_images[i].path), width: 50, height: 50, fit: BoxFit.cover)),
                    title: Text(_images[i].name, style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 13), overflow: TextOverflow.ellipsis),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      GestureDetector(onTap: () => setState(() => _images.removeAt(i)), child: Icon(Icons.drag_indicator_rounded, color: AppTheme.txtSecondary(context), size: 18)),
                      const SizedBox(width: 8), Icon(Icons.drag_indicator_rounded, color: AppTheme.txtSecondary(context)),
                    ]),
                  ),
                ),
              )),
        // PDF name + create button
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: TextField(
          controller: _nameController, style: TextStyle(color: AppTheme.txtPrimary(context)),
          decoration: InputDecoration(hintText: 'PDF filename', hintStyle: TextStyle(color: AppTheme.txtSecondary(context).withAlpha(120)), filled: true, fillColor: AppTheme.surf(context), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: Icon(Icons.edit, color: AppTheme.primary)),
        )),
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), child: SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
          onPressed: _images.isEmpty || _isProcessing ? null : _create,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, disabledBackgroundColor: AppTheme.surf(context), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: _isProcessing
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
              : Text('Create PDF (${_images.length} images)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        ))),
      ])),
    );
  }

  @override
  void dispose() { _nameController.dispose(); super.dispose(); }
}
