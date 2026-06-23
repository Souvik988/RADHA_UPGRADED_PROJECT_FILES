// RADHA bundled visual assets (Bible v2.1 — the upgraded "v2" set).
//
// Typed catalog of every shipped image / Lottie asset under `assets/v2/`.
// Screens and widgets MUST reference these constants — never a raw string
// path — so a renamed or missing asset is a compile-time concern, not a
// runtime surprise. Mockup reference boards under `assets/v2/mockup/` are
// design references for implementation and are deliberately NOT listed here
// (they are not shipped UI).
//
// Asset folders are registered in `pubspec.yaml` under `flutter: assets:`.

/// Mor's emotional states (see CHARACTER_STORYTELLING_BIBLE.md §4.5).
enum MorMood {
  idle,
  greet,
  think,
  work,
  celebrate,
  shelter,
  concern,
  guard,
  sleep,
}

/// Canonical paths to bundled v2 assets.
class RadhaAssets {
  RadhaAssets._();

  static const String _v2 = 'assets/v2';

  // --- Mor — the companion mascot ----------------------------------------
  static const String morTurnaround = '$_v2/character/mor/sheet-turnaround.png';
  static const String morExpressions =
      '$_v2/character/mor/sheet-expressions.png';
  static const String morGlyph = '$_v2/character/mor/glyph.png';
  static const String morPartsSheet =
      '$_v2/character/mor/parts/parts-sheet.png';

  // Hero scenes (full illustrated moments).
  static const String morHeroSplash = '$_v2/character/mor/hero-splash.png';
  static const String morHeroOffline = '$_v2/character/mor/hero-offline.png';
  static const String morHeroWin = '$_v2/character/mor/hero-win.png';

  // Static mood frames (used directly for mood swaps + as reduced-motion
  // fallbacks for any animated Mor).
  static const String morIdle = '$_v2/character/mor/static/idle.png';
  static const String morGreet = '$_v2/character/mor/static/greet.png';
  static const String morThink = '$_v2/character/mor/static/think.png';
  static const String morWork = '$_v2/character/mor/static/work.png';
  static const String morCelebrate = '$_v2/character/mor/static/celebrate.png';
  static const String morShelter = '$_v2/character/mor/static/shelter.png';
  static const String morConcern = '$_v2/character/mor/static/concern.png';
  static const String morGuard = '$_v2/character/mor/static/guard.png';
  static const String morSleep = '$_v2/character/mor/static/sleep.png';

  /// Resolve a [MorMood] to its static frame path.
  static String morMoodFrame(MorMood mood) => switch (mood) {
    MorMood.idle => morIdle,
    MorMood.greet => morGreet,
    MorMood.think => morThink,
    MorMood.work => morWork,
    MorMood.celebrate => morCelebrate,
    MorMood.shelter => morShelter,
    MorMood.concern => morConcern,
    MorMood.guard => morGuard,
    MorMood.sleep => morSleep,
  };

  // --- Human shopkeeper cast ---------------------------------------------
  static const String humansSheet = '$_v2/character/humans/sheet.png';
  static const String humanRameshOnIt = '$_v2/character/humans/ramesh-onit.png';

  // --- Icons (KPI / nav / health) ----------------------------------------
  static const String iconClockExpiry = '$_v2/icons/clock-expiry.png';
  static const String iconBoxLowStock = '$_v2/icons/box-lowstock.png';
  static const String iconClipboardTasks = '$_v2/icons/clipboard-tasks.png';
  static const String iconTruckGrn = '$_v2/icons/truck-grn.png';
  static const String iconScanBarcode = '$_v2/icons/scan-barcode.png';
  static const String iconHome = '$_v2/icons/home.png';
  static const String iconTasksList = '$_v2/icons/tasks-list.png';
  static const String iconProfileUser = '$_v2/icons/profile-user.png';
  // Health-flag icons (scan result, product detail).
  static const String iconSugar = '$_v2/icons/sugar-drop.png';
  static const String iconFat = '$_v2/icons/fat-droplet.png';
  static const String iconSalt = '$_v2/icons/salt-shaker.png';
  static const String iconProcessed = '$_v2/icons/processed-factory.png';
  static const String iconChildStar = '$_v2/icons/child-star.png';

  // --- Illustrations ------------------------------------------------------
  static const String illoHomeStorefront =
      '$_v2/illustration/home-storefront.png';
  static const String illoHomeMission = '$_v2/illustration/home-mission.png';
  static const String illoCategorySet = '$_v2/illustrations/cat-set-8.png';
  static const String illoScanFrame = '$_v2/illustrations/scan-frame.png';
  static const String illoSpotExpiry = '$_v2/illustrations/spot-expiry.png';
  static const String illoSpotStoreHealth =
      '$_v2/illustrations/spot-storehealth.png';

  // --- Onboarding split-screen photos (Personal/Business segment picker) --
  static const String heroOnboardingWelcome =
      '$_v2/illustrations/hero_onboarding_welcome.png';
  static const String heroOnboardingCapabilities =
      '$_v2/illustrations/hero_onboarding_capabilities.png';
  static const String segPersonal = '$_v2/illustrations/seg_personal.png';
  static const String segBusiness = '$_v2/illustrations/seg_business.png';

  // --- Home promo banners (v3 — cinematic editorial scenes) --------------
  // Full-bleed 1:1 photographic banners; rendered with a bottom gradient
  // scrim so overlaid copy stays legible. See `home_screen.dart`.
  static const String bannerHomeMission =
      '$_v2/illustration/home-mission-v3.jpg';
  static const String bannerHomePromoConsumer =
      '$_v2/illustration/home-promo-consumer-v3.jpg';

  // --- Category cutouts (v3 — image-led "shop by category" rail) ---------
  // Square product pack-shots on white; sit inside rounded tiles via cover.
  static const String catBiscuits = '$_v2/illustrations/cat-biscuits.png';
  static const String catBreakfast = '$_v2/illustrations/cat-breakfast.png';
  static const String catDairy = '$_v2/illustrations/cat-dairy.png';
  static const String catBeverages = '$_v2/illustrations/cat-beverages.png';
  static const String catPersonalCare =
      '$_v2/illustrations/cat-personal-care.png';
  static const String catHousehold = '$_v2/illustrations/cat-household.png';
  static const String catStaples = '$_v2/illustrations/cat-staples.png';
  static const String catFrozen = '$_v2/illustrations/cat-frozen.png';

  // --- Lottie scenes ------------------------------------------------------
  // NOTE: the current `.json` files are lightweight placeholders. Real
  // hand-authored Lottie lands with the motion pass (loader / scan-success /
  // offline-sync / win-beat). Guard usage behind reduced-motion.
  static const String lottieSplash = '$_v2/lottie/splash.json';
  static const String lottieScanSuccess = '$_v2/lottie/scan-success.json';
  static const String lottieOfflineSync = '$_v2/lottie/offline-sync.json';
  static const String lottieWinBeatPetals = '$_v2/lottie/win-beat-petals.json';

  // ── v3 — generated premium art (Mor scenes, state illos, banners, etc.) ──
  // High-res hand-illustrated set (2026-06-09), optimized to WebP. Mor here is
  // the full peacock companion (richer than the static mood frames above).

  // Mor scenes (full-figure companion moments).
  static const String morSceneSplash =
      '$_v2/character/mor/scenes/hero-splash.webp';
  static const String morSceneOffline =
      '$_v2/character/mor/scenes/hero-offline.webp';
  static const String morSceneWin = '$_v2/character/mor/scenes/hero-win.webp';
  static const String morSceneSearch =
      '$_v2/character/mor/scenes/search-think.webp';
  static const String morSceneScanning =
      '$_v2/character/mor/scenes/scanning.webp';

  // Designed empty / error states (Mor-based; used by EmptyState/ErrorState).
  static const String stateNoResults = '$_v2/states/no-results.webp';
  static const String stateEmptyList = '$_v2/states/empty-list.webp';
  static const String stateErrorRetry = '$_v2/states/error-retry.webp';
  static const String stateOffline = '$_v2/states/offline.webp';

  // Home promo carousel banners (editorial photos with a built-in text scrim).
  static const String bannerHealthMission = '$_v2/banners/health-mission.webp';
  static const String bannerExpiryMission = '$_v2/banners/expiry-mission.webp';
  static const String bannerFestive = '$_v2/banners/festive-store-pride.webp';

  // Onboarding scenes (consumer + business).
  static const String onboardScan = '$_v2/onboarding/scan.webp';
  static const String onboardHealth = '$_v2/onboarding/health.webp';
  static const String onboardAudit = '$_v2/onboarding/audit.webp';
  static const String onboardGrowth = '$_v2/onboarding/growth.webp';

  // Illustrated health-flag badges (scan result / ingredient deep-dive).
  static const String hiSugarHigh = '$_v2/icons/health/sugar-high.webp';
  static const String hiFatHigh = '$_v2/icons/health/fat-high.webp';
  static const String hiSodiumHigh = '$_v2/icons/health/sodium-high.webp';
  static const String hiFiberGood = '$_v2/icons/health/fiber-good.webp';
  static const String hiProteinGood = '$_v2/icons/health/protein-good.webp';
  static const String hiAdditiveWarning =
      '$_v2/icons/health/additive-warning.webp';
  static const String hiAllergenFlag = '$_v2/icons/health/allergen-flag.webp';
  static const String hiUltraProcessed =
      '$_v2/icons/health/ultra-processed.webp';

  // RADHA Plus paywall hero + brand splash lockup.
  static const String paywallHero = '$_v2/plus/paywall-hero.webp';
  static const String splashLockup = '$_v2/brand/splash-lockup.webp';
}
