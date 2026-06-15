// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get subTitle => 'சந்தா';

  @override
  String get subUnlockHeadline => 'RADHA-வின் முழுமையான பார்வையைத் திறக்கவும்';

  @override
  String get subLoadError => 'உங்கள் சந்தாவை ஏற்ற முடியவில்லை';

  @override
  String get subErrorBody =>
      'உங்கள் இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get subChoosePlan => 'ஒரு திட்டத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get subPlansLoadError => 'திட்டங்களை ஏற்ற முடியவில்லை';

  @override
  String get subPlansUnavailable =>
      'இப்போது திட்டங்கள் எதுவும் கிடைக்கவில்லை. பிறகு மீண்டும் முயற்சிக்கவும்.';

  @override
  String get subSecurePayment => 'Razorpay மூலம் பாதுகாப்பான கட்டணம்';

  @override
  String get subCurrentPlan => 'தற்போதைய திட்டம்';

  @override
  String subRenewsInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days நாட்களில் புதுப்பிக்கப்படும்',
      one: '1 நாளில் புதுப்பிக்கப்படும்',
    );
    return '$_temp0';
  }

  @override
  String get subBillingMonthly => 'மாதந்தோறும்';

  @override
  String get subBillingYearly => 'ஆண்டுதோறும்';

  @override
  String get subBilledYearly => 'ஆண்டுக் கட்டணம்';

  @override
  String get subPerMonth => '/மாதம்';

  @override
  String get subPerYear => '/ஆண்டு';

  @override
  String get subPopular => 'பிரபலம்';

  @override
  String get subStatusTrial => 'சோதனை';

  @override
  String subStatusDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days நாட்கள் மீதம்',
      one: '1 நாள் மீதம்',
    );
    return '$_temp0';
  }

  @override
  String get subStatusActive => 'செயலில்';

  @override
  String get subStatusPastDue => 'நிலுவை';

  @override
  String get subStatusPaused => 'இடைநிறுத்தப்பட்டது';

  @override
  String get subStatusCancelled => 'ரத்து செய்யப்பட்டது';

  @override
  String subUpgradeTo(String plan) {
    return '$plan-க்கு மேம்படுத்தவும்';
  }

  @override
  String subChoosePlanNamed(String plan) {
    return '$plan தேர்ந்தெடுக்கவும்';
  }

  @override
  String subYoureOnPlan(String plan) {
    return 'நீங்கள் $plan இல் உள்ளீர்கள்';
  }

  @override
  String subWelcome(String plan) {
    return 'நீங்கள் $plan இல் உள்ளீர்கள். RADHA $plan-க்கு வரவேற்கிறோம்!';
  }

  @override
  String get subCheckoutCancelled =>
      'செக்அவுட் ரத்து செய்யப்பட்டது — உங்கள் திட்டம் மாறவில்லை.';

  @override
  String subPaymentPending(String supportRef) {
    return 'கட்டணம் பெறப்பட்டது — இப்போது உறுதிசெய்யப்படுகிறது. குறிப்பு $supportRef. சிறிது நேரத்தில் புதுப்பிக்கக் கீழே இழுக்கவும்.';
  }

  @override
  String get subPaymentFailed =>
      'கட்டணம் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get catalogSearchBarHint => 'உங்களுக்கு ஏற்ற தயாரிப்பைத் தேடுங்கள்';

  @override
  String get catalogSearchHint => 'தயாரிப்பு அல்லது பிராண்டைத் தேடுங்கள்';

  @override
  String get catalogSearchClear => 'அழி';

  @override
  String get catalogNoMatchesTitle => 'பொருத்தம் இல்லை';

  @override
  String catalogNoMatchesBody(String query) {
    return '“$query” க்கான தயாரிப்புகள் கிடைக்கவில்லை. வேறு பெயரை முயற்சிக்கவும், அல்லது பொருளை ஸ்கேன் செய்யவும்.';
  }

  @override
  String get catalogScanProduct => 'தயாரிப்பை ஸ்கேன் செய்யவும்';

  @override
  String get catalogFindTitle => 'தயாரிப்பைக் கண்டறியவும்';

  @override
  String get catalogFindBody =>
      'அதன் ஹெல்த் மதிப்பீடு மற்றும் உள்ளடக்கத்தைக் காண தயாரிப்பு பெயர் அல்லது பிராண்டைத் தேடுங்கள்.';

  @override
  String get catalogProductsFallback => 'தயாரிப்புகள்';

  @override
  String get catalogLoadErrorTitle => 'தயாரிப்புகளை ஏற்ற முடியவில்லை';

  @override
  String catalogLoadErrorBody(String category) {
    return '$category ஏற்றுவதில் சிக்கல். மீண்டும் முயற்சிக்கவும்.';
  }

  @override
  String get catalogSourceOffline =>
      'ஆஃப்லைன் — சேமித்த பட்டியலைக் காட்டுகிறோம்';

  @override
  String get catalogSourceUnavailable =>
      'நேரடி பட்டியல் கிடைக்கவில்லை — சேமித்த பட்டியலைக் காட்டுகிறோம்';

  @override
  String get catalogRetry => 'மீண்டும்';

  @override
  String get catalogSortHealthiest => 'ஆரோக்கியமானது';

  @override
  String get catalogSortAZ => 'பெயர் வரிசை';

  @override
  String get catalogVegOnly => 'சைவம் மட்டும்';

  @override
  String get catalogVeg => 'சைவம்';

  @override
  String get catalogNoVegTitle => 'இங்கே இன்னும் சைவ பொருட்கள் இல்லை';

  @override
  String catalogNoVegBody(String category) {
    return '$category இல் இப்போது சைவ வடிகட்டிக்கு எதுவும் பொருந்தவில்லை.';
  }

  @override
  String get catalogShowAll => 'அனைத்தையும் காட்டு';

  @override
  String get catalogNoProductsTitle => 'இன்னும் தயாரிப்புகள் இல்லை';

  @override
  String catalogNoProductsBody(String category) {
    return '$category பிரிவை நிரப்பி வருகிறோம். அதுவரை, எந்தப் பொருளையும் ஸ்கேன் செய்து அதன் ஆரோக்கியம் மற்றும் காலாவதியைச் சரிபார்க்கவும்.';
  }

  @override
  String get catalogFeaturedTitle => 'சிறப்பு தயாரிப்புகள்';

  @override
  String get catalogHealthyPicksTitle => 'ஆரோக்கியத் தேர்வுகள்';

  @override
  String get catalogDetailProductFallback => 'தயாரிப்பு';

  @override
  String get catalogDetailTitle => 'தயாரிப்பு';

  @override
  String get catalogDetailShareTooltip => 'பகிர்';

  @override
  String get catalogDetailSeeHealthierOptions =>
      'ஆரோக்கியமான மாற்றுகளைப் பார்க்கவும்';

  @override
  String get catalogDetailSavedSnackbar =>
      'சேமிக்கப்பட்டது — இது ஒருநாள் ரீகால் செய்யப்பட்டால் நாங்கள் எச்சரிப்போம்.';

  @override
  String get catalogDetailSaveFailedSnackbar =>
      'சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String catalogDetailShareRating(String rating, String label) {
    return ' — RADHA ஆரோக்கிய மதிப்பீடு $rating/5 ($label)';
  }

  @override
  String catalogDetailShareText(String productName, String ratingSummary) {
    return 'RADHA-வில் \"$productName\" சரிபார்க்கப்பட்டது$ratingSummary.';
  }

  @override
  String get catalogDetailSavedTooltip => 'சேமிக்கப்பட்டது';

  @override
  String get catalogDetailHealthPendingTitle =>
      'ஆரோக்கிய மதிப்பீடு இன்னும் வரவில்லை';

  @override
  String get catalogDetailHealthPendingBody =>
      'இந்த தயாரிப்பை ஸ்கேன் செய்து அதன் முழு ஆரோக்கிய பகுப்பாய்வை RADHA-வில் பெறுங்கள்.';

  @override
  String get catalogDetailHealthRatingLabel => 'RADHA ஆரோக்கிய மதிப்பீடு';

  @override
  String get catalogDetailHealthExcellent => 'சிறந்தது';

  @override
  String get catalogDetailHealthGood => 'நன்று';

  @override
  String get catalogDetailHealthFair => 'சராசரி';

  @override
  String get catalogDetailHealthPoor => 'பலவீனம்';

  @override
  String get catalogDetailHealthAvoid => 'தவிர்க்கவும்';

  @override
  String get catalogDetailInsightHighProtein => 'அதிக புரதம்';

  @override
  String get catalogDetailInsightGoodFibre => 'நல்ல நார்ச்சத்து';

  @override
  String get catalogDetailInsightMinimallyProcessed =>
      'குறைவாக செயலாக்கப்பட்டது';

  @override
  String get catalogDetailConcernHighSugar => 'அதிக சர்க்கரை';

  @override
  String get catalogDetailConcernHighSaturatedFat =>
      'அதிக செறிவூட்டப்பட்ட கொழுப்பு';

  @override
  String get catalogDetailConcernHighSodium => 'அதிக சோடியம்';

  @override
  String get catalogDetailConcernUltraProcessed => 'அல்ட்ரா-செயலாக்கப்பட்டது';

  @override
  String get catalogDetailConcernContainsTransFat => 'டிரான்ஸ் கொழுப்பு உள்ளது';

  @override
  String get catalogDetailConcernContainsAllergens => 'ஒவ்வாமை தூண்டிகள் உள்ளன';

  @override
  String get catalogDetailLikeHeading => 'உங்களுக்கு பிடிக்கும் அம்சங்கள்';

  @override
  String get catalogDetailConcernHeading => 'கவனிக்க வேண்டியவை';

  @override
  String get catalogDetailNutritionSourceNote =>
      'தயாரிப்பின் உண்மையான ஊட்டச்சத்து தரவை அடிப்படையாகக் கொண்டது (100 கிராமுக்கு).';

  @override
  String get catalogDetailKeyNutrients => 'முக்கிய ஊட்டச்சத்துகள்';

  @override
  String get catalogDetailNutrientProtein => 'புரதம்';

  @override
  String get catalogDetailNutrientTotalSugars => 'மொத்த சர்க்கரை';

  @override
  String get catalogDetailNutrientEnergy => 'ஆற்றல்';

  @override
  String get catalogDetailAllNutrients => 'அனைத்து ஊட்டச்சத்துகள்';

  @override
  String get catalogDetailNutrientTotalFat => 'மொத்த கொழுப்பு';

  @override
  String get catalogDetailNutrientSaturatedFat => 'செறிவூட்டப்பட்ட கொழுப்பு';

  @override
  String get catalogDetailNutrientCarbohydrates => 'கார்போஹைட்ரேட்டுகள்';

  @override
  String get catalogDetailNutrientFibre => 'நார்ச்சத்து';

  @override
  String get catalogDetailNutrientSodium => 'சோடியம்';

  @override
  String get catalogDetailPer100g => '100 கிராமுக்கு';

  @override
  String get catalogDetailPer50g => '50 கிராமுக்கு';

  @override
  String get catalogDetailRdaNote =>
      'குறிப்பு தினசரி உட்கொள்ளலின் % (வயது வந்தோர்).';

  @override
  String get catalogDetailRadhaPlus => 'RADHA Plus';

  @override
  String get catalogDetailForYou => 'உங்களுக்காக';

  @override
  String get catalogDetailIngredientDeepDiveTitle =>
      'சேர்வுப் பொருள் விரிவாய்வு';

  @override
  String get catalogDetailIngredientDeepDiveLockedBody =>
      'ஒவ்வொரு சேர்வையும் பாதுகாப்பு கருத்துடன் புரிந்து கொள்ளுங்கள் — அது என்ன, ஏன் சேர்க்கப்பட்டது, கவலைப்பட வேண்டுமா என்பதும்.';

  @override
  String get catalogDetailIngredientExplainError =>
      'இந்த சேர்வுகளை இப்போது விளக்க முடியவில்லை.';

  @override
  String get catalogDetailIngredientNeedsLabel =>
      'மூலப்பொருள் விவரத்திற்கு தெளிவான லேபிள் படம் தேவை. பேக் லேபிளை ஸ்கேன் செய்தால் RADHA உண்மையான மூலப்பொருள் பட்டியலை விளக்கும்.';

  @override
  String get catalogDetailPersonalisedFlagsTitle => 'தனிப்பயன் எச்சரிக்கைகள்';

  @override
  String get catalogDetailPersonalisedFlagsLockedBody =>
      'இந்த தயாரிப்பை உங்கள் சேமித்த ஒவ்வாமைகள் மற்றும் ஆரோக்கிய இலக்குகளுடன் ஒப்பிடுங்கள் — உங்களுக்கு சரியா தவறா என்பதை நாங்கள் காட்டுவோம்.';

  @override
  String get catalogDetailPersonaliseError =>
      'இதை இப்போது தனிப்பயனாக்க முடியவில்லை.';

  @override
  String get catalogDetailNoAllergensDetected =>
      'இந்த தயாரிப்பில் ஒவ்வாமை தூண்டிகள் கண்டறியப்படவில்லை.';

  @override
  String get catalogDetailAllergenSignalDetected =>
      'இந்த தயாரிப்பில் சாத்தியமான அலர்ஜன் தகவல் உள்ளது. வாங்குவதற்கு முன் லேபிளைச் சரிபார்க்கவும்.';

  @override
  String get catalogDetailAllergenSignalUnavailable =>
      'அலர்ஜன் விவரம் இன்னும் இந்த தயாரிப்பு பதிவில் இல்லை. பாதுகாப்பாக தனிப்பயனாக்க லேபிளை ஸ்கேன் செய்யவும்.';

  @override
  String catalogDetailAllergenAvoided(String allergen) {
    return '$allergen — இதை நீங்கள் தவிர்க்கிறீர்கள்';
  }

  @override
  String catalogDetailUnlockWithPlan(String plan) {
    return '$plan மூலம் திறக்கவும்';
  }

  @override
  String get catalogDetailWouldBuyQuestion =>
      'இந்த தயாரிப்பை நீங்கள் வாங்குவீர்களா?';

  @override
  String get catalogDetailWouldBuyThanks => 'பகிர்ந்ததற்கு நன்றி!';

  @override
  String get catalogDetailWouldBuyYes => 'ஆம்';

  @override
  String get catalogDetailWouldBuyNo => 'இல்லை';

  @override
  String get catalogDetailWouldBuyAlreadyBought => 'ஏற்கனவே வாங்கியது';

  @override
  String get catalogDetailNutritionNotFoundTitle =>
      'இந்த பதிவு இன்னும் எங்களிடம் இல்லை';

  @override
  String get catalogDetailNutritionNotFoundBody =>
      'இந்த தயாரிப்பின் முழு ஊட்டச்சத்து RADHA-வில் இன்னும் இல்லை. உண்மையான தரவை பெற அதன் பார்கோடு அல்லது லேபிளை ஸ்கேன் செய்யுங்கள்.';

  @override
  String get catalogDetailNutritionOfflineTitle =>
      'நீங்கள் ஆஃப்லைனில் உள்ளீர்கள்';

  @override
  String get catalogDetailNutritionOfflineBody =>
      'ஊட்டச்சத்தை ஏற்ற முடியவில்லை. மேலுள்ள தயாரிப்பு விவரங்கள் அப்படியே உள்ளன — மீண்டும் இணைந்து முயற்சிக்கவும்.';

  @override
  String get catalogDetailNutritionSessionExpiredTitle => 'அமர்வு காலாவதியானது';

  @override
  String get catalogDetailNutritionSessionExpiredBody =>
      'மீண்டும் முயற்சிக்கவும் — RADHA உங்கள் அமர்வை புதுப்பித்து மீண்டும் முயறும்.';

  @override
  String get catalogDetailNutritionAccessDeniedTitle =>
      'அணுகல் கட்டுப்படுத்தப்பட்டது';

  @override
  String get catalogDetailNutritionAccessDeniedBody =>
      'இந்த ஊட்டச்சத்து பதிவை உங்கள் கணக்கு படிக்க முடியாது. மேலுள்ள தயாரிப்பு தகவல் தொடர்ந்து கிடைக்கும்.';

  @override
  String get catalogDetailNutritionTimeoutTitle => 'கோரிக்கை நேரம் முடிந்தது';

  @override
  String get catalogDetailNutritionTimeoutBody =>
      'RADHA நேரத்தில் ஊட்டச்சத்து சேவையை அடைய முடியவில்லை. இணைப்பு நிலையாக இருக்கும் போது மீண்டும் முயற்சிக்கவும்.';

  @override
  String get catalogDetailNutritionServerTitle =>
      'ஊட்டச்சத்தை ஏற்ற முடியவில்லை';

  @override
  String get catalogDetailNutritionServerBody =>
      'விவரங்களை பெறும்போது ஏதோ தவறு நடந்தது. மேலுள்ள தயாரிப்பு தகவல் பாதிக்கப்படவில்லை.';

  @override
  String get catalogDetailScanLabel => 'லேபிளை ஸ்கேன் செய்';

  @override
  String get catalogDetailFullNutritionPendingTitle =>
      'முழு ஊட்டச்சத்து இன்னும் இல்லை';

  @override
  String get catalogDetailFullNutritionPendingBody =>
      'இந்த தயாரிப்பின் பார்கோடை ஸ்கேன் செய்து உண்மையான ஊட்டச்சத்து மற்றும் ஆரோக்கிய பகுப்பாய்வை RADHA-வில் பெறுங்கள் — ஒரு நொடி தான் ஆகும்.';

  @override
  String get catalogDetailScanToUnlock => 'திறக்க ஸ்கேன் செய்';

  @override
  String get profileSectionAccount => 'கணக்கு';

  @override
  String get profileManageStores => 'கடைகளை நிர்வகிக்கவும்';

  @override
  String get profileSectionPreferences => 'விருப்பங்கள்';

  @override
  String get profileShoppingList => 'ஷாப்பிங் பட்டியல்';

  @override
  String get profileSectionAbout => 'பற்றி';

  @override
  String get profileGuestName => 'விருந்தினர்';

  @override
  String get profileYouName => 'நீங்கள்';

  @override
  String get profileRoleMember => 'உறுப்பினர்';

  @override
  String get profileRoleOwner => 'உரிமையாளர்';

  @override
  String get profileRoleManager => 'மேலாளர்';

  @override
  String get profileRoleStaff => 'பணியாளர்';

  @override
  String get profileRoleAuditor => 'ஆடிட்டர்';

  @override
  String get profileRoleConsumer => 'நுகர்வோர்';

  @override
  String get profileRoleAdmin => 'நிர்வாகி';

  @override
  String get profileVersionLoading => 'பதிப்பு ஏற்றப்படுகிறது…';

  @override
  String get profileVersionUnavailable => 'பதிப்பு கிடைக்கவில்லை';

  @override
  String get profileSignOutConfirmBody =>
      'ஆப்பைப் பயன்படுத்த மீண்டும் OTP மூலம் உள்நுழைய வேண்டும்.';

  @override
  String get selectStoreTitle => 'கடையைத் தேர்ந்தெடுக்கவும்';

  @override
  String get selectStoreHeading => 'ஒரு கடையைத் தேர்ந்தெடுக்கவும்';

  @override
  String get selectStoreBody =>
      'இன்று நீங்கள் வேலை செய்யும் கடையைத் தேர்ந்தெடுக்கவும். பின்னர் சுயவிவரத்தில் இருந்து கடையை மாற்றலாம்.';

  @override
  String get selectStoreEmptyTitle => 'இன்னும் கடைகள் இல்லை';

  @override
  String get selectStoreEmptyBody =>
      'உங்கள் கணக்கு இன்னும் எந்த கடையுடனும் இணைக்கப்படவில்லை. அணுகலை வழங்க மேலாளரிடம் கேட்டு, பின்னர் திரும்பி வந்து ஒன்றைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get selectStoreContactManager => 'மேலாளரை தொடர்புகொள்ளவும்';

  @override
  String get selectStoreContactManagerSnackbar =>
      'ஒரு கடையில் சேர்க்கப்பட உங்கள் மேலாளரை தொடர்புகொள்ளவும்.';

  @override
  String get recallTitle => 'மீட்பு எச்சரிக்கைகள்';

  @override
  String get recallLoadError => 'மீட்புகளை ஏற்ற முடியவில்லை.';

  @override
  String get recallEmptyTitle => 'செயலில் மீட்புகள் இல்லை';

  @override
  String get recallEmptyBody =>
      'ஒழுங்குமுறை அமைப்புகள் தயாரிப்பு மீட்புகளை வெளியிடும்போது அவை இங்கே தோன்றும்.';

  @override
  String recallProductFallback(String id) {
    return 'தயாரிப்பு $id';
  }

  @override
  String recallRecalledOn(String date) {
    return '$date அன்று மீட்கப்பட்டது';
  }

  @override
  String get recallViewProduct => 'தயாரிப்பைக் காண்க';

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
}
