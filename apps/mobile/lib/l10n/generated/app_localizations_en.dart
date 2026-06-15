// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get subTitle => 'Subscription';

  @override
  String get subUnlockHeadline => 'Unlock RADHA’s full picture';

  @override
  String get subLoadError => 'Couldn\'t load your subscription';

  @override
  String get subErrorBody => 'Check your connection and try again.';

  @override
  String get subChoosePlan => 'Choose a plan';

  @override
  String get subPlansLoadError => 'Couldn\'t load plans';

  @override
  String get subPlansUnavailable =>
      'Plans are unavailable right now. Please try again later.';

  @override
  String get subSecurePayment => 'Secure payment via Razorpay';

  @override
  String get subCurrentPlan => 'Current plan';

  @override
  String subRenewsInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Renews in $days days',
      one: 'Renews in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get subBillingMonthly => 'Monthly';

  @override
  String get subBillingYearly => 'Yearly';

  @override
  String get subBilledYearly => 'billed yearly';

  @override
  String get subPerMonth => '/mo';

  @override
  String get subPerYear => '/yr';

  @override
  String get subPopular => 'Popular';

  @override
  String get subStatusTrial => 'Trial';

  @override
  String subStatusDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get subStatusActive => 'Active';

  @override
  String get subStatusPastDue => 'Past due';

  @override
  String get subStatusPaused => 'Paused';

  @override
  String get subStatusCancelled => 'Cancelled';

  @override
  String subUpgradeTo(String plan) {
    return 'Upgrade to $plan';
  }

  @override
  String subChoosePlanNamed(String plan) {
    return 'Choose $plan';
  }

  @override
  String subYoureOnPlan(String plan) {
    return 'You\'re on $plan';
  }

  @override
  String subWelcome(String plan) {
    return 'You\'re on $plan. Welcome to RADHA $plan!';
  }

  @override
  String get subCheckoutCancelled =>
      'Checkout cancelled — your plan is unchanged.';

  @override
  String subPaymentPending(String supportRef) {
    return 'Payment received — confirming it now. Ref $supportRef. Pull down to refresh in a moment.';
  }

  @override
  String get subPaymentFailed => 'Payment failed. Please try again.';

  @override
  String get catalogSearchBarHint => 'Search products to find what fits you';

  @override
  String get catalogSearchHint => 'Search products or brands';

  @override
  String get catalogSearchClear => 'Clear';

  @override
  String get catalogNoMatchesTitle => 'No matches';

  @override
  String catalogNoMatchesBody(String query) {
    return 'We couldn\'t find products for “$query”. Try a different name, or scan the item instead.';
  }

  @override
  String get catalogScanProduct => 'Scan a product';

  @override
  String get catalogFindTitle => 'Find a product';

  @override
  String get catalogFindBody =>
      'Search by product name or brand to see its health rating and what\'s inside.';

  @override
  String get catalogProductsFallback => 'Products';

  @override
  String get catalogLoadErrorTitle => 'Couldn\'t load products';

  @override
  String catalogLoadErrorBody(String category) {
    return 'We hit a snag loading $category. Please try again.';
  }

  @override
  String get catalogSourceOffline => 'Offline — showing your saved catalog';

  @override
  String get catalogSourceUnavailable =>
      'Live catalog unavailable — showing saved catalog';

  @override
  String get catalogRetry => 'Retry';

  @override
  String get catalogSortHealthiest => 'Healthiest';

  @override
  String get catalogSortAZ => 'A–Z';

  @override
  String get catalogVegOnly => 'Veg only';

  @override
  String get catalogVeg => 'Veg';

  @override
  String get catalogNoVegTitle => 'No veg items here yet';

  @override
  String catalogNoVegBody(String category) {
    return 'Nothing in $category matches the veg filter right now.';
  }

  @override
  String get catalogShowAll => 'Show all';

  @override
  String get catalogNoProductsTitle => 'No products yet';

  @override
  String catalogNoProductsBody(String category) {
    return 'We\'re stocking the $category aisle. Meanwhile, scan any item to check its health and expiry.';
  }

  @override
  String get catalogFeaturedTitle => 'Featured products';

  @override
  String get catalogHealthyPicksTitle => 'Healthy picks';

  @override
  String get catalogDetailProductFallback => 'Product';

  @override
  String get catalogDetailTitle => 'Product';

  @override
  String get catalogDetailShareTooltip => 'Share';

  @override
  String get catalogDetailSeeHealthierOptions => 'See healthier options';

  @override
  String get catalogDetailSavedSnackbar =>
      'Saved — we\'ll alert you if it\'s ever recalled.';

  @override
  String get catalogDetailSaveFailedSnackbar =>
      'Could not save. Please try again.';

  @override
  String catalogDetailShareRating(String rating, String label) {
    return ' — RADHA health rating $rating/5 ($label)';
  }

  @override
  String catalogDetailShareText(String productName, String ratingSummary) {
    return 'Checked \"$productName\" on RADHA$ratingSummary.';
  }

  @override
  String get catalogDetailSavedTooltip => 'Saved';

  @override
  String get catalogDetailHealthPendingTitle => 'Health rating not in yet';

  @override
  String get catalogDetailHealthPendingBody =>
      'Scan this product to pull its full health analysis into RADHA.';

  @override
  String get catalogDetailHealthRatingLabel => 'RADHA Health Rating';

  @override
  String get catalogDetailHealthExcellent => 'Excellent';

  @override
  String get catalogDetailHealthGood => 'Good';

  @override
  String get catalogDetailHealthFair => 'Fair';

  @override
  String get catalogDetailHealthPoor => 'Poor';

  @override
  String get catalogDetailHealthAvoid => 'Avoid';

  @override
  String get catalogDetailInsightHighProtein => 'High protein';

  @override
  String get catalogDetailInsightGoodFibre => 'Good fibre';

  @override
  String get catalogDetailInsightMinimallyProcessed => 'Minimally processed';

  @override
  String get catalogDetailConcernHighSugar => 'High sugar';

  @override
  String get catalogDetailConcernHighSaturatedFat => 'High saturated fat';

  @override
  String get catalogDetailConcernHighSodium => 'High sodium';

  @override
  String get catalogDetailConcernUltraProcessed => 'Ultra-processed';

  @override
  String get catalogDetailConcernContainsTransFat => 'Contains trans fat';

  @override
  String get catalogDetailConcernContainsAllergens => 'Contains allergens';

  @override
  String get catalogDetailLikeHeading => 'What you\'ll like';

  @override
  String get catalogDetailConcernHeading => 'What should concern you';

  @override
  String get catalogDetailNutritionSourceNote =>
      'Based on the product\'s real nutrition (per 100 g).';

  @override
  String get catalogDetailKeyNutrients => 'Key nutrients';

  @override
  String get catalogDetailNutrientProtein => 'Protein';

  @override
  String get catalogDetailNutrientTotalSugars => 'Total Sugars';

  @override
  String get catalogDetailNutrientEnergy => 'Energy';

  @override
  String get catalogDetailAllNutrients => 'All nutrients';

  @override
  String get catalogDetailNutrientTotalFat => 'Total Fat';

  @override
  String get catalogDetailNutrientSaturatedFat => 'Saturated Fat';

  @override
  String get catalogDetailNutrientCarbohydrates => 'Carbohydrates';

  @override
  String get catalogDetailNutrientFibre => 'Fibre';

  @override
  String get catalogDetailNutrientSodium => 'Sodium';

  @override
  String get catalogDetailPer100g => 'Per 100 g';

  @override
  String get catalogDetailPer50g => 'Per 50 g';

  @override
  String get catalogDetailRdaNote => '% of reference daily intake (adult).';

  @override
  String get catalogDetailRadhaPlus => 'RADHA Plus';

  @override
  String get catalogDetailForYou => 'For you';

  @override
  String get catalogDetailIngredientDeepDiveTitle => 'Ingredient deep-dive';

  @override
  String get catalogDetailIngredientDeepDiveLockedBody =>
      'See every ingredient explained with a safety verdict — what it is, why it\'s there, and whether to worry.';

  @override
  String get catalogDetailIngredientExplainError =>
      'We couldn\'t explain these ingredients right now.';

  @override
  String get catalogDetailIngredientNeedsLabel =>
      'Ingredient detail needs a clear label photo. Scan the pack label and RADHA will explain the real ingredient list.';

  @override
  String get catalogDetailPersonalisedFlagsTitle => 'Personalised flags';

  @override
  String get catalogDetailPersonalisedFlagsLockedBody =>
      'Match this product against your saved allergens & health goals — we\'ll flag what\'s right (or wrong) for you.';

  @override
  String get catalogDetailPersonaliseError =>
      'We couldn\'t personalise this right now.';

  @override
  String get catalogDetailNoAllergensDetected =>
      'No allergens detected in this product.';

  @override
  String get catalogDetailAllergenSignalDetected =>
      'This product reports possible allergens. Check the label before buying.';

  @override
  String get catalogDetailAllergenSignalUnavailable =>
      'Allergen details are not in the product record yet. Scan the label to personalise this safely.';

  @override
  String catalogDetailAllergenAvoided(String allergen) {
    return '$allergen — you avoid this';
  }

  @override
  String catalogDetailUnlockWithPlan(String plan) {
    return 'Unlock with $plan';
  }

  @override
  String get catalogDetailWouldBuyQuestion => 'Would you buy this product?';

  @override
  String get catalogDetailWouldBuyThanks => 'Thanks for sharing!';

  @override
  String get catalogDetailWouldBuyYes => 'Yes';

  @override
  String get catalogDetailWouldBuyNo => 'No';

  @override
  String get catalogDetailWouldBuyAlreadyBought => 'Already bought';

  @override
  String get catalogDetailNutritionNotFoundTitle =>
      'We don\'t have this record yet';

  @override
  String get catalogDetailNutritionNotFoundBody =>
      'RADHA doesn\'t have this product\'s full nutrition yet. Scan its barcode or label to pull in the real data.';

  @override
  String get catalogDetailNutritionOfflineTitle => 'You\'re offline';

  @override
  String get catalogDetailNutritionOfflineBody =>
      'We couldn\'t load nutrition. Your product details above are still here — reconnect and retry.';

  @override
  String get catalogDetailNutritionSessionExpiredTitle => 'Session expired';

  @override
  String get catalogDetailNutritionSessionExpiredBody =>
      'Please retry — RADHA will refresh your session and try again.';

  @override
  String get catalogDetailNutritionAccessDeniedTitle => 'Access restricted';

  @override
  String get catalogDetailNutritionAccessDeniedBody =>
      'Your account cannot read this nutrition record. The product information above is still available.';

  @override
  String get catalogDetailNutritionTimeoutTitle => 'Request timed out';

  @override
  String get catalogDetailNutritionTimeoutBody =>
      'RADHA could not reach the nutrition service in time. Retry when your connection is stable.';

  @override
  String get catalogDetailNutritionServerTitle => 'Couldn\'t load nutrition';

  @override
  String get catalogDetailNutritionServerBody =>
      'Something went wrong fetching the details. The product info above is unaffected.';

  @override
  String get catalogDetailScanLabel => 'Scan label';

  @override
  String get catalogDetailFullNutritionPendingTitle =>
      'Full nutrition isn\'t in yet';

  @override
  String get catalogDetailFullNutritionPendingBody =>
      'Scan this product\'s barcode to pull its real nutrition & health analysis into RADHA — it only takes a second.';

  @override
  String get catalogDetailScanToUnlock => 'Scan to unlock';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileManageStores => 'Manage stores';

  @override
  String get profileSectionPreferences => 'Preferences';

  @override
  String get profileShoppingList => 'Shopping list';

  @override
  String get profileSectionAbout => 'About';

  @override
  String get profileGuestName => 'Guest';

  @override
  String get profileYouName => 'You';

  @override
  String get profileRoleMember => 'Member';

  @override
  String get profileRoleOwner => 'Owner';

  @override
  String get profileRoleManager => 'Manager';

  @override
  String get profileRoleStaff => 'Staff';

  @override
  String get profileRoleAuditor => 'Auditor';

  @override
  String get profileRoleConsumer => 'Consumer';

  @override
  String get profileRoleAdmin => 'Admin';

  @override
  String get profileVersionLoading => 'Loading version…';

  @override
  String get profileVersionUnavailable => 'Version unavailable';

  @override
  String get profileSignOutConfirmBody =>
      'You will need to sign in again with an OTP to use the app.';

  @override
  String get selectStoreTitle => 'Select store';

  @override
  String get selectStoreHeading => 'Choose a store';

  @override
  String get selectStoreBody =>
      'Pick where you\'re working today. You can switch stores later from your profile.';

  @override
  String get selectStoreEmptyTitle => 'No stores yet';

  @override
  String get selectStoreEmptyBody =>
      'Your account is not associated with any store yet. Ask your manager to grant access, then come back to pick one.';

  @override
  String get selectStoreContactManager => 'Contact your manager';

  @override
  String get selectStoreContactManagerSnackbar =>
      'Reach out to your manager to be added to a store.';

  @override
  String get recallTitle => 'Recall alerts';

  @override
  String get recallLoadError => 'Could not load recalls.';

  @override
  String get recallEmptyTitle => 'No active recalls';

  @override
  String get recallEmptyBody =>
      'You will see product recall alerts here as they are issued by regulatory bodies.';

  @override
  String recallProductFallback(String id) {
    return 'Product $id';
  }

  @override
  String recallRecalledOn(String date) {
    return 'Recalled $date';
  }

  @override
  String get recallViewProduct => 'View product';

  @override
  String get couldNotLoad => 'Could not load';

  @override
  String get retryLabel => 'Retry';

  @override
  String get lowStockTitle => 'Low stock alerts';

  @override
  String get lowStockLoadError => 'Failed to load alerts';

  @override
  String get lowStockEmpty => 'All stock levels are healthy';

  @override
  String get lowStockRestock => 'Restock';

  @override
  String lowStockProductFallback(String id) {
    return 'Product $id';
  }

  @override
  String lowStockLevel(Object current, Object threshold) {
    return 'Current: $current / Threshold: $threshold';
  }

  @override
  String get appName => 'RADHA';

  @override
  String get tagline => 'Retail Assistant for Data, Health & Audits.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get getStarted => 'Get started';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get search => 'Search';

  @override
  String get loading => 'Loading';

  @override
  String get error => 'Something went wrong';

  @override
  String get tryAgain => 'Try again';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get enterOtp => 'Enter OTP';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get otpSent => 'We sent you a 6-digit code';

  @override
  String get home => 'Home';

  @override
  String get scan => 'Scan';

  @override
  String get expiry => 'Expiry';

  @override
  String get tasks => 'Tasks';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get scanProduct => 'Scan a product';

  @override
  String get pointAtBarcode => 'Point your camera at a barcode';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get productNotFound => 'Product not found';

  @override
  String get expiryTracker => 'Expiry tracker';

  @override
  String get addExpiry => 'Add expiry';

  @override
  String get expiringSoon => 'Expiring soon';

  @override
  String get expired => 'Expired';

  @override
  String get yourTasks => 'Your tasks';

  @override
  String get noTasks => 'No tasks yet';

  @override
  String get completeTask => 'Complete task';

  @override
  String get welcome => 'Welcome';

  @override
  String get welcomeMessage =>
      'Scan, track, audit your stock without the spreadsheets.';

  @override
  String get referrals => 'Referrals';

  @override
  String get shareYourCode => 'Share your code';

  @override
  String get yourReferralCode => 'Your referral code';

  @override
  String get invitees => 'Invitees';

  @override
  String get rewardsEarned => 'Rewards earned';

  @override
  String get redeemCode => 'Redeem code';

  @override
  String get enterReferralCode => 'Enter a referral code';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get languageUpdated => 'Language updated';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String errorRateLimitOtp(int seconds) {
    return 'Too many OTP requests. Try again in $seconds seconds.';
  }

  @override
  String get errorOtpInvalid => 'Invalid OTP. Please try again.';

  @override
  String get errorOtpExpired => 'OTP expired. Please request a new one.';

  @override
  String get errorAuthRequired => 'Please sign in to continue.';

  @override
  String get errorNotFound => 'Not found.';

  @override
  String get ingredientExplainerErrorTitle => 'Could not load explanation';

  @override
  String get ingredientExplainerHealthConsiderations => 'Health considerations';

  @override
  String healthyAlternativesTitle(String productName) {
    return 'Better choices than $productName';
  }

  @override
  String get healthyAlternativesGenericTitle => 'Better choices';

  @override
  String get healthyAlternativesEmptyTitle => 'No healthier alternatives yet';

  @override
  String get healthyAlternativesEmptyBody =>
      'No healthier alternatives found in the same category yet.';

  @override
  String get healthyAlternativesErrorTitle => 'Could not load alternatives';

  @override
  String get healthyAlternativesAddToList => 'Add to shopping list';

  @override
  String get healthyAlternativesView => 'View';

  @override
  String get healthyAlternativesAddedToList => 'Added to your shopping list';

  @override
  String get healthyAlternativesAddFailed => 'Could not add to shopping list';

  @override
  String get savedProductsTitle => 'Saved products';

  @override
  String get savedProductsEmptyTitle => 'Saved products';

  @override
  String get savedProductsEmptyBody =>
      'Save products from the scan result screen to see them here.';

  @override
  String get savedProductsErrorTitle => 'Could not load saved products';

  @override
  String savedProductsSavedOn(String date) {
    return 'Saved $date';
  }

  @override
  String get digestTitle => 'Your week with RADHA';

  @override
  String digestWeekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String digestSavingsHero(String amount) {
    return '₹$amount saved';
  }

  @override
  String digestScansHero(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scans',
      one: '1 scan',
    );
    return '$_temp0';
  }

  @override
  String get digestHeroEmptyHeadline => 'A quiet week';

  @override
  String get digestScans => 'Scans';

  @override
  String get digestSavedProducts => 'Saved';

  @override
  String get digestExpiringSoon => 'Expiring soon';

  @override
  String digestRecallAlerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recall alerts',
      one: '1 recall alert',
    );
    return '$_temp0';
  }

  @override
  String get digestRecallAlertsBody =>
      'Products you scanned this week have new safety advisories.';

  @override
  String get digestRecallAlertsCta => 'Review';

  @override
  String get digestTopCategoriesHeader => 'What you\'re scanning';

  @override
  String get digestHighlightsHeader => 'Highlights';

  @override
  String get digestContinueScanning => 'Continue scanning';

  @override
  String get digestShare => 'Share my week';

  @override
  String digestShareTemplate(int scans, String savings) {
    return 'I scanned $scans products this week and saved ₹$savings with RADHA. Try it: https://radha.app';
  }

  @override
  String get digestEmptyTitle => 'No activity this week';

  @override
  String get digestEmptyBody => 'Start scanning to build your weekly story.';

  @override
  String get digestErrorTitle => 'Could not load your weekly digest';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPushNotifications => 'Push notifications';

  @override
  String get settingsPushNotificationsHint => 'Get alerts on your phone';

  @override
  String get settingsRecallAlerts => 'Recall alerts';

  @override
  String get settingsRecallAlertsHint =>
      'Be told when a product you scanned is recalled';

  @override
  String get settingsWeeklyDigest => 'Weekly digest';

  @override
  String get settingsWeeklyDigestHint =>
      'Sunday summary of your scans and savings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTextSize => 'Text size';

  @override
  String get settingsTextSizeSmall => 'Small';

  @override
  String get settingsTextSizeStandard => 'Standard';

  @override
  String get settingsTextSizeLarge => 'Large';

  @override
  String get settingsDataPrivacy => 'Data & privacy';

  @override
  String get settingsAllergens => 'Allergen profile';

  @override
  String get settingsAllergensHint =>
      'Pick the ingredients we should warn you about';

  @override
  String get settingsSignOutAll => 'Sign out from all devices';

  @override
  String get settingsSignOutAllConfirmTitle => 'Sign out everywhere?';

  @override
  String get settingsSignOutAllConfirmBody =>
      'You\'ll need to sign in again on every device that uses this account.';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountTitle => 'Delete account';

  @override
  String get settingsDeleteAccountBody =>
      'This will permanently delete your data. Type DELETE to confirm.';

  @override
  String get settingsDeleteAccountConfirm => 'DELETE';

  @override
  String get settingsDeleteAccountUnavailable =>
      'Contact support to delete your account.';

  @override
  String get settingsDeleteAccountContact => 'Contact support';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsTerms => 'Terms of service';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsVersion => 'App version';

  @override
  String settingsVersionValue(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get settingsSupport => 'Support';

  @override
  String get settingsSupportHint => 'Get help, report a bug, or share feedback';

  @override
  String get settingsLinkOpenFailed => 'Could not open link';

  @override
  String conflictBannerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conflicts need your attention',
      one: '1 conflict needs your attention',
    );
    return '$_temp0';
  }

  @override
  String get conflictBannerCta => 'Resolve';

  @override
  String get conflictBannerDismiss => 'Dismiss';

  @override
  String get conflictResolveTitle => 'Resolve sync conflicts';

  @override
  String get conflictResolveSubtitle =>
      'Pick which version to keep for each item.';

  @override
  String get conflictUseMine => 'Use my version';

  @override
  String get conflictUseServer => 'Use server version';

  @override
  String get conflictResolved => 'Conflict resolved';

  @override
  String get conflictResolvedAll => 'All conflicts resolved';

  @override
  String conflictAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return 'Tried $_temp0';
  }

  @override
  String get conflictResourceTask => 'Task';

  @override
  String get conflictResourceExpiry => 'Expiry record';

  @override
  String get conflictResourceScan => 'Scan';

  @override
  String get conflictResourceInventory => 'Stock adjustment';

  @override
  String get conflictResourceGrn => 'GRN entry';

  @override
  String get conflictResourceShoppingList => 'Shopping list item';

  @override
  String get conflictResourceGeneric => 'Sync change';

  @override
  String conflictLocalChangeSummary(String summary) {
    return 'Your change: $summary';
  }

  @override
  String get supportTitle => 'Support';

  @override
  String get supportContactUs => 'Contact us';

  @override
  String get supportEmailUs => 'Email us';

  @override
  String get supportEmailUsHint => 'support@radha.app';

  @override
  String get supportCallUs => 'Call support';

  @override
  String get supportCallUsHint => 'Mon–Fri, 9am–6pm IST';

  @override
  String get supportReportBug => 'Report a bug';

  @override
  String get supportBugDescription => 'What happened?';

  @override
  String get supportBugDescriptionHint =>
      'Describe what you were doing when it broke.';

  @override
  String get supportAttachScreenshot => 'Attach screenshot';

  @override
  String get supportScreenshotAttached => 'Screenshot attached';

  @override
  String get supportRemoveScreenshot => 'Remove';

  @override
  String get supportSubmit => 'Send report';

  @override
  String get supportSubmitted => 'Thanks — we received your report.';

  @override
  String get supportSubmitFailed => 'Could not send. Please email us instead.';

  @override
  String get supportBugDescriptionRequired => 'Please describe what happened.';

  @override
  String get supportFaq => 'Frequently asked questions';

  @override
  String get supportFaqQ1 => 'How do I scan a barcode?';

  @override
  String get supportFaqA1 =>
      'Open the Scan tab, point your camera at the barcode, and hold steady. We\'ll find the product the moment we read a clean code.';

  @override
  String get supportFaqQ2 => 'What if a product isn\'t in the database?';

  @override
  String get supportFaqA2 =>
      'Tap \"Add product\" on the not-found screen and we\'ll create a new entry tied to your store. The catalog grows for everyone over time.';

  @override
  String get supportFaqQ3 => 'How do I cancel my subscription?';

  @override
  String get supportFaqA3 =>
      'Go to Profile → Subscription. You can cancel anytime; we don\'t charge after the next billing cycle starts.';

  @override
  String get supportFaqQ4 => 'Why am I seeing a recall alert?';

  @override
  String get supportFaqA4 =>
      'We match every scan against the FSSAI recall feed. If a batch you sold is on the list, we surface it so you can pull stock and notify customers.';

  @override
  String get supportFaqQ5 => 'How do I share my allergen profile with family?';

  @override
  String get supportFaqA5 =>
      'Allergen profiles are per-account today. Share them with family by signing in on the same household account, or pick the same allergens on each phone.';

  @override
  String get reportsTitle => 'Reports & exports';

  @override
  String get reportsTabAvailable => 'Available';

  @override
  String get reportsTabScheduled => 'Scheduled';

  @override
  String get reportsTabHistory => 'History';

  @override
  String get reportsQuickExportsHeader => 'Quick exports';

  @override
  String get reportsInventorySnapshot => 'Inventory snapshot';

  @override
  String get reportsExpiringItems => 'Expiring items';

  @override
  String get reportsSalesSummary => 'Sales summary';

  @override
  String get reportsAuditLog => 'Audit log';

  @override
  String get reportsGenerate => 'Generate';

  @override
  String get reportsGenerateSuccess => 'Report ready';

  @override
  String get reportsGenerateQueued =>
      'Generation started — we\'ll notify you when it\'s ready';

  @override
  String get reportsGenerateFailed => 'Could not start the report';

  @override
  String get reportsDownloadFailed => 'Could not open the download';

  @override
  String get reportsScheduleNew => 'New schedule';

  @override
  String get reportsScheduleCreate => 'Create schedule';

  @override
  String get reportsScheduleSuccess => 'Schedule created';

  @override
  String get reportsScheduleReportLabel => 'Report';

  @override
  String get reportsScheduleDayOfWeek => 'Day of week';

  @override
  String get reportsScheduleDayOfMonth => 'Day of month';

  @override
  String get reportsScheduleTime => 'Time';

  @override
  String get reportsScheduleFormat => 'Format';

  @override
  String get reportsScheduleActionsTooltip => 'Schedule actions';

  @override
  String get reportsFrequency => 'Frequency';

  @override
  String get reportsFrequencyDaily => 'Daily';

  @override
  String get reportsFrequencyWeekly => 'Weekly';

  @override
  String get reportsFrequencyMonthly => 'Monthly';

  @override
  String get reportsPause => 'Pause';

  @override
  String get reportsResume => 'Resume';

  @override
  String get reportsDelete => 'Delete';

  @override
  String get reportsDeleteScheduleTitle => 'Delete schedule?';

  @override
  String get reportsDeleteScheduleBody =>
      'This recurring schedule will stop firing. Past runs stay in your history.';

  @override
  String reportsLastRun(String when) {
    return 'Last run $when';
  }

  @override
  String get reportsLastRunNever => 'Hasn\'t run yet';

  @override
  String reportsNextRun(String when) {
    return 'Next run $when';
  }

  @override
  String get reportsDownload => 'Download';

  @override
  String get reportsStatusCompleted => 'Ready';

  @override
  String get reportsStatusGenerating => 'Generating';

  @override
  String get reportsStatusFailed => 'Failed';

  @override
  String get reportsStatusCancelled => 'Cancelled';

  @override
  String get reportsStatusExpired => 'Expired';

  @override
  String get reportsEmptyTitle => 'No exports yet';

  @override
  String get reportsEmptyBody =>
      'Generate a report from the Available tab and it\'ll show up here.';

  @override
  String get reportsScheduledEmptyTitle => 'No scheduled reports';

  @override
  String get reportsScheduledEmptyBody =>
      'Tap New schedule to have a report run automatically.';

  @override
  String get reportsErrorTitle => 'Could not load reports';

  @override
  String get ohsTitle => 'Operational health';

  @override
  String get ohsScoreCaption => 'OHS score';

  @override
  String ohsScore(int score) {
    return '$score';
  }

  @override
  String ohsDeltaUp(int value) {
    return '+$value from last week';
  }

  @override
  String ohsDeltaDown(int value) {
    return '-$value from last week';
  }

  @override
  String get ohsDeltaSame => 'No change from last week';

  @override
  String get ohsDeltaUnavailable =>
      'Not enough data for a week-over-week comparison yet';

  @override
  String get ohsCompliance => 'Compliance';

  @override
  String get ohsInventoryHygiene => 'Inventory hygiene';

  @override
  String get ohsAuditCompletion => 'Audit completion';

  @override
  String get ohsActionItemsHeader => 'Action items';

  @override
  String ohsActionExpiry(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expiry alerts need a review',
      one: '1 expiry alert needs a review',
    );
    return '$_temp0';
  }

  @override
  String ohsActionLowStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count low-stock alerts are unresolved',
      one: '1 low-stock alert is unresolved',
    );
    return '$_temp0';
  }

  @override
  String get ohsActionTasks => 'Review open tasks for your store';

  @override
  String get ohsActionNoneBody =>
      'Everything looks good — keep scanning to maintain your score.';

  @override
  String get ohsTrendHeader => 'Trend';

  @override
  String get ohsViewDetailedReports => 'View detailed reports';

  @override
  String get ohsEmptyTitle => 'Build your operational health score';

  @override
  String get ohsEmptyBody => 'Start scanning to build your OHS score.';

  @override
  String get ohsErrorTitle => 'Could not load your dashboard';

  @override
  String get expiryTabNear => 'Near-expiry';

  @override
  String get expiryTabSafe => 'Safe';

  @override
  String get expiryCalendarTooltip => 'Calendar view';

  @override
  String get expiryEmptyExpiredTitle => 'Nothing expired';

  @override
  String get expiryEmptyNearTitle => 'All clear';

  @override
  String get expiryEmptyDefaultTitle => 'No records yet';

  @override
  String get expiryEmptyBody => 'No records in this category.';

  @override
  String expiryProductShort(String id) {
    return 'Product $id';
  }

  @override
  String expiryBatch(String batch) {
    return 'Batch $batch';
  }

  @override
  String expiryQty(String qty) {
    return 'Qty $qty';
  }

  @override
  String expiryExp(String date) {
    return 'Exp $date';
  }

  @override
  String get expiryPillToday => 'Today';

  @override
  String get expiryPillTomorrow => 'Tomorrow';

  @override
  String expiryPillDays(int days) {
    return '${days}d';
  }

  @override
  String get expiryPillSoon => 'Soon';

  @override
  String get expiryLoadError => 'Couldn\'t load expiry records.';

  @override
  String get expiryCouldNotLoadSemantic => 'Could not load';

  @override
  String get inventoryTitle => 'Inventory';

  @override
  String get inventorySearchTooltip => 'Search inventory';

  @override
  String get inventorySearchHint => 'Search by product or EAN...';

  @override
  String get inventoryStockMovement => 'Stock Movement';

  @override
  String get inventoryLowStockAlerts => 'Low Stock Alerts';

  @override
  String get inventoryLoadError => 'Failed to load inventory';

  @override
  String get inventoryEmpty => 'No inventory items found';

  @override
  String inventoryNoMatches(String query) {
    return 'No matches for \"$query\"';
  }

  @override
  String inventoryProductShort(String id) {
    return 'Product $id';
  }

  @override
  String get inventoryBelowThreshold => 'Below threshold';

  @override
  String get inventoryInStock => 'In stock';

  @override
  String get inventoryUnitsLabel => 'units';

  @override
  String get inventoryTotalQuantity => 'Total quantity';

  @override
  String get inventoryLowStockThreshold => 'Low-stock threshold';

  @override
  String inventoryQtyUnits(int count) {
    return '$count units';
  }

  @override
  String get inventoryBatchLedgerHint =>
      'Tap \"Stock movement\" to view the full batch ledger.';

  @override
  String get inventoryLowStockBadge => 'Low Stock';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get tasksTabMine => 'My Tasks';

  @override
  String get tasksTabAll => 'All';

  @override
  String get tasksNewTask => 'New task';

  @override
  String get tasksEmptyTitle => 'No tasks here';

  @override
  String get tasksEmptyBody => 'Tasks assigned to this view will show up here.';

  @override
  String get tasksLoadError => 'Failed to load tasks';

  @override
  String get taskEvidence => 'Evidence';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get taskStatusOpen => 'Open';

  @override
  String get taskStatusPending => 'Pending';

  @override
  String get taskStatusInProgress => 'In progress';

  @override
  String get taskStatusCompleted => 'Completed';

  @override
  String get taskStatusCancelled => 'Cancelled';

  @override
  String get scanTitle => 'Scan a product';

  @override
  String get scanAlignHint => 'Align the barcode within the frame';

  @override
  String get scanBatchHint =>
      'Batch mode — keep scanning, items add automatically';

  @override
  String scanBatchAdded(String code, int count) {
    return 'Added $code · $count scanned';
  }

  @override
  String scanBatchDone(int count) {
    return 'Done · $count';
  }

  @override
  String get scanLabelAction => 'Scan label';

  @override
  String get scanGalleryAction => 'Gallery';

  @override
  String get scanEnterManually => 'Enter manually';

  @override
  String get scanBulkAudit => 'Bulk audit';

  @override
  String get scanHistoryAction => 'History';

  @override
  String get scanFlash => 'Flash';

  @override
  String get scanTroubleTitle => 'Trouble scanning?';

  @override
  String get scanTroubleBody =>
      'Low light or a damaged barcode? Turn on the flash, or read the label instead.';

  @override
  String get scanGalleryNoBarcode =>
      'No barcode found. Tip: use \'Scan label\' to read the ingredients.';

  @override
  String get scanInvalidEan => 'Enter a valid EAN-8, EAN-13, or UPC-A code';

  @override
  String get scanWebTitle => 'Scan';

  @override
  String get scanWebUnavailable =>
      'Camera scanning is not available on web.\nEnter a barcode manually:';

  @override
  String get scanEanFieldLabel => 'EAN / UPC Code';

  @override
  String get scanEanHintExample => 'e.g. 5901234123457';

  @override
  String get scanLookUp => 'Look up';

  @override
  String get scanEnterBarcode => 'Enter barcode';

  @override
  String get scanHistoryTitle => 'Scan history';

  @override
  String get scanNoHistory => 'No scans yet this session.';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeGreetingFallbackName => 'there';

  @override
  String get homeTrialEnded => 'Free trial ended — upgrade to keep access';

  @override
  String homeTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Free trial · $_temp0 left';
  }

  @override
  String get homeUpgradeArrow => 'Upgrade →';

  @override
  String get homeKpiSaved => 'Saved';

  @override
  String get homeKpiNearExpiry => 'Near expiry';

  @override
  String get homeKpiRecallAlerts => 'Recall alerts';

  @override
  String get homeKpiOpenTasks => 'Open tasks';

  @override
  String get homeKpiLowStock => 'Low stock';

  @override
  String get homeEyebrowFoodSafety => 'FOOD SAFETY ALERT';

  @override
  String get homeEyebrowToday => 'AAJ KA KAAM · TODAY';

  @override
  String get homeEyebrowHealthScan => 'YOUR HEALTH SCAN';

  @override
  String get homeEyebrowScanToLearn => 'SCAN TO LEARN';

  @override
  String get homeEyebrowAllClear => 'ALL CLEAR';

  @override
  String homeStoryRecall(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recalled products — check what you have at home',
      one: '1 recalled product — check what you have at home',
    );
    return '$_temp0';
  }

  @override
  String homeStoryNearExpiryConsumer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved items expire this week — use them up',
      one: '1 saved item expires this week — use it up',
    );
    return '$_temp0';
  }

  @override
  String get homeStoryKnowWhatYouEat => 'Know what you eat';

  @override
  String get homeStoryScanInside =>
      'Point your camera at any food barcode — see what\'s inside';

  @override
  String homeStoryNearExpiryBusiness(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items near expiry — clear the shelf',
      one: '1 item near expiry — clear the shelf',
    );
    return '$_temp0';
  }

  @override
  String homeStoryOpenTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks need you today',
      one: '1 task needs you today',
    );
    return '$_temp0';
  }

  @override
  String homeStoryLowStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items running low on stock',
      one: '1 item running low on stock',
    );
    return '$_temp0';
  }

  @override
  String get homeStoreToday => 'Here\'s your store today';

  @override
  String get homeStoreAllGood => 'Shabaash! Your store\'s in great shape today';

  @override
  String get homeCtaViewRecallAlerts => 'View recall alerts';

  @override
  String get homeCtaCheckExpiry => 'Check expiry';

  @override
  String get homeCtaOpenExpiry => 'Open expiry';

  @override
  String get homeCtaViewTasks => 'View tasks';

  @override
  String get homeCtaCheckInventory => 'Check inventory';

  @override
  String get homeCtaOpenTasks => 'Open tasks';

  @override
  String get homeCtaRunAudit => 'Run a quick audit';

  @override
  String get homeQuickActions => 'Quick actions';

  @override
  String get homeQuickScan => 'Scan';

  @override
  String get homeQuickShopping => 'Shopping';

  @override
  String get homeQuickAddExpiry => 'Add Expiry';

  @override
  String get homeQuickNewTask => 'New Task';

  @override
  String get homeRecentTasks => 'Recent tasks';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeNoOpenTasks => 'No open tasks — create one';

  @override
  String homeTaskAssignedTo(String name) {
    return 'Assigned to $name';
  }

  @override
  String get homeTaskOverdue => 'Overdue';

  @override
  String get homeTaskDueToday => 'Due today';

  @override
  String get homeTaskDueTomorrow => 'Due tomorrow';

  @override
  String homeTaskDueInDays(int days) {
    return 'Due in $days days';
  }

  @override
  String homeTaskDueOn(String date) {
    return 'Due $date';
  }

  @override
  String get homeHowHelps => 'How RADHA helps you';

  @override
  String get homeScanBarcodeTitle => 'Scan any food barcode';

  @override
  String get homeScanBarcodeBody =>
      'See the health rating, ingredients, and what to watch out for.';

  @override
  String get homeRecallTitle => 'Safety recall alerts';

  @override
  String get homeRecallBody => 'Stay informed about recalled food products.';

  @override
  String get homePromoKnowFoodEyebrow => 'KNOW YOUR FOOD';

  @override
  String get homePromoKnowFoodHeadline =>
      'Scan the label — see what\'s really inside';

  @override
  String get homePromoKnowFoodCta => 'Scan & learn';

  @override
  String get homePromoExpiryEyebrow => 'NEVER MISS A DATE';

  @override
  String get homePromoExpiryHeadline =>
      'Catch every expiry before it slips away';

  @override
  String get homePromoExpiryCta => 'Track expiry';

  @override
  String get homePromoFestiveEyebrow => 'FESTIVE PICKS';

  @override
  String get homePromoFestiveHeadline => 'Shop the season, the healthy way';

  @override
  String get homePromoFestiveCta => 'Browse products';

  @override
  String get homePromoBazaarEyebrow => 'AAJ KA BAZAAR';

  @override
  String get homePromoBazaarHeadline => 'Audit your shelves in minutes';

  @override
  String get homePromoBazaarCta => 'Start an audit';

  @override
  String get homeShopByCategory => 'Shop by category';

  @override
  String get homeShopByCategorySubtitle =>
      'Tap an aisle to scan or browse its products';

  @override
  String get onboardingWelcomeValue =>
      'Scan, track, audit your stock without the spreadsheets.';

  @override
  String get onboardingCapabilitiesTitle =>
      'Built for the floor,\nnot the back office.';

  @override
  String get onboardingCapScanTitle => 'Scan products in one tap';

  @override
  String get onboardingCapScanBody =>
      'EAN lookup with health and approval pre-checked.';

  @override
  String get onboardingCapExpiryTitle => 'Catch expiry before it costs you';

  @override
  String get onboardingCapExpiryBody =>
      'OCR-assisted dates and per-category thresholds.';

  @override
  String get onboardingCapAuditTitle => 'Run audits the team can finish';

  @override
  String get onboardingCapAuditBody =>
      'Tasks, evidence and bulk scan sessions.';

  @override
  String get onboardingSegmentTitle => 'Who are you here as?';

  @override
  String get onboardingSegmentSubtitle =>
      'Pick the closest fit. You can change later in Settings.';

  @override
  String get segmentPersonalTitle => 'Personal';

  @override
  String get segmentPersonalBody => 'Just shopping for myself';

  @override
  String get segmentParentTitle => 'Parent';

  @override
  String get segmentParentBody => 'Shopping for my family / kids';

  @override
  String get segmentBusinessTitle => 'Business owner';

  @override
  String get segmentBusinessBody => 'I run a small retail store';

  @override
  String get segmentPharmacyTitle => 'Pharmacy';

  @override
  String get segmentPharmacyBody => 'I run a pharmacy / chemist';

  @override
  String get segmentInstitutionTitle => 'Institution';

  @override
  String get segmentInstitutionBody => 'School / hostel / canteen';

  @override
  String get segmentAuditorTitle => 'Auditor (invited)';

  @override
  String get segmentAuditorBody => 'I have an invite code';

  @override
  String get allergenTitle => 'Allergens';

  @override
  String get allergenLoadError => 'Could not load your allergen profile.';

  @override
  String get allergenHeading => 'Your allergens';

  @override
  String get allergenIntro =>
      'Tap any allergens you react to. We will warn you when a scanned product contains them.';

  @override
  String allergenTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allergens tracked',
      one: '1 allergen tracked',
    );
    return '$_temp0';
  }

  @override
  String get allergenNoneTracked => 'No allergens tracked yet';

  @override
  String get allergenSavedCleared => 'Allergen profile cleared.';

  @override
  String get allergenSaved => 'Allergen profile saved.';

  @override
  String get allergenSaveError => 'Could not save your allergens.';

  @override
  String get allergenPeanut => 'Peanut';

  @override
  String get allergenTreeNut => 'Tree nut';

  @override
  String get allergenDairy => 'Dairy';

  @override
  String get allergenEggs => 'Eggs';

  @override
  String get allergenSoy => 'Soy';

  @override
  String get allergenWheat => 'Wheat';

  @override
  String get allergenFish => 'Fish';

  @override
  String get allergenShellfish => 'Shellfish';

  @override
  String get allergenSesame => 'Sesame';

  @override
  String get allergenGluten => 'Gluten';

  @override
  String get allergenMustard => 'Mustard';

  @override
  String get allergenCelery => 'Celery';

  @override
  String get allergenLupin => 'Lupin';

  @override
  String get allergenMolluscs => 'Molluscs';

  @override
  String get allergenSulphites => 'Sulphites';

  @override
  String get homePromoPlusHeadline =>
      'Unlock ingredient deep-dives and allergen alerts';
}
