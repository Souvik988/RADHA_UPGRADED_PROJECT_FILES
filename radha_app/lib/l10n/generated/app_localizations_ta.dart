// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'RADHA';

  @override
  String get tagline =>
      'தரவு, ஆரோக்கியம் மற்றும் தணிக்கைக்கான சில்லறை உதவியாளர்.';

  @override
  String get continueLabel => 'தொடரவும்';

  @override
  String get getStarted => 'தொடங்கவும்';

  @override
  String get skip => 'தவிர்';

  @override
  String get next => 'அடுத்து';

  @override
  String get back => 'பின்';

  @override
  String get cancel => 'ரத்து';

  @override
  String get save => 'சேமி';

  @override
  String get delete => 'நீக்கு';

  @override
  String get edit => 'திருத்து';

  @override
  String get add => 'சேர்';

  @override
  String get search => 'தேடு';

  @override
  String get loading => 'ஏற்றுகிறது';

  @override
  String get error => 'ஏதோ தவறு நடந்தது';

  @override
  String get tryAgain => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get done => 'முடிந்தது';

  @override
  String get close => 'மூடு';

  @override
  String get signIn => 'உள்நுழை';

  @override
  String get signOut => 'வெளியேறு';

  @override
  String get mobileNumber => 'மொபைல் எண்';

  @override
  String get enterOtp => 'OTP உள்ளிடவும்';

  @override
  String get verifyOtp => 'OTP சரிபார்க்கவும்';

  @override
  String get resendOtp => 'OTP மீண்டும் அனுப்பு';

  @override
  String get otpSent => 'உங்களுக்கு 6 இலக்க குறியீடு அனுப்பப்பட்டது';

  @override
  String get home => 'முகப்பு';

  @override
  String get scan => 'ஸ்கேன்';

  @override
  String get expiry => 'காலாவதி';

  @override
  String get tasks => 'பணிகள்';

  @override
  String get profile => 'சுயவிவரம்';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get language => 'மொழி';

  @override
  String get scanProduct => 'பொருளை ஸ்கேன் செய்';

  @override
  String get pointAtBarcode => 'பார்கோடில் கேமராவை வையுங்கள்';

  @override
  String get scanAgain => 'மீண்டும் ஸ்கேன் செய்';

  @override
  String get productNotFound => 'பொருள் கிடைக்கவில்லை';

  @override
  String get expiryTracker => 'காலாவதி கண்காணிப்பு';

  @override
  String get addExpiry => 'காலாவதி சேர்';

  @override
  String get expiringSoon => 'விரைவில் காலாவதியாகும்';

  @override
  String get expired => 'காலாவதியானது';

  @override
  String get yourTasks => 'உங்கள் பணிகள்';

  @override
  String get noTasks => 'பணிகள் இல்லை';

  @override
  String get completeTask => 'பணியை முடிக்கவும்';

  @override
  String get welcome => 'வரவேற்கிறோம்';

  @override
  String get welcomeMessage =>
      'விரிதாள்கள் இல்லாமல் உங்கள் சரக்கை ஸ்கேன், கண்காணிக்க, தணிக்கை செய்யுங்கள்.';

  @override
  String get referrals => 'பரிந்துரைகள்';

  @override
  String get shareYourCode => 'உங்கள் குறியீட்டைப் பகிரவும்';

  @override
  String get yourReferralCode => 'உங்கள் பரிந்துரை குறியீடு';

  @override
  String get invitees => 'அழைக்கப்பட்டவர்கள்';

  @override
  String get rewardsEarned => 'சம்பாதித்த வெகுமதிகள்';

  @override
  String get redeemCode => 'குறியீட்டை மீட்க';

  @override
  String get enterReferralCode => 'பரிந்துரை குறியீட்டை உள்ளிடவும்';

  @override
  String get chooseLanguage => 'மொழியைத் தேர்ந்தெடு';

  @override
  String get languageUpdated => 'மொழி புதுப்பிக்கப்பட்டது';

  @override
  String get errorGeneric => 'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String errorRateLimitOtp(int seconds) {
    return 'அதிக OTP கோரிக்கைகள். $seconds வினாடிகளில் மீண்டும் முயற்சிக்கவும்.';
  }

  @override
  String get errorOtpInvalid => 'OTP தவறானது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get errorOtpExpired => 'OTP காலாவதியானது. புதிய OTP கோரவும்.';

  @override
  String get errorAuthRequired => 'தொடர உள்நுழையவும்.';

  @override
  String get errorNotFound => 'கிடைக்கவில்லை.';

  @override
  String get ingredientExplainerErrorTitle => 'விளக்கத்தை ஏற்ற முடியவில்லை';

  @override
  String get ingredientExplainerHealthConsiderations => 'ஆரோக்கிய கருத்துகள்';

  @override
  String healthyAlternativesTitle(String productName) {
    return '$productName ஐ விட சிறந்த தேர்வுகள்';
  }

  @override
  String get healthyAlternativesGenericTitle => 'சிறந்த தேர்வுகள்';

  @override
  String get healthyAlternativesEmptyTitle =>
      'ஆரோக்கியமான மாற்றுகள் இன்னும் இல்லை';

  @override
  String get healthyAlternativesEmptyBody =>
      'இதே வகையில் இன்னும் ஆரோக்கியமான மாற்றுகள் கிடைக்கவில்லை.';

  @override
  String get healthyAlternativesErrorTitle => 'மாற்றுகளை ஏற்ற முடியவில்லை';

  @override
  String get healthyAlternativesAddToList => 'ஷாப்பிங் பட்டியலில் சேர்';

  @override
  String get healthyAlternativesView => 'காண்';

  @override
  String get healthyAlternativesAddedToList =>
      'ஷாப்பிங் பட்டியலில் சேர்க்கப்பட்டது';

  @override
  String get healthyAlternativesAddFailed =>
      'ஷாப்பிங் பட்டியலில் சேர்க்க முடியவில்லை';

  @override
  String get savedProductsTitle => 'சேமித்த பொருட்கள்';

  @override
  String get savedProductsEmptyTitle => 'சேமித்த பொருட்கள்';

  @override
  String get savedProductsEmptyBody =>
      'ஸ்கேன் முடிவு திரையில் இருந்து பொருட்களை சேமித்தால் அவை இங்கு காண்பிக்கப்படும்.';

  @override
  String get savedProductsErrorTitle => 'சேமித்த பொருட்களை ஏற்ற முடியவில்லை';

  @override
  String savedProductsSavedOn(String date) {
    return '$date அன்று சேமிக்கப்பட்டது';
  }

  @override
  String get digestTitle => 'RADHA-வுடன் உங்கள் வாரம்';

  @override
  String digestWeekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String digestSavingsHero(String amount) {
    return '₹$amount சேமிப்பு';
  }

  @override
  String digestScansHero(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ஸ்கேன்கள்',
      one: '1 ஸ்கேன்',
    );
    return '$_temp0';
  }

  @override
  String get digestHeroEmptyHeadline => 'அமைதியான வாரம்';

  @override
  String get digestScans => 'ஸ்கேன்கள்';

  @override
  String get digestSavedProducts => 'சேமிக்கப்பட்டவை';

  @override
  String get digestExpiringSoon => 'விரைவில் காலாவதி';

  @override
  String digestRecallAlerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ரிகால் எச்சரிக்கைகள்',
      one: '1 ரிகால் எச்சரிக்கை',
    );
    return '$_temp0';
  }

  @override
  String get digestRecallAlertsBody =>
      'இந்த வாரம் நீங்கள் ஸ்கேன் செய்த தயாரிப்புகளுக்கு புதிய பாதுகாப்பு அறிவிப்புகள் உள்ளன.';

  @override
  String get digestRecallAlertsCta => 'பார்க்க';

  @override
  String get digestTopCategoriesHeader => 'நீங்கள் ஸ்கேன் செய்வது';

  @override
  String get digestHighlightsHeader => 'முக்கியாம்சங்கள்';

  @override
  String get digestContinueScanning => 'தொடர்ந்து ஸ்கேன் செய்';

  @override
  String get digestShare => 'என் வாரத்தைப் பகிர்';

  @override
  String digestShareTemplate(int scans, String savings) {
    return 'இந்த வாரம் நான் $scans தயாரிப்புகளை ஸ்கேன் செய்து RADHA மூலம் ₹$savings சேமித்தேன். முயற்சிக்கவும்: https://radha.app';
  }

  @override
  String get digestEmptyTitle => 'இந்த வாரம் செயல்பாடு இல்லை';

  @override
  String get digestEmptyBody =>
      'உங்கள் வார கதையை உருவாக்க ஸ்கேன் செய்யத் தொடங்குங்கள்.';

  @override
  String get digestErrorTitle => 'வாராந்திர சுருக்கத்தை ஏற்ற முடியவில்லை';

  @override
  String get settingsTitle => 'அமைப்புகள்';

  @override
  String get settingsNotifications => 'அறிவிப்புகள்';

  @override
  String get settingsPushNotifications => 'புஷ் அறிவிப்புகள்';

  @override
  String get settingsPushNotificationsHint =>
      'உங்கள் ஃபோனில் எச்சரிக்கைகள் பெறுங்கள்';

  @override
  String get settingsRecallAlerts => 'ரிகால் எச்சரிக்கைகள்';

  @override
  String get settingsRecallAlertsHint =>
      'ஸ்கேன் செய்த தயாரிப்பு திரும்பப் பெறப்படும்போது அறியுங்கள்';

  @override
  String get settingsWeeklyDigest => 'வாராந்திர சுருக்கம்';

  @override
  String get settingsWeeklyDigestHint => 'ஞாயிறு உங்கள் ஸ்கேன்களின் சுருக்கம்';

  @override
  String get settingsAppearance => 'தோற்றம்';

  @override
  String get settingsTheme => 'தீம்';

  @override
  String get settingsThemeSystem => 'சிஸ்டம்';

  @override
  String get settingsThemeLight => 'ஒளி';

  @override
  String get settingsThemeDark => 'இருள்';

  @override
  String get settingsLanguage => 'மொழி';

  @override
  String get settingsTextSize => 'உரை அளவு';

  @override
  String get settingsTextSizeSmall => 'சிறிய';

  @override
  String get settingsTextSizeStandard => 'வழக்கமான';

  @override
  String get settingsTextSizeLarge => 'பெரிய';

  @override
  String get settingsDataPrivacy => 'தரவு மற்றும் தனியுரிமை';

  @override
  String get settingsAllergens => 'ஒவ்வாமை சுயவிவரம்';

  @override
  String get settingsAllergensHint =>
      'எச்சரிக்க வேண்டிய பொருட்களைத் தேர்ந்தெடுக்கவும்';

  @override
  String get settingsSignOutAll => 'அனைத்து சாதனங்களிலிருந்தும் வெளியேறு';

  @override
  String get settingsSignOutAllConfirmTitle => 'எல்லா இடத்திலும் வெளியேற?';

  @override
  String get settingsSignOutAllConfirmBody =>
      'இந்தக் கணக்கைப் பயன்படுத்தும் ஒவ்வொரு சாதனத்திலும் மீண்டும் உள்நுழைய வேண்டும்.';

  @override
  String get settingsDeleteAccount => 'கணக்கை நீக்கு';

  @override
  String get settingsDeleteAccountTitle => 'கணக்கை நீக்கு';

  @override
  String get settingsDeleteAccountBody =>
      'இது உங்கள் தரவை நிரந்தரமாக நீக்கும். உறுதிப்படுத்த DELETE எனத் தட்டச்சிடவும்.';

  @override
  String get settingsDeleteAccountConfirm => 'DELETE';

  @override
  String get settingsDeleteAccountUnavailable =>
      'உங்கள் கணக்கை நீக்க ஆதரவைத் தொடர்புகொள்ளவும்.';

  @override
  String get settingsDeleteAccountContact => 'ஆதரவைத் தொடர்புகொள்ளவும்';

  @override
  String get settingsAbout => 'பற்றி';

  @override
  String get settingsTerms => 'சேவை விதிமுறைகள்';

  @override
  String get settingsPrivacyPolicy => 'தனியுரிமைக் கொள்கை';

  @override
  String get settingsVersion => 'ஆப் பதிப்பு';

  @override
  String settingsVersionValue(String version, String build) {
    return 'பதிப்பு $version ($build)';
  }

  @override
  String get settingsSupport => 'ஆதரவு';

  @override
  String get settingsSupportHint =>
      'உதவி பெறுங்கள், பிழையைப் புகாரளிக்கவும், கருத்துப் பகிரவும்';

  @override
  String get settingsLinkOpenFailed => 'இணைப்பைத் திறக்க முடியவில்லை';

  @override
  String conflictBannerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count முரண்பாடுகள் கவனம் தேவை',
      one: '1 முரண்பாடு கவனம் தேவை',
    );
    return '$_temp0';
  }

  @override
  String get conflictBannerCta => 'தீர்க்க';

  @override
  String get conflictBannerDismiss => 'மூடு';

  @override
  String get conflictResolveTitle => 'ஒத்திசைவு முரண்பாடுகளைத் தீர்க்கவும்';

  @override
  String get conflictResolveSubtitle =>
      'ஒவ்வொரு உருப்படிக்கும் எந்தப் பதிப்பை வைத்திருக்க வேண்டும் எனத் தேர்வு செய்யவும்.';

  @override
  String get conflictUseMine => 'என் பதிப்பைப் பயன்படுத்து';

  @override
  String get conflictUseServer => 'சர்வர் பதிப்பைப் பயன்படுத்து';

  @override
  String get conflictResolved => 'முரண்பாடு தீர்ந்தது';

  @override
  String get conflictResolvedAll => 'அனைத்து முரண்பாடுகளும் தீர்க்கப்பட்டன';

  @override
  String conflictAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count முறை முயற்சித்தது',
      one: '1 முறை முயற்சித்தது',
    );
    return '$_temp0';
  }

  @override
  String get conflictResourceTask => 'பணி';

  @override
  String get conflictResourceExpiry => 'காலாவதி பதிவு';

  @override
  String get conflictResourceScan => 'ஸ்கேன்';

  @override
  String get conflictResourceInventory => 'சரக்கு சரிசெய்தல்';

  @override
  String get conflictResourceGrn => 'GRN உள்ளீடு';

  @override
  String get conflictResourceShoppingList => 'ஷாப்பிங் பட்டியல் உருப்படி';

  @override
  String get conflictResourceGeneric => 'ஒத்திசைவு மாற்றம்';

  @override
  String conflictLocalChangeSummary(String summary) {
    return 'உங்கள் மாற்றம்: $summary';
  }

  @override
  String get supportTitle => 'ஆதரவு';

  @override
  String get supportContactUs => 'எங்களைத் தொடர்புகொள்ளுங்கள்';

  @override
  String get supportEmailUs => 'மின்னஞ்சல் அனுப்பு';

  @override
  String get supportEmailUsHint => 'support@radha.app';

  @override
  String get supportCallUs => 'ஆதரவை அழைக்கவும்';

  @override
  String get supportCallUsHint => 'திங்கள்–வெள்ளி, காலை 9 – மாலை 6 IST';

  @override
  String get supportReportBug => 'பிழையைப் புகாரளிக்கவும்';

  @override
  String get supportBugDescription => 'என்ன நடந்தது?';

  @override
  String get supportBugDescriptionHint =>
      'பிழை நிகழ்ந்தபோது நீங்கள் என்ன செய்து கொண்டிருந்தீர்கள் என விளக்கவும்.';

  @override
  String get supportAttachScreenshot => 'ஸ்கிரீன்ஷாட்டை இணைக்கவும்';

  @override
  String get supportScreenshotAttached => 'ஸ்கிரீன்ஷாட் இணைக்கப்பட்டது';

  @override
  String get supportRemoveScreenshot => 'அகற்று';

  @override
  String get supportSubmit => 'அறிக்கையை அனுப்பு';

  @override
  String get supportSubmitted => 'நன்றி — உங்கள் அறிக்கையைப் பெற்றோம்.';

  @override
  String get supportSubmitFailed =>
      'அனுப்ப முடியவில்லை. தயவு செய்து எங்களுக்கு மின்னஞ்சல் அனுப்புங்கள்.';

  @override
  String get supportBugDescriptionRequired => 'என்ன நடந்தது என்பதை விளக்கவும்.';

  @override
  String get supportFaq => 'அடிக்கடி கேட்கப்படும் கேள்விகள்';

  @override
  String get supportFaqQ1 => 'பார்கோடை எவ்வாறு ஸ்கேன் செய்வது?';

  @override
  String get supportFaqA1 =>
      'ஸ்கேன் தாவலைத் திறக்கவும், கேமராவை பார்கோடில் வைத்து நிலையாக வைத்திருங்கள். தெளிவான குறியீட்டைப் படிக்கும் தருணத்தில் தயாரிப்பு தோன்றும்.';

  @override
  String get supportFaqQ2 => 'தயாரிப்பு தரவுத்தளத்தில் இல்லாவிட்டால் என்ன?';

  @override
  String get supportFaqA2 =>
      'காணப்படவில்லை திரையில் \"தயாரிப்பைச் சேர்\" எனத் தட்டவும். உங்கள் ஸ்டோருடன் இணைக்கப்பட்ட புதிய பதிவை உருவாக்கும்.';

  @override
  String get supportFaqQ3 => 'என் சந்தாவை எப்படி ரத்துசெய்வது?';

  @override
  String get supportFaqA3 =>
      'சுயவிவரம் → சந்தா-வுக்குச் செல்லுங்கள். எப்போது வேண்டுமானாலும் ரத்துசெய்யலாம்; அடுத்த பில்லிங் சுழற்சிக்குப் பிறகு கட்டணம் இல்லை.';

  @override
  String get supportFaqQ4 => 'எனக்கு ரிகால் எச்சரிக்கை ஏன் தோன்றுகிறது?';

  @override
  String get supportFaqA4 =>
      'ஒவ்வொரு ஸ்கேனையும் FSSAI ரிகால் ஃபீடுடன் ஒப்பிடுகிறோம். விற்ற பேட்ச் பட்டியலில் இருந்தால் உங்களுக்கு அறிவிக்கிறோம்.';

  @override
  String get supportFaqQ5 =>
      'என் ஒவ்வாமை சுயவிவரத்தைக் குடும்பத்துடன் எப்படி பகிர்வது?';

  @override
  String get supportFaqA5 =>
      'ஒவ்வாமை சுயவிவரம் தற்போது ஒவ்வொரு கணக்குக்கும் தனியானது. ஒரே குடும்பக் கணக்கில் உள்நுழையவும் அல்லது ஒவ்வொரு ஃபோனிலும் அதே ஒவ்வாமைகளைத் தேர்ந்தெடுக்கவும்.';

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
  String get expiryTabNear => 'விரைவில் காலாவதி';

  @override
  String get expiryTabSafe => 'பாதுகாப்பானது';

  @override
  String get expiryCalendarTooltip => 'காலெண்டர் காட்சி';

  @override
  String get expiryEmptyExpiredTitle => 'எதுவும் காலாவதியாகவில்லை';

  @override
  String get expiryEmptyNearTitle => 'எல்லாம் சரி';

  @override
  String get expiryEmptyDefaultTitle => 'இன்னும் பதிவுகள் இல்லை';

  @override
  String get expiryEmptyBody => 'இந்தப் பிரிவில் பதிவுகள் இல்லை.';

  @override
  String expiryProductShort(String id) {
    return 'பொருள் $id';
  }

  @override
  String expiryBatch(String batch) {
    return 'தொகுதி $batch';
  }

  @override
  String expiryQty(String qty) {
    return 'அளவு $qty';
  }

  @override
  String expiryExp(String date) {
    return 'காலாவதி $date';
  }

  @override
  String get expiryPillToday => 'இன்று';

  @override
  String get expiryPillTomorrow => 'நாளை';

  @override
  String expiryPillDays(int days) {
    return '${days}d';
  }

  @override
  String get expiryPillSoon => 'விரைவில்';

  @override
  String get expiryLoadError => 'காலாவதிப் பதிவுகளை ஏற்ற முடியவில்லை.';

  @override
  String get expiryCouldNotLoadSemantic => 'ஏற்ற முடியவில்லை';

  @override
  String get inventoryTitle => 'சரக்கு';

  @override
  String get inventorySearchTooltip => 'சரக்கைத் தேடு';

  @override
  String get inventorySearchHint => 'பொருள் அல்லது EAN மூலம் தேடு...';

  @override
  String get inventoryStockMovement => 'சரக்கு நகர்வு';

  @override
  String get inventoryLowStockAlerts => 'குறைந்த சரக்கு எச்சரிக்கைகள்';

  @override
  String get inventoryLoadError => 'சரக்கை ஏற்ற முடியவில்லை';

  @override
  String get inventoryEmpty => 'சரக்கு உருப்படிகள் எதுவும் இல்லை';

  @override
  String inventoryNoMatches(String query) {
    return '\"$query\" க்கு பொருத்தம் இல்லை';
  }

  @override
  String inventoryProductShort(String id) {
    return 'பொருள் $id';
  }

  @override
  String get inventoryBelowThreshold => 'வரம்புக்குக் கீழே';

  @override
  String get inventoryInStock => 'கையிருப்பில்';

  @override
  String get inventoryUnitsLabel => 'யூனிட்கள்';

  @override
  String get inventoryTotalQuantity => 'மொத்த அளவு';

  @override
  String get inventoryLowStockThreshold => 'குறைந்த சரக்கு வரம்பு';

  @override
  String inventoryQtyUnits(int count) {
    return '$count யூனிட்கள்';
  }

  @override
  String get inventoryBatchLedgerHint =>
      'முழு தொகுதி பேரேட்டைப் பார்க்க \"சரக்கு நகர்வு\" தட்டவும்.';

  @override
  String get inventoryLowStockBadge => 'குறைந்த சரக்கு';

  @override
  String get tasksTitle => 'பணிகள்';

  @override
  String get tasksTabMine => 'என் பணிகள்';

  @override
  String get tasksTabAll => 'அனைத்தும்';

  @override
  String get tasksNewTask => 'புதிய பணி';

  @override
  String get tasksEmptyTitle => 'இங்கே பணிகள் இல்லை';

  @override
  String get tasksEmptyBody =>
      'இந்தக் காட்சிக்கு ஒதுக்கப்பட்ட பணிகள் இங்கே தோன்றும்.';

  @override
  String get tasksLoadError => 'பணிகளை ஏற்ற முடியவில்லை';

  @override
  String get taskEvidence => 'சான்று';

  @override
  String get priorityHigh => 'உயர்';

  @override
  String get priorityMedium => 'நடுத்தர';

  @override
  String get priorityLow => 'குறைந்த';

  @override
  String get priorityUrgent => 'அவசரம்';

  @override
  String get taskStatusOpen => 'திறந்தது';

  @override
  String get taskStatusPending => 'நிலுவையில்';

  @override
  String get taskStatusInProgress => 'செயலில் உள்ளது';

  @override
  String get taskStatusCompleted => 'முடிந்தது';

  @override
  String get taskStatusCancelled => 'ரத்து செய்யப்பட்டது';

  @override
  String get scanTitle => 'ஒரு பொருளை ஸ்கேன் செய்';

  @override
  String get scanAlignHint => 'பார்கோடை சட்டகத்திற்குள் சீரமைக்கவும்';

  @override
  String get scanBatchHint =>
      'தொகுதி பயன்முறை — ஸ்கேன் செய்துகொண்டே இருங்கள், உருப்படிகள் தானாகவே சேர்க்கப்படும்';

  @override
  String scanBatchAdded(String code, int count) {
    return '$code சேர்க்கப்பட்டது · $count ஸ்கேன் செய்யப்பட்டது';
  }

  @override
  String scanBatchDone(int count) {
    return 'முடிந்தது · $count';
  }

  @override
  String get scanLabelAction => 'லேபிளை ஸ்கேன் செய்';

  @override
  String get scanGalleryAction => 'கேலரி';

  @override
  String get scanEnterManually => 'கைமுறையாக உள்ளிடவும்';

  @override
  String get scanBulkAudit => 'மொத்த தணிக்கை';

  @override
  String get scanHistoryAction => 'வரலாறு';

  @override
  String get scanFlash => 'ஃபிளாஷ்';

  @override
  String get scanTroubleTitle => 'ஸ்கேன் செய்வதில் சிக்கலா?';

  @override
  String get scanTroubleBody =>
      'மங்கலான வெளிச்சம் அல்லது சேதமடைந்த பார்கோடா? ஃபிளாஷை இயக்கவும், அல்லது அதற்குப் பதிலாக லேபிளைப் படிக்கவும்.';

  @override
  String get scanGalleryNoBarcode =>
      'பார்கோடு எதுவும் இல்லை. குறிப்பு: பொருட்களைப் படிக்க \'லேபிளை ஸ்கேன் செய்\' பயன்படுத்தவும்.';

  @override
  String get scanInvalidEan =>
      'சரியான EAN-8, EAN-13, அல்லது UPC-A குறியீட்டை உள்ளிடவும்';

  @override
  String get scanWebTitle => 'ஸ்கேன்';

  @override
  String get scanWebUnavailable =>
      'வலையில் கேமரா ஸ்கேனிங் கிடைக்காது.\nபார்கோடை கைமுறையாக உள்ளிடவும்:';

  @override
  String get scanEanFieldLabel => 'EAN / UPC குறியீடு';

  @override
  String get scanEanHintExample => 'எ.கா. 5901234123457';

  @override
  String get scanLookUp => 'தேடு';

  @override
  String get scanEnterBarcode => 'பார்கோடை உள்ளிடவும்';

  @override
  String get scanHistoryTitle => 'ஸ்கேன் வரலாறு';

  @override
  String get scanNoHistory => 'இந்த அமர்வில் இன்னும் ஸ்கேன் இல்லை.';

  @override
  String get homeGreetingMorning => 'காலை வணக்கம்';

  @override
  String get homeGreetingAfternoon => 'மதிய வணக்கம்';

  @override
  String get homeGreetingEvening => 'மாலை வணக்கம்';

  @override
  String get homeGreetingFallbackName => 'நண்பரே';

  @override
  String get homeTrialEnded =>
      'இலவச சோதனை முடிந்தது — அணுகலைத் தொடர அப்கிரேடு செய்யவும்';

  @override
  String homeTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days நாட்கள்',
      one: '1 நாள்',
    );
    return 'இலவச சோதனை · $_temp0 மீதம்';
  }

  @override
  String get homeUpgradeArrow => 'அப்கிரேடு →';

  @override
  String get homeKpiSaved => 'சேமித்தவை';

  @override
  String get homeKpiNearExpiry => 'விரைவில் காலாவதி';

  @override
  String get homeKpiRecallAlerts => 'ரீகால் எச்சரிக்கைகள்';

  @override
  String get homeKpiOpenTasks => 'திறந்த பணிகள்';

  @override
  String get homeKpiLowStock => 'குறைந்த சரக்கு';

  @override
  String get homeEyebrowFoodSafety => 'உணவு பாதுகாப்பு எச்சரிக்கை';

  @override
  String get homeEyebrowToday => 'இன்றைய பணி';

  @override
  String get homeEyebrowHealthScan => 'உங்கள் ஹெல்த் ஸ்கேன்';

  @override
  String get homeEyebrowScanToLearn => 'ஸ்கேன் செய்து அறியுங்கள்';

  @override
  String get homeEyebrowAllClear => 'எல்லாம் சரி';

  @override
  String homeStoryRecall(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ரீகால் செய்யப்பட்ட பொருட்கள் — உங்கள் வீட்டில் உள்ளதைப் பார்க்கவும்',
      one: '1 ரீகால் செய்யப்பட்ட பொருள் — உங்கள் வீட்டில் உள்ளதைப் பார்க்கவும்',
    );
    return '$_temp0';
  }

  @override
  String homeStoryNearExpiryConsumer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count சேமித்த பொருட்கள் இந்த வாரம் காலாவதியாகின்றன — பயன்படுத்துங்கள்',
      one: '1 சேமித்த பொருள் இந்த வாரம் காலாவதியாகிறது — பயன்படுத்துங்கள்',
    );
    return '$_temp0';
  }

  @override
  String get homeStoryKnowWhatYouEat => 'நீங்கள் சாப்பிடுவதை அறியுங்கள்';

  @override
  String get homeStoryScanInside =>
      'எந்த உணவு பார்கோடிலும் கேமராவை வைக்கவும் — உள்ளே என்ன இருக்கிறது என்பதைப் பார்க்கவும்';

  @override
  String homeStoryNearExpiryBusiness(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count பொருட்கள் விரைவில் காலாவதி — அலமாரியை காலி செய்யுங்கள்',
      one: '1 பொருள் விரைவில் காலாவதி — அலமாரியை காலி செய்யுங்கள்',
    );
    return '$_temp0';
  }

  @override
  String homeStoryOpenTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count பணிகளுக்கு இன்று உங்கள் தேவை',
      one: '1 பணிக்கு இன்று உங்கள் தேவை',
    );
    return '$_temp0';
  }

  @override
  String homeStoryLowStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count பொருட்களின் சரக்கு குறைகிறது',
      one: '1 பொருளின் சரக்கு குறைகிறது',
    );
    return '$_temp0';
  }

  @override
  String get homeStoreToday => 'இதோ இன்று உங்கள் கடை';

  @override
  String get homeStoreAllGood =>
      'ஷபாஷ்! உங்கள் கடை இன்று சிறந்த நிலையில் உள்ளது';

  @override
  String get homeCtaViewRecallAlerts => 'ரீகால் எச்சரிக்கைகளைப் பார்க்கவும்';

  @override
  String get homeCtaCheckExpiry => 'காலாவதியைப் பார்க்கவும்';

  @override
  String get homeCtaOpenExpiry => 'காலாவதியைத் திறக்கவும்';

  @override
  String get homeCtaViewTasks => 'பணிகளைப் பார்க்கவும்';

  @override
  String get homeCtaCheckInventory => 'சரக்கைப் பார்க்கவும்';

  @override
  String get homeCtaOpenTasks => 'பணிகளைத் திறக்கவும்';

  @override
  String get homeCtaRunAudit => 'ஒரு விரைவு தணிக்கையை இயக்கவும்';

  @override
  String get homeQuickActions => 'விரைவு செயல்கள்';

  @override
  String get homeQuickScan => 'ஸ்கேன்';

  @override
  String get homeQuickShopping => 'ஷாப்பிங்';

  @override
  String get homeQuickAddExpiry => 'காலாவதி சேர்க்கவும்';

  @override
  String get homeQuickNewTask => 'புதிய பணி';

  @override
  String get homeRecentTasks => 'சமீபத்திய பணிகள்';

  @override
  String get homeSeeAll => 'அனைத்தையும் பார்க்கவும்';

  @override
  String get homeNoOpenTasks => 'திறந்த பணிகள் இல்லை — ஒன்றை உருவாக்கவும்';

  @override
  String homeTaskAssignedTo(String name) {
    return '$name க்கு ஒதுக்கப்பட்டது';
  }

  @override
  String get homeTaskOverdue => 'தாமதம்';

  @override
  String get homeTaskDueToday => 'இன்று செலுத்த வேண்டியது';

  @override
  String get homeTaskDueTomorrow => 'நாளை செலுத்த வேண்டியது';

  @override
  String homeTaskDueInDays(int days) {
    return '$days நாட்களில் செலுத்த வேண்டியது';
  }

  @override
  String homeTaskDueOn(String date) {
    return '$date அன்று செலுத்த வேண்டியது';
  }

  @override
  String get homeHowHelps => 'RADHA உங்களுக்கு எப்படி உதவுகிறது';

  @override
  String get homeScanBarcodeTitle =>
      'எந்த உணவு பார்கோடையும் ஸ்கேன் செய்யுங்கள்';

  @override
  String get homeScanBarcodeBody =>
      'ஹெல்த் மதிப்பீடு, பொருட்கள், எதைக் கவனிக்க வேண்டும் — அனைத்தையும் பார்க்கவும்.';

  @override
  String get homeRecallTitle => 'பாதுகாப்பு ரீகால் எச்சரிக்கைகள்';

  @override
  String get homeRecallBody =>
      'ரீகால் செய்யப்பட்ட உணவுப் பொருட்கள் குறித்து அறிந்திருங்கள்.';

  @override
  String get homePromoKnowFoodEyebrow => 'உங்கள் உணவை அறியுங்கள்';

  @override
  String get homePromoKnowFoodHeadline =>
      'லேபிளை ஸ்கேன் செய்யுங்கள் — உண்மையில் உள்ளே என்ன இருக்கிறது என்பதைப் பார்க்கவும்';

  @override
  String get homePromoKnowFoodCta => 'ஸ்கேன் செய்து அறியுங்கள்';

  @override
  String get homePromoExpiryEyebrow => 'எந்த தேதியையும் தவறவிடாதீர்கள்';

  @override
  String get homePromoExpiryHeadline =>
      'ஒவ்வொரு காலாவதியையும் நழுவுவதற்கு முன் பிடியுங்கள்';

  @override
  String get homePromoExpiryCta => 'காலாவதியைக் கண்காணியுங்கள்';

  @override
  String get homePromoFestiveEyebrow => 'பண்டிகை தேர்வுகள்';

  @override
  String get homePromoFestiveHeadline =>
      'பருவத்தை ஆரோக்கியமான முறையில் வாங்குங்கள்';

  @override
  String get homePromoFestiveCta => 'பொருட்களை உலாவுங்கள்';

  @override
  String get homePromoBazaarEyebrow => 'இன்றைய சந்தை';

  @override
  String get homePromoBazaarHeadline =>
      'நிமிடங்களில் உங்கள் அலமாரிகளை தணிக்கை செய்யுங்கள்';

  @override
  String get homePromoBazaarCta => 'தணிக்கையைத் தொடங்குங்கள்';

  @override
  String get homeShopByCategory => 'வகை வாரியாக வாங்குங்கள்';

  @override
  String get homeShopByCategorySubtitle =>
      'ஸ்கேன் செய்ய அல்லது உலாவ ஒரு பிரிவைத் தட்டவும்';

  @override
  String get onboardingWelcomeValue =>
      'ஸ்கேன் செய்யுங்கள், கண்காணியுங்கள், உங்கள் சரக்கை தணிக்கை செய்யுங்கள் — ஸ்ப்ரெட்ஷீட் இல்லாமல்.';

  @override
  String get onboardingCapabilitiesTitle =>
      'கடை தளத்திற்காக உருவாக்கப்பட்டது,\nஅலுவலகத்திற்காக அல்ல.';

  @override
  String get onboardingCapScanTitle =>
      'ஒரே தட்டில் பொருட்களை ஸ்கேன் செய்யுங்கள்';

  @override
  String get onboardingCapScanBody =>
      'ஹெல்த் மற்றும் ஒப்புதல் முன்கூட்டியே சரிபார்க்கப்பட்ட EAN தேடல்.';

  @override
  String get onboardingCapExpiryTitle =>
      'உங்களுக்கு நஷ்டம் ஏற்படுவதற்கு முன் காலாவதியைப் பிடியுங்கள்';

  @override
  String get onboardingCapExpiryBody =>
      'OCR-உதவியுடன் தேதிகள் மற்றும் வகை வாரியான வரம்புகள்.';

  @override
  String get onboardingCapAuditTitle =>
      'குழு முடிக்கக்கூடிய தணிக்கைகளை இயக்குங்கள்';

  @override
  String get onboardingCapAuditBody =>
      'பணிகள், சான்றுகள் மற்றும் மொத்த ஸ்கேன் அமர்வுகள்.';

  @override
  String get onboardingSegmentTitle => 'நீங்கள் இங்கே யாராக இருக்கிறீர்கள்?';

  @override
  String get onboardingSegmentSubtitle =>
      'மிக நெருக்கமான பொருத்தத்தைத் தேர்ந்தெடுக்கவும். பின்னர் அமைப்புகளில் மாற்றலாம்.';

  @override
  String get segmentPersonalTitle => 'தனிப்பட்ட';

  @override
  String get segmentPersonalBody => 'எனக்காக மட்டுமே வாங்குகிறேன்';

  @override
  String get segmentParentTitle => 'பெற்றோர்';

  @override
  String get segmentParentBody =>
      'என் குடும்பம் / குழந்தைகளுக்காக வாங்குகிறேன்';

  @override
  String get segmentBusinessTitle => 'வணிக உரிமையாளர்';

  @override
  String get segmentBusinessBody => 'நான் ஒரு சிறிய சில்லறை கடை நடத்துகிறேன்';

  @override
  String get segmentPharmacyTitle => 'மருந்தகம்';

  @override
  String get segmentPharmacyBody =>
      'நான் ஒரு மருந்தகம் / கெமிஸ்ட் நடத்துகிறேன்';

  @override
  String get segmentInstitutionTitle => 'நிறுவனம்';

  @override
  String get segmentInstitutionBody => 'பள்ளி / விடுதி / உணவகம்';

  @override
  String get segmentAuditorTitle => 'தணிக்கையாளர் (அழைக்கப்பட்டவர்)';

  @override
  String get segmentAuditorBody => 'என்னிடம் அழைப்புக் குறியீடு உள்ளது';

  @override
  String get allergenTitle => 'ஒவ்வாமைகள்';

  @override
  String get allergenLoadError =>
      'உங்கள் ஒவ்வாமை சுயவிவரத்தை ஏற்ற முடியவில்லை.';

  @override
  String get allergenHeading => 'உங்கள் ஒவ்வாமைகள்';

  @override
  String get allergenIntro =>
      'உங்களுக்கு ஒவ்வாமை ஏற்படுத்தும் எவற்றையும் தட்டவும். ஸ்கேன் செய்யப்பட்ட பொருளில் அவை இருந்தால் நாங்கள் உங்களை எச்சரிப்போம்.';

  @override
  String allergenTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ஒவ்வாமைகள் கண்காணிக்கப்படுகின்றன',
      one: '1 ஒவ்வாமை கண்காணிக்கப்படுகிறது',
    );
    return '$_temp0';
  }

  @override
  String get allergenNoneTracked =>
      'இன்னும் ஒவ்வாமைகள் எதுவும் கண்காணிக்கப்படவில்லை';

  @override
  String get allergenSavedCleared => 'ஒவ்வாமை சுயவிவரம் அழிக்கப்பட்டது.';

  @override
  String get allergenSaved => 'ஒவ்வாமை சுயவிவரம் சேமிக்கப்பட்டது.';

  @override
  String get allergenSaveError => 'உங்கள் ஒவ்வாமைகளை சேமிக்க முடியவில்லை.';

  @override
  String get allergenPeanut => 'வேர்க்கடலை';

  @override
  String get allergenTreeNut => 'மரக் கொட்டை';

  @override
  String get allergenDairy => 'பால் பொருட்கள்';

  @override
  String get allergenEggs => 'முட்டை';

  @override
  String get allergenSoy => 'சோயா';

  @override
  String get allergenWheat => 'கோதுமை';

  @override
  String get allergenFish => 'மீன்';

  @override
  String get allergenShellfish => 'ஓட்டுமீன்';

  @override
  String get allergenSesame => 'எள்';

  @override
  String get allergenGluten => 'குளுட்டன்';

  @override
  String get allergenMustard => 'கடுகு';

  @override
  String get allergenCelery => 'செலரி';

  @override
  String get allergenLupin => 'லூபின்';

  @override
  String get allergenMolluscs => 'மெல்லுடலி';

  @override
  String get allergenSulphites => 'சல்பைட்டுகள்';
}
