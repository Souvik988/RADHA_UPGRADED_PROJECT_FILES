# RADHA Mobile — Asset Pipeline

> **Scope**: Image, icon, font, Lottie, splash and store-asset management for `apps/mobile/`. Defines the directory layout, formats, budgets, naming conventions and CI gates. Companion to `FRONTEND_PHASES/FE-39_PHASE.md` (perf budgets), `LOCALIZATION_STRATEGY.md` (localized fonts, store screenshots) and `ENVIRONMENT_CONFIG.md` (per-flavor launcher icons).

---

## 1. Asset organization

```
apps/mobile/assets/
  images/                    # Photographs, illustrations
    placeholder/             # Fallback placeholders
    onboarding/              # FE-09 onboarding
    paywall/                 # FE-13 hero illustrations
    empty/                   # FE-37 empty-state illustrations
    2.0x/                    # Flutter resolution variants
    3.0x/
  icons/                     # SVG only — see §3
    nav/                     # Bottom-nav icons
    actions/                 # Action icons (scan, camera, share, settings)
    status/                  # Status indicators (sync, recall, allergen)
  lottie/                    # Vector animations
    static/                  # PNG fallbacks for reduced-motion users
  fonts/                     # Bundled font fallbacks (subset)
  brand/                     # Pipeline source files — generators read from here
    icon_dev.png             # 1024×1024
    icon_staging.png
    icon_prod.png
    icon_adaptive_foreground.png
    icon_adaptive_background.png
    splash.png               # 1024×1024 light
    splash_dark.png          # 1024×1024 dark
```

Files outside this tree are not picked up by `flutter pub get`. Engineers place new assets only inside `apps/mobile/assets/` and declare them in `pubspec.yaml` (§13).

---

## 2. Image rules

| Rule | Detail |
|---|---|
| **Preferred format** | WebP, quality 85 |
| **Allowed fallback** | PNG only when WebP support is genuinely missing (rare in Flutter; covers brand source files in `brand/`) |
| **JPEG** | Banned — no transparency, lossy artefacts on text overlays |
| **GIF** | Banned — use Lottie for animation; `Image.asset` does not loop GIFs efficiently |
| **HEIC** | Banned — designer hand-off must be WebP/PNG |
| **Max dimensions** | 800×800 unless the image is a hero or full-bleed background. Hero exceptions are listed in `tool/performance/image_budget.yaml` (FE-39) under `overrides:` |
| **Resolution variants** | Provide `image.webp` (1.0x), `2.0x/image.webp` (2.0x), `3.0x/image.webp` (3.0x) per Flutter convention |
| **Per-asset KB budget** | Enforced by `tool/performance/image_budget.yaml`; CI fails on regression. See FE-39 for the budget table |
| **Color profile** | sRGB. No P3 unless explicitly requested for a marketing surface and approved by tech lead |
| **EXIF stripped** | Always. The export script `tool/assets/export.sh` runs `exiftool -all=` on every committed image |

A typical illustration ships as:

```
assets/images/empty_recipes.webp           # 1.0x — 12 KB
assets/images/2.0x/empty_recipes.webp      # 2.0x — 28 KB
assets/images/3.0x/empty_recipes.webp      # 3.0x — 48 KB
```

Total weight per illustration capped at ≤ 100 KB across all densities.

---

## 3. Icon rules

| Rule | Detail |
|---|---|
| **Format** | **SVG only**, rendered via `flutter_svg ^2.0.10` |
| **Source library** | Phosphor Icons (preferred) or Material Symbols Rounded. **One** library per project; no mix |
| **Stroke** | 1.5 px exclusively. Filled vs stroked variants both allowed; never mix in the same screen |
| **Max size** | ≤ 8 KB per icon (after SVGO optimization) |
| **Color** | SVGs export in `currentColor` so a single asset themes light + dark via `colorFilter: ColorFilter.mode(color, BlendMode.srcIn)` |
| **Banned** | PNG icons (see §16 lint), emoji-as-icons (e.g., 🚨 for recall — replaced by an SVG), FontAwesome (license + non-uniform stroke), Cupertino icons (we don't dual-render) |
| **Naming** | `<group>_<verb_or_noun>_<state?>.svg` e.g., `nav_scan.svg`, `actions_share.svg`, `status_recall_active.svg` |

**Rendering pattern**:

```dart
SvgPicture.asset(
  'assets/icons/nav/nav_scan.svg',
  width: 24,
  height: 24,
  colorFilter: ColorFilter.mode(
    Theme.of(context).colorScheme.onSurface,
    BlendMode.srcIn,
  ),
  semanticsLabel: S.of(context).iconScanLabel,
)
```

The `RadhaIcon` widget (FE-03) wraps `SvgPicture.asset` with theme + RTL handling so call-sites don't repeat the `colorFilter`.

---

## 4. SVG optimization

Every icon committed to the repo is run through `svgo` with the `apps/mobile/tool/assets/svgo.config.json` preset:

```json
{
  "multipass": true,
  "plugins": [
    "preset-default",
    "removeDimensions",
    "convertStyleToAttrs",
    { "name": "removeAttrs", "params": { "attrs": ["xmlns:xlink", "data-name"] } }
  ]
}
```

CI step `tool/assets/check_svgo.sh` re-runs `svgo` on every file under `assets/icons/` and asserts the resulting bytes match the committed bytes. If they don't, an engineer skipped optimization — CI fails with a diff.

---

## 5. Font pipeline

| Font | Use | Source | Bundled? |
|---|---|---|---|
| **Plus Jakarta Sans** | Display + body | `google_fonts` package (runtime fetch + cache) | yes — Latin + Devanagari subset only |
| **JetBrains Mono** | Numerics, OTP entry, codes | `google_fonts` (runtime fetch + cache) | yes — Latin + numeric glyphs only |
| **Noto Sans Tamil** | Tamil text rendering | bundled (Google Fonts permalink, subset) | yes |
| **Noto Sans Telugu** | Telugu | bundled, subset | yes |
| **Noto Sans Bengali** | Bengali | bundled, subset | yes |

**Why both runtime and bundled?**

- `google_fonts` keeps the IPA/AAB small in the common case (Latin-only Hindi user with network access).
- Bundled subsets cover the offline-first scenario (FE-08) and low-end devices that are slow to fetch.
- The bundle is **subset** — Plus Jakarta Sans bundled covers Latin + Devanagari only; Tamil/Telugu/Bengali users rely on the dedicated Noto subsets above. Total bundled-font weight stays under 8 MB across all flavors (CI gate in §16).

**Subsetting tool**: `pyftsubset` (fonttools), driven by `tool/assets/subset_fonts.sh`. Glyph subsets per script are listed in `tool/assets/font_subsets.yaml`. Re-run only when the subset changes (rare).

**Pubspec declaration**: see §13.

**Runtime selection**:

```dart
TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
      fontSize: 32, fontWeight: FontWeight.w700, height: 1.2,
    );
```

If `google_fonts` cannot fetch (offline, low storage, fetch quota), it transparently falls back to the bundled `PlusJakartaSans` family declared under `flutter.fonts:`. The fallback path is unit-tested by overriding `HttpOverrides` in `test/fonts/google_fonts_offline_test.dart`.

---

## 6. Per-script font fallback

`RadhaTypography` (FE-02) selects the script-appropriate family per active locale:

```dart
String _familyFor(Locale locale) {
  switch (locale.languageCode) {
    case 'ta': return 'NotoSansTamil';
    case 'te': return 'NotoSansTelugu';
    case 'bn': return 'NotoSansBengali';
    case 'hi':
    case 'mr':
    case 'en':
    default:   return 'PlusJakartaSans';   // covers Latin + Devanagari
  }
}
```

`TextStyle.fontFamily` flips per locale; line-height also flips per `LOCALIZATION_STRATEGY.md` §21. This avoids tofu boxes on Tamil/Telugu/Bengali devices that lack the system font.

---

## 7. Lottie pipeline

| Rule | Detail |
|---|---|
| **Source format** | After Effects → Bodymovin export, `.json` |
| **Optimization** | `lottie-optimize` CLI run via `tool/assets/optimize_lottie.sh` — strips unused layers, quantizes coordinates, `gzip`-friendly |
| **Per-file budget** | ≤ 80 KB. Enforced by `tool/assets/check_lottie_size.dart` |
| **Total Lottie pack** | ≤ 2 MB across all `assets/lottie/*.json` |
| **Frame rate** | 30 fps maximum. 60 fps Lotties rejected at PR review (designer guidance) |
| **Naming** | `{screen}_{action}_{state}.json` e.g., `scan_capture_success.json`, `paywall_celebrate_purchase.json`, `splash_logo_loop.json` |
| **Reduced-motion fallback** | Every Lottie has a static PNG sibling at `assets/lottie/static/{name}.png` (frame 0 of the animation) |
| **Loading API** | `LottieBuilder.asset('assets/lottie/...')` — wrapped by `RadhaLottie` widget (FE-04) which handles reduced motion + theme tinting |
| **Tinting** | `delegates: LottieDelegates(values: [...])` for theme-aware colour swaps; never bake brand colours into the JSON |

**Reduced-motion swap**:

```dart
class RadhaLottie extends StatelessWidget {
  final String name;
  const RadhaLottie(this.name, {super.key});
  @override
  Widget build(BuildContext c) {
    final reduced = MediaQuery.disableAnimationsOf(c);
    if (reduced) {
      return Image.asset('assets/lottie/static/$name.png');
    }
    return LottieBuilder.asset('assets/lottie/$name.json');
  }
}
```

This contract is enforced by FE-39's perf gate: any Lottie missing its `static/<name>.png` sibling fails CI.

---

## 8. Splash screen

| Concern | Detail |
|---|---|
| **Generator** | `flutter_native_splash ^2.4` |
| **Source** | `assets/brand/splash.png` (light), `assets/brand/splash_dark.png` (dark) — 1024×1024 each |
| **Background** | Light mode: `#F8F9FA` (RADHA-base surface); dark mode: `#0E0F12` |
| **Generation command** | `dart run flutter_native_splash:create --flavor dev|staging|prod` |
| **Per-flavor** | yes — generated with each flavor's brand wordmark |
| **Min display** | 700 ms (matches FE-09 splash phase). `bootstrap()` keeps the splash up via `flutter_native_splash.preserve()` until first frame is rendered |
| **iOS storyboard** | `LaunchScreen.storyboard` is overwritten by the generator; do not edit by hand |
| **Android 12+ splash API** | Generator emits `android:windowSplashScreenAnimatedIcon` + `android:windowSplashScreenBackground` so RADHA's icon-on-fill is the OS-driven splash on API 31+ |
| **Branding** | Wordmark only on the splash; no tagline, no version. The first in-app frame (FE-09) handles brand reveal |

`flutter_native_splash.yaml` lives at `apps/mobile/flutter_native_splash.yaml` with three top-level flavor sections (`dev:`, `staging:`, `prod:`) — the generator emits per-flavor resources into `android/app/src/<flavor>/res/` and `ios/Runner/Assets.xcassets`.

---

## 9. App icons

| Concern | Detail |
|---|---|
| **Generator** | `flutter_launcher_icons ^0.13` |
| **Source per flavor** | `assets/brand/icon_dev.png`, `icon_staging.png`, `icon_prod.png` — 1024×1024 each |
| **Distinguishability** | dev = green ring around the wordmark; staging = amber ring; prod = clean. Engineers can identify the active flavor at a glance on the launcher |
| **Adaptive icon (Android)** | Two source files: `assets/brand/icon_adaptive_foreground.png` (transparent BG, 1024×1024) + `icon_adaptive_background.png` (solid colour, 1024×1024) |
| **iOS** | Generator emits `Assets.xcassets/AppIcon.appiconset/` for each flavor at all required sizes (20pt → 1024pt) |
| **Android legacy** | mipmap-mdpi → mipmap-xxxhdpi at all sizes, including round + square variants |
| **Generation command** | `dart run flutter_launcher_icons -f flutter_launcher_icons-dev.yaml` (one config per flavor) |

`flutter_launcher_icons-dev.yaml`:

```yaml
flutter_launcher_icons:
  android: 'launcher_icon'
  ios: true
  image_path: 'assets/brand/icon_dev.png'
  adaptive_icon_foreground: 'assets/brand/icon_adaptive_foreground.png'
  adaptive_icon_background: '#10B981'   # dev = green
  min_sdk_android: 26
  remove_alpha_ios: true
  flavor: dev
```

Identical structure for `flutter_launcher_icons-staging.yaml` (`#F59E0B` amber) and `flutter_launcher_icons-prod.yaml` (`#1E3A8A` brand navy). All three configs live at `apps/mobile/`.

---

## 10. Store screenshots

| Concern | Detail |
|---|---|
| **Pipeline** | `fastlane snapshot` (iOS) + `fastlane screengrab` (Android), invoked from `apps/mobile/integration_test/screenshots/` |
| **Per device class per locale** | 8 screenshots × 6 locales × 2 device classes (phone, tablet) = 96 images, generated automatically |
| **Devices** | iOS: iPhone 15 Pro Max (6.7"), iPhone SE 3 (4.7"), iPad Pro 12.9". Android: Pixel 7, Pixel Tablet |
| **Locales overridden in tests** | Each integration test sets `Locale` via `MaterialApp.locale` override; copy and dynamic content render in the target locale |
| **Screens captured** | Onboarding (FE-09), scan landing (FE-17), product detail (FE-19), allergen alert (FE-15), expiry dashboard (FE-23), recall card (FE-21), paywall (FE-13), settings (FE-31) |
| **Output path** | `apps/mobile/fastlane/screenshots/<locale>/<device>/01_onboarding.png` etc. |
| **CI integration** | Generated as part of `mobile-release.yml` (FE-40); not on every PR — too slow |
| **Localized text overlays** | Marketing overlays (callouts, taglines on the screenshot) are generated with localized PNG strips composited via `tool/assets/compose_screenshot.dart` reading text from `intl_<lang>.arb` |

---

## 11. Network-loaded assets

Product images, recall images, user avatars are not bundled — they're loaded from the CDN.

| Rule | Detail |
|---|---|
| **Loader** | `cached_network_image ^3.3` exclusively. `NetworkImage` (raw) is banned by lint (§16) |
| **Fallback placeholder** | `assets/images/placeholder/product_placeholder.webp` (12 KB) shown while loading and on error |
| **Cache size — high-end** | 100 entries / 96 MB |
| **Cache size — mid-tier** | 75 entries / 48 MB |
| **Cache size — low-end** | 50 entries / 24 MB |
| **Cache tuning** | `lib/perf/image_cache_tuning.dart` (FE-39) reads `deviceClassProvider` and applies the right limits at boot |
| **Cache eviction** | LRU; `cached_network_image` handles disk + memory |
| **Cache headers** | CDN sends `Cache-Control: public, max-age=2592000, immutable` for product images (versioned URLs); avatars use `max-age=86400` |
| **Disk cache location** | `getTemporaryDirectory()/libCachedImageData` — purged by OS under storage pressure |
| **Loading widget** | `RadhaProductImage` (FE-03) wraps `CachedNetworkImage` with skeleton placeholder + error fallback + Hero tag |

```dart
CachedNetworkImage(
  imageUrl: product.imageUrl,
  cacheManager: ref.watch(imageCacheManagerProvider),
  placeholder: (_, __) => const ShimmerSkeleton(),
  errorWidget: (_, __, ___) => Image.asset(
    'assets/images/placeholder/product_placeholder.webp',
  ),
  fit: BoxFit.cover,
  fadeInDuration: const Duration(milliseconds: 180),
)
```

---

## 12. Per-flavor asset overrides — explicitly NOT supported

Flavors share the same asset bundle. The only flavor-specific assets are:

- Launcher icons (§9)
- Splash artwork (§8)
- Firebase config files (`ENVIRONMENT_CONFIG.md` §7)

Reasons:

- Flavor-specific images would explode APK size — three copies of every illustration.
- Surprises in production when a dev-only image accidentally shipped is the kind of bug we never want.
- Designers want one source of truth.

If a screen needs to render different copy or imagery in dev vs prod (e.g., a debug-only tile), it does so by checking `env.flavor` at runtime and choosing among shared assets — never by including a parallel asset path under `assets/dev/` or `assets/prod/`.

---

## 13. `pubspec.yaml` asset declaration

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/images/placeholder/
    - assets/images/onboarding/
    - assets/images/paywall/
    - assets/images/empty/
    - assets/images/2.0x/
    - assets/images/3.0x/
    - assets/icons/
    - assets/icons/nav/
    - assets/icons/actions/
    - assets/icons/status/
    - assets/lottie/
    - assets/lottie/static/
    - assets/brand/

  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Regular.ttf
        - asset: assets/fonts/PlusJakartaSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/PlusJakartaSans-Bold.ttf
          weight: 700
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
        - asset: assets/fonts/JetBrainsMono-Medium.ttf
          weight: 500
    - family: NotoSansTamil
      fonts:
        - asset: assets/fonts/NotoSansTamil-Regular.ttf
        - asset: assets/fonts/NotoSansTamil-Medium.ttf
          weight: 500
        - asset: assets/fonts/NotoSansTamil-Bold.ttf
          weight: 700
    - family: NotoSansTelugu
      fonts:
        - asset: assets/fonts/NotoSansTelugu-Regular.ttf
        - asset: assets/fonts/NotoSansTelugu-Bold.ttf
          weight: 700
    - family: NotoSansBengali
      fonts:
        - asset: assets/fonts/NotoSansBengali-Regular.ttf
        - asset: assets/fonts/NotoSansBengali-Bold.ttf
          weight: 700
```

`assets/fonts/*.ttf` are subset (§5). `pubspec.yaml` is the only asset registration — Flutter ignores anything not declared here.

---

## 14. Runtime asset loading patterns

| Asset class | API | Wrapper widget |
|---|---|---|
| Bundled image | `Image.asset('assets/images/...', fit: BoxFit.cover)` | `RadhaImage` (FE-03) |
| Network image | `CachedNetworkImage(imageUrl: ...)` | `RadhaProductImage` (FE-03) |
| Icon | `SvgPicture.asset('assets/icons/...')` | `RadhaIcon` (FE-03) |
| Lottie | `LottieBuilder.asset('assets/lottie/...')` | `RadhaLottie` (FE-04) |
| Bundled font | `TextStyle(fontFamily: 'PlusJakartaSans')` | `RadhaTypography` (FE-02) |
| Network font | `GoogleFonts.plusJakartaSans()` | `RadhaTypography` (FE-02) |

Engineers use the wrappers, not the raw APIs — the wrappers handle theme, RTL, reduced motion, semantics labels and Hero tagging. The raw APIs are allowed only inside the wrapper implementations themselves.

---

## 15. Asset CI gates

Every PR runs the following gates as part of `mobile-ci.yml` (see `CI_CD_PIPELINE.md` §4). All four are blocking.

| Gate | Tool | What it checks |
|---|---|---|
| **Image budget** | `tool/assets/check_image_budget.dart` | Walks `assets/`, asserts every file under its `tool/performance/image_budget.yaml` cap; fails on any regression |
| **Icon format** | `tool/assets/check_no_png_icons.dart` | Walks `assets/icons/`, asserts only `.svg` extension |
| **SVGO clean** | `tool/assets/check_svgo.sh` | Re-runs SVGO; asserts committed bytes match optimized bytes |
| **Lottie size** | `tool/assets/check_lottie_size.dart` | Asserts each `assets/lottie/*.json` ≤ 80 KB and pack ≤ 2 MB |
| **Lottie static fallback** | `tool/assets/check_lottie_fallback.dart` | Every `assets/lottie/X.json` has a sibling `assets/lottie/static/X.png` |
| **Pubspec coverage** | `tool/assets/check_pubspec_assets.dart` | Every file under `assets/` (excluding `brand/`) is declared in `pubspec.yaml` `flutter.assets:` |
| **Bundled font weight** | `tool/assets/check_font_weight.dart` | Total `assets/fonts/*.ttf` ≤ 8 MB |
| **Launcher icon regen** | `tool/assets/check_launcher_icons.sh` | If any `assets/brand/icon_*.png` changed, asserts `flutter_launcher_icons` was re-run (mtime check on generated mipmaps) |

A regression fails the gate; an *increase within budget* posts a PR comment but does not block.

---

## 16. Custom-lint rules

`apps/mobile/tool/lint/` — registered with `dart run custom_lint`:

| Rule | Detail |
|---|---|
| `no_png_icons` | Flags any `Image.asset('assets/icons/...png')` |
| `no_raw_network_image` | Flags any `NetworkImage(`; suggests `CachedNetworkImage` |
| `no_inline_color_filter` | Flags `SvgPicture.asset` without `colorFilter` (theme breaks); suggests using `RadhaIcon` |
| `no_emoji_as_icon` | Flags any `Text('🚨')`-style emoji used outside chat/messaging UI |
| `no_undeclared_asset` | Flags any string literal `'assets/...'` whose file isn't declared in `pubspec.yaml` |
| `lottie_must_have_fallback` | Flags `LottieBuilder.asset` outside `RadhaLottie`; the wrapper is the only legal entry point |

Lint is run by `mobile-ci.yml` step "Custom lints"; failures block merge.

---

## 17. Hero tagging

For shared-element transitions (FE-04 motion bootstrap, FE-19 product detail), images carry stable Hero tags:

```dart
Hero(
  tag: 'product-image-${product.id}',
  child: RadhaProductImage(url: product.imageUrl),
)
```

Tag format: `<entity>-<field>-<id>`. Enforced at code-review (no lint yet — false positives would be noisy).

---

## 18. Design hand-off contract

| Concern | Designer responsibility | Engineer responsibility |
|---|---|---|
| Image export | WebP @ 85, three densities, EXIF stripped | Drop into `assets/images/` + density subdirs; declare in pubspec |
| Icon export | SVG, 1.5 px stroke, `currentColor`, ≤ 8 KB | Run SVGO, drop into `assets/icons/<group>/` |
| Lottie export | Bodymovin JSON, ≤ 30 fps, ≤ 80 KB | Run `lottie-optimize`, drop into `assets/lottie/`, capture frame-0 PNG into `assets/lottie/static/` |
| Brand source | 1024×1024 PNGs in `brand/` | Re-run `flutter_native_splash` and `flutter_launcher_icons` per flavor |
| Store screenshots | n/a — generated by tests | Maintain `integration_test/screenshots/` test scripts |
| Localized strings on screenshots | Reviewed in Lokalise | Composited via `tool/assets/compose_screenshot.dart` |

The contract is documented at `apps/mobile/DESIGN_HANDOFF.md` (referenced from the design-team Notion). PRs that violate the contract are bounced back to design rather than fixed in-flight by engineering.

---

## 19. Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| **Asset bloat from a single careless commit (e.g., 5 MB hero PNG)** | Medium | `check_image_budget.dart` per-asset cap; bundle-size diff comment on every PR (`mobile-ci.yml` §4) |
| **Lottie that references a font URL** | Low/High impact | `lottie-optimize` strips font references; runtime `RadhaLottie` rejects animations with non-bundled font refs |
| **`google_fonts` cache poisoned or fetch fails on low-end** | Medium | Bundled subsets are the fallback; fallback is unit-tested with `HttpOverrides` to deny fetch |
| **PNG icon sneaks in via a copy/paste from another project** | Medium | `no_png_icons` lint + `check_no_png_icons.dart` CI gate; both must be green |
| **Real-prod app icon shipped on dev flavor (or vice versa)** | Low | Per-flavor `flutter_launcher_icons-<flavor>.yaml`; `assert_bundle_isolation.sh` verifies side-by-side install with distinct icons |
| **Lottie 60 fps merged accidentally** | Low | Designer hand-off contract documents 30 fps cap; reviewer checks; `tool/assets/check_lottie_size.dart` warns when a JSON declares `> 30 fps` |
| **Network image without placeholder → blank flash** | Medium | `RadhaProductImage` wrapper enforces placeholder; `no_raw_network_image` lint blocks bypass |
| **Bundled font weight blows past 8 MB** | Low/Medium | `check_font_weight.dart` CI gate; subset script re-run on font additions |
| **Adaptive-icon background colour change ships unintentionally** | Low | The colour is in `flutter_launcher_icons-<flavor>.yaml`; PR diff highlights it; designer + tech lead review required |
| **Designer hand-off bypass** | Medium | Engineering bounces non-compliant PRs back; the contract sits in the same repo so it's not a "different team's problem" |

---

## 20. Cross-references

- `CI_CD_PIPELINE.md` — asset CI gates run as part of `mobile-ci.yml`
- `ENVIRONMENT_CONFIG.md` — per-flavor launcher icons, splash, FCM
- `LOCALIZATION_STRATEGY.md` — bundled font fallback per script, store screenshots per locale
- `FRONTEND_PHASES/FE-02_PHASE.md` — `RadhaTypography`, theme, color tokens
- `FRONTEND_PHASES/FE-03_PHASE.md` — `RadhaIcon`, `RadhaImage`, `RadhaProductImage` wrappers
- `FRONTEND_PHASES/FE-04_PHASE.md` — `RadhaLottie` wrapper, motion system
- `FRONTEND_PHASES/FE-09_PHASE.md` — splash + onboarding asset usage
- `FRONTEND_PHASES/FE-39_PHASE.md` — `tool/performance/image_budget.yaml`, perf gates
- `FRONTEND_PHASES/FE-40_PHASE.md` — store screenshots, app icons, splash final assets
