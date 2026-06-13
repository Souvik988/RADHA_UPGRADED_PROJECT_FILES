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
}
