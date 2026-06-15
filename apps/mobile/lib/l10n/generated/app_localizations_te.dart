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
  String get catalogFeaturedTitle => 'ప్రత్యేక ఉత్పత్తులు';

  @override
  String get catalogHealthyPicksTitle => 'ఆరోగ్యకర ఎంపికలు';

  @override
  String get catalogDetailProductFallback => 'ఉత్పత్తి';

  @override
  String get catalogDetailTitle => 'ఉత్పత్తి';

  @override
  String get catalogDetailShareTooltip => 'షేర్ చేయండి';

  @override
  String get catalogDetailSeeHealthierOptions =>
      'మరింత ఆరోగ్యకరమైన ఎంపికలు చూడండి';

  @override
  String get catalogDetailSavedSnackbar =>
      'సేవ్ అయింది — ఇది ఎప్పుడైనా రీకాల్ అయితే మీకు తెలియజేస్తాం.';

  @override
  String get catalogDetailSaveFailedSnackbar =>
      'సేవ్ చేయలేకపోయాం. దయచేసి మళ్లీ ప్రయత్నించండి.';

  @override
  String catalogDetailShareRating(String rating, String label) {
    return ' — RADHA ఆరోగ్య రేటింగ్ $rating/5 ($label)';
  }

  @override
  String catalogDetailShareText(String productName, String ratingSummary) {
    return 'RADHAలో \"$productName\" చెక్ చేశాం$ratingSummary.';
  }

  @override
  String get catalogDetailSavedTooltip => 'సేవ్ అయింది';

  @override
  String get catalogDetailHealthPendingTitle => 'ఆరోగ్య రేటింగ్ ఇంకా రాలేదు';

  @override
  String get catalogDetailHealthPendingBody =>
      'ఈ ఉత్పత్తిని స్కాన్ చేసి పూర్తి ఆరోగ్య విశ్లేషణను RADHAలోకి తెప్పించండి.';

  @override
  String get catalogDetailHealthRatingLabel => 'RADHA ఆరోగ్య రేటింగ్';

  @override
  String get catalogDetailHealthExcellent => 'అద్భుతం';

  @override
  String get catalogDetailHealthGood => 'మంచిది';

  @override
  String get catalogDetailHealthFair => 'సరాసరి';

  @override
  String get catalogDetailHealthPoor => 'బలహీనం';

  @override
  String get catalogDetailHealthAvoid => 'దూరంగా ఉంచండి';

  @override
  String get catalogDetailInsightHighProtein => 'అధిక ప్రోటీన్';

  @override
  String get catalogDetailInsightGoodFibre => 'మంచి ఫైబర్';

  @override
  String get catalogDetailInsightMinimallyProcessed =>
      'తక్కువగా ప్రాసెస్ చేయబడింది';

  @override
  String get catalogDetailConcernHighSugar => 'అధిక చక్కెర';

  @override
  String get catalogDetailConcernHighSaturatedFat => 'అధిక సాచ్యురేటెడ్ కొవ్వు';

  @override
  String get catalogDetailConcernHighSodium => 'అధిక సోడియం';

  @override
  String get catalogDetailConcernUltraProcessed => 'అల్ట్రా-ప్రాసెస్డ్';

  @override
  String get catalogDetailConcernContainsTransFat => 'ట్రాన్స్ ఫ్యాట్ ఉంది';

  @override
  String get catalogDetailConcernContainsAllergens => 'అలెర్జెన్లు ఉన్నాయి';

  @override
  String get catalogDetailLikeHeading => 'మీకు నచ్చేవి';

  @override
  String get catalogDetailConcernHeading => 'మీరు గమనించాల్సినవి';

  @override
  String get catalogDetailNutritionSourceNote =>
      'ఉత్పత్తి యొక్క నిజమైన పోషక సమాచారం ఆధారంగా (100 గ్రాములకు).';

  @override
  String get catalogDetailKeyNutrients => 'ముఖ్య పోషకాలు';

  @override
  String get catalogDetailNutrientProtein => 'ప్రోటీన్';

  @override
  String get catalogDetailNutrientTotalSugars => 'మొత్తం చక్కెర';

  @override
  String get catalogDetailNutrientEnergy => 'శక్తి';

  @override
  String get catalogDetailAllNutrients => 'అన్ని పోషకాలు';

  @override
  String get catalogDetailNutrientTotalFat => 'మొత్తం కొవ్వు';

  @override
  String get catalogDetailNutrientSaturatedFat => 'సాచ్యురేటెడ్ కొవ్వు';

  @override
  String get catalogDetailNutrientCarbohydrates => 'కార్బోహైడ్రేట్లు';

  @override
  String get catalogDetailNutrientFibre => 'ఫైబర్';

  @override
  String get catalogDetailNutrientSodium => 'సోడియం';

  @override
  String get catalogDetailPer100g => '100 గ్రాములకు';

  @override
  String get catalogDetailPer50g => '50 గ్రాములకు';

  @override
  String get catalogDetailRdaNote =>
      'సూచనాత్మక రోజువారీ తీసుకునే పరిమాణంలో % (వయోజనుడు).';

  @override
  String get catalogDetailRadhaPlus => 'RADHA Plus';

  @override
  String get catalogDetailForYou => 'మీ కోసం';

  @override
  String get catalogDetailIngredientDeepDiveTitle => 'పదార్థాల లోతైన వివరణ';

  @override
  String get catalogDetailIngredientDeepDiveLockedBody =>
      'ప్రతి పదార్థాన్ని భద్రతా అభిప్రాయంతో అర్థం చేసుకోండి — అది ఏమిటి, ఎందుకు ఉంది, ఆందోళన చెందాలా వద్దా.';

  @override
  String get catalogDetailIngredientExplainError =>
      'ఈ పదార్థాలను ఇప్పుడే వివరించలేకపోయాం.';

  @override
  String get catalogDetailIngredientNeedsLabel =>
      'పదార్థాల వివరాలకు స్పష్టమైన లేబుల్ ఫోటో కావాలి. ప్యాక్ లేబల్ స్కాన్ చేస్తే RADHA నిజమైన పదార్థాల జాబితాను వివరిస్తుంది.';

  @override
  String get catalogDetailPersonalisedFlagsTitle => 'వ్యక్తిగత హెచ్చరికలు';

  @override
  String get catalogDetailPersonalisedFlagsLockedBody =>
      'ఈ ఉత్పత్తిని మీ సేవ్ చేసిన అలెర్జెన్లు మరియు ఆరోగ్య లక్ష్యాలతో సరిపోల్చండి — మీకు సరైనదా కాదా మేము చూపిస్తాం.';

  @override
  String get catalogDetailPersonaliseError =>
      'ఇప్పుడే మీకు అనుగుణంగా చూపించలేకపోయాం.';

  @override
  String get catalogDetailNoAllergensDetected =>
      'ఈ ఉత్పత్తిలో అలెర్జెన్లు కనబడలేదు.';

  @override
  String get catalogDetailAllergenSignalDetected =>
      'ఈ ఉత్పత్తిలో సాధ్యమైన అలర్జెన్ సమాచారం ఉంది. కొనుగోలు చేయడానికి ముందు లేబల్ చూడండి.';

  @override
  String get catalogDetailAllergenSignalUnavailable =>
      'అలర్జెన్ వివరాలు ఇంకా ఈ ఉత్పత్తి రికార్డులో లేవు. భద్రంగా వ్యక్తిగతీకరించడానికి లేబల్ స్కాన్ చేయండి.';

  @override
  String catalogDetailAllergenAvoided(String allergen) {
    return '$allergen — మీరు దీన్ని దూరంగా ఉంచుతారు';
  }

  @override
  String catalogDetailUnlockWithPlan(String plan) {
    return '$planతో అన్‌లాక్ చేయండి';
  }

  @override
  String get catalogDetailWouldBuyQuestion =>
      'మీరు ఈ ఉత్పత్తిని కొనుగోలు చేస్తారా?';

  @override
  String get catalogDetailWouldBuyThanks => 'షేర్ చేసినందుకు ధన్యవాదాలు!';

  @override
  String get catalogDetailWouldBuyYes => 'అవును';

  @override
  String get catalogDetailWouldBuyNo => 'లేదు';

  @override
  String get catalogDetailWouldBuyAlreadyBought => 'ఇప్పటికే కొనుగోలు చేశాను';

  @override
  String get catalogDetailNutritionNotFoundTitle =>
      'ఈ రికార్డ్ ఇంకా మా దగ్గర లేదు';

  @override
  String get catalogDetailNutritionNotFoundBody =>
      'RADHAలో ఈ ఉత్పత్తి పూర్తి పోషక సమాచారం ఇంకా లేదు. నిజమైన డేటా కోసం దాని బార్కోడ్ లేదా లేబుల్‌ను స్కాన్ చేయండి.';

  @override
  String get catalogDetailNutritionOfflineTitle => 'మీరు ఆఫ్‌లైన్‌లో ఉన్నారు';

  @override
  String get catalogDetailNutritionOfflineBody =>
      'పోషక సమాచారం లోడ్ కాలేదు. పై ఉత్పత్తి వివరాలు అలాగే ఉన్నాయి — మళ్లీ కనెక్ట్ అయి ప్రయత్నించండి.';

  @override
  String get catalogDetailNutritionSessionExpiredTitle =>
      'సెషన్ గడువు ముగిసింది';

  @override
  String get catalogDetailNutritionSessionExpiredBody =>
      'దయచేసి మళ్లీ ప్రయత్నించండి — RADHA మీ సెషన్‌ను రిఫ్రెష్ చేసి మళ్లీ ప్రయత్నిస్తుంది.';

  @override
  String get catalogDetailNutritionAccessDeniedTitle => 'ప్రవేశం పరిమితం';

  @override
  String get catalogDetailNutritionAccessDeniedBody =>
      'మీ ఖాతా ఈ పోషక రికార్డును చదవలదు. పై ఉత్పత్తి సమాచారం అందుబాటులో ఉంది.';

  @override
  String get catalogDetailNutritionTimeoutTitle => 'అభ్యర్థన సమయం ముగిసింది';

  @override
  String get catalogDetailNutritionTimeoutBody =>
      'RADHA సమయానికి పోషక సేవను చేరుకోలేకపోయింది. కనెక్షన్ స్థిరంగా ఉన్నప్పుడు మళ్లీ ప్రయత్నించండి.';

  @override
  String get catalogDetailNutritionServerTitle => 'పోషక సమాచారం లోడ్ కాలేదు';

  @override
  String get catalogDetailNutritionServerBody =>
      'వివరాలు తెచ్చేటప్పుడు ఏదో తప్పు జరిగింది. పై ఉత్పత్తి సమాచారం ప్రభావితం కాలేదు.';

  @override
  String get catalogDetailScanLabel => 'లేబుల్ స్కాన్ చేయండి';

  @override
  String get catalogDetailFullNutritionPendingTitle =>
      'పూర్తి పోషక సమాచారం ఇంకా లేదు';

  @override
  String get catalogDetailFullNutritionPendingBody =>
      'ఈ ఉత్పత్తి బార్కోడ్‌ను స్కాన్ చేసి నిజమైన పోషక సమాచారం మరియు ఆరోగ్య విశ్లేషణను RADHAలోకి తెప్పించండి — ఒక్క క్షణమే పడుతుంది.';

  @override
  String get catalogDetailScanToUnlock => 'అన్‌లాక్ చేయడానికి స్కాన్ చేయండి';

  @override
  String get profileSectionAccount => 'ఖాతా';

  @override
  String get profileManageStores => 'స్టోర్లను నిర్వహించండి';

  @override
  String get profileSectionPreferences => 'ప్రాధాన్యతలు';

  @override
  String get profileShoppingList => 'షాపింగ్ జాబితా';

  @override
  String get profileSectionAbout => 'గురించి';

  @override
  String get profileGuestName => 'అతిథి';

  @override
  String get profileYouName => 'మీరు';

  @override
  String get profileRoleMember => 'సభ్యుడు';

  @override
  String get profileRoleOwner => 'యజమాని';

  @override
  String get profileRoleManager => 'మేనేజర్';

  @override
  String get profileRoleStaff => 'సిబ్బంది';

  @override
  String get profileRoleAuditor => 'ఆడిటర్';

  @override
  String get profileRoleConsumer => 'వినియోగదారు';

  @override
  String get profileRoleAdmin => 'అడ్మిన్';

  @override
  String get profileVersionLoading => 'వెర్షన్ లోడ్ అవుతోంది…';

  @override
  String get profileVersionUnavailable => 'వెర్షన్ అందుబాటులో లేదు';

  @override
  String get profileSignOutConfirmBody =>
      'యాప్ ఉపయోగించడానికి మళ్లీ OTPతో సైన్ ఇన్ చేయాలి.';

  @override
  String get selectStoreTitle => 'స్టోర్ ఎంచుకోండి';

  @override
  String get selectStoreHeading => 'ఒక స్టోర్ ఎంచుకోండి';

  @override
  String get selectStoreBody =>
      'ఈ రోజు మీరు పని చేస్తున్న స్టోర్‌ను ఎంచుకోండి. తర్వాత ప్రొఫైల్ నుంచి స్టోర్‌ను మార్చవచ్చు.';

  @override
  String get selectStoreEmptyTitle => 'ఇంకా స్టోర్లు లేవు';

  @override
  String get selectStoreEmptyBody =>
      'మీ ఖాతా ఇంకా ఏ స్టోర్‌తోనూ అనుసంధానించబడలేదు. యాక్సెస్ ఇవ్వమని మీ మేనేజర్‌ను అడిగి, తర్వాత తిరిగి వచ్చి ఒకటి ఎంచుకోండి.';

  @override
  String get selectStoreContactManager => 'మీ మేనేజర్‌ను సంప్రదించండి';

  @override
  String get selectStoreContactManagerSnackbar =>
      'స్టోర్‌కు జోడించబడేందుకు మీ మేనేజర్‌ను సంప్రదించండి.';

  @override
  String get recallTitle => 'రీకాల్ హెచ్చరికలు';

  @override
  String get recallLoadError => 'రీకాల్‌లను లోడ్ చేయలేకపోయాం.';

  @override
  String get recallEmptyTitle => 'క్రియాశీల రీకాల్‌లు లేవు';

  @override
  String get recallEmptyBody =>
      'నియంత్రణ సంస్థలు ఉత్పత్తి రీకాల్‌లను జారీ చేసినప్పుడు అవి ఇక్కడ కనిపిస్తాయి.';

  @override
  String recallProductFallback(String id) {
    return 'ఉత్పత్తి $id';
  }

  @override
  String recallRecalledOn(String date) {
    return '$dateన రీకాల్ చేయబడింది';
  }

  @override
  String get recallViewProduct => 'ఉత్పత్తిని చూడండి';

  @override
  String get couldNotLoad => 'లోడ్ చేయలేకపోయాం';

  @override
  String get retryLabel => 'మళ్ళీ ప్రయత్నించు';

  @override
  String get lowStockTitle => 'తక్కువ స్టాక్ హెచ్చరికలు';

  @override
  String get lowStockLoadError => 'హెచ్చరికలను లోడ్ చేయలేకపోయాం';

  @override
  String get lowStockEmpty => 'అన్ని స్టాక్ స్థాయిలు బాగున్నాయి';

  @override
  String get lowStockRestock => 'రీస్టాక్';

  @override
  String lowStockProductFallback(String id) {
    return 'ఉత్పత్తి $id';
  }

  @override
  String lowStockLevel(Object current, Object threshold) {
    return 'ప్రస్తుతం: $current / పరిమితి: $threshold';
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

  @override
  String get expiryTabNear => 'త్వరలో గడువు';

  @override
  String get expiryTabSafe => 'సురక్షితం';

  @override
  String get expiryCalendarTooltip => 'క్యాలెండర్ వీక్షణ';

  @override
  String get expiryEmptyExpiredTitle => 'ఏదీ గడువు ముగియలేదు';

  @override
  String get expiryEmptyNearTitle => 'అంతా సవ్యంగా ఉంది';

  @override
  String get expiryEmptyDefaultTitle => 'ఇంకా రికార్డులు లేవు';

  @override
  String get expiryEmptyBody => 'ఈ విభాగంలో రికార్డులు లేవు.';

  @override
  String expiryProductShort(String id) {
    return 'ఉత్పత్తి $id';
  }

  @override
  String expiryBatch(String batch) {
    return 'బ్యాచ్ $batch';
  }

  @override
  String expiryQty(String qty) {
    return 'పరిమాణం $qty';
  }

  @override
  String expiryExp(String date) {
    return 'గడువు $date';
  }

  @override
  String get expiryPillToday => 'ఈ రోజు';

  @override
  String get expiryPillTomorrow => 'రేపు';

  @override
  String expiryPillDays(int days) {
    return '${days}d';
  }

  @override
  String get expiryPillSoon => 'త్వరలో';

  @override
  String get expiryLoadError => 'గడువు రికార్డులను లోడ్ చేయలేకపోయాం.';

  @override
  String get expiryCouldNotLoadSemantic => 'లోడ్ చేయలేకపోయాం';

  @override
  String get inventoryTitle => 'ఇన్వెంటరీ';

  @override
  String get inventorySearchTooltip => 'ఇన్వెంటరీ శోధించండి';

  @override
  String get inventorySearchHint => 'ఉత్పత్తి లేదా EAN ద్వారా శోధించండి...';

  @override
  String get inventoryStockMovement => 'స్టాక్ కదలిక';

  @override
  String get inventoryLowStockAlerts => 'తక్కువ స్టాక్ హెచ్చరికలు';

  @override
  String get inventoryLoadError => 'ఇన్వెంటరీ లోడ్ చేయడం విఫలమైంది';

  @override
  String get inventoryEmpty => 'ఇన్వెంటరీ అంశాలు ఏవీ కనుగొనబడలేదు';

  @override
  String inventoryNoMatches(String query) {
    return '\"$query\" కోసం సరిపోలికలు లేవు';
  }

  @override
  String inventoryProductShort(String id) {
    return 'ఉత్పత్తి $id';
  }

  @override
  String get inventoryBelowThreshold => 'పరిమితి కంటే తక్కువ';

  @override
  String get inventoryInStock => 'స్టాక్‌లో ఉంది';

  @override
  String get inventoryUnitsLabel => 'యూనిట్లు';

  @override
  String get inventoryTotalQuantity => 'మొత్తం పరిమాణం';

  @override
  String get inventoryLowStockThreshold => 'తక్కువ స్టాక్ పరిమితి';

  @override
  String inventoryQtyUnits(int count) {
    return '$count యూనిట్లు';
  }

  @override
  String get inventoryBatchLedgerHint =>
      'పూర్తి బ్యాచ్ లెడ్జర్ చూడటానికి \"స్టాక్ కదలిక\" నొక్కండి.';

  @override
  String get inventoryLowStockBadge => 'తక్కువ స్టాక్';

  @override
  String get tasksTitle => 'పనులు';

  @override
  String get tasksTabMine => 'నా పనులు';

  @override
  String get tasksTabAll => 'అన్నీ';

  @override
  String get tasksNewTask => 'కొత్త పని';

  @override
  String get tasksEmptyTitle => 'ఇక్కడ పనులు లేవు';

  @override
  String get tasksEmptyBody => 'ఈ వీక్షణకు కేటాయించిన పనులు ఇక్కడ కనిపిస్తాయి.';

  @override
  String get tasksLoadError => 'పనులను లోడ్ చేయడం విఫలమైంది';

  @override
  String get taskEvidence => 'సాక్ష్యం';

  @override
  String get priorityHigh => 'అధిక';

  @override
  String get priorityMedium => 'మధ్యస్థ';

  @override
  String get priorityLow => 'తక్కువ';

  @override
  String get priorityUrgent => 'అత్యవసరం';

  @override
  String get taskStatusOpen => 'తెరిచి ఉంది';

  @override
  String get taskStatusPending => 'పెండింగ్‌లో';

  @override
  String get taskStatusInProgress => 'పురోగతిలో ఉంది';

  @override
  String get taskStatusCompleted => 'పూర్తయింది';

  @override
  String get taskStatusCancelled => 'రద్దు చేయబడింది';

  @override
  String get scanTitle => 'ఉత్పత్తిని స్కాన్ చేయండి';

  @override
  String get scanAlignHint => 'బార్‌కోడ్‌ను ఫ్రేమ్‌లో సరిచేయండి';

  @override
  String get scanBatchHint =>
      'బ్యాచ్ మోడ్ — స్కాన్ చేస్తూ ఉండండి, అంశాలు ఆటోమేటిక్‌గా జోడించబడతాయి';

  @override
  String scanBatchAdded(String code, int count) {
    return '$code జోడించబడింది · $count స్కాన్ చేయబడ్డాయి';
  }

  @override
  String scanBatchDone(int count) {
    return 'పూర్తయింది · $count';
  }

  @override
  String get scanLabelAction => 'లేబుల్ స్కాన్';

  @override
  String get scanGalleryAction => 'గ్యాలరీ';

  @override
  String get scanEnterManually => 'మాన్యువల్‌గా నమోదు చేయండి';

  @override
  String get scanBulkAudit => 'బల్క్ ఆడిట్';

  @override
  String get scanHistoryAction => 'చరిత్ర';

  @override
  String get scanFlash => 'ఫ్లాష్';

  @override
  String get scanTroubleTitle => 'స్కాన్ చేయడంలో సమస్యా?';

  @override
  String get scanTroubleBody =>
      'తక్కువ వెలుతురు లేదా దెబ్బతిన్న బార్‌కోడా? ఫ్లాష్ ఆన్ చేయండి, లేదా బదులుగా లేబుల్ చదవండి.';

  @override
  String get scanGalleryNoBarcode =>
      'బార్‌కోడ్ కనుగొనబడలేదు. చిట్కా: పదార్థాలను చదవడానికి \'లేబుల్ స్కాన్\' ఉపయోగించండి.';

  @override
  String get scanInvalidEan =>
      'చెల్లుబాటు అయ్యే EAN-8, EAN-13, లేదా UPC-A కోడ్‌ను నమోదు చేయండి';

  @override
  String get scanWebTitle => 'స్కాన్';

  @override
  String get scanWebUnavailable =>
      'వెబ్‌లో కెమెరా స్కానింగ్ అందుబాటులో లేదు.\nబార్‌కోడ్‌ను మాన్యువల్‌గా నమోదు చేయండి:';

  @override
  String get scanEanFieldLabel => 'EAN / UPC కోడ్';

  @override
  String get scanEanHintExample => 'ఉదా. 5901234123457';

  @override
  String get scanLookUp => 'వెతకండి';

  @override
  String get scanEnterBarcode => 'బార్‌కోడ్‌ను నమోదు చేయండి';

  @override
  String get scanHistoryTitle => 'స్కాన్ చరిత్ర';

  @override
  String get scanNoHistory => 'ఈ సెషన్‌లో ఇంకా స్కాన్‌లు లేవు.';

  @override
  String get homeGreetingMorning => 'శుభోదయం';

  @override
  String get homeGreetingAfternoon => 'శుభ మధ్యాహ్నం';

  @override
  String get homeGreetingEvening => 'శుభ సాయంత్రం';

  @override
  String get homeGreetingFallbackName => 'మిత్రమా';

  @override
  String get homeTrialEnded =>
      'ఉచిత ట్రయల్ ముగిసింది — యాక్సెస్ కొనసాగించడానికి అప్‌గ్రేడ్ చేయండి';

  @override
  String homeTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days రోజులు',
      one: '1 రోజు',
    );
    return 'ఉచిత ట్రయల్ · $_temp0 మిగిలి ఉంది';
  }

  @override
  String get homeUpgradeArrow => 'అప్‌గ్రేడ్ →';

  @override
  String get homeKpiSaved => 'సేవ్ చేసినవి';

  @override
  String get homeKpiNearExpiry => 'త్వరలో గడువు';

  @override
  String get homeKpiRecallAlerts => 'రీకాల్ హెచ్చరికలు';

  @override
  String get homeKpiOpenTasks => 'తెరిచిన పనులు';

  @override
  String get homeKpiLowStock => 'తక్కువ స్టాక్';

  @override
  String get homeEyebrowFoodSafety => 'ఆహార భద్రత హెచ్చరిక';

  @override
  String get homeEyebrowToday => 'నేటి పని';

  @override
  String get homeEyebrowHealthScan => 'మీ హెల్త్ స్కాన్';

  @override
  String get homeEyebrowScanToLearn => 'స్కాన్ చేసి తెలుసుకోండి';

  @override
  String get homeEyebrowAllClear => 'అంతా సవ్యంగా ఉంది';

  @override
  String homeStoryRecall(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count రీకాల్ చేయబడిన ఉత్పత్తులు — మీ ఇంట్లో ఏముందో చూడండి',
      one: '1 రీకాల్ చేయబడిన ఉత్పత్తి — మీ ఇంట్లో ఏముందో చూడండి',
    );
    return '$_temp0';
  }

  @override
  String homeStoryNearExpiryConsumer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count సేవ్ చేసిన అంశాలు ఈ వారం గడువు ముగుస్తాయి — వాడేయండి',
      one: '1 సేవ్ చేసిన అంశం ఈ వారం గడువు ముగుస్తుంది — వాడేయండి',
    );
    return '$_temp0';
  }

  @override
  String get homeStoryKnowWhatYouEat => 'మీరు తినేది తెలుసుకోండి';

  @override
  String get homeStoryScanInside =>
      'ఏదైనా ఆహార బార్‌కోడ్‌పై కెమెరా ఉంచండి — లోపల ఏముందో చూడండి';

  @override
  String homeStoryNearExpiryBusiness(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count అంశాలు త్వరలో గడువు — షెల్ఫ్ క్లియర్ చేయండి',
      one: '1 అంశం త్వరలో గడువు — షెల్ఫ్ క్లియర్ చేయండి',
    );
    return '$_temp0';
  }

  @override
  String homeStoryOpenTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count పనులకు ఈ రోజు మీరు అవసరం',
      one: '1 పనికి ఈ రోజు మీరు అవసరం',
    );
    return '$_temp0';
  }

  @override
  String homeStoryLowStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count అంశాల స్టాక్ తక్కువగా ఉంది',
      one: '1 అంశం స్టాక్ తక్కువగా ఉంది',
    );
    return '$_temp0';
  }

  @override
  String get homeStoreToday => 'ఇదిగో ఈ రోజు మీ స్టోర్';

  @override
  String get homeStoreAllGood => 'శభాష్! మీ స్టోర్ ఈ రోజు చక్కటి స్థితిలో ఉంది';

  @override
  String get homeCtaViewRecallAlerts => 'రీకాల్ హెచ్చరికలను చూడండి';

  @override
  String get homeCtaCheckExpiry => 'గడువును చూడండి';

  @override
  String get homeCtaOpenExpiry => 'గడువును తెరవండి';

  @override
  String get homeCtaViewTasks => 'పనులను చూడండి';

  @override
  String get homeCtaCheckInventory => 'ఇన్వెంటరీని చూడండి';

  @override
  String get homeCtaOpenTasks => 'పనులను తెరవండి';

  @override
  String get homeCtaRunAudit => 'ఒక శీఘ్ర ఆడిట్ అమలు చేయండి';

  @override
  String get homeQuickActions => 'శీఘ్ర చర్యలు';

  @override
  String get homeQuickScan => 'స్కాన్';

  @override
  String get homeQuickShopping => 'షాపింగ్';

  @override
  String get homeQuickAddExpiry => 'గడువు జోడించండి';

  @override
  String get homeQuickNewTask => 'కొత్త పని';

  @override
  String get homeRecentTasks => 'ఇటీవలి పనులు';

  @override
  String get homeSeeAll => 'అన్నీ చూడండి';

  @override
  String get homeNoOpenTasks => 'తెరిచిన పనులు లేవు — ఒకటి సృష్టించండి';

  @override
  String homeTaskAssignedTo(String name) {
    return '$name కి కేటాయించబడింది';
  }

  @override
  String get homeTaskOverdue => 'గడువు మించింది';

  @override
  String get homeTaskDueToday => 'ఈ రోజు గడువు';

  @override
  String get homeTaskDueTomorrow => 'రేపు గడువు';

  @override
  String homeTaskDueInDays(int days) {
    return '$days రోజుల్లో గడువు';
  }

  @override
  String homeTaskDueOn(String date) {
    return 'గడువు $date';
  }

  @override
  String get homeHowHelps => 'RADHA మీకు ఎలా సహాయపడుతుంది';

  @override
  String get homeScanBarcodeTitle => 'ఏదైనా ఆహార బార్‌కోడ్‌ను స్కాన్ చేయండి';

  @override
  String get homeScanBarcodeBody =>
      'హెల్త్ రేటింగ్, పదార్థాలు, దేని గురించి జాగ్రత్త వహించాలి — అన్నీ చూడండి.';

  @override
  String get homeRecallTitle => 'భద్రతా రీకాల్ హెచ్చరికలు';

  @override
  String get homeRecallBody =>
      'రీకాల్ చేయబడిన ఆహార ఉత్పత్తుల గురించి తెలుసుకోండి.';

  @override
  String get homePromoKnowFoodEyebrow => 'మీ ఆహారాన్ని తెలుసుకోండి';

  @override
  String get homePromoKnowFoodHeadline =>
      'లేబుల్ స్కాన్ చేయండి — నిజంగా లోపల ఏముందో చూడండి';

  @override
  String get homePromoKnowFoodCta => 'స్కాన్ చేసి తెలుసుకోండి';

  @override
  String get homePromoExpiryEyebrow => 'ఏ తేదీని మిస్ కాకండి';

  @override
  String get homePromoExpiryHeadline => 'ప్రతి గడువును జారిపోకముందే పట్టుకోండి';

  @override
  String get homePromoExpiryCta => 'గడువును ట్రాక్ చేయండి';

  @override
  String get homePromoFestiveEyebrow => 'పండుగ ఎంపికలు';

  @override
  String get homePromoFestiveHeadline =>
      'సీజన్‌ను ఆరోగ్యకరమైన మార్గంలో షాపింగ్ చేయండి';

  @override
  String get homePromoFestiveCta => 'ఉత్పత్తులను బ్రౌజ్ చేయండి';

  @override
  String get homePromoBazaarEyebrow => 'నేటి బజార్';

  @override
  String get homePromoBazaarHeadline => 'నిమిషాల్లో మీ షెల్ఫ్‌లను ఆడిట్ చేయండి';

  @override
  String get homePromoBazaarCta => 'ఆడిట్ ప్రారంభించండి';

  @override
  String get homeShopByCategory => 'వర్గం వారీగా షాపింగ్ చేయండి';

  @override
  String get homeShopByCategorySubtitle =>
      'స్కాన్ చేయడానికి లేదా బ్రౌజ్ చేయడానికి ఒక విభాగాన్ని నొక్కండి';

  @override
  String get onboardingWelcomeValue =>
      'స్కాన్ చేయండి, ట్రాక్ చేయండి, మీ స్టాక్‌ను ఆడిట్ చేయండి — స్ప్రెడ్‌షీట్‌లు లేకుండా.';

  @override
  String get onboardingCapabilitiesTitle =>
      'షాప్ ఫ్లోర్ కోసం రూపొందించబడింది,\nబ్యాక్ ఆఫీస్ కోసం కాదు.';

  @override
  String get onboardingCapScanTitle =>
      'ఒక్క ట్యాప్‌లో ఉత్పత్తులను స్కాన్ చేయండి';

  @override
  String get onboardingCapScanBody =>
      'హెల్త్ మరియు ఆమోదం ముందుగా తనిఖీ చేయబడిన EAN లుకప్.';

  @override
  String get onboardingCapExpiryTitle =>
      'మీకు నష్టం కలిగించక ముందే గడువును పట్టుకోండి';

  @override
  String get onboardingCapExpiryBody =>
      'OCR-సహాయక తేదీలు మరియు వర్గం వారీ పరిమితులు.';

  @override
  String get onboardingCapAuditTitle =>
      'బృందం పూర్తి చేయగల ఆడిట్‌లను అమలు చేయండి';

  @override
  String get onboardingCapAuditBody =>
      'పనులు, సాక్ష్యం మరియు బల్క్ స్కాన్ సెషన్‌లు.';

  @override
  String get onboardingSegmentTitle => 'మీరు ఇక్కడ ఎవరిగా ఉన్నారు?';

  @override
  String get onboardingSegmentSubtitle =>
      'దగ్గరగా సరిపోయేదాన్ని ఎంచుకోండి. తర్వాత సెట్టింగ్‌లలో మార్చవచ్చు.';

  @override
  String get segmentPersonalTitle => 'వ్యక్తిగత';

  @override
  String get segmentPersonalBody => 'నా కోసమే షాపింగ్';

  @override
  String get segmentParentTitle => 'తల్లిదండ్రి';

  @override
  String get segmentParentBody => 'నా కుటుంబం / పిల్లల కోసం షాపింగ్';

  @override
  String get segmentBusinessTitle => 'వ్యాపార యజమాని';

  @override
  String get segmentBusinessBody => 'నేను ఒక చిన్న రిటైల్ స్టోర్ నడుపుతున్నాను';

  @override
  String get segmentPharmacyTitle => 'ఫార్మసీ';

  @override
  String get segmentPharmacyBody => 'నేను ఫార్మసీ / కెమిస్ట్ నడుపుతున్నాను';

  @override
  String get segmentInstitutionTitle => 'సంస్థ';

  @override
  String get segmentInstitutionBody => 'పాఠశాల / హాస్టల్ / క్యాంటీన్';

  @override
  String get segmentAuditorTitle => 'ఆడిటర్ (ఆహ్వానించబడిన)';

  @override
  String get segmentAuditorBody => 'నా దగ్గర ఆహ్వాన కోడ్ ఉంది';

  @override
  String get allergenTitle => 'అలెర్జెన్‌లు';

  @override
  String get allergenLoadError => 'మీ అలెర్జెన్ ప్రొఫైల్‌ను లోడ్ చేయలేకపోయాం.';

  @override
  String get allergenHeading => 'మీ అలెర్జెన్‌లు';

  @override
  String get allergenIntro =>
      'మీకు అలెర్జీ కలిగించే వాటిని నొక్కండి. స్కాన్ చేసిన ఉత్పత్తిలో అవి ఉంటే మేము మిమ్మల్ని హెచ్చరిస్తాం.';

  @override
  String allergenTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count అలెర్జెన్‌లు ట్రాక్ చేయబడ్డాయి',
      one: '1 అలెర్జెన్ ట్రాక్ చేయబడింది',
    );
    return '$_temp0';
  }

  @override
  String get allergenNoneTracked => 'ఇంకా అలెర్జెన్‌లు ఏవీ ట్రాక్ చేయబడలేదు';

  @override
  String get allergenSavedCleared => 'అలెర్జెన్ ప్రొఫైల్ క్లియర్ చేయబడింది.';

  @override
  String get allergenSaved => 'అలెర్జెన్ ప్రొఫైల్ సేవ్ చేయబడింది.';

  @override
  String get allergenSaveError => 'మీ అలెర్జెన్‌లను సేవ్ చేయలేకపోయాం.';

  @override
  String get allergenPeanut => 'వేరుశెనగ';

  @override
  String get allergenTreeNut => 'చెట్టు గింజలు';

  @override
  String get allergenDairy => 'పాల ఉత్పత్తులు';

  @override
  String get allergenEggs => 'గుడ్లు';

  @override
  String get allergenSoy => 'సోయా';

  @override
  String get allergenWheat => 'గోధుమ';

  @override
  String get allergenFish => 'చేప';

  @override
  String get allergenShellfish => 'షెల్‌ఫిష్';

  @override
  String get allergenSesame => 'నువ్వులు';

  @override
  String get allergenGluten => 'గ్లూటెన్';

  @override
  String get allergenMustard => 'ఆవాలు';

  @override
  String get allergenCelery => 'సెలెరీ';

  @override
  String get allergenLupin => 'లుపిన్';

  @override
  String get allergenMolluscs => 'మొలస్క్‌లు';

  @override
  String get allergenSulphites => 'సల్ఫైట్‌లు';

  @override
  String get homePromoPlusHeadline =>
      '???????? ????? ??????????, ????????? ??????????? ???????? ??????';
}
