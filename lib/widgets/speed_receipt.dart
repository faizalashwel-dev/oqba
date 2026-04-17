import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Speed Receipt — Wow Factor #1
/// Animated banner: "Merged in 340ms · Offline"
/// Slides in from top, auto-dismisses after 3 seconds.
class SpeedReceipt extends StatefulWidget {
  final String operation; // "Merged", "Scanned", "Converted"
  final int elapsedMs;
  final String? fileSize; // "1.2 MB"
  final VoidCallback? onDismissed;

  const SpeedReceipt({
    super.key,
    required this.operation,
    required this.elapsedMs,
    this.fileSize,
    this.onDismissed,
  });

  @override
  State<SpeedReceipt> createState() => _SpeedReceiptState();
}

class _SpeedReceiptState extends State<SpeedReceipt>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismissed?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.operation} successfully',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _buildSubtitle(),
                      style: TextStyle(
                        color: AppTheme.primary.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>['${widget.elapsedMs}ms'];
    if (widget.fileSize != null) {
      parts.add(widget.fileSize!);
    }
    parts.add('Offline');
    return parts.join(' · ');
  }
}

/// Helper to show SpeedReceipt as an overlay
void showSpeedReceipt(
  BuildContext context, {
  required String operation,
  required int elapsedMs,
  String? fileSize,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: SpeedReceipt(
          operation: operation,
          elapsedMs: elapsedMs,
          fileSize: fileSize,
          onDismissed: () => entry.remove(),
        ),
      ),
    ),
  );

  overlay.insert(entry);
}
