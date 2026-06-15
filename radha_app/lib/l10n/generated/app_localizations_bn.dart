// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'RADHA';

  @override
  String get tagline => 'ডেটা, স্বাস্থ্য এবং অডিটের জন্য খুচরা সহকারী।';

  @override
  String get continueLabel => 'চালিয়ে যান';

  @override
  String get getStarted => 'শুরু করুন';

  @override
  String get skip => 'এড়িয়ে যান';

  @override
  String get next => 'পরবর্তী';

  @override
  String get back => 'পিছনে';

  @override
  String get cancel => 'বাতিল';

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get delete => 'মুছুন';

  @override
  String get edit => 'সম্পাদনা';

  @override
  String get add => 'যোগ করুন';

  @override
  String get search => 'অনুসন্ধান';

  @override
  String get loading => 'লোড হচ্ছে';

  @override
  String get error => 'কিছু ভুল হয়েছে';

  @override
  String get tryAgain => 'আবার চেষ্টা করুন';

  @override
  String get done => 'সম্পন্ন';

  @override
  String get close => 'বন্ধ করুন';

  @override
  String get signIn => 'সাইন ইন';

  @override
  String get signOut => 'সাইন আউট';

  @override
  String get mobileNumber => 'মোবাইল নম্বর';

  @override
  String get enterOtp => 'OTP লিখুন';

  @override
  String get verifyOtp => 'OTP যাচাই করুন';

  @override
  String get resendOtp => 'OTP পুনরায় পাঠান';

  @override
  String get otpSent => 'আমরা আপনাকে একটি 6-অঙ্কের কোড পাঠিয়েছি';

  @override
  String get home => 'হোম';

  @override
  String get scan => 'স্ক্যান';

  @override
  String get expiry => 'মেয়াদ';

  @override
  String get tasks => 'কাজ';

  @override
  String get profile => 'প্রোফাইল';

  @override
  String get settings => 'সেটিংস';

  @override
  String get language => 'ভাষা';

  @override
  String get scanProduct => 'পণ্য স্ক্যান করুন';

  @override
  String get pointAtBarcode => 'আপনার ক্যামেরা বারকোডে রাখুন';

  @override
  String get scanAgain => 'আবার স্ক্যান করুন';

  @override
  String get productNotFound => 'পণ্য পাওয়া যায়নি';

  @override
  String get expiryTracker => 'মেয়াদ ট্র্যাকার';

  @override
  String get addExpiry => 'মেয়াদ যোগ করুন';

  @override
  String get expiringSoon => 'শীঘ্রই মেয়াদ শেষ হবে';

  @override
  String get expired => 'মেয়াদ শেষ';

  @override
  String get yourTasks => 'আপনার কাজ';

  @override
  String get noTasks => 'কোনো কাজ নেই';

  @override
  String get completeTask => 'কাজ সম্পূর্ণ করুন';

  @override
  String get welcome => 'স্বাগতম';

  @override
  String get welcomeMessage =>
      'স্প্রেডশিট ছাড়াই আপনার স্টক স্ক্যান, ট্র্যাক ও অডিট করুন।';

  @override
  String get referrals => 'রেফারাল';

  @override
  String get shareYourCode => 'আপনার কোড শেয়ার করুন';

  @override
  String get yourReferralCode => 'আপনার রেফারাল কোড';

  @override
  String get invitees => 'আমন্ত্রিত';

  @override
  String get rewardsEarned => 'অর্জিত পুরস্কার';

  @override
  String get redeemCode => 'কোড রিডিম করুন';

  @override
  String get enterReferralCode => 'রেফারাল কোড লিখুন';

  @override
  String get chooseLanguage => 'ভাষা নির্বাচন করুন';

  @override
  String get languageUpdated => 'ভাষা আপডেট হয়েছে';

  @override
  String get errorGeneric => 'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।';

  @override
  String errorRateLimitOtp(int seconds) {
    return 'অনেক বেশি OTP অনুরোধ। $seconds সেকেন্ডে আবার চেষ্টা করুন।';
  }

  @override
  String get errorOtpInvalid => 'OTP ভুল। আবার চেষ্টা করুন।';

  @override
  String get errorOtpExpired => 'OTP-এর মেয়াদ শেষ। নতুন একটি অনুরোধ করুন।';

  @override
  String get errorAuthRequired => 'চালিয়ে যেতে সাইন ইন করুন।';

  @override
  String get errorNotFound => 'পাওয়া যায়নি।';

  @override
  String get ingredientExplainerErrorTitle => 'ব্যাখ্যা লোড করা যায়নি';

  @override
  String get ingredientExplainerHealthConsiderations => 'স্বাস্থ্য বিবেচনা';

  @override
  String healthyAlternativesTitle(String productName) {
    return '$productName এর চেয়ে ভালো বিকল্প';
  }

  @override
  String get healthyAlternativesGenericTitle => 'ভালো বিকল্প';

  @override
  String get healthyAlternativesEmptyTitle => 'এখনও স্বাস্থ্যকর বিকল্প নেই';

  @override
  String get healthyAlternativesEmptyBody =>
      'একই বিভাগে এখনও স্বাস্থ্যকর বিকল্প পাওয়া যায়নি।';

  @override
  String get healthyAlternativesErrorTitle => 'বিকল্প লোড করা যায়নি';

  @override
  String get healthyAlternativesAddToList => 'শপিং তালিকায় যোগ করুন';

  @override
  String get healthyAlternativesView => 'দেখুন';

  @override
  String get healthyAlternativesAddedToList => 'শপিং তালিকায় যোগ করা হয়েছে';

  @override
  String get healthyAlternativesAddFailed => 'শপিং তালিকায় যোগ করা যায়নি';

  @override
  String get savedProductsTitle => 'সংরক্ষিত পণ্য';

  @override
  String get savedProductsEmptyTitle => 'সংরক্ষিত পণ্য';

  @override
  String get savedProductsEmptyBody =>
      'স্ক্যান ফলাফল স্ক্রিন থেকে পণ্য সংরক্ষণ করলে সেগুলো এখানে দেখা যাবে।';

  @override
  String get savedProductsErrorTitle => 'সংরক্ষিত পণ্য লোড করা যায়নি';

  @override
  String savedProductsSavedOn(String date) {
    return '$date-এ সংরক্ষিত';
  }

  @override
  String get digestTitle => 'RADHA-এর সঙ্গে আপনার সপ্তাহ';

  @override
  String digestWeekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String digestSavingsHero(String amount) {
    return '₹$amount সাশ্রয়';
  }

  @override
  String digestScansHero(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি স্ক্যান',
      one: '1টি স্ক্যান',
    );
    return '$_temp0';
  }

  @override
  String get digestHeroEmptyHeadline => 'একটি শান্ত সপ্তাহ';

  @override
  String get digestScans => 'স্ক্যান';

  @override
  String get digestSavedProducts => 'সংরক্ষিত';

  @override
  String get digestExpiringSoon => 'শীঘ্রই মেয়াদ শেষ';

  @override
  String digestRecallAlerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি রিকল অ্যালার্ট',
      one: '1টি রিকল অ্যালার্ট',
    );
    return '$_temp0';
  }

  @override
  String get digestRecallAlertsBody =>
      'এই সপ্তাহে স্ক্যান করা পণ্যগুলির নতুন সুরক্ষা পরামর্শ আছে।';

  @override
  String get digestRecallAlertsCta => 'দেখুন';

  @override
  String get digestTopCategoriesHeader => 'আপনি কী স্ক্যান করছেন';

  @override
  String get digestHighlightsHeader => 'মুখ্য বিষয়';

  @override
  String get digestContinueScanning => 'স্ক্যান চালিয়ে যান';

  @override
  String get digestShare => 'আমার সপ্তাহ শেয়ার করুন';

  @override
  String digestShareTemplate(int scans, String savings) {
    return 'আমি এই সপ্তাহে $scansটি পণ্য স্ক্যান করেছি এবং RADHA দিয়ে ₹$savings সাশ্রয় করেছি। চেষ্টা করুন: https://radha.app';
  }

  @override
  String get digestEmptyTitle => 'এই সপ্তাহে কোনো কার্যকলাপ নেই';

  @override
  String get digestEmptyBody => 'আপনার সাপ্তাহিক গল্প গড়তে স্ক্যান শুরু করুন।';

  @override
  String get digestErrorTitle => 'সাপ্তাহিক সারাংশ লোড করা যায়নি';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get settingsNotifications => 'নোটিফিকেশন';

  @override
  String get settingsPushNotifications => 'পুশ নোটিফিকেশন';

  @override
  String get settingsPushNotificationsHint => 'আপনার ফোনে অ্যালার্ট পান';

  @override
  String get settingsRecallAlerts => 'রিকল অ্যালার্ট';

  @override
  String get settingsRecallAlertsHint =>
      'স্ক্যান করা পণ্য রিকল হলে জানিয়ে দেব';

  @override
  String get settingsWeeklyDigest => 'সাপ্তাহিক সারাংশ';

  @override
  String get settingsWeeklyDigestHint =>
      'রবিবার আপনার স্ক্যান ও সাশ্রয়ের সারাংশ';

  @override
  String get settingsAppearance => 'চেহারা';

  @override
  String get settingsTheme => 'থিম';

  @override
  String get settingsThemeSystem => 'সিস্টেম';

  @override
  String get settingsThemeLight => 'লাইট';

  @override
  String get settingsThemeDark => 'ডার্ক';

  @override
  String get settingsLanguage => 'ভাষা';

  @override
  String get settingsTextSize => 'টেক্সট আকার';

  @override
  String get settingsTextSizeSmall => 'ছোট';

  @override
  String get settingsTextSizeStandard => 'মান';

  @override
  String get settingsTextSizeLarge => 'বড়';

  @override
  String get settingsDataPrivacy => 'ডেটা ও গোপনীয়তা';

  @override
  String get settingsAllergens => 'অ্যালার্জি প্রোফাইল';

  @override
  String get settingsAllergensHint =>
      'যে উপাদানের ব্যাপারে সতর্ক করতে হবে তা বাছুন';

  @override
  String get settingsSignOutAll => 'সব ডিভাইস থেকে সাইন আউট';

  @override
  String get settingsSignOutAllConfirmTitle => 'সর্বত্র সাইন আউট?';

  @override
  String get settingsSignOutAllConfirmBody =>
      'এই অ্যাকাউন্ট ব্যবহার করা প্রতিটি ডিভাইসে আবার সাইন ইন করতে হবে।';

  @override
  String get settingsDeleteAccount => 'অ্যাকাউন্ট মুছুন';

  @override
  String get settingsDeleteAccountTitle => 'অ্যাকাউন্ট মুছুন';

  @override
  String get settingsDeleteAccountBody =>
      'এটি আপনার ডেটা স্থায়ীভাবে মুছে ফেলবে। নিশ্চিত করতে DELETE টাইপ করুন।';

  @override
  String get settingsDeleteAccountConfirm => 'DELETE';

  @override
  String get settingsDeleteAccountUnavailable =>
      'অ্যাকাউন্ট মুছতে সাপোর্টের সাথে যোগাযোগ করুন।';

  @override
  String get settingsDeleteAccountContact => 'সাপোর্টের সাথে যোগাযোগ করুন';

  @override
  String get settingsAbout => 'সম্পর্কে';

  @override
  String get settingsTerms => 'পরিষেবার শর্তাবলি';

  @override
  String get settingsPrivacyPolicy => 'গোপনীয়তা নীতি';

  @override
  String get settingsVersion => 'অ্যাপ সংস্করণ';

  @override
  String settingsVersionValue(String version, String build) {
    return 'সংস্করণ $version ($build)';
  }

  @override
  String get settingsSupport => 'সাপোর্ট';

  @override
  String get settingsSupportHint =>
      'সাহায্য পান, বাগ রিপোর্ট করুন, বা মতামত দিন';

  @override
  String get settingsLinkOpenFailed => 'লিঙ্ক খোলা যায়নি';

  @override
  String conflictBannerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি দ্বন্দ্বে আপনার মনোযোগ দরকার',
      one: '1টি দ্বন্দ্বে আপনার মনোযোগ দরকার',
    );
    return '$_temp0';
  }

  @override
  String get conflictBannerCta => 'সমাধান করুন';

  @override
  String get conflictBannerDismiss => 'বন্ধ করুন';

  @override
  String get conflictResolveTitle => 'সিঙ্ক দ্বন্দ্ব সমাধান করুন';

  @override
  String get conflictResolveSubtitle =>
      'প্রতিটি আইটেমের জন্য কোন সংস্করণ রাখবেন তা বাছাই করুন।';

  @override
  String get conflictUseMine => 'আমার সংস্করণ রাখুন';

  @override
  String get conflictUseServer => 'সার্ভারের সংস্করণ রাখুন';

  @override
  String get conflictResolved => 'দ্বন্দ্ব সমাধান হয়েছে';

  @override
  String get conflictResolvedAll => 'সব দ্বন্দ্ব সমাধান হয়েছে';

  @override
  String conflictAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count বার চেষ্টা করা হয়েছে',
      one: '1 বার চেষ্টা করা হয়েছে',
    );
    return '$_temp0';
  }

  @override
  String get conflictResourceTask => 'কাজ';

  @override
  String get conflictResourceExpiry => 'মেয়াদ রেকর্ড';

  @override
  String get conflictResourceScan => 'স্ক্যান';

  @override
  String get conflictResourceInventory => 'স্টক সমন্বয়';

  @override
  String get conflictResourceGrn => 'GRN এন্ট্রি';

  @override
  String get conflictResourceShoppingList => 'শপিং তালিকা আইটেম';

  @override
  String get conflictResourceGeneric => 'সিঙ্ক পরিবর্তন';

  @override
  String conflictLocalChangeSummary(String summary) {
    return 'আপনার পরিবর্তন: $summary';
  }

  @override
  String get supportTitle => 'সাপোর্ট';

  @override
  String get supportContactUs => 'আমাদের সাথে যোগাযোগ করুন';

  @override
  String get supportEmailUs => 'ইমেইল করুন';

  @override
  String get supportEmailUsHint => 'support@radha.app';

  @override
  String get supportCallUs => 'সাপোর্টে কল করুন';

  @override
  String get supportCallUsHint => 'সোম–শুক্র, সকাল ৯ – সন্ধ্যা ৬ IST';

  @override
  String get supportReportBug => 'বাগ রিপোর্ট করুন';

  @override
  String get supportBugDescription => 'কী হয়েছিল?';

  @override
  String get supportBugDescriptionHint =>
      'যখন সমস্যা হয়েছিল তখন আপনি কী করছিলেন বর্ণনা করুন।';

  @override
  String get supportAttachScreenshot => 'স্ক্রিনশট সংযুক্ত করুন';

  @override
  String get supportScreenshotAttached => 'স্ক্রিনশট সংযুক্ত হয়েছে';

  @override
  String get supportRemoveScreenshot => 'সরান';

  @override
  String get supportSubmit => 'রিপোর্ট পাঠান';

  @override
  String get supportSubmitted => 'ধন্যবাদ — আপনার রিপোর্ট পেয়েছি।';

  @override
  String get supportSubmitFailed =>
      'পাঠানো যায়নি। দয়া করে আমাদের ইমেইল করুন।';

  @override
  String get supportBugDescriptionRequired =>
      'অনুগ্রহ করে কী হয়েছিল বর্ণনা করুন।';

  @override
  String get supportFaq => 'সাধারণ জিজ্ঞাসা';

  @override
  String get supportFaqQ1 => 'বারকোড কীভাবে স্ক্যান করব?';

  @override
  String get supportFaqA1 =>
      'স্ক্যান ট্যাব খুলে ক্যামেরা বারকোডে রাখুন এবং স্থির রাখুন। পরিষ্কার কোড পড়ার সাথে সাথে পণ্যটি দেখা যাবে।';

  @override
  String get supportFaqQ2 => 'পণ্যটি ডেটাবেসে না থাকলে কী?';

  @override
  String get supportFaqA2 =>
      'পাওয়া-যায়নি স্ক্রিনে \"পণ্য যোগ করুন\" ট্যাপ করুন। এটি আপনার স্টোরের সাথে যুক্ত নতুন এন্ট্রি তৈরি করবে।';

  @override
  String get supportFaqQ3 => 'আমি আমার সাবস্ক্রিপশন কীভাবে বাতিল করব?';

  @override
  String get supportFaqA3 =>
      'প্রোফাইল → সাবস্ক্রিপশনে যান। যেকোনো সময় বাতিল করতে পারেন; পরবর্তী বিলিং চক্রের পরে চার্জ নেই।';

  @override
  String get supportFaqQ4 => 'আমি কেন রিকল অ্যালার্ট দেখছি?';

  @override
  String get supportFaqA4 =>
      'প্রতিটি স্ক্যানকে FSSAI রিকল ফিডের সাথে মিলিয়ে দেখি। আপনি যে ব্যাচ বিক্রি করেছেন তা তালিকায় থাকলে আপনাকে জানিয়ে দিই।';

  @override
  String get supportFaqQ5 =>
      'আমার অ্যালার্জি প্রোফাইল পরিবারের সাথে কীভাবে শেয়ার করব?';

  @override
  String get supportFaqA5 =>
      'অ্যালার্জি প্রোফাইল এখন প্রতি অ্যাকাউন্টে আলাদা। একই পরিবারের অ্যাকাউন্টে সাইন ইন করুন বা প্রতিটি ফোনে একই অ্যালার্জি বেছে নিন।';

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
  String get expiryTabNear => 'শীঘ্রই মেয়াদ';

  @override
  String get expiryTabSafe => 'নিরাপদ';

  @override
  String get expiryCalendarTooltip => 'ক্যালেন্ডার ভিউ';

  @override
  String get expiryEmptyExpiredTitle => 'কিছুই মেয়াদোত্তীর্ণ নয়';

  @override
  String get expiryEmptyNearTitle => 'সব ঠিক আছে';

  @override
  String get expiryEmptyDefaultTitle => 'এখনও কোনো রেকর্ড নেই';

  @override
  String get expiryEmptyBody => 'এই বিভাগে কোনো রেকর্ড নেই।';

  @override
  String expiryProductShort(String id) {
    return 'পণ্য $id';
  }

  @override
  String expiryBatch(String batch) {
    return 'ব্যাচ $batch';
  }

  @override
  String expiryQty(String qty) {
    return 'পরিমাণ $qty';
  }

  @override
  String expiryExp(String date) {
    return 'মেয়াদ $date';
  }

  @override
  String get expiryPillToday => 'আজ';

  @override
  String get expiryPillTomorrow => 'আগামীকাল';

  @override
  String expiryPillDays(int days) {
    return '${days}d';
  }

  @override
  String get expiryPillSoon => 'শীঘ্রই';

  @override
  String get expiryLoadError => 'মেয়াদের রেকর্ড লোড করা যায়নি।';

  @override
  String get expiryCouldNotLoadSemantic => 'লোড করা যায়নি';

  @override
  String get inventoryTitle => 'ইনভেন্টরি';

  @override
  String get inventorySearchTooltip => 'ইনভেন্টরি খুঁজুন';

  @override
  String get inventorySearchHint => 'পণ্য বা EAN দিয়ে খুঁজুন...';

  @override
  String get inventoryStockMovement => 'স্টক মুভমেন্ট';

  @override
  String get inventoryLowStockAlerts => 'কম স্টক সতর্কতা';

  @override
  String get inventoryLoadError => 'ইনভেন্টরি লোড করা যায়নি';

  @override
  String get inventoryEmpty => 'কোনো ইনভেন্টরি আইটেম পাওয়া যায়নি';

  @override
  String inventoryNoMatches(String query) {
    return '\"$query\" এর জন্য কোনো মিল নেই';
  }

  @override
  String inventoryProductShort(String id) {
    return 'পণ্য $id';
  }

  @override
  String get inventoryBelowThreshold => 'সীমার নিচে';

  @override
  String get inventoryInStock => 'স্টকে আছে';

  @override
  String get inventoryUnitsLabel => 'ইউনিট';

  @override
  String get inventoryTotalQuantity => 'মোট পরিমাণ';

  @override
  String get inventoryLowStockThreshold => 'কম-স্টক সীমা';

  @override
  String inventoryQtyUnits(int count) {
    return '$count ইউনিট';
  }

  @override
  String get inventoryBatchLedgerHint =>
      'সম্পূর্ণ ব্যাচ লেজার দেখতে \"স্টক মুভমেন্ট\" ট্যাপ করুন।';

  @override
  String get inventoryLowStockBadge => 'কম স্টক';

  @override
  String get tasksTitle => 'কাজ';

  @override
  String get tasksTabMine => 'আমার কাজ';

  @override
  String get tasksTabAll => 'সব';

  @override
  String get tasksNewTask => 'নতুন কাজ';

  @override
  String get tasksEmptyTitle => 'এখানে কোনো কাজ নেই';

  @override
  String get tasksEmptyBody => 'এই ভিউতে বরাদ্দ করা কাজগুলি এখানে দেখা যাবে।';

  @override
  String get tasksLoadError => 'কাজ লোড করা যায়নি';

  @override
  String get taskEvidence => 'প্রমাণ';

  @override
  String get priorityHigh => 'উচ্চ';

  @override
  String get priorityMedium => 'মাঝারি';

  @override
  String get priorityLow => 'নিম্ন';

  @override
  String get priorityUrgent => 'জরুরি';

  @override
  String get taskStatusOpen => 'খোলা';

  @override
  String get taskStatusPending => 'মুলতুবি';

  @override
  String get taskStatusInProgress => 'চলমান';

  @override
  String get taskStatusCompleted => 'সম্পন্ন';

  @override
  String get taskStatusCancelled => 'বাতিল';

  @override
  String get scanTitle => 'একটি পণ্য স্ক্যান করুন';

  @override
  String get scanAlignHint => 'ফ্রেমের মধ্যে বারকোড সারিবদ্ধ করুন';

  @override
  String get scanBatchHint =>
      'ব্যাচ মোড — স্ক্যান করতে থাকুন, আইটেম স্বয়ংক্রিয়ভাবে যোগ হবে';

  @override
  String scanBatchAdded(String code, int count) {
    return '$code যোগ করা হয়েছে · $count স্ক্যান করা হয়েছে';
  }

  @override
  String scanBatchDone(int count) {
    return 'সম্পন্ন · $count';
  }

  @override
  String get scanLabelAction => 'লেবেল স্ক্যান';

  @override
  String get scanGalleryAction => 'গ্যালারি';

  @override
  String get scanEnterManually => 'ম্যানুয়ালি লিখুন';

  @override
  String get scanBulkAudit => 'বাল্ক অডিট';

  @override
  String get scanHistoryAction => 'ইতিহাস';

  @override
  String get scanFlash => 'ফ্ল্যাশ';

  @override
  String get scanTroubleTitle => 'স্ক্যান করতে সমস্যা?';

  @override
  String get scanTroubleBody =>
      'কম আলো বা ক্ষতিগ্রস্ত বারকোড? ফ্ল্যাশ চালু করুন, অথবা পরিবর্তে লেবেল পড়ুন।';

  @override
  String get scanGalleryNoBarcode =>
      'কোনো বারকোড পাওয়া যায়নি। টিপ: উপাদান পড়তে \'লেবেল স্ক্যান\' ব্যবহার করুন।';

  @override
  String get scanInvalidEan => 'একটি বৈধ EAN-8, EAN-13, বা UPC-A কোড লিখুন';

  @override
  String get scanWebTitle => 'স্ক্যান';

  @override
  String get scanWebUnavailable =>
      'ওয়েবে ক্যামেরা স্ক্যানিং উপলব্ধ নয়।\nবারকোড ম্যানুয়ালি লিখুন:';

  @override
  String get scanEanFieldLabel => 'EAN / UPC কোড';

  @override
  String get scanEanHintExample => 'যেমন 5901234123457';

  @override
  String get scanLookUp => 'খুঁজুন';

  @override
  String get scanEnterBarcode => 'বারকোড লিখুন';

  @override
  String get scanHistoryTitle => 'স্ক্যান ইতিহাস';

  @override
  String get scanNoHistory => 'এই সেশনে এখনও কোনো স্ক্যান নেই।';

  @override
  String get homeGreetingMorning => 'সুপ্রভাত';

  @override
  String get homeGreetingAfternoon => 'শুভ অপরাহ্ন';

  @override
  String get homeGreetingEvening => 'শুভ সন্ধ্যা';

  @override
  String get homeGreetingFallbackName => 'বন্ধু';

  @override
  String get homeTrialEnded =>
      'ফ্রি ট্রায়াল শেষ — অ্যাক্সেস ধরে রাখতে আপগ্রেড করুন';

  @override
  String homeTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days দিন',
      one: '1 দিন',
    );
    return 'ফ্রি ট্রায়াল · $_temp0 বাকি';
  }

  @override
  String get homeUpgradeArrow => 'আপগ্রেড →';

  @override
  String get homeKpiSaved => 'সংরক্ষিত';

  @override
  String get homeKpiNearExpiry => 'শীঘ্রই মেয়াদ';

  @override
  String get homeKpiRecallAlerts => 'রিকল সতর্কতা';

  @override
  String get homeKpiOpenTasks => 'খোলা কাজ';

  @override
  String get homeKpiLowStock => 'কম স্টক';

  @override
  String get homeEyebrowFoodSafety => 'খাদ্য সুরক্ষা সতর্কতা';

  @override
  String get homeEyebrowToday => 'আজকের কাজ';

  @override
  String get homeEyebrowHealthScan => 'আপনার হেলথ স্ক্যান';

  @override
  String get homeEyebrowScanToLearn => 'স্ক্যান করে জানুন';

  @override
  String get homeEyebrowAllClear => 'সব ঠিক আছে';

  @override
  String homeStoryRecall(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি রিকল করা পণ্য — দেখুন আপনার বাড়িতে কী আছে',
      one: '1টি রিকল করা পণ্য — দেখুন আপনার বাড়িতে কী আছে',
    );
    return '$_temp0';
  }

  @override
  String homeStoryNearExpiryConsumer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$countটি সংরক্ষিত আইটেম এই সপ্তাহে মেয়াদ শেষ হচ্ছে — ব্যবহার করুন',
      one: '1টি সংরক্ষিত আইটেম এই সপ্তাহে মেয়াদ শেষ হচ্ছে — ব্যবহার করুন',
    );
    return '$_temp0';
  }

  @override
  String get homeStoryKnowWhatYouEat => 'আপনি কী খান তা জানুন';

  @override
  String get homeStoryScanInside =>
      'যেকোনো খাদ্য বারকোডে ক্যামেরা তাক করুন — ভেতরে কী আছে দেখুন';

  @override
  String homeStoryNearExpiryBusiness(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি আইটেম শীঘ্রই মেয়াদ — তাক পরিষ্কার করুন',
      one: '1টি আইটেম শীঘ্রই মেয়াদ — তাক পরিষ্কার করুন',
    );
    return '$_temp0';
  }

  @override
  String homeStoryOpenTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি কাজে আজ আপনাকে দরকার',
      one: '1টি কাজে আজ আপনাকে দরকার',
    );
    return '$_temp0';
  }

  @override
  String homeStoryLowStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি আইটেমের স্টক কমে যাচ্ছে',
      one: '1টি আইটেমের স্টক কমে যাচ্ছে',
    );
    return '$_temp0';
  }

  @override
  String get homeStoreToday => 'এই যে আজ আপনার দোকান';

  @override
  String get homeStoreAllGood => 'শাবাশ! আপনার দোকান আজ দারুণ অবস্থায় আছে';

  @override
  String get homeCtaViewRecallAlerts => 'রিকল সতর্কতা দেখুন';

  @override
  String get homeCtaCheckExpiry => 'মেয়াদ দেখুন';

  @override
  String get homeCtaOpenExpiry => 'মেয়াদ খুলুন';

  @override
  String get homeCtaViewTasks => 'কাজ দেখুন';

  @override
  String get homeCtaCheckInventory => 'ইনভেন্টরি দেখুন';

  @override
  String get homeCtaOpenTasks => 'কাজ খুলুন';

  @override
  String get homeCtaRunAudit => 'একটি দ্রুত অডিট চালান';

  @override
  String get homeQuickActions => 'দ্রুত ক্রিয়া';

  @override
  String get homeQuickScan => 'স্ক্যান';

  @override
  String get homeQuickShopping => 'শপিং';

  @override
  String get homeQuickAddExpiry => 'মেয়াদ যোগ করুন';

  @override
  String get homeQuickNewTask => 'নতুন কাজ';

  @override
  String get homeRecentTasks => 'সাম্প্রতিক কাজ';

  @override
  String get homeSeeAll => 'সব দেখুন';

  @override
  String get homeNoOpenTasks => 'কোনো খোলা কাজ নেই — একটি তৈরি করুন';

  @override
  String homeTaskAssignedTo(String name) {
    return '$name কে বরাদ্দ করা হয়েছে';
  }

  @override
  String get homeTaskOverdue => 'বকেয়া';

  @override
  String get homeTaskDueToday => 'আজ দেয়';

  @override
  String get homeTaskDueTomorrow => 'আগামীকাল দেয়';

  @override
  String homeTaskDueInDays(int days) {
    return '$days দিনে দেয়';
  }

  @override
  String homeTaskDueOn(String date) {
    return 'দেয় $date';
  }

  @override
  String get homeHowHelps => 'RADHA কীভাবে আপনাকে সাহায্য করে';

  @override
  String get homeScanBarcodeTitle => 'যেকোনো খাদ্য বারকোড স্ক্যান করুন';

  @override
  String get homeScanBarcodeBody =>
      'হেলথ রেটিং, উপাদান, এবং কী লক্ষ্য রাখতে হবে — সব দেখুন।';

  @override
  String get homeRecallTitle => 'সুরক্ষা রিকল সতর্কতা';

  @override
  String get homeRecallBody => 'রিকল করা খাদ্য পণ্য সম্পর্কে অবগত থাকুন।';

  @override
  String get homePromoKnowFoodEyebrow => 'আপনার খাবার জানুন';

  @override
  String get homePromoKnowFoodHeadline =>
      'লেবেল স্ক্যান করুন — সত্যিই ভেতরে কী আছে দেখুন';

  @override
  String get homePromoKnowFoodCta => 'স্ক্যান করে জানুন';

  @override
  String get homePromoExpiryEyebrow => 'কোনো তারিখ মিস করবেন না';

  @override
  String get homePromoExpiryHeadline =>
      'প্রতিটি মেয়াদ হাতছাড়া হওয়ার আগে ধরুন';

  @override
  String get homePromoExpiryCta => 'মেয়াদ ট্র্যাক করুন';

  @override
  String get homePromoFestiveEyebrow => 'উৎসবের বাছাই';

  @override
  String get homePromoFestiveHeadline =>
      'মরশুমের কেনাকাটা করুন, স্বাস্থ্যকর উপায়ে';

  @override
  String get homePromoFestiveCta => 'পণ্য ব্রাউজ করুন';

  @override
  String get homePromoBazaarEyebrow => 'আজকের বাজার';

  @override
  String get homePromoBazaarHeadline => 'মিনিটেই আপনার তাক অডিট করুন';

  @override
  String get homePromoBazaarCta => 'অডিট শুরু করুন';

  @override
  String get homeShopByCategory => 'বিভাগ অনুযায়ী কিনুন';

  @override
  String get homeShopByCategorySubtitle =>
      'স্ক্যান বা ব্রাউজ করতে একটি আইলে ট্যাপ করুন';

  @override
  String get onboardingWelcomeValue =>
      'স্ক্যান করুন, ট্র্যাক করুন, আপনার স্টক অডিট করুন — স্প্রেডশিট ছাড়াই।';

  @override
  String get onboardingCapabilitiesTitle =>
      'দোকানের মেঝের জন্য তৈরি,\nব্যাক অফিসের জন্য নয়।';

  @override
  String get onboardingCapScanTitle => 'এক ট্যাপে পণ্য স্ক্যান করুন';

  @override
  String get onboardingCapScanBody =>
      'হেলথ এবং অনুমোদন পূর্ব-যাচাইকৃত EAN লুকআপ।';

  @override
  String get onboardingCapExpiryTitle => 'ক্ষতির আগে মেয়াদ ধরুন';

  @override
  String get onboardingCapExpiryBody =>
      'OCR-সহায়ক তারিখ এবং প্রতি-বিভাগ সীমা।';

  @override
  String get onboardingCapAuditTitle => 'এমন অডিট চালান যা দল শেষ করতে পারে';

  @override
  String get onboardingCapAuditBody => 'কাজ, প্রমাণ এবং বাল্ক স্ক্যান সেশন।';

  @override
  String get onboardingSegmentTitle => 'আপনি এখানে কে হিসেবে আছেন?';

  @override
  String get onboardingSegmentSubtitle =>
      'সবচেয়ে কাছের বিকল্পটি বেছে নিন। আপনি পরে সেটিংসে পরিবর্তন করতে পারবেন।';

  @override
  String get segmentPersonalTitle => 'ব্যক্তিগত';

  @override
  String get segmentPersonalBody => 'শুধু নিজের জন্য কেনাকাটা';

  @override
  String get segmentParentTitle => 'অভিভাবক';

  @override
  String get segmentParentBody => 'আমার পরিবার / সন্তানদের জন্য কেনাকাটা';

  @override
  String get segmentBusinessTitle => 'ব্যবসার মালিক';

  @override
  String get segmentBusinessBody => 'আমি একটি ছোট খুচরা দোকান চালাই';

  @override
  String get segmentPharmacyTitle => 'ফার্মেসি';

  @override
  String get segmentPharmacyBody => 'আমি একটি ফার্মেসি / কেমিস্ট চালাই';

  @override
  String get segmentInstitutionTitle => 'প্রতিষ্ঠান';

  @override
  String get segmentInstitutionBody => 'স্কুল / হোস্টেল / ক্যান্টিন';

  @override
  String get segmentAuditorTitle => 'অডিটর (আমন্ত্রিত)';

  @override
  String get segmentAuditorBody => 'আমার কাছে একটি আমন্ত্রণ কোড আছে';

  @override
  String get allergenTitle => 'অ্যালার্জেন';

  @override
  String get allergenLoadError => 'আপনার অ্যালার্জেন প্রোফাইল লোড করা যায়নি।';

  @override
  String get allergenHeading => 'আপনার অ্যালার্জেন';

  @override
  String get allergenIntro =>
      'আপনার যেগুলিতে প্রতিক্রিয়া হয় সেই অ্যালার্জেনগুলিতে ট্যাপ করুন। স্ক্যান করা পণ্যে সেগুলি থাকলে আমরা আপনাকে সতর্ক করব।';

  @override
  String allergenTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি অ্যালার্জেন ট্র্যাক করা হচ্ছে',
      one: '1টি অ্যালার্জেন ট্র্যাক করা হচ্ছে',
    );
    return '$_temp0';
  }

  @override
  String get allergenNoneTracked => 'এখনও কোনো অ্যালার্জেন ট্র্যাক করা হয়নি';

  @override
  String get allergenSavedCleared => 'অ্যালার্জেন প্রোফাইল সাফ করা হয়েছে।';

  @override
  String get allergenSaved => 'অ্যালার্জেন প্রোফাইল সংরক্ষিত হয়েছে।';

  @override
  String get allergenSaveError => 'আপনার অ্যালার্জেন সংরক্ষণ করা যায়নি।';

  @override
  String get allergenPeanut => 'চিনাবাদাম';

  @override
  String get allergenTreeNut => 'গাছের বাদাম';

  @override
  String get allergenDairy => 'দুগ্ধজাত';

  @override
  String get allergenEggs => 'ডিম';

  @override
  String get allergenSoy => 'সয়া';

  @override
  String get allergenWheat => 'গম';

  @override
  String get allergenFish => 'মাছ';

  @override
  String get allergenShellfish => 'শেলফিশ';

  @override
  String get allergenSesame => 'তিল';

  @override
  String get allergenGluten => 'গ্লুটেন';

  @override
  String get allergenMustard => 'সরিষা';

  @override
  String get allergenCelery => 'সেলারি';

  @override
  String get allergenLupin => 'লুপিন';

  @override
  String get allergenMolluscs => 'মলাস্ক';

  @override
  String get allergenSulphites => 'সালফাইট';
}
