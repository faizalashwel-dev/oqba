import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/offline_indicator.dart';

/// Security Page — Tool launcher for all 4 security features.
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: Text('PDF Security', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.txtPrimary(context))),
        actions: const [OfflineIndicator(), SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.security_rounded, color: AppTheme.primary, size: 48),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'PDF Security Suite',
                  style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Sign, watermark, protect & unlock your PDFs',
                  style: TextStyle(color: AppTheme.subtleText(context), fontSize: 13),
                ),
              ),
              const SizedBox(height: 32),

              // Tool cards
              _SecurityToolCard(
                icon: Icons.draw_rounded,
                title: 'Sign PDF',
                description: 'Draw your signature and stamp it on any page',
                onTap: () => Navigator.pushNamed(context, '/security/sign'),
              ),
              const SizedBox(height: 12),
              _SecurityToolCard(
                icon: Icons.water_drop_rounded,
                title: 'Add Watermark',
                description: 'Stamp transparent text across every page',
                onTap: () => Navigator.pushNamed(context, '/security/watermark'),
              ),
              const SizedBox(height: 12),
              _SecurityToolCard(
                icon: Icons.lock_rounded,
                title: 'Protect PDF',
                description: 'Add AES-256 password encryption',
                onTap: () => Navigator.pushNamed(context, '/security/protect'),
              ),
              const SizedBox(height: 12),
              _SecurityToolCard(
                icon: Icons.lock_open_rounded,
                title: 'Unprotect PDF',
                description: 'Remove password and save unlocked copy',
                onTap: () => Navigator.pushNamed(context, '/security/unprotect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _SecurityToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: AppTheme.txtPrimary(context), fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(description, style: TextStyle(color: AppTheme.subtleText(context), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.subtleText(context)),
          ],
        ),
      ),
    );
  }
}
