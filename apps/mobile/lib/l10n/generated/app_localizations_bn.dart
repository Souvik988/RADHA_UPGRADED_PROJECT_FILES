// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get subTitle => 'সাবস্ক্রিপশন';

  @override
  String get subUnlockHeadline => 'RADHA-র সম্পূর্ণ ছবি আনলক করুন';

  @override
  String get subLoadError => 'আপনার সাবস্ক্রিপশন লোড করা যায়নি';

  @override
  String get subErrorBody => 'আপনার সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get subChoosePlan => 'একটি প্ল্যান বেছে নিন';

  @override
  String get subPlansLoadError => 'প্ল্যান লোড করা যায়নি';

  @override
  String get subPlansUnavailable =>
      'এই মুহূর্তে কোনও প্ল্যান উপলব্ধ নেই। অনুগ্রহ করে পরে আবার চেষ্টা করুন।';

  @override
  String get subSecurePayment => 'Razorpay-এর মাধ্যমে নিরাপদ পেমেন্ট';

  @override
  String get subCurrentPlan => 'বর্তমান প্ল্যান';

  @override
  String subRenewsInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days দিনে নবীকরণ',
      one: '1 দিনে নবীকরণ',
    );
    return '$_temp0';
  }

  @override
  String get subBillingMonthly => 'মাসিক';

  @override
  String get subBillingYearly => 'বার্ষিক';

  @override
  String get subBilledYearly => 'বার্ষিক বিলিং';

  @override
  String get subPerMonth => '/মাস';

  @override
  String get subPerYear => '/বছর';

  @override
  String get subPopular => 'জনপ্রিয়';

  @override
  String get subStatusTrial => 'ট্রায়াল';

  @override
  String subStatusDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days দিন বাকি',
      one: '1 দিন বাকি',
    );
    return '$_temp0';
  }

  @override
  String get subStatusActive => 'সক্রিয়';

  @override
  String get subStatusPastDue => 'বকেয়া';

  @override
  String get subStatusPaused => 'বিরতি দেওয়া';

  @override
  String get subStatusCancelled => 'বাতিল';

  @override
  String subUpgradeTo(String plan) {
    return '$plan-এ আপগ্রেড করুন';
  }

  @override
  String subChoosePlanNamed(String plan) {
    return '$plan বেছে নিন';
  }

  @override
  String subYoureOnPlan(String plan) {
    return 'আপনি $plan-এ আছেন';
  }

  @override
  String subWelcome(String plan) {
    return 'আপনি $plan-এ আছেন। RADHA $plan-এ স্বাগতম!';
  }

  @override
  String get subCheckoutCancelled =>
      'চেকআউট বাতিল করা হয়েছে — আপনার প্ল্যান অপরিবর্তিত।';

  @override
  String subPaymentPending(String supportRef) {
    return 'পেমেন্ট পাওয়া গেছে — এখন নিশ্চিত করা হচ্ছে। রেফ $supportRef. কিছুক্ষণের মধ্যে রিফ্রেশ করতে নিচে টানুন।';
  }

  @override
  String get subPaymentFailed =>
      'পেমেন্ট ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String get catalogSearchBarHint => 'আপনার জন্য উপযুক্ত পণ্য খুঁজুন';

  @override
  String get catalogSearchHint => 'পণ্য বা ব্র্যান্ড খুঁজুন';

  @override
  String get catalogSearchClear => 'মুছুন';

  @override
  String get catalogNoMatchesTitle => 'কোনও মিল নেই';

  @override
  String catalogNoMatchesBody(String query) {
    return 'আমরা “$query”-এর জন্য কোনও পণ্য খুঁজে পাইনি। অন্য একটি নাম চেষ্টা করুন, বা পণ্যটি স্ক্যান করুন।';
  }

  @override
  String get catalogScanProduct => 'পণ্য স্ক্যান করুন';

  @override
  String get catalogFindTitle => 'পণ্য খুঁজুন';

  @override
  String get catalogFindBody =>
      'এর হেলথ রেটিং এবং উপাদান দেখতে পণ্যের নাম বা ব্র্যান্ড খুঁজুন।';

  @override
  String get catalogProductsFallback => 'পণ্য';

  @override
  String get catalogLoadErrorTitle => 'পণ্য লোড করা যায়নি';

  @override
  String catalogLoadErrorBody(String category) {
    return '$category লোড করতে সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';
  }

  @override
  String get catalogSourceOffline =>
      'অফলাইন — আপনার সংরক্ষিত ক্যাটালগ দেখানো হচ্ছে';

  @override
  String get catalogSourceUnavailable =>
      'লাইভ ক্যাটালগ অনুপলব্ধ — সংরক্ষিত ক্যাটালগ দেখানো হচ্ছে';

  @override
  String get catalogRetry => 'আবার';

  @override
  String get catalogSortHealthiest => 'সবচেয়ে স্বাস্থ্যকর';

  @override
  String get catalogSortAZ => 'নাম অনুসারে';

  @override
  String get catalogVegOnly => 'শুধু নিরামিষ';

  @override
  String get catalogVeg => 'নিরামিষ';

  @override
  String get catalogNoVegTitle => 'এখানে এখনও কোনও নিরামিষ আইটেম নেই';

  @override
  String catalogNoVegBody(String category) {
    return '$category-এ এখন নিরামিষ ফিল্টারের সঙ্গে কিছু মেলে না।';
  }

  @override
  String get catalogShowAll => 'সব দেখান';

  @override
  String get catalogNoProductsTitle => 'এখনও কোনও পণ্য নেই';

  @override
  String catalogNoProductsBody(String category) {
    return 'আমরা $category বিভাগটি সাজাচ্ছি। ইতিমধ্যে, যেকোনও আইটেম স্ক্যান করে তার স্বাস্থ্য ও মেয়াদ পরীক্ষা করুন।';
  }

  @override
  String get catalogFeaturedTitle => 'বিশেষ পণ্য';

  @override
  String get catalogHealthyPicksTitle => 'স্বাস্থ্যকর বাছাই';

  @override
  String get catalogDetailProductFallback => 'পণ্য';

  @override
  String get catalogDetailTitle => 'পণ্য';

  @override
  String get catalogDetailShareTooltip => 'শেয়ার করুন';

  @override
  String get catalogDetailSeeHealthierOptions => 'আরও স্বাস্থ্যকর বিকল্প দেখুন';

  @override
  String get catalogDetailSavedSnackbar =>
      'সেভ হয়েছে — কখনও রিকল হলে আমরা আপনাকে জানাব।';

  @override
  String get catalogDetailSaveFailedSnackbar =>
      'সেভ করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String catalogDetailShareRating(String rating, String label) {
    return ' — RADHA স্বাস্থ্য রেটিং $rating/5 ($label)';
  }

  @override
  String catalogDetailShareText(String productName, String ratingSummary) {
    return 'RADHA-তে \"$productName\" চেক করা হয়েছে$ratingSummary.';
  }

  @override
  String get catalogDetailSavedTooltip => 'সেভ হয়েছে';

  @override
  String get catalogDetailHealthPendingTitle => 'স্বাস্থ্য রেটিং এখনও আসেনি';

  @override
  String get catalogDetailHealthPendingBody =>
      'এই পণ্যটি স্ক্যান করে এর পূর্ণ স্বাস্থ্য বিশ্লেষণ RADHA-তে আনুন।';

  @override
  String get catalogDetailHealthRatingLabel => 'RADHA স্বাস্থ্য রেটিং';

  @override
  String get catalogDetailHealthExcellent => 'অসাধারণ';

  @override
  String get catalogDetailHealthGood => 'ভালো';

  @override
  String get catalogDetailHealthFair => 'মোটামুটি';

  @override
  String get catalogDetailHealthPoor => 'দুর্বল';

  @override
  String get catalogDetailHealthAvoid => 'এড়িয়ে চলুন';

  @override
  String get catalogDetailInsightHighProtein => 'প্রোটিন বেশি';

  @override
  String get catalogDetailInsightGoodFibre => 'ভালো ফাইবার';

  @override
  String get catalogDetailInsightMinimallyProcessed => 'কম প্রক্রিয়াজাত';

  @override
  String get catalogDetailConcernHighSugar => 'চিনি বেশি';

  @override
  String get catalogDetailConcernHighSaturatedFat => 'স্যাচুরেটেড ফ্যাট বেশি';

  @override
  String get catalogDetailConcernHighSodium => 'সোডিয়াম বেশি';

  @override
  String get catalogDetailConcernUltraProcessed => 'অতি-প্রক্রিয়াজাত';

  @override
  String get catalogDetailConcernContainsTransFat => 'ট্রান্স ফ্যাট আছে';

  @override
  String get catalogDetailConcernContainsAllergens => 'অ্যালার্জেন আছে';

  @override
  String get catalogDetailLikeHeading => 'যা আপনার ভালো লাগবে';

  @override
  String get catalogDetailConcernHeading => 'যা নজরে রাখা দরকার';

  @override
  String get catalogDetailNutritionSourceNote =>
      'পণ্যের আসল পুষ্টি তথ্যের উপর ভিত্তি করে (প্রতি 100 গ্রাম)।';

  @override
  String get catalogDetailKeyNutrients => 'মূল পুষ্টি';

  @override
  String get catalogDetailNutrientProtein => 'প্রোটিন';

  @override
  String get catalogDetailNutrientTotalSugars => 'মোট চিনি';

  @override
  String get catalogDetailNutrientEnergy => 'শক্তি';

  @override
  String get catalogDetailAllNutrients => 'সব পুষ্টি';

  @override
  String get catalogDetailNutrientTotalFat => 'মোট ফ্যাট';

  @override
  String get catalogDetailNutrientSaturatedFat => 'স্যাচুরেটেড ফ্যাট';

  @override
  String get catalogDetailNutrientCarbohydrates => 'কার্বোহাইড্রেট';

  @override
  String get catalogDetailNutrientFibre => 'ফাইবার';

  @override
  String get catalogDetailNutrientSodium => 'সোডিয়াম';

  @override
  String get catalogDetailPer100g => 'প্রতি 100 গ্রাম';

  @override
  String get catalogDetailPer50g => 'প্রতি 50 গ্রাম';

  @override
  String get catalogDetailRdaNote =>
      'রেফারেন্স দৈনিক গ্রহণের % (প্রাপ্তবয়স্ক)।';

  @override
  String get catalogDetailRadhaPlus => 'RADHA Plus';

  @override
  String get catalogDetailForYou => 'আপনার জন্য';

  @override
  String get catalogDetailIngredientDeepDiveTitle => 'উপাদানের গভীর বিশ্লেষণ';

  @override
  String get catalogDetailIngredientDeepDiveLockedBody =>
      'প্রতিটি উপাদান নিরাপত্তা মতামতসহ বুঝুন — এটি কী, কেন আছে, আর চিন্তার কারণ আছে কি না।';

  @override
  String get catalogDetailIngredientExplainError =>
      'এই উপাদানগুলো এখন ব্যাখ্যা করা যায়নি।';

  @override
  String get catalogDetailPersonalisedFlagsTitle => 'ব্যক্তিগত সতর্কতা';

  @override
  String get catalogDetailPersonalisedFlagsLockedBody =>
      'এই পণ্যকে আপনার সেভ করা অ্যালার্জেন ও স্বাস্থ্য লক্ষ্যের সঙ্গে মিলিয়ে দেখুন — আপনার জন্য কী ঠিক বা ভুল তা আমরা দেখাব।';

  @override
  String get catalogDetailPersonaliseError =>
      'এখন এটি ব্যক্তিগতভাবে দেখানো যায়নি।';

  @override
  String get catalogDetailNoAllergensDetected =>
      'এই পণ্যে কোনো অ্যালার্জেন পাওয়া যায়নি।';

  @override
  String catalogDetailAllergenAvoided(String allergen) {
    return '$allergen — আপনি এটি এড়িয়ে চলেন';
  }

  @override
  String catalogDetailUnlockWithPlan(String plan) {
    return '$plan দিয়ে আনলক করুন';
  }

  @override
  String get catalogDetailWouldBuyQuestion => 'আপনি কি এই পণ্যটি কিনবেন?';

  @override
  String get catalogDetailWouldBuyThanks => 'শেয়ার করার জন্য ধন্যবাদ!';

  @override
  String get catalogDetailWouldBuyYes => 'হ্যাঁ';

  @override
  String get catalogDetailWouldBuyNo => 'না';

  @override
  String get catalogDetailWouldBuyAlreadyBought => 'ইতিমধ্যে কিনেছি';

  @override
  String get catalogDetailNutritionNotFoundTitle =>
      'এই রেকর্ডটি এখনও আমাদের কাছে নেই';

  @override
  String get catalogDetailNutritionNotFoundBody =>
      'RADHA-তে এই পণ্যের পূর্ণ পুষ্টি তথ্য এখনও নেই। আসল ডেটা আনতে এর বারকোড বা লেবেল স্ক্যান করুন।';

  @override
  String get catalogDetailNutritionOfflineTitle => 'আপনি অফলাইনে আছেন';

  @override
  String get catalogDetailNutritionOfflineBody =>
      'পুষ্টি তথ্য লোড করা যায়নি। উপরের পণ্যের তথ্য ঠিক আছে — আবার সংযোগ করে চেষ্টা করুন।';

  @override
  String get catalogDetailNutritionSessionExpiredTitle => 'সেশন শেষ হয়েছে';

  @override
  String get catalogDetailNutritionSessionExpiredBody =>
      'আবার চেষ্টা করুন — RADHA আপনার সেশন রিফ্রেশ করে আবার চেষ্টা করবে।';

  @override
  String get catalogDetailNutritionServerTitle => 'পুষ্টি তথ্য লোড করা যায়নি';

  @override
  String get catalogDetailNutritionServerBody =>
      'বিবরণ আনতে গিয়ে কিছু ভুল হয়েছে। উপরের পণ্যের তথ্য প্রভাবিত হয়নি।';

  @override
  String get catalogDetailScanLabel => 'লেবেল স্ক্যান করুন';

  @override
  String get catalogDetailFullNutritionPendingTitle =>
      'পূর্ণ পুষ্টি তথ্য এখনও নেই';

  @override
  String get catalogDetailFullNutritionPendingBody =>
      'এই পণ্যের বারকোড স্ক্যান করে আসল পুষ্টি ও স্বাস্থ্য বিশ্লেষণ RADHA-তে আনুন — মাত্র এক সেকেন্ড লাগবে।';

  @override
  String get catalogDetailScanToUnlock => 'আনলক করতে স্ক্যান করুন';

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
