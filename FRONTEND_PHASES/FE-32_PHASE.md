# Phase FE-32: Reports List + Detail + Export Sheet

## Phase Metadata
- **Phase ID**: FE-32
- **Phase Name**: Reports List + Detail + Export Sheet
- **Section**: Frontend Execution — Business + Owner (Layer 4)
- **Depends On**: FE-04 (motion tokens), FE-05 (GoRouter + deep links), FE-06 (API client + retry), FE-07 (Riverpod auth + plan provider), FE-08 (Drift offline cache for already-generated reports), FE-15 (subscription paywall reused for AI summary entitlement gate), FE-30 (low-stock + movement reports), FE-31 (task completion stats fold into reports), BE-20 (`GET /api/v1/reports`, `POST /api/v1/reports/generate`, `GET /api/v1/reports/{id}`), BE-21 (`GET /api/v1/reports/{id}/download`, scheduled-reports CRUD), BE-22 (Premium-gated AI report summary)
- **Blocks**: FE-39 (perf budget gate — the report list with 1000+ historical rows is the worst-case scroll surface in the app and must hold 60fps)
- **Estimated Duration**: 3–4 days
- **Complexity**: Medium

## Goal
Reports turn the day's scans, GRNs, expiry events, and tasks into something a manager can hand to an owner — or an auditor. FE-32 ships a **list** (recent + scheduled), a **detail screen** (summary, table, optional AI narrative), and an **export sheet** (Excel + PDF via `share_plus`). Generation runs async on the server (BullMQ worker — BE-21); the UI **polls** `GET /api/v1/reports/{id}` until the status flips from `queued` → `running` → `ready`, then auto-opens the download.

The bar: a manager closes the day, taps "Generate weekly low-stock," watches the `report_generating.json` Lottie for ~6 seconds, then shares the Excel via WhatsApp. Eight taps. The same flow with a Premium plan adds an AI narrative on top of the table; non-Premium users see the FE-15 entitlement overlay instead of the AI section — the rest of the report is unchanged.

## Why This Phase Matters
- **The owner-facing surface for the business app.** Dashboards (FE-25/26) are real-time and ephemeral. Reports are the artefact — the thing that ends up in WhatsApp threads, email, and printed for an audit. They are how RADHA earns its place in the business beyond "the scanner."
- **Compliance and audit trail.** A signed PDF of "Scan Audit, week of YYYY-MM-DD" is the FSSAI-friendly document. Without this phase the data exists but cannot leave the app.
- **Premium upsell moment.** AI narratives are the single most-asked-for feature in user research. Gating them via FE-15 paywall (non-blocking — the rest of the report still renders) gives every report-opener a brush with Premium without breaking their flow.
- **Time savings.** Weekly Excel export by hand: ~25 minutes. With one-tap generate-and-share: ~30 seconds. ~₹400/week saved per store on a manager's time.
- **Accessibility moment.** PDF preview must respect a "large text mode" — which means the PDF rendered for a user who's running iOS at 200% type size is itself laid out at a larger base font size, not the standard one. This is a quiet feature most apps skip.

## Prerequisites
- [ ] Backend: `GET /api/v1/reports?storeId=&kind=&cursor=` cursor page of `ReportSummary` (BE-20)
- [ ] Backend: `POST /api/v1/reports/generate` body `{ kind, params: {...}, includeAiSummary?: boolean }` → `{ id, status: 'queued' }` (BE-20)
- [ ] Backend: `GET /api/v1/reports/{id}` → `{ id, status, kind, params, generatedAt?, aiSummary?, rows?: object[], schema?: ColumnSpec[] }` (BE-20)
- [ ] Backend: `GET /api/v1/reports/{id}/download?format=xlsx|pdf` → 302 to a signed CDN URL (BE-21)
- [ ] Backend: `GET /api/v1/reports/scheduled?storeId=` and `POST/PUT/DELETE /api/v1/reports/scheduled` for cadence (BE-21)
- [ ] Backend: BE-22 returns AI summary embedded in `GET /api/v1/reports/{id}` only when the requesting plan includes `ai_report_summary` (server-enforced entitlement)
- [ ] FE-15 `EntitlementOverlay` widget exposed for reuse with `requiredFeature: 'ai_report_summary'`
- [ ] FE-08 Drift cache table `report_cache` keyed by `(reportId, etag)` for offline re-open of already-generated reports
- [ ] Lottie pack additions:
  - `report_generating.json` — 4s loop, ≤ 42 KB (drives the polling state)
  - `report_ready_pop.json` — 800ms one-shot, ≤ 50 KB (plays the moment status flips to `ready`)
- [ ] `share_plus 9.x` declared in `pubspec.yaml`
- [ ] Design assets: 5 report-kind illustrations (expiry, low-stock, scan audit, GRN log, AI summary)

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/business/reports/reports_list_screen.dart` | List host: tabs Recent / Scheduled |
| `apps/mobile/lib/features/business/reports/report_detail_screen.dart` | Detail: summary, table, optional AI narrative |
| `apps/mobile/lib/features/business/reports/generate_report_sheet.dart` | Kind picker + params + include-AI toggle |
| `apps/mobile/lib/features/business/reports/schedule_report_sheet.dart` | Cadence picker (weekly / monthly) |
| `apps/mobile/lib/features/business/reports/export_sheet.dart` | Excel / PDF / Cancel sheet wrapping `share_plus` |
| `apps/mobile/lib/features/business/reports/reports_controller.dart` | Riverpod list `Notifier<ReportsListState>` |
| `apps/mobile/lib/features/business/reports/report_detail_controller.dart` | Riverpod detail `Notifier<ReportDetailState>` with polling |
| `apps/mobile/lib/features/business/reports/reports_state.dart` | Sealed states + kind enum + cadence enum |
| `apps/mobile/lib/features/business/reports/data/reports_repository.dart` | Wraps BE-20 |
| `apps/mobile/lib/features/business/reports/data/report_download_repository.dart` | Wraps BE-21 download (302 chase + local file write) |
| `apps/mobile/lib/features/business/reports/data/scheduled_reports_repository.dart` | Wraps BE-21 scheduled CRUD |
| `apps/mobile/lib/features/business/reports/data/report_cache.dart` | Drift cache + ETag |
| `apps/mobile/lib/features/business/reports/widgets/report_kind_card.dart` | Card for each report kind in the picker |
| `apps/mobile/lib/features/business/reports/widgets/report_row.dart` | List tile with kind icon + status chip |
| `apps/mobile/lib/features/business/reports/widgets/status_chip.dart` | Queued / Running / Ready / Failed pill |
| `apps/mobile/lib/features/business/reports/widgets/generating_panel.dart` | Lottie + step text while polling |
| `apps/mobile/lib/features/business/reports/widgets/report_table.dart` | Horizontally scrollable, sticky-header table for `rows + schema` |
| `apps/mobile/lib/features/business/reports/widgets/ai_narrative_card.dart` | AI summary section with entitlement overlay fallback |
| `apps/mobile/lib/features/business/reports/widgets/cadence_chip_strip.dart` | Weekly / Monthly chips |
| `apps/mobile/lib/features/business/reports/widgets/pdf_preview.dart` | Read-only PDF preview honoring system text scale |
| `apps/mobile/test/features/business/reports/reports_controller_test.dart` | Unit |
| `apps/mobile/test/features/business/reports/report_detail_controller_test.dart` | Unit (polling, backoff) |
| `apps/mobile/test/features/business/reports/golden/report_states.dart` | Goldens (light + dark + RTL) |
| `apps/mobile/integration_test/reports_flow_test.dart` | Patrol E2E |

## Screen / Widget Spec

```dart
// reports_state.dart
enum ReportKind {
  expirySummary,
  lowStock,
  scanAudit,
  grnPostingLog,
  aiSummary, // composite — pulls from multiple kinds + AI narrative
}

enum Cadence { weekly, monthly }

enum ReportStatus { queued, running, ready, failed }

sealed class ReportsListState { const ReportsListState(); }
class ReportsLoading extends ReportsListState { const ReportsLoading(); }
class ReportsLoaded extends ReportsListState {
  final List<ReportSummary> recent;
  final List<ScheduledReport> scheduled;
  final String? nextCursor;
  final bool refreshing;
  const ReportsLoaded({...});
}
class ReportsError extends ReportsListState {
  final String code;
  final ReportsLoaded? lastGood;
  const ReportsError(this.code, this.lastGood);
}

sealed class ReportDetailState { const ReportDetailState(); }
class ReportDetailLoading extends ReportDetailState { const ReportDetailLoading(); }
class ReportDetailGenerating extends ReportDetailState {
  final String reportId;
  final ReportStatus status; // queued | running
  final int pollAttempt;
  final Duration nextPoll;
  const ReportDetailGenerating({...});
}
class ReportDetailReady extends ReportDetailState {
  final Report report;
  final bool aiNarrativeEntitled;
  final bool fromOfflineCache;
  const ReportDetailReady({...});
}
class ReportDetailFailed extends ReportDetailState {
  final String reportId;
  final String reasonCode;
  final bool retryable;
  const ReportDetailFailed({...});
}
```

```dart
// report_detail_controller.dart
abstract interface class ReportDetailController {
  Future<void> open(String reportId);
  Future<void> retry();
  Future<void> exportTo(ExportFormat format); // wraps share_plus
  Future<void> openAiSummaryPaywall();         // routes to FE-15 sheet
}

// reports_controller.dart
abstract interface class ReportsController {
  Future<void> refresh();
  Future<void> loadMore();
  Future<String> generate(GenerateReportInput input); // returns reportId, throws on quota/403
  Future<void> schedule(ScheduledReportInput input);
  Future<void> unschedule(String scheduledId);
}
```

### Polling strategy
The detail controller polls `GET /api/v1/reports/{id}` with capped exponential backoff anchored to the kind's typical generation time:

```
attempt:  1     2     3     4     5     6     7     8     9    10
delay:   600  900  1300  1800  2400  3000  3000  3000  3000  3000  (ms, capped at 3s)
total:    0.6   1.5   2.8   4.6   7.0  10.0  13.0  16.0  19.0  22.0  s
```

After 30 seconds without `ready`, the UI surfaces a "Still generating — we'll notify you when it's ready" panel and registers a one-shot FCM listener on `report_ready` for that reportId. The detail screen can be safely backgrounded; opening the push deep-links straight back to detail with the report ready.

### Export sheet
Tapping "Export" on a `ready` report opens a bottom sheet:
- **Excel** — chases the 302 from `GET /reports/{id}/download?format=xlsx`, writes to a temp file, calls `Share.shareXFiles([XFile(path)])`
- **PDF** — same, with format `pdf`. PDF preview opens locally via `pdf_preview.dart` before share.
- **Cancel** — dismiss

### AI narrative gating
`ai_narrative_card.dart` has three render branches:
- **Entitled + present**: full markdown with embedded mini-charts, fade-in stagger
- **Entitled + missing** (rare — server failed to generate): inline retry with apology copy
- **Not entitled**: `EntitlementOverlay` from FE-15 with `requiredFeature: 'ai_report_summary'`. The rest of the report (table, totals) renders normally below.

## Visual Behaviour & Interaction States

| # | State | Visual |
|---|---|---|
| 1 | **List loading** | Skeleton rows (5) with shimmer at `motion.normal` cycle |
| 2 | **List loaded — Recent tab** | Rows fade in with `normal` stagger; status chip on the right; relative time below the title |
| 3 | **List empty** | "No reports yet" illustration + primary CTA "Generate your first report" |
| 4 | **Tab switch (Recent → Scheduled)** | Cross-fade at `motion.fast`; segmented control slides selection |
| 5 | **Generate sheet open** | Bottom sheet 80% height; kind cards in 2-up grid; per-kind params expand on selection (`motion.normal` `swiftOut`) |
| 6 | **Generate sheet — AI toggle (entitled)** | Toggle on; cost-impact text "Adds ~3s to generation" appears |
| 7 | **Generate sheet — AI toggle (not entitled)** | Toggle disabled; "Premium feature — preview" with FE-15 paywall sheet on tap |
| 8 | **Generation queued** | Detail opens; `report_generating.json` Lottie loops; step text rotates ("Queued → Crunching scans → Compiling table → Writing summary"); back button preserved (UI is non-blocking) |
| 9 | **Generation taking long** | At 30s, panel swaps to "Still generating — we'll notify you when it's ready" with a Close CTA |
| 10 | **Status flips to ready** | `report_ready_pop.json` plays once (800ms); summary card scales in (`motion.celebrate`); table fades in below; export FAB appears |
| 11 | **AI narrative present** | Markdown card with stagger fade-in; embedded mini-charts use FE-25's `MicroSparkline` |
| 12 | **AI narrative entitlement-blocked** | Card shows blurred placeholder + lock icon; tap opens FE-15 paywall sheet |
| 13 | **Export sheet open** | Three-row sheet (Excel / PDF / Cancel); 240ms slide-up |
| 14 | **PDF preview open** | Full-screen preview honoring `MediaQuery.textScaler`; pinch-to-zoom enabled; share + print actions in app bar |
| 15 | **Share** | OS share sheet via `share_plus`; closes our sheet on success |
| 16 | **Generation failed** | Error panel with reason ("Insufficient data" / "Server timeout"); retry button if `retryable` |
| 17 | **Offline open of cached report** | Detail loads from Drift cache; "Offline copy" badge in header; export still works for the cached file |
| 18 | **Schedule sheet** | Kind picker + cadence (Weekly / Monthly) + day-of-week / day-of-month picker |
| 19 | **Schedule confirmation** | Inline success row in the list ("Weekly low-stock — every Monday 09:00") |
| 20 | **Quota exceeded on generate** | Server returns 429; toast + "Try again in {n} min" |
| 21 | **Reduced motion** | Lottie generating loop replaced with a 4-step text rotator at 1.2s per step; `report_ready_pop` replaced with a static check |
| 22 | **Dark mode** | Surface tokens swap; AI narrative markdown uses dark-mode syntax theme |
| 23 | **RTL** | Table column order reverses; status chips align right |
| 24 | **Dynamic type xxLarge** | Generate-sheet kind cards drop to 1-up; PDF preview uses larger base font (server-rendered with `?textScale=1.5`) |

## Animations

Reports motion budget is calm — this is a deliverable-focused screen, not a daily-fidget surface. The earned moments are **report ready** (status flip) and **export sheet open**. Polling animation is intentionally low-volume so it doesn't pulse-burn during the long tail.

- **Lottie**:
  - `report_generating.json` — 4s loop while polling; opacity 0.85 to keep it muted
  - `report_ready_pop.json` — 800ms one-shot when `status` flips to `ready`
- **flutter_animate chains**:
  - List row enter: stagger `normal` (48ms), `.fadeIn(motion.fast).slideY(begin: 0.04)`
  - Generate-sheet kind card select: scale 1.0 → 1.02 over `motion.fast`, accent stripe slides in
  - Step text rotator: cross-fade between steps over 280ms; never jarring
  - Status flip: `report_ready_pop` + summary card `.scale(begin: 0.96, end: 1.0, curve: motion.curve.celebrate)`
  - AI narrative reveal: paragraphs stagger `tight` (28ms), `.fadeIn(motion.fast).slideY(begin: 0.02)`
  - Export sheet: standard 240ms slide-up
- **Hero**: `Hero(tag: RadhaHero.report(reportId))` from list row to detail header. Single Hero, enforced by FE-33.
- **Custom**: status chip color tween between `queued → running → ready` over 320ms `swiftOut` so the change is felt as a transition, not a swap

## Haptics
- **selection** — tab switch, kind card tap, cadence chip select
- **light** — list row tap, AI toggle press
- **medium** — generation queued (one pulse on `POST /generate` ack)
- **success** — status flip to ready (pattern fires alongside `report_ready_pop`)
- **warning** — generation failed
- **heavy** — quota exceeded toast (rare)

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `reports.title` | "Reports" | "रिपोर्ट" | "அறிக்கைகள்" | "నివేదికలు" | "প্রতিবেদন" | "अहवाल" |
| `reports.tab.recent` | "Recent" | "हाल ही में" | "சமீபத்திய" | "ఇటీవలి" | "সাম্প্রতিক" | "अलीकडील" |
| `reports.tab.scheduled` | "Scheduled" | "अनुसूचित" | "திட்டமிட்ட" | "షెడ్యూల్" | "নির্ধারিত" | "नियोजित" |
| `reports.empty` | "No reports yet" | "अभी रिपोर्ट नहीं" | "இன்னும் இல்லை" | "ఇంకా లేదు" | "এখনো নেই" | "अजून नाही" |
| `reports.cta.generate` | "Generate report" | "रिपोर्ट बनाएँ" | "அறிக்கை உருவாக்கு" | "నివేదిక సృష్టించు" | "প্রতিবেদন তৈরি" | "अहवाल तयार करा" |
| `reports.kind.expiry` | "Expiry summary" | "एक्सपायरी सारांश" | "காலாவதி சுருக்கம்" | "గడువు సారాంశం" | "মেয়াদের সারাংশ" | "मुदत सारांश" |
| `reports.kind.lowstock` | "Low-stock" | "कम स्टॉक" | "குறைந்த சரக்கு" | "తక్కువ స్టాక్" | "কম স্টক" | "कमी स्टॉक" |
| `reports.kind.scanaudit` | "Scan audit" | "स्कैन ऑडिट" | "ஸ்கேன் தணிக்கை" | "స్కాన్ ఆడిట్" | "স্ক্যান অডিট" | "स्कॅन ऑडिट" |
| `reports.kind.grnlog` | "GRN posting log" | "GRN लॉग" | "GRN பதிவு" | "GRN లాగ్" | "GRN লগ" | "GRN लॉग" |
| `reports.kind.aisummary` | "AI summary" | "AI सारांश" | "AI சுருக்கம்" | "AI సారాంశం" | "AI সারাংশ" | "AI सारांश" |
| `reports.ai.toggle` | "Include AI summary" | "AI सारांश शामिल" | "AI சேர்" | "AI చేర్చండి" | "AI যোগ করুন" | "AI समाविष्ट करा" |
| `reports.ai.gated` | "Premium feature" | "प्रीमियम फ़ीचर" | "பிரீமியம்" | "ప్రీమియం" | "প্রিমিয়াম" | "प्रीमियम" |
| `reports.gen.queued` | "Queued…" | "क्यूड…" | "வரிசையில்…" | "క్యూలో…" | "সারিতে…" | "रांगेत…" |
| `reports.gen.running` | "Compiling…" | "तैयार हो रहा…" | "தொகுக்கிறது…" | "సిద్ధం చేస్తోంది…" | "তৈরি হচ্ছে…" | "तयार होत आहे…" |
| `reports.gen.long` | "We'll notify you when it's ready" | "तैयार होने पर सूचित" | "தயாரானதும் அறிவிப்பு" | "సిద్ధమైనప్పుడు" | "প্রস্তুত হলে জানাব" | "तयार झाल्यावर सूचित" |
| `reports.ready` | "Report ready" | "रिपोर्ट तैयार" | "தயார்" | "సిద్ధం" | "প্রস্তুত" | "तयार" |
| `reports.export.excel` | "Export Excel" | "एक्सेल" | "எக்செல்" | "ఎక్సెల్" | "এক্সেল" | "एक्सेल" |
| `reports.export.pdf` | "Export PDF" | "पीडीएफ" | "பிடிஎஃப்" | "పిడిఎఫ్" | "পিডিএফ" | "पीडीएफ" |
| `reports.schedule.weekly` | "Weekly" | "साप्ताहिक" | "வாராந்திர" | "వారం" | "সাপ্তাহিক" | "साप्ताहिक" |
| `reports.schedule.monthly` | "Monthly" | "मासिक" | "மாதாந்திர" | "నెల" | "মাসিক" | "मासिक" |
| `reports.failed.retry` | "Couldn't generate — try again" | "विफल — पुनः" | "தோல்வி — மீண்டும்" | "విఫలం — మళ్ళీ" | "ব্যর্থ — পুনরায়" | "अपयश — पुन्हा" |
| `reports.offline.copy` | "Offline copy" | "ऑफ़लाइन कॉपी" | "ஆஃப்லைன் நகல்" | "ఆఫ్‌లైన్ కాపీ" | "অফলাইন কপি" | "ऑफलाइन प्रत" |

## Backend Integration

- **GET /api/v1/reports** — cursor page; cached in Drift keyed by `(storeId, kind)`. ETag honoured.
- **POST /api/v1/reports/generate** body `{ kind, params, includeAiSummary }` → `200 { id, status: 'queued' }`. UI immediately routes to detail and starts polling.
- **GET /api/v1/reports/{id}** — polled with the backoff above; response carries `aiSummary` only if entitled (server-enforced).
- **GET /api/v1/reports/{id}/download** — 302 to a signed CDN URL; Dio chases redirects with `followRedirects: true` (FE-06). The download writes to `path_provider`'s temp dir and returns a path; `share_plus` consumes the path.
- **GET /api/v1/reports/scheduled** — list of `ScheduledReport` rows; cached.
- **POST /api/v1/reports/scheduled** body `{ kind, params, cadence, anchorDay }` → `201`.
- **DELETE /api/v1/reports/scheduled/{id}** — `204`.

### Idempotency
`POST /reports/generate` sends `Idempotency-Key: rpt-gen-{uuid-v4-per-attempt}`. A retry never queues a duplicate worker job — the server returns the existing `id`. The UI can therefore safely retry on a flaky network without dual-billing the AI cost.

### Entitlement gating (Premium AI summary)
The UI sends `includeAiSummary: true` based on the user's local plan flag, but **the server is the source of truth**. If the local plan is stale (e.g., subscription downgraded between cold start and submit), the server omits `aiSummary` from the response and the UI renders the FE-15 paywall card in its place. The non-AI body of the report still renders. Users always get value; only the narrative is gated.

### Push deep-link from "Still generating"
When the 30s long-tail panel surfaces, the UI registers a one-shot FCM listener for `report_ready` with the matching `reportId`. The push payload is `{ kind: 'report_ready', reportId, downloadUrl }`. Tapping the push deep-links to `/business/reports/:reportId` and the detail controller short-circuits its polling because the response already carries `status: 'ready'` from the cache hit.

### Error code → UI mapping
| HTTP | Error code | UI |
|---|---|---|
| 200 | — | normal flow |
| 400 | `validation_error` | inline error in Generate sheet |
| 401 | `unauthorized` | force `/login` |
| 403 | `not_in_role` / `not_entitled` | demoted modal or entitlement overlay (depending on code) |
| 404 | `report_not_found` | "This report is gone" empty state |
| 422 | `insufficient_data` | error panel with apology copy ("Not enough scans this period") |
| 429 | `rate_limited` / `quota_exceeded` | toast "Try again in {n} min" |
| 503 | `worker_busy` | retry-after header respected; UI shows "Servers busy — auto-retrying" |
| 5xx / network | — | offline read from cache if available, otherwise retry banner |

## Charts & Data Viz

The detail screen uses a small chart strip above the table for compatible kinds:

| Kind | Chart |
|---|---|
| `expirySummary` | Stacked bar — items expiring in 7/14/30 days |
| `lowStock` | Sparkline — count of below-threshold SKUs over the report window |
| `scanAudit` | Donut — verdict distribution (verified / mismatch / unknown) |
| `grnPostingLog` | Timeline strip — postings per day |
| `aiSummary` | Mixed — pulls visuals from each underlying kind into one strip |

All charts read from the same `report.summary.charts` payload (BE-20 returns it). They reuse FE-25's chart primitives — no new chart code in this phase.

Accessibility for charts:
- Each chart has a `Semantics(label: '<verbal description>', hint: 'Long-press for table view')`
- Long-press swaps the chart for a row/column data table accessible to screen readers
- Reduced motion: charts paint instantly with no path-trace animation

## Accessibility
- List row: `Semantics(label: '{kind} report, status {status}, generated {time}')`
- Generate-sheet AI toggle: announces "Include AI summary, Premium feature, currently {on|off}"
- Status chip changes announce live: "Status changed to running"
- PDF preview: respects `MediaQuery.textScaler`; the server PDF render is requested with `?textScale={current}` so the document itself reflects the user's text size
- Reduced motion: Lottie generating loop replaced with a 4-step text rotator; success pop replaced with static check
- Dynamic type xxLarge: kind cards drop to 1-up; PDF preview honors larger base font
- High contrast: status chip colors use luminance-mapped tokens; chart palettes have dark-mode variants
- Focus order: app bar back → tabs → list → FAB
- TalkBack/VoiceOver on detail: reads in order — header, status, summary stats, AI narrative (or paywall), table column headers, first 3 rows, "rest of {n} rows in scroll"
- Voice input on Generate-sheet param fields

## Testing

### Unit
- `reports_controller_test.dart`: list paginates, filters by kind, refreshes correctly
- `report_detail_controller_test.dart`: polling backoff matches the curve; long-tail switch at 30s; success short-circuit on push payload
- `report_cache_test.dart`: ETag hits skip network; offline open returns cached report
- `entitlement_test.dart`: AI section paywalls when server omits `aiSummary`, even with local `includeAiSummary: true`
- Idempotency key uniqueness per attempt

### Widget
- Generate sheet: AI toggle disabled for non-entitled; tapping opens FE-15 paywall
- Status chip color tween renders the three colors over 320ms
- Long-tail panel surfaces at exactly 30s; closing the screen still keeps the FCM listener alive
- Export sheet wires `share_plus` correctly (mocked)
- PDF preview honors `MediaQuery.textScaler` — golden frames at 1.0x and 1.5x

### Golden (light + dark + RTL)
- 10 anchor states × 3 themes × 3 sizes = 90 goldens
  - list-loading, list-empty, list-loaded, generate-sheet, detail-generating, detail-long-tail, detail-ready, detail-ready-ai-gated, detail-failed, export-sheet

### Integration (Patrol)
- Happy path: tap Generate → choose lowStock → submit → polling Lottie → status flips to ready (within ~6s on staging) → tap Export → Excel → OS share sheet
- Premium AI path: same with `includeAiSummary: true`; AI card renders
- Non-Premium AI path: `includeAiSummary: true` sent; server omits `aiSummary`; paywall card renders; rest of report unchanged
- Long-tail path: simulated 35s server delay → long-tail panel → backgrounded app → push fires → deep-link opens detail in `ready` state
- Quota exceeded: 429 → toast → CTA disabled 30s
- Offline open of cached report: airplane mode → list shows cached rows → tap row → detail loads from cache → export still works (uses local file)
- Insufficient-data path: 422 on generate → error panel with apology

### Perf
- Pixel 4a release build: 1000-row report list scroll at 60fps with jank rate < 1% (FE-39 gate)
- Detail open with cached report < 240ms p95
- PDF preview cold open < 1.2s p95 for a 5-page document

## Risk Assessment

| Risk | Likelihood | Mitigation |
|---|---|---|
| Polling pulse-burns battery if user leaves the detail open for hours | Medium | Cap polling at 30s, then switch to FCM listener; resume polling only on explicit refresh |
| Local plan flag stale, AI summary requested but not delivered | High | Server is the source of truth; UI always renders the paywall card on missing `aiSummary`, plan flag is just a UX hint |
| Idempotency key reused across attempts queues two worker jobs | Low/Critical | Fresh UUID per attempt; integration test asserts only one worker invocation per generate |
| 1000-row report table scroll janks on Pixel 4a | Medium | `ListView.builder` + `RepaintBoundary` per row + sticky header pinned via `SliverPersistentHeader`; verified by FE-39 perf pass |
| PDF preview ignores system text scale and looks tiny on xxLarge type | Medium | Server-side render with `?textScale={n}`; integration test forces `textScaler: 1.5x` and verifies PDF page font size |
| `share_plus` returns success on a cancelled share dialog (iOS quirk) | Medium | Treat any return as "user is done"; do not show success haptic on `ShareResultStatus.dismissed` |
| Push deep-link arrives before auth bootstrap completes | Medium | FE-05 deep-link queue holds the route until `authStateProvider` resolves |
| AI narrative card with embedded charts breaks layout in RTL | Low | Goldens cover RTL; chart primitives are RTL-aware (FE-25) |
| Excel export of >50k rows fails on low-memory devices | Low | Server caps row count at 50k per file and paginates into multiple files; UI surfaces a "Multiple files" hint |

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Generate-sheet kind picker shows 5 cards; tapping `lowStock` expands per-kind params with `motion.normal` `swiftOut` |
| T2 | `POST /reports/generate` returns `id, status: queued`; UI auto-routes to detail and the polling backoff matches the documented curve within ±50ms |
| T3 | Status flips queued → running → ready in a staging happy path; `report_ready_pop` plays once and the export FAB appears |
| T4 | Long-tail panel surfaces at exactly 30s; backgrounding the app keeps the FCM listener alive; the `report_ready` push deep-links back into the ready detail |
| T5 | Idempotency: two `POST /reports/generate` with the same key return the same `id`; only one worker job runs |
| T6 | Premium AI toggle on (entitled) sends `includeAiSummary: true`; response carries `aiSummary` and the AI card renders |
| T7 | Local plan stale (downgraded mid-session): server omits `aiSummary`; UI renders FE-15 paywall card; non-AI body still renders |
| T8 | Export Excel: 302 chased, file written to temp dir, `share_plus` opens OS share sheet; on dismiss, no success haptic |
| T9 | Export PDF: preview opens with system text scale honoured; pinch-to-zoom works; share + print actions in app bar |
| T10 | PDF preview at `MediaQuery.textScaler == 1.5x` requests `?textScale=1.5` and the rendered document uses the larger base font |
| T11 | Offline open of a cached report loads from Drift in < 200ms; export uses the local cached file; "Offline copy" badge in header |
| T12 | 1000-row report table scroll on Pixel 4a release build maintains < 1% jank rate |
| T13 | Reduced motion: generating Lottie replaced with text rotator; ready-pop replaced with static check; AI narrative paragraphs render without stagger |
| T14 | TalkBack reads detail in order: header, status, summary, AI narrative or paywall, table headers, first 3 rows |
| T15 | Quota exceeded: 429 with `quota_exceeded` code surfaces toast with retry-after timer; CTA disabled until timer expires |

### Q&A Questions (8)
1. Why poll at all instead of long-poll or WebSocket? What's the bandwidth and battery cost of the chosen backoff curve over a long generation?
2. How does the UI distinguish between "AI summary missing because not entitled" and "AI summary missing because the server failed to generate" — and what's the user copy for each?
3. What's the cleanup strategy for downloaded Excel/PDF files in the temp directory — TTL, on-app-launch sweep, or LRU?
4. How do we keep the Drift report cache from growing unbounded — evict by age, by storage cap, or by explicit user action?
5. What happens when a scheduled report's cadence changes (e.g., weekly → monthly) — does the next-run timestamp recompute on the server or on the client?
6. How does the UI handle a `share_plus` return of `ShareResultStatus.unavailable` (e.g., no share targets installed) — silent failure or visible advisory?
7. What's the analytics taxonomy for `report_generated`, `report_exported`, `report_scheduled` so the Owner Dashboard can compute "weekly active reporters" and "AI summary attach rate"?
8. How do we keep PDF text-scale rendering honest across Android (Skia) and iOS (CoreGraphics) — is the server PDF renderer normalized to a single output, or do we expect per-OS pixel diffs?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 90% on `lib/features/business/reports/**`; 1000-row scroll perf gate met
- [ ] Developer: 8 Q&A answered in the handoff doc
- [ ] Reviewer: idempotency + long-tail push path verified end-to-end on hardware
- [ ] Reviewer: confirmed AI gating is server-enforced; UI never reveals `aiSummary` it didn't receive
- [ ] Designer (motion review): generating loop, ready pop, status chip color tween reviewed on hardware
- [ ] Accessibility reviewer: TalkBack + VoiceOver on detail, PDF text-scale verified at 1.0x and 1.5x
- [ ] PM: Microcopy reviewed in all 6 languages

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________
**Accessibility Reviewer Signature**: ___________________________

---
**END OF FE-32 — DO NOT PROCEED WITHOUT APPROVAL**
