import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/compress_service.dart';
import '../../services/file_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';
import '../../widgets/pro_gate.dart';
import '../../main.dart' show isPro;

class CompressPage extends StatefulWidget {
  const CompressPage({super.key});
  @override
  State<CompressPage> createState() => _CompressPageState();
}

class _CompressPageState extends State<CompressPage> {
  final CompressService _compressService = CompressService();
  final FileService _fileService = FileService();
  String? _pdfPath;
  String? _pdfName;
  int _originalSize = 0;
  String _preset = 'medium';
  bool _isProcessing = false;
  CompressResult? _result;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      try {
        final importedPath = await _fileService.importFile(result.files.single.path!);
        final file = File(importedPath);
        setState(() { _pdfPath = importedPath; _pdfName = result.files.single.name; _originalSize = file.lengthSync(); _result = null; });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _compress() async {
    if (_pdfPath == null) return;
    setState(() => _isProcessing = true);
    try {
      final result = await _compressService.compressPdf(_pdfPath!, preset: _preset);
      setState(() { _result = result; _isProcessing = false; });
      if (mounted) showSpeedReceipt(context, operation: 'Compressed ${result.reductionPercent.toStringAsFixed(0)}%', elapsedMs: 0, fileSize: 'Saved ${result.formattedSaved}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Compression failed: $e'), backgroundColor: Colors.redAccent));
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(title: Text('Compress PDF', style: TextStyle(fontWeight: FontWeight.w700)), actions: const [OfflineIndicator(), SizedBox(width: 12)]),
      body: ProGate(isPro: isPro, featureName: 'PDF Compression', child: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // File picker
        GestureDetector(onTap: _isProcessing ? null : _pickFile, child: Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.surf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primary.withAlpha(60))),
          child: _pdfPath == null
              ? Column(children: [Icon(Icons.upload_file_rounded, color: AppTheme.primary, size: 40), SizedBox(height: 8), Text('Select PDF', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600))])
              : Row(children: [Icon(Icons.picture_as_pdf, color: AppTheme.primary, size: 32), const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_pdfName ?? '', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    Text(CompressResult(outputPath: '', originalSizeBytes: _originalSize, newSizeBytes: _originalSize).formattedOriginal, style: TextStyle(color: AppTheme.txtSecondary(context), fontSize: 12)),
                  ]))]),
        )),
        if (_pdfPath != null && _result == null) ...[
          const SizedBox(height: 24),
          Text('Compression Level', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          _presetCard('low', 'Low', 'Minimal quality loss', '~20-30% smaller', Icons.compress),
          const SizedBox(height: 8),
          _presetCard('medium', 'Medium', 'Good quality balance', '~40-60% smaller', Icons.tune),
          const SizedBox(height: 8),
          _presetCard('high', 'High', 'Maximum compression', '~60-80% smaller', Icons.speed),
        ],
        if (_result != null) ...[
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.surf(context), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Text('Compression Result', style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_result!.formattedOriginal, style: TextStyle(color: AppTheme.txtSecondary(context), fontSize: 16)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.arrow_forward, color: AppTheme.primary)),
                Text(_result!.formattedNew, style: TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 12),
              // Animated bar
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Stack(children: [
                Container(height: 24, width: double.infinity, color: AppTheme.bg(context)),
                AnimatedContainer(duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic,
                  height: 24, width: MediaQuery.of(context).size.width * 0.85 * (1 - _result!.reductionPercent / 100),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withGreen(200)]), borderRadius: BorderRadius.circular(8))),
              ])),
              const SizedBox(height: 8),
              Text('Saved ${_result!.reductionPercent.toStringAsFixed(1)}%', style: TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w700)),
            ])),
        ],
        const Spacer(),
        if (_pdfPath != null && _result == null) SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
          onPressed: _isProcessing ? null : _compress,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: _isProcessing
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
              : Text('Compress PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        )),
      ])))),
    );
  }

  Widget _presetCard(String key, String title, String subtitle, String badge, IconData icon) {
    final selected = _preset == key;
    return GestureDetector(
      onTap: () => setState(() => _preset = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withAlpha(20) : AppTheme.surf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.surf(context), width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Icon(icon, color: selected ? AppTheme.primary : AppTheme.txtSecondary(context), size: 28),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: selected ? AppTheme.primary : AppTheme.txtPrimary(context), fontWeight: FontWeight.w700)),
            Text(subtitle, style: TextStyle(color: AppTheme.txtSecondary(context), fontSize: 11)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: selected ? AppTheme.primary.withAlpha(30) : AppTheme.bg(context), borderRadius: BorderRadius.circular(6)),
            child: Text(badge, style: TextStyle(color: selected ? AppTheme.primary : AppTheme.txtSecondary(context), fontSize: 10, fontWeight: FontWeight.w600))),
        ]),
      ),
    );
  }
}
