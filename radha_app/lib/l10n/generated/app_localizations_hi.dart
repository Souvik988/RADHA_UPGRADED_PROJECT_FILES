// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'RADHA';

  @override
  String get tagline => 'डेटा, स्वास्थ्य और ऑडिट के लिए रिटेल असिस्टेंट।';

  @override
  String get continueLabel => 'जारी रखें';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get skip => 'छोड़ें';

  @override
  String get next => 'आगे';

  @override
  String get back => 'पीछे';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get delete => 'हटाएँ';

  @override
  String get edit => 'संपादित करें';

  @override
  String get add => 'जोड़ें';

  @override
  String get search => 'खोजें';

  @override
  String get loading => 'लोड हो रहा है';

  @override
  String get error => 'कुछ गड़बड़ हो गई';

  @override
  String get tryAgain => 'फिर से कोशिश करें';

  @override
  String get done => 'पूरा हुआ';

  @override
  String get close => 'बंद करें';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get signOut => 'साइन आउट करें';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get enterOtp => 'OTP दर्ज करें';

  @override
  String get verifyOtp => 'OTP सत्यापित करें';

  @override
  String get resendOtp => 'OTP फिर से भेजें';

  @override
  String get otpSent => 'हमने आपको 6 अंकों का कोड भेजा है';

  @override
  String get home => 'होम';

  @override
  String get scan => 'स्कैन';

  @override
  String get expiry => 'एक्सपायरी';

  @override
  String get tasks => 'कार्य';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get scanProduct => 'उत्पाद स्कैन करें';

  @override
  String get pointAtBarcode => 'कैमरा बारकोड पर रखें';

  @override
  String get scanAgain => 'फिर से स्कैन करें';

  @override
  String get productNotFound => 'उत्पाद नहीं मिला';

  @override
  String get expiryTracker => 'एक्सपायरी ट्रैकर';

  @override
  String get addExpiry => 'एक्सपायरी जोड़ें';

  @override
  String get expiringSoon => 'जल्द एक्सपायर होगा';

  @override
  String get expired => 'एक्सपायर हो चुका';

  @override
  String get yourTasks => 'आपके कार्य';

  @override
  String get noTasks => 'कोई कार्य नहीं';

  @override
  String get completeTask => 'कार्य पूरा करें';

  @override
  String get welcome => 'स्वागत है';

  @override
  String get welcomeMessage =>
      'स्प्रेडशीट के बिना अपना स्टॉक स्कैन, ट्रैक और ऑडिट करें।';

  @override
  String get referrals => 'रेफरल';

  @override
  String get shareYourCode => 'अपना कोड साझा करें';

  @override
  String get yourReferralCode => 'आपका रेफरल कोड';

  @override
  String get invitees => 'आमंत्रित';

  @override
  String get rewardsEarned => 'अर्जित पुरस्कार';

  @override
  String get redeemCode => 'कोड भुनाएँ';

  @override
  String get enterReferralCode => 'रेफरल कोड दर्ज करें';

  @override
  String get chooseLanguage => 'भाषा चुनें';

  @override
  String get languageUpdated => 'भाषा अपडेट की गई';

  @override
  String get errorGeneric => 'कुछ गड़बड़ हो गई। कृपया पुनः प्रयास करें।';

  @override
  String errorRateLimitOtp(int seconds) {
    return 'बहुत अधिक OTP अनुरोध। $seconds सेकंड में पुनः प्रयास करें।';
  }

  @override
  String get errorOtpInvalid => 'OTP गलत है। कृपया पुनः प्रयास करें।';

  @override
  String get errorOtpExpired =>
      'OTP की समय-सीमा समाप्त हो गई। कृपया नया OTP भेजें।';

  @override
  String get errorAuthRequired => 'जारी रखने के लिए साइन इन करें।';

  @override
  String get errorNotFound => 'नहीं मिला।';

  @override
  String get ingredientExplainerErrorTitle => 'व्याख्या लोड नहीं हो सकी';

  @override
  String get ingredientExplainerHealthConsiderations => 'स्वास्थ्य विचार';

  @override
  String healthyAlternativesTitle(String productName) {
    return '$productName से बेहतर विकल्प';
  }

  @override
  String get healthyAlternativesGenericTitle => 'बेहतर विकल्प';

  @override
  String get healthyAlternativesEmptyTitle => 'अभी कोई स्वस्थ विकल्प नहीं';

  @override
  String get healthyAlternativesEmptyBody =>
      'इसी श्रेणी में अभी तक कोई स्वस्थ विकल्प नहीं मिला।';

  @override
  String get healthyAlternativesErrorTitle => 'विकल्प लोड नहीं हो सके';

  @override
  String get healthyAlternativesAddToList => 'खरीदारी सूची में जोड़ें';

  @override
  String get healthyAlternativesView => 'देखें';

  @override
  String get healthyAlternativesAddedToList => 'खरीदारी सूची में जोड़ा गया';

  @override
  String get healthyAlternativesAddFailed =>
      'खरीदारी सूची में नहीं जोड़ा जा सका';

  @override
  String get savedProductsTitle => 'सहेजे गए उत्पाद';

  @override
  String get savedProductsEmptyTitle => 'सहेजे गए उत्पाद';

  @override
  String get savedProductsEmptyBody =>
      'स्कैन परिणाम स्क्रीन से उत्पाद सहेजें ताकि वे यहाँ दिखें।';

  @override
  String get savedProductsErrorTitle => 'सहेजे गए उत्पाद लोड नहीं हो सके';

  @override
  String savedProductsSavedOn(String date) {
    return '$date को सहेजा गया';
  }

  @override
  String get digestTitle => 'RADHA के साथ आपका सप्ताह';

  @override
  String digestWeekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String digestSavingsHero(String amount) {
    return '₹$amount की बचत';
  }

  @override
  String digestScansHero(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count स्कैन',
      one: '1 स्कैन',
    );
    return '$_temp0';
  }

  @override
  String get digestHeroEmptyHeadline => 'शांत सप्ताह';

  @override
  String get digestScans => 'स्कैन';

  @override
  String get digestSavedProducts => 'सहेजे गए';

  @override
  String get digestExpiringSoon => 'जल्द एक्सपायर';

  @override
  String digestRecallAlerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिकॉल अलर्ट',
      one: '1 रिकॉल अलर्ट',
    );
    return '$_temp0';
  }

  @override
  String get digestRecallAlertsBody =>
      'इस सप्ताह स्कैन किए गए उत्पादों पर नई सुरक्षा सूचनाएँ हैं।';

  @override
  String get digestRecallAlertsCta => 'देखें';

  @override
  String get digestTopCategoriesHeader => 'आप क्या स्कैन कर रहे हैं';

  @override
  String get digestHighlightsHeader => 'मुख्य बातें';

  @override
  String get digestContinueScanning => 'स्कैन करते रहें';

  @override
  String get digestShare => 'मेरा सप्ताह साझा करें';

  @override
  String digestShareTemplate(int scans, String savings) {
    return 'मैंने इस सप्ताह $scans उत्पाद स्कैन किए और RADHA से ₹$savings बचाए। आप भी आज़माएँ: https://radha.app';
  }

  @override
  String get digestEmptyTitle => 'इस सप्ताह कोई गतिविधि नहीं';

  @override
  String get digestEmptyBody =>
      'अपनी साप्ताहिक कहानी शुरू करने के लिए स्कैन करें।';

  @override
  String get digestErrorTitle => 'साप्ताहिक डाइजेस्ट लोड नहीं हो सका';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsNotifications => 'सूचनाएँ';

  @override
  String get settingsPushNotifications => 'पुश सूचनाएँ';

  @override
  String get settingsPushNotificationsHint => 'अपने फोन पर अलर्ट पाएँ';

  @override
  String get settingsRecallAlerts => 'रिकॉल अलर्ट';

  @override
  String get settingsRecallAlertsHint =>
      'जब स्कैन किया गया उत्पाद रिकॉल हो तो जानें';

  @override
  String get settingsWeeklyDigest => 'साप्ताहिक डाइजेस्ट';

  @override
  String get settingsWeeklyDigestHint =>
      'रविवार को आपके स्कैन और बचत का सारांश';

  @override
  String get settingsAppearance => 'रूप';

  @override
  String get settingsTheme => 'थीम';

  @override
  String get settingsThemeSystem => 'सिस्टम';

  @override
  String get settingsThemeLight => 'लाइट';

  @override
  String get settingsThemeDark => 'डार्क';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get settingsTextSize => 'टेक्स्ट आकार';

  @override
  String get settingsTextSizeSmall => 'छोटा';

  @override
  String get settingsTextSizeStandard => 'मानक';

  @override
  String get settingsTextSizeLarge => 'बड़ा';

  @override
  String get settingsDataPrivacy => 'डेटा और गोपनीयता';

  @override
  String get settingsAllergens => 'एलर्जी प्रोफ़ाइल';

  @override
  String get settingsAllergensHint =>
      'जिन सामग्रियों से सावधान करना है उन्हें चुनें';

  @override
  String get settingsSignOutAll => 'सभी डिवाइस से साइन आउट';

  @override
  String get settingsSignOutAllConfirmTitle => 'हर जगह से साइन आउट?';

  @override
  String get settingsSignOutAllConfirmBody =>
      'इस अकाउंट का उपयोग करने वाले हर डिवाइस पर आपको फिर से साइन इन करना होगा।';

  @override
  String get settingsDeleteAccount => 'अकाउंट हटाएँ';

  @override
  String get settingsDeleteAccountTitle => 'अकाउंट हटाएँ';

  @override
  String get settingsDeleteAccountBody =>
      'यह आपके डेटा को स्थायी रूप से हटा देगा। पुष्टि करने के लिए DELETE टाइप करें।';

  @override
  String get settingsDeleteAccountConfirm => 'DELETE';

  @override
  String get settingsDeleteAccountUnavailable =>
      'अकाउंट हटाने के लिए सहायता से संपर्क करें।';

  @override
  String get settingsDeleteAccountContact => 'सहायता से संपर्क करें';

  @override
  String get settingsAbout => 'के बारे में';

  @override
  String get settingsTerms => 'सेवा की शर्तें';

  @override
  String get settingsPrivacyPolicy => 'गोपनीयता नीति';

  @override
  String get settingsVersion => 'ऐप संस्करण';

  @override
  String settingsVersionValue(String version, String build) {
    return 'संस्करण $version ($build)';
  }

  @override
  String get settingsSupport => 'सहायता';

  @override
  String get settingsSupportHint =>
      'मदद पाएँ, बग रिपोर्ट करें, या प्रतिक्रिया साझा करें';

  @override
  String get settingsLinkOpenFailed => 'लिंक नहीं खोला जा सका';

  @override
  String conflictBannerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count विरोधों पर ध्यान देना है',
      one: '1 विरोध पर ध्यान देना है',
    );
    return '$_temp0';
  }

  @override
  String get conflictBannerCta => 'हल करें';

  @override
  String get conflictBannerDismiss => 'बंद करें';

  @override
  String get conflictResolveTitle => 'सिंक विरोध हल करें';

  @override
  String get conflictResolveSubtitle =>
      'हर आइटम के लिए कौन सा संस्करण रखना है चुनें।';

  @override
  String get conflictUseMine => 'मेरा संस्करण रखें';

  @override
  String get conflictUseServer => 'सर्वर का संस्करण रखें';

  @override
  String get conflictResolved => 'विरोध हल हुआ';

  @override
  String get conflictResolvedAll => 'सभी विरोध हल हो गए';

  @override
  String conflictAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बार कोशिश की',
      one: '1 बार कोशिश की',
    );
    return '$_temp0';
  }

  @override
  String get conflictResourceTask => 'कार्य';

  @override
  String get conflictResourceExpiry => 'एक्सपायरी रिकॉर्ड';

  @override
  String get conflictResourceScan => 'स्कैन';

  @override
  String get conflictResourceInventory => 'स्टॉक समायोजन';

  @override
  String get conflictResourceGrn => 'GRN प्रविष्टि';

  @override
  String get conflictResourceShoppingList => 'खरीदारी सूची आइटम';

  @override
  String get conflictResourceGeneric => 'सिंक परिवर्तन';

  @override
  String conflictLocalChangeSummary(String summary) {
    return 'आपका बदलाव: $summary';
  }

  @override
  String get supportTitle => 'सहायता';

  @override
  String get supportContactUs => 'हमसे संपर्क करें';

  @override
  String get supportEmailUs => 'ईमेल भेजें';

  @override
  String get supportEmailUsHint => 'support@radha.app';

  @override
  String get supportCallUs => 'कॉल करें';

  @override
  String get supportCallUsHint => 'सोम–शुक्र, सुबह 9 से शाम 6, IST';

  @override
  String get supportReportBug => 'बग रिपोर्ट करें';

  @override
  String get supportBugDescription => 'क्या हुआ?';

  @override
  String get supportBugDescriptionHint =>
      'बताएँ कि जब समस्या हुई तब आप क्या कर रहे थे।';

  @override
  String get supportAttachScreenshot => 'स्क्रीनशॉट जोड़ें';

  @override
  String get supportScreenshotAttached => 'स्क्रीनशॉट जोड़ा गया';

  @override
  String get supportRemoveScreenshot => 'हटाएँ';

  @override
  String get supportSubmit => 'रिपोर्ट भेजें';

  @override
  String get supportSubmitted => 'धन्यवाद — हमें आपकी रिपोर्ट मिल गई।';

  @override
  String get supportSubmitFailed => 'भेजा नहीं जा सका। कृपया हमें ईमेल करें।';

  @override
  String get supportBugDescriptionRequired => 'कृपया बताएँ कि क्या हुआ।';

  @override
  String get supportFaq => 'अक्सर पूछे जाने वाले प्रश्न';

  @override
  String get supportFaqQ1 => 'मैं बारकोड कैसे स्कैन करूँ?';

  @override
  String get supportFaqA1 =>
      'स्कैन टैब खोलें, कैमरा बारकोड पर रखें और स्थिर रखें। साफ कोड पढ़ते ही उत्पाद दिखेगा।';

  @override
  String get supportFaqQ2 => 'अगर उत्पाद डेटाबेस में नहीं है तो?';

  @override
  String get supportFaqA2 =>
      'नहीं-मिला स्क्रीन पर \"उत्पाद जोड़ें\" टैप करें। यह आपके स्टोर से जुड़ी नई एंट्री बनाएगा।';

  @override
  String get supportFaqQ3 => 'मैं अपनी सदस्यता कैसे रद्द करूँ?';

  @override
  String get supportFaqA3 =>
      'प्रोफ़ाइल → सदस्यता पर जाएँ। आप कभी भी रद्द कर सकते हैं; अगले बिलिंग चक्र के बाद कोई शुल्क नहीं लगेगा।';

  @override
  String get supportFaqQ4 => 'मुझे रिकॉल अलर्ट क्यों दिख रहा है?';

  @override
  String get supportFaqA4 =>
      'हम हर स्कैन की FSSAI रिकॉल फीड से तुलना करते हैं। यदि आपने जो बैच बेचा वो सूची में है तो हम आपको बताते हैं।';

  @override
  String get supportFaqQ5 =>
      'अपनी एलर्जी प्रोफ़ाइल परिवार के साथ कैसे साझा करूँ?';

  @override
  String get supportFaqA5 =>
      'अभी एलर्जी प्रोफ़ाइल प्रति-अकाउंट होती है। एक ही घरेलू अकाउंट से साइन इन करें या हर फोन पर वही एलर्जी चुनें।';

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
  String get expiryTabNear => 'जल्द समाप्त';

  @override
  String get expiryTabSafe => 'सुरक्षित';

  @override
  String get expiryCalendarTooltip => 'कैलेंडर दृश्य';

  @override
  String get expiryEmptyExpiredTitle => 'कुछ भी एक्सपायर नहीं';

  @override
  String get expiryEmptyNearTitle => 'सब ठीक है';

  @override
  String get expiryEmptyDefaultTitle => 'अभी कोई रिकॉर्ड नहीं';

  @override
  String get expiryEmptyBody => 'इस श्रेणी में कोई रिकॉर्ड नहीं है।';

  @override
  String expiryProductShort(String id) {
    return 'उत्पाद $id';
  }

  @override
  String expiryBatch(String batch) {
    return 'बैच $batch';
  }

  @override
  String expiryQty(String qty) {
    return 'मात्रा $qty';
  }

  @override
  String expiryExp(String date) {
    return 'एक्सपायरी $date';
  }

  @override
  String get expiryPillToday => 'आज';

  @override
  String get expiryPillTomorrow => 'कल';

  @override
  String expiryPillDays(int days) {
    return '${days}d';
  }

  @override
  String get expiryPillSoon => 'जल्द';

  @override
  String get expiryLoadError => 'एक्सपायरी रिकॉर्ड लोड नहीं हो सके।';

  @override
  String get expiryCouldNotLoadSemantic => 'लोड नहीं हो सका';

  @override
  String get inventoryTitle => 'इन्वेंटरी';

  @override
  String get inventorySearchTooltip => 'इन्वेंटरी खोजें';

  @override
  String get inventorySearchHint => 'उत्पाद या EAN से खोजें...';

  @override
  String get inventoryStockMovement => 'स्टॉक मूवमेंट';

  @override
  String get inventoryLowStockAlerts => 'कम स्टॉक अलर्ट';

  @override
  String get inventoryLoadError => 'इन्वेंटरी लोड नहीं हो सकी';

  @override
  String get inventoryEmpty => 'कोई इन्वेंटरी आइटम नहीं मिला';

  @override
  String inventoryNoMatches(String query) {
    return '\"$query\" के लिए कोई मिलान नहीं';
  }

  @override
  String inventoryProductShort(String id) {
    return 'उत्पाद $id';
  }

  @override
  String get inventoryBelowThreshold => 'सीमा से नीचे';

  @override
  String get inventoryInStock => 'स्टॉक में';

  @override
  String get inventoryUnitsLabel => 'यूनिट';

  @override
  String get inventoryTotalQuantity => 'कुल मात्रा';

  @override
  String get inventoryLowStockThreshold => 'कम-स्टॉक सीमा';

  @override
  String inventoryQtyUnits(int count) {
    return '$count यूनिट';
  }

  @override
  String get inventoryBatchLedgerHint =>
      'पूरा बैच लेज़र देखने के लिए \"स्टॉक मूवमेंट\" टैप करें।';

  @override
  String get inventoryLowStockBadge => 'कम स्टॉक';

  @override
  String get tasksTitle => 'कार्य';

  @override
  String get tasksTabMine => 'मेरे कार्य';

  @override
  String get tasksTabAll => 'सभी';

  @override
  String get tasksNewTask => 'नया कार्य';

  @override
  String get tasksEmptyTitle => 'यहाँ कोई कार्य नहीं';

  @override
  String get tasksEmptyBody => 'इस दृश्य को सौंपे गए कार्य यहाँ दिखेंगे।';

  @override
  String get tasksLoadError => 'कार्य लोड नहीं हो सके';

  @override
  String get taskEvidence => 'साक्ष्य';

  @override
  String get priorityHigh => 'उच्च';

  @override
  String get priorityMedium => 'मध्यम';

  @override
  String get priorityLow => 'निम्न';

  @override
  String get priorityUrgent => 'अत्यावश्यक';

  @override
  String get taskStatusOpen => 'खुला';

  @override
  String get taskStatusPending => 'लंबित';

  @override
  String get taskStatusInProgress => 'जारी है';

  @override
  String get taskStatusCompleted => 'पूर्ण';

  @override
  String get taskStatusCancelled => 'रद्द';

  @override
  String get scanTitle => 'उत्पाद स्कैन करें';

  @override
  String get scanAlignHint => 'बारकोड को फ्रेम के भीतर रखें';

  @override
  String get scanBatchHint =>
      'बैच मोड — स्कैन करते रहें, आइटम स्वतः जुड़ते जाएँगे';

  @override
  String scanBatchAdded(String code, int count) {
    return '$code जोड़ा · $count स्कैन किए गए';
  }

  @override
  String scanBatchDone(int count) {
    return 'पूर्ण · $count';
  }

  @override
  String get scanLabelAction => 'लेबल स्कैन';

  @override
  String get scanGalleryAction => 'गैलरी';

  @override
  String get scanEnterManually => 'मैन्युअल रूप से दर्ज करें';

  @override
  String get scanBulkAudit => 'बल्क ऑडिट';

  @override
  String get scanHistoryAction => 'इतिहास';

  @override
  String get scanFlash => 'फ्लैश';

  @override
  String get scanTroubleTitle => 'स्कैन करने में परेशानी?';

  @override
  String get scanTroubleBody =>
      'कम रोशनी या खराब बारकोड? फ्लैश चालू करें, या इसके बजाय लेबल पढ़ें।';

  @override
  String get scanGalleryNoBarcode =>
      'कोई बारकोड नहीं मिला। सुझाव: सामग्री पढ़ने के लिए \'लेबल स्कैन\' का उपयोग करें।';

  @override
  String get scanInvalidEan => 'एक वैध EAN-8, EAN-13, या UPC-A कोड दर्ज करें';

  @override
  String get scanWebTitle => 'स्कैन';

  @override
  String get scanWebUnavailable =>
      'वेब पर कैमरा स्कैनिंग उपलब्ध नहीं है।\nबारकोड मैन्युअल रूप से दर्ज करें:';

  @override
  String get scanEanFieldLabel => 'EAN / UPC कोड';

  @override
  String get scanEanHintExample => 'उदा. 5901234123457';

  @override
  String get scanLookUp => 'खोजें';

  @override
  String get scanEnterBarcode => 'बारकोड दर्ज करें';

  @override
  String get scanHistoryTitle => 'स्कैन इतिहास';

  @override
  String get scanNoHistory => 'इस सत्र में अभी तक कोई स्कैन नहीं।';

  @override
  String get homeGreetingMorning => 'सुप्रभात';

  @override
  String get homeGreetingAfternoon => 'शुभ दोपहर';

  @override
  String get homeGreetingEvening => 'शुभ संध्या';

  @override
  String get homeGreetingFallbackName => 'दोस्त';

  @override
  String get homeTrialEnded =>
      'मुफ़्त ट्रायल समाप्त — एक्सेस बनाए रखने के लिए अपग्रेड करें';

  @override
  String homeTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन',
      one: '1 दिन',
    );
    return 'मुफ़्त ट्रायल · $_temp0 शेष';
  }

  @override
  String get homeUpgradeArrow => 'अपग्रेड →';

  @override
  String get homeKpiSaved => 'सहेजे गए';

  @override
  String get homeKpiNearExpiry => 'जल्द समाप्त';

  @override
  String get homeKpiRecallAlerts => 'रिकॉल अलर्ट';

  @override
  String get homeKpiOpenTasks => 'खुले कार्य';

  @override
  String get homeKpiLowStock => 'कम स्टॉक';

  @override
  String get homeEyebrowFoodSafety => 'खाद्य सुरक्षा चेतावनी';

  @override
  String get homeEyebrowToday => 'आज का काम';

  @override
  String get homeEyebrowHealthScan => 'आपका हेल्थ स्कैन';

  @override
  String get homeEyebrowScanToLearn => 'स्कैन करके जानें';

  @override
  String get homeEyebrowAllClear => 'सब ठीक है';

  @override
  String homeStoryRecall(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिकॉल किए गए उत्पाद — देखें आपके घर में क्या है',
      one: '1 रिकॉल किया गया उत्पाद — देखें आपके घर में क्या है',
    );
    return '$_temp0';
  }

  @override
  String homeStoryNearExpiryConsumer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count सहेजे आइटम इस सप्ताह समाप्त हो रहे हैं — इन्हें इस्तेमाल करें',
      one: '1 सहेजा आइटम इस सप्ताह समाप्त हो रहा है — इसे इस्तेमाल करें',
    );
    return '$_temp0';
  }

  @override
  String get homeStoryKnowWhatYouEat => 'जानें आप क्या खाते हैं';

  @override
  String get homeStoryScanInside =>
      'किसी भी फूड बारकोड पर कैमरा रखें — देखें अंदर क्या है';

  @override
  String homeStoryNearExpiryBusiness(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आइटम जल्द समाप्त — शेल्फ साफ़ करें',
      one: '1 आइटम जल्द समाप्त — शेल्फ साफ़ करें',
    );
    return '$_temp0';
  }

  @override
  String homeStoryOpenTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कार्यों को आज आपकी ज़रूरत है',
      one: '1 कार्य को आज आपकी ज़रूरत है',
    );
    return '$_temp0';
  }

  @override
  String homeStoryLowStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आइटम का स्टॉक कम हो रहा है',
      one: '1 आइटम का स्टॉक कम हो रहा है',
    );
    return '$_temp0';
  }

  @override
  String get homeStoreToday => 'यह रही आज आपकी दुकान';

  @override
  String get homeStoreAllGood => 'शाबाश! आपकी दुकान आज बढ़िया स्थिति में है';

  @override
  String get homeCtaViewRecallAlerts => 'रिकॉल अलर्ट देखें';

  @override
  String get homeCtaCheckExpiry => 'एक्सपायरी देखें';

  @override
  String get homeCtaOpenExpiry => 'एक्सपायरी खोलें';

  @override
  String get homeCtaViewTasks => 'कार्य देखें';

  @override
  String get homeCtaCheckInventory => 'इन्वेंटरी देखें';

  @override
  String get homeCtaOpenTasks => 'कार्य खोलें';

  @override
  String get homeCtaRunAudit => 'एक त्वरित ऑडिट चलाएँ';

  @override
  String get homeQuickActions => 'त्वरित क्रियाएँ';

  @override
  String get homeQuickScan => 'स्कैन';

  @override
  String get homeQuickShopping => 'शॉपिंग';

  @override
  String get homeQuickAddExpiry => 'एक्सपायरी जोड़ें';

  @override
  String get homeQuickNewTask => 'नया कार्य';

  @override
  String get homeRecentTasks => 'हाल के कार्य';

  @override
  String get homeSeeAll => 'सभी देखें';

  @override
  String get homeNoOpenTasks => 'कोई खुला कार्य नहीं — एक बनाएँ';

  @override
  String homeTaskAssignedTo(String name) {
    return '$name को सौंपा गया';
  }

  @override
  String get homeTaskOverdue => 'बकाया';

  @override
  String get homeTaskDueToday => 'आज देय';

  @override
  String get homeTaskDueTomorrow => 'कल देय';

  @override
  String homeTaskDueInDays(int days) {
    return '$days दिनों में देय';
  }

  @override
  String homeTaskDueOn(String date) {
    return 'देय $date';
  }

  @override
  String get homeHowHelps => 'RADHA आपकी कैसे मदद करता है';

  @override
  String get homeScanBarcodeTitle => 'किसी भी फूड बारकोड को स्कैन करें';

  @override
  String get homeScanBarcodeBody =>
      'हेल्थ रेटिंग, सामग्री, और किन बातों का ध्यान रखें — सब देखें।';

  @override
  String get homeRecallTitle => 'सुरक्षा रिकॉल अलर्ट';

  @override
  String get homeRecallBody =>
      'रिकॉल किए गए खाद्य उत्पादों के बारे में सूचित रहें।';

  @override
  String get homePromoKnowFoodEyebrow => 'अपना भोजन जानें';

  @override
  String get homePromoKnowFoodHeadline =>
      'लेबल स्कैन करें — देखें अंदर वास्तव में क्या है';

  @override
  String get homePromoKnowFoodCta => 'स्कैन करें और जानें';

  @override
  String get homePromoExpiryEyebrow => 'कोई तारीख न चूकें';

  @override
  String get homePromoExpiryHeadline => 'हर एक्सपायरी को फिसलने से पहले पकड़ें';

  @override
  String get homePromoExpiryCta => 'एक्सपायरी ट्रैक करें';

  @override
  String get homePromoFestiveEyebrow => 'त्योहारी चुनिंदा';

  @override
  String get homePromoFestiveHeadline =>
      'सीज़न की खरीदारी करें, सेहतमंद तरीके से';

  @override
  String get homePromoFestiveCta => 'उत्पाद ब्राउज़ करें';

  @override
  String get homePromoBazaarEyebrow => 'आज का बाज़ार';

  @override
  String get homePromoBazaarHeadline => 'मिनटों में अपनी शेल्फ का ऑडिट करें';

  @override
  String get homePromoBazaarCta => 'ऑडिट शुरू करें';

  @override
  String get homeShopByCategory => 'श्रेणी से खरीदें';

  @override
  String get homeShopByCategorySubtitle =>
      'स्कैन या ब्राउज़ करने के लिए किसी आइल पर टैप करें';

  @override
  String get onboardingWelcomeValue =>
      'स्कैन करें, ट्रैक करें, अपने स्टॉक का ऑडिट करें — स्प्रेडशीट के बिना।';

  @override
  String get onboardingCapabilitiesTitle =>
      'दुकान के फ़र्श के लिए बना,\nपिछले दफ़्तर के लिए नहीं।';

  @override
  String get onboardingCapScanTitle => 'एक टैप में उत्पाद स्कैन करें';

  @override
  String get onboardingCapScanBody =>
      'EAN लुकअप, हेल्थ और अप्रूवल पहले से जाँचे हुए।';

  @override
  String get onboardingCapExpiryTitle => 'नुकसान से पहले एक्सपायरी पकड़ें';

  @override
  String get onboardingCapExpiryBody =>
      'OCR-सहायता प्राप्त तिथियाँ और प्रति-श्रेणी सीमाएँ।';

  @override
  String get onboardingCapAuditTitle => 'ऐसे ऑडिट चलाएँ जो टीम पूरे कर सके';

  @override
  String get onboardingCapAuditBody => 'कार्य, साक्ष्य और बल्क स्कैन सत्र।';

  @override
  String get onboardingSegmentTitle => 'आप यहाँ किस रूप में हैं?';

  @override
  String get onboardingSegmentSubtitle =>
      'सबसे करीबी विकल्प चुनें। आप बाद में सेटिंग्स में बदल सकते हैं।';

  @override
  String get segmentPersonalTitle => 'व्यक्तिगत';

  @override
  String get segmentPersonalBody => 'बस अपने लिए खरीदारी';

  @override
  String get segmentParentTitle => 'अभिभावक';

  @override
  String get segmentParentBody => 'अपने परिवार / बच्चों के लिए खरीदारी';

  @override
  String get segmentBusinessTitle => 'व्यवसाय मालिक';

  @override
  String get segmentBusinessBody => 'मैं एक छोटी रिटेल दुकान चलाता हूँ';

  @override
  String get segmentPharmacyTitle => 'फार्मेसी';

  @override
  String get segmentPharmacyBody => 'मैं एक फार्मेसी / केमिस्ट चलाता हूँ';

  @override
  String get segmentInstitutionTitle => 'संस्थान';

  @override
  String get segmentInstitutionBody => 'स्कूल / छात्रावास / कैंटीन';

  @override
  String get segmentAuditorTitle => 'ऑडिटर (आमंत्रित)';

  @override
  String get segmentAuditorBody => 'मेरे पास एक आमंत्रण कोड है';

  @override
  String get allergenTitle => 'एलर्जेन';

  @override
  String get allergenLoadError => 'आपकी एलर्जेन प्रोफ़ाइल लोड नहीं हो सकी।';

  @override
  String get allergenHeading => 'आपके एलर्जेन';

  @override
  String get allergenIntro =>
      'जिन एलर्जेन से आपको प्रतिक्रिया होती है उन्हें टैप करें। स्कैन किए गए उत्पाद में वे होने पर हम आपको चेतावनी देंगे।';

  @override
  String allergenTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count एलर्जेन ट्रैक किए गए',
      one: '1 एलर्जेन ट्रैक किया गया',
    );
    return '$_temp0';
  }

  @override
  String get allergenNoneTracked => 'अभी तक कोई एलर्जेन ट्रैक नहीं किया गया';

  @override
  String get allergenSavedCleared => 'एलर्जेन प्रोफ़ाइल साफ़ कर दी गई।';

  @override
  String get allergenSaved => 'एलर्जेन प्रोफ़ाइल सहेजी गई।';

  @override
  String get allergenSaveError => 'आपकी एलर्जेन सहेजी नहीं जा सकीं।';

  @override
  String get allergenPeanut => 'मूंगफली';

  @override
  String get allergenTreeNut => 'ट्री नट';

  @override
  String get allergenDairy => 'डेयरी';

  @override
  String get allergenEggs => 'अंडे';

  @override
  String get allergenSoy => 'सोया';

  @override
  String get allergenWheat => 'गेहूँ';

  @override
  String get allergenFish => 'मछली';

  @override
  String get allergenShellfish => 'शेलफिश';

  @override
  String get allergenSesame => 'तिल';

  @override
  String get allergenGluten => 'ग्लूटेन';

  @override
  String get allergenMustard => 'सरसों';

  @override
  String get allergenCelery => 'सेलरी';

  @override
  String get allergenLupin => 'ल्यूपिन';

  @override
  String get allergenMolluscs => 'मोलस्क';

  @override
  String get allergenSulphites => 'सल्फाइट';
}
