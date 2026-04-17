import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback? onPremiumTap;

  const SettingsPage({super.key, this.onPremiumTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ListView(
        children: [
          // Header
          const Center(
            child: Text(
              'Oqba Settings',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Premium Banner
          GestureDetector(
            onTap: onPremiumTap,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primary.withGreen(200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.workspace_premium_rounded,
                                color: AppTheme.premium, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              'Subscription',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upgrade to unlock premium features',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.premium,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // About / Privacy section (follows Strategy Report recommendation)
          const Text(
            'About',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            children: [
              _SettingsItem(
                icon: Icons.shield_outlined,
                title: 'Privacy',
                subtitle: '100% offline · Your data never leaves this device',
                trailing: const Icon(Icons.verified_rounded,
                    color: AppTheme.primary, size: 20),
              ),
              _SettingsItem(
                icon: Icons.info_outline_rounded,
                title: 'Version',
                subtitle: '1.0.0 · Built in 24 hours',
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Theme section
          const Text(
            'Theme',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            children: [
              _SettingsItem(
                icon: Icons.dark_mode_rounded,
                title: 'Theme Mode',
                trailing: Text(
                  'Dark',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 13,
                  ),
                ),
              ),
              _SettingsItem(
                icon: Icons.language_rounded,
                title: 'Language',
                trailing: Text(
                  'English',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Contact section
          const Text(
            'Contact',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            children: [
              _SettingsItem(
                icon: Icons.send_rounded,
                title: 'Telegram',
                subtitle: 'Contact Oqba directly on Telegram',
              ),
              _SettingsItem(
                icon: Icons.mail_outline_rounded,
                title: 'Email',
                subtitle: 'Send feedback or report a bug to Oqba',
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Follow Us
          const Text(
            'Follow Us',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            children: [
              _SettingsItem(
                icon: Icons.campaign_rounded,
                title: 'Telegram Channel',
                subtitle: 'Get the latest Oqba updates and news',
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
                indent: 56,
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textPrimary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
