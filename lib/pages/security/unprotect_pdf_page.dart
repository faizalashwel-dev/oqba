import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/security_service.dart';
import '../../services/file_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';

class UnprotectPdfPage extends StatefulWidget {
  const UnprotectPdfPage({super.key});
  @override
  State<UnprotectPdfPage> createState() => _UnprotectPdfPageState();
}

class _UnprotectPdfPageState extends State<UnprotectPdfPage> {
  final SecurityService _securityService = SecurityService();
  final FileService _fileService = FileService();
  final TextEditingController _passwordController = TextEditingController();
  String? _pdfPath;
  String? _pdfName;
  bool _isProcessing = false;
  bool _showPassword = false;

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

  Future<void> _unprotect() async {
    if (_pdfPath == null) return;
    final password = _passwordController.text;

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password cannot be empty'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final startTime = DateTime.now();
      await _securityService.removePassword(_pdfPath!, password: password);
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (mounted) {
        showSpeedReceipt(context, operation: 'PDF unlocked', elapsedMs: elapsed);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong password or decryption failed'), backgroundColor: Colors.redAccent),
        );
      }
    }
    setState(() => _isProcessing = false);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: Text('Unprotect PDF', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.txtPrimary(context))),
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
                      ? Column(children: [Icon(Icons.upload_file_rounded, color: AppTheme.primary, size: 40), const SizedBox(height: 8), Text('Select Protected PDF', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600))])
                      : Row(children: [Icon(Icons.lock, color: Colors.orangeAccent, size: 32), const SizedBox(width: 12), Expanded(child: Text(_pdfName ?? '', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis))]),
                ),
              ),

              if (_pdfPath != null) ...[
                const SizedBox(height: 24),
                // Info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orangeAccent, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Enter the password used to protect this PDF', style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 13))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Password input
                Text('Password', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  style: TextStyle(color: AppTheme.txtPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Enter password to unlock',
                    hintStyle: TextStyle(color: AppTheme.subtleText(context)),
                    filled: true,
                    fillColor: AppTheme.surf(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.subtleText(context)),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
              ],

              const Spacer(),

              if (_pdfPath != null) SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _unprotect,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isProcessing
                      ? Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)), SizedBox(width: 12), Text('Decrypting...', style: TextStyle(color: Colors.white))])
                      : Text('Unlock PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
