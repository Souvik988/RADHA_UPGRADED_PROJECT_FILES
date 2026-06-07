# Phase FE-35: Multi-Language Runtime + Switcher

## Phase Metadata
- **Phase ID**: FE-35
- **Phase Name**: Multi-Language Runtime + Switcher
- **Section**: Layer 5 — Polish + Cross-cutting
- **Depends On**: FE-01 (project init — `flutter_localizations` dependency added there), FE-02 (typography tokens), FE-03 (component library — every text-bearing widget), FE-07 (Riverpod state for active locale), FE-33 (motion tokens for the switcher animation)
- **Backend Depends On**: BE-42 i18n (mirrors keys, `PUT /api/v1/users/me/language`, product translation pipeline)
- **Blocks**: FE-37 (empty/error states are localized), FE-40 (release prep ships translations)
- **Estimated Duration**: 3-4 days
- **Complexity**: Medium-High — typography fallback + script rendering is non-trivial

## Goal
Ship the same six-language matrix the backend supports — **English, Hindi, Tamil, Telugu, Bengali, Marathi** — at every visible string, every push notification body, every error toast, and every Lottie text overlay. Specifically:

- ARB files for `en / hi / ta / te / bn / mr` covering 100% of UI strings, with key parity to BE-42 server locales.
- `flutter_localizations` + `intl_utils` codegen wired into CI; missing keys fail the build.
- Per-screen runtime language refresh — switching languages does **not** require an app restart, and **does not** drop scroll position or in-flight forms.
- Devanagari (hi, mr), Tamil (ta), Telugu (te), Bengali (bn) script support via Noto Sans Indic font subsets, lazy-loaded per active locale.
- Number, date, currency, and pluralization formatting per locale (Devanagari numerals optional; defaults to Western Arabic per Indian govt convention).
- A language switcher screen (settings) with country/script preview and a Lottie flag transition.
- Active locale propagated to every Dio request as the `Accept-Language` header so BE-42 returns localized product data.
- RTL: none of our 6 languages are RTL but the app's `Directionality` plumbing is wired correctly so adding Urdu later costs zero refactor.

By the end, a Tamil-speaking shopkeeper in Coimbatore can use the entire app in Tamil — including push notifications and AI ingredient explainers (FE-22) — and switch to English mid-session without losing state.

## Why This Phase Matters
- **Adoption beyond metros**: 78% of Indian smartphone users prefer a non-English app interface. Shipping English-only caps the addressable market at ~22%.
- **Tier-2/3 conversion**: Survey data shows premium-conversion rate triples when the paywall (FE-13) is rendered in the user's preferred language.
- **Trust on safety features**: Allergen warnings (FE-15/FE-18) and recall alerts (FE-21) must be readable to non-English speakers — these are public-safety features. A Hindi-only mother understanding "milk allergen detected" is a non-negotiable.
- **App Store visibility**: Localized app store listings (FE-40) earn ~2× organic install share in regional markets.
- **Backend symmetry**: BE-42 already ships server-side translations — without this phase the backend work is half-used.
- **Brand quality**: Botched script rendering (broken conjuncts, wrong font, ASCII-rendered Devanagari) is the #1 telltale of an "amateur Indian app." Getting the typography right is brand-level.

## Prerequisites
- [ ] BE-42 deployed and `PUT /api/v1/users/me/language` endpoint live.
- [ ] BE-42 ARB key catalog handed off (~480 keys at last count).
- [ ] Noto Sans Indic font files: `NotoSansDevanagari-Regular/Bold.ttf`, `NotoSansTamil-Regular/Bold.ttf`, `NotoSansTelugu-Regular/Bold.ttf`, `NotoSansBengali-Regular/Bold.ttf`. Subsetted to ≤ 480 KB each (only glyphs we use, plus base Latin fallback).
- [ ] Native-speaker translator review on file for hi/ta/te/bn/mr — strings are not LLM-translated for safety-critical strings.
- [ ] FE-07 Riverpod state established.
- [ ] FE-33 motion tokens locked.

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/l10n/app_en.arb` | Master ARB — every key originates here |
| `apps/mobile/lib/l10n/app_hi.arb` | Hindi |
| `apps/mobile/lib/l10n/app_ta.arb` | Tamil |
| `apps/mobile/lib/l10n/app_te.arb` | Telugu |
| `apps/mobile/lib/l10n/app_bn.arb` | Bengali |
| `apps/mobile/lib/l10n/app_mr.arb` | Marathi |
| `apps/mobile/lib/l10n/l10n.yaml` | `intl_utils` config |
| `apps/mobile/lib/i18n/locale_state.dart` | Riverpod `LocaleNotifier` (active locale + persistence) |
| `apps/mobile/lib/i18n/locale_repository.dart` | Drift table for `app_settings.preferred_language` + secure-storage cache |
| `apps/mobile/lib/i18n/supported_locales.dart` | The 6-locale list + display metadata (flag, native name, script) |
| `apps/mobile/lib/i18n/font_resolver.dart` | Returns `TextTheme` with Indic font fallbacks for active locale |
| `apps/mobile/lib/i18n/number_format.dart` | Per-locale `NumberFormat`, `DateFormat`, `Currency` helpers |
| `apps/mobile/lib/i18n/locale_request_interceptor.dart` | Dio interceptor: `Accept-Language` header from active locale |
| `apps/mobile/lib/features/settings/language_switcher_screen.dart` | The user-facing switcher |
| `apps/mobile/lib/features/settings/widgets/language_tile.dart` | Single-language tile with flag + native name + script preview |
| `apps/mobile/test/i18n/locale_state_test.dart` | Unit |
| `apps/mobile/test/i18n/key_parity_test.dart` | Asserts every ARB has identical keys |
| `apps/mobile/test/i18n/script_render_golden_test.dart` | Goldens per script |
| `apps/mobile/integration_test/runtime_language_swap_test.dart` | Mid-session swap E2E |
| `tools/scripts/check_arb_parity.dart` | CI script — fails on key drift |
| `tools/scripts/sync_arb_with_backend.dart` | Pulls BE-42 server keys, asserts mirror |

## Implementation Spec

### Supported locales registry
```dart
class SupportedLocale {
  final Locale locale;
  final String nativeName;     // "हिन्दी", "தமிழ்", …
  final String englishName;    // "Hindi", "Tamil", …
  final String flagAsset;      // 'assets/flags/in_hi.svg'
  final String script;         // 'Devanagari', 'Tamil', …
  final String fontFamily;     // 'NotoSansDevanagari', …
  final String previewLine;    // a sample sentence to demo the script
  final TextDirection direction; // all six are LTR; field exists for future Urdu
}

const supportedLocales = <SupportedLocale>[
  SupportedLocale(Locale('en'), 'English',  'English', 'assets/flags/in_en.svg', 'Latin',      'Inter',                'Read the label, know the food.', TextDirection.ltr),
  SupportedLocale(Locale('hi'), 'हिन्दी',     'Hindi',   'assets/flags/in_hi.svg', 'Devanagari', 'NotoSansDevanagari',   'लेबल पढ़ें, खाना समझें।',           TextDirection.ltr),
  SupportedLocale(Locale('ta'), 'தமிழ்',     'Tamil',   'assets/flags/in_ta.svg', 'Tamil',      'NotoSansTamil',        'லேபிளைப் படியுங்கள், உணவை அறியுங்கள்.', TextDirection.ltr),
  SupportedLocale(Locale('te'), 'తెలుగు',    'Telugu',  'assets/flags/in_te.svg', 'Telugu',     'NotoSansTelugu',       'లేబుల్‌ను చదవండి, ఆహారం తెలుసుకోండి.', TextDirection.ltr),
  SupportedLocale(Locale('bn'), 'বাংলা',     'Bengali', 'assets/flags/in_bn.svg', 'Bengali',    'NotoSansBengali',      'লেবেল পড়ুন, খাবার জানুন।',         TextDirection.ltr),
  SupportedLocale(Locale('mr'), 'मराठी',     'Marathi', 'assets/flags/in_mr.svg', 'Devanagari', 'NotoSansDevanagari',   'लेबल वाचा, अन्न ओळखा.',             TextDirection.ltr),
];
```

> Note: hi and mr share the Devanagari font subset, halving the bundle footprint.

### `LocaleNotifier`
```dart
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final stored = ref.read(localeRepositoryProvider).read();
    if (stored != null) return stored;
    final system = WidgetsBinding.instance.platformDispatcher.locale;
    return _matchSupported(system);
  }

  Future<void> set(Locale locale) async {
    if (!_isSupported(locale)) return;
    state = locale;
    await ref.read(localeRepositoryProvider).write(locale);
    // Tell backend (BE-42) — fire-and-forget (we don't block UI).
    unawaited(ref.read(usersApiProvider).setPreferredLanguage(locale.languageCode));
    // Tell observability (BE-48) — language is a core property.
    Sentry.setExtra('locale', locale.toLanguageTag());
    // Reload only the locale-bound providers, not the world.
    ref.invalidate(numberFormatProvider);
    ref.invalidate(dateFormatProvider);
  }

  Locale _matchSupported(Locale sys) =>
      supportedLocales.firstWhere(
        (s) => s.locale.languageCode == sys.languageCode,
        orElse: () => supportedLocales.first,
      ).locale;
}
```

### `RadhaApp` wiring
```dart
class RadhaApp extends ConsumerWidget {
  Widget build(context, ref) {
    final locale = ref.watch(localeProvider);
    final config = ref.watch(flavorConfigProvider);
    final supported = supportedLocales.firstWhere((s) => s.locale == locale);
    return MaterialApp.router(
      locale: locale,
      supportedLocales: supportedLocales.map((s) => s.locale).toList(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (ctx, child) => Directionality(
        textDirection: supported.direction,
        child: MediaQuery(
          data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        ),
      ),
      theme: ref.watch(themeProvider).withFontFamily(supported.fontFamily),
      // …
    );
  }
}
```

### Number / date / currency helpers
```dart
class RadhaFormat {
  static String currency(num value, Locale locale) {
    // Indian numbering system (lakh / crore) when locale is Indian;
    // otherwise standard.
    return NumberFormat.simpleCurrency(locale: locale.toLanguageTag(), name: 'INR').format(value);
  }
  static String date(DateTime d, Locale locale) =>
      DateFormat.yMMMd(locale.toLanguageTag()).format(d);
  static String time(DateTime d, Locale locale) =>
      DateFormat.jm(locale.toLanguageTag()).format(d);
  static String number(num value, Locale locale, {bool nativeDigits = false}) {
    final f = NumberFormat.decimalPattern(locale.toLanguageTag());
    return nativeDigits ? f.format(value) : f.format(value).replaceAll(RegExp(r'\D*'), (m) => m.group(0)!); // ASCII-only digits by default
  }
}
```

### Dio interceptor
```dart
class LocaleRequestInterceptor extends Interceptor {
  final Ref ref;
  LocaleRequestInterceptor(this.ref);
  @override
  void onRequest(options, handler) {
    final lang = ref.read(localeProvider).languageCode;
    options.headers['Accept-Language'] = lang;
    handler.next(options);
  }
}
```

## Patterns / Reusable Widgets

| Widget / Helper | API |
|---|---|
| `LocaleNotifier` (Riverpod) | `set(Locale)`, `state` |
| `localeProvider` | `Provider<Locale>` |
| `RadhaFormat.currency / date / time / number` | static — never instantiate `NumberFormat` at call sites |
| `LanguageSwitcherScreen` | Settings → Language; tap a tile → animate flag → call `LocaleNotifier.set` |
| `LanguageTile` | flag SVG + nativeName + englishName subtitle + previewLine in target script |
| `LocaleAwareText` | small wrapper used only in unit tests / Widgetbook to demo a string in all 6 locales side-by-side |

## Configuration / Tokens

| Token | Value | Why |
|---|---|---|
| `i18n.supportedLanguages.count` | 6 | en, hi, ta, te, bn, mr |
| `i18n.fallbackLocale` | en | When a key is missing in the active locale |
| `i18n.font.indicSubsetSize` | ≤ 480 KB per script | Bundle size budget |
| `i18n.font.totalSubsetSize` | ≤ 1.6 MB across 4 Indic fonts (Devanagari counted once for hi+mr) | APK size budget |
| `i18n.runtime.swapMaxLatencyMs` | 200 | Tap a tile → strings repaint in < 200ms |
| `i18n.persistence.key` | `app_settings.preferred_language` | Drift column |
| `i18n.api.endpoint` | `PUT /api/v1/users/me/language` | BE-42 |
| `i18n.api.timeoutMs` | 4000 | Switcher does not block on this |
| `i18n.numberSystem` | Western Arabic (default) | Indian govt convention; nativeDigits opt-in |
| `i18n.dateFormat.shortPattern` | `dd MMM yyyy` | Anchored format across locales |
| `i18n.lottie.textOverlays` | Localized via `Lottie.asset.delegates` | No baked text in animations |

## Per-Screen Application Checklist

| Screen / Phase | UI strings keyed | Server-localized data | Number / date format | Notes |
|---|---|---|---|---|
| Splash FE-09 | n/a (no copy) | — | — | language read from secure store at boot |
| Onboarding cards FE-10 | ✓ | — | — | 6 cards × 6 langs = 36 strings |
| OTP entry FE-11 | ✓ | — | phone format per locale | Indian +91 default |
| OTP verify FE-12 | ✓ | — | — | resend timer formatted per locale |
| Premium subscribe FE-13 | ✓ | ✓ plan names | ✓ ₹49 with locale grouping | currency from BE-28 |
| Family invite FE-14 | ✓ | — | — | — |
| Allergen setup FE-15 | ✓ | ✓ allergen names from BE-37 | — | safety-critical: human-translated only |
| Business activation FE-16 | ✓ | — | — | — |
| Scanner FE-17 | ✓ (5 strings) | — | — | minimal copy on this screen |
| Scan output FE-18 | ✓ | ✓ verdict text from BE-12 | sugar / salt / oil g | locale-formatted units |
| Product detail FE-19 | ✓ | ✓ name, brand, ingredients from BE-42 product_translations | — | per-EAN translation precedence |
| Expiry calendar FE-20 | ✓ | — | ✓ date headers per locale | month names full not abbreviated |
| Recall inbox FE-21 | ✓ | ✓ recall reason from BE-39 | timestamps "2 घंटे पहले" | safety-critical |
| Ingredient explainer FE-22 | ✓ | ✓ LLM stream in target lang from BE-40 | — | LLM cache keyed by (ingredient, lang) |
| Healthy alternatives FE-23 | ✓ | ✓ from BE-41 | ✓ price | — |
| Shopping list FE-24 | ✓ | — | ✓ qty | WhatsApp share message localized |
| Business dashboard FE-25 | ✓ | ✓ KPI labels from BE-30 | ✓ numbers | — |
| OHS detail FE-26 | ✓ | ✓ component names | ✓ % | — |
| Bulk scan FE-27 | ✓ | — | — | error toasts |
| Expiry tracker biz FE-28 | ✓ | — | ✓ date | — |
| GRN wizard FE-29 | ✓ | ✓ supplier names from BE-25 | ✓ qty | — |
| Inventory FE-30 | ✓ | — | ✓ counts | — |
| Tasks FE-31 | ✓ | ✓ task description from BE-19 | ✓ due date | priority labels human-translated |
| Reports FE-32 | ✓ | ✓ report titles | ✓ date | exports retain user locale |
| Settings — Language Switcher | ✓ | — | — | ships with FE-35 |

## Backend Integration

| Backend | Role |
|---|---|
| **BE-42 i18n** | Source of truth for the 480-key catalog. CI script `tools/scripts/sync_arb_with_backend.dart` pulls server keys nightly and fails the build if our ARBs drift. |
| **BE-42 `PUT /api/v1/users/me/language`** | Persists the user's choice server-side so push notifications (BE-24), emails, and weekly digest (BE-43) honour it. |
| **BE-42 `Accept-Language` middleware** | Every Dio request from this app carries the header, so scan/explain/recall responses come back localized. |
| **BE-39 recalls** | Recall reason text fetched in active locale from BE-42 `product_translations` table. |
| **BE-40 AI ingredient explainer** | Stream prompt includes `language` param; LLM cache keyed by `(ingredient, lang)` so the second user in any language pays cache cost only. |
| **BE-46 quotas** | Quota-exceeded toast text resolved against the active locale. |
| **BE-29 analytics** | `language_changed` event emitted on every switch with `{from, to}`. |
| **BE-48 observability** | Sentry user context updated with active locale on every switch — used to filter regression by language. |

## Accessibility & Platform Variants

### Script rendering
- Devanagari conjuncts (`क्ष`, `ज्ञ`, `त्र`) verified via golden tests on the 4 most common 4 conjunct shapes per script.
- Tamil aytham, visarga, half-letter forms tested.
- Telugu vowel signs above and below the consonant cluster verified.
- Bengali yo-phala and ra-phala render correctly.
- Marathi-specific eyelash ra (`ऱ`) included in the Devanagari subset.

### Font fallback
- Active locale loads its dedicated font; other Indic scripts fall through to system if encountered (e.g., a Hindi user reading a Bengali product name in a recall feed).
- Latin glyphs always render in Inter regardless of script — keeps numerals and English brand names consistent.

### Dynamic type
- All localized strings use `Theme.of(context).textTheme` — they scale with system text size up to xxLarge.
- Long strings in Tamil/Telugu can be ~1.4× longer than English; UI tested with 1.4× line counts on every screen.

### Reduced motion
- The language switcher's flag-flip animation drops to a 200ms cross-fade.

### RTL readiness
- `Directionality` is wired but always LTR for these 6. `directionality_test.dart` asserts that swapping any locale's `TextDirection` to RTL renders correctly (Arabic test fixture loaded as a 7th locale in test mode only).

### Android specifics
- Per-app language preference (Android 13+) honoured: the system `LocaleManager` setting overrides the user's in-app choice on first boot. After that, the in-app choice wins.

### iOS specifics
- iOS per-app language picker (iOS 13+) similarly honoured at first launch.
- iOS keyboard switch matches script: setting locale to ta surfaces Tamil keyboard suggestion in `RadhaTextField`.

### Tablet
- Tamil/Telugu lines tested at the larger column width — line breaking verified by `BiDiFormatter`.

## Testing

### Widget tests
- `key_parity_test.dart`: every ARB has identical key set; CI fails on drift.
- `locale_state_test.dart`: `LocaleNotifier.set` updates state, persists to Drift, fires Dio header update.
- `format_test.dart`: ₹49 in en → "₹49.00", in hi → "₹49.00" (Western digits by default), in hi nativeDigits → "₹४९.००".
- `font_resolver_test.dart`: locale=ta → text theme uses NotoSansTamil family.

### Golden tests
- One golden per screen per locale — 25 screens × 6 locales = 150 frames in the regression suite.
- Devanagari conjunct golden, Tamil grantha golden, Bengali yophala golden, Telugu vowel-sign-above-consonant-cluster golden.

### Integration tests
- `runtime_language_swap_test.dart`: open scan output (en) → settings → switch to hi → return → assert all strings repainted in hi without scroll loss.
- `notification_localization_test.dart`: stub a recall push, set locale=ta, assert payload text matches BE-42 `ta.json`.
- `dio_header_test.dart`: any outbound request after `LocaleNotifier.set('te')` carries `Accept-Language: te`.

### Perf benchmarks
- Locale swap end-to-end latency: tap → repaint complete ≤ 200ms (DevTools timeline, Pixel 4a).
- Cold start latency delta from this phase: ≤ 80ms (font load deferred to first text render in active script).
- APK size delta: ≤ 1.7 MB (4 subset Indic fonts + 6 ARBs).

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | All 6 ARB files load without parse error (CI step) |
| T2 | Every key in `app_en.arb` exists in all 5 other ARBs (CI fails on drift) |
| T3 | Every key in BE-42 server `ta.json` exists in `app_ta.arb` (CI fails on drift, syncs nightly) |
| T4 | Boot the app on a device with system locale = `mr` and no stored preference → app starts in Marathi |
| T5 | Switch from `en` → `hi` mid-session: every visible string repaints in Hindi within 200ms; scroll position preserved |
| T6 | Switch from `en` → `ta` while a `RadhaTextField` is in focus: focus retained, value retained, label repaints in Tamil |
| T7 | Devanagari conjunct `क्षत्रिय` renders without broken halant on the splash demo string (golden) |
| T8 | Tamil `ஞ்` half-letter renders correctly mid-word (golden) |
| T9 | Bengali `র্য` ra-phala renders correctly (golden) |
| T10 | Telugu `గ్రా` consonant cluster renders correctly (golden) |
| T11 | A scan output card on Pixel 4a in Tamil at xxLarge dynamic type does not clip; lines wrap correctly |
| T12 | Setting locale to `bn` causes the next `POST /api/v1/products/scan` request to carry `Accept-Language: bn` (verified via Dio interceptor mock) |
| T13 | Setting locale calls `PUT /api/v1/users/me/language` once; success and failure both leave UI in the new locale (server is fire-and-forget) |
| T14 | A push notification arriving while locale is `te` is rendered with the Telugu body from BE-24 |
| T15 | APK size impact ≤ 1.7 MB for all 4 subset fonts + 6 ARBs |

### Q&A Questions (8)

1. We default Indian Western Arabic numerals everywhere. Why — and what's the discoverability path for a user who wants Devanagari numerals?
2. Hindi and Marathi share Devanagari, but they have different conventions (`ऱ` eyelash ra in Marathi). How does the font subset cover both without a 2× footprint?
3. The user changes locale; the backend `PUT /me/language` call fails. What's the user-visible behaviour, and what happens on the next push notification?
4. AI ingredient explainer (FE-22) streams a response in the active locale. If the user switches locale mid-stream, do we restart the stream, finish in the original language, or do something else?
5. Long Tamil/Telugu translations of "Quota exceeded — upgrade to Premium" overflow the toast on Pixel 4a. What's the truncation policy, and at what dynamic type size do we switch to a sheet?
6. How do we discover untranslated strings shipping accidentally with English fallback in a release build? (Not just CI ARB parity — real running app instrumentation.)
7. None of the 6 are RTL. Why bother with `Directionality` plumbing now? What's the cost of adding Urdu later if we don't?
8. Per-app language (Android 13+) and the in-app switcher can conflict. Which wins, and how do we communicate that to the user?

## Sign-off Gate
- [ ] Developer: 15 tests pass; CI ARB parity gate live; coverage ≥ 95% on `lib/i18n/**`.
- [ ] Developer: 8 Q&A answered.
- [ ] Developer: every screen has a golden in all 6 locales.
- [ ] Reviewer: spot-checked 5 screens in Tamil and 5 in Bengali on real devices.
- [ ] Reviewer: confirmed font fallback chain — no Latin "tofu" boxes in any screen.
- [ ] Native-speaker translator: signed off on hi/ta/te/bn/mr ARBs (especially safety-critical strings — allergen, recall, expiry).
- [ ] Designer: typography hierarchy preserved across all 6 fonts.
- [ ] Accessibility reviewer: dynamic type + TalkBack work in every locale.

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________
**Accessibility Reviewer Signature**: ___________________________
**Translator (per language) Signatures**: ___________________________

---
**END OF FE-35 — DO NOT PROCEED WITHOUT APPROVAL**
