// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Ocean Delivery';

  @override
  String get tagline => 'Chain of custody,\nverified at the bay.';

  @override
  String get loginEyebrow => 'Representative sign-in';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get continueAction => 'Continue';

  @override
  String get verifyingToken => 'Verifying token…';

  @override
  String get jwtFooter => 'JWT · Role REPRESENTATIVE only';

  @override
  String get copyright => '© Ocean Delivery · Audit ledger';

  @override
  String greeting(Object name, Object role) {
    return 'Hi, $name · $role';
  }

  @override
  String mastersToClear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count master orders to clear.',
      one: '1 master order to clear.',
      zero: 'No master orders',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Search master PO, vendor, SKU…';

  @override
  String get openSection => 'Open';

  @override
  String get recentlyClosedSection => 'Recently closed';

  @override
  String get yardFeed => 'Yard feed';

  @override
  String get masterPurchaseOrder => 'Master Purchase Order';

  @override
  String get vendorPos => 'Vendor POs';

  @override
  String vendors(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vendors',
      one: '1 vendor',
    );
    return '$_temp0';
  }

  @override
  String clearedRatio(Object done, Object total) {
    return '$done/$total vendor POs cleared';
  }

  @override
  String clearedShort(Object done, Object total) {
    return '$done/$total cleared';
  }

  @override
  String get mapAction => 'Map';

  @override
  String finalizedAt(Object at) {
    return 'finalized $at';
  }

  @override
  String get items => 'Items';

  @override
  String get stepCurrent => 'Current step';

  @override
  String get stepCompleted => 'Completed';

  @override
  String get stepInProgress => 'In progress';

  @override
  String get shipmentPhoto => 'Shipment photo';

  @override
  String get itemPhoto => 'Item photo';

  @override
  String get finalStep => 'Final step';

  @override
  String get startVendor => 'Start verification';

  @override
  String get captureShipment => 'Capture shipment photo';

  @override
  String get captureItems => 'Capture item photos';

  @override
  String get viewProofs => 'Proof history';

  @override
  String get finalize => 'Finalize';

  @override
  String get markMissing => 'Mark missing';

  @override
  String get retake => 'Retake';

  @override
  String get submit => 'Submit';

  @override
  String get done => 'Done';

  @override
  String get shipmentCaptureTitle => 'Shipment-level proof';

  @override
  String get shipmentCaptureSubtitle =>
      'Group photo + GPS for the whole delivery';

  @override
  String get waitingGps => 'Acquiring GPS lock…';

  @override
  String get gpsLocked => 'GPS locked';

  @override
  String get shutterLocked => 'Wait for GPS lock to enable shutter';

  @override
  String get captureNow => 'Capture';

  @override
  String get openSettings => 'Open settings';

  @override
  String get gpsBlocked => 'Location permission is required';

  @override
  String get cameraBlocked => 'Camera permission is required';

  @override
  String get itemLoopTitle => 'Per-item verification';

  @override
  String get itemLoopSubtitle => 'Capture proof for every line item';

  @override
  String deliveredCount(Object count) {
    return '$count delivered';
  }

  @override
  String missingCount(Object count) {
    return '$count missing';
  }

  @override
  String pendingCount(Object count) {
    return '$count pending';
  }

  @override
  String get markMissingTitle => 'Mark this item as missing?';

  @override
  String get markMissingBody =>
      'This item won\'t be re-introduced into this Vendor PO. The Master PO will be recomputed.';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get proofsTitle => 'Proof history';

  @override
  String get shipmentProofs => 'Shipment proofs';

  @override
  String get itemProofs => 'Item proofs';

  @override
  String get autoCompleted => 'Auto-completed';

  @override
  String get noProofs => 'No proofs uploaded yet';

  @override
  String get finalizeTitle => 'Finalize Vendor PO';

  @override
  String finalizeBody(
      Object delivered, Object missing, Object total, Object outcome) {
    return '$delivered delivered · $missing missing · $total total. The system will assign $outcome on submit.';
  }

  @override
  String get fullyDelivered => 'FULLY DELIVERED';

  @override
  String get partiallyDelivered => 'PARTIALLY DELIVERED';

  @override
  String get finalizeBlocked =>
      'Resolve every item (delivered or missing) before submitting.';

  @override
  String get handoffTitle => 'Audit row sealed';

  @override
  String get handoffBody =>
      'Master PO progress recomputed. Procurement has been notified.';

  @override
  String get backToDashboard => 'Back to dashboard';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get toggleLanguage => 'Language';

  @override
  String get logout => 'Sign out';
}
