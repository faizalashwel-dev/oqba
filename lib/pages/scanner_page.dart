import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../services/scanner_service.dart';
import '../services/pdf_service.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final ScannerService _scannerService = ScannerService();
  final PdfService _pdfService = PdfService();
  bool _isProcessing = false;
  bool _permissionDenied = false;
  bool _permanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPermissionAndScan());
  }

  Future<void> _checkPermissionAndScan() async {
    final permResult = await _scannerService.ensureCameraPermission();

    if (!permResult.granted) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _permanentlyDenied = permResult.permanentlyDenied;
        });
      }
      return;
    }

    await _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isProcessing = true;
      _permissionDenied = false;
    });

    try {
      final scannedPaths = await _scannerService.scanDocument();

      if (scannedPaths.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }

      // Convert scanned images to PDF — runs in background Isolate
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final result = await _pdfService.imagesToPdf(
        scannedPaths,
        'scan_$timestamp',
      );

      if (mounted) {
        Navigator.pop(context, {
          'operation': 'Scanned',
          'elapsedMs': result.elapsedMs,
          'fileSize': result.formattedSize,
        });
      }
    } on ScannerException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _startScan,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _scannerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _permissionDenied
            ? _buildPermissionGate()
            : _isProcessing
                ? _buildProcessingState()
                : const SizedBox.shrink(),
      ),
    );
  }

  /// Permission Gate — never leave user on a blank screen.
  Widget _buildPermissionGate() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: AppTheme.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Camera Access Required',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Oqba needs camera access to scan your documents.\nAll processing happens 100% on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_permanentlyDenied) {
                    await openAppSettings();
                  } else {
                    await _checkPermissionAndScan();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                ),
                child: Text(
                  _permanentlyDenied ? 'Open Settings' : 'Grant Permission',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Processing scan...',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Converting to PDF · 100% on-device',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
