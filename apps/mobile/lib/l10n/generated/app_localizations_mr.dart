// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get subTitle => 'सदस्यता';

  @override
  String get subUnlockHeadline => 'RADHA चे संपूर्ण चित्र अनलॉक करा';

  @override
  String get subLoadError => 'तुमची सदस्यता लोड करता आली नाही';

  @override
  String get subErrorBody => 'तुमचे कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.';

  @override
  String get subChoosePlan => 'एक प्लॅन निवडा';

  @override
  String get subPlansLoadError => 'प्लॅन लोड करता आले नाहीत';

  @override
  String get subPlansUnavailable =>
      'सध्या कोणतेही प्लॅन उपलब्ध नाहीत. कृपया नंतर पुन्हा प्रयत्न करा.';

  @override
  String get subSecurePayment => 'Razorpay द्वारे सुरक्षित पेमेंट';

  @override
  String get subCurrentPlan => 'सध्याचा प्लॅन';

  @override
  String subRenewsInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिवसांत नूतनीकरण',
      one: '1 दिवसात नूतनीकरण',
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
  String get subPerMonth => '/महिना';

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
      other: '$days दिवस शिल्लक',
      one: '1 दिवस शिल्लक',
    );
    return '$_temp0';
  }

  @override
  String get subStatusActive => 'सक्रिय';

  @override
  String get subStatusPastDue => 'थकबाकी';

  @override
  String get subStatusPaused => 'थांबवले';

  @override
  String get subStatusCancelled => 'रद्द';

  @override
  String subUpgradeTo(String plan) {
    return '$plan मध्ये अपग्रेड करा';
  }

  @override
  String subChoosePlanNamed(String plan) {
    return '$plan निवडा';
  }

  @override
  String subYoureOnPlan(String plan) {
    return 'तुम्ही $plan वर आहात';
  }

  @override
  String subWelcome(String plan) {
    return 'तुम्ही $plan वर आहात. RADHA $plan मध्ये स्वागत आहे!';
  }

  @override
  String get subCheckoutCancelled => 'चेकआउट रद्द केले — तुमचा प्लॅन तसाच आहे.';

  @override
  String subPaymentPending(String supportRef) {
    return 'पेमेंट मिळाले — आता त्याची खात्री केली जात आहे. संदर्भ $supportRef. थोड्या वेळात रिफ्रेश करण्यासाठी खाली ओढा.';
  }

  @override
  String get subPaymentFailed =>
      'पेमेंट अयशस्वी झाले. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get catalogSearchBarHint => 'तुमच्यासाठी योग्य उत्पादन शोधा';

  @override
  String get catalogSearchHint => 'उत्पादन किंवा ब्रँड शोधा';

  @override
  String get catalogSearchClear => 'साफ करा';

  @override
  String get catalogNoMatchesTitle => 'जुळणी नाही';

  @override
  String catalogNoMatchesBody(String query) {
    return 'आम्हाला “$query” साठी कोणतेही उत्पादन सापडले नाही. दुसरे नाव वापरून पहा, किंवा वस्तू स्कॅन करा.';
  }

  @override
  String get catalogScanProduct => 'उत्पादन स्कॅन करा';

  @override
  String get catalogFindTitle => 'उत्पादन शोधा';

  @override
  String get catalogFindBody =>
      'त्याचे हेल्थ रेटिंग आणि घटक पाहण्यासाठी उत्पादनाचे नाव किंवा ब्रँड शोधा.';

  @override
  String get catalogProductsFallback => 'उत्पादने';

  @override
  String get catalogLoadErrorTitle => 'उत्पादने लोड करता आली नाहीत';

  @override
  String catalogLoadErrorBody(String category) {
    return '$category लोड करताना अडचण आली. कृपया पुन्हा प्रयत्न करा.';
  }

  @override
  String get catalogSourceOffline =>
      'ऑफलाइन — तुमचा जतन केलेला कॅटलॉग दाखवत आहोत';

  @override
  String get catalogSourceUnavailable =>
      'लाइव्ह कॅटलॉग उपलब्ध नाही — जतन केलेला कॅटलॉग दाखवत आहोत';

  @override
  String get catalogRetry => 'पुन्हा';

  @override
  String get catalogSortHealthiest => 'सर्वात आरोग्यदायी';

  @override
  String get catalogSortAZ => 'नावानुसार';

  @override
  String get catalogVegOnly => 'फक्त शाकाहारी';

  @override
  String get catalogVeg => 'शाकाहारी';

  @override
  String get catalogNoVegTitle => 'इथे अजून शाकाहारी वस्तू नाहीत';

  @override
  String catalogNoVegBody(String category) {
    return '$category मध्ये सध्या शाकाहारी फिल्टरशी काहीही जुळत नाही.';
  }

  @override
  String get catalogShowAll => 'सर्व दाखवा';

  @override
  String get catalogNoProductsTitle => 'अजून उत्पादने नाहीत';

  @override
  String catalogNoProductsBody(String category) {
    return 'आम्ही $category विभाग भरत आहोत. तोपर्यंत, कोणतीही वस्तू स्कॅन करून तिचे आरोग्य आणि एक्सपायरी तपासा.';
  }

  @override
  String get catalogFeaturedTitle => 'खास उत्पादने';

  @override
  String get catalogHealthyPicksTitle => 'आरोग्यदायी निवडी';

  @override
  String get catalogDetailProductFallback => 'उत्पादन';

  @override
  String get catalogDetailTitle => 'उत्पादन';

  @override
  String get catalogDetailShareTooltip => 'शेअर करा';

  @override
  String get catalogDetailSeeHealthierOptions => 'अधिक आरोग्यदायी पर्याय पहा';

  @override
  String get catalogDetailSavedSnackbar =>
      'साठवले — हे कधी रिकॉल झाले तर आम्ही तुम्हाला कळवू.';

  @override
  String get catalogDetailSaveFailedSnackbar =>
      'साठवता आले नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String catalogDetailShareRating(String rating, String label) {
    return ' — RADHA आरोग्य रेटिंग $rating/5 ($label)';
  }

  @override
  String catalogDetailShareText(String productName, String ratingSummary) {
    return 'RADHA वर \"$productName\" तपासले$ratingSummary.';
  }

  @override
  String get catalogDetailSavedTooltip => 'साठवले';

  @override
  String get catalogDetailHealthPendingTitle => 'आरोग्य रेटिंग अजून आलेले नाही';

  @override
  String get catalogDetailHealthPendingBody =>
      'या उत्पादनाचे संपूर्ण आरोग्य विश्लेषण RADHA मध्ये आणण्यासाठी ते स्कॅन करा.';

  @override
  String get catalogDetailHealthRatingLabel => 'RADHA आरोग्य रेटिंग';

  @override
  String get catalogDetailHealthExcellent => 'उत्कृष्ट';

  @override
  String get catalogDetailHealthGood => 'चांगले';

  @override
  String get catalogDetailHealthFair => 'मध्यम';

  @override
  String get catalogDetailHealthPoor => 'कमकुवत';

  @override
  String get catalogDetailHealthAvoid => 'टाळा';

  @override
  String get catalogDetailInsightHighProtein => 'जास्त प्रोटीन';

  @override
  String get catalogDetailInsightGoodFibre => 'चांगले फायबर';

  @override
  String get catalogDetailInsightMinimallyProcessed => 'कमी प्रक्रिया केलेले';

  @override
  String get catalogDetailConcernHighSugar => 'जास्त साखर';

  @override
  String get catalogDetailConcernHighSaturatedFat => 'जास्त संतृप्त फॅट';

  @override
  String get catalogDetailConcernHighSodium => 'जास्त सोडियम';

  @override
  String get catalogDetailConcernUltraProcessed => 'अल्ट्रा-प्रोसेस्ड';

  @override
  String get catalogDetailConcernContainsTransFat => 'ट्रान्स फॅट आहे';

  @override
  String get catalogDetailConcernContainsAllergens => 'अॅलर्जन्स आहेत';

  @override
  String get catalogDetailLikeHeading => 'तुम्हाला काय आवडेल';

  @override
  String get catalogDetailConcernHeading => 'कशाकडे लक्ष द्यावे';

  @override
  String get catalogDetailNutritionSourceNote =>
      'उत्पादनाच्या खऱ्या पोषण माहितीनुसार (प्रति 100 ग्रॅम).';

  @override
  String get catalogDetailKeyNutrients => 'मुख्य पोषक घटक';

  @override
  String get catalogDetailNutrientProtein => 'प्रोटीन';

  @override
  String get catalogDetailNutrientTotalSugars => 'एकूण साखर';

  @override
  String get catalogDetailNutrientEnergy => 'ऊर्जा';

  @override
  String get catalogDetailAllNutrients => 'सर्व पोषक घटक';

  @override
  String get catalogDetailNutrientTotalFat => 'एकूण फॅट';

  @override
  String get catalogDetailNutrientSaturatedFat => 'संतृप्त फॅट';

  @override
  String get catalogDetailNutrientCarbohydrates => 'कार्बोहायड्रेट्स';

  @override
  String get catalogDetailNutrientFibre => 'फायबर';

  @override
  String get catalogDetailNutrientSodium => 'सोडियम';

  @override
  String get catalogDetailPer100g => 'प्रति 100 ग्रॅम';

  @override
  String get catalogDetailPer50g => 'प्रति 50 ग्रॅम';

  @override
  String get catalogDetailRdaNote => 'संदर्भ दैनिक सेवनाचा % (प्रौढ).';

  @override
  String get catalogDetailRadhaPlus => 'RADHA Plus';

  @override
  String get catalogDetailForYou => 'तुमच्यासाठी';

  @override
  String get catalogDetailIngredientDeepDiveTitle => 'घटकांची सखोल माहिती';

  @override
  String get catalogDetailIngredientDeepDiveLockedBody =>
      'प्रत्येक घटक सुरक्षिततेच्या मतासह समजून घ्या — तो काय आहे, का वापरला आहे, आणि काळजी करावी का.';

  @override
  String get catalogDetailIngredientExplainError =>
      'हे घटक सध्या समजावता आले नाहीत.';

  @override
  String get catalogDetailPersonalisedFlagsTitle => 'वैयक्तिक सूचना';

  @override
  String get catalogDetailPersonalisedFlagsLockedBody =>
      'हे उत्पादन तुमच्या साठवलेल्या अॅलर्जन्स आणि आरोग्य उद्दिष्टांशी जुळवा — तुमच्यासाठी काय योग्य किंवा अयोग्य आहे ते आम्ही दाखवू.';

  @override
  String get catalogDetailPersonaliseError =>
      'हे सध्या तुमच्यासाठी वैयक्तिक करता आले नाही.';

  @override
  String get catalogDetailNoAllergensDetected =>
      'या उत्पादनात कोणतेही अॅलर्जन्स आढळले नाहीत.';

  @override
  String catalogDetailAllergenAvoided(String allergen) {
    return '$allergen — तुम्ही हे टाळता';
  }

  @override
  String catalogDetailUnlockWithPlan(String plan) {
    return '$plan ने अनलॉक करा';
  }

  @override
  String get catalogDetailWouldBuyQuestion =>
      'तुम्ही हे उत्पादन खरेदी कराल का?';

  @override
  String get catalogDetailWouldBuyThanks => 'शेअर केल्याबद्दल धन्यवाद!';

  @override
  String get catalogDetailWouldBuyYes => 'हो';

  @override
  String get catalogDetailWouldBuyNo => 'नाही';

  @override
  String get catalogDetailWouldBuyAlreadyBought => 'आधीच खरेदी केले';

  @override
  String get catalogDetailNutritionNotFoundTitle =>
      'हा रेकॉर्ड अजून आमच्याकडे नाही';

  @override
  String get catalogDetailNutritionNotFoundBody =>
      'RADHA कडे या उत्पादनाची संपूर्ण पोषण माहिती अजून नाही. खरी माहिती आणण्यासाठी त्याचा बारकोड किंवा लेबल स्कॅन करा.';

  @override
  String get catalogDetailNutritionOfflineTitle => 'तुम्ही ऑफलाइन आहात';

  @override
  String get catalogDetailNutritionOfflineBody =>
      'पोषण माहिती लोड झाली नाही. वरची उत्पादन माहिती तशीच आहे — पुन्हा कनेक्ट करून प्रयत्न करा.';

  @override
  String get catalogDetailNutritionSessionExpiredTitle => 'सेशन संपले';

  @override
  String get catalogDetailNutritionSessionExpiredBody =>
      'कृपया पुन्हा प्रयत्न करा — RADHA तुमचे सेशन रीफ्रेश करून पुन्हा प्रयत्न करेल.';

  @override
  String get catalogDetailNutritionServerTitle => 'पोषण माहिती लोड झाली नाही';

  @override
  String get catalogDetailNutritionServerBody =>
      'तपशील आणताना काहीतरी चूक झाली. वरची उत्पादन माहिती प्रभावित झालेली नाही.';

  @override
  String get catalogDetailScanLabel => 'लेबल स्कॅन करा';

  @override
  String get catalogDetailFullNutritionPendingTitle =>
      'संपूर्ण पोषण माहिती अजून नाही';

  @override
  String get catalogDetailFullNutritionPendingBody =>
      'या उत्पादनाचा बारकोड स्कॅन करून खरी पोषण माहिती आणि आरोग्य विश्लेषण RADHA मध्ये आणा — फक्त एक सेकंद लागेल.';

  @override
  String get catalogDetailScanToUnlock => 'अनलॉक करण्यासाठी स्कॅन करा';

  @override
  String get profileSectionAccount => 'खाते';

  @override
  String get profileManageStores => 'स्टोअर्स व्यवस्थापित करा';

  @override
  String get profileSectionPreferences => 'प्राधान्ये';

  @override
  String get profileShoppingList => 'खरेदी यादी';

  @override
  String get profileSectionAbout => 'माहिती';

  @override
  String get profileGuestName => 'अतिथी';

  @override
  String get profileYouName => 'तुम्ही';

  @override
  String get profileRoleMember => 'सदस्य';

  @override
  String get profileRoleOwner => 'मालक';

  @override
  String get profileRoleManager => 'व्यवस्थापक';

  @override
  String get profileRoleStaff => 'स्टाफ';

  @override
  String get profileRoleAuditor => 'ऑडिटर';

  @override
  String get profileRoleConsumer => 'ग्राहक';

  @override
  String get profileRoleAdmin => 'अॅडमिन';

  @override
  String get profileVersionLoading => 'आवृत्ती लोड होत आहे…';

  @override
  String get profileVersionUnavailable => 'आवृत्ती उपलब्ध नाही';

  @override
  String get profileSignOutConfirmBody =>
      'अॅप वापरण्यासाठी तुम्हाला OTP ने पुन्हा साइन इन करावे लागेल.';

  @override
  String get selectStoreTitle => 'स्टोअर निवडा';

  @override
  String get selectStoreHeading => 'एक स्टोअर निवडा';

  @override
  String get selectStoreBody =>
      'आज तुम्ही ज्या स्टोअरमध्ये काम करत आहात ते निवडा. नंतर प्रोफाइलमधून स्टोअर बदलू शकता.';

  @override
  String get selectStoreEmptyTitle => 'अजून स्टोअर्स नाहीत';

  @override
  String get selectStoreEmptyBody =>
      'तुमचे खाते अजून कोणत्याही स्टोअरशी जोडलेले नाही. प्रवेश देण्यासाठी तुमच्या व्यवस्थापकाला सांगा, मग परत येऊन एक निवडा.';

  @override
  String get selectStoreContactManager => 'तुमच्या व्यवस्थापकाला संपर्क करा';

  @override
  String get selectStoreContactManagerSnackbar =>
      'स्टोअरमध्ये जोडण्यासाठी तुमच्या व्यवस्थापकाला संपर्क करा.';

  @override
  String get appName => 'RADHA';

  @override
  String get tagline => 'डेटा, आरोग्य आणि ऑडिटसाठी रिटेल असिस्टंट.';

  @override
  String get continueLabel => 'सुरू ठेवा';

  @override
  String get getStarted => 'सुरू करा';

  @override
  String get skip => 'वगळा';

  @override
  String get next => 'पुढे';

  @override
  String get back => 'मागे';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get save => 'जतन करा';

  @override
  String get delete => 'हटवा';

  @override
  String get edit => 'संपादन';

  @override
  String get add => 'जोडा';

  @override
  String get search => 'शोधा';

  @override
  String get loading => 'लोड होत आहे';

  @override
  String get error => 'काहीतरी चूक झाली';

  @override
  String get tryAgain => 'पुन्हा प्रयत्न करा';

  @override
  String get done => 'पूर्ण';

  @override
  String get close => 'बंद करा';

  @override
  String get signIn => 'साइन इन';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get enterOtp => 'OTP प्रविष्ट करा';

  @override
  String get verifyOtp => 'OTP सत्यापित करा';

  @override
  String get resendOtp => 'OTP पुन्हा पाठवा';

  @override
  String get otpSent => 'आम्ही तुम्हाला 6 अंकी कोड पाठवला आहे';

  @override
  String get home => 'होम';

  @override
  String get scan => 'स्कॅन';

  @override
  String get expiry => 'एक्स्पायरी';

  @override
  String get tasks => 'कामे';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get language => 'भाषा';

  @override
  String get scanProduct => 'उत्पादन स्कॅन करा';

  @override
  String get pointAtBarcode => 'तुमचा कॅमेरा बारकोडवर ठेवा';

  @override
  String get scanAgain => 'पुन्हा स्कॅन करा';

  @override
  String get productNotFound => 'उत्पादन सापडले नाही';

  @override
  String get expiryTracker => 'एक्स्पायरी ट्रॅकर';

  @override
  String get addExpiry => 'एक्स्पायरी जोडा';

  @override
  String get expiringSoon => 'लवकरच एक्स्पायर होईल';

  @override
  String get expired => 'एक्स्पायर झाले';

  @override
  String get yourTasks => 'तुमची कामे';

  @override
  String get noTasks => 'कोणतीही कामे नाहीत';

  @override
  String get completeTask => 'काम पूर्ण करा';

  @override
  String get welcome => 'स्वागत आहे';

  @override
  String get welcomeMessage =>
      'स्प्रेडशीटशिवाय तुमचा साठा स्कॅन, ट्रॅक आणि ऑडिट करा.';

  @override
  String get referrals => 'रेफरल';

  @override
  String get shareYourCode => 'तुमचा कोड शेअर करा';

  @override
  String get yourReferralCode => 'तुमचा रेफरल कोड';

  @override
  String get invitees => 'आमंत्रित';

  @override
  String get rewardsEarned => 'मिळवलेले पुरस्कार';

  @override
  String get redeemCode => 'कोड रिडीम करा';

  @override
  String get enterReferralCode => 'रेफरल कोड प्रविष्ट करा';

  @override
  String get chooseLanguage => 'भाषा निवडा';

  @override
  String get languageUpdated => 'भाषा अद्यतनित केली';

  @override
  String get errorGeneric => 'काहीतरी चूक झाली. कृपया पुन्हा प्रयत्न करा.';

  @override
  String errorRateLimitOtp(int seconds) {
    return 'खूप जास्त OTP विनंत्या. $seconds सेकंदात पुन्हा प्रयत्न करा.';
  }

  @override
  String get errorOtpInvalid => 'OTP चुकीचा आहे. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get errorOtpExpired => 'OTP ची मुदत संपली. नवीन विनंती करा.';

  @override
  String get errorAuthRequired => 'सुरू ठेवण्यासाठी साइन इन करा.';

  @override
  String get errorNotFound => 'सापडले नाही.';

  @override
  String get ingredientExplainerErrorTitle => 'स्पष्टीकरण लोड होऊ शकले नाही';

  @override
  String get ingredientExplainerHealthConsiderations => 'आरोग्य विचार';

  @override
  String healthyAlternativesTitle(String productName) {
    return '$productName पेक्षा चांगले पर्याय';
  }

  @override
  String get healthyAlternativesGenericTitle => 'चांगले पर्याय';

  @override
  String get healthyAlternativesEmptyTitle => 'अद्याप आरोग्यकारक पर्याय नाहीत';

  @override
  String get healthyAlternativesEmptyBody =>
      'त्याच श्रेणीत अद्याप आरोग्यकारक पर्याय सापडलेले नाहीत.';

  @override
  String get healthyAlternativesErrorTitle => 'पर्याय लोड होऊ शकले नाहीत';

  @override
  String get healthyAlternativesAddToList => 'खरेदी यादीत जोडा';

  @override
  String get healthyAlternativesView => 'पहा';

  @override
  String get healthyAlternativesAddedToList => 'खरेदी यादीत जोडले';

  @override
  String get healthyAlternativesAddFailed => 'खरेदी यादीत जोडता आले नाही';

  @override
  String get savedProductsTitle => 'जतन केलेली उत्पादने';

  @override
  String get savedProductsEmptyTitle => 'जतन केलेली उत्पादने';

  @override
  String get savedProductsEmptyBody =>
      'स्कॅन निकाल स्क्रीनवरून उत्पादने जतन करा म्हणजे ती येथे दिसतील.';

  @override
  String get savedProductsErrorTitle =>
      'जतन केलेली उत्पादने लोड करता आली नाहीत';

  @override
  String savedProductsSavedOn(String date) {
    return '$date रोजी जतन केले';
  }

  @override
  String get digestTitle => 'RADHA सोबत तुमचा आठवडा';

  @override
  String digestWeekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String digestSavingsHero(String amount) {
    return '₹$amount वाचवले';
  }

  @override
  String digestScansHero(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count स्कॅन्स',
      one: '1 स्कॅन',
    );
    return '$_temp0';
  }

  @override
  String get digestHeroEmptyHeadline => 'एक शांत आठवडा';

  @override
  String get digestScans => 'स्कॅन्स';

  @override
  String get digestSavedProducts => 'जतन केलेले';

  @override
  String get digestExpiringSoon => 'लवकरच एक्स्पायर';

  @override
  String digestRecallAlerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिकॉल अलर्ट्स',
      one: '1 रिकॉल अलर्ट',
    );
    return '$_temp0';
  }

  @override
  String get digestRecallAlertsBody =>
      'या आठवड्यात तुम्ही स्कॅन केलेल्या उत्पादनांसाठी नवीन सुरक्षा सूचना आहेत.';

  @override
  String get digestRecallAlertsCta => 'पाहा';

  @override
  String get digestTopCategoriesHeader => 'तुम्ही काय स्कॅन करत आहात';

  @override
  String get digestHighlightsHeader => 'ठळक मुद्दे';

  @override
  String get digestContinueScanning => 'स्कॅन सुरू ठेवा';

  @override
  String get digestShare => 'माझा आठवडा शेअर करा';

  @override
  String digestShareTemplate(int scans, String savings) {
    return 'या आठवड्यात मी $scans उत्पादने स्कॅन केली आणि RADHA सोबत ₹$savings वाचवले. तुम्हीही करून पहा: https://radha.app';
  }

  @override
  String get digestEmptyTitle => 'या आठवड्यात कोणतीही क्रिया नाही';

  @override
  String get digestEmptyBody =>
      'तुमची साप्ताहिक कथा तयार करण्यासाठी स्कॅन सुरू करा.';

  @override
  String get digestErrorTitle => 'साप्ताहिक सारांश लोड करू शकलो नाही';

  @override
  String get settingsTitle => 'सेटिंग्ज';

  @override
  String get settingsNotifications => 'सूचना';

  @override
  String get settingsPushNotifications => 'पुश सूचना';

  @override
  String get settingsPushNotificationsHint => 'तुमच्या फोनवर अलर्ट मिळवा';

  @override
  String get settingsRecallAlerts => 'रिकॉल अलर्ट';

  @override
  String get settingsRecallAlertsHint =>
      'तुम्ही स्कॅन केलेले उत्पादन रिकॉल झाल्यावर कळवा';

  @override
  String get settingsWeeklyDigest => 'साप्ताहिक सारांश';

  @override
  String get settingsWeeklyDigestHint =>
      'रविवारी तुमचे स्कॅन्स आणि बचतीचा सारांश';

  @override
  String get settingsAppearance => 'स्वरूप';

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
  String get settingsTextSizeSmall => 'लहान';

  @override
  String get settingsTextSizeStandard => 'मानक';

  @override
  String get settingsTextSizeLarge => 'मोठा';

  @override
  String get settingsDataPrivacy => 'डेटा आणि गोपनीयता';

  @override
  String get settingsAllergens => 'अॅलर्जी प्रोफाइल';

  @override
  String get settingsAllergensHint => 'ज्या घटकांची सावधगिरी हवी ती निवडा';

  @override
  String get settingsSignOutAll => 'सर्व डिव्हाइसमधून साइन आउट करा';

  @override
  String get settingsSignOutAllConfirmTitle => 'सर्वत्र साइन आउट?';

  @override
  String get settingsSignOutAllConfirmBody =>
      'हे खाते वापरणाऱ्या प्रत्येक डिव्हाइसवर तुम्हाला पुन्हा साइन इन करावे लागेल.';

  @override
  String get settingsDeleteAccount => 'खाते हटवा';

  @override
  String get settingsDeleteAccountTitle => 'खाते हटवा';

  @override
  String get settingsDeleteAccountBody =>
      'हे तुमचा डेटा कायमचा हटवेल. पुष्टी करण्यासाठी DELETE टाइप करा.';

  @override
  String get settingsDeleteAccountConfirm => 'DELETE';

  @override
  String get settingsDeleteAccountUnavailable =>
      'खाते हटवण्यासाठी सपोर्टशी संपर्क साधा.';

  @override
  String get settingsDeleteAccountContact => 'सपोर्टशी संपर्क साधा';

  @override
  String get settingsAbout => 'बद्दल';

  @override
  String get settingsTerms => 'सेवेच्या अटी';

  @override
  String get settingsPrivacyPolicy => 'गोपनीयता धोरण';

  @override
  String get settingsVersion => 'अॅप आवृत्ती';

  @override
  String settingsVersionValue(String version, String build) {
    return 'आवृत्ती $version ($build)';
  }

  @override
  String get settingsSupport => 'सपोर्ट';

  @override
  String get settingsSupportHint => 'मदत मिळवा, बग नोंदवा किंवा अभिप्राय द्या';

  @override
  String get settingsLinkOpenFailed => 'लिंक उघडता आली नाही';

  @override
  String conflictBannerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count विरोधांना तुमचे लक्ष हवे आहे',
      one: '1 विरोधाला तुमचे लक्ष हवे आहे',
    );
    return '$_temp0';
  }

  @override
  String get conflictBannerCta => 'सोडवा';

  @override
  String get conflictBannerDismiss => 'बंद करा';

  @override
  String get conflictResolveTitle => 'सिंक विरोध सोडवा';

  @override
  String get conflictResolveSubtitle =>
      'प्रत्येक आयटमसाठी कोणती आवृत्ती ठेवायची ते निवडा.';

  @override
  String get conflictUseMine => 'माझी आवृत्ती ठेवा';

  @override
  String get conflictUseServer => 'सर्व्हर आवृत्ती ठेवा';

  @override
  String get conflictResolved => 'विरोध सोडवला';

  @override
  String get conflictResolvedAll => 'सर्व विरोध सोडवले';

  @override
  String conflictAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वेळा प्रयत्न केला',
      one: '1 वेळा प्रयत्न केला',
    );
    return '$_temp0';
  }

  @override
  String get conflictResourceTask => 'कार्य';

  @override
  String get conflictResourceExpiry => 'एक्स्पायरी रेकॉर्ड';

  @override
  String get conflictResourceScan => 'स्कॅन';

  @override
  String get conflictResourceInventory => 'स्टॉक समायोजन';

  @override
  String get conflictResourceGrn => 'GRN नोंद';

  @override
  String get conflictResourceShoppingList => 'खरेदी यादी आयटम';

  @override
  String get conflictResourceGeneric => 'सिंक बदल';

  @override
  String conflictLocalChangeSummary(String summary) {
    return 'तुमचा बदल: $summary';
  }

  @override
  String get supportTitle => 'सपोर्ट';

  @override
  String get supportContactUs => 'आमच्याशी संपर्क साधा';

  @override
  String get supportEmailUs => 'ईमेल करा';

  @override
  String get supportEmailUsHint => 'support@radha.app';

  @override
  String get supportCallUs => 'सपोर्टला कॉल करा';

  @override
  String get supportCallUsHint => 'सोम–शुक्र, सकाळी 9 – संध्याकाळी 6 IST';

  @override
  String get supportReportBug => 'बग नोंदवा';

  @override
  String get supportBugDescription => 'काय झाले?';

  @override
  String get supportBugDescriptionHint =>
      'जेव्हा अडचण आली तेव्हा तुम्ही काय करत होता ते सांगा.';

  @override
  String get supportAttachScreenshot => 'स्क्रीनशॉट जोडा';

  @override
  String get supportScreenshotAttached => 'स्क्रीनशॉट जोडला';

  @override
  String get supportRemoveScreenshot => 'काढा';

  @override
  String get supportSubmit => 'अहवाल पाठवा';

  @override
  String get supportSubmitted => 'धन्यवाद — तुमचा अहवाल मिळाला.';

  @override
  String get supportSubmitFailed => 'पाठवू शकलो नाही. कृपया आम्हाला ईमेल करा.';

  @override
  String get supportBugDescriptionRequired => 'कृपया काय झाले ते सांगा.';

  @override
  String get supportFaq => 'वारंवार विचारले जाणारे प्रश्न';

  @override
  String get supportFaqQ1 => 'बारकोड कसा स्कॅन करावा?';

  @override
  String get supportFaqA1 =>
      'स्कॅन टॅब उघडा, कॅमेरा बारकोडवर ठेवा आणि स्थिर ठेवा. स्पष्ट कोड वाचताच उत्पादन दिसेल.';

  @override
  String get supportFaqQ2 => 'उत्पादन डेटाबेसमध्ये नसल्यास?';

  @override
  String get supportFaqA2 =>
      'सापडले-नाही स्क्रीनवर \"उत्पादन जोडा\" टॅप करा. हे तुमच्या स्टोअरशी जोडलेली नवीन नोंद तयार करेल.';

  @override
  String get supportFaqQ3 => 'मी माझे सबस्क्रिप्शन कसे रद्द करू?';

  @override
  String get supportFaqA3 =>
      'प्रोफाइल → सबस्क्रिप्शनवर जा. कधीही रद्द करू शकता; पुढील बिलिंग चक्रानंतर शुल्क नाही.';

  @override
  String get supportFaqQ4 => 'मला रिकॉल अलर्ट का दिसत आहे?';

  @override
  String get supportFaqA4 =>
      'प्रत्येक स्कॅन FSSAI रिकॉल फीडशी जुळवतो. विकलेला बॅच यादीत असेल तर आम्ही कळवतो.';

  @override
  String get supportFaqQ5 => 'माझी अॅलर्जी प्रोफाइल कुटुंबासह कशी शेअर करू?';

  @override
  String get supportFaqA5 =>
      'अॅलर्जी प्रोफाइल सध्या प्रत्येक खात्यासाठी असते. एकाच घराच्या खात्यावर साइन इन करा किंवा प्रत्येक फोनवर तीच अॅलर्जी निवडा.';

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
