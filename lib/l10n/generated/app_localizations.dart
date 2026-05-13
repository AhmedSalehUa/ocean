import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
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
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n? of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n);
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

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

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Ocean Delivery'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Chain of custody,\nverified at the bay.'**
  String get tagline;

  /// No description provided for @loginEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Representative sign-in'**
  String get loginEyebrow;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @verifyingToken.
  ///
  /// In en, this message translates to:
  /// **'Verifying token…'**
  String get verifyingToken;

  /// No description provided for @jwtFooter.
  ///
  /// In en, this message translates to:
  /// **'JWT · Role REPRESENTATIVE only'**
  String get jwtFooter;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© Ocean Delivery · Audit ledger'**
  String get copyright;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} · {role}'**
  String greeting(Object name, Object role);

  /// No description provided for @mastersToClear.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No master orders} =1{1 master order to clear.} other{{count} master orders to clear.}}'**
  String mastersToClear(num count);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search master PO, vendor, SKU…'**
  String get searchHint;

  /// No description provided for @openSection.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openSection;

  /// No description provided for @recentlyClosedSection.
  ///
  /// In en, this message translates to:
  /// **'Recently closed'**
  String get recentlyClosedSection;

  /// No description provided for @yardFeed.
  ///
  /// In en, this message translates to:
  /// **'Yard feed'**
  String get yardFeed;

  /// No description provided for @masterPurchaseOrder.
  ///
  /// In en, this message translates to:
  /// **'Master Purchase Order'**
  String get masterPurchaseOrder;

  /// No description provided for @vendorPos.
  ///
  /// In en, this message translates to:
  /// **'Vendor POs'**
  String get vendorPos;

  /// No description provided for @vendors.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 vendor} other{{count} vendors}}'**
  String vendors(num count);

  /// No description provided for @clearedRatio.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} vendor POs cleared'**
  String clearedRatio(Object done, Object total);

  /// No description provided for @clearedShort.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} cleared'**
  String clearedShort(Object done, Object total);

  /// No description provided for @mapAction.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapAction;

  /// No description provided for @finalizedAt.
  ///
  /// In en, this message translates to:
  /// **'finalized {at}'**
  String finalizedAt(Object at);

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @stepCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current step'**
  String get stepCurrent;

  /// No description provided for @stepCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get stepCompleted;

  /// No description provided for @stepInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get stepInProgress;

  /// No description provided for @shipmentPhoto.
  ///
  /// In en, this message translates to:
  /// **'Shipment photo'**
  String get shipmentPhoto;

  /// No description provided for @itemPhoto.
  ///
  /// In en, this message translates to:
  /// **'Item photo'**
  String get itemPhoto;

  /// No description provided for @finalStep.
  ///
  /// In en, this message translates to:
  /// **'Final step'**
  String get finalStep;

  /// No description provided for @startVendor.
  ///
  /// In en, this message translates to:
  /// **'Start verification'**
  String get startVendor;

  /// No description provided for @captureShipment.
  ///
  /// In en, this message translates to:
  /// **'Capture shipment photo'**
  String get captureShipment;

  /// No description provided for @captureItems.
  ///
  /// In en, this message translates to:
  /// **'Capture item photos'**
  String get captureItems;

  /// No description provided for @viewProofs.
  ///
  /// In en, this message translates to:
  /// **'Proof history'**
  String get viewProofs;

  /// No description provided for @finalize.
  ///
  /// In en, this message translates to:
  /// **'Finalize'**
  String get finalize;

  /// No description provided for @markMissing.
  ///
  /// In en, this message translates to:
  /// **'Mark missing'**
  String get markMissing;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @shipmentCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Shipment-level proof'**
  String get shipmentCaptureTitle;

  /// No description provided for @shipmentCaptureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Group photo + GPS for the whole delivery'**
  String get shipmentCaptureSubtitle;

  /// No description provided for @waitingGps.
  ///
  /// In en, this message translates to:
  /// **'Acquiring GPS lock…'**
  String get waitingGps;

  /// No description provided for @gpsLocked.
  ///
  /// In en, this message translates to:
  /// **'GPS locked'**
  String get gpsLocked;

  /// No description provided for @shutterLocked.
  ///
  /// In en, this message translates to:
  /// **'Wait for GPS lock to enable shutter'**
  String get shutterLocked;

  /// No description provided for @captureNow.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get captureNow;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @gpsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required'**
  String get gpsBlocked;

  /// No description provided for @cameraBlocked.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required'**
  String get cameraBlocked;

  /// No description provided for @itemLoopTitle.
  ///
  /// In en, this message translates to:
  /// **'Per-item verification'**
  String get itemLoopTitle;

  /// No description provided for @itemLoopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture proof for every line item'**
  String get itemLoopSubtitle;

  /// No description provided for @deliveredCount.
  ///
  /// In en, this message translates to:
  /// **'{count} delivered'**
  String deliveredCount(Object count);

  /// No description provided for @missingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} missing'**
  String missingCount(Object count);

  /// No description provided for @pendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingCount(Object count);

  /// No description provided for @markMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark this item as missing?'**
  String get markMissingTitle;

  /// No description provided for @markMissingBody.
  ///
  /// In en, this message translates to:
  /// **'This item won\'t be re-introduced into this Vendor PO. The Master PO will be recomputed.'**
  String get markMissingBody;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @proofsTitle.
  ///
  /// In en, this message translates to:
  /// **'Proof history'**
  String get proofsTitle;

  /// No description provided for @shipmentProofs.
  ///
  /// In en, this message translates to:
  /// **'Shipment proofs'**
  String get shipmentProofs;

  /// No description provided for @itemProofs.
  ///
  /// In en, this message translates to:
  /// **'Item proofs'**
  String get itemProofs;

  /// No description provided for @autoCompleted.
  ///
  /// In en, this message translates to:
  /// **'Auto-completed'**
  String get autoCompleted;

  /// No description provided for @noProofs.
  ///
  /// In en, this message translates to:
  /// **'No proofs uploaded yet'**
  String get noProofs;

  /// No description provided for @finalizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Finalize Vendor PO'**
  String get finalizeTitle;

  /// No description provided for @finalizeBody.
  ///
  /// In en, this message translates to:
  /// **'{delivered} delivered · {missing} missing · {total} total. The system will assign {outcome} on submit.'**
  String finalizeBody(
      Object delivered, Object missing, Object total, Object outcome);

  /// No description provided for @fullyDelivered.
  ///
  /// In en, this message translates to:
  /// **'FULLY DELIVERED'**
  String get fullyDelivered;

  /// No description provided for @partiallyDelivered.
  ///
  /// In en, this message translates to:
  /// **'PARTIALLY DELIVERED'**
  String get partiallyDelivered;

  /// No description provided for @finalizeBlocked.
  ///
  /// In en, this message translates to:
  /// **'Resolve every item (delivered or missing) before submitting.'**
  String get finalizeBlocked;

  /// No description provided for @handoffTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit row sealed'**
  String get handoffTitle;

  /// No description provided for @handoffBody.
  ///
  /// In en, this message translates to:
  /// **'Master PO progress recomputed. Procurement has been notified.'**
  String get handoffBody;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to dashboard'**
  String get backToDashboard;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @toggleLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get toggleLanguage;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppL10nAr();
    case 'en':
      return AppL10nEn();
  }

  throw FlutterError(
      'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
