// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Oqba';

  @override
  String get filesTitle => 'Files';

  @override
  String get toolsTitle => 'Oqba PDF Tools Suite';

  @override
  String get settingsTitle => 'Oqba Settings';

  @override
  String get homeTab => 'Home';

  @override
  String get toolsTab => 'Tools';

  @override
  String get settingsTab => 'Settings';

  @override
  String get scanButton => 'Scan';

  @override
  String get importFiles => 'Import Files';

  @override
  String get searchFiles => 'Search files...';

  @override
  String get noFilesYet => 'No Files Yet';

  @override
  String get noFilesMessage =>
      'You don\'t have any files here. Use the scanner or tools to create or import files – they\'ll show up once added.';

  @override
  String documents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
    );
    return '$_temp0';
  }

  @override
  String noResults(String query) {
    return 'No files matching \"$query\"';
  }

  @override
  String get deleteFile => 'Delete File';

  @override
  String deleteConfirm(String name) {
    return 'Delete \"$name\"?\nThis action cannot be undone.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get renameFile => 'Rename File';

  @override
  String get enterNewName => 'Enter new name';

  @override
  String get open => 'Open';

  @override
  String get share => 'Share';

  @override
  String get saveToDevice => 'Save to Device';

  @override
  String get recentBundles => 'Recent Bundles';

  @override
  String items(int count) {
    return '$count items';
  }

  @override
  String get organizePdf => 'Organize PDF';

  @override
  String get mergePdf => 'Merge PDF';

  @override
  String get mergePdfDesc => 'Combine multiple files into one';

  @override
  String get splitPdf => 'Split PDF';

  @override
  String get splitPdfDesc => 'Split into smaller files';

  @override
  String get extractPages => 'Extract Pages';

  @override
  String get extractPagesDesc => 'Extract pages to new PDF';

  @override
  String get reorderPages => 'Reorder Pages';

  @override
  String get reorderPagesDesc => 'Change page order';

  @override
  String get deletePages => 'Delete Pages';

  @override
  String get deletePagesDesc => 'Remove unwanted pages';

  @override
  String get rotatePages => 'Rotate Pages';

  @override
  String get rotatePagesDesc => 'Rotate PDF pages';

  @override
  String get convert => 'Convert';

  @override
  String get pdfToImages => 'PDF to Images';

  @override
  String get pdfToImagesDesc => 'Convert pages to images';

  @override
  String get imagesToPdf => 'Images to PDF';

  @override
  String get imagesToPdfDesc => 'Combine images into PDF';

  @override
  String get ocrTool => 'Images to Text (OCR)';

  @override
  String get ocrToolDesc => 'Extract text from images using on-device AI.';

  @override
  String get extractOptimize => 'Extract & Optimize';

  @override
  String get extractImages => 'Extract Images';

  @override
  String get extractImagesDesc => 'Pull embedded images';

  @override
  String get extractText => 'Extract Text';

  @override
  String get extractTextDesc => 'Get text from PDF';

  @override
  String get compressPdf => 'Compress PDF';

  @override
  String get compressPdfDesc => 'Reduce file size while keeping quality.';

  @override
  String get security => 'Security';

  @override
  String get pdfSecurity => 'PDF Security';

  @override
  String get signPdf => 'Sign PDF';

  @override
  String get signPdfDesc => 'Draw and stamp your signature';

  @override
  String get addWatermark => 'Add Watermark';

  @override
  String get addWatermarkDesc => 'Stamp text across every page';

  @override
  String get protectPdf => 'Protect PDF';

  @override
  String get protectPdfDesc => 'Add password encryption';

  @override
  String get unprotectPdf => 'Unprotect PDF';

  @override
  String get unprotectPdfDesc => 'Remove password protection';

  @override
  String get about => 'About';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyDesc => '100% offline · Your data never leaves this device';

  @override
  String get version => 'Version';

  @override
  String get versionDesc => '1.0.0 · Built in 24 hours';

  @override
  String get theme => 'Theme';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get system => 'System';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get storage => 'Storage';

  @override
  String get storageManagement => 'Storage Management';

  @override
  String cacheSize(String size) {
    return 'Cache Size: $size';
  }

  @override
  String get clearCache => 'Clear Cache';

  @override
  String cacheCleared(String size) {
    return 'Cache cleared! Freed $size';
  }

  @override
  String get contact => 'Contact';

  @override
  String get telegram => 'Telegram';

  @override
  String get telegramDesc => 'Contact Oqba directly on Telegram';

  @override
  String get email => 'Email';

  @override
  String get emailDesc => 'Send feedback or report a bug to Oqba';

  @override
  String get followUs => 'Follow Us';

  @override
  String get telegramChannel => 'Telegram Channel';

  @override
  String get telegramChannelDesc => 'Get the latest Oqba updates and news';

  @override
  String get selectPdf => 'Select PDF';

  @override
  String get converting => 'Converting...';

  @override
  String get processing => 'Processing...';

  @override
  String get extracting => 'Extracting...';

  @override
  String get noEmbeddedImages => 'No embedded images found';

  @override
  String get noEmbeddedImagesDesc =>
      'This PDF doesn\'t contain embedded images. If this is a scanned document, please use the \'PDF to Images\' tool instead to convert each page into an image.';

  @override
  String get openPdfToImages => 'Open PDF to Images';

  @override
  String get quality => 'Quality';

  @override
  String get screen => 'Screen';

  @override
  String get standard => 'Standard';

  @override
  String get print => 'Print';

  @override
  String get convertButton => 'Convert';

  @override
  String get selectPages => 'Select pages to convert';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get saveAllToGallery => 'Save All to Gallery';

  @override
  String get savedToGallery => 'Saved to Gallery!';

  @override
  String get savedToDownloads => 'Saved to Downloads!';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get signatureTitle => 'Draw your signature';

  @override
  String get clearSignature => 'Clear';

  @override
  String get undoStroke => 'Undo';

  @override
  String get placeSignature => 'Place your signature';

  @override
  String get dragToPosition => 'Drag the signature to position it';

  @override
  String get stampSignature => 'Stamp Signature';

  @override
  String get watermarkText => 'Watermark Text';

  @override
  String get opacity => 'Opacity';

  @override
  String get rotation => 'Rotation';

  @override
  String get addWatermarkButton => 'Add Watermark';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get ownerPassword => 'Owner Password (optional)';

  @override
  String get protectButton => 'Protect PDF';

  @override
  String get unprotectButton => 'Unlock PDF';

  @override
  String get passwordMismatch => 'Passwords don\'t match';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String get pdfProtected => 'PDF protected successfully!';

  @override
  String get pdfUnprotected => 'PDF unlocked successfully!';

  @override
  String get watermarkAdded => 'Watermark added!';

  @override
  String get signatureStamped => 'Signature stamped!';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }
}
