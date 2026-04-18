import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/offline_indicator.dart';

/// Security Page — Stub for v2.0.
///
/// Displays a "Coming Soon" placeholder with feature preview cards.
/// Full implementation (password protect, watermark, etc.) deferred to v2.0.
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('PDF Security', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: const [OfflineIndicator(), SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Coming soon icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppTheme.primary,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Security Tools',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coming in v2.0',
                style: TextStyle(
                  color: AppTheme.primary.withAlpha(200),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),

              // Feature preview cards
              _featurePreview(Icons.password, 'Password Protect', 'Encrypt PDFs with 256-bit AES encryption'),
              const SizedBox(height: 12),
              _featurePreview(Icons.lock_open, 'Remove Password', 'Unlock password-protected PDFs'),
              const SizedBox(height: 12),
              _featurePreview(Icons.water_drop, 'Add Watermark', 'Stamp text watermarks on every page'),

              const SizedBox(height: 32),

              // Notify Me button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You\'ll be notified when Security Tools are ready!'),
                        backgroundColor: AppTheme.primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
                  label: const Text('Notify Me When Ready', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featurePreview(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary.withAlpha(120), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppTheme.textPrimary.withAlpha(150), fontWeight: FontWeight.w600, fontSize: 14)),
                Text(desc, style: TextStyle(color: AppTheme.textSecondary.withAlpha(100), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
