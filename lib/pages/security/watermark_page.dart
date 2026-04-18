import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/security_service.dart';
import '../../services/file_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';

class WatermarkPage extends StatefulWidget {
  const WatermarkPage({super.key});
  @override
  State<WatermarkPage> createState() => _WatermarkPageState();
}

class _WatermarkPageState extends State<WatermarkPage> {
  final SecurityService _securityService = SecurityService();
  final FileService _fileService = FileService();
  final TextEditingController _textController = TextEditingController(text: 'CONFIDENTIAL');
  String? _pdfPath;
  String? _pdfName;
  double _opacity = 0.3;
  double _rotation = -45;
  bool _isProcessing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      try {
        final importedPath = await _fileService.importFile(result.files.single.path!);
        setState(() { _pdfPath = importedPath; _pdfName = result.files.single.name; });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _addWatermark() async {
    if (_pdfPath == null || _textController.text.trim().isEmpty) return;
    setState(() => _isProcessing = true);
    try {
      final startTime = DateTime.now();
      await _securityService.addWatermark(
        _pdfPath!,
        text: _textController.text.trim(),
        opacity: _opacity,
        rotation: _rotation,
      );
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (mounted) {
        showSpeedReceipt(context, operation: 'Watermark added', elapsedMs: elapsed);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent));
    }
    setState(() => _isProcessing = false);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: Text('Add Watermark', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.txtPrimary(context))),
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
                    color: AppTheme.surf(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: _pdfPath == null
                      ? Column(children: [Icon(Icons.upload_file_rounded, color: AppTheme.primary, size: 40), const SizedBox(height: 8), Text('Select PDF', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600))])
                      : Row(children: [Icon(Icons.picture_as_pdf, color: AppTheme.primary, size: 32), const SizedBox(width: 12), Expanded(child: Text(_pdfName ?? '', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis))]),
                ),
              ),

              if (_pdfPath != null) ...[
                const SizedBox(height: 24),
                // Watermark text
                Text('Watermark Text', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _textController,
                  style: TextStyle(color: AppTheme.txtPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'e.g. CONFIDENTIAL',
                    hintStyle: TextStyle(color: AppTheme.subtleText(context)),
                    filled: true,
                    fillColor: AppTheme.surf(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                // Opacity slider
                Text('Opacity: ${(_opacity * 100).toInt()}%', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600)),
                Slider(
                  value: _opacity,
                  min: 0.05,
                  max: 0.8,
                  activeColor: AppTheme.primary,
                  onChanged: (v) => setState(() => _opacity = v),
                ),

                // Rotation slider
                Text('Rotation: ${_rotation.toInt()}°', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600)),
                Slider(
                  value: _rotation,
                  min: -90,
                  max: 90,
                  activeColor: AppTheme.primary,
                  onChanged: (v) => setState(() => _rotation = v),
                ),

                // Preview
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder(context)),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: _rotation * 3.14159 / 180,
                      child: Text(
                        _textController.text,
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: _opacity),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const Spacer(),

              if (_pdfPath != null) SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _addWatermark,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isProcessing
                      ? Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)), SizedBox(width: 12), Text('Adding watermark...', style: TextStyle(color: Colors.white))])
                      : Text('Add Watermark', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
