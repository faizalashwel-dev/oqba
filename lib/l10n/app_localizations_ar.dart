// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'عقبة';

  @override
  String get filesTitle => 'الملفات';

  @override
  String get toolsTitle => 'أدوات عقبة لـ PDF';

  @override
  String get settingsTitle => 'إعدادات عقبة';

  @override
  String get homeTab => 'الرئيسية';

  @override
  String get toolsTab => 'الأدوات';

  @override
  String get settingsTab => 'الإعدادات';

  @override
  String get scanButton => 'مسح';

  @override
  String get importFiles => 'استيراد ملفات';

  @override
  String get searchFiles => 'البحث في الملفات...';

  @override
  String get noFilesYet => 'لا توجد ملفات بعد';

  @override
  String get noFilesMessage =>
      'ليس لديك أي ملفات هنا. استخدم الماسح الضوئي أو الأدوات لإنشاء أو استيراد الملفات — ستظهر هنا بعد إضافتها.';

  @override
  String documents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مستندات',
      one: 'مستند واحد',
    );
    return '$_temp0';
  }

  @override
  String noResults(String query) {
    return 'لا توجد ملفات تطابق \"$query\"';
  }

  @override
  String get deleteFile => 'حذف الملف';

  @override
  String deleteConfirm(String name) {
    return 'حذف \"$name\"؟\nلا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get renameFile => 'إعادة تسمية الملف';

  @override
  String get enterNewName => 'أدخل الاسم الجديد';

  @override
  String get open => 'فتح';

  @override
  String get share => 'مشاركة';

  @override
  String get saveToDevice => 'حفظ على الجهاز';

  @override
  String get recentBundles => 'الحزم الأخيرة';

  @override
  String items(int count) {
    return '$count عناصر';
  }

  @override
  String get organizePdf => 'تنظيم PDF';

  @override
  String get mergePdf => 'دمج PDF';

  @override
  String get mergePdfDesc => 'دمج ملفات متعددة في ملف واحد';

  @override
  String get splitPdf => 'تقسيم PDF';

  @override
  String get splitPdfDesc => 'تقسيم إلى ملفات أصغر';

  @override
  String get extractPages => 'استخراج صفحات';

  @override
  String get extractPagesDesc => 'استخراج صفحات إلى PDF جديد';

  @override
  String get reorderPages => 'إعادة ترتيب الصفحات';

  @override
  String get reorderPagesDesc => 'تغيير ترتيب الصفحات';

  @override
  String get deletePages => 'حذف صفحات';

  @override
  String get deletePagesDesc => 'إزالة الصفحات غير المرغوبة';

  @override
  String get rotatePages => 'تدوير الصفحات';

  @override
  String get rotatePagesDesc => 'تدوير صفحات PDF';

  @override
  String get convert => 'تحويل';

  @override
  String get pdfToImages => 'PDF إلى صور';

  @override
  String get pdfToImagesDesc => 'تحويل الصفحات إلى صور';

  @override
  String get imagesToPdf => 'صور إلى PDF';

  @override
  String get imagesToPdfDesc => 'دمج الصور في PDF';

  @override
  String get ocrTool => 'صور إلى نص (OCR)';

  @override
  String get ocrToolDesc => 'استخراج النص من الصور باستخدام الذكاء الاصطناعي.';

  @override
  String get extractOptimize => 'استخراج وتحسين';

  @override
  String get extractImages => 'استخراج الصور';

  @override
  String get extractImagesDesc => 'سحب الصور المضمنة';

  @override
  String get extractText => 'استخراج النص';

  @override
  String get extractTextDesc => 'الحصول على النص من PDF';

  @override
  String get compressPdf => 'ضغط PDF';

  @override
  String get compressPdfDesc => 'تقليل حجم الملف مع الحفاظ على الجودة.';

  @override
  String get security => 'الأمان';

  @override
  String get pdfSecurity => 'أمان PDF';

  @override
  String get signPdf => 'توقيع PDF';

  @override
  String get signPdfDesc => 'ارسم وختم توقيعك';

  @override
  String get addWatermark => 'إضافة علامة مائية';

  @override
  String get addWatermarkDesc => 'ختم نص عبر كل صفحة';

  @override
  String get protectPdf => 'حماية PDF';

  @override
  String get protectPdfDesc => 'إضافة تشفير بكلمة مرور';

  @override
  String get unprotectPdf => 'إلغاء حماية PDF';

  @override
  String get unprotectPdfDesc => 'إزالة حماية كلمة المرور';

  @override
  String get about => 'حول';

  @override
  String get privacy => 'الخصوصية';

  @override
  String get privacyDesc => '100% بدون اتصال · بياناتك لا تغادر هذا الجهاز';

  @override
  String get version => 'الإصدار';

  @override
  String get versionDesc => '1.0.0 · بُني في 24 ساعة';

  @override
  String get theme => 'المظهر';

  @override
  String get themeMode => 'وضع المظهر';

  @override
  String get dark => 'داكن';

  @override
  String get light => 'فاتح';

  @override
  String get system => 'تلقائي';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get storage => 'التخزين';

  @override
  String get storageManagement => 'إدارة التخزين';

  @override
  String cacheSize(String size) {
    return 'حجم الذاكرة المؤقتة: $size';
  }

  @override
  String get clearCache => 'مسح الذاكرة المؤقتة';

  @override
  String cacheCleared(String size) {
    return 'تم مسح الذاكرة المؤقتة! تم تحرير $size';
  }

  @override
  String get contact => 'التواصل';

  @override
  String get telegram => 'تيليجرام';

  @override
  String get telegramDesc => 'تواصل مع عقبة مباشرة على تيليجرام';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailDesc => 'أرسل ملاحظات أو أبلغ عن خطأ لعقبة';

  @override
  String get followUs => 'تابعنا';

  @override
  String get telegramChannel => 'قناة تيليجرام';

  @override
  String get telegramChannelDesc => 'احصل على آخر تحديثات وأخبار عقبة';

  @override
  String get selectPdf => 'اختر PDF';

  @override
  String get converting => 'جاري التحويل...';

  @override
  String get processing => 'جاري المعالجة...';

  @override
  String get extracting => 'جاري الاستخراج...';

  @override
  String get noEmbeddedImages => 'لم يتم العثور على صور مضمنة';

  @override
  String get noEmbeddedImagesDesc =>
      'هذا الـ PDF لا يحتوي على صور مضمنة. إذا كان هذا مستندًا ممسوحًا ضوئيًا، يرجى استخدام أداة \'PDF إلى صور\' لتحويل كل صفحة إلى صورة.';

  @override
  String get openPdfToImages => 'فتح PDF إلى صور';

  @override
  String get quality => 'الجودة';

  @override
  String get screen => 'شاشة';

  @override
  String get standard => 'قياسي';

  @override
  String get print => 'طباعة';

  @override
  String get convertButton => 'تحويل';

  @override
  String get selectPages => 'اختر الصفحات للتحويل';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get deselectAll => 'إلغاء تحديد الكل';

  @override
  String get saveAllToGallery => 'حفظ الكل في المعرض';

  @override
  String get savedToGallery => 'تم الحفظ في المعرض!';

  @override
  String get savedToDownloads => 'تم الحفظ في التنزيلات!';

  @override
  String get saveFailed => 'فشل الحفظ';

  @override
  String get signatureTitle => 'ارسم توقيعك';

  @override
  String get clearSignature => 'مسح';

  @override
  String get undoStroke => 'تراجع';

  @override
  String get placeSignature => 'ضع توقيعك';

  @override
  String get dragToPosition => 'اسحب التوقيع لتحديد موضعه';

  @override
  String get stampSignature => 'ختم التوقيع';

  @override
  String get watermarkText => 'نص العلامة المائية';

  @override
  String get opacity => 'الشفافية';

  @override
  String get rotation => 'الدوران';

  @override
  String get addWatermarkButton => 'إضافة علامة مائية';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get ownerPassword => 'كلمة مرور المالك (اختياري)';

  @override
  String get protectButton => 'حماية PDF';

  @override
  String get unprotectButton => 'فتح PDF';

  @override
  String get passwordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get wrongPassword => 'كلمة المرور خاطئة';

  @override
  String get pdfProtected => 'تمت حماية PDF بنجاح!';

  @override
  String get pdfUnprotected => 'تم فتح PDF بنجاح!';

  @override
  String get watermarkAdded => 'تمت إضافة العلامة المائية!';

  @override
  String get signatureStamped => 'تم ختم التوقيع!';

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String hoursAgo(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String daysAgo(int count) {
    return 'منذ $count يوم';
  }
}
