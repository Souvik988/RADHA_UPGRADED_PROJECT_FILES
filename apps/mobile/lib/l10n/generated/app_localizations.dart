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

  /// Subscription screen app-bar title.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subTitle;

  /// Paywall hero headline. RADHA is the brand mark, do not translate.
  ///
  /// In en, this message translates to:
  /// **'Unlock RADHA’s full picture'**
  String get subUnlockHeadline;

  /// No description provided for @subLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your subscription'**
  String get subLoadError;

  /// No description provided for @subErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get subErrorBody;

  /// No description provided for @subChoosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get subChoosePlan;

  /// No description provided for @subPlansLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load plans'**
  String get subPlansLoadError;

  /// No description provided for @subPlansUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Plans are unavailable right now. Please try again later.'**
  String get subPlansUnavailable;

  /// Razorpay is the payment provider brand, do not translate.
  ///
  /// In en, this message translates to:
  /// **'Secure payment via Razorpay'**
  String get subSecurePayment;

  /// No description provided for @subCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get subCurrentPlan;

  /// Days until the paid plan renews.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Renews in 1 day} other{Renews in {days} days}}'**
  String subRenewsInDays(int days);

  /// No description provided for @subBillingMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subBillingMonthly;

  /// No description provided for @subBillingYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get subBillingYearly;

  /// No description provided for @subBilledYearly.
  ///
  /// In en, this message translates to:
  /// **'billed yearly'**
  String get subBilledYearly;

  /// No description provided for @subPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get subPerMonth;

  /// No description provided for @subPerYear.
  ///
  /// In en, this message translates to:
  /// **'/yr'**
  String get subPerYear;

  /// No description provided for @subPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get subPopular;

  /// No description provided for @subStatusTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get subStatusTrial;

  /// Trial days-remaining chip.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day left} other{{days} days left}}'**
  String subStatusDaysLeft(int days);

  /// No description provided for @subStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subStatusActive;

  /// No description provided for @subStatusPastDue.
  ///
  /// In en, this message translates to:
  /// **'Past due'**
  String get subStatusPastDue;

  /// No description provided for @subStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get subStatusPaused;

  /// No description provided for @subStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get subStatusCancelled;

  /// Upgrade CTA for the recommended plan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to {plan}'**
  String subUpgradeTo(String plan);

  /// Choose CTA for a non-recommended plan.
  ///
  /// In en, this message translates to:
  /// **'Choose {plan}'**
  String subChoosePlanNamed(String plan);

  /// Current-plan pill label.
  ///
  /// In en, this message translates to:
  /// **'You\'re on {plan}'**
  String subYoureOnPlan(String plan);

  /// Snackbar after a verified upgrade. RADHA is the brand mark.
  ///
  /// In en, this message translates to:
  /// **'You\'re on {plan}. Welcome to RADHA {plan}!'**
  String subWelcome(String plan);

  /// No description provided for @subCheckoutCancelled.
  ///
  /// In en, this message translates to:
  /// **'Checkout cancelled — your plan is unchanged.'**
  String get subCheckoutCancelled;

  /// Payment pending confirmation. supportRef is a short reference id.
  ///
  /// In en, this message translates to:
  /// **'Payment received — confirming it now. Ref {supportRef}. Pull down to refresh in a moment.'**
  String subPaymentPending(String supportRef);

  /// No description provided for @subPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Please try again.'**
  String get subPaymentFailed;

  /// No description provided for @catalogSearchBarHint.
  ///
  /// In en, this message translates to:
  /// **'Search products to find what fits you'**
  String get catalogSearchBarHint;

  /// No description provided for @catalogSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products or brands'**
  String get catalogSearchHint;

  /// No description provided for @catalogSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get catalogSearchClear;

  /// No description provided for @catalogNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get catalogNoMatchesTitle;

  /// Catalog search empty state. query is the user's search text.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find products for “{query}”. Try a different name, or scan the item instead.'**
  String catalogNoMatchesBody(String query);

  /// No description provided for @catalogScanProduct.
  ///
  /// In en, this message translates to:
  /// **'Scan a product'**
  String get catalogScanProduct;

  /// No description provided for @catalogFindTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a product'**
  String get catalogFindTitle;

  /// No description provided for @catalogFindBody.
  ///
  /// In en, this message translates to:
  /// **'Search by product name or brand to see its health rating and what\'s inside.'**
  String get catalogFindBody;

  /// No description provided for @catalogProductsFallback.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get catalogProductsFallback;

  /// No description provided for @catalogLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load products'**
  String get catalogLoadErrorTitle;

  /// Browse load error. category is the (lowercased) category name.
  ///
  /// In en, this message translates to:
  /// **'We hit a snag loading {category}. Please try again.'**
  String catalogLoadErrorBody(String category);

  /// No description provided for @catalogSourceOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing your saved catalog'**
  String get catalogSourceOffline;

  /// No description provided for @catalogSourceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live catalog unavailable — showing saved catalog'**
  String get catalogSourceUnavailable;

  /// No description provided for @catalogRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get catalogRetry;

  /// No description provided for @catalogSortHealthiest.
  ///
  /// In en, this message translates to:
  /// **'Healthiest'**
  String get catalogSortHealthiest;

  /// No description provided for @catalogSortAZ.
  ///
  /// In en, this message translates to:
  /// **'A–Z'**
  String get catalogSortAZ;

  /// No description provided for @catalogVegOnly.
  ///
  /// In en, this message translates to:
  /// **'Veg only'**
  String get catalogVegOnly;

  /// No description provided for @catalogVeg.
  ///
  /// In en, this message translates to:
  /// **'Veg'**
  String get catalogVeg;

  /// No description provided for @catalogNoVegTitle.
  ///
  /// In en, this message translates to:
  /// **'No veg items here yet'**
  String get catalogNoVegTitle;

  /// Empty state when the veg filter excludes everything. category is the (lowercased) category name.
  ///
  /// In en, this message translates to:
  /// **'Nothing in {category} matches the veg filter right now.'**
  String catalogNoVegBody(String category);

  /// No description provided for @catalogShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get catalogShowAll;

  /// No description provided for @catalogNoProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get catalogNoProductsTitle;

  /// Empty category state. category is the (lowercased) category name.
  ///
  /// In en, this message translates to:
  /// **'We\'re stocking the {category} aisle. Meanwhile, scan any item to check its health and expiry.'**
  String catalogNoProductsBody(String category);

  /// No description provided for @catalogFeaturedTitle.
  ///
  /// In en, this message translates to:
  /// **'Featured products'**
  String get catalogFeaturedTitle;

  /// No description provided for @catalogHealthyPicksTitle.
  ///
  /// In en, this message translates to:
  /// **'Healthy picks'**
  String get catalogHealthyPicksTitle;

  /// No description provided for @catalogDetailProductFallback.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get catalogDetailProductFallback;

  /// No description provided for @catalogDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get catalogDetailTitle;

  /// No description provided for @catalogDetailShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get catalogDetailShareTooltip;

  /// No description provided for @catalogDetailSeeHealthierOptions.
  ///
  /// In en, this message translates to:
  /// **'See healthier options'**
  String get catalogDetailSeeHealthierOptions;

  /// No description provided for @catalogDetailSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Saved — we\'ll alert you if it\'s ever recalled.'**
  String get catalogDetailSavedSnackbar;

  /// No description provided for @catalogDetailSaveFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again.'**
  String get catalogDetailSaveFailedSnackbar;

  /// Optional suffix in native share text with the product health rating.
  ///
  /// In en, this message translates to:
  /// **' — RADHA health rating {rating}/5 ({label})'**
  String catalogDetailShareRating(String rating, String label);

  /// Native share text for a catalog product.
  ///
  /// In en, this message translates to:
  /// **'Checked \"{productName}\" on RADHA{ratingSummary}.'**
  String catalogDetailShareText(String productName, String ratingSummary);

  /// No description provided for @catalogDetailSavedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get catalogDetailSavedTooltip;

  /// No description provided for @catalogDetailHealthPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Health rating not in yet'**
  String get catalogDetailHealthPendingTitle;

  /// No description provided for @catalogDetailHealthPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Scan this product to pull its full health analysis into RADHA.'**
  String get catalogDetailHealthPendingBody;

  /// No description provided for @catalogDetailHealthRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'RADHA Health Rating'**
  String get catalogDetailHealthRatingLabel;

  /// No description provided for @catalogDetailHealthExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get catalogDetailHealthExcellent;

  /// No description provided for @catalogDetailHealthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get catalogDetailHealthGood;

  /// No description provided for @catalogDetailHealthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get catalogDetailHealthFair;

  /// No description provided for @catalogDetailHealthPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get catalogDetailHealthPoor;

  /// No description provided for @catalogDetailHealthAvoid.
  ///
  /// In en, this message translates to:
  /// **'Avoid'**
  String get catalogDetailHealthAvoid;

  /// No description provided for @catalogDetailInsightHighProtein.
  ///
  /// In en, this message translates to:
  /// **'High protein'**
  String get catalogDetailInsightHighProtein;

  /// No description provided for @catalogDetailInsightGoodFibre.
  ///
  /// In en, this message translates to:
  /// **'Good fibre'**
  String get catalogDetailInsightGoodFibre;

  /// No description provided for @catalogDetailInsightMinimallyProcessed.
  ///
  /// In en, this message translates to:
  /// **'Minimally processed'**
  String get catalogDetailInsightMinimallyProcessed;

  /// No description provided for @catalogDetailConcernHighSugar.
  ///
  /// In en, this message translates to:
  /// **'High sugar'**
  String get catalogDetailConcernHighSugar;

  /// No description provided for @catalogDetailConcernHighSaturatedFat.
  ///
  /// In en, this message translates to:
  /// **'High saturated fat'**
  String get catalogDetailConcernHighSaturatedFat;

  /// No description provided for @catalogDetailConcernHighSodium.
  ///
  /// In en, this message translates to:
  /// **'High sodium'**
  String get catalogDetailConcernHighSodium;

  /// No description provided for @catalogDetailConcernUltraProcessed.
  ///
  /// In en, this message translates to:
  /// **'Ultra-processed'**
  String get catalogDetailConcernUltraProcessed;

  /// No description provided for @catalogDetailConcernContainsTransFat.
  ///
  /// In en, this message translates to:
  /// **'Contains trans fat'**
  String get catalogDetailConcernContainsTransFat;

  /// No description provided for @catalogDetailConcernContainsAllergens.
  ///
  /// In en, this message translates to:
  /// **'Contains allergens'**
  String get catalogDetailConcernContainsAllergens;

  /// No description provided for @catalogDetailLikeHeading.
  ///
  /// In en, this message translates to:
  /// **'What you\'ll like'**
  String get catalogDetailLikeHeading;

  /// No description provided for @catalogDetailConcernHeading.
  ///
  /// In en, this message translates to:
  /// **'What should concern you'**
  String get catalogDetailConcernHeading;

  /// No description provided for @catalogDetailNutritionSourceNote.
  ///
  /// In en, this message translates to:
  /// **'Based on the product\'s real nutrition (per 100 g).'**
  String get catalogDetailNutritionSourceNote;

  /// No description provided for @catalogDetailKeyNutrients.
  ///
  /// In en, this message translates to:
  /// **'Key nutrients'**
  String get catalogDetailKeyNutrients;

  /// No description provided for @catalogDetailNutrientProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get catalogDetailNutrientProtein;

  /// No description provided for @catalogDetailNutrientTotalSugars.
  ///
  /// In en, this message translates to:
  /// **'Total Sugars'**
  String get catalogDetailNutrientTotalSugars;

  /// No description provided for @catalogDetailNutrientEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get catalogDetailNutrientEnergy;

  /// No description provided for @catalogDetailAllNutrients.
  ///
  /// In en, this message translates to:
  /// **'All nutrients'**
  String get catalogDetailAllNutrients;

  /// No description provided for @catalogDetailNutrientTotalFat.
  ///
  /// In en, this message translates to:
  /// **'Total Fat'**
  String get catalogDetailNutrientTotalFat;

  /// No description provided for @catalogDetailNutrientSaturatedFat.
  ///
  /// In en, this message translates to:
  /// **'Saturated Fat'**
  String get catalogDetailNutrientSaturatedFat;

  /// No description provided for @catalogDetailNutrientCarbohydrates.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates'**
  String get catalogDetailNutrientCarbohydrates;

  /// No description provided for @catalogDetailNutrientFibre.
  ///
  /// In en, this message translates to:
  /// **'Fibre'**
  String get catalogDetailNutrientFibre;

  /// No description provided for @catalogDetailNutrientSodium.
  ///
  /// In en, this message translates to:
  /// **'Sodium'**
  String get catalogDetailNutrientSodium;

  /// No description provided for @catalogDetailPer100g.
  ///
  /// In en, this message translates to:
  /// **'Per 100 g'**
  String get catalogDetailPer100g;

  /// No description provided for @catalogDetailPer50g.
  ///
  /// In en, this message translates to:
  /// **'Per 50 g'**
  String get catalogDetailPer50g;

  /// No description provided for @catalogDetailRdaNote.
  ///
  /// In en, this message translates to:
  /// **'% of reference daily intake (adult).'**
  String get catalogDetailRdaNote;

  /// No description provided for @catalogDetailRadhaPlus.
  ///
  /// In en, this message translates to:
  /// **'RADHA Plus'**
  String get catalogDetailRadhaPlus;

  /// No description provided for @catalogDetailForYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get catalogDetailForYou;

  /// No description provided for @catalogDetailIngredientDeepDiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredient deep-dive'**
  String get catalogDetailIngredientDeepDiveTitle;

  /// No description provided for @catalogDetailIngredientDeepDiveLockedBody.
  ///
  /// In en, this message translates to:
  /// **'See every ingredient explained with a safety verdict — what it is, why it\'s there, and whether to worry.'**
  String get catalogDetailIngredientDeepDiveLockedBody;

  /// No description provided for @catalogDetailIngredientExplainError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t explain these ingredients right now.'**
  String get catalogDetailIngredientExplainError;

  /// No description provided for @catalogDetailIngredientNeedsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ingredient detail needs a clear label photo. Scan the pack label and RADHA will explain the real ingredient list.'**
  String get catalogDetailIngredientNeedsLabel;

  /// No description provided for @catalogDetailPersonalisedFlagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Personalised flags'**
  String get catalogDetailPersonalisedFlagsTitle;

  /// No description provided for @catalogDetailPersonalisedFlagsLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Match this product against your saved allergens & health goals — we\'ll flag what\'s right (or wrong) for you.'**
  String get catalogDetailPersonalisedFlagsLockedBody;

  /// No description provided for @catalogDetailPersonaliseError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t personalise this right now.'**
  String get catalogDetailPersonaliseError;

  /// No description provided for @catalogDetailNoAllergensDetected.
  ///
  /// In en, this message translates to:
  /// **'No allergens detected in this product.'**
  String get catalogDetailNoAllergensDetected;

  /// No description provided for @catalogDetailAllergenSignalDetected.
  ///
  /// In en, this message translates to:
  /// **'This product reports possible allergens. Check the label before buying.'**
  String get catalogDetailAllergenSignalDetected;

  /// No description provided for @catalogDetailAllergenSignalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Allergen details are not in the product record yet. Scan the label to personalise this safely.'**
  String get catalogDetailAllergenSignalUnavailable;

  /// Allergen chip when the product contains something in the user's profile.
  ///
  /// In en, this message translates to:
  /// **'{allergen} — you avoid this'**
  String catalogDetailAllergenAvoided(String allergen);

  /// Upsell CTA label for a gated catalog detail feature.
  ///
  /// In en, this message translates to:
  /// **'Unlock with {plan}'**
  String catalogDetailUnlockWithPlan(String plan);

  /// No description provided for @catalogDetailWouldBuyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Would you buy this product?'**
  String get catalogDetailWouldBuyQuestion;

  /// No description provided for @catalogDetailWouldBuyThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for sharing!'**
  String get catalogDetailWouldBuyThanks;

  /// No description provided for @catalogDetailWouldBuyYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get catalogDetailWouldBuyYes;

  /// No description provided for @catalogDetailWouldBuyNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get catalogDetailWouldBuyNo;

  /// No description provided for @catalogDetailWouldBuyAlreadyBought.
  ///
  /// In en, this message translates to:
  /// **'Already bought'**
  String get catalogDetailWouldBuyAlreadyBought;

  /// No description provided for @catalogDetailNutritionNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'We don\'t have this record yet'**
  String get catalogDetailNutritionNotFoundTitle;

  /// No description provided for @catalogDetailNutritionNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'RADHA doesn\'t have this product\'s full nutrition yet. Scan its barcode or label to pull in the real data.'**
  String get catalogDetailNutritionNotFoundBody;

  /// No description provided for @catalogDetailNutritionOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get catalogDetailNutritionOfflineTitle;

  /// No description provided for @catalogDetailNutritionOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load nutrition. Your product details above are still here — reconnect and retry.'**
  String get catalogDetailNutritionOfflineBody;

  /// No description provided for @catalogDetailNutritionSessionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get catalogDetailNutritionSessionExpiredTitle;

  /// No description provided for @catalogDetailNutritionSessionExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Please retry — RADHA will refresh your session and try again.'**
  String get catalogDetailNutritionSessionExpiredBody;

  /// No description provided for @catalogDetailNutritionAccessDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access restricted'**
  String get catalogDetailNutritionAccessDeniedTitle;

  /// No description provided for @catalogDetailNutritionAccessDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Your account cannot read this nutrition record. The product information above is still available.'**
  String get catalogDetailNutritionAccessDeniedBody;

  /// No description provided for @catalogDetailNutritionTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Request timed out'**
  String get catalogDetailNutritionTimeoutTitle;

  /// No description provided for @catalogDetailNutritionTimeoutBody.
  ///
  /// In en, this message translates to:
  /// **'RADHA could not reach the nutrition service in time. Retry when your connection is stable.'**
  String get catalogDetailNutritionTimeoutBody;

  /// No description provided for @catalogDetailNutritionServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load nutrition'**
  String get catalogDetailNutritionServerTitle;

  /// No description provided for @catalogDetailNutritionServerBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong fetching the details. The product info above is unaffected.'**
  String get catalogDetailNutritionServerBody;

  /// No description provided for @catalogDetailScanLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan label'**
  String get catalogDetailScanLabel;

  /// No description provided for @catalogDetailFullNutritionPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Full nutrition isn\'t in yet'**
  String get catalogDetailFullNutritionPendingTitle;

  /// No description provided for @catalogDetailFullNutritionPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Scan this product\'s barcode to pull its real nutrition & health analysis into RADHA — it only takes a second.'**
  String get catalogDetailFullNutritionPendingBody;

  /// No description provided for @catalogDetailScanToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Scan to unlock'**
  String get catalogDetailScanToUnlock;

  /// Section header on the Profile tab for account-related links.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileSectionAccount;

  /// Profile row label that opens store selection / store management.
  ///
  /// In en, this message translates to:
  /// **'Manage stores'**
  String get profileManageStores;

  /// Section header on the Profile tab for user preference links.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profileSectionPreferences;

  /// Profile row label that opens the shopping list.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get profileShoppingList;

  /// Section header on the Profile tab for app metadata.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileSectionAbout;

  /// Fallback display name when no user session is loaded.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get profileGuestName;

  /// Fallback display name when the signed-in user id is unexpectedly empty.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get profileYouName;

  /// Fallback role chip label on the Profile tab.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get profileRoleMember;

  /// Role chip label for business owner users.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get profileRoleOwner;

  /// Role chip label for store managers.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get profileRoleManager;

  /// Role chip label for staff users.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get profileRoleStaff;

  /// Role chip label for auditor users.
  ///
  /// In en, this message translates to:
  /// **'Auditor'**
  String get profileRoleAuditor;

  /// Role chip label for consumer users.
  ///
  /// In en, this message translates to:
  /// **'Consumer'**
  String get profileRoleConsumer;

  /// Role chip label for platform or tenant admins.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get profileRoleAdmin;

  /// Profile about-card text while app version is loading.
  ///
  /// In en, this message translates to:
  /// **'Loading version…'**
  String get profileVersionLoading;

  /// Profile about-card text when app version cannot be read.
  ///
  /// In en, this message translates to:
  /// **'Version unavailable'**
  String get profileVersionUnavailable;

  /// Confirmation dialog body shown before signing out from the Profile tab. OTP is a product term; do not translate OTP.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again with an OTP to use the app.'**
  String get profileSignOutConfirmBody;

  /// AppBar title on the store-selection screen after sign-in.
  ///
  /// In en, this message translates to:
  /// **'Select store'**
  String get selectStoreTitle;

  /// Headline above the list of stores the user can access.
  ///
  /// In en, this message translates to:
  /// **'Choose a store'**
  String get selectStoreHeading;

  /// Helper copy under the store-selection headline.
  ///
  /// In en, this message translates to:
  /// **'Pick where you\'re working today. You can switch stores later from your profile.'**
  String get selectStoreBody;

  /// Empty-state title when the signed-in user has no store access rows.
  ///
  /// In en, this message translates to:
  /// **'No stores yet'**
  String get selectStoreEmptyTitle;

  /// Empty-state body when the signed-in user has no stores.
  ///
  /// In en, this message translates to:
  /// **'Your account is not associated with any store yet. Ask your manager to grant access, then come back to pick one.'**
  String get selectStoreEmptyBody;

  /// Empty-state CTA label suggesting the user contact their manager for store access.
  ///
  /// In en, this message translates to:
  /// **'Contact your manager'**
  String get selectStoreContactManager;

  /// Snackbar after tapping the contact-manager CTA on the select-store empty state.
  ///
  /// In en, this message translates to:
  /// **'Reach out to your manager to be added to a store.'**
  String get selectStoreContactManagerSnackbar;

  /// No description provided for @recallTitle.
  ///
  /// In en, this message translates to:
  /// **'Recall alerts'**
  String get recallTitle;

  /// No description provided for @recallLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load recalls.'**
  String get recallLoadError;

  /// No description provided for @recallEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No active recalls'**
  String get recallEmptyTitle;

  /// No description provided for @recallEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'You will see product recall alerts here as they are issued by regulatory bodies.'**
  String get recallEmptyBody;

  /// Fallback recall row title when the backend has no product name; id is a short product id.
  ///
  /// In en, this message translates to:
  /// **'Product {id}'**
  String recallProductFallback(String id);

  /// Recall date line; date is a preformatted YYYY-MM-DD string.
  ///
  /// In en, this message translates to:
  /// **'Recalled {date}'**
  String recallRecalledOn(String date);

  /// No description provided for @recallViewProduct.
  ///
  /// In en, this message translates to:
  /// **'View product'**
  String get recallViewProduct;

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get couldNotLoad;

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// No description provided for @lowStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Low stock alerts'**
  String get lowStockTitle;

  /// No description provided for @lowStockLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load alerts'**
  String get lowStockLoadError;

  /// No description provided for @lowStockEmpty.
  ///
  /// In en, this message translates to:
  /// **'All stock levels are healthy'**
  String get lowStockEmpty;

  /// No description provided for @lowStockRestock.
  ///
  /// In en, this message translates to:
  /// **'Restock'**
  String get lowStockRestock;

  /// Low-stock row title fallback; id is the product id.
  ///
  /// In en, this message translates to:
  /// **'Product {id}'**
  String lowStockProductFallback(String id);

  /// Current quantity vs low-stock threshold.
  ///
  /// In en, this message translates to:
  /// **'Current: {current} / Threshold: {threshold}'**
  String lowStockLevel(Object current, Object threshold);

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
