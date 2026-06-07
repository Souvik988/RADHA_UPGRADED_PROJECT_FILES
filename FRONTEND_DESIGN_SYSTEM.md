# RADHA Mobile — Frontend Design System

> **Version**: `v1.0.0`
> **Last updated**: 2026-05-17
> **Owner**: Design Lead + Frontend Tech Lead (joint sign-off on every change)
> **Status**: **Locked for v1.** Token additions are MINOR bumps; renames or value changes are MAJOR bumps.

This document defines every visible token used in the RADHA Flutter app: spacing, typography, color, radius, shadow, motion, haptics, breakpoints, and component contracts. It is reference material, not advice. Code that contradicts this document fails the token-lint check (`tool/design/lint_tokens.dart`) referenced from `FRONTEND_VERIFICATION_SYSTEM.md`.

Constrained by:
- **ADR-006** — `flex_color_scheme` 7.3 + Material 3 + `ThemeExtension`.
- **ADR-002** — token consumers are Riverpod-aware (custom theme tokens reachable through `Theme.of`).
- **ADR-010** — primitives live in `lib/widgets/`, screens consume them.

---

## 1. Versioning

Semantic versioning of the **token surface** (not the package version):

| Bump | When |
|---|---|
| **MAJOR** | A token value changes (e.g. `radius.md` 12 → 14), a token is renamed, or a token is removed. |
| **MINOR** | A token is added (e.g. new `motion.celebrate-xl`). |
| **PATCH** | Documentation-only fix (typo, clarification). |

Every change appends an entry to the **Changelog** at the bottom of this file with the date, the bumped version, and the affected files. Phase docs that change tokens must reference the bump in their Sign-off Gate.

The current bumped version is **v1.0.0**.

---

## 2. Spacing scale

A single, strict 4-dp ladder. No other values are allowed in widget code.

| Token | dp | Use |
|---|---|---|
| `spacing.xxs` | 4 | hairline gap, icon-to-text inside a chip |
| `spacing.xs` | 8 | inner padding of compact chips, gap inside a row of icons |
| `spacing.sm` | 12 | input field internal padding-y, list-item secondary text gap |
| `spacing.md` | 16 | screen edge padding, default vertical gap between cards |
| `spacing.lg` | 24 | section break between unrelated card groups |
| `spacing.xl` | 32 | hero/header to body gap |
| `spacing.xxl` | 48 | empty state vertical breathing room |
| `spacing.xxxl` | 64 | celebratory states, splash hero |

Implementation:

```dart
@immutable
class RadhaSpacing extends ThemeExtension<RadhaSpacing> {
  const RadhaSpacing({
    this.xxs = 4,
    this.xs = 8,
    this.sm = 12,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xxl = 48,
    this.xxxl = 64,
  });
  final double xxs, xs, sm, md, lg, xl, xxl, xxxl;
  @override
  RadhaSpacing copyWith({...}) => ...;
  @override
  RadhaSpacing lerp(ThemeExtension<RadhaSpacing>? other, double t) => this;
}
```

Non-token literal `Padding(padding: EdgeInsets.all(20))` fails CI unless tagged `// design:ok` with a reviewer signature in the same line.

---

## 3. Typography scale

Two typefaces only:

- **Plus Jakarta Sans** (display + body) — paid, embedded as TTF in `assets/fonts/`.
- **JetBrains Mono** (numerics, monospace contexts: scan codes, IDs, audit timestamps) — OFL.

Banned typefaces in widget code: **Inter, Roboto, Roboto Flex, Arial, Helvetica, sans-serif fallbacks.** The token-lint pack rejects `fontFamily: 'Inter'` and similar.

Full Material 3 type ramp (mapped to `Theme.of(context).textTheme.*`):

| Token | Size / dp | Weight | Tracking | Line-height | Use |
|---|---|---|---|---|---|
| `displayLarge`  | 57 | 700 | -0.25 | 64 | reserved (splash hero only) |
| `displayMedium` | 45 | 700 | 0     | 52 | onboarding hero number |
| `displaySmall`  | 36 | 700 | 0     | 44 | section hero (e.g. OHS score) |
| `headlineLarge` | 32 | 600 | 0     | 40 | screen titles (premium screens) |
| `headlineMedium`| 28 | 600 | 0     | 36 | screen titles (default) |
| `headlineSmall` | 24 | 600 | 0     | 32 | dialog titles, sheet headers |
| `titleLarge`    | 22 | 600 | 0     | 28 | card titles, AppBar |
| `titleMedium`   | 16 | 600 | 0.15  | 24 | list item primary |
| `titleSmall`    | 14 | 600 | 0.10  | 20 | small section headers |
| `bodyLarge`     | 16 | 400 | 0.50  | 24 | primary body text |
| `bodyMedium`    | 14 | 400 | 0.25  | 20 | secondary body text |
| `bodySmall`     | 12 | 400 | 0.40  | 16 | helper text, captions |
| `labelLarge`    | 14 | 600 | 0.10  | 20 | button labels |
| `labelMedium`   | 12 | 600 | 0.50  | 16 | chip labels, tab labels |
| `labelSmall`    | 11 | 600 | 0.50  | 16 | badges, micro-meta |

JetBrains Mono is exposed via a separate text role:

```dart
extension RadhaMonoText on TextTheme {
  TextStyle get monoBody => bodyLarge!.copyWith(fontFamily: 'JetBrainsMono');
  TextStyle get monoLabel => labelMedium!.copyWith(fontFamily: 'JetBrainsMono');
}
```

Uses: EAN/barcode strings, batch numbers, GRN reference IDs, audit timestamps, sync queue counts.

Dynamic type is honoured: every text widget uses theme roles (no hardcoded `fontSize: 14`). At `MediaQuery.textScaleFactor = 2.0` (xxLarge), layouts must not clip.

---

## 4. Radius tokens

| Token | dp | Use |
|---|---|---|
| `radius.xs` | 4 | chips, small badges |
| `radius.sm` | 8 | inputs, snackbars |
| `radius.md` | 12 | buttons (primary/secondary), cards (compact) |
| `radius.lg` | 16 | cards, sheets, dialogs |
| `radius.xl` | 24 | bottom sheets handle area, hero cards |
| `radius.full` | 9999 | pill chips, FAB, avatars |

Implementation via `RadhaCustomRadii extends ThemeExtension<RadhaCustomRadii>`. Component code calls `Theme.of(context).extension<RadhaCustomRadii>()!.md`. Direct `BorderRadius.circular(10)` outside theme files fails CI.

---

## 5. Shadow / elevation tokens

Material 3 elevation values, but soft tinted shadows replace harsh black drop shadows.

| Token | Elevation | Shadow color | Blur | Y-offset | Use |
|---|---|---|---|---|---|
| `elevation.0` | 0 | none | — | — | flush surfaces |
| `elevation.1` | 1 | `Color(0x14000000)` | 8 | 1 | resting cards |
| `elevation.3` | 3 | `Color(0x1A000000)` | 12 | 2 | floating cards (hover-equivalent on touch) |
| `elevation.6` | 6 | `Color(0x1F000000)` | 16 | 4 | sheets, dialogs |
| `elevation.12` | 12 | `Color(0x29000000)` | 24 | 8 | FAB pressed, modal backdrops |

Banned: `BoxShadow(color: Colors.black, ...)` at full opacity, multi-layer drop shadows, `BlurStyle.outer`.

Dark mode uses tonal lifts (`surfaceContainer`, `surfaceContainerHigh`), not raw shadows. Shadow alpha is reduced 30% in dark mode (e.g. `Color(0x0E000000)` for elevation 1).

---

## 6. Color system

### 6.1 Brand

- **Primary**: emerald `#10B981` (single accent — no purple/blue gradient anywhere in the app).
- **Primary container**: `#A7F3D0` (light), `#065F46` (dark).
- **On primary**: `#FFFFFF`.
- **On primary container**: `#022C22` (light), `#D1FAE5` (dark).

### 6.2 Semantic — Light mode

| Role | Hex | Notes |
|---|---|---|
| `surface` | `#FFFFFF` | scaffold background |
| `surfaceContainer` | `#F4F6F5` | cards |
| `surfaceContainerHigh` | `#ECEEED` | sheet, dialog |
| `onSurface` | `#0F172A` | primary text |
| `onSurfaceMuted` | `#475569` | secondary text |
| `outline` | `#CBD5E1` | dividers, inactive borders |
| `outlineVariant` | `#E2E8F0` | hairline dividers |
| `primary` | `#10B981` | brand emerald |
| `success` | `#16A34A` | positive states |
| `warning` | `#F59E0B` | amber, expiry-near |
| `danger` | `#E11D48` | rose, recall + critical errors |
| `info` | `#0284C7` | informational chips |

### 6.3 Semantic — Dark mode

| Role | Hex | Notes |
|---|---|---|
| `surface` | `#0B1117` | scaffold background |
| `surfaceContainer` | `#111A22` | cards |
| `surfaceContainerHigh` | `#172230` | sheet, dialog |
| `onSurface` | `#E5E9EE` | primary text |
| `onSurfaceMuted` | `#94A3B8` | secondary text |
| `outline` | `#334155` | dividers |
| `outlineVariant` | `#1F2A37` | hairline dividers |
| `primary` | `#10B981` | full saturation preserved |
| `success` | `#22C55E` | adjusted for contrast |
| `warning` | `#FBBF24` | warmer amber |
| `danger` | `#FB7185` | softer rose |
| `info` | `#38BDF8` | sky |

### 6.4 Strategy

- Every color comes from `Theme.of(context).colorScheme.*` or a `RadhaSemanticColors extends ThemeExtension` for non-M3 roles (`onSurfaceMuted`, `success`, `warning`, `danger`, `info`).
- Hardcoded `Color(0x...)` outside `theme/`, `widgets/foundation/`, or assets fails CI.
- WCAG AA contrast verified for every text role over its surface (`onSurface` over `surface` ≥ 4.5:1; muted text over surface ≥ 4.5:1 at body sizes).
- Brand emerald stays at full saturation in both modes (no automatic tonal adjustment).

---

## 7. Theme strategy

```dart
ThemeData buildLightTheme() {
  return FlexThemeData.light(
    colors: const FlexSchemeColor(
      primary: Color(0xFF10B981),
      primaryContainer: Color(0xFFA7F3D0),
      // ... full mapping
    ),
    useMaterial3: true,
    subThemesData: const FlexSubThemesData(
      defaultRadius: 12,
      inputDecoratorRadius: 12,
      buttonMinSize: Size(0, 44),
      // ... see widgets section
    ),
    fontFamily: 'PlusJakartaSans',
    extensions: <ThemeExtension<dynamic>>[
      const RadhaSpacing(),
      const RadhaCustomRadii(),
      const RadhaMotion(),
      const RadhaHaptics(),
      const RadhaSemanticColors.light(),
    ],
  );
}
```

Dark mode is symmetric (`FlexThemeData.dark`). Dynamic color (Material You) is opt-in per flavor: enabled in dev/staging for visual testing, off in prod v1 (RADHA brand emerald is the source of truth).

---

## 8. Adaptive layout breakpoints

Phone is the primary surface. Tablet and desktop are supplementary (Web only).

| Class | Width range | Behaviour |
|---|---|---|
| `phone` | < 600 dp | single-column, max content width 600 dp |
| `tablet` | 600 – 905 dp | 2-pane on detail screens, max content width 720 dp |
| `desktop` | ≥ 905 dp | reserved for Flutter Web only — same widgets, wider gutters |

```dart
enum RadhaBreakpoint { phone, tablet, desktop }
extension BreakpointOf on BuildContext {
  RadhaBreakpoint get bp {
    final w = MediaQuery.sizeOf(this).width;
    if (w < 600) return RadhaBreakpoint.phone;
    if (w < 905) return RadhaBreakpoint.tablet;
    return RadhaBreakpoint.desktop;
  }
}
```

Layout rules:
- Phone: `EdgeInsets.symmetric(horizontal: spacing.md)` for screen content.
- Tablet: max content width 720 dp, centered, with `spacing.lg` gutters.
- Bottom navigation bar height: 72 dp + safe-area inset (no fixed pixel value; uses `MediaQuery.padding.bottom`).
- Safe-area aware via `SafeArea(top: ..., bottom: ...)` on every screen scaffold.

---

## 9. Platform adaptations

Material 3 is the default on both platforms. Cupertino is used selectively:

- **iOS back gesture**: routes use `CupertinoPageRoute` only on iOS (`Platform.isIOS`); GoRouter handles the swap via a builder.
- **iOS back button**: `CupertinoNavigationBarBackButton` in `AppBar.leading` on iOS only.
- **Everything else** (buttons, sheets, dialogs, switches, sliders) stays Material on both platforms for one-codebase consistency.

Banned: `CupertinoButton` in screen code, `CupertinoSwitch`, `CupertinoSlider`, ad-hoc `Platform.isIOS` branching outside `lib/widgets/foundation/platform_adapter.dart`.

---

## 10. Component hierarchy

Atomic → composite ladder:

```
tokens (spacing, color, radius, motion, haptics, typography)
  ↓
primitives (PrimaryButton, AppTextField, AppCard, AppDivider, AppIcon, AppAvatar)
  ↓
patterns  (StatusChip, SectionHeader, EmptyState, ErrorState, SkeletonLoader,
           BottomSheet, AppDialog, FAB, Toast, BannerBar)
  ↓
screens   (lib/features/<domain>/presentation/*)
```

Rules:
- Primitives never call `BuildContext`-dependent token lookups inline — they always read from `Theme.of(context).extension<...>()!`.
- Screens never instantiate raw `Container`s for visual styling — they compose primitives and patterns.
- A new pattern requires a `widgetbook` story (see FE-03) and a golden file before a screen consumes it.

---

## 11. Button system

Five variants, three sizes, four states.

### Variants
| Variant | Use | Background | Foreground | Border |
|---|---|---|---|---|
| `PrimaryButton` | high-emphasis CTA, one per screen | `primary` | `onPrimary` | none |
| `SecondaryButton` | medium-emphasis | `surfaceContainerHigh` | `onSurface` | 1 dp `outline` |
| `TextButton` | low-emphasis, inline | transparent | `primary` | none |
| `IconButton` | icon-only action | transparent | `onSurface` | none, 48 dp tap target |
| `FAB` | screen-wide primary action | `primary` | `onPrimary` | none, elevation 6 |

### Sizes
| Size | Height | Horizontal padding | Label style |
|---|---|---|---|
| `sm` | 36 | 12 | `labelMedium` |
| `md` (default) | 44 | 16 | `labelLarge` |
| `lg` | 56 | 24 | `labelLarge` |

Minimum height is 44 dp visual; `MaterialTapTargetSize.padded` ensures the tap target is ≥ 48 dp even when visual is `sm`.

### States
| State | Visual |
|---|---|
| `default` | base colors |
| `pressed` | tonal overlay 0.12 alpha, scale 0.98, `motion.fast` |
| `disabled` | 0.38 opacity on foreground, 0.12 on background, no haptics |
| `loading` | label replaced by 18-dp `CircularProgressIndicator`; button retains its width to prevent layout shift |

Haptic on press: `haptic.light` for primary/secondary, `haptic.tap` for text/icon, `haptic.medium` for FAB.

### Public API

```dart
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = ButtonSize.md,
    this.loading = false,
    this.fullWidth = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;        // null = disabled
  final IconData? icon;
  final ButtonSize size;
  final bool loading;
  final bool fullWidth;
  ...
}
```

---

## 12. Input system

`AppTextField` is the only input primitive. Five variants by `TextInputType`:

| Variant | Keyboard | Validation hook |
|---|---|---|
| `text` | `TextInputType.text` | optional |
| `email` | `TextInputType.emailAddress` | RFC 5322 light |
| `phone` | `TextInputType.phone` | E.164 / 10-digit IN |
| `otp` | `TextInputType.number`, `obscureText: false`, length-bound | digit-only |
| `multiline` | `TextInputType.multiline`, `maxLines: 5` | optional |

Layout:
- **Label** above the field, `titleSmall`, `onSurfaceMuted`.
- **Input** 56 dp height, 12 dp internal padding, `radius.md`.
- **Helper / error** below, `bodySmall`. Helper is `onSurfaceMuted`; error is `danger`.
- **Focus ring**: 2 dp `primary` outline.
- **Error ring**: 2 dp `danger` outline; an icon (`circle-warning`) leads the helper text.
- **Disabled**: 0.38 opacity, no border highlight.

Counter widgets use `JetBrainsMono` for digit alignment.

---

## 13. Layout standards

- **Screen content max width**: 600 dp on phone, 720 dp on tablet, centered.
- **Screen edge padding**: `spacing.md` (16 dp) horizontal, `spacing.md` top, safe-area bottom.
- **Card spacing**: `spacing.md` between sibling cards; `spacing.lg` between unrelated card groups.
- **Bottom navigation**: 72 dp + safe-area inset, fixed; never scrolls off-screen.
- **AppBar**: 56 dp default, 64 dp when used with a `bottom: TabBar`.
- **FAB**: anchored bottom-right with `spacing.md` margin, 56 dp diameter.

Every screen scaffold follows the pattern:

```dart
Scaffold(
  appBar: AppBar(...),
  body: SafeArea(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Padding(padding: EdgeInsets.symmetric(horizontal: spacing.md), child: ...),
    ),
  ),
);
```

---

## 14. Motion standards

| Token | Duration | Curve | Use |
|---|---|---|---|
| `motion.instant` | 0 ms | linear | toggles, internal-state-only |
| `motion.fast` | 120 ms | `Curves.easeOutCubic` | hover/press feedback, chip press |
| `motion.normal` | 200 ms | `Curves.easeInOutCubic` | sheet open, dialog enter, banner reveal |
| `motion.slow` | 320 ms | `Curves.easeOutQuint` | route transitions (non-Hero) |
| `motion.expressive` | 480 ms | `Cubic(0.16, 1, 0.3, 1)` | Hero choreography, big reveals |
| `motion.celebrate` | 800 ms | spring(stiffness: 200, damping: 18) | success animations, confetti |

Reduced motion: when `MediaQuery.disableAnimationsOf(context)` is true, durations collapse to 0 ms and Lottie files swap to a static frame. Implementation lives in `lib/widgets/foundation/motion.dart`. Phase FE-04 ships the foundation; FE-33 hardens the Lottie pack.

```dart
@immutable
class RadhaMotion extends ThemeExtension<RadhaMotion> {
  const RadhaMotion();
  Duration get instant     => Duration.zero;
  Duration get fast        => const Duration(milliseconds: 120);
  Duration get normal      => const Duration(milliseconds: 200);
  Duration get slow        => const Duration(milliseconds: 320);
  Duration get expressive  => const Duration(milliseconds: 480);
  Duration get celebrate   => const Duration(milliseconds: 800);
  Curve get easeOut        => Curves.easeOutCubic;
  Curve get easeInOut      => Curves.easeInOutCubic;
  Curve get easeOutQuint   => Curves.easeOutQuint;
  Cubic get expressiveCurve=> const Cubic(0.16, 1, 0.3, 1);
  ...
}
```

Banned: hard-coded `Duration(milliseconds: 250)` in screen code.

---

## 15. Error standards

| Surface | Use | Component |
|---|---|---|
| **Inline** below a field | input validation | helper-text slot of `AppTextField` |
| **Toast** (top, dismissible) | transient action result (saved, copied, undo) | `RadhaToast` (via `ScaffoldMessenger`) |
| **Banner** (top, persistent) | session-scoped state (offline, sync paused) | `BannerBar` |
| **Full-screen** | unrecoverable state on a route load | `ErrorState` widget |

Rules:
- Errors **never block the back button.** Even in a full-screen error, `Navigator.pop` works.
- Every error shows: title (`titleMedium`), description (`bodyMedium`), at least one CTA (Retry / Go back / Contact support).
- Network errors include the underlying status code in a `dev`-only diagnostic line (visible behind a long-press in non-prod).
- Server-mapped errors (BE-44 sync) include the correlation ID so support can trace.

---

## 16. Loading standards

| Duration of operation | Treatment |
|---|---|
| < 100 ms | no indicator; render result directly |
| 100 – 300 ms | inline spinner only on the triggering control |
| ≥ 300 ms | skeleton placeholder for the upcoming surface |
| Splash only | full-screen Lottie (`radha_logo_loop.json`, ≤ 60 KB) |

`SkeletonLoader` is the canonical primitive; it shimmers using `motion.normal` and respects reduced motion (turns into a flat `surfaceContainerHigh` block).

Banned: `Center(child: CircularProgressIndicator())` as a screen-level state. Use `SkeletonLoader` matching the eventual layout.

---

## 17. Empty standards

Every list/grid/feed screen renders an `EmptyState`, never a blank canvas:

```dart
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.illustration,   // SVG or Lottie asset
    required this.title,          // titleMedium
    required this.body,           // bodyMedium, optional
    this.cta,                     // optional PrimaryButton
    super.key,
  });
}
```

Patterns: scanner first-launch shows "Point at a barcode to begin"; tasks-empty shows "No tasks today, go celebrate"; expiry-empty shows "All clear, no items expiring soon" with a green check Lottie.

---

## 18. Touch targets

Minimum **48 × 48 dp** on every tappable element. Visual size may be smaller; tap target is enforced via `MaterialTapTargetSize.padded` and explicit `Padding`/`SizedBox.expand` wrappers.

The custom-lint pack flags any `GestureDetector` or `InkWell` whose enclosing constraint is less than 48 dp on either axis.

---

## 19. Accessibility standards

- **Dynamic type**: every text uses theme roles. At `MediaQuery.textScaleFactor = 2.0`, layouts must not clip; verified by golden tests.
- **Semantics**: every non-decorative widget has a `Semantics(label: ...)`. Decorative Lotties use `excludeSemantics: true` and a sibling `Semantics(label: 'Loading')` when needed.
- **Focus order**: matches reading order; verified by `tester.binding.focusManager.primaryFocus` traversal in widget tests.
- **Reduced motion**: motion tokens respect `MediaQuery.disableAnimationsOf`.
- **High contrast**: when `MediaQuery.highContrastOf(context)` is true, the theme switches to high-contrast variants (`outline` becomes `onSurface`, shadow alpha doubles).
- **Color contrast**: WCAG AA verified for every `(text role, surface role)` pair, AAA for body text.
- **Screen-reader walkthrough**: every screen has a TalkBack/VoiceOver script in its phase doc.

---

## 20. Icon system

- **Primary icon set**: **Phosphor Icons** (`phosphor_flutter`), Regular weight, 1.5 dp stroke.
- **Fallback set**: **Material Symbols Rounded** (used only where Phosphor lacks a glyph; documented per occurrence).
- **Stroke**: never mix weights on a single screen.
- **Format**: SVG via `flutter_svg`. **PNG icons are banned** (asset bloat, no scaling).
- **Standard sizes**: 16, 20, 24, 32 dp. Other sizes require a `// design:ok` review note.

Every icon in a tappable container has a `semanticLabel`.

---

## 21. Elevation system

Allowed elevations: **0, 1, 3, 6, 12.** No other values.

| Elevation | Component examples |
|---|---|
| 0 | flush surfaces, in-card sub-blocks |
| 1 | resting cards |
| 3 | floating cards on press, pinned headers |
| 6 | sheets, dialogs, snackbars |
| 12 | FAB, modal scrim layer |

Elevation is paired with the shadow tokens in §5. Custom values fail CI.

---

## 22. Dark mode strategy

- Light and dark schemes derive from the same emerald seed via `flex_color_scheme.tones`.
- Surfaces use **tonal lifts** (`surface` → `surfaceContainer` → `surfaceContainerHigh` → `surfaceContainerHighest`) rather than raw inversions.
- Brand emerald is preserved at full saturation in dark mode (`#10B981`).
- Shadows are 30% softer in dark mode (alpha reduction).
- Images and Lottie assets must be tested on both modes; assets that look broken on dark inherit a `colorFilter` from the design tokens (e.g. `BlendMode.modulate` to lift highlights).
- System theme follows `MediaQuery.platformBrightnessOf(context)`; user override stored in secure preferences (FE-07).

---

## 23. RTL readiness

RTL is **not active in v1 GA** (locales en/hi/ta/te/bn/mr are LTR), but the architecture supports it.

Required practices:
- Use `Padding.directional` and `EdgeInsetsDirectional` everywhere; raw `EdgeInsets.fromLTRB` is banned in screen code.
- `Align(alignment: AlignmentDirectional.centerStart)` over `Alignment.centerLeft`.
- Mirror-aware icons (chevrons, arrows) use `Icon(..., textDirection: Directionality.of(context))`.
- A smoke-test locale `ar-EG` is wired in golden tests (FE-38) to catch regressions, even though it is not user-selectable.

When RTL ships in v2, switching `MaterialApp.supportedLocales` is the only change required.

---

## 24. ThemeExtension definitions

The full set registered with `ThemeData.extensions`:

```dart
final extensions = <ThemeExtension<dynamic>>[
  const RadhaSpacing(),                     // §2
  const RadhaCustomRadii(),                 // §4
  const RadhaMotion(),                      // §14
  const RadhaHaptics(),                     // §25
  const RadhaSemanticColors.light(),        // §6 (variant: .dark())
  const RadhaIconTokens(),                  // §20 (sizes + stroke)
  const RadhaElevationTokens(),             // §5 / §21
];
```

Access pattern in widgets:

```dart
final spacing = Theme.of(context).extension<RadhaSpacing>()!;
final motion  = Theme.of(context).extension<RadhaMotion>()!;
```

`riverpod_lint` rule rejects extension lookups in build methods that recompute — they live in `late final` per-state members on `ConsumerStatefulWidget` or in `useMemo`-ed values on `HookConsumerWidget`.

---

## 25. Haptics

| Token | Native | When |
|---|---|---|
| `haptic.tap` | `HapticFeedback.selectionClick` | tab switch, chip toggle |
| `haptic.light` | `HapticFeedback.lightImpact` | primary/secondary button press |
| `haptic.medium` | `HapticFeedback.mediumImpact` | sheet snap, scan capture |
| `haptic.heavy` | `HapticFeedback.heavyImpact` | recall alert, expiry critical |
| `haptic.success` | platform-specific pattern (`HapticPatterns.success`) | scan verified, OTP success |
| `haptic.warning` | platform-specific pattern | allergen flag |
| `haptic.error` | platform-specific pattern | OTP wrong, network fail |

Wrapper: `package:gaptic_feedback`. Behind a `RadhaHaptics` extension so tests can override to no-op without monkey-patching.

---

## 26. Versioning rules

| Change | Bump | Action |
|---|---|---|
| Add `motion.celebrateXl` | MINOR (1.0.0 → 1.1.0) | append to §14 + Changelog |
| Rename `radius.md` → `radius.button` | MAJOR (1.0.0 → 2.0.0) | rewrite §4 + write a migration note in Changelog + open ADR if rename was contentious |
| Change `primary` from `#10B981` to `#0FA876` | MAJOR | rewrite §6 + run a full visual regression pass |
| Fix typo in §17 prose | PATCH | append to Changelog only |

Every MAJOR or MINOR change must:
1. Update the version field at the top of this file.
2. Append a Changelog entry with date, version, and bumped tokens.
3. Reference the change in the next phase doc's Sign-off Gate that touches the affected token.
4. Update `tool/design/lint_tokens.dart` allow-list if a value changes.

---

## Changelog

### v1.0.0 — 2026-05-17
- Initial design system locked.
- Defined: spacing (§2), typography (§3), radius (§4), shadow (§5), color (§6), theme strategy (§7), breakpoints (§8), platform adaptations (§9), component hierarchy (§10), buttons (§11), inputs (§12), layout (§13), motion (§14), errors (§15), loading (§16), empty (§17), touch targets (§18), accessibility (§19), icons (§20), elevation (§21), dark mode (§22), RTL (§23), theme extensions (§24), haptics (§25).
- Locked typefaces: Plus Jakarta Sans + JetBrains Mono.
- Banned: Inter, Roboto, Arial, Helvetica, sans-serif fallbacks.
- Banned: hardcoded color literals in screen code.
- Banned: PNG icons.
- Banned: `CupertinoButton`/`CupertinoSwitch`/`CupertinoSlider` in screen code.
- Banned: elevation values other than {0, 1, 3, 6, 12}.

---

**See also**: `ADR_LOG.md` (ADR-006 theme stack), `FRONTEND_QA_SYSTEM.md` (golden + a11y gates), `FRONTEND_VERIFICATION_SYSTEM.md` (token-lint pipeline), `FRONTEND_PHASES/FE-02_PHASE.md` (initial implementation), `FRONTEND_PHASES/FE-03_PHASE.md` (component library).
