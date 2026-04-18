import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/speed_receipt.dart';
import 'pages/home_page.dart';
import 'pages/tools_page.dart';
import 'pages/settings_page.dart';
import 'pages/scanner_page.dart';
import 'pages/merge_page.dart';
import 'pages/organize/split_page.dart';
import 'pages/organize/extract_pages_page.dart';
import 'pages/organize/reorder_pages_page.dart';
import 'pages/organize/delete_pages_page.dart';
import 'pages/organize/rotate_pages_page.dart';
import 'pages/convert/pdf_to_images_page.dart';
import 'pages/convert/images_to_pdf_page.dart';
import 'pages/convert/ocr_page.dart';
import 'pages/extract_optimize/extract_images_page.dart';
import 'pages/extract_optimize/extract_text_page.dart';
import 'pages/extract_optimize/compress_page.dart';
import 'pages/security/security_page.dart';
import 'pages/security/sign_pdf_page.dart';
import 'pages/security/watermark_page.dart';
import 'pages/security/protect_pdf_page.dart';
import 'pages/security/unprotect_pdf_page.dart';
import 'services/file_service.dart';

/// Global PRO status flag.
/// Hardcoded to `true` to unlock all PRO features for testing.
bool isPro = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final appState = AppState();
  await appState.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.surface,
  ));
  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const OqbaApp(),
    ),
  );
}

class OqbaApp extends StatelessWidget {
  const OqbaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return MaterialApp(
      title: 'Oqba',
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: appState.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const OqbaShell(),
      routes: {
        '/organize/split': (_) => const SplitPage(),
        '/organize/extract-pages': (_) => const ExtractPagesPage(),
        '/organize/reorder': (_) => const ReorderPagesPage(),
        '/organize/delete': (_) => const DeletePagesPage(),
        '/organize/rotate': (_) => const RotatePagesPage(),
        '/convert/pdf-to-images': (_) => const PdfToImagesPage(),
        '/convert/images-to-pdf': (_) => const ImagesToPdfPage(),
        '/convert/ocr': (_) => const OcrPage(),
        '/extract/images': (_) => const ExtractImagesPage(),
        '/extract/text': (_) => const ExtractTextPage(),
        '/extract/compress': (_) => const CompressPage(),
        '/security': (_) => const SecurityPage(),
        '/security/sign': (_) => const SignPdfPage(),
        '/security/watermark': (_) => const WatermarkPage(),
        '/security/protect': (_) => const ProtectPdfPage(),
        '/security/unprotect': (_) => const UnprotectPdfPage(),
      },
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
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            HomePage(key: _homeKey),
            ToolsPage(onMergeTap: _onMergeTap),
            const SettingsPage(),
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
