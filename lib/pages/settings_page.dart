import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../services/cleanup_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final CleanupService _cleanupService = CleanupService();
  String _cacheSize = 'Calculating...';
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final size = await _cleanupService.calculateCacheSize();
    if (mounted) {
      setState(() => _cacheSize = CleanupService.formatSize(size));
    }
  }

  Future<void> _clearCache() async {
    setState(() => _isClearing = true);
    final freed = await _cleanupService.clearCache();
    await _loadCacheSize();
    if (mounted) {
      setState(() => _isClearing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cache cleared! Freed ${CleanupService.formatSize(freed)}'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  void _showThemeSheet() {
    final appState = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme Mode', style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _ThemeOption(
                icon: Icons.dark_mode_rounded,
                label: 'Dark',
                isSelected: appState.themeMode == ThemeMode.dark,
                onTap: () { appState.setThemeMode(ThemeMode.dark); Navigator.pop(ctx); },
              ),
              _ThemeOption(
                icon: Icons.light_mode_rounded,
                label: 'Light',
                isSelected: appState.themeMode == ThemeMode.light,
                onTap: () { appState.setThemeMode(ThemeMode.light); Navigator.pop(ctx); },
              ),
              _ThemeOption(
                icon: Icons.brightness_auto_rounded,
                label: 'System',
                isSelected: appState.themeMode == ThemeMode.system,
                onTap: () { appState.setThemeMode(ThemeMode.system); Navigator.pop(ctx); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet() {
    final appState = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Language', style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _ThemeOption(
                icon: Icons.language_rounded,
                label: 'English',
                isSelected: appState.locale.languageCode == 'en',
                onTap: () { appState.setLocale(const Locale('en')); Navigator.pop(ctx); },
              ),
              _ThemeOption(
                icon: Icons.language_rounded,
                label: 'العربية',
                isSelected: appState.locale.languageCode == 'ar',
                onTap: () { appState.setLocale(const Locale('ar')); Navigator.pop(ctx); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final themeModeLabel = switch (appState.themeMode) {
      ThemeMode.light => 'Light',
      ThemeMode.system => 'System',
      _ => 'Dark',
    };
    final langLabel = appState.locale.languageCode == 'ar' ? 'العربية' : 'English';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ListView(
        children: [
          // Header
          Center(
            child: Text(
              'Oqba Settings',
              style: TextStyle(
                color: AppTheme.txtPrimary(context),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // About / Privacy section
          Text(
            'About',
            style: TextStyle(
              color: AppTheme.txtPrimary(context),
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
                trailing: Icon(Icons.verified_rounded,
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
          Text(
            'Theme',
            style: TextStyle(
              color: AppTheme.txtPrimary(context),
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
                onTap: _showThemeSheet,
                trailing: Text(
                  themeModeLabel,
                  style: TextStyle(
                    color: AppTheme.subtleText(context),
                    fontSize: 13,
                  ),
                ),
              ),
              _SettingsItem(
                icon: Icons.language_rounded,
                title: 'Language',
                onTap: _showLanguageSheet,
                trailing: Text(
                  langLabel,
                  style: TextStyle(
                    color: AppTheme.subtleText(context),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Storage Management section (Task 10)
          Text(
            'Storage',
            style: TextStyle(
              color: AppTheme.txtPrimary(context),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            children: [
              _SettingsItem(
                icon: Icons.storage_rounded,
                title: 'Cache Size',
                subtitle: _cacheSize,
              ),
              _SettingsItem(
                icon: Icons.cleaning_services_rounded,
                title: 'Clear Cache',
                subtitle: 'Delete temporary files to free space',
                onTap: _isClearing ? null : _clearCache,
                trailing: _isClearing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                    : Icon(Icons.chevron_right_rounded, color: AppTheme.primary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Contact section
          Text(
            'Contact',
            style: TextStyle(
              color: AppTheme.txtPrimary(context),
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
          Text(
            'Follow Us',
            style: TextStyle(
              color: AppTheme.txtPrimary(context),
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

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.subtleText(context), size: 22),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(color: AppTheme.txtPrimary(context), fontSize: 15, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400))),
            if (isSelected) Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22),
          ],
        ),
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
        color: AppTheme.surf(context).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                color: AppTheme.cardBorder(context),
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
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.txtPrimary(context), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.txtPrimary(context),
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
                          color: AppTheme.subtleText(context),
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
      ),
    );
  }
}
