import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Paywall gate widget for PRO features.
///
/// Wraps any feature widget. When [isPro] is false, the child is rendered
/// at 40% opacity with a BackdropFilter blur and a centered "Upgrade to PRO"
/// overlay. When [isPro] is true, the child renders normally with zero overhead.
///
/// Source of truth: The global `isPro` boolean in main.dart.
/// Flipping it to `true` unlocks all PRO features instantly for demo purposes.
class ProGate extends StatelessWidget {
  final bool isPro;
  final Widget child;
  final String featureName;

  const ProGate({
    super.key,
    required this.isPro,
    required this.child,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    // PRO user → render child normally, no overhead
    if (isPro) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Dimmed child ──
        Opacity(
          opacity: 0.4,
          child: IgnorePointer(child: child),
        ),

        // ── Blur + Overlay ──
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: AppTheme.background.withAlpha(128),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Crown icon
                      const Icon(
                        Icons.workspace_premium,
                        color: AppTheme.premium,
                        size: 64,
                      ),
                      const SizedBox(height: 16),

                      // "PRO FEATURE" badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.premium.withAlpha(26),
                          border: Border.all(
                              color: AppTheme.premium.withAlpha(64)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRO FEATURE',
                          style: TextStyle(
                            color: AppTheme.premium,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Feature name
                      Text(
                        featureName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // CTA button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/premium');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.premium,
                          foregroundColor: AppTheme.background,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Upgrade to PRO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
