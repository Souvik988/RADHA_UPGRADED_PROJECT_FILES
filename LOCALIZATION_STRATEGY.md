# RADHA Mobile — Localization Strategy

> **Scope**: Internationalization architecture for `apps/mobile/`. Owns ARB structure, key naming, translation workflow, RTL readiness, and the CI gates that keep all six locales whole. Companion to `FRONTEND_PHASES/FE-35_PHASE.md` (i18n implementation) and the per-phase microcopy tables in every `FE-XX_PHASE.md`.

---

## 1. Stack — locked

| Concern | Choice | Notes |
|---|---|---|
| Loader | `flutter_localizations` (SDK) | First-party, plays cleanly with `MaterialApp.localizationsDelegates` |
| Format/parse | `intl 0.19` | ICU MessageFormat, `DateFormat`, `NumberFormat` |
| Source format | **ARB** (`.arb` JSON-with-metadata) | Industry standard; supported by every major TMS |
| Code generation | `intl_utils 2.8+` | Generates `S` class with type-safe getters |
| Translation memory | **Lokalise** project `radha-mobile` | Webhook-driven sync from `intl_en.arb` source of truth |
| Lint enforcement | custom-lint rule `forbid_hardcoded_strings` | Rejects user-facing string literals outside an allowlist |

Alternatives considered and rejected:

| Option | Verdict | Reason |
|---|---|---|
| `slang` | ❌ | Younger ecosystem, smaller TMS plugin support, no ARB-native pipeline. We have to be ready to add Arabic, Kannada, Punjabi later — sticking to ARB keeps that path open. |
| `GetX i18n` | ❌ | Couples i18n to a state-management framework we explicitly rejected (FE-07 picked Riverpod). The "translations Map" pattern fragments source-of-truth across files. |
| Hand-rolled `Map<String,String>` | ❌ | No pluralization, no parameter typing, no TMS round-trip. |

---

## 2. Locales — v1

Six locales ship in v1 GA:

| Locale code | Language | Script | Speaker base (India) | Notes |
|---|---|---|---|---|
| `en` (base) | English | Latin | universal in retail context | Source of truth — every key originates here |
| `hi` | Hindi | Devanagari | ~530M | Highest-priority non-English |
| `ta` | Tamil | Tamil | ~75M | Different pluralization rules from Hindi |
| `te` | Telugu | Telugu | ~80M | |
| `bn` | Bengali | Bengali | ~100M (incl. West Bengal) | Line-height tuning required |
| `mr` | Marathi | Devanagari | ~85M | Shares Devanagari fallback with Hindi |

Out of v1: Kannada, Punjabi, Gujarati, Malayalam, Urdu, Arabic. Architecture below leaves room for them; adding one is a Lokalise + ARB add — no code change required.

---

## 3. Locale fallback chain

`MaterialApp.localeResolutionCallback` resolves a device locale to one we ship:

```
requested locale (e.g., hi-IN)
  ↓ if exact match in supportedLocales → use it
  ↓ else strip region (hi-IN → hi) and match by language
  ↓ if language matches a supported locale → use it
  ↓ else → en (final fallback)
```

`MaterialApp.locale` can be force-set by a Riverpod `localeProvider` (FE-35) when the user explicitly chooses a language in settings; that choice persists in `flutter_secure_storage` and overrides system locale on next boot.

---

## 4. ARB file structure

```
apps/mobile/lib/l10n/
  intl_en.arb        # source of truth — every key + @meta description + placeholders
  intl_hi.arb        # Hindi (Devanagari)
  intl_ta.arb        # Tamil
  intl_te.arb        # Telugu
  intl_bn.arb        # Bengali
  intl_mr.arb        # Marathi
  l10n.yaml          # intl_utils configuration
  generated/         # output of intl_utils (gitignored — regenerated in CI)
    l10n.dart        # facade
    intl/messages_*.dart
    s.dart           # `S` class — type-safe access via `S.of(context)`
```

`intl_en.arb` excerpt:

```json
{
  "@@locale": "en",
  "@@last_modified": "2025-01-15T10:00:00Z",

  "scan.cta.start": "Scan a barcode",
  "@scan.cta.start": {
    "description": "Primary CTA on the scan landing screen, FE-17",
    "context": "BUTTON_LABEL"
  },

  "scan.error.network": "No internet — your scan will sync when you're back online",
  "@scan.error.network": {
    "description": "Error banner shown when scan API call fails offline. Should be reassuring, not alarming.",
    "context": "ERROR_MESSAGE"
  },

  "expiry.due.today": "{count, plural, =0{Nothing expires today} =1{1 item expires today} other{{count} items expire today}}",
  "@expiry.due.today": {
    "description": "Expiry rollup count, FE-23 dashboard card",
    "placeholders": {
      "count": { "type": "int", "format": "compact" }
    }
  }
}
```

`l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: intl_en.arb
output-localization-file: s.dart
output-class: S
output-dir: lib/l10n/generated
nullable-getter: false
synthetic-package: false
```

---

## 5. Key naming convention

Format: `<screen>.<element>.<state>` — three dot-separated lowercase tokens.

| Token | Allowed values | Examples |
|---|---|---|
| `<screen>` | a screen owner from `FRONTEND_PHASES/` (e.g., `scan`, `expiry`, `paywall`, `recall`, `recipe`) | `scan`, `expiry`, `paywall` |
| `<element>` | a UI element class — `cta`, `error`, `hint`, `title`, `body`, `toast`, `dialog`, `tab`, `field`, `legend` | `cta`, `error`, `hint` |
| `<state>` | optional fourth segment for state variants — `start`, `success`, `pending`, `disabled`, `today`, `due` | `start`, `success`, `today` |

Enforced by `tool/i18n/lint_arb_keys.dart` which rejects keys that don't match the regex `^[a-z]+(\.[a-z_]+){1,3}$`. Run as part of `mobile-ci.yml` (see `CI_CD_PIPELINE.md` §4).

Examples:

| Key | Use |
|---|---|
| `scan.cta.start` | "Scan a barcode" button |
| `scan.error.network` | offline scan error |
| `expiry.due.today` | pluralized rollup |
| `paywall.title.tier_1` | tier-1 paywall heading |
| `recall.body.acknowledged` | recall confirmation body copy |
| `auth.field.otp.hint` | OTP entry placeholder |

Anti-patterns banned by the lint:

- `scanCtaStart` — camelCase
- `Scan.Start` — uppercase
- `scan_start` — underscores in `<screen>`
- `scan` — single segment

---

## 6. Generated `S` class

`intl_utils` emits `lib/l10n/generated/s.dart` with one method per key:

```dart
class S {
  static S of(BuildContext context) =>
      Localizations.of<S>(context, S)!;

  String get scanCtaStart;
  String get scanErrorNetwork;
  String expiryDueToday(int count);
  String paywallTitleTier1;
  // ...
}
```

Usage at call sites is always:

```dart
Text(S.of(context).scanCtaStart)
```

Never:

```dart
Text('Scan a barcode')          // banned by forbid_hardcoded_strings
Text(S.of(context)['scan.cta.start']) // S has no [] operator — type-safe only
```

Autocomplete + compile-time checks mean a typo in the key fails the build, not at runtime.

---

## 7. Hardcoded string ban

`tool/lint/forbid_hardcoded_strings.dart` (custom-lint) rejects any user-visible `String` literal in `lib/` that meets all of:

- length ≥ 2 characters
- contains at least one alphabetic character
- is not in the file-level allowlist
- is not annotated `// i18n-ignore: <reason>`

**Allowlist** (`tool/lint/i18n_allowlist.yaml`):

```yaml
# Files where strings are inherently non-user-facing
allowed_files:
  - 'lib/services/logging/**'    # log messages — English only
  - 'lib/perf/**'                # perf telemetry tags
  - 'lib/services/analytics/**'  # event names
  - 'lib/services/sentry/**'     # breadcrumb categories
  - 'tool/**'                    # build tooling
  - 'integration_test/**'        # test labels
  - 'test/**'                    # test labels

# Constants that are domain-correct in any locale
allowed_strings:
  - '₹'        # currency symbol — see §11
  - 'OK'       # well-understood across all 6 locales; reviewed
  - 'API'
  - 'OTP'
  - 'PIN'
  - 'EAN'
  - 'SKU'
  - 'GST'
```

Anything else triggers a CI error. Engineers add a key + ARB entry, not an allowlist exception.

---

## 8. CI gate — `check_arb_coverage.sh`

```bash
#!/usr/bin/env bash
# tool/i18n/check_arb_coverage.sh
# Fails CI if any key referenced in lib/ is missing from any *.arb file,
# or if any *.arb has keys not referenced anywhere.
set -euo pipefail

cd "$(dirname "$0")/../.."

# 1. Extract all S.of(context).<key> references
USED_KEYS=$(grep -REho 'S\.of\(context\)\.[a-zA-Z]+' lib/ \
  | sed -E 's/S\.of\(context\)\.//' \
  | sort -u)

# 2. Convert camelCase back to dotted form (intl_utils mapping)
DOTTED_USED=$(echo "$USED_KEYS" | dart run tool/i18n/camel_to_dotted.dart)

# 3. For each ARB, assert every used key exists
FAIL=0
for ARB in lib/l10n/intl_*.arb; do
  LOCALE=$(basename "$ARB" .arb | sed 's/intl_//')
  MISSING=$(comm -23 \
    <(echo "$DOTTED_USED") \
    <(jq -r 'keys | .[]' "$ARB" | grep -v '^@' | sort -u))
  if [ -n "$MISSING" ]; then
    echo "❌ $LOCALE missing keys:"
    echo "$MISSING"
    FAIL=1
  fi
done

# 4. Assert no orphan keys in en (source of truth)
ORPHANS=$(comm -13 \
  <(echo "$DOTTED_USED") \
  <(jq -r 'keys | .[]' lib/l10n/intl_en.arb | grep -v '^@' | sort -u))
if [ -n "$ORPHANS" ]; then
  echo "⚠️ orphan keys in intl_en.arb (referenced nowhere):"
  echo "$ORPHANS"
  # Orphans warn, don't fail — sometimes a key lands ahead of the screen
fi

exit $FAIL
```

This runs as a step in `mobile-ci.yml` (see `CI_CD_PIPELINE.md` §4) on every PR.

---

## 9. Translation workflow

```
Engineer writes screen
  ↓
Adds key + English value + @description to intl_en.arb
  ↓
Opens PR
  ↓
Lokalise webhook (apps/mobile/tool/i18n/sync.lokalise.yaml) detects new keys on intl_en.arb
  ↓
Lokalise queues translations for hi/ta/te/bn/mr
  ↓
In-house translators (or vendor) fill values in Lokalise UI
  ↓
Lokalise opens "Translations: <branch>" PR with updated intl_<lang>.arb
  ↓
PR runs mobile-ci.yml, intl_utils regenerates S class, golden tests run with each locale
  ↓
Translator PR merged into engineer's PR
  ↓
Original PR mergeable when all 6 ARBs are complete
```

**Time budget**: from PR open to "all 6 ARBs complete" is targeted at 24 h on weekdays. Holiday lag tolerated up to 72 h. Engineering can ship the English-only PR behind a feature flag (FE-47) if the translation lag is blocking.

`@@last_modified` and `@<key>.context` fields in `intl_en.arb` give translators the context they need (which screen, what kind of UI element). Translators never see Dart code; everything they need is in the ARB metadata.

---

## 10. Pluralization

ICU MessageFormat is used for any user-visible count:

```json
"expiry.due.today": "{count, plural, =0{Nothing expires today} =1{1 item expires today} other{{count} items expire today}}"
```

Per-language pluralization differs from English:

| Language | Plural categories | ICU keys |
|---|---|---|
| English (`en`) | one, other | `=0`, `=1`, `other` |
| Hindi (`hi`) | one, other | `=0`, `=1`, `other` |
| Tamil (`ta`) | one, other | `=0`, `=1`, `other` |
| Telugu (`te`) | one, other | `=0`, `=1`, `other` |
| Bengali (`bn`) | one, other | `=0`, `=1`, `other` |
| Marathi (`mr`) | one, other | `=0`, `=1`, `other` |

(All 6 v1 languages happen to share the `one` / `other` pattern; we still keep `=0` separate for natural copy.)

When Arabic ships post-v1, it requires `zero`, `one`, `two`, `few`, `many`, `other` — the ICU MessageFormat already supports it; the translator fills new branches without code change.

---

## 11. Date / time / number formatting

Always via `intl`. Never hand-roll.

| Concern | API | Example |
|---|---|---|
| Date | `DateFormat.yMMMMd(locale).format(d)` | "15 January 2025" / "१५ जनवरी २०२५" |
| Time | `DateFormat.jm(locale).format(d)` | "3:45 PM" / "३:४५ PM" |
| Relative | custom helper using `timeago` package | "3 hours ago" / "3 घंटे पहले" |
| Number | `NumberFormat.decimalPattern(locale).format(n)` | "12,345" / "१२,३४५" |
| Compact number | `NumberFormat.compact(locale).format(n)` | "12K" / "12 हज़ार" |
| Percentage | `NumberFormat.percentPattern(locale).format(0.42)` | "42%" / "४२%" |
| Currency | always ₹ in v1 (see §12) | "₹ 1,499" / "₹ १,४९९" |

The locale comes from `Localizations.localeOf(context).toLanguageTag()`. Never pass a hardcoded `'en_IN'`.

---

## 12. Currency

In v1 RADHA is India-only. Currency is always **₹ (INR)**. We do not switch currency by locale.

- Symbol literal `₹` is on the i18n allowlist (§7).
- Number formatting follows the active locale: `₹ 1,499` (en) vs `₹ १,४९९` (hi default — though most Hindi-speaking users keep Latin digits, so we render the locale-active number system as-is).
- `intl.NumberFormat.currency(locale: 'hi_IN', symbol: '₹')` produces correct grouping ("1,49,90,000" lakhs/crores) — used in any value over six digits.

A future multi-region build (out of v1) introduces a `Currency` enum and re-routes all formatting through `MoneyFormatter`. The plumbing for that lives in `lib/services/money/` and currently always returns INR.

---

## 13. RTL readiness

No RTL locale ships in v1, but the architecture is RTL-clean today so adding Arabic later is purely a translation drop:

- All padding, margin, alignment uses `EdgeInsetsDirectional`, `AlignmentDirectional`, `Padding(padding: EdgeInsetsDirectional.only(start:..., end:...))`.
- Icons that imply direction (chevrons, back arrows, undo) are rendered via the directional variants where the framework provides them (`Icons.arrow_back_ios_new` is auto-flipped by Flutter when `Directionality.of(context) == TextDirection.rtl`); custom SVG icons get a `Transform.flip(flipX: !isLtr)` wrap inside `RadhaIcon`.
- Text alignment uses `TextAlign.start` / `TextAlign.end` — never `TextAlign.left` / `TextAlign.right`.
- A golden-test variant `golden_rtl/` runs every screen with `Directionality.rtl` and a synthetic `ar` locale (`ar_EG_pseudo.arb` — pseudo-localized English with RTL marker characters). New screens land with their RTL golden green or they don't merge.

---

## 14. RTL specifics — when Arabic ships

Reserved for the post-v1 phase. The deltas from today:

- Add `ar` to `supportedLocales`.
- Add `intl_ar.arb`.
- Wire pluralization branches `zero`, `one`, `two`, `few`, `many`, `other` (already supported by ICU).
- Audit any `Image.asset` that depicts language-dependent screenshots (paywall, store screenshots) — generate Arabic variants.
- Re-run all goldens with `directionality: rtl` and the live `ar` locale.

The work above is bounded — we expect ~3 days, mostly translation throughput, because today's components already breathe RTL.

---

## 15. Runtime locale switch

Runtime locale switching is supported and matches BE-42:

```
User selects "हिंदी" in Settings
  ↓
PUT /api/v1/user/language { locale: "hi" } (BE-42)
  ↓
Server persists choice
  ↓
Client updates localeProvider via Riverpod
  ↓
MaterialApp.locale flips → entire tree rebuilds with S = SHi
  ↓
Choice persisted in flutter_secure_storage so next cold start uses it pre-network
```

`GetMaterialApp` is **not** used. We use `MaterialApp` + `localizationsDelegates` + `supportedLocales` directly. The reason: `GetMaterialApp` carries i18n state in a singleton that fights Riverpod's dependency graph and breaks test isolation. FE-07 already chose Riverpod; this decision keeps the boundary clean.

---

## 16. Dynamic-content localization

Server-served strings (recall titles, AI explainer text, paywall headlines published by marketing) are localized server-side:

- Client sends `Accept-Language: hi-IN, hi;q=0.9, en;q=0.5` on every API request (Dio interceptor — FE-06).
- Backend (BE-42) returns the best-matching locale variant and includes a `lang` field on the payload.
- If the client locale changes mid-session, the `userLocaleProvider` invalidates the relevant query keys (FE-07 plus the per-feature query helpers) so the dynamic content re-fetches.
- If the backend can't service the requested locale (rare; only happens for new content not yet translated), it returns `en` and tags `lang: "en"` — the client surfaces this gracefully (no error toast; English copy displays).

---

## 17. Translation memory + tooling

- **Lokalise project**: `radha-mobile`. Branches mirror Git branches: `main`, `staging`, `develop`. Translators work against `develop`; merges roll up.
- **Tags** in Lokalise:
  - `phase:FE-17` — phase that introduced the key
  - `screen:scan` — screen-level filter
  - `priority:p0` — copy that blocks shipping (legal, recall, allergen)
  - `length:cta` / `length:body` / `length:legal` — character-budget guidance for translators
- **Glossary**: `radha-glossary.csv` in `apps/mobile/tool/i18n/` lists brand terms that must not be translated (`RADHA`, `EAN`, `OTP`) plus controlled translations for retail jargon (`SKU` → `SKU`, `GRN` → `GRN` not "इनवर्ड").
- **Style guide**: `apps/mobile/tool/i18n/style_guide.md` — voice/tone per language. Hindi: respectful but not formal; Tamil: avoid Sanskrit-loanwords where Tamil-native exists; etc.

---

## 18. 6-language coverage scope

Hard requirement: **every** user-facing string in **every** phase ships in all 6 ARBs before the phase is signed off.

- Phase sign-off (the FE-XX phase doc footer "Sign-off Gate") explicitly lists "all microcopy keys present in all 6 ARBs" as a checkbox.
- The phase doc carries a microcopy table (already established in FE-09 onward) — each row maps a screen string to an ARB key. Translators consume that table directly.
- Non-user-facing logs (`developer.log`, Sentry breadcrumbs, analytics event names) stay English-only and are exempt by the i18n allowlist (§7).

---

## 19. Per-phase i18n checklist

Every `FRONTEND_PHASES/FE-XX_PHASE.md` lists, in its "Files to Create" or its dedicated microcopy table, the ARB keys it introduces. The CI gate (§8) makes this enforceable: a phase that uses `S.of(context).newKey` cannot merge until `newKey` exists in all 6 ARBs.

The sign-off owner (reviewer) verifies, in addition:

- Each new key has an `@<key>.description` in `intl_en.arb`.
- The Lokalise webhook fired (visible in PR comments).
- All 6 ARB files were updated by the translator PR before merge.

---

## 20. Locale detection

```
First launch
  ↓
Read system locale (Platform.localeName / View.platformDispatcher.locale)
  ↓
Match via fallback chain (§3) → set initial locale
  ↓
Persist in flutter_secure_storage as `last_locale`
  ↓
Subsequent launches
  ↓
Read flutter_secure_storage.last_locale → set locale before first frame
  ↓
If user changes language in Settings → BE-42 PUT, flutter_secure_storage updated
```

Boot order matters: the persisted locale is read **before** the first frame to avoid an English flash for non-English users. This happens in `bootstrap()` (see `ENVIRONMENT_CONFIG.md` §13) before `runApp`.

---

## 21. Known issues

| Issue | Detail | Workaround |
|---|---|---|
| Tamil + Bengali line-height | Default Material `lineHeight: 1.2` clips Tamil descenders and Bengali matra-rendering | `RadhaTypography` (FE-02) overrides line-height to `1.4` for `ta` and `bn`; `1.3` for `hi`/`mr` (Devanagari); `1.2` for `en`/`te`. Implemented as a `TextTheme` extension keyed off `Localizations.localeOf(context).languageCode`. |
| Bengali default font | `Roboto` lacks Bengali glyphs; renders as boxes | Bundled `NotoSansBengali` declared in `pubspec.yaml` `fonts:`; `RadhaTypography` selects it for `bn` (see `ASSET_PIPELINE.md` §6). |
| Tamil shaping in old Android (API 26-27) | Conjunct rendering breaks pre-API 28 | Bundled `NotoSansTamil` overrides system font; tested on API 26 emulator. |
| Hindi numerals vs Latin numerals | Some Hindi speakers prefer Latin digits ("1, 2, 3"); some prefer Devanagari ("१, २, ३") | We render whatever `intl.NumberFormat` returns for `hi_IN` (Latin by default); a future user-pref toggle could override. Not in v1. |
| ARB file ordering churn | Editors re-order keys on save → noisy diffs | `tool/i18n/sort_arb.dart` runs as a pre-commit hook to keep keys alphabetized. |
| ICU MessageFormat parse error | Translator typo in `{count, plural, ...}` brackets ships and crashes | `tool/i18n/validate_icu.dart` runs as part of `mobile-ci.yml`; rejects malformed messages with a line-pointed error. |

---

## 22. Tooling for engineers

- VS Code extension **Flutter Intl** (Localizely) — ARB editing, key add/rename, generates `S` on save. Pinned in `apps/mobile/.vscode/extensions.json`.
- `intl_utils` watcher: `flutter pub run intl_utils:watch` regenerates `S` on every ARB save during dev. Documented in `apps/mobile/README.md`.
- `tool/i18n/sort_arb.dart` — alphabetize keys in all 6 ARBs.
- `tool/i18n/validate_icu.dart` — sanity-check ICU MessageFormat strings.
- `tool/i18n/camel_to_dotted.dart` — translate generated `S.of(context).scanCtaStart` back to `scan.cta.start` for the coverage gate (§8).
- `tool/i18n/lint_arb_keys.dart` — enforce key-name regex (§5).

---

## 23. Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| **Translator missing a deadline → ship blocked** | Medium | Phase sign-off allows shipping behind a feature flag (FE-47); the English-only behaviour degrades gracefully, fallback chain covers; Lokalise SLA is 48 h for retail vocabulary in our supported locales |
| **Hardcoded string slips through** | Medium | `forbid_hardcoded_strings` custom-lint runs in CI; reviewer checklist in PR template; per-phase audit checkbox |
| **Tamil/Bengali rendering regression after Flutter SDK upgrade** | Medium | RTL + per-locale golden tests; SDK upgrades pinned (`apps/mobile/.fvmrc`) and gated by green goldens |
| **ICU MessageFormat typo from translator → crash** | Low | `validate_icu.dart` CI gate; runtime fallback to the `other` branch via `intl`'s parser-error guard |
| **Currency assumption breaks on multi-region build** | Low (post-v1) | All currency formatting routes through `MoneyFormatter`; flipping to a per-locale currency is a single `Currency` enum addition |
| **Lokalise outage blocks a release** | Low | ARBs are committed in-repo; engineering can hand-edit non-English ARBs and merge directly when Lokalise is down (Lokalise re-syncs on next webhook) |
| **Mismatched key between client and BE-42 dynamic content** | Medium | BE-42 contract documents every key; `tool/contracts/diff_dtos.dart` (FE-06) extends to localized response keys; CI fails on drift |

---

## 24. Cross-references

- `CI_CD_PIPELINE.md` — i18n CI gate (§4 of that doc)
- `ENVIRONMENT_CONFIG.md` — locale storage in `flutter_secure_storage` is flavor-independent
- `ASSET_PIPELINE.md` — bundled font subsetting for Devanagari/Tamil/Telugu/Bengali
- `FRONTEND_PHASES/FE-35_PHASE.md` — full i18n implementation phase
- `FRONTEND_PHASES/FE-02_PHASE.md` — `RadhaTypography` per-locale line-height
