// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get subTitle => 'సబ్‌స్క్రిప్షన్';

  @override
  String get subUnlockHeadline => 'RADHA పూర్తి చిత్రాన్ని అన్‌లాక్ చేయండి';

  @override
  String get subLoadError => 'మీ సబ్‌స్క్రిప్షన్‌ను లోడ్ చేయలేకపోయాం';

  @override
  String get subErrorBody => 'మీ కనెక్షన్‌ను తనిఖీ చేసి మళ్ళీ ప్రయత్నించండి.';

  @override
  String get subChoosePlan => 'ఒక ప్లాన్‌ను ఎంచుకోండి';

  @override
  String get subPlansLoadError => 'ప్లాన్‌లను లోడ్ చేయలేకపోయాం';

  @override
  String get subPlansUnavailable =>
      'ప్రస్తుతం ప్లాన్‌లు అందుబాటులో లేవు. దయచేసి తర్వాత మళ్ళీ ప్రయత్నించండి.';

  @override
  String get subSecurePayment => 'Razorpay ద్వారా సురక్షిత చెల్లింపు';

  @override
  String get subCurrentPlan => 'ప్రస్తుత ప్లాన్';

  @override
  String subRenewsInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days రోజుల్లో పునరుద్ధరణ',
      one: '1 రోజులో పునరుద్ధరణ',
    );
    return '$_temp0';
  }

  @override
  String get subBillingMonthly => 'నెలవారీ';

  @override
  String get subBillingYearly => 'వార్షిక';

  @override
  String get subBilledYearly => 'వార్షిక బిల్లింగ్';

  @override
  String get subPerMonth => '/నెల';

  @override
  String get subPerYear => '/సంవత్సరం';

  @override
  String get subPopular => 'జనాదరణ';

  @override
  String get subStatusTrial => 'ట్రయల్';

  @override
  String subStatusDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days రోజులు మిగిలి ఉన్నాయి',
      one: '1 రోజు మిగిలి ఉంది',
    );
    return '$_temp0';
  }

  @override
  String get subStatusActive => 'యాక్టివ్';

  @override
  String get subStatusPastDue => 'బకాయి';

  @override
  String get subStatusPaused => 'పాజ్ చేయబడింది';

  @override
  String get subStatusCancelled => 'రద్దు చేయబడింది';

  @override
  String subUpgradeTo(String plan) {
    return '$planకి అప్‌గ్రేడ్ చేయండి';
  }

  @override
  String subChoosePlanNamed(String plan) {
    return '$plan ఎంచుకోండి';
  }

  @override
  String subYoureOnPlan(String plan) {
    return 'మీరు $planలో ఉన్నారు';
  }

  @override
  String subWelcome(String plan) {
    return 'మీరు $planలో ఉన్నారు. RADHA $planకి స్వాగతం!';
  }

  @override
  String get subCheckoutCancelled =>
      'చెక్‌అవుట్ రద్దు చేయబడింది — మీ ప్లాన్ మారలేదు.';

  @override
  String subPaymentPending(String supportRef) {
    return 'చెల్లింపు అందింది — ఇప్పుడు ధృవీకరిస్తోంది. రిఫరెన్స్ $supportRef. కొద్దిసేపటిలో రిఫ్రెష్ చేయడానికి కిందికి లాగండి.';
  }

  @override
  String get subPaymentFailed =>
      'చెల్లింపు విఫలమైంది. దయచేసి మళ్ళీ ప్రయత్నించండి.';

  @override
  String get catalogSearchBarHint => 'మీకు సరిపోయే ఉత్పత్తిని కనుగొనండి';

  @override
  String get catalogSearchHint => 'ఉత్పత్తి లేదా బ్రాండ్‌ను శోధించండి';

  @override
  String get catalogSearchClear => 'క్లియర్ చేయి';

  @override
  String get catalogNoMatchesTitle => 'సరిపోలికలు లేవు';

  @override
  String catalogNoMatchesBody(String query) {
    return '“$query” కోసం ఉత్పత్తులు కనుగొనబడలేదు. వేరే పేరు ప్రయత్నించండి, లేదా వస్తువును స్కాన్ చేయండి.';
  }

  @override
  String get catalogScanProduct => 'ఉత్పత్తిని స్కాన్ చేయండి';

  @override
  String get catalogFindTitle => 'ఉత్పత్తిని కనుగొనండి';

  @override
  String get catalogFindBody =>
      'దాని హెల్త్ రేటింగ్ మరియు పదార్థాలను చూడటానికి ఉత్పత్తి పేరు లేదా బ్రాండ్‌ను శోధించండి.';

  @override
  String get catalogProductsFallback => 'ఉత్పత్తులు';

  @override
  String get catalogLoadErrorTitle => 'ఉత్పత్తులను లోడ్ చేయలేకపోయాం';

  @override
  String catalogLoadErrorBody(String category) {
    return '$category లోడ్ చేయడంలో సమస్య. దయచేసి మళ్ళీ ప్రయత్నించండి.';
  }

  @override
  String get catalogSourceOffline =>
      'ఆఫ్‌లైన్ — మీ సేవ్ చేసిన కేటలాగ్‌ను చూపిస్తోంది';

  @override
  String get catalogSourceUnavailable =>
      'లైవ్ కేటలాగ్ అందుబాటులో లేదు — సేవ్ చేసిన కేటలాగ్‌ను చూపిస్తోంది';

  @override
  String get catalogRetry => 'మళ్ళీ';

  @override
  String get catalogSortHealthiest => 'ఆరోగ్యకరమైనది';

  @override
  String get catalogSortAZ => 'పేరు ప్రకారం';

  @override
  String get catalogVegOnly => 'శాకాహారం మాత్రమే';

  @override
  String get catalogVeg => 'శాకాహారం';

  @override
  String get catalogNoVegTitle => 'ఇక్కడ ఇంకా శాకాహార వస్తువులు లేవు';

  @override
  String catalogNoVegBody(String category) {
    return '$categoryలో ప్రస్తుతం శాకాహార ఫిల్టర్‌కు ఏదీ సరిపోలడం లేదు.';
  }

  @override
  String get catalogShowAll => 'అన్నీ చూపించు';

  @override
  String get catalogNoProductsTitle => 'ఇంకా ఉత్పత్తులు లేవు';

  @override
  String catalogNoProductsBody(String category) {
    return 'మేము $category విభాగాన్ని నింపుతున్నాం. ఈలోపు, ఏదైనా వస్తువును స్కాన్ చేసి దాని ఆరోగ్యం మరియు గడువును తనిఖీ చేయండి.';
  }

  @override
  String get appName => 'RADHA';

  @override
  String get tagline => 'డేటా, ఆరోగ్యం మరియు ఆడిట్‌ల కోసం రిటైల్ అసిస్టెంట్.';

  @override
  String get continueLabel => 'కొనసాగించు';

  @override
  String get getStarted => 'ప్రారంభించండి';

  @override
  String get skip => 'దాటవేయి';

  @override
  String get next => 'తదుపరి';

  @override
  String get back => 'వెనుకకు';

  @override
  String get cancel => 'రద్దు చేయి';

  @override
  String get save => 'సేవ్ చేయి';

  @override
  String get delete => 'తొలగించు';

  @override
  String get edit => 'సవరించు';

  @override
  String get add => 'జోడించు';

  @override
  String get search => 'వెతుకు';

  @override
  String get loading => 'లోడ్ అవుతోంది';

  @override
  String get error => 'ఏదో తప్పు జరిగింది';

  @override
  String get tryAgain => 'మళ్ళీ ప్రయత్నించండి';

  @override
  String get done => 'పూర్తయింది';

  @override
  String get close => 'మూసివేయి';

  @override
  String get signIn => 'సైన్ ఇన్ చేయండి';

  @override
  String get signOut => 'సైన్ అవుట్ చేయండి';

  @override
  String get mobileNumber => 'మొబైల్ నంబర్';

  @override
  String get enterOtp => 'OTP నమోదు చేయండి';

  @override
  String get verifyOtp => 'OTP ధృవీకరించండి';

  @override
  String get resendOtp => 'OTP మళ్ళీ పంపండి';

  @override
  String get otpSent => 'మేము మీకు 6-అంకెల కోడ్ పంపాము';

  @override
  String get home => 'హోమ్';

  @override
  String get scan => 'స్కాన్';

  @override
  String get expiry => 'గడువు';

  @override
  String get tasks => 'పనులు';

  @override
  String get profile => 'ప్రొఫైల్';

  @override
  String get settings => 'సెట్టింగ్‌లు';

  @override
  String get language => 'భాష';

  @override
  String get scanProduct => 'ఉత్పత్తిని స్కాన్ చేయండి';

  @override
  String get pointAtBarcode => 'మీ కెమెరాను బార్‌కోడ్ వద్ద ఉంచండి';

  @override
  String get scanAgain => 'మళ్ళీ స్కాన్ చేయండి';

  @override
  String get productNotFound => 'ఉత్పత్తి కనుగొనబడలేదు';

  @override
  String get expiryTracker => 'గడువు ట్రాకర్';

  @override
  String get addExpiry => 'గడువు జోడించు';

  @override
  String get expiringSoon => 'త్వరలో గడువు ముగుస్తుంది';

  @override
  String get expired => 'గడువు ముగిసింది';

  @override
  String get yourTasks => 'మీ పనులు';

  @override
  String get noTasks => 'ఇంకా పనులు లేవు';

  @override
  String get completeTask => 'పనిని పూర్తి చేయండి';

  @override
  String get welcome => 'స్వాగతం';

  @override
  String get welcomeMessage =>
      'స్ప్రెడ్‌షీట్‌లు లేకుండా మీ స్టాక్‌ను స్కాన్, ట్రాక్, ఆడిట్ చేయండి.';

  @override
  String get referrals => 'రిఫరల్‌లు';

  @override
  String get shareYourCode => 'మీ కోడ్‌ను షేర్ చేయండి';

  @override
  String get yourReferralCode => 'మీ రిఫరల్ కోడ్';

  @override
  String get invitees => 'ఆహ్వానితులు';

  @override
  String get rewardsEarned => 'సంపాదించిన బహుమతులు';

  @override
  String get redeemCode => 'కోడ్ రీడీమ్ చేయండి';

  @override
  String get enterReferralCode => 'రిఫరల్ కోడ్ నమోదు చేయండి';

  @override
  String get chooseLanguage => 'భాషను ఎంచుకోండి';

  @override
  String get languageUpdated => 'భాష నవీకరించబడింది';

  @override
  String get errorGeneric => 'ఏదో తప్పు జరిగింది. దయచేసి మళ్ళీ ప్రయత్నించండి.';

  @override
  String errorRateLimitOtp(int seconds) {
    return 'చాలా ఎక్కువ OTP అభ్యర్థనలు. $seconds సెకన్లలో మళ్ళీ ప్రయత్నించండి.';
  }

  @override
  String get errorOtpInvalid => 'OTP తప్పు. దయచేసి మళ్ళీ ప్రయత్నించండి.';

  @override
  String get errorOtpExpired =>
      'OTP గడువు ముగిసింది. కొత్తదాన్ని అభ్యర్థించండి.';

  @override
  String get errorAuthRequired => 'కొనసాగించడానికి సైన్ ఇన్ చేయండి.';

  @override
  String get errorNotFound => 'కనుగొనబడలేదు.';

  @override
  String get ingredientExplainerErrorTitle => 'వివరణను లోడ్ చేయలేకపోయాము';

  @override
  String get ingredientExplainerHealthConsiderations => 'ఆరోగ్య పరిగణనలు';

  @override
  String healthyAlternativesTitle(String productName) {
    return '$productName కంటే మంచి ఎంపికలు';
  }

  @override
  String get healthyAlternativesGenericTitle => 'మంచి ఎంపికలు';

  @override
  String get healthyAlternativesEmptyTitle =>
      'ఆరోగ్యకరమైన ప్రత్యామ్నాయాలు ఇంకా లేవు';

  @override
  String get healthyAlternativesEmptyBody =>
      'ఇదే వర్గంలో ఇంకా ఆరోగ్యకరమైన ప్రత్యామ్నాయాలు దొరకలేదు.';

  @override
  String get healthyAlternativesErrorTitle =>
      'ప్రత్యామ్నాయాలను లోడ్ చేయలేకపోయాము';

  @override
  String get healthyAlternativesAddToList => 'షాపింగ్ జాబితాకు జోడించు';

  @override
  String get healthyAlternativesView => 'చూడు';

  @override
  String get healthyAlternativesAddedToList => 'షాపింగ్ జాబితాకు జోడించబడింది';

  @override
  String get healthyAlternativesAddFailed =>
      'షాపింగ్ జాబితాకు జోడించడం సాధ్యం కాలేదు';

  @override
  String get savedProductsTitle => 'సేవ్ చేసిన ఉత్పత్తులు';

  @override
  String get savedProductsEmptyTitle => 'సేవ్ చేసిన ఉత్పత్తులు';

  @override
  String get savedProductsEmptyBody =>
      'స్కాన్ ఫలితం స్క్రీన్ నుండి ఉత్పత్తులను సేవ్ చేయండి, అవి ఇక్కడ కనిపిస్తాయి.';

  @override
  String get savedProductsErrorTitle =>
      'సేవ్ చేసిన ఉత్పత్తులను లోడ్ చేయలేకపోయాము';

  @override
  String savedProductsSavedOn(String date) {
    return '$date న సేవ్ చేయబడింది';
  }

  @override
  String get digestTitle => 'RADHA తో మీ వారం';

  @override
  String digestWeekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String digestSavingsHero(String amount) {
    return '₹$amount ఆదా';
  }

  @override
  String digestScansHero(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count స్కాన్‌లు',
      one: '1 స్కాన్',
    );
    return '$_temp0';
  }

  @override
  String get digestHeroEmptyHeadline => 'ప్రశాంత వారం';

  @override
  String get digestScans => 'స్కాన్‌లు';

  @override
  String get digestSavedProducts => 'సేవ్ చేసినవి';

  @override
  String get digestExpiringSoon => 'త్వరలో గడువు';

  @override
  String digestRecallAlerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count రీకాల్ అలర్ట్‌లు',
      one: '1 రీకాల్ అలర్ట్',
    );
    return '$_temp0';
  }

  @override
  String get digestRecallAlertsBody =>
      'ఈ వారం మీరు స్కాన్ చేసిన ఉత్పత్తులకు కొత్త భద్రతా సూచనలు ఉన్నాయి.';

  @override
  String get digestRecallAlertsCta => 'సమీక్షించండి';

  @override
  String get digestTopCategoriesHeader => 'మీరు ఏం స్కాన్ చేస్తున్నారు';

  @override
  String get digestHighlightsHeader => 'ముఖ్యాంశాలు';

  @override
  String get digestContinueScanning => 'స్కాన్ కొనసాగించండి';

  @override
  String get digestShare => 'నా వారాన్ని షేర్ చేయండి';

  @override
  String digestShareTemplate(int scans, String savings) {
    return 'ఈ వారం నేను $scans ఉత్పత్తులను స్కాన్ చేసి RADHA తో ₹$savings ఆదా చేశాను. మీరు కూడా ప్రయత్నించండి: https://radha.app';
  }

  @override
  String get digestEmptyTitle => 'ఈ వారం ఏ కార్యకలాపం లేదు';

  @override
  String get digestEmptyBody =>
      'మీ వారపు కథను నిర్మించడానికి స్కాన్ చేయడం ప్రారంభించండి.';

  @override
  String get digestErrorTitle => 'వారపు సారాంశాన్ని లోడ్ చేయలేకపోయాము';

  @override
  String get settingsTitle => 'సెట్టింగ్‌లు';

  @override
  String get settingsNotifications => 'నోటిఫికేషన్‌లు';

  @override
  String get settingsPushNotifications => 'పుష్ నోటిఫికేషన్‌లు';

  @override
  String get settingsPushNotificationsHint => 'మీ ఫోన్‌లో అలర్ట్‌లను పొందండి';

  @override
  String get settingsRecallAlerts => 'రీకాల్ అలర్ట్‌లు';

  @override
  String get settingsRecallAlertsHint =>
      'మీరు స్కాన్ చేసిన ఉత్పత్తి రీకాల్ అయితే తెలియజేస్తాం';

  @override
  String get settingsWeeklyDigest => 'వారపు సారాంశం';

  @override
  String get settingsWeeklyDigestHint =>
      'ఆదివారం మీ స్కాన్‌లు మరియు పొదుపుల సారాంశం';

  @override
  String get settingsAppearance => 'రూపం';

  @override
  String get settingsTheme => 'థీమ్';

  @override
  String get settingsThemeSystem => 'సిస్టమ్';

  @override
  String get settingsThemeLight => 'లైట్';

  @override
  String get settingsThemeDark => 'డార్క్';

  @override
  String get settingsLanguage => 'భాష';

  @override
  String get settingsTextSize => 'టెక్స్ట్ పరిమాణం';

  @override
  String get settingsTextSizeSmall => 'చిన్న';

  @override
  String get settingsTextSizeStandard => 'ప్రామాణికం';

  @override
  String get settingsTextSizeLarge => 'పెద్ద';

  @override
  String get settingsDataPrivacy => 'డేటా & గోప్యత';

  @override
  String get settingsAllergens => 'అలెర్జీ ప్రొఫైల్';

  @override
  String get settingsAllergensHint =>
      'మనం హెచ్చరించాల్సిన పదార్థాలను ఎంచుకోండి';

  @override
  String get settingsSignOutAll => 'అన్ని పరికరాల నుండి సైన్ అవుట్ చేయండి';

  @override
  String get settingsSignOutAllConfirmTitle => 'ప్రతిచోటి నుంచీ సైన్ అవుట్?';

  @override
  String get settingsSignOutAllConfirmBody =>
      'ఈ ఖాతాను ఉపయోగించే ప్రతి పరికరంలోనూ మళ్లీ సైన్ ఇన్ చేయాలి.';

  @override
  String get settingsDeleteAccount => 'ఖాతాను తొలగించండి';

  @override
  String get settingsDeleteAccountTitle => 'ఖాతాను తొలగించండి';

  @override
  String get settingsDeleteAccountBody =>
      'ఇది మీ డేటాను శాశ్వతంగా తొలగిస్తుంది. ధృవీకరించడానికి DELETE అని టైప్ చేయండి.';

  @override
  String get settingsDeleteAccountConfirm => 'DELETE';

  @override
  String get settingsDeleteAccountUnavailable =>
      'మీ ఖాతాను తొలగించడానికి సహాయాన్ని సంప్రదించండి.';

  @override
  String get settingsDeleteAccountContact => 'సహాయాన్ని సంప్రదించండి';

  @override
  String get settingsAbout => 'గురించి';

  @override
  String get settingsTerms => 'సేవా నిబంధనలు';

  @override
  String get settingsPrivacyPolicy => 'గోప్యతా విధానం';

  @override
  String get settingsVersion => 'యాప్ సంస్కరణ';

  @override
  String settingsVersionValue(String version, String build) {
    return 'సంస్కరణ $version ($build)';
  }

  @override
  String get settingsSupport => 'సహాయం';

  @override
  String get settingsSupportHint =>
      'సహాయం పొందండి, బగ్‌ను నివేదించండి, లేదా ఫీడ్‌బ్యాక్ ఇవ్వండి';

  @override
  String get settingsLinkOpenFailed => 'లింక్‌ను తెరవలేకపోయాము';

  @override
  String conflictBannerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count వైరుధ్యాలకు మీ దృష్టి అవసరం',
      one: '1 వైరుధ్యానికి మీ దృష్టి అవసరం',
    );
    return '$_temp0';
  }

  @override
  String get conflictBannerCta => 'పరిష్కరించండి';

  @override
  String get conflictBannerDismiss => 'మూసివేయి';

  @override
  String get conflictResolveTitle => 'సింక్ వైరుధ్యాలను పరిష్కరించండి';

  @override
  String get conflictResolveSubtitle =>
      'ప్రతి అంశానికి ఏ సంస్కరణను ఉంచాలో ఎంచుకోండి.';

  @override
  String get conflictUseMine => 'నా సంస్కరణను ఉంచు';

  @override
  String get conflictUseServer => 'సర్వర్ సంస్కరణను ఉంచు';

  @override
  String get conflictResolved => 'వైరుధ్యం పరిష్కరించబడింది';

  @override
  String get conflictResolvedAll => 'అన్ని వైరుధ్యాలు పరిష్కరించబడ్డాయి';

  @override
  String conflictAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count సార్లు ప్రయత్నించబడింది',
      one: '1 సారి ప్రయత్నించబడింది',
    );
    return '$_temp0';
  }

  @override
  String get conflictResourceTask => 'పని';

  @override
  String get conflictResourceExpiry => 'గడువు రికార్డ్';

  @override
  String get conflictResourceScan => 'స్కాన్';

  @override
  String get conflictResourceInventory => 'స్టాక్ సర్దుబాటు';

  @override
  String get conflictResourceGrn => 'GRN ఎంట్రీ';

  @override
  String get conflictResourceShoppingList => 'షాపింగ్ జాబితా అంశం';

  @override
  String get conflictResourceGeneric => 'సింక్ మార్పు';

  @override
  String conflictLocalChangeSummary(String summary) {
    return 'మీ మార్పు: $summary';
  }

  @override
  String get supportTitle => 'సహాయం';

  @override
  String get supportContactUs => 'మమ్మల్ని సంప్రదించండి';

  @override
  String get supportEmailUs => 'ఇమెయిల్ పంపండి';

  @override
  String get supportEmailUsHint => 'support@radha.app';

  @override
  String get supportCallUs => 'సహాయానికి కాల్ చేయండి';

  @override
  String get supportCallUsHint => 'సోమ–శుక్ర, ఉదయం 9 – సాయంత్రం 6 IST';

  @override
  String get supportReportBug => 'బగ్‌ను నివేదించండి';

  @override
  String get supportBugDescription => 'ఏం జరిగింది?';

  @override
  String get supportBugDescriptionHint =>
      'సమస్య ఏర్పడినప్పుడు మీరు ఏం చేస్తున్నారో వివరించండి.';

  @override
  String get supportAttachScreenshot => 'స్క్రీన్‌షాట్‌ను జతచేయండి';

  @override
  String get supportScreenshotAttached => 'స్క్రీన్‌షాట్ జతచేయబడింది';

  @override
  String get supportRemoveScreenshot => 'తొలగించు';

  @override
  String get supportSubmit => 'నివేదికను పంపు';

  @override
  String get supportSubmitted => 'ధన్యవాదాలు — మీ నివేదికను అందుకున్నాము.';

  @override
  String get supportSubmitFailed => 'పంపలేకపోయాము. దయచేసి మాకు ఇమెయిల్ పంపండి.';

  @override
  String get supportBugDescriptionRequired => 'ఏమి జరిగిందో వివరించండి.';

  @override
  String get supportFaq => 'తరచుగా అడిగే ప్రశ్నలు';

  @override
  String get supportFaqQ1 => 'బార్‌కోడ్‌ను ఎలా స్కాన్ చేయాలి?';

  @override
  String get supportFaqA1 =>
      'స్కాన్ ట్యాబ్‌ను తెరవండి, కెమెరాను బార్‌కోడ్‌పై ఉంచి స్థిరంగా ఉంచండి. స్పష్టంగా చదివిన క్షణంలో ఉత్పత్తి కనిపిస్తుంది.';

  @override
  String get supportFaqQ2 => 'ఉత్పత్తి డేటాబేస్‌లో లేకపోతే ఏమి?';

  @override
  String get supportFaqA2 =>
      'కనుగొనబడలేదు స్క్రీన్‌లో \"ఉత్పత్తి జోడించు\" నొక్కండి. మీ స్టోర్‌తో అనుసంధానించబడిన కొత్త ఎంట్రీని సృష్టిస్తుంది.';

  @override
  String get supportFaqQ3 => 'నా సబ్‌స్క్రిప్షన్‌ను ఎలా రద్దు చేయాలి?';

  @override
  String get supportFaqA3 =>
      'ప్రొఫైల్ → సబ్‌స్క్రిప్షన్‌కి వెళ్లండి. ఎప్పుడైనా రద్దు చేయవచ్చు; తదుపరి బిల్లింగ్ చక్రం తర్వాత ఛార్జీలు ఉండవు.';

  @override
  String get supportFaqQ4 => 'నాకు రీకాల్ అలర్ట్ ఎందుకు కనిపిస్తుంది?';

  @override
  String get supportFaqA4 =>
      'ప్రతి స్కాన్‌ను FSSAI రీకాల్ ఫీడ్‌తో పోలుస్తాము. మీరు అమ్మిన బ్యాచ్ జాబితాలో ఉంటే మీకు తెలియజేస్తాము.';

  @override
  String get supportFaqQ5 =>
      'నా అలెర్జీ ప్రొఫైల్‌ను కుటుంబంతో ఎలా షేర్ చేయాలి?';

  @override
  String get supportFaqA5 =>
      'ప్రస్తుతం అలెర్జీ ప్రొఫైల్ ప్రతి ఖాతాకు ఒకటే. ఒకే గృహ ఖాతాలో సైన్ ఇన్ చేయండి లేదా ప్రతి ఫోన్‌లో ఒకే అలెర్జీలను ఎంచుకోండి.';

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
