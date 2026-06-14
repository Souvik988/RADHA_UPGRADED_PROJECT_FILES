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
}
