// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get subTitle => 'सदस्यता';

  @override
  String get subUnlockHeadline => 'RADHA की पूरी तस्वीर अनलॉक करें';

  @override
  String get subLoadError => 'आपकी सदस्यता लोड नहीं हो सकी';

  @override
  String get subErrorBody => 'अपना कनेक्शन जाँचें और फिर से कोशिश करें।';

  @override
  String get subChoosePlan => 'एक प्लान चुनें';

  @override
  String get subPlansLoadError => 'प्लान लोड नहीं हो सके';

  @override
  String get subPlansUnavailable =>
      'अभी कोई प्लान उपलब्ध नहीं है। कृपया बाद में फिर से कोशिश करें।';

  @override
  String get subSecurePayment => 'Razorpay के ज़रिए सुरक्षित भुगतान';

  @override
  String get subCurrentPlan => 'मौजूदा प्लान';

  @override
  String subRenewsInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिनों में नवीनीकरण',
      one: '1 दिन में नवीनीकरण',
    );
    return '$_temp0';
  }

  @override
  String get subBillingMonthly => 'मासिक';

  @override
  String get subBillingYearly => 'वार्षिक';

  @override
  String get subBilledYearly => 'वार्षिक बिलिंग';

  @override
  String get subPerMonth => '/माह';

  @override
  String get subPerYear => '/वर्ष';

  @override
  String get subPopular => 'लोकप्रिय';

  @override
  String get subStatusTrial => 'ट्रायल';

  @override
  String subStatusDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन शेष',
      one: '1 दिन शेष',
    );
    return '$_temp0';
  }

  @override
  String get subStatusActive => 'सक्रिय';

  @override
  String get subStatusPastDue => 'बकाया';

  @override
  String get subStatusPaused => 'रुका हुआ';

  @override
  String get subStatusCancelled => 'रद्द';

  @override
  String subUpgradeTo(String plan) {
    return '$plan में अपग्रेड करें';
  }

  @override
  String subChoosePlanNamed(String plan) {
    return '$plan चुनें';
  }

  @override
  String subYoureOnPlan(String plan) {
    return 'आप $plan पर हैं';
  }

  @override
  String subWelcome(String plan) {
    return 'आप $plan पर हैं। RADHA $plan में आपका स्वागत है!';
  }

  @override
  String get subCheckoutCancelled =>
      'चेकआउट रद्द किया गया — आपका प्लान वही है।';

  @override
  String subPaymentPending(String supportRef) {
    return 'भुगतान मिल गया — इसे अभी सत्यापित किया जा रहा है। संदर्भ $supportRef. थोड़ी देर में रिफ्रेश करने के लिए नीचे खींचें।';
  }

  @override
  String get subPaymentFailed => 'भुगतान विफल रहा। कृपया फिर से कोशिश करें।';

  @override
  String get catalogSearchBarHint => 'अपने लिए सही उत्पाद खोजें';

  @override
  String get catalogSearchHint => 'उत्पाद या ब्रांड खोजें';

  @override
  String get catalogSearchClear => 'साफ़ करें';

  @override
  String get catalogNoMatchesTitle => 'कोई मिलान नहीं';

  @override
  String catalogNoMatchesBody(String query) {
    return 'हमें “$query” के लिए कोई उत्पाद नहीं मिला। कोई दूसरा नाम आज़माएँ, या आइटम को स्कैन करें।';
  }

  @override
  String get catalogScanProduct => 'उत्पाद स्कैन करें';

  @override
  String get catalogFindTitle => 'उत्पाद खोजें';

  @override
  String get catalogFindBody =>
      'इसकी हेल्थ रेटिंग और सामग्री देखने के लिए उत्पाद का नाम या ब्रांड खोजें।';

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
}
