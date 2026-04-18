import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/convert_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';
import '../../widgets/pro_gate.dart';
import '../../main.dart' show isPro;

class OcrPage extends StatefulWidget {
  const OcrPage({super.key});
  @override
  State<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> {
  final ConvertService _convertService = ConvertService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  String? _imagePath;
  bool _isProcessing = false;
  bool _hasResult = false;

  Future<void> _pickFromGallery() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() { _imagePath = img.path; _hasResult = false; _textController.clear(); });
  }

  Future<void> _pickFromCamera() async {
    final img = await _picker.pickImage(source: ImageSource.camera);
    if (img != null) setState(() { _imagePath = img.path; _hasResult = false; _textController.clear(); });
  }

  Future<void> _extractText() async {
    if (_imagePath == null) return;
    setState(() { _isProcessing = true; });
    try {
      final startTime = DateTime.now();
      final text = await _convertService.extractTextFromImage(_imagePath!);
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final wordCount = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      setState(() { _textController.text = text; _hasResult = true; _isProcessing = false; });
      if (mounted) showSpeedReceipt(context, operation: 'Extracted $wordCount words', elapsedMs: elapsed);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OCR failed: $e'), backgroundColor: Colors.redAccent));
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportTxt() async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}/Oqba/extracted');
    if (!await outDir.exists()) await outDir.create(recursive: true);
    final path = '${outDir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.txt';
    File(path).writeAsStringSync(_textController.text);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $path'), backgroundColor: AppTheme.primary));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('OCR · Text from Image', style: TextStyle(fontWeight: FontWeight.w700)), actions: const [OfflineIndicator(), SizedBox(width: 12)]),
      body: ProGate(isPro: isPro, featureName: 'OCR Text Recognition', child: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Image source buttons
        Row(children: [
          Expanded(child: GestureDetector(onTap: _pickFromGallery, child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primary.withAlpha(60))),
            child: const Column(children: [Icon(Icons.photo_library, color: AppTheme.primary, size: 28), SizedBox(height: 4), Text('Gallery', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12))]),
          ))),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(onTap: _pickFromCamera, child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primary.withAlpha(60))),
            child: const Column(children: [Icon(Icons.camera_alt, color: AppTheme.primary, size: 28), SizedBox(height: 4), Text('Camera', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12))]),
          ))),
        ]),
        const SizedBox(height: 16),
        // Image preview
        if (_imagePath != null)
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_imagePath!), height: 200, width: double.infinity, fit: BoxFit.cover)),
        const SizedBox(height: 16),
        // Extract button or result
        if (_imagePath != null && !_hasResult)
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
            onPressed: _isProcessing ? null : _extractText,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _isProcessing
                ? const Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)), SizedBox(width: 12), Text('Analyzing with on-device AI...', style: TextStyle(color: Colors.white))])
                : const Text('Extract Text', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          )),
        if (_hasResult) ...[
          if (_textController.text.isEmpty)
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.orangeAccent.withAlpha(30), borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [Icon(Icons.info_outline, color: Colors.orangeAccent), SizedBox(width: 8), Expanded(child: Text('No text detected. Try a clearer image.', style: TextStyle(color: Colors.orangeAccent, fontSize: 13)))]))
          else ...[
            Expanded(child: TextField(controller: _textController, maxLines: null, expands: true, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(filled: true, fillColor: AppTheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: _textController.text)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'))); },
                icon: const Icon(Icons.copy), label: const Text('Copy All'), style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: const BorderSide(color: AppTheme.primary)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(onPressed: _exportTxt, icon: const Icon(Icons.save_alt, color: Colors.white), label: const Text('Export .txt', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary))),
            ]),
          ],
        ],
      ])))),
    );
  }

  @override
  void dispose() { _textController.dispose(); super.dispose(); }
}
