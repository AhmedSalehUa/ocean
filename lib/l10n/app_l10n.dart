import 'package:flutter/material.dart';

/// Hand-rolled localization layer. Strings live here so the project builds
/// without a codegen step. The keys match `app_en.arb` / `app_ar.arb`
/// so you can switch to `flutter gen-l10n` later without changing call sites.
class AppL10n {
  AppL10n(this.locale);
  final Locale locale;

  static const supported = [Locale('en'), Locale('ar')];

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  bool get isAr => locale.languageCode == 'ar';

  String _t(String en, String ar) => isAr ? ar : en;

  // ─── Login & shell ───
  String get appName => _t('Ocean Delivery', 'أوشن للتوصيل');
  String get tagline => _t('Chain of custody,\nverified at the bay.',
      'سلسلة الحراسة،\nمُتحقَّقة عند الرصيف.');
  String get loginEyebrow => _t('Representative sign-in', 'تسجيل دخول الممثل');
  String get username => _t('Username', 'اسم المستخدم');
  String get password => _t('Password', 'كلمة المرور');
  String get continueAction => _t('Continue', 'متابعة');
  String get verifyingToken => _t('Verifying token…', 'جارٍ التحقق من الرمز…');
  String get jwtFooter => _t('JWT · Role REPRESENTATIVE only', 'JWT · للممثلين فقط');
  String get copyright => _t('© Ocean Delivery · Audit ledger',
      '© أوشن للتوصيل · سجل التدقيق');

  // ─── Dashboard ───
  String greeting(String name, String role) =>
      _t('Hi, $name · $role', 'مرحباً، $name · $role');
  String get greetingMorning => _t('Good morning', 'صباح الخير');
  String get greetingAfternoon => _t('Good afternoon', 'مساء الخير');
  String get greetingEvening => _t('Good evening', 'مساء الخير');
  String get statOpen => _t('Open', 'مفتوحة');
  String get statClosed => _t('Closed', 'مغلقة');
  String get statTotal => _t('Total', 'الإجمالي');
  String mastersToClear(int count) {
    if (isAr) {
      if (count == 0) return 'لا توجد طلبات رئيسية.';
      if (count == 1) return 'طلب رئيسي واحد للإنجاز.';
      return '$count طلبات رئيسية للإنجاز.';
    }
    if (count == 0) return 'No master orders.';
    if (count == 1) return '1 master order to clear.';
    return '$count master orders to clear.';
  }

  String get searchHint => _t('Search master PO, vendor, SKU…',
      'ابحث عن طلب رئيسي أو مورّد أو رمز…');
  String get openSection => _t('Open', 'مفتوحة');
  String get recentlyClosedSection => _t('Recently closed', 'مغلقة مؤخراً');
  String get yardFeed => _t('Yard feed', 'أخبار الساحة');

  // ─── Vendor list ───
  String get masterPurchaseOrder => _t('Master Purchase Order', 'أمر الشراء الرئيسي');
  String get vendorPos => _t('Vendor POs', 'أوامر المورّدين');
  String vendors(int count) {
    if (isAr) return count == 1 ? 'مورّد واحد' : '$count مورّدون';
    return count == 1 ? '1 vendor' : '$count vendors';
  }

  String clearedRatio(int done, int total) =>
      _t('$done/$total vendor POs cleared', '$done/$total مكتمل');
  String clearedShort(int done, int total) =>
      _t('$done/$total cleared', '$done/$total مكتمل');
  String get mapAction => _t('Map', 'خريطة');
  String finalizedAt(String at) => _t('finalized $at', 'أُنهي في $at');

  // ─── Detail / steps ───
  String get items => _t('Items', 'البنود');
  String get stepCurrent => _t('Current step', 'الخطوة الحالية');
  String get stepCompleted => _t('Completed', 'مكتمل');
  String get stepInProgress => _t('In progress', 'قيد التنفيذ');
  String get shipmentPhoto => _t('Shipment photo', 'صورة الشحنة');
  String get itemPhoto => _t('Item photo', 'صورة البند');
  String get finalStep => _t('Final step', 'الخطوة النهائية');
  String get startVendor => _t('Start verification', 'بدء التحقق');
  String get captureShipment => _t('Capture shipment photo', 'التقاط صورة الشحنة');
  String get captureItems => _t('Capture item photos', 'التقاط صور البنود');
  String get viewProofs => _t('Proof history', 'سجل الإثبات');
  String get finalize => _t('Finalize', 'إنهاء');
  String get markMissing => _t('Mark missing', 'تحديد كمفقود');
  String get retake => _t('Retake', 'إعادة الالتقاط');
  String get submit => _t('Submit', 'إرسال');
  String get done => _t('Done', 'تم');

  // ─── Shipment capture ───
  String get shipmentCaptureTitle => _t('Shipment-level proof', 'إثبات على مستوى الشحنة');
  String get shipmentCaptureSubtitle => _t('Group photo + GPS for the whole delivery',
      'صورة جماعية + GPS للتسليم بأكمله');
  String get waitingGps => _t('Acquiring GPS lock…', 'جارٍ تثبيت موقع GPS…');
  String get gpsLocked => _t('GPS locked', 'تم تثبيت GPS');
  String get shutterLocked => _t('Wait for GPS lock to enable shutter', 'بانتظار GPS لتمكين الالتقاط');
  String get captureNow => _t('Capture', 'التقاط');
  String get pickItemTitle => _t('Pick an item', 'اختر بنداً');
  String get capturedBadge => _t('Captured', 'تم التقاطه');
  String get takePhoto => _t('Take photo', 'التقاط صورة');
  String get uploadFromGallery => _t('Upload from gallery', 'رفع من المعرض');
  String get choosePhotoSource =>
      _t('Add a photo', 'إضافة صورة');
  String get openSettings => _t('Open settings', 'فتح الإعدادات');
  String get gpsBlocked => _t('Location permission is required', 'إذن الموقع مطلوب');
  String get cameraBlocked => _t('Camera permission is required', 'إذن الكاميرا مطلوب');
  String get shipmentProofEyebrow => _t('SHIPMENT PROOF', 'إثبات الشحنة');
  String get frameUnloadingScene =>
      _t('Frame the entire unloading scene', 'اضبط مشهد التفريغ بالكامل');
  String get flip => _t('Flip', 'تبديل');
  String get hdr => _t('HDR', 'HDR');
  String get retry => _t('Retry', 'إعادة');

  // ─── Item loop ───
  String get itemLoopTitle => _t('Per-item verification', 'التحقق من كل بند');
  String get itemLoopSubtitle => _t('Capture proof for every line item', 'التقط إثباتاً لكل بند');
  String deliveredCount(int count) => _t('$count delivered', '$count مُسلَّمة');
  String missingCount(int count) => _t('$count missing', '$count مفقودة');
  String pendingCount(int count) => _t('$count pending', '$count قيد الانتظار');
  String itemsRemaining(int count) =>
      _t('$count items remaining', 'بقي $count عناصر');
  String capturedItem(String code, int remaining) => _t(
      '$code captured · $remaining items remaining',
      'تم التقاط $code · بقي $remaining عناصر');
  String uploadingItem(String code) => _t(
      'Uploading photo for $code…', 'جارٍ رفع صورة $code…');
  String get uploadingShipment =>
      _t('Uploading shipment photo…', 'جارٍ رفع صورة الشحنة…');
  String itemOfTotal(int index, int total) =>
      _t('Item $index of $total', 'البند $index من $total');
  String uploadingBadge(int count) =>
      _t('Uploading $count…', 'جارٍ رفع $count…');
  String failedBadge(int count) =>
      _t('$count failed · tap to retry', '$count فشل · اضغط لإعادة المحاولة');
  String get startItemCapture => _t('Start item capture', 'بدء التقاط البنود');
  String get confirmPhoto => _t('OK', 'موافق');
  String get nextItem => _t('Next', 'التالي');
  String get noPendingItems => _t('No pending items', 'لا توجد بنود معلقة');
  String markedMissingItem(String code, int remaining) => _t(
      '$code marked missing · $remaining items remaining',
      'تم تحديد $code كمفقود · بقي $remaining عناصر');
  String get allItemsCaptured =>
      _t('All items captured', 'تم التقاط جميع البنود');
  String get markMissingTitle => _t('Mark this item as missing?', 'تحديد هذا البند كمفقود؟');
  String get markMissingBody => _t(
      "This item won't be re-introduced into this Vendor PO. The Master PO will be recomputed.",
      'لن يُعاد إدخال هذا البند في أمر المورّد. سيُعاد احتساب الأمر الرئيسي.');
  String get markRejected => _t('Reject', 'رفض');
  String get markRejectedTitle =>
      _t('Reject this item at the final step?', 'رفض هذا البند في الخطوة النهائية؟');
  String get markRejectedBody => _t(
      'Rejection is recorded against this final step only. The item stays on the PO but is flagged.',
      'يُسجَّل الرفض على الخطوة النهائية فقط. يبقى البند ضمن الأمر مع وضع علامة الرفض.');
  String get confirm => _t('Confirm', 'تأكيد');
  String get cancel => _t('Cancel', 'إلغاء');

  // ─── Proofs ───
  String get proofsTitle => _t('Proof history', 'سجل الإثبات');
  String get shipmentProofs => _t('Shipment proofs', 'إثباتات الشحنة');
  String get itemProofs => _t('Item proofs', 'إثباتات البنود');
  String get autoCompleted => _t('Auto-completed', 'إنهاء تلقائي');
  String get noProofs => _t('No proofs uploaded yet', 'لا توجد إثباتات بعد');
  String get viewOnMap => _t('View location on map', 'عرض الموقع على الخريطة');
  String get locationUnavailable =>
      _t('Location not recorded for this proof.', 'لم يتم تسجيل موقع لهذا الإثبات.');
  String get mapOpenFailed =>
      _t('Couldn\'t open the map app.', 'تعذّر فتح تطبيق الخرائط.');
  String get imageLoadFailed => _t('Image failed to load.', 'تعذّر تحميل الصورة.');

  // ─── Finalize / handoff ───
  String get finalizeTitle => _t('Finalize Vendor PO', 'إنهاء أمر المورّد');
  String finalizeBody({required int delivered, required int missing, required int total, required String outcome}) =>
      _t(
          '$delivered delivered · $missing missing · $total total. The system will assign $outcome on submit.',
          '$delivered مُسلَّمة · $missing مفقودة · $total الإجمالي. النظام سيُسجِّل $outcome عند الإرسال.');
  String get fullyDelivered => _t('FULLY DELIVERED', 'تسليم كامل');
  String get partiallyDelivered => _t('PARTIALLY DELIVERED', 'تسليم جزئي');
  String get finalizeBlocked => _t(
      'Resolve every item (delivered or missing) before submitting.',
      'حل كل البنود (تسليم أو مفقود) قبل الإرسال.');

  String get handoffTitle => _t('Audit row sealed', 'تم ختم سجل التدقيق');
  String get handoffBody => _t(
      'Master PO progress recomputed. Procurement has been notified.',
      'أُعيد حساب تقدُّم الأمر الرئيسي. تم إشعار المشتريات.');
  String get backToDashboard => _t('Back to dashboard', 'العودة إلى لوحة التحكم');

  // ─── Step done ───
  String get stepDoneTitle => _t('Step complete', 'اكتملت الخطوة');
  String stepLockedHint(String requiredStepName) => _t(
      'Complete "$requiredStepName" first to unlock this step.',
      'أكمل "$requiredStepName" أولاً لفتح هذه الخطوة.');
  String get finalizeBlockedSteps => _t(
      'Finish every step before finalizing.',
      'أكمل جميع الخطوات قبل الإنهاء.');
  String stepDoneSubtitle(String stepName) =>
      _t('$stepName captured and uploaded.', 'تم التقاط ورفع $stepName.');
  String get stepDoneContinue => _t('Continue to next step', 'الانتقال إلى الخطوة التالية');
  String get stepDoneFinalize => _t('Finalize delivery', 'إنهاء التسليم');
  String get stepDoneAwaitingUploads =>
      _t('Waiting for background uploads to finish…',
          'في انتظار اكتمال الرفع في الخلفية…');
  String stepDoneFailedUploads(int n) => _t(
      '$n upload(s) failed — retry before continuing.',
      'فشل رفع $n عنصر — أعد المحاولة قبل المتابعة.');

  // ─── Settings ───
  String get languageEnglish => 'English';
  String get languageArabic => 'العربية';
  String get toggleLanguage => _t('Language', 'اللغة');
  String get logout => _t('Sign out', 'تسجيل الخروج');
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppL10n.supported.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppL10n> load(Locale locale) async => AppL10n(locale);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}
