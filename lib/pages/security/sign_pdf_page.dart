import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/security_service.dart';
import '../../services/file_service.dart';
import '../../services/page_thumbnail_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/speed_receipt.dart';

class SignPdfPage extends StatefulWidget {
  const SignPdfPage({super.key});
  @override
  State<SignPdfPage> createState() => _SignPdfPageState();
}

class _SignPdfPageState extends State<SignPdfPage> {
  final SecurityService _securityService = SecurityService();
  final FileService _fileService = FileService();
  String? _pdfPath;

  int _pageCount = 0;
  int _selectedPage = 0;
  Uint8List? _signatureBytes;
  bool _isProcessing = false;

  // Signature position (fraction of page)
  double _sigX = 0.6;
  double _sigY = 0.8;

  // Drawing state
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  // Step: 0 = pick file, 1 = draw signature, 2 = place signature
  int _step = 0;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      try {
        final importedPath = await _fileService.importFile(result.files.single.path!);
        final count = await PageThumbnailService().getPageCount(importedPath);
        setState(() {
          _pdfPath = importedPath;
          _pageCount = count;
          _step = 1;
        });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _captureSignature() async {
    if (_strokes.isEmpty) return;

    // Render strokes to image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final stroke in _strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(400, 200);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData != null) {
      setState(() {
        _signatureBytes = byteData.buffer.asUint8List();
        _step = 2;
      });
    }
  }

  Future<void> _stampSignature() async {
    if (_pdfPath == null || _signatureBytes == null) return;
    setState(() => _isProcessing = true);

    try {
      final startTime = DateTime.now();
      await _securityService.signPdf(
        _pdfPath!,
        signatureBytes: _signatureBytes!,
        pageIndex: _selectedPage,
        xPercent: _sigX,
        yPercent: _sigY,
      );
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;

      if (mounted) {
        showSpeedReceipt(context, operation: 'Signature stamped', elapsedMs: elapsed);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signing failed: $e'), backgroundColor: Colors.redAccent));
    }
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: Text('Sign PDF', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.txtPrimary(context))),
        actions: const [OfflineIndicator(), SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: switch (_step) {
            0 => _buildPickFile(),
            1 => _buildDrawSignature(),
            2 => _buildPlaceSignature(),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }

  Widget _buildPickFile() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppTheme.surf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.upload_file_rounded, color: AppTheme.primary, size: 48),
                const SizedBox(height: 12),
                Text('Select PDF to Sign', style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawSignature() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Draw your signature', style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        // Drawing canvas
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _currentStroke = [details.localPosition];
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _currentStroke.add(details.localPosition);
              });
            },
            onPanEnd: (_) {
              setState(() {
                _strokes.add(List.from(_currentStroke));
                _currentStroke = [];
              });
            },
            child: CustomPaint(
              painter: _SignaturePainter(strokes: _strokes, currentStroke: _currentStroke),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() { _strokes.clear(); _currentStroke.clear(); }),
                icon: Icon(Icons.clear_rounded),
                label: Text('Clear'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: const BorderSide(color: AppTheme.primary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _strokes.isNotEmpty ? () => setState(() => _strokes.removeLast()) : null,
                icon: Icon(Icons.undo_rounded),
                label: Text('Undo'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: const BorderSide(color: AppTheme.primary)),
              ),
            ),
          ],
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _strokes.isNotEmpty ? _captureSignature : null,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text('Next: Place Signature', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceSignature() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Place your signature', style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Drag to position · Page ${_selectedPage + 1}/$_pageCount', style: TextStyle(color: AppTheme.subtleText(context), fontSize: 13)),
        const SizedBox(height: 16),

        // Page selector (horizontal)
        if (_pageCount > 1) ...[
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pageCount,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => setState(() => _selectedPage = i),
                child: Container(
                  width: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _selectedPage == i ? AppTheme.primary : AppTheme.surf(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _selectedPage == i ? AppTheme.primary : AppTheme.cardBorder(context)),
                  ),
                  child: Center(child: Text('${i + 1}', style: TextStyle(color: _selectedPage == i ? Colors.white : AppTheme.txtPrimary(context), fontWeight: FontWeight.w600, fontSize: 13))),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Page preview with draggable signature
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder(context)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Page thumbnail
                    Center(
                      child: FutureBuilder<Uint8List?>(
                        future: PageThumbnailService().getThumbnail(_pdfPath!, _selectedPage, width: 300),
                        builder: (ctx, snap) {
                          if (snap.hasData && snap.data != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(snap.data!, fit: BoxFit.contain),
                            );
                          }
                          return const CircularProgressIndicator(color: AppTheme.primary);
                        },
                      ),
                    ),
                    // Draggable signature
                    Positioned(
                      left: _sigX * constraints.maxWidth - 50,
                      top: _sigY * constraints.maxHeight - 25,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _sigX = ((_sigX * constraints.maxWidth + details.delta.dx) / constraints.maxWidth).clamp(0.0, 1.0);
                            _sigY = ((_sigY * constraints.maxHeight + details.delta.dy) / constraints.maxHeight).clamp(0.0, 1.0);
                          });
                        },
                        child: Container(
                          width: 100,
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primary, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _signatureBytes != null
                              ? Image.memory(_signatureBytes!, fit: BoxFit.contain)
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _stampSignature,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: _isProcessing
                ? Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)), SizedBox(width: 12), Text('Stamping...', style: TextStyle(color: Colors.white))])
                : Text('Stamp Signature', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _SignaturePainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final stroke in [...strokes, currentStroke]) {
      if (stroke.length < 2) continue;
      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
