// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppL10nAr extends AppL10n {
  AppL10nAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'أوشن للتوصيل';

  @override
  String get tagline => 'سلسلة الحراسة،\nمُتحقَّقة عند الرصيف.';

  @override
  String get loginEyebrow => 'تسجيل دخول الممثل';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get continueAction => 'متابعة';

  @override
  String get verifyingToken => 'جارٍ التحقق من الرمز…';

  @override
  String get jwtFooter => 'JWT · للممثلين فقط';

  @override
  String get copyright => '© أوشن للتوصيل · سجل التدقيق';

  @override
  String greeting(Object name, Object role) {
    return 'مرحباً، $name · $role';
  }

  @override
  String mastersToClear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلبات رئيسية للإنجاز.',
      one: 'طلب رئيسي واحد للإنجاز.',
      zero: 'لا توجد طلبات رئيسية',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'ابحث عن طلب رئيسي أو مورّد أو رمز…';

  @override
  String get openSection => 'مفتوحة';

  @override
  String get recentlyClosedSection => 'مغلقة مؤخراً';

  @override
  String get yardFeed => 'أخبار الساحة';

  @override
  String get masterPurchaseOrder => 'أمر الشراء الرئيسي';

  @override
  String get vendorPos => 'أوامر المورّدين';

  @override
  String vendors(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مورّدون',
      one: 'مورّد واحد',
    );
    return '$_temp0';
  }

  @override
  String clearedRatio(Object done, Object total) {
    return '$done/$total مكتمل';
  }

  @override
  String clearedShort(Object done, Object total) {
    return '$done/$total مكتمل';
  }

  @override
  String get mapAction => 'خريطة';

  @override
  String finalizedAt(Object at) {
    return 'أُنهي في $at';
  }

  @override
  String get items => 'البنود';

  @override
  String get stepCurrent => 'الخطوة الحالية';

  @override
  String get stepCompleted => 'مكتمل';

  @override
  String get stepInProgress => 'قيد التنفيذ';

  @override
  String get shipmentPhoto => 'صورة الشحنة';

  @override
  String get itemPhoto => 'صورة البند';

  @override
  String get finalStep => 'الخطوة النهائية';

  @override
  String get startVendor => 'بدء التحقق';

  @override
  String get captureShipment => 'التقاط صورة الشحنة';

  @override
  String get captureItems => 'التقاط صور البنود';

  @override
  String get viewProofs => 'سجل الإثبات';

  @override
  String get finalize => 'إنهاء';

  @override
  String get markMissing => 'تحديد كمفقود';

  @override
  String get retake => 'إعادة الالتقاط';

  @override
  String get submit => 'إرسال';

  @override
  String get done => 'تم';

  @override
  String get shipmentCaptureTitle => 'إثبات على مستوى الشحنة';

  @override
  String get shipmentCaptureSubtitle => 'صورة جماعية + GPS للتسليم بأكمله';

  @override
  String get waitingGps => 'جارٍ تثبيت موقع GPS…';

  @override
  String get gpsLocked => 'تم تثبيت GPS';

  @override
  String get shutterLocked => 'بانتظار GPS لتمكين الالتقاط';

  @override
  String get captureNow => 'التقاط';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get gpsBlocked => 'إذن الموقع مطلوب';

  @override
  String get cameraBlocked => 'إذن الكاميرا مطلوب';

  @override
  String get itemLoopTitle => 'التحقق من كل بند';

  @override
  String get itemLoopSubtitle => 'التقط إثباتاً لكل بند';

  @override
  String deliveredCount(Object count) {
    return '$count مُسلَّمة';
  }

  @override
  String missingCount(Object count) {
    return '$count مفقودة';
  }

  @override
  String pendingCount(Object count) {
    return '$count قيد الانتظار';
  }

  @override
  String get markMissingTitle => 'تحديد هذا البند كمفقود؟';

  @override
  String get markMissingBody =>
      'لن يُعاد إدخال هذا البند في أمر المورّد. سيُعاد احتساب الأمر الرئيسي.';

  @override
  String get confirm => 'تأكيد';

  @override
  String get cancel => 'إلغاء';

  @override
  String get proofsTitle => 'سجل الإثبات';

  @override
  String get shipmentProofs => 'إثباتات الشحنة';

  @override
  String get itemProofs => 'إثباتات البنود';

  @override
  String get autoCompleted => 'إنهاء تلقائي';

  @override
  String get noProofs => 'لا توجد إثباتات بعد';

  @override
  String get finalizeTitle => 'إنهاء أمر المورّد';

  @override
  String finalizeBody(
      Object delivered, Object missing, Object total, Object outcome) {
    return '$delivered مُسلَّمة · $missing مفقودة · $total الإجمالي. النظام سيُسجِّل $outcome عند الإرسال.';
  }

  @override
  String get fullyDelivered => 'تسليم كامل';

  @override
  String get partiallyDelivered => 'تسليم جزئي';

  @override
  String get finalizeBlocked => 'حل كل البنود (تسليم أو مفقود) قبل الإرسال.';

  @override
  String get handoffTitle => 'تم ختم سجل التدقيق';

  @override
  String get handoffBody =>
      'أُعيد حساب تقدُّم الأمر الرئيسي. تم إشعار المشتريات.';

  @override
  String get backToDashboard => 'العودة إلى لوحة التحكم';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get toggleLanguage => 'اللغة';

  @override
  String get logout => 'تسجيل الخروج';
}
