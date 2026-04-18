import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/security_service.dart';
import '../../services/file_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';

class ProtectPdfPage extends StatefulWidget {
  const ProtectPdfPage({super.key});
  @override
  State<ProtectPdfPage> createState() => _ProtectPdfPageState();
}

class _ProtectPdfPageState extends State<ProtectPdfPage> {
  final SecurityService _securityService = SecurityService();
  final FileService _fileService = FileService();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _ownerController = TextEditingController();
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

  Future<void> _protect() async {
    if (_pdfPath == null) return;
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password cannot be empty'), backgroundColor: Colors.redAccent));
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords don\'t match'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final startTime = DateTime.now();
      final ownerPw = _ownerController.text.trim();
      await _securityService.passwordProtect(
        _pdfPath!,
        userPassword: password,
        ownerPassword: ownerPw.isNotEmpty ? ownerPw : null,
      );
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (mounted) {
        showSpeedReceipt(context, operation: 'PDF protected with AES-256', elapsedMs: elapsed);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Protection failed: $e'), backgroundColor: Colors.redAccent));
    }
    setState(() => _isProcessing = false);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: Text('Protect PDF', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.txtPrimary(context))),
        actions: const [OfflineIndicator(), SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
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

                // Encryption info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_rounded, color: AppTheme.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text('AES-256 bit encryption', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600, fontSize: 14))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Password
                Text('Password', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  style: TextStyle(color: AppTheme.txtPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Enter password',
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
                const SizedBox(height: 16),

                // Confirm password
                Text('Confirm Password', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmController,
                  obscureText: !_showPassword,
                  style: TextStyle(color: AppTheme.txtPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Re-enter password',
                    hintStyle: TextStyle(color: AppTheme.subtleText(context)),
                    filled: true,
                    fillColor: AppTheme.surf(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // Owner password (optional)
                Text('Owner Password (optional)', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _ownerController,
                  obscureText: !_showPassword,
                  style: TextStyle(color: AppTheme.txtPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'For full access (optional)',
                    hintStyle: TextStyle(color: AppTheme.subtleText(context)),
                    filled: true,
                    fillColor: AppTheme.surf(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _protect,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: _isProcessing
                        ? Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)), SizedBox(width: 12), Text('Encrypting...', style: TextStyle(color: Colors.white))])
                        : Text('Protect PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
