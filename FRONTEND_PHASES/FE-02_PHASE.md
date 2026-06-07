# Phase FE-02: Design Tokens & Theme System

## Phase Metadata
- **Phase ID**: FE-02
- **Section**: Layer 1 — Foundation
- **Depends On**: FE-01
- **Blocks**: FE-03, FE-04, every screen-level phase
- **Estimated Duration**: 3-4 days
- **Complexity**: Medium

## Goal
Define the entire RADHA visual language as code. Three layers of tokens (primitive → semantic → component) generated into a single `tokens.dart` file. Build the runtime theme system on top of `flex_color_scheme` so that flipping `ThemeMode.dark` or honouring Material You dynamic color is a one-line change. By the end of this phase, every later phase reads colors, type, spacing, radii, elevation, motion durations, and curves from `RadhaTokens` — never hardcoded.

The theme must support light, dark, high-contrast, and Material You dynamic-color modes, all six languages (FE-35 hooks), and respect `MediaQuery.disableAnimations`. A demo screen shipped with this phase shows every token and double-acts as the first golden-test target.

## Why This Phase Matters
- **Premium feel comes from consistency**, not from any single hero animation. Tokens enforce consistency.
- **Dark mode**: 60%+ of Indian Android users keep dark mode on. We can't bolt it on later.
- **Material You** dynamic color on Android 12+ makes the app feel native to the user's device — a free retention boost.
- **Every later phase doc references these tokens by name**, which is what makes the roadmap reviewable.
- **Refactor cost is now or later**. Now is two days. Later is three weeks of regression hunting.

## Prerequisites
- [ ] Backend: none.
- [ ] Earlier FE: FE-01 complete.
- [ ] Design assets: token spreadsheet (Figma → tokens.json export). 1 brand palette + 1 dark palette + 1 high-contrast palette.
- [ ] Fonts: `Inter` (Latin), `Hind` (Devanagari for Hindi/Marathi), `Noto Sans Tamil`, `Noto Sans Telugu`, `Noto Sans Bengali`. Variable weights: 400/500/600/700.

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/design_system/tokens/tokens.dart` | Source of truth (re-exports below) |
| `apps/mobile/lib/design_system/tokens/colors.dart` | Brand + semantic + neutral palettes |
| `apps/mobile/lib/design_system/tokens/typography.dart` | 3 type scales × 5 sizes |
| `apps/mobile/lib/design_system/tokens/spacing.dart` | 8pt grid (s0..s10) |
| `apps/mobile/lib/design_system/tokens/radii.dart` | r0..r5 + pill |
| `apps/mobile/lib/design_system/tokens/elevation.dart` | e0..e5 with M3-aligned shadows |
| `apps/mobile/lib/design_system/tokens/motion.dart` | Duration + Curves vocabulary (matches roadmap) |
| `apps/mobile/lib/design_system/tokens/iconography.dart` | RadhaIcons enum + size scale |
| `apps/mobile/lib/design_system/theme/radha_theme.dart` | `ThemeData light/dark` + `ColorScheme` builders |
| `apps/mobile/lib/design_system/theme/theme_extensions.dart` | `RadhaThemeExtension` for tokens not in M3 |
| `apps/mobile/lib/design_system/theme/dynamic_color.dart` | Material You wrapper (uses `dynamic_color` pkg) |
| `apps/mobile/lib/design_system/theme/theme_controller.dart` | Riverpod controller: light/dark/system + high-contrast toggle |
| `apps/mobile/lib/design_system/showcase/tokens_gallery.dart` | Internal screen rendering every token |
| `apps/mobile/test/design_system/tokens_test.dart` | Token contract tests |
| `apps/mobile/test/design_system/theme_golden_test.dart` | Goldens: tokens_gallery in light + dark + dynamic |
| `apps/mobile/assets/fonts/*.ttf` | 5 font families |
| `apps/mobile/docs/design_system.md` | Designer-facing reference |

## Token Spec

### Color (primitive layer)

```dart
// design_system/tokens/colors.dart
class _Brand {
  static const saffron50  = Color(0xFFFFF6E5);
  static const saffron100 = Color(0xFFFFE4B0);
  static const saffron300 = Color(0xFFFFB347);
  static const saffron500 = Color(0xFFFF8A00); // brand primary
  static const saffron700 = Color(0xFFCC6E00);
  static const saffron900 = Color(0xFF8A4A00);

  static const teal500 = Color(0xFF00A39B);   // brand secondary (RADHA Verified)
  static const indigo500 = Color(0xFF3B4CCA); // tertiary / accents
}

class _Semantic {
  static const success500 = Color(0xFF1FAB57); // green - safe scan
  static const warning500 = Color(0xFFE0A100); // amber - moderate
  static const danger500  = Color(0xFFD64545); // red - allergen, recall, expired
  static const info500    = Color(0xFF2D7BD6); // info / neutral notice
}

class _Neutral {
  static const n0   = Color(0xFFFFFFFF);
  static const n50  = Color(0xFFF7F7F8);
  static const n100 = Color(0xFFEDEEF0);
  static const n200 = Color(0xFFD9DBDF);
  static const n300 = Color(0xFFB6B9C2);
  static const n500 = Color(0xFF6E7280);
  static const n700 = Color(0xFF3A3D45);
  static const n900 = Color(0xFF161821);
  static const n950 = Color(0xFF0B0C12); // dark surface base
}
```

### Color (semantic layer — what screens consume)

```dart
class RadhaColors {
  final Color brand, brandOn, brandContainer, brandOnContainer;
  final Color surface, surfaceElevated, surfaceMuted, onSurface, onSurfaceMuted;
  final Color success, successContainer, onSuccess, onSuccessContainer;
  final Color warning, warningContainer, onWarning, onWarningContainer;
  final Color danger, dangerContainer, onDanger, onDangerContainer;
  final Color allergen, recall, expired; // semantic shortcuts to danger variants
  final Color verifiedBadge, premiumBadge;
  final Color outline, divider, scrim;

  const RadhaColors._(...)
  factory RadhaColors.light() => ...;
  factory RadhaColors.dark() => ...;
  factory RadhaColors.fromDynamic(ColorScheme cs) => ...; // Material You
  factory RadhaColors.highContrastLight() => ...;
  factory RadhaColors.highContrastDark() => ...;
}
```

Pattern: every screen reads `Theme.of(context).extension<RadhaThemeExtension>()!.colors.allergen` — never `Colors.red`.

### Typography (3 scales)

| Scale | Used for |
|---|---|
| `display` | Splash hero, paywall, big celebrate moments |
| `text` | Body / titles / labels — 95% of the app |
| `mono` | Numbers, EAN codes, OHS scores, batch codes |

Each scale has 5 sizes:

```dart
class RadhaTypography {
  // text scale (primary)
  final TextStyle textXs;   // 12 / 16 — captions
  final TextStyle textSm;   // 14 / 20 — body small
  final TextStyle textMd;   // 16 / 24 — body
  final TextStyle textLg;   // 18 / 26 — emphasized body
  final TextStyle textXl;   // 22 / 28 — section titles
  // display
  final TextStyle displayMd; // 28 / 34
  final TextStyle displayLg; // 36 / 42
  final TextStyle displayXl; // 48 / 54
  // mono
  final TextStyle monoSm;    // 14 / 20 — EAN
  final TextStyle monoMd;    // 18 / 24 — OHS large
}
```

All sizes scale with `MediaQuery.textScalerOf(context)` — capped at 1.4 to prevent layout breakage on extreme accessibility settings.

### Spacing (8pt grid)

```dart
class RadhaSpacing {
  static const s0  = 0.0;
  static const s1  = 4.0;
  static const s2  = 8.0;
  static const s3  = 12.0;
  static const s4  = 16.0;
  static const s5  = 20.0;
  static const s6  = 24.0;
  static const s7  = 32.0;
  static const s8  = 40.0;
  static const s9  = 56.0;
  static const s10 = 80.0;
}
```

### Radii

```dart
class RadhaRadii {
  static const r0   = Radius.zero;
  static const r1   = Radius.circular(4);
  static const r2   = Radius.circular(8);
  static const r3   = Radius.circular(12); // default card
  static const r4   = Radius.circular(16); // sheet
  static const r5   = Radius.circular(24); // hero
  static const pill = Radius.circular(999);
}
```

### Elevation

| Token | dp | Shadow blur | Used for |
|---|---|---|---|
| `e0` | 0 | none | flush surfaces, outlined cards |
| `e1` | 1 | 2px / 0,1 | resting cards |
| `e2` | 3 | 6px / 0,2 | filled buttons, FAB resting |
| `e3` | 6 | 12px / 0,4 | sheet, dialog backdrop edge |
| `e4` | 12 | 24px / 0,8 | modal, paywall card |
| `e5` | 24 | 48px / 0,16 | full-screen overlay |

Dark mode replaces shadows with surface-tint per Material 3 spec — handled inside `flex_color_scheme`.

### Motion

```dart
class RadhaMotion {
  static const instant     = Duration.zero;
  static const fast        = Duration(milliseconds: 120);
  static const normal      = Duration(milliseconds: 200);
  static const slow        = Duration(milliseconds: 320);
  static const expressive  = Duration(milliseconds: 480);
  static const celebrate   = Duration(milliseconds: 800);

  static const easeOut       = Curves.easeOutCubic;
  static const easeInOut     = Curves.easeInOutCubic;
  static const expressiveOut = Cubic(0.16, 1.0, 0.3, 1.0);
  static const spring        = SpringDescription(mass: 1, stiffness: 200, damping: 18);
}
```

A reduced-motion variant collapses every duration to `fast` and replaces `expressive` with `linear`.

## Theme Wiring

```dart
// design_system/theme/radha_theme.dart
class RadhaTheme {
  static ThemeData light({ColorScheme? dynamicScheme}) {
    final scheme = dynamicScheme ?? FlexColorScheme.light(
      colors: const FlexSchemeColor(
        primary: _Brand.saffron500,
        secondary: _Brand.teal500,
        tertiary: _Brand.indigo500,
        // ...
      ),
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurfaces,
      blendLevel: 8,
      subThemesData: const FlexSubThemesData(
        defaultRadius: 12,
        useTextTheme: true,
        elevatedButtonElevation: 1,
        inputDecoratorRadius: 12,
        bottomSheetRadius: 24,
      ),
    ).toScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _buildTextTheme(scheme.brightness),
      extensions: [
        RadhaThemeExtension(
          colors: dynamicScheme != null
            ? RadhaColors.fromDynamic(scheme)
            : RadhaColors.light(),
          typography: RadhaTypography.fromScheme(scheme),
          spacing: const RadhaSpacing(),
        ),
      ],
    );
  }

  static ThemeData dark({ColorScheme? dynamicScheme}) { ... }
}
```

```dart
// design_system/theme/theme_controller.dart
@riverpod
class ThemeController extends _$ThemeController {
  @override
  ThemeMode build() => ThemeMode.system;
  void setMode(ThemeMode m) => state = m;
}

@riverpod
class HighContrastController extends _$HighContrastController {
  @override bool build() => false;
  void toggle() => state = !state;
}
```

Top of widget tree:

```dart
class RadhaApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    final hc = ref.watch(highContrastControllerProvider);
    return DynamicColorBuilder(builder: (light, dark) {
      return MaterialApp.router(
        themeMode: mode,
        theme: RadhaTheme.light(dynamicScheme: light, highContrast: hc),
        darkTheme: RadhaTheme.dark(dynamicScheme: dark, highContrast: hc),
        routerConfig: ref.watch(routerProvider),
      );
    });
  }
}
```

## Visual Behaviour (Tokens Gallery screen — also goldens target)

| State | Visual |
|---|---|
| **Default load** | Single ScrollView showing every primitive color, every semantic color, every type scale, every spacing rule, every radius, every elevation, every motion duration, all live. Each item labeled with its token name. |
| **Tap a color swatch** | Light haptic + snackbar with hex + token name (`RadhaColors.allergen — #D64545`). |
| **Theme switcher (top)** | Three-button segmented control: System / Light / Dark. Tap = `motion.normal` cross-fade across the whole screen. |
| **High-contrast toggle** | Switch in app bar; flips the `RadhaColors` set with a 200 ms cross-fade. |
| **Dynamic-color toggle** | Switch labelled "Material You" — Android 12+ only, disabled with tooltip on iOS. |
| **Reduced motion ON** | Every animation collapses to `fast` linear; elevation transitions become instant. Verify by toggling system setting and observing. |
| **RTL mock** | Long-press app bar to flip `Directionality.rtl` (testing only — not user-facing). |
| **Font size XL (system)** | Type scales up to cap of 1.4×; spacing and layout do not break. |

## Animations
- **Theme switch cross-fade**: 200 ms `motion.normal`, opacity blend on `MaterialApp` rebuild via `AnimatedTheme` wrapper.
- **High-contrast flip**: 200 ms cross-fade.
- **Token gallery load-in**: stagger of 40 ms per row using `flutter_animate` `.animate(delay: index * 40.ms).fadeIn()` — capped at 12 visible rows so total ≤ 480 ms.
- **No Lottie** in this phase — pure declarative motion. (Lottie pack lives in FE-04 / FE-33.)
- **Motion budget per screen**: ≤ 480 ms aggregated.

## Accessibility
- **Contrast**: every semantic color pair (e.g. `onSurface` on `surface`) ≥ 4.5:1 in both light + dark. The token tests assert this.
- **High-contrast**: dedicated palette pushes ratios to ≥ 7:1.
- **Dynamic type**: text scales to system, capped at 1.4×; goldens cover 1.0× and 1.4×.
- **Semantics**: token gallery rows have descriptive labels (`'Color token: allergen, hex D64545, contrast ratio 5.1 to 1'`).
- **Reduced motion**: all motion tokens auto-degrade.
- **Focus**: keyboard traversal works through the gallery in source order (verified in `meta` test).

## Testing
- **Token contract test**: `RadhaColors` exposes every documented field; missing field = test fails.
- **Contrast test**: assert WCAG AA (4.5:1) on every (`onX`, `X`) pair in both themes — uses `Color`'s computeLuminance.
- **Theme switching test**: pump app, change `ThemeController.setMode(dark)`, expect surface color matches dark token within 200 ms.
- **Dynamic color test**: stub `DynamicColorBuilder` with a custom palette, expect `RadhaColors.fromDynamic` produces semantic mapping (brand stays saffron — only neutrals adapt).
- **Golden tests**: 6 baselines:
  - `tokens_gallery_light.png`
  - `tokens_gallery_dark.png`
  - `tokens_gallery_light_hc.png`
  - `tokens_gallery_dark_hc.png`
  - `tokens_gallery_light_xl_text.png`
  - `tokens_gallery_dynamic.png` (uses fixed seed palette)
- **Integration test** (smoke): on Pixel 4a emulator, switch theme 5 times — frame budget < 16.6 ms p99 on the swap frame.

## Risk Assessment
| Risk | Likelihood | Mitigation |
|---|---|---|
| Brand colors clash with Material You dynamic palette | Medium | Brand primary always wins (`onPrimary` derived from brand, not from `seed`); dynamic only adapts neutrals + tertiary. Demoed in goldens. |
| Inconsistent token usage in later phases | High | ESLint-style lint rule (custom `lint`): forbid raw `Color(0x…)` in `lib/features/**`. Custom analyzer plugin. |
| Font files balloon APK size | Medium | Subset Devanagari/Tamil/Telugu/Bengali to deliver via runtime download (`google_fonts` package + cache) for non-default locales. Default English bundled. |
| Dark-mode shadow dropouts | Low | Use M3 surface tint, not `BoxShadow`, in elevation tokens. |
| Theme rebuild jank | Low | `AnimatedTheme` is cached; profile run shows ≤ 16 ms swap frame. |

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | `RadhaColors.light().allergen` equals `_Semantic.danger500`. |
| T2 | `RadhaColors.dark().success` differs from `RadhaColors.light().success` (lighter for legibility). |
| T3 | All (color, onColor) pairs in light theme score ≥ 4.5:1 contrast (asserted in test). |
| T4 | All (color, onColor) pairs in dark theme score ≥ 4.5:1 contrast. |
| T5 | All pairs in high-contrast theme score ≥ 7:1. |
| T6 | `RadhaTypography.textMd.fontSize` is 16 and `height` is `24/16 = 1.5`. |
| T7 | `RadhaSpacing.s4` is 16.0 and is a multiple of 8 (asserted by test scanning every token). |
| T8 | Theme switcher: setting `ThemeMode.dark` causes `Theme.of(context).brightness` to be `Brightness.dark` after a single frame pump. |
| T9 | `RadhaMotion.expressiveOut` equals `Cubic(0.16, 1.0, 0.3, 1.0)`. |
| T10 | Reduced-motion provider returns `fast` for any motion request when the system reduces motion. |
| T11 | `flutter test --update-goldens` produces stable PNGs (re-running CI shows zero diff). |
| T12 | Lint rule rejects a screen file containing `Color(0xFF…)` outside `lib/design_system/tokens/`. |
| T13 | `DynamicColorBuilder` with a fixed seed produces a `RadhaColors` with brand still saffron and neutrals adapted. |
| T14 | Long-press in tokens gallery flips `Directionality` to RTL and layout still passes goldens. |
| T15 | App size delta from FE-01 to FE-02 is < 2 MB on prod release APK. |

### Q&A Questions (8)

1. Why three layers (primitive → semantic → component) instead of one flat token list? Where do component tokens live?
2. How does `RadhaThemeExtension` interact with `Theme.of(context).colorScheme` — when does a developer use which?
3. What's the rule for adding a new semantic color (e.g. `caution`)? Who approves and where does it land?
4. How is dynamic color (Material You) reconciled with brand primary? Which colors adapt vs stay fixed?
5. How does the high-contrast toggle interact with system "Increase Contrast" on iOS / Android Accessibility setting?
6. Why is `monoSm`/`monoMd` a separate scale instead of using `FontFeature.tabularFigures` on `text`?
7. What happens to text sizing when a user has both system text scale 1.5× and our cap is 1.4×?
8. How do we ensure third-party widgets (e.g. `firebase_auth_ui`) inherit the theme without hardcoded styling?

## Sign-off Gate
- [ ] Developer: 15 tests pass, golden baselines committed.
- [ ] Developer: 8 Q&A answered in handoff.
- [ ] Developer: `docs/design_system.md` walks a designer through all tokens.
- [ ] Reviewer: ran tokens_gallery on a Pixel 4a + iPhone SE 2 in light, dark, dynamic.
- [ ] Reviewer: spot-checked contrast ratios with browser dev-tools.
- [ ] Reviewer: confirmed no hardcoded colors in committed code outside `tokens/`.

**Developer Signature**: ___________________________

**☐ APPROVED — Proceed to FE-03**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF FE-02 — DO NOT PROCEED WITHOUT APPROVAL**
