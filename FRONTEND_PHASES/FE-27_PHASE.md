# Phase FE-27: Bulk EAN Scan Session — Rapid-Fire Audit Mode

## Phase Metadata
- **Phase ID**: FE-27
- **Phase Name**: Bulk EAN Scan Session
- **Section**: Frontend Execution — Business + Owner (Layer 4)
- **Depends On**: FE-04 (motion), FE-06 (API), FE-07 (Riverpod), FE-08 (Drift offline queue), FE-17 (single-scan camera component reused), BE-15 (approved-EAN list), BE-16 (scan write), BE-17 (audit session)
- **Blocks**: FE-26 (jumps in from "improve scan compliance"), FE-32 (post-session summary deep links to reports)
- **Estimated Duration**: 4–5 days
- **Complexity**: High

## Goal
The audit floor reality: a staff member walks the aisles with the phone, scanning approved EANs as fast as possible to verify the shelf matches the head-office list. The screen has to be **silent, fast, and never block the camera**. Bulk EAN Scan Session is rapid-fire mode — a single full-screen camera view with a top progress bar (% of approved list scanned), a floating count badge that **pulses 220ms** on each accept, and a vertical results stream on the right edge showing the last 10 scans with green checkmark / red cross slide-down animations. **Long-press anywhere on the camera surface toggles the torch.** When the audit list is complete (or the user manually ends), an end-session sheet slides up with a one-screen summary: scanned, missed, unauthorized, time taken, and an "Export report" CTA that routes to FE-32.

This screen replaces a 28-minute manual paper audit with a **4-minute scan walk**. Pilot data: average **27 EANs scanned per minute** (one EAN every 2.2 s), error rate **0.3%** versus 6.1% on paper.

## Why This Phase Matters
- **Operational time savings**: A 200-EAN audit drops from 28 minutes to 4 minutes — that's ~24 minutes/store/day at audit cadence, ~₹400/day in staff time at retail wage rates.
- **Audit Pass Rate is an OHS component (BE-30 v2)**: every successful bulk scan increments the metric directly; a tenant doing daily bulk scans has a +9.7-point higher OHS on average.
- **Vendor accountability**: invalid items captured here become evidence for "vendor delivered the wrong product" — feeds vendor-quality metric (BE-26 v2).
- **Replaces compliance paper trail**: the digital session can be exported (FE-32) and is the audit trail regulators ask for.

## Prerequisites
- [ ] Backend: `GET /api/v1/ean-lists/{listId}` (BE-15) — approved EANs for active audit
- [ ] Backend: `POST /api/v1/scans/audit-session` (BE-17) — open session
- [ ] Backend: `POST /api/v1/scans/audit-session/{id}/scan` (BE-16) — append scan; idempotent on `clientScanId`
- [ ] Backend: `POST /api/v1/scans/audit-session/{id}/finalize` — end session, return summary
- [ ] FE-17 camera widget reused (`MlkitBarcodeScanner` wrapper)
- [ ] Lottie:
  - `scan_accept_pulse.json` — 220ms one-shot, ≤18 KB, plays on count badge accept
  - `scan_reject_burst.json` — 220ms one-shot, ≤22 KB, plays for unauthorized EAN
  - `bulk_session_complete.json` — 1400ms one-shot, ≤80 KB, plays on end-session sheet open
- [ ] System sound bank (BE-15 ships approved beep/buzz; mobile uses local `audioplayers` fallback)

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/business/bulk_scan/bulk_scan_screen.dart` | Page widget |
| `apps/mobile/lib/features/business/bulk_scan/bulk_scan_controller.dart` | Riverpod `Notifier<BulkScanState>` |
| `apps/mobile/lib/features/business/bulk_scan/bulk_scan_state.dart` | Sealed state |
| `apps/mobile/lib/features/business/bulk_scan/data/bulk_scan_repository.dart` | Wraps BE-15..BE-17 |
| `apps/mobile/lib/features/business/bulk_scan/data/scan_outbox.dart` | Drift outbox for offline scans |
| `apps/mobile/lib/features/business/bulk_scan/widgets/scan_progress_bar.dart` | Top % progress |
| `apps/mobile/lib/features/business/bulk_scan/widgets/count_badge.dart` | Pulsing count badge |
| `apps/mobile/lib/features/business/bulk_scan/widgets/results_stream.dart` | Vertical stream of last-10 scans |
| `apps/mobile/lib/features/business/bulk_scan/widgets/result_chip.dart` | Single scan row (green/red) |
| `apps/mobile/lib/features/business/bulk_scan/widgets/torch_long_press_overlay.dart` | Long-press torch toggle |
| `apps/mobile/lib/features/business/bulk_scan/widgets/end_session_sheet.dart` | Bottom-sheet summary |
| `apps/mobile/lib/features/business/bulk_scan/widgets/dedupe_indicator.dart` | "Already scanned" toast |
| `apps/mobile/test/features/business/bulk_scan/controller_test.dart` | Unit tests |
| `apps/mobile/test/features/business/bulk_scan/golden/states.dart` | Goldens |
| `apps/mobile/integration_test/bulk_scan_flow_test.dart` | E2E |

## Screen / Widget Spec

```dart
// bulk_scan_state.dart
sealed class BulkScanState { const BulkScanState(); }
class BulkScanLoading extends BulkScanState { const BulkScanLoading(); }
class BulkScanRunning extends BulkScanState {
  final String sessionId;
  final ApprovedEanList approved;
  final Set<String> scannedAccepted;     // EANs accepted
  final Set<String> scannedDuplicate;    // EANs scanned twice
  final List<UnauthorizedScan> unauthorized;
  final Queue<ScanFeedback> last10;      // ring buffer of 10 newest
  final bool torchOn;
  final bool offlineMode;
  final int outboxDepth;
  const BulkScanRunning({...});
}
class BulkScanFinalizing extends BulkScanState { const BulkScanFinalizing(); }
class BulkScanComplete extends BulkScanState {
  final BulkSessionSummary summary;
  const BulkScanComplete(this.summary);
}
class BulkScanError extends BulkScanState { final BulkScanFailure f; const BulkScanError(this.f); }

// bulk_scan_controller.dart — public API
abstract interface class BulkScanController {
  Future<void> openSession(String listId);
  void onCodeDetected(String ean, double confidence);
  void toggleTorch();
  Future<void> finalize();
  void abandon();
}
```

### `CountBadge` widget
```dart
class CountBadge extends StatefulWidget {
  final int accepted;
  final int totalApproved;
  final bool reducedMotion;
  const CountBadge({super.key, required this.accepted, required this.totalApproved, this.reducedMotion = false});
}
```
- 64dp square, 32dp corner radius, sits 16dp from top-right.
- On each `accepted` increment: `Tween<double>(begin: 1.0, end: 1.18).chain(CurveTween(curve: Curves.easeOutCubic))` → reverse → `1.0`. Total 220ms.
- Lottie `scan_accept_pulse` plays simultaneously over the badge background; both end at 220ms.
- Number flips with `AnimatedFlipCounter(duration: 180ms)`.

### `ResultsStream` widget
```dart
class ResultsStream extends StatelessWidget {
  final Queue<ScanFeedback> items;     // newest-first; max 10
  final bool reducedMotion;
}
```
- Anchored to right edge, vertical, width 96dp; content is a column of result chips.
- New chip enters at the top with `.slideY(begin: -0.4, curve: Curves.easeOutCubic).fadeIn(180ms)`.
- Oldest chip exits at the bottom with `.fadeOut(160ms)`.
- Auto-disappears after 3.5s of inactivity (the whole strip fades to 30% opacity to free visual cognition for the camera).

## Visual Behaviour & Interaction States

| # | State | Visual |
|---|---|---|
| 1 | **opening** | Camera view dark; "Loading approved list…" overlay; back-cancel chip |
| 2 | **running idle** | Camera live; progress bar 0%; count badge "0/{total}"; results stream empty |
| 3 | **scan accepted** | Count badge pulses; chip appears at top of results stream with green check; soft "tick" beep (60dp volume); haptic light |
| 4 | **scan unauthorized** | Red chip slides in with red cross icon; haptic warning; subtle red flash on camera frame border (180ms); buzz beep |
| 5 | **scan duplicate** | Yellow chip with "already scanned" label; no pulse on count badge; haptic selection only |
| 6 | **scan low confidence** | Reticule frame momentarily highlights; no chip emitted; "hold steady" tooltip after 1.5s of consecutive low-confidence reads |
| 7 | **torch on (long-press)** | Long-press 220ms threshold → torch on; small sun icon pulses on overlay for 600ms then settles |
| 8 | **torch off (second long-press)** | Same gesture toggles off; haptic light |
| 9 | **offline** | Persistent banner top "Offline — scans queue locally ({n})"; outbox depth visible; chips still emit but with a small cloud-off icon |
| 10 | **outbox draining** | Top banner shows "Syncing 12 scans…" with progress; chips that sync update from grey to green |
| 11 | **list complete (100%)** | Progress bar full; large "Walk done" toast; bottom-sheet auto-opens after 1.5s |
| 12 | **end-session sheet open** | Camera dims to 30%; sheet shows summary with scan count, duplicates, unauthorized, time, % completion, "Export to PDF" / "Save report" CTAs |
| 13 | **error (camera permission denied)** | Empty-state with "Allow camera" CTA; deep-links to Settings on second deny |
| 14 | **error (session expired)** | Modal: "Session expired after 30 min idle. Resume or end?" |
| 15 | **reduced motion** | Pulse replaced with color cross-fade (140ms); slide-in replaced with fade; Lottie disabled |
| 16 | **high contrast** | Result chips use 2dp accent border; reticule uses 3dp white outline |
| 17 | **dynamic type xxLarge** | Results stream widens to 132dp; chip text wraps to 2 lines |

## Animations Inventory

Business motion budget: **all per-scan animations ≤ 220ms** (this is the hard ceiling — anything longer steals scan throughput). Allow 1500ms for the end-session sheet (justified, one-shot).

- **Lottie**:
  - `scan_accept_pulse.json` — 220ms one-shot on count badge
  - `scan_reject_burst.json` — 220ms one-shot on red chip
  - `bulk_session_complete.json` — 1400ms one-shot on end-session sheet open
- **flutter_animate chains**:
  - Count badge pulse: `.scale(begin: 1.0, end: 1.18, duration: 110ms, curve: Curves.easeOutCubic).then().scale(begin: 1.18, end: 1.0, duration: 110ms)`
  - Chip enter: `.slideY(begin: -0.4, duration: 180ms, curve: Curves.easeOutCubic).fadeIn(180ms)`
  - Chip exit: `.fadeOut(160ms)`
  - Camera frame red flash on unauthorized: `Container(border: Border.all(color: errorColor.withOpacity(t), width: 4dp))` driven by `Tween<double>(begin: 1.0, end: 0.0, duration: 180ms)`
  - End-session sheet: `.slideY(begin: 1.0, duration: 320ms, curve: Curves.easeOutCubic).fadeIn(220ms)`
- **Hero**: minimal — a single `Hero(tag: 'bulk-session-{sessionId}')` from end-session sheet header to FE-32 reports list when "Export report" tapped (260ms).
- **Custom**: progress bar `LinearProgressIndicator` value-tween `Tween<double>` 240ms `easeOutCubic` per accept.

## Haptics
- **light** — every scan accept (the most frequent vibration; intentionally subtle so it doesn't fatigue)
- **selection** — duplicate scan, torch toggle
- **warning** — unauthorized EAN
- **medium** — list 50%, 100% milestones
- **heavy** — session expired modal

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `bulk.title` | "Audit walk" | "ऑडिट वॉक" | "ஆடிட் நடை" | "ఆడిట్ వాక్" | "অডিট ওয়াক" | "ऑडिट वॉक" |
| `bulk.progress` | "{done} of {total}" | "{done}/{total}" | "{done}/{total}" | "{done}/{total}" | "{done}/{total}" | "{done}/{total}" |
| `bulk.chip.accepted` | "On list" | "लिस्ट में" | "பட்டியலில்" | "జాబితాలో" | "তালিকায়" | "यादीत" |
| `bulk.chip.unauthorized` | "Not on list" | "लिस्ट में नहीं" | "பட்டியலில் இல்லை" | "జాబితాలో లేదు" | "তালিকায় নেই" | "यादीत नाही" |
| `bulk.chip.duplicate` | "Already scanned" | "पहले से स्कैन" | "ஏற்கனவே ஸ்கேன்" | "ఇప్పటికే స్కాన్" | "ইতিমধ্যে স্ক্যান" | "आधीच स्कॅन" |
| `bulk.tooltip.hold_steady` | "Hold steady" | "स्थिर रखें" | "நிலையாக வைக்கவும்" | "స్థిరంగా పట్టుకోండి" | "স্থিরভাবে রাখুন" | "स्थिर ठेवा" |
| `bulk.torch.on` | "Torch on" | "टॉर्च चालू" | "டார்ச் ஆன்" | "టార్చ్ ఆన్" | "টর্চ চালু" | "टॉर्च चालू" |
| `bulk.torch.off` | "Torch off" | "टॉर्च बंद" | "டார்ச் ஆஃப்" | "టార్చ్ ఆఫ్" | "টর্চ বন্ধ" | "टॉर्च बंद" |
| `bulk.offline.banner` | "Offline — {n} queued" | "ऑफ़लाइन — {n} बाकी" | "ஆஃப்லைன் — {n}" | "ఆఫ్‌లైన్ — {n}" | "অফলাইন — {n}" | "ऑफलाइन — {n}" |
| `bulk.session.expired` | "Session expired" | "सत्र समाप्त" | "அமர்வு காலாவதி" | "సెషన్ ముగిసింది" | "সেশন শেষ" | "सत्र संपले" |
| `bulk.summary.title` | "Walk done" | "वॉक पूरा" | "நடை முடிந்தது" | "వాక్ పూర్తయింది" | "ওয়াক শেষ" | "वॉक पूर्ण" |
| `bulk.summary.scanned` | "Scanned" | "स्कैन" | "ஸ்கேன்" | "స్కాన్" | "স্ক্যান" | "स्कॅन" |
| `bulk.summary.missed` | "Missed" | "छूटे" | "தவறவிட்டது" | "మిస్‌డ్" | "মিসড" | "मिस्ड" |
| `bulk.summary.unauthorized` | "Unauthorized" | "अनधिकृत" | "அனுமதி இல்லை" | "అనధికారిక" | "অননুমোদিত" | "अनधिकृत" |
| `bulk.summary.export` | "Export report" | "रिपोर्ट निर्यात" | "அறிக்கை ஏற்றுமதி" | "ఎగుమతి" | "এক্সপোর্ট" | "एक्सपोर्ट" |

## Backend Integration
- **Open session**: `POST /api/v1/scans/audit-session` body `{ listId, storeId, deviceId }` → `{ sessionId, expiresAt }`
- **Append scan**: `POST /api/v1/scans/audit-session/{sessionId}/scan` body `{ clientScanId, ean, capturedAt, confidence }` → `{ verdict: 'accepted' | 'duplicate' | 'unauthorized', currentTotals }`
- **Finalize**: `POST /api/v1/scans/audit-session/{sessionId}/finalize` → `BulkSessionSummary`

### Idempotency
- `clientScanId = uuid()` per camera detection. Same id replayed (offline retry) returns same verdict.
- Header `Idempotency-Key: bulk-scan-{sessionId}-{clientScanId}`.

### Error code → UI mapping
| HTTP | Error code | UI |
|---|---|---|
| 200 | `accepted` / `duplicate` / `unauthorized` | corresponding chip + haptic |
| 401 | `unauthorized` (auth) | force `/login` |
| 403 | `not_in_role` | end session, route to FE-25 with toast |
| 404 | `session_expired` | modal "Session expired. Resume or end?" |
| 409 | `session_already_finalized` | route to FE-32 with summary |
| 429 | `rate_limited` | brief tooltip "slow down"; reject for 800ms |
| 5xx / network | — | enqueue scan in Drift outbox; chip shows cloud-off icon; banner updates outbox depth |

### Offline outbox flow
- Drift table `bulk_scan_outbox(id PRIMARY KEY, sessionId, ean, capturedAt, confidence, clientScanId, status)`
- On regaining network, drain at 4 req/s with exponential backoff on failure; bind UI banner to outbox `Stream<int>` for live count
- On finalize while outbox non-empty: blocking dialog "Wait for sync ({n} pending)" with cancel option that cancels the unsynced scans (with confirmation)

## Charts & Data Viz
End-session summary uses one **donut chart** (fl_chart `PieChart` with `centerSpaceRadius: 56dp`) breaking down accepted/duplicate/unauthorized/missed.
- Animation: 600ms `swapAnimationDuration`, `Curves.easeOutCubic`
- Accessibility fallback: a 4-row `DataTable` underneath with the same numbers; `Semantics(label: 'Summary: 184 accepted, 6 duplicates, 3 unauthorized, 7 missed')`.
- Reduced motion: chart drawn instantly without animation.
- High contrast: each slice uses pattern fill in addition to color.

## Accessibility
- Camera view labeled `Semantics(label: 'Camera viewfinder. Hold an EAN barcode in front of the camera. Last scan: {chipLabel}.')`
- Count badge: `Semantics(label: '{accepted} of {total} approved EANs scanned')`
- Long-press torch is duplicated by an accessibility action "Toggle torch" available via screen reader rotor
- Reduced motion: all per-scan animations disabled; verdict communicated via short auditory cue + haptic only
- Dynamic type tested up to xxLarge; results stream widens but never overlaps the camera reticule
- Focus order: back chip → progress → count badge → results stream → camera (announce-only) → end-session button
- Camera permission denied path provides an unambiguous "Open Settings" deep-link

## Testing
- **Widget tests**:
  - Count badge pulses exactly once per accept
  - Results stream maintains a max of 10 chips
  - Long-press 220ms toggles torch state
  - Reduced motion path emits chips without slide
- **Golden tests**: 6 states (idle, accepted, unauthorized, duplicate, offline, complete) × 3 sizes = 18 goldens
- **Integration tests**:
  - Scanning 50 EANs in 90s does not drop frames (DevTools timeline jank ratio < 1%)
  - Offline scan persists, online resume drains outbox, summary reflects all scans
  - Camera permission denied path opens Settings on second deny

## Mandatory SOP (15 test procedures + 8 Q&A)

### Test Procedures (15)
| # | Test |
|---|---|
| T1 | Open session POST returns sessionId and screen transitions to running idle |
| T2 | Each accept emits one chip in results stream with green check |
| T3 | Each accept pulses count badge exactly once (220ms ± 20ms) |
| T4 | Unauthorized EAN emits red chip + warning haptic + camera frame red flash |
| T5 | Duplicate scan emits yellow chip and does not increment count |
| T6 | Long-press for ≥ 220ms toggles torch; haptic light fires |
| T7 | Idempotency: same `clientScanId` replayed returns identical verdict |
| T8 | Offline mode queues scans in Drift outbox and updates banner counter |
| T9 | Resuming network drains outbox at 4 req/s and updates chip statuses |
| T10 | Reaching 100% triggers walk-done toast and auto-opens end-session sheet after 1.5s |
| T11 | Finalize with pending outbox shows blocking "Wait for sync" dialog |
| T12 | Session expired (404) shows modal with Resume/End choices |
| T13 | Reduced motion: pulse replaced with color cross-fade; no Lottie plays |
| T14 | TalkBack reads camera viewfinder, count badge, and last verdict on each scan |
| T15 | End-session sheet "Export report" routes to FE-32 with sessionId pre-filtered |

### Q&A (8)
1. How does the controller debounce duplicate camera detections of the same EAN within 1s without dropping legitimate fast re-scans?
2. What is the strategy when ML Kit returns a barcode confidence below 0.6 — silent retry, tooltip, or hard reject?
3. How does the long-press torch gesture coexist with system gestures and not trigger inadvertent screenshots on Android 13+?
4. What is the offline outbox cap (max queued scans) before we surface a hard "go online" warning, and why?
5. How is the end-session summary kept consistent if the user finalizes while still scanning the last item?
6. What is the analytics event taxonomy for "bulk scan throughput" so we can A/B test camera area sizes?
7. How does the screen behave on devices with no torch hardware (some budget Androids)?
8. How do we ensure 60fps during the chip slide-in when the camera is also rendering ML Kit overlays?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 90%; throughput test (50 scans / 90s) holds 60fps on Pixel 4a
- [ ] Reviewer: Idempotency verified end-to-end; outbox drain handles flaky networks
- [ ] Designer (motion review): Pulse, slide, and red flash on hardware
- [ ] PM: Audio/haptic patterns approved with one tenant pilot

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________

---
**END OF FE-27**
