import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('ta'),
    Locale('te'),
  ];

  /// App name (brand mark, do not translate).
  ///
  /// In en, this message translates to:
  /// **'RADHA'**
  String get appName;

  /// One-line app tagline shown on splash and onboarding.
  ///
  /// In en, this message translates to:
  /// **'Retail Assistant for Data, Health & Audits.'**
  String get tagline;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'We sent you a 6-digit code'**
  String get otpSent;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @expiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get expiry;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @scanProduct.
  ///
  /// In en, this message translates to:
  /// **'Scan a product'**
  String get scanProduct;

  /// No description provided for @pointAtBarcode.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at a barcode'**
  String get pointAtBarcode;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanAgain;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// No description provided for @expiryTracker.
  ///
  /// In en, this message translates to:
  /// **'Expiry tracker'**
  String get expiryTracker;

  /// No description provided for @addExpiry.
  ///
  /// In en, this message translates to:
  /// **'Add expiry'**
  String get addExpiry;

  /// No description provided for @expiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get expiringSoon;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @yourTasks.
  ///
  /// In en, this message translates to:
  /// **'Your tasks'**
  String get yourTasks;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasks;

  /// No description provided for @completeTask.
  ///
  /// In en, this message translates to:
  /// **'Complete task'**
  String get completeTask;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan, track, audit your stock without the spreadsheets.'**
  String get welcomeMessage;

  /// No description provided for @referrals.
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get referrals;

  /// No description provided for @shareYourCode.
  ///
  /// In en, this message translates to:
  /// **'Share your code'**
  String get shareYourCode;

  /// No description provided for @yourReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Your referral code'**
  String get yourReferralCode;

  /// No description provided for @invitees.
  ///
  /// In en, this message translates to:
  /// **'Invitees'**
  String get invitees;

  /// No description provided for @rewardsEarned.
  ///
  /// In en, this message translates to:
  /// **'Rewards earned'**
  String get rewardsEarned;

  /// No description provided for @redeemCode.
  ///
  /// In en, this message translates to:
  /// **'Redeem code'**
  String get redeemCode;

  /// No description provided for @enterReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Enter a referral code'**
  String get enterReferralCode;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageUpdated;

  /// Fallback error shown when the backend returns no recognised code.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// OTP rate limit (HTTP 429) — backend code E3007 or generic E1004.
  ///
  /// In en, this message translates to:
  /// **'Too many OTP requests. Try again in {seconds} seconds.'**
  String errorRateLimitOtp(int seconds);

  /// OTP did not verify (E3005).
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP. Please try again.'**
  String get errorOtpInvalid;

  /// OTP request window elapsed (E3006).
  ///
  /// In en, this message translates to:
  /// **'OTP expired. Please request a new one.'**
  String get errorOtpExpired;

  /// Session missing / token expired (E3000, E3002).
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue.'**
  String get errorAuthRequired;

  /// Generic 404 (E5000).
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get errorNotFound;

  /// Title shown when fetching an ingredient explanation fails (FE-19).
  ///
  /// In en, this message translates to:
  /// **'Could not load explanation'**
  String get ingredientExplainerErrorTitle;

  /// Section header above the bullet list on the ingredient explainer screen (FE-19).
  ///
  /// In en, this message translates to:
  /// **'Health considerations'**
  String get ingredientExplainerHealthConsiderations;

  /// AppBar title on the healthy alternatives screen (FE-22) when the source product name is known.
  ///
  /// In en, this message translates to:
  /// **'Better choices than {productName}'**
  String healthyAlternativesTitle(String productName);

  /// AppBar title on the healthy alternatives screen (FE-22) when the source product name is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Better choices'**
  String get healthyAlternativesGenericTitle;

  /// Empty-state title on the healthy alternatives screen (FE-22).
  ///
  /// In en, this message translates to:
  /// **'No healthier alternatives yet'**
  String get healthyAlternativesEmptyTitle;

  /// Empty-state body on the healthy alternatives screen (FE-22).
  ///
  /// In en, this message translates to:
  /// **'No healthier alternatives found in the same category yet.'**
  String get healthyAlternativesEmptyBody;

  /// Error-state title on the healthy alternatives screen (FE-22).
  ///
  /// In en, this message translates to:
  /// **'Could not load alternatives'**
  String get healthyAlternativesErrorTitle;

  /// CTA on each alternative card to add the item to the shopping list (FE-22).
  ///
  /// In en, this message translates to:
  /// **'Add to shopping list'**
  String get healthyAlternativesAddToList;

  /// Primary CTA on each alternative card to open the product's scan-result page (FE-22).
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get healthyAlternativesView;

  /// Snackbar confirmation after adding an alternative to the shopping list (FE-22).
  ///
  /// In en, this message translates to:
  /// **'Added to your shopping list'**
  String get healthyAlternativesAddedToList;

  /// Snackbar shown when adding an alternative to the shopping list fails (FE-22).
  ///
  /// In en, this message translates to:
  /// **'Could not add to shopping list'**
  String get healthyAlternativesAddFailed;

  /// AppBar title on the saved products screen (FE-16).
  ///
  /// In en, this message translates to:
  /// **'Saved products'**
  String get savedProductsTitle;

  /// Empty-state title on the saved products screen (FE-16).
  ///
  /// In en, this message translates to:
  /// **'Saved products'**
  String get savedProductsEmptyTitle;

  /// Empty-state body on the saved products screen (FE-16).
  ///
  /// In en, this message translates to:
  /// **'Save products from the scan result screen to see them here.'**
  String get savedProductsEmptyBody;

  /// Error-state title on the saved products screen (FE-16).
  ///
  /// In en, this message translates to:
  /// **'Could not load saved products'**
  String get savedProductsErrorTitle;

  /// Subtitle showing when a saved product was bookmarked (FE-16).
  ///
  /// In en, this message translates to:
  /// **'Saved {date}'**
  String savedProductsSavedOn(String date);

  /// Hero headline on the weekly digest landing screen (FE-24).
  ///
  /// In en, this message translates to:
  /// **'Your week with RADHA'**
  String get digestTitle;

  /// Subtitle below the digest hero showing the week range, e.g. 'May 19 – May 25, 2026' (FE-24).
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String digestWeekRange(String start, String end);

  /// Hero metric on the weekly digest when estimated savings is greater than zero (FE-24).
  ///
  /// In en, this message translates to:
  /// **'₹{amount} saved'**
  String digestSavingsHero(String amount);

  /// Hero metric on the weekly digest when savings is zero — falls back to scan count (FE-24).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 scan} other{{count} scans}}'**
  String digestScansHero(int count);

  /// Hero metric headline shown when the user has no activity for the week (FE-24).
  ///
  /// In en, this message translates to:
  /// **'A quiet week'**
  String get digestHeroEmptyHeadline;

  /// Stat label for total scans (FE-24).
  ///
  /// In en, this message translates to:
  /// **'Scans'**
  String get digestScans;

  /// Stat label for saved products count (FE-24).
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get digestSavedProducts;

  /// Stat label for items expiring this week (FE-24).
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get digestExpiringSoon;

  /// Headline on the recall alerts call-out card (FE-24).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recall alert} other{{count} recall alerts}}'**
  String digestRecallAlerts(int count);

  /// Body copy on the recall alerts call-out card (FE-24).
  ///
  /// In en, this message translates to:
  /// **'Products you scanned this week have new safety advisories.'**
  String get digestRecallAlertsBody;

  /// CTA on the recall alerts call-out card linking to /recall-alerts (FE-24).
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get digestRecallAlertsCta;

  /// Section header above the top categories bar list (FE-24).
  ///
  /// In en, this message translates to:
  /// **'What you\'re scanning'**
  String get digestTopCategoriesHeader;

  /// Section header above the health highlights bullet list (FE-24).
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get digestHighlightsHeader;

  /// Primary CTA in the digest action footer routing to /scan (FE-24).
  ///
  /// In en, this message translates to:
  /// **'Continue scanning'**
  String get digestContinueScanning;

  /// Secondary text CTA in the digest footer that opens the native share sheet (FE-24).
  ///
  /// In en, this message translates to:
  /// **'Share my week'**
  String get digestShare;

  /// Body of the native share intent fired from the weekly digest screen (FE-24).
  ///
  /// In en, this message translates to:
  /// **'I scanned {scans} products this week and saved ₹{savings} with RADHA. Try it: https://radha.app'**
  String digestShareTemplate(int scans, String savings);

  /// Empty-state title on the weekly digest screen (FE-24).
  ///
  /// In en, this message translates to:
  /// **'No activity this week'**
  String get digestEmptyTitle;

  /// Empty-state body on the weekly digest screen (FE-24).
  ///
  /// In en, this message translates to:
  /// **'Start scanning to build your weekly story.'**
  String get digestEmptyBody;

  /// Error-state title on the weekly digest screen (FE-24).
  ///
  /// In en, this message translates to:
  /// **'Could not load your weekly digest'**
  String get digestErrorTitle;

  /// AppBar title for the Settings hub (FE-32).
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Notifications section header in Settings hub (FE-32).
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get settingsPushNotifications;

  /// No description provided for @settingsPushNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Get alerts on your phone'**
  String get settingsPushNotificationsHint;

  /// No description provided for @settingsRecallAlerts.
  ///
  /// In en, this message translates to:
  /// **'Recall alerts'**
  String get settingsRecallAlerts;

  /// No description provided for @settingsRecallAlertsHint.
  ///
  /// In en, this message translates to:
  /// **'Be told when a product you scanned is recalled'**
  String get settingsRecallAlertsHint;

  /// No description provided for @settingsWeeklyDigest.
  ///
  /// In en, this message translates to:
  /// **'Weekly digest'**
  String get settingsWeeklyDigest;

  /// No description provided for @settingsWeeklyDigestHint.
  ///
  /// In en, this message translates to:
  /// **'Sunday summary of your scans and savings'**
  String get settingsWeeklyDigestHint;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsTextSize;

  /// No description provided for @settingsTextSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get settingsTextSizeSmall;

  /// No description provided for @settingsTextSizeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get settingsTextSizeStandard;

  /// No description provided for @settingsTextSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get settingsTextSizeLarge;

  /// No description provided for @settingsDataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Data & privacy'**
  String get settingsDataPrivacy;

  /// No description provided for @settingsAllergens.
  ///
  /// In en, this message translates to:
  /// **'Allergen profile'**
  String get settingsAllergens;

  /// No description provided for @settingsAllergensHint.
  ///
  /// In en, this message translates to:
  /// **'Pick the ingredients we should warn you about'**
  String get settingsAllergensHint;

  /// No description provided for @settingsSignOutAll.
  ///
  /// In en, this message translates to:
  /// **'Sign out from all devices'**
  String get settingsSignOutAll;

  /// No description provided for @settingsSignOutAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out everywhere?'**
  String get settingsSignOutAllConfirmTitle;

  /// No description provided for @settingsSignOutAllConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again on every device that uses this account.'**
  String get settingsSignOutAllConfirmBody;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your data. Type DELETE to confirm.'**
  String get settingsDeleteAccountBody;

  /// No description provided for @settingsDeleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get settingsDeleteAccountConfirm;

  /// No description provided for @settingsDeleteAccountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Contact support to delete your account.'**
  String get settingsDeleteAccountUnavailable;

  /// No description provided for @settingsDeleteAccountContact.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get settingsDeleteAccountContact;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get settingsTerms;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settingsVersion;

  /// Subtitle on the App version row in Settings hub.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String settingsVersionValue(String version, String build);

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// No description provided for @settingsSupportHint.
  ///
  /// In en, this message translates to:
  /// **'Get help, report a bug, or share feedback'**
  String get settingsSupportHint;

  /// No description provided for @settingsLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get settingsLinkOpenFailed;

  /// Sticky banner shown when the offline queue has unresolved sync conflicts (FE-34).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 conflict needs your attention} other{{count} conflicts need your attention}}'**
  String conflictBannerCount(int count);

  /// No description provided for @conflictBannerCta.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get conflictBannerCta;

  /// No description provided for @conflictBannerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get conflictBannerDismiss;

  /// No description provided for @conflictResolveTitle.
  ///
  /// In en, this message translates to:
  /// **'Resolve sync conflicts'**
  String get conflictResolveTitle;

  /// No description provided for @conflictResolveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick which version to keep for each item.'**
  String get conflictResolveSubtitle;

  /// No description provided for @conflictUseMine.
  ///
  /// In en, this message translates to:
  /// **'Use my version'**
  String get conflictUseMine;

  /// No description provided for @conflictUseServer.
  ///
  /// In en, this message translates to:
  /// **'Use server version'**
  String get conflictUseServer;

  /// No description provided for @conflictResolved.
  ///
  /// In en, this message translates to:
  /// **'Conflict resolved'**
  String get conflictResolved;

  /// No description provided for @conflictResolvedAll.
  ///
  /// In en, this message translates to:
  /// **'All conflicts resolved'**
  String get conflictResolvedAll;

  /// Sub-label on a conflict card showing how many sync attempts have been made.
  ///
  /// In en, this message translates to:
  /// **'Tried {count, plural, =1{1 time} other{{count} times}}'**
  String conflictAttempts(int count);

  /// No description provided for @conflictResourceTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get conflictResourceTask;

  /// No description provided for @conflictResourceExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry record'**
  String get conflictResourceExpiry;

  /// No description provided for @conflictResourceScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get conflictResourceScan;

  /// No description provided for @conflictResourceInventory.
  ///
  /// In en, this message translates to:
  /// **'Stock adjustment'**
  String get conflictResourceInventory;

  /// No description provided for @conflictResourceGrn.
  ///
  /// In en, this message translates to:
  /// **'GRN entry'**
  String get conflictResourceGrn;

  /// No description provided for @conflictResourceShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping list item'**
  String get conflictResourceShoppingList;

  /// No description provided for @conflictResourceGeneric.
  ///
  /// In en, this message translates to:
  /// **'Sync change'**
  String get conflictResourceGeneric;

  /// One-line summary of the user's local edit shown on a conflict card (FE-34).
  ///
  /// In en, this message translates to:
  /// **'Your change: {summary}'**
  String conflictLocalChangeSummary(String summary);

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportTitle;

  /// No description provided for @supportContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get supportContactUs;

  /// No description provided for @supportEmailUs.
  ///
  /// In en, this message translates to:
  /// **'Email us'**
  String get supportEmailUs;

  /// No description provided for @supportEmailUsHint.
  ///
  /// In en, this message translates to:
  /// **'support@radha.app'**
  String get supportEmailUsHint;

  /// No description provided for @supportCallUs.
  ///
  /// In en, this message translates to:
  /// **'Call support'**
  String get supportCallUs;

  /// No description provided for @supportCallUsHint.
  ///
  /// In en, this message translates to:
  /// **'Mon–Fri, 9am–6pm IST'**
  String get supportCallUsHint;

  /// No description provided for @supportReportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get supportReportBug;

  /// No description provided for @supportBugDescription.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get supportBugDescription;

  /// No description provided for @supportBugDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what you were doing when it broke.'**
  String get supportBugDescriptionHint;

  /// No description provided for @supportAttachScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Attach screenshot'**
  String get supportAttachScreenshot;

  /// No description provided for @supportScreenshotAttached.
  ///
  /// In en, this message translates to:
  /// **'Screenshot attached'**
  String get supportScreenshotAttached;

  /// No description provided for @supportRemoveScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get supportRemoveScreenshot;

  /// No description provided for @supportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get supportSubmit;

  /// No description provided for @supportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thanks — we received your report.'**
  String get supportSubmitted;

  /// No description provided for @supportSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send. Please email us instead.'**
  String get supportSubmitFailed;

  /// No description provided for @supportBugDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please describe what happened.'**
  String get supportBugDescriptionRequired;

  /// No description provided for @supportFaq.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get supportFaq;

  /// No description provided for @supportFaqQ1.
  ///
  /// In en, this message translates to:
  /// **'How do I scan a barcode?'**
  String get supportFaqQ1;

  /// No description provided for @supportFaqA1.
  ///
  /// In en, this message translates to:
  /// **'Open the Scan tab, point your camera at the barcode, and hold steady. We\'ll find the product the moment we read a clean code.'**
  String get supportFaqA1;

  /// No description provided for @supportFaqQ2.
  ///
  /// In en, this message translates to:
  /// **'What if a product isn\'t in the database?'**
  String get supportFaqQ2;

  /// No description provided for @supportFaqA2.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add product\" on the not-found screen and we\'ll create a new entry tied to your store. The catalog grows for everyone over time.'**
  String get supportFaqA2;

  /// No description provided for @supportFaqQ3.
  ///
  /// In en, this message translates to:
  /// **'How do I cancel my subscription?'**
  String get supportFaqQ3;

  /// No description provided for @supportFaqA3.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile → Subscription. You can cancel anytime; we don\'t charge after the next billing cycle starts.'**
  String get supportFaqA3;

  /// No description provided for @supportFaqQ4.
  ///
  /// In en, this message translates to:
  /// **'Why am I seeing a recall alert?'**
  String get supportFaqQ4;

  /// No description provided for @supportFaqA4.
  ///
  /// In en, this message translates to:
  /// **'We match every scan against the FSSAI recall feed. If a batch you sold is on the list, we surface it so you can pull stock and notify customers.'**
  String get supportFaqA4;

  /// No description provided for @supportFaqQ5.
  ///
  /// In en, this message translates to:
  /// **'How do I share my allergen profile with family?'**
  String get supportFaqQ5;

  /// No description provided for @supportFaqA5.
  ///
  /// In en, this message translates to:
  /// **'Allergen profiles are per-account today. Share them with family by signing in on the same household account, or pick the same allergens on each phone.'**
  String get supportFaqA5;

  /// AppBar title on the Reports & Exports screen (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Reports & exports'**
  String get reportsTitle;

  /// Tab label for the Available section (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get reportsTabAvailable;

  /// Tab label for the Scheduled section (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get reportsTabScheduled;

  /// Tab label for the History section (FE-30).
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get reportsTabHistory;

  /// Section header above the 2x2 quick-exports grid (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Quick exports'**
  String get reportsQuickExportsHeader;

  /// Quick-export tile title for the inventory snapshot (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Inventory snapshot'**
  String get reportsInventorySnapshot;

  /// Quick-export tile title for the expiring items report (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Expiring items'**
  String get reportsExpiringItems;

  /// Quick-export tile title for the sales summary (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Sales summary'**
  String get reportsSalesSummary;

  /// Quick-export tile title for the audit log (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get reportsAuditLog;

  /// Primary CTA in the export config bottom sheet (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get reportsGenerate;

  /// Snackbar confirming the export download was opened (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Report ready'**
  String get reportsGenerateSuccess;

  /// Snackbar shown when a generate request was accepted but the file isn't downloadable yet (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Generation started — we\'ll notify you when it\'s ready'**
  String get reportsGenerateQueued;

  /// Snackbar shown when the generate API call fails outright (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Could not start the report'**
  String get reportsGenerateFailed;

  /// Snackbar shown when the presigned URL fails to launch (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Could not open the download'**
  String get reportsDownloadFailed;

  /// FAB label on the Scheduled tab (FE-30).
  ///
  /// In en, this message translates to:
  /// **'New schedule'**
  String get reportsScheduleNew;

  /// Primary CTA in the scheduler bottom sheet (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Create schedule'**
  String get reportsScheduleCreate;

  /// Snackbar confirming a new recurring schedule was created (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Schedule created'**
  String get reportsScheduleSuccess;

  /// Section label in the scheduler bottom sheet selecting which report to schedule (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportsScheduleReportLabel;

  /// Section label in the scheduler bottom sheet selecting which weekday to fire on (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Day of week'**
  String get reportsScheduleDayOfWeek;

  /// Section label in the scheduler bottom sheet selecting which day of the month to fire on (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get reportsScheduleDayOfMonth;

  /// Section label in the scheduler bottom sheet selecting the hour to fire (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reportsScheduleTime;

  /// Section label in the scheduler bottom sheet selecting the export format (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get reportsScheduleFormat;

  /// Tooltip on the per-row schedule actions menu (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Schedule actions'**
  String get reportsScheduleActionsTooltip;

  /// Section label in the scheduler bottom sheet selecting how often the report fires (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get reportsFrequency;

  /// Daily-frequency choice (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get reportsFrequencyDaily;

  /// Weekly-frequency choice (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get reportsFrequencyWeekly;

  /// Monthly-frequency choice (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get reportsFrequencyMonthly;

  /// Per-row action label that pauses a recurring schedule (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get reportsPause;

  /// Per-row action label that resumes a paused schedule (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get reportsResume;

  /// Per-row destructive action label for a recurring schedule (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get reportsDelete;

  /// Confirmation dialog title shown before cancelling a recurring schedule (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Delete schedule?'**
  String get reportsDeleteScheduleTitle;

  /// Confirmation dialog body for cancelling a recurring schedule (FE-30).
  ///
  /// In en, this message translates to:
  /// **'This recurring schedule will stop firing. Past runs stay in your history.'**
  String get reportsDeleteScheduleBody;

  /// Subtitle on a scheduled-report row showing when the schedule last fired (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Last run {when}'**
  String reportsLastRun(String when);

  /// Subtitle on a scheduled-report row that hasn't fired yet (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Hasn\'t run yet'**
  String get reportsLastRunNever;

  /// Subtitle on a scheduled-report row showing the next firing time (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Next run {when}'**
  String reportsNextRun(String when);

  /// Tooltip / label on a per-row download icon button on the History tab (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get reportsDownload;

  /// Status pill label for a completed report (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get reportsStatusCompleted;

  /// Status pill label for a pending or in-flight report (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Generating'**
  String get reportsStatusGenerating;

  /// Status pill label for a failed report (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get reportsStatusFailed;

  /// Status pill label for a cancelled report (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get reportsStatusCancelled;

  /// Status pill label for a report whose artefacts have expired (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get reportsStatusExpired;

  /// Empty-state title on the History tab (FE-30).
  ///
  /// In en, this message translates to:
  /// **'No exports yet'**
  String get reportsEmptyTitle;

  /// Empty-state body on the History tab (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Generate a report from the Available tab and it\'ll show up here.'**
  String get reportsEmptyBody;

  /// Empty-state title on the Scheduled tab (FE-30).
  ///
  /// In en, this message translates to:
  /// **'No scheduled reports'**
  String get reportsScheduledEmptyTitle;

  /// Empty-state body on the Scheduled tab (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Tap New schedule to have a report run automatically.'**
  String get reportsScheduledEmptyBody;

  /// Error-state title shown when the reports list fails to load (FE-30).
  ///
  /// In en, this message translates to:
  /// **'Could not load reports'**
  String get reportsErrorTitle;

  /// AppBar / hero title on the OHS Dashboard screen (FE-26).
  ///
  /// In en, this message translates to:
  /// **'Operational health'**
  String get ohsTitle;

  /// Eyebrow caption above the headline OHS score (FE-26).
  ///
  /// In en, this message translates to:
  /// **'OHS score'**
  String get ohsScoreCaption;

  /// Headline OHS score, rendered in JetBrains Mono. The placeholder is the integer 0-100 derived from the dashboard summary (FE-26).
  ///
  /// In en, this message translates to:
  /// **'{score}'**
  String ohsScore(int score);

  /// Subtitle below the OHS score when the week-over-week delta is positive (FE-26).
  ///
  /// In en, this message translates to:
  /// **'+{value} from last week'**
  String ohsDeltaUp(int value);

  /// Subtitle below the OHS score when the week-over-week delta is negative (FE-26).
  ///
  /// In en, this message translates to:
  /// **'-{value} from last week'**
  String ohsDeltaDown(int value);

  /// Subtitle below the OHS score when this week matches last week (FE-26).
  ///
  /// In en, this message translates to:
  /// **'No change from last week'**
  String get ohsDeltaSame;

  /// Subtitle below the OHS score when there's no prior week to compare to (FE-26).
  ///
  /// In en, this message translates to:
  /// **'Not enough data for a week-over-week comparison yet'**
  String get ohsDeltaUnavailable;

  /// Bento card label for the compliance dimension (FE-26).
  ///
  /// In en, this message translates to:
  /// **'Compliance'**
  String get ohsCompliance;

  /// Bento card label for the inventory-hygiene dimension (FE-26).
  ///
  /// In en, this message translates to:
  /// **'Inventory hygiene'**
  String get ohsInventoryHygiene;

  /// Bento card label for the audit-completion dimension (FE-26).
  ///
  /// In en, this message translates to:
  /// **'Audit completion'**
  String get ohsAuditCompletion;

  /// Section header above the list of recommended next actions (FE-26).
  ///
  /// In en, this message translates to:
  /// **'Action items'**
  String get ohsActionItemsHeader;

  /// Action-item label that routes to /expiry (FE-26).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 expiry alert needs a review} other{{count} expiry alerts need a review}}'**
  String ohsActionExpiry(int count);

  /// Action-item label that routes to /inventory/low-stock-alerts (FE-26).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 low-stock alert is unresolved} other{{count} low-stock alerts are unresolved}}'**
  String ohsActionLowStock(int count);

  /// Action-item label that routes to /tasks (FE-26).
  ///
  /// In en, this message translates to:
  /// **'Review open tasks for your store'**
  String get ohsActionTasks;

  /// Body shown in the action-items area when no callable counters are non-zero (FE-26).
  ///
  /// In en, this message translates to:
  /// **'Everything looks good — keep scanning to maintain your score.'**
  String get ohsActionNoneBody;

  /// Section header above the 7-bar weekly trend (FE-26).
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get ohsTrendHeader;

  /// Primary footer CTA on the OHS dashboard, routing to /reports (FE-26).
  ///
  /// In en, this message translates to:
  /// **'View detailed reports'**
  String get ohsViewDetailedReports;

  /// Empty-state title on the OHS dashboard (FE-26).
  ///
  /// In en, this message translates to:
  /// **'Build your operational health score'**
  String get ohsEmptyTitle;

  /// Empty-state body on the OHS dashboard (FE-26).
  ///
  /// In en, this message translates to:
  /// **'Start scanning to build your OHS score.'**
  String get ohsEmptyBody;

  /// Error-state title on the OHS dashboard (FE-26).
  ///
  /// In en, this message translates to:
  /// **'Could not load your dashboard'**
  String get ohsErrorTitle;

  /// Expiry list segmented tab — items approaching expiry.
  ///
  /// In en, this message translates to:
  /// **'Near-expiry'**
  String get expiryTabNear;

  /// Expiry list segmented tab / pill — items with comfortable shelf life.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get expiryTabSafe;

  /// Tooltip for the calendar-view action on the expiry list.
  ///
  /// In en, this message translates to:
  /// **'Calendar view'**
  String get expiryCalendarTooltip;

  /// Empty-state title on the Expired tab.
  ///
  /// In en, this message translates to:
  /// **'Nothing expired'**
  String get expiryEmptyExpiredTitle;

  /// Empty-state title on the Near-expiry tab.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get expiryEmptyNearTitle;

  /// Empty-state title on the Safe / default expiry tab.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get expiryEmptyDefaultTitle;

  /// Empty-state body shared by all expiry tabs.
  ///
  /// In en, this message translates to:
  /// **'No records in this category.'**
  String get expiryEmptyBody;

  /// Fallback product label using a short id token until product names join server-side.
  ///
  /// In en, this message translates to:
  /// **'Product {id}'**
  String expiryProductShort(String id);

  /// Batch-number chip in the expiry tile subtitle.
  ///
  /// In en, this message translates to:
  /// **'Batch {batch}'**
  String expiryBatch(String batch);

  /// Quantity chip in the expiry tile subtitle.
  ///
  /// In en, this message translates to:
  /// **'Qty {qty}'**
  String expiryQty(String qty);

  /// Expiry-date chip in the expiry tile subtitle.
  ///
  /// In en, this message translates to:
  /// **'Exp {date}'**
  String expiryExp(String date);

  /// Day-count pill when the item expires today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get expiryPillToday;

  /// Day-count pill when the item expires tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get expiryPillTomorrow;

  /// Compact day-count pill, e.g. 5d. The 'd' unit stays latin in all locales for the mono pill.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String expiryPillDays(int days);

  /// Day-count pill fallback when only a near-expiry status is known.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get expiryPillSoon;

  /// Error-state body on the expiry list.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load expiry records.'**
  String get expiryLoadError;

  /// Accessibility label for the error-state companion illustration. Reused across list screens.
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get expiryCouldNotLoadSemantic;

  /// Inventory list screen AppBar title.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTitle;

  /// Tooltip for the search action on the inventory list.
  ///
  /// In en, this message translates to:
  /// **'Search inventory'**
  String get inventorySearchTooltip;

  /// Placeholder text in the inventory search field.
  ///
  /// In en, this message translates to:
  /// **'Search by product or EAN...'**
  String get inventorySearchHint;

  /// Quick-action button → stock movement ledger.
  ///
  /// In en, this message translates to:
  /// **'Stock Movement'**
  String get inventoryStockMovement;

  /// Quick-action button → low-stock alerts.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alerts'**
  String get inventoryLowStockAlerts;

  /// Error-state body on the inventory list.
  ///
  /// In en, this message translates to:
  /// **'Failed to load inventory'**
  String get inventoryLoadError;

  /// Empty-state text when no inventory items exist.
  ///
  /// In en, this message translates to:
  /// **'No inventory items found'**
  String get inventoryEmpty;

  /// Empty-state text when a search yields no results.
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{query}\"'**
  String inventoryNoMatches(String query);

  /// Fallback product label until product names join server-side.
  ///
  /// In en, this message translates to:
  /// **'Product {id}'**
  String inventoryProductShort(String id);

  /// Status line when quantity is under the low-stock threshold.
  ///
  /// In en, this message translates to:
  /// **'Below threshold'**
  String get inventoryBelowThreshold;

  /// Status line when quantity is at or above the threshold.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inventoryInStock;

  /// Small unit label beneath the quantity number on an inventory tile.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get inventoryUnitsLabel;

  /// Expanded-detail label for total quantity on hand.
  ///
  /// In en, this message translates to:
  /// **'Total quantity'**
  String get inventoryTotalQuantity;

  /// Expanded-detail label for the configured low-stock threshold.
  ///
  /// In en, this message translates to:
  /// **'Low-stock threshold'**
  String get inventoryLowStockThreshold;

  /// Quantity-with-unit value, e.g. 12 units.
  ///
  /// In en, this message translates to:
  /// **'{count} units'**
  String inventoryQtyUnits(int count);

  /// Hint in the expanded inventory detail pointing to the stock-movement ledger.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Stock movement\" to view the full batch ledger.'**
  String get inventoryBatchLedgerHint;

  /// Pill badge shown on tiles below their low-stock threshold.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get inventoryLowStockBadge;

  /// Tasks list screen AppBar title.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// Tasks filter tab — tasks assigned to the current user.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get tasksTabMine;

  /// Tasks filter tab — all tasks regardless of assignee.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tasksTabAll;

  /// Manager-only FAB label to create a task.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get tasksNewTask;

  /// Empty-state title on a tasks tab.
  ///
  /// In en, this message translates to:
  /// **'No tasks here'**
  String get tasksEmptyTitle;

  /// Empty-state body on a tasks tab.
  ///
  /// In en, this message translates to:
  /// **'Tasks assigned to this view will show up here.'**
  String get tasksEmptyBody;

  /// Error-state body on the tasks list.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tasks'**
  String get tasksLoadError;

  /// Meta chip indicating a task requires photo evidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get taskEvidence;

  /// Shared severity label — high priority.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// Shared severity label — medium priority.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// Shared severity label — low priority.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// Shared severity label — urgent priority.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// Task status label — open / default.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get taskStatusOpen;

  /// Task status label — pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get taskStatusPending;

  /// Task status label — in progress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get taskStatusInProgress;

  /// Task status label / Completed filter tab.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskStatusCompleted;

  /// Task status label — cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get taskStatusCancelled;

  /// Camera scanner top-bar title.
  ///
  /// In en, this message translates to:
  /// **'Scan a product'**
  String get scanTitle;

  /// Default guidance pill under the scan frame.
  ///
  /// In en, this message translates to:
  /// **'Align the barcode within the frame'**
  String get scanAlignHint;

  /// Guidance pill shown while batch (continuous) scan mode is on.
  ///
  /// In en, this message translates to:
  /// **'Batch mode — keep scanning, items add automatically'**
  String get scanBatchHint;

  /// Snackbar after a batch-mode scan adds an item.
  ///
  /// In en, this message translates to:
  /// **'Added {code} · {count} scanned'**
  String scanBatchAdded(String code, int count);

  /// Finish-batch pill button with running scanned count.
  ///
  /// In en, this message translates to:
  /// **'Done · {count}'**
  String scanBatchDone(int count);

  /// Action to OCR-scan the product label instead of the barcode.
  ///
  /// In en, this message translates to:
  /// **'Scan label'**
  String get scanLabelAction;

  /// Action to pick a barcode image from the gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get scanGalleryAction;

  /// Action to type a barcode by hand.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get scanEnterManually;

  /// Action to open the bulk EAN audit flow.
  ///
  /// In en, this message translates to:
  /// **'Bulk audit'**
  String get scanBulkAudit;

  /// Action to open this session's scan history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get scanHistoryAction;

  /// Torch toggle label in the trouble-scanning card.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get scanFlash;

  /// Title of the low-light / damaged-barcode rescue card.
  ///
  /// In en, this message translates to:
  /// **'Trouble scanning?'**
  String get scanTroubleTitle;

  /// Body of the trouble-scanning rescue card.
  ///
  /// In en, this message translates to:
  /// **'Low light or a damaged barcode? Turn on the flash, or read the label instead.'**
  String get scanTroubleBody;

  /// Snackbar when a gallery image has no readable barcode.
  ///
  /// In en, this message translates to:
  /// **'No barcode found. Tip: use \'Scan label\' to read the ingredients.'**
  String get scanGalleryNoBarcode;

  /// Validation message for an invalid barcode entry.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid EAN-8, EAN-13, or UPC-A code'**
  String get scanInvalidEan;

  /// AppBar title on the web manual-entry fallback.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanWebTitle;

  /// Explanation on the web fallback where camera scanning is unsupported.
  ///
  /// In en, this message translates to:
  /// **'Camera scanning is not available on web.\nEnter a barcode manually:'**
  String get scanWebUnavailable;

  /// Label for the barcode text field on the web fallback.
  ///
  /// In en, this message translates to:
  /// **'EAN / UPC Code'**
  String get scanEanFieldLabel;

  /// Example barcode placeholder in entry fields.
  ///
  /// In en, this message translates to:
  /// **'e.g. 5901234123457'**
  String get scanEanHintExample;

  /// Button to look up a manually entered barcode.
  ///
  /// In en, this message translates to:
  /// **'Look up'**
  String get scanLookUp;

  /// Title of the manual barcode entry bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Enter barcode'**
  String get scanEnterBarcode;

  /// Title of the scan history bottom sheet / button.
  ///
  /// In en, this message translates to:
  /// **'Scan history'**
  String get scanHistoryTitle;

  /// Empty state inside the scan history sheet.
  ///
  /// In en, this message translates to:
  /// **'No scans yet this session.'**
  String get scanNoHistory;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// Greeting name placeholder when the user has no resolvable name.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get homeGreetingFallbackName;

  /// No description provided for @homeTrialEnded.
  ///
  /// In en, this message translates to:
  /// **'Free trial ended — upgrade to keep access'**
  String get homeTrialEnded;

  /// Business-mode trial ribbon with remaining days.
  ///
  /// In en, this message translates to:
  /// **'Free trial · {days, plural, =1{1 day} other{{days} days}} left'**
  String homeTrialDaysLeft(int days);

  /// No description provided for @homeUpgradeArrow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade →'**
  String get homeUpgradeArrow;

  /// No description provided for @homeKpiSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get homeKpiSaved;

  /// No description provided for @homeKpiNearExpiry.
  ///
  /// In en, this message translates to:
  /// **'Near expiry'**
  String get homeKpiNearExpiry;

  /// No description provided for @homeKpiRecallAlerts.
  ///
  /// In en, this message translates to:
  /// **'Recall alerts'**
  String get homeKpiRecallAlerts;

  /// No description provided for @homeKpiOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'Open tasks'**
  String get homeKpiOpenTasks;

  /// No description provided for @homeKpiLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get homeKpiLowStock;

  /// No description provided for @homeEyebrowFoodSafety.
  ///
  /// In en, this message translates to:
  /// **'FOOD SAFETY ALERT'**
  String get homeEyebrowFoodSafety;

  /// Story-banner eyebrow — brand Hinglish for 'today's work'. Keep the brand voice in English; translate naturally elsewhere.
  ///
  /// In en, this message translates to:
  /// **'AAJ KA KAAM · TODAY'**
  String get homeEyebrowToday;

  /// No description provided for @homeEyebrowHealthScan.
  ///
  /// In en, this message translates to:
  /// **'YOUR HEALTH SCAN'**
  String get homeEyebrowHealthScan;

  /// No description provided for @homeEyebrowScanToLearn.
  ///
  /// In en, this message translates to:
  /// **'SCAN TO LEARN'**
  String get homeEyebrowScanToLearn;

  /// No description provided for @homeEyebrowAllClear.
  ///
  /// In en, this message translates to:
  /// **'ALL CLEAR'**
  String get homeEyebrowAllClear;

  /// Consumer story headline when recall alerts exist.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recalled product — check what you have at home} other{{count} recalled products — check what you have at home}}'**
  String homeStoryRecall(int count);

  /// Consumer story headline for near-expiry saved items.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 saved item expires this week — use it up} other{{count} saved items expire this week — use them up}}'**
  String homeStoryNearExpiryConsumer(int count);

  /// No description provided for @homeStoryKnowWhatYouEat.
  ///
  /// In en, this message translates to:
  /// **'Know what you eat'**
  String get homeStoryKnowWhatYouEat;

  /// No description provided for @homeStoryScanInside.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at any food barcode — see what\'s inside'**
  String get homeStoryScanInside;

  /// Business story headline for items near expiry.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item near expiry — clear the shelf} other{{count} items near expiry — clear the shelf}}'**
  String homeStoryNearExpiryBusiness(int count);

  /// Business story headline for open tasks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task needs you today} other{{count} tasks need you today}}'**
  String homeStoryOpenTasks(int count);

  /// Business story headline for low-stock items.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item running low on stock} other{{count} items running low on stock}}'**
  String homeStoryLowStock(int count);

  /// No description provided for @homeStoreToday.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your store today'**
  String get homeStoreToday;

  /// All-clear business headline. 'Shabaash' = well done (brand voice).
  ///
  /// In en, this message translates to:
  /// **'Shabaash! Your store\'s in great shape today'**
  String get homeStoreAllGood;

  /// No description provided for @homeCtaViewRecallAlerts.
  ///
  /// In en, this message translates to:
  /// **'View recall alerts'**
  String get homeCtaViewRecallAlerts;

  /// No description provided for @homeCtaCheckExpiry.
  ///
  /// In en, this message translates to:
  /// **'Check expiry'**
  String get homeCtaCheckExpiry;

  /// No description provided for @homeCtaOpenExpiry.
  ///
  /// In en, this message translates to:
  /// **'Open expiry'**
  String get homeCtaOpenExpiry;

  /// No description provided for @homeCtaViewTasks.
  ///
  /// In en, this message translates to:
  /// **'View tasks'**
  String get homeCtaViewTasks;

  /// No description provided for @homeCtaCheckInventory.
  ///
  /// In en, this message translates to:
  /// **'Check inventory'**
  String get homeCtaCheckInventory;

  /// No description provided for @homeCtaOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'Open tasks'**
  String get homeCtaOpenTasks;

  /// No description provided for @homeCtaRunAudit.
  ///
  /// In en, this message translates to:
  /// **'Run a quick audit'**
  String get homeCtaRunAudit;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickActions;

  /// No description provided for @homeQuickScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get homeQuickScan;

  /// No description provided for @homeQuickShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get homeQuickShopping;

  /// No description provided for @homeQuickAddExpiry.
  ///
  /// In en, this message translates to:
  /// **'Add Expiry'**
  String get homeQuickAddExpiry;

  /// No description provided for @homeQuickNewTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get homeQuickNewTask;

  /// No description provided for @homeRecentTasks.
  ///
  /// In en, this message translates to:
  /// **'Recent tasks'**
  String get homeRecentTasks;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeNoOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'No open tasks — create one'**
  String get homeNoOpenTasks;

  /// Recent-task meta line — assignee.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}'**
  String homeTaskAssignedTo(String name);

  /// No description provided for @homeTaskOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get homeTaskOverdue;

  /// No description provided for @homeTaskDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get homeTaskDueToday;

  /// No description provided for @homeTaskDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get homeTaskDueTomorrow;

  /// Recent-task meta line — due in N days (N is always 2+).
  ///
  /// In en, this message translates to:
  /// **'Due in {days} days'**
  String homeTaskDueInDays(int days);

  /// Recent-task meta line — fallback raw due date.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String homeTaskDueOn(String date);

  /// No description provided for @homeHowHelps.
  ///
  /// In en, this message translates to:
  /// **'How RADHA helps you'**
  String get homeHowHelps;

  /// No description provided for @homeScanBarcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan any food barcode'**
  String get homeScanBarcodeTitle;

  /// No description provided for @homeScanBarcodeBody.
  ///
  /// In en, this message translates to:
  /// **'See the health rating, ingredients, and what to watch out for.'**
  String get homeScanBarcodeBody;

  /// No description provided for @homeRecallTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety recall alerts'**
  String get homeRecallTitle;

  /// No description provided for @homeRecallBody.
  ///
  /// In en, this message translates to:
  /// **'Stay informed about recalled food products.'**
  String get homeRecallBody;

  /// No description provided for @homePromoKnowFoodEyebrow.
  ///
  /// In en, this message translates to:
  /// **'KNOW YOUR FOOD'**
  String get homePromoKnowFoodEyebrow;

  /// No description provided for @homePromoKnowFoodHeadline.
  ///
  /// In en, this message translates to:
  /// **'Scan the label — see what\'s really inside'**
  String get homePromoKnowFoodHeadline;

  /// No description provided for @homePromoKnowFoodCta.
  ///
  /// In en, this message translates to:
  /// **'Scan & learn'**
  String get homePromoKnowFoodCta;

  /// No description provided for @homePromoExpiryEyebrow.
  ///
  /// In en, this message translates to:
  /// **'NEVER MISS A DATE'**
  String get homePromoExpiryEyebrow;

  /// No description provided for @homePromoExpiryHeadline.
  ///
  /// In en, this message translates to:
  /// **'Catch every expiry before it slips away'**
  String get homePromoExpiryHeadline;

  /// No description provided for @homePromoExpiryCta.
  ///
  /// In en, this message translates to:
  /// **'Track expiry'**
  String get homePromoExpiryCta;

  /// No description provided for @homePromoFestiveEyebrow.
  ///
  /// In en, this message translates to:
  /// **'FESTIVE PICKS'**
  String get homePromoFestiveEyebrow;

  /// No description provided for @homePromoFestiveHeadline.
  ///
  /// In en, this message translates to:
  /// **'Shop the season, the healthy way'**
  String get homePromoFestiveHeadline;

  /// No description provided for @homePromoFestiveCta.
  ///
  /// In en, this message translates to:
  /// **'Browse products'**
  String get homePromoFestiveCta;

  /// Business promo eyebrow — brand Hinglish for 'today's market'.
  ///
  /// In en, this message translates to:
  /// **'AAJ KA BAZAAR'**
  String get homePromoBazaarEyebrow;

  /// No description provided for @homePromoBazaarHeadline.
  ///
  /// In en, this message translates to:
  /// **'Audit your shelves in minutes'**
  String get homePromoBazaarHeadline;

  /// No description provided for @homePromoBazaarCta.
  ///
  /// In en, this message translates to:
  /// **'Start an audit'**
  String get homePromoBazaarCta;

  /// No description provided for @homeShopByCategory.
  ///
  /// In en, this message translates to:
  /// **'Shop by category'**
  String get homeShopByCategory;

  /// No description provided for @homeShopByCategorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap an aisle to scan or browse its products'**
  String get homeShopByCategorySubtitle;

  /// Welcome-page value proposition (onboarding page 1).
  ///
  /// In en, this message translates to:
  /// **'Scan, track, audit your stock without the spreadsheets.'**
  String get onboardingWelcomeValue;

  /// Capabilities-page headline (onboarding page 2). Keeps the line break.
  ///
  /// In en, this message translates to:
  /// **'Built for the floor,\nnot the back office.'**
  String get onboardingCapabilitiesTitle;

  /// No description provided for @onboardingCapScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan products in one tap'**
  String get onboardingCapScanTitle;

  /// No description provided for @onboardingCapScanBody.
  ///
  /// In en, this message translates to:
  /// **'EAN lookup with health and approval pre-checked.'**
  String get onboardingCapScanBody;

  /// No description provided for @onboardingCapExpiryTitle.
  ///
  /// In en, this message translates to:
  /// **'Catch expiry before it costs you'**
  String get onboardingCapExpiryTitle;

  /// No description provided for @onboardingCapExpiryBody.
  ///
  /// In en, this message translates to:
  /// **'OCR-assisted dates and per-category thresholds.'**
  String get onboardingCapExpiryBody;

  /// No description provided for @onboardingCapAuditTitle.
  ///
  /// In en, this message translates to:
  /// **'Run audits the team can finish'**
  String get onboardingCapAuditTitle;

  /// No description provided for @onboardingCapAuditBody.
  ///
  /// In en, this message translates to:
  /// **'Tasks, evidence and bulk scan sessions.'**
  String get onboardingCapAuditBody;

  /// Segment-selector page headline (onboarding page 3).
  ///
  /// In en, this message translates to:
  /// **'Who are you here as?'**
  String get onboardingSegmentTitle;

  /// No description provided for @onboardingSegmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the closest fit. You can change later in Settings.'**
  String get onboardingSegmentSubtitle;

  /// No description provided for @segmentPersonalTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get segmentPersonalTitle;

  /// No description provided for @segmentPersonalBody.
  ///
  /// In en, this message translates to:
  /// **'Just shopping for myself'**
  String get segmentPersonalBody;

  /// No description provided for @segmentParentTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get segmentParentTitle;

  /// No description provided for @segmentParentBody.
  ///
  /// In en, this message translates to:
  /// **'Shopping for my family / kids'**
  String get segmentParentBody;

  /// No description provided for @segmentBusinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Business owner'**
  String get segmentBusinessTitle;

  /// No description provided for @segmentBusinessBody.
  ///
  /// In en, this message translates to:
  /// **'I run a small retail store'**
  String get segmentBusinessBody;

  /// No description provided for @segmentPharmacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get segmentPharmacyTitle;

  /// No description provided for @segmentPharmacyBody.
  ///
  /// In en, this message translates to:
  /// **'I run a pharmacy / chemist'**
  String get segmentPharmacyBody;

  /// No description provided for @segmentInstitutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get segmentInstitutionTitle;

  /// No description provided for @segmentInstitutionBody.
  ///
  /// In en, this message translates to:
  /// **'School / hostel / canteen'**
  String get segmentInstitutionBody;

  /// No description provided for @segmentAuditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Auditor (invited)'**
  String get segmentAuditorTitle;

  /// No description provided for @segmentAuditorBody.
  ///
  /// In en, this message translates to:
  /// **'I have an invite code'**
  String get segmentAuditorBody;

  /// Allergen profile screen AppBar title.
  ///
  /// In en, this message translates to:
  /// **'Allergens'**
  String get allergenTitle;

  /// No description provided for @allergenLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your allergen profile.'**
  String get allergenLoadError;

  /// No description provided for @allergenHeading.
  ///
  /// In en, this message translates to:
  /// **'Your allergens'**
  String get allergenHeading;

  /// No description provided for @allergenIntro.
  ///
  /// In en, this message translates to:
  /// **'Tap any allergens you react to. We will warn you when a scanned product contains them.'**
  String get allergenIntro;

  /// Selection summary count of tracked allergens.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 allergen tracked} other{{count} allergens tracked}}'**
  String allergenTracked(int count);

  /// No description provided for @allergenNoneTracked.
  ///
  /// In en, this message translates to:
  /// **'No allergens tracked yet'**
  String get allergenNoneTracked;

  /// No description provided for @allergenSavedCleared.
  ///
  /// In en, this message translates to:
  /// **'Allergen profile cleared.'**
  String get allergenSavedCleared;

  /// No description provided for @allergenSaved.
  ///
  /// In en, this message translates to:
  /// **'Allergen profile saved.'**
  String get allergenSaved;

  /// No description provided for @allergenSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your allergens.'**
  String get allergenSaveError;

  /// No description provided for @allergenPeanut.
  ///
  /// In en, this message translates to:
  /// **'Peanut'**
  String get allergenPeanut;

  /// No description provided for @allergenTreeNut.
  ///
  /// In en, this message translates to:
  /// **'Tree nut'**
  String get allergenTreeNut;

  /// No description provided for @allergenDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get allergenDairy;

  /// No description provided for @allergenEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get allergenEggs;

  /// No description provided for @allergenSoy.
  ///
  /// In en, this message translates to:
  /// **'Soy'**
  String get allergenSoy;

  /// No description provided for @allergenWheat.
  ///
  /// In en, this message translates to:
  /// **'Wheat'**
  String get allergenWheat;

  /// No description provided for @allergenFish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get allergenFish;

  /// No description provided for @allergenShellfish.
  ///
  /// In en, this message translates to:
  /// **'Shellfish'**
  String get allergenShellfish;

  /// No description provided for @allergenSesame.
  ///
  /// In en, this message translates to:
  /// **'Sesame'**
  String get allergenSesame;

  /// No description provided for @allergenGluten.
  ///
  /// In en, this message translates to:
  /// **'Gluten'**
  String get allergenGluten;

  /// No description provided for @allergenMustard.
  ///
  /// In en, this message translates to:
  /// **'Mustard'**
  String get allergenMustard;

  /// No description provided for @allergenCelery.
  ///
  /// In en, this message translates to:
  /// **'Celery'**
  String get allergenCelery;

  /// No description provided for @allergenLupin.
  ///
  /// In en, this message translates to:
  /// **'Lupin'**
  String get allergenLupin;

  /// No description provided for @allergenMolluscs.
  ///
  /// In en, this message translates to:
  /// **'Molluscs'**
  String get allergenMolluscs;

  /// No description provided for @allergenSulphites.
  ///
  /// In en, this message translates to:
  /// **'Sulphites'**
  String get allergenSulphites;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'hi',
    'mr',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
