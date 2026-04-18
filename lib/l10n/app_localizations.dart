import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Oqba'**
  String get appTitle;

  /// No description provided for @filesTitle.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get filesTitle;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Oqba PDF Tools Suite'**
  String get toolsTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Oqba Settings'**
  String get settingsTitle;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @toolsTab.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @scanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanButton;

  /// No description provided for @importFiles.
  ///
  /// In en, this message translates to:
  /// **'Import Files'**
  String get importFiles;

  /// No description provided for @searchFiles.
  ///
  /// In en, this message translates to:
  /// **'Search files...'**
  String get searchFiles;

  /// No description provided for @noFilesYet.
  ///
  /// In en, this message translates to:
  /// **'No Files Yet'**
  String get noFilesYet;

  /// No description provided for @noFilesMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any files here. Use the scanner or tools to create or import files – they\'ll show up once added.'**
  String get noFilesMessage;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 document} other{{count} documents}}'**
  String documents(int count);

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No files matching \"{query}\"'**
  String noResults(String query);

  /// No description provided for @deleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get deleteFile;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?\nThis action cannot be undone.'**
  String deleteConfirm(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renameFile.
  ///
  /// In en, this message translates to:
  /// **'Rename File'**
  String get renameFile;

  /// No description provided for @enterNewName.
  ///
  /// In en, this message translates to:
  /// **'Enter new name'**
  String get enterNewName;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @saveToDevice.
  ///
  /// In en, this message translates to:
  /// **'Save to Device'**
  String get saveToDevice;

  /// No description provided for @recentBundles.
  ///
  /// In en, this message translates to:
  /// **'Recent Bundles'**
  String get recentBundles;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String items(int count);

  /// No description provided for @organizePdf.
  ///
  /// In en, this message translates to:
  /// **'Organize PDF'**
  String get organizePdf;

  /// No description provided for @mergePdf.
  ///
  /// In en, this message translates to:
  /// **'Merge PDF'**
  String get mergePdf;

  /// No description provided for @mergePdfDesc.
  ///
  /// In en, this message translates to:
  /// **'Combine multiple files into one'**
  String get mergePdfDesc;

  /// No description provided for @splitPdf.
  ///
  /// In en, this message translates to:
  /// **'Split PDF'**
  String get splitPdf;

  /// No description provided for @splitPdfDesc.
  ///
  /// In en, this message translates to:
  /// **'Split into smaller files'**
  String get splitPdfDesc;

  /// No description provided for @extractPages.
  ///
  /// In en, this message translates to:
  /// **'Extract Pages'**
  String get extractPages;

  /// No description provided for @extractPagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Extract pages to new PDF'**
  String get extractPagesDesc;

  /// No description provided for @reorderPages.
  ///
  /// In en, this message translates to:
  /// **'Reorder Pages'**
  String get reorderPages;

  /// No description provided for @reorderPagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Change page order'**
  String get reorderPagesDesc;

  /// No description provided for @deletePages.
  ///
  /// In en, this message translates to:
  /// **'Delete Pages'**
  String get deletePages;

  /// No description provided for @deletePagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove unwanted pages'**
  String get deletePagesDesc;

  /// No description provided for @rotatePages.
  ///
  /// In en, this message translates to:
  /// **'Rotate Pages'**
  String get rotatePages;

  /// No description provided for @rotatePagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Rotate PDF pages'**
  String get rotatePagesDesc;

  /// No description provided for @convert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convert;

  /// No description provided for @pdfToImages.
  ///
  /// In en, this message translates to:
  /// **'PDF to Images'**
  String get pdfToImages;

  /// No description provided for @pdfToImagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Convert pages to images'**
  String get pdfToImagesDesc;

  /// No description provided for @imagesToPdf.
  ///
  /// In en, this message translates to:
  /// **'Images to PDF'**
  String get imagesToPdf;

  /// No description provided for @imagesToPdfDesc.
  ///
  /// In en, this message translates to:
  /// **'Combine images into PDF'**
  String get imagesToPdfDesc;

  /// No description provided for @ocrTool.
  ///
  /// In en, this message translates to:
  /// **'Images to Text (OCR)'**
  String get ocrTool;

  /// No description provided for @ocrToolDesc.
  ///
  /// In en, this message translates to:
  /// **'Extract text from images using on-device AI.'**
  String get ocrToolDesc;

  /// No description provided for @extractOptimize.
  ///
  /// In en, this message translates to:
  /// **'Extract & Optimize'**
  String get extractOptimize;

  /// No description provided for @extractImages.
  ///
  /// In en, this message translates to:
  /// **'Extract Images'**
  String get extractImages;

  /// No description provided for @extractImagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Pull embedded images'**
  String get extractImagesDesc;

  /// No description provided for @extractText.
  ///
  /// In en, this message translates to:
  /// **'Extract Text'**
  String get extractText;

  /// No description provided for @extractTextDesc.
  ///
  /// In en, this message translates to:
  /// **'Get text from PDF'**
  String get extractTextDesc;

  /// No description provided for @compressPdf.
  ///
  /// In en, this message translates to:
  /// **'Compress PDF'**
  String get compressPdf;

  /// No description provided for @compressPdfDesc.
  ///
  /// In en, this message translates to:
  /// **'Reduce file size while keeping quality.'**
  String get compressPdfDesc;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @pdfSecurity.
  ///
  /// In en, this message translates to:
  /// **'PDF Security'**
  String get pdfSecurity;

  /// No description provided for @signPdf.
  ///
  /// In en, this message translates to:
  /// **'Sign PDF'**
  String get signPdf;

  /// No description provided for @signPdfDesc.
  ///
  /// In en, this message translates to:
  /// **'Draw and stamp your signature'**
  String get signPdfDesc;

  /// No description provided for @addWatermark.
  ///
  /// In en, this message translates to:
  /// **'Add Watermark'**
  String get addWatermark;

  /// No description provided for @addWatermarkDesc.
  ///
  /// In en, this message translates to:
  /// **'Stamp text across every page'**
  String get addWatermarkDesc;

  /// No description provided for @protectPdf.
  ///
  /// In en, this message translates to:
  /// **'Protect PDF'**
  String get protectPdf;

  /// No description provided for @protectPdfDesc.
  ///
  /// In en, this message translates to:
  /// **'Add password encryption'**
  String get protectPdfDesc;

  /// No description provided for @unprotectPdf.
  ///
  /// In en, this message translates to:
  /// **'Unprotect PDF'**
  String get unprotectPdf;

  /// No description provided for @unprotectPdfDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove password protection'**
  String get unprotectPdfDesc;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyDesc.
  ///
  /// In en, this message translates to:
  /// **'100% offline · Your data never leaves this device'**
  String get privacyDesc;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @versionDesc.
  ///
  /// In en, this message translates to:
  /// **'1.0.0 · Built in 24 hours'**
  String get versionDesc;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @storageManagement.
  ///
  /// In en, this message translates to:
  /// **'Storage Management'**
  String get storageManagement;

  /// No description provided for @cacheSize.
  ///
  /// In en, this message translates to:
  /// **'Cache Size: {size}'**
  String cacheSize(String size);

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared! Freed {size}'**
  String cacheCleared(String size);

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @telegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get telegram;

  /// No description provided for @telegramDesc.
  ///
  /// In en, this message translates to:
  /// **'Contact Oqba directly on Telegram'**
  String get telegramDesc;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailDesc.
  ///
  /// In en, this message translates to:
  /// **'Send feedback or report a bug to Oqba'**
  String get emailDesc;

  /// No description provided for @followUs.
  ///
  /// In en, this message translates to:
  /// **'Follow Us'**
  String get followUs;

  /// No description provided for @telegramChannel.
  ///
  /// In en, this message translates to:
  /// **'Telegram Channel'**
  String get telegramChannel;

  /// No description provided for @telegramChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Get the latest Oqba updates and news'**
  String get telegramChannelDesc;

  /// No description provided for @selectPdf.
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get selectPdf;

  /// No description provided for @converting.
  ///
  /// In en, this message translates to:
  /// **'Converting...'**
  String get converting;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @extracting.
  ///
  /// In en, this message translates to:
  /// **'Extracting...'**
  String get extracting;

  /// No description provided for @noEmbeddedImages.
  ///
  /// In en, this message translates to:
  /// **'No embedded images found'**
  String get noEmbeddedImages;

  /// No description provided for @noEmbeddedImagesDesc.
  ///
  /// In en, this message translates to:
  /// **'This PDF doesn\'t contain embedded images. If this is a scanned document, please use the \'PDF to Images\' tool instead to convert each page into an image.'**
  String get noEmbeddedImagesDesc;

  /// No description provided for @openPdfToImages.
  ///
  /// In en, this message translates to:
  /// **'Open PDF to Images'**
  String get openPdfToImages;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @screen.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get screen;

  /// No description provided for @standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standard;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @convertButton.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convertButton;

  /// No description provided for @selectPages.
  ///
  /// In en, this message translates to:
  /// **'Select pages to convert'**
  String get selectPages;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @saveAllToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save All to Gallery'**
  String get saveAllToGallery;

  /// No description provided for @savedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Saved to Gallery!'**
  String get savedToGallery;

  /// No description provided for @savedToDownloads.
  ///
  /// In en, this message translates to:
  /// **'Saved to Downloads!'**
  String get savedToDownloads;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @signatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw your signature'**
  String get signatureTitle;

  /// No description provided for @clearSignature.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSignature;

  /// No description provided for @undoStroke.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoStroke;

  /// No description provided for @placeSignature.
  ///
  /// In en, this message translates to:
  /// **'Place your signature'**
  String get placeSignature;

  /// No description provided for @dragToPosition.
  ///
  /// In en, this message translates to:
  /// **'Drag the signature to position it'**
  String get dragToPosition;

  /// No description provided for @stampSignature.
  ///
  /// In en, this message translates to:
  /// **'Stamp Signature'**
  String get stampSignature;

  /// No description provided for @watermarkText.
  ///
  /// In en, this message translates to:
  /// **'Watermark Text'**
  String get watermarkText;

  /// No description provided for @opacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get opacity;

  /// No description provided for @rotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get rotation;

  /// No description provided for @addWatermarkButton.
  ///
  /// In en, this message translates to:
  /// **'Add Watermark'**
  String get addWatermarkButton;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @ownerPassword.
  ///
  /// In en, this message translates to:
  /// **'Owner Password (optional)'**
  String get ownerPassword;

  /// No description provided for @protectButton.
  ///
  /// In en, this message translates to:
  /// **'Protect PDF'**
  String get protectButton;

  /// No description provided for @unprotectButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock PDF'**
  String get unprotectButton;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwordMismatch;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get wrongPassword;

  /// No description provided for @pdfProtected.
  ///
  /// In en, this message translates to:
  /// **'PDF protected successfully!'**
  String get pdfProtected;

  /// No description provided for @pdfUnprotected.
  ///
  /// In en, this message translates to:
  /// **'PDF unlocked successfully!'**
  String get pdfUnprotected;

  /// No description provided for @watermarkAdded.
  ///
  /// In en, this message translates to:
  /// **'Watermark added!'**
  String get watermarkAdded;

  /// No description provided for @signatureStamped.
  ///
  /// In en, this message translates to:
  /// **'Signature stamped!'**
  String get signatureStamped;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
