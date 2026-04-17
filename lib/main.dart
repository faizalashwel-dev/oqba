import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/speed_receipt.dart';
import 'pages/home_page.dart';
import 'pages/tools_page.dart';
import 'pages/settings_page.dart';
import 'pages/premium_page.dart';
import 'pages/scanner_page.dart';
import 'pages/merge_page.dart';
import 'services/file_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.surface,
  ));
  runApp(const OqbaApp());
}

class OqbaApp extends StatelessWidget {
  const OqbaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oqba',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData.light(),
      darkTheme: AppTheme.darkTheme,
      home: const OqbaShell(),
    );
  }
}

class OqbaShell extends StatefulWidget {
  const OqbaShell({super.key});

  @override
  State<OqbaShell> createState() => _OqbaShellState();
}

class _OqbaShellState extends State<OqbaShell> {
  int _currentIndex = 0;
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();

  @override
  void initState() {
    super.initState();
    // Clean temp dir on app start
    FileService().clearTempDir();
  }

  void _onNavTap(int index) {
    if (index == 3) {
      // PRO tab → push premium as full screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumPage()),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _onScanTap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ScannerPage(),
      ),
    );

    // Show speed receipt and refresh home
    if (result != null && mounted) {
      showSpeedReceipt(
        context,
        operation: result['operation'] as String,
        elapsedMs: result['elapsedMs'] as int,
        fileSize: result['fileSize'] as String?,
      );
      // Refresh the home page file list
      _homeKey.currentState?.loadFiles();
      setState(() => _currentIndex = 0); // Switch to home
    }
  }

  void _onMergeTap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const MergePage()),
    );

    if (result != null && mounted) {
      showSpeedReceipt(
        context,
        operation: result['operation'] as String,
        elapsedMs: result['elapsedMs'] as int,
        fileSize: result['fileSize'] as String?,
      );
      _homeKey.currentState?.loadFiles();
      setState(() => _currentIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex > 2 ? 2 : _currentIndex,
          children: [
            HomePage(key: _homeKey),
            ToolsPage(onMergeTap: _onMergeTap),
            SettingsPage(onPremiumTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PremiumPage()),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        onScanTap: _onScanTap,
      ),
    );
  }
}
