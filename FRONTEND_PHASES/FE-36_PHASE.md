# Phase FE-36: Offline-First Sync UI

## Phase Metadata
- **Phase ID**: FE-36
- **Phase Name**: Offline-First Sync UI
- **Section**: Layer 5 — Polish + Cross-cutting
- **Depends On**: FE-06 (Dio + offline queue scaffold), FE-07 (Riverpod), FE-08 (Drift + sync hooks), FE-33 (motion tokens), FE-34 (`RadhaPullToRefresh`, `SwipeAction`)
- **Backend Depends On**: BE-44 sync API (`POST /sync/scans`, `POST /sync/saved-products`, `POST /sync/allergen-profiles`, `GET /sync/changes?since=`), BE-46 quotas (sync-time enforcement), BE-48 observability (sync errors)
- **Blocks**: FE-37 (sync error states use the same banner), FE-40 (release prep depends on this for store listing screenshots)
- **Estimated Duration**: 3-4 days
- **Complexity**: High — concurrency + UX + correctness all converge here

## Goal
Make the offline-first contract from BE-44 visible, trustworthy, and recoverable end-to-end. Specifically:

- **Global sync indicator** in the app shell with four states: `idle`, `queued (n)`, `syncing`, `error (n)`. Always visible, never blocking.
- **Per-screen optimistic UI**: every mutation appears applied within 60ms, then either commits or rolls back when the server replies. List rows show a tiny `pending` dot until acknowledged.
- **Conflict resolution UX**: when BE-44 returns a server-wins result on critical fields (`subscriptions.tier`, `users.role`, `email_verified`), the user sees a one-time toast — never a silent overwrite.
- **Pull-to-refresh** integrates with sync: it flushes the outbound queue *first*, then pulls server changes since the last cursor.
- **Idempotency keys** generated per mutation (UUID v4) on the device and persisted in Drift so retries reuse the key — never the request body.
- **Sync queue inspection screen** (Settings → Advanced → Sync queue) for power users and support staff: lists every pending mutation with timestamp, route, status (`queued/inflight/failed/applied`), error reason, and a "retry now" / "drop" affordance.
- **Concurrency safety**: max 4 in-flight requests; FIFO inside each table family; cross-table parallel allowed.
- **Resumable on app kill**: queue persisted; first cold start after kill flushes the queue before showing any data.

## Why This Phase Matters
- **Tier-2/3 users live on flaky networks.** Industry data shows median 2G/3G fallback time per session in tier-3 cities is 6-12 minutes. Without offline-first the app is unusable; with offline-first invisible to the user, the app feels indistinguishable from a $50K/yr SaaS.
- **Trust on writes**: a shopkeeper scanning 200 items at end-of-shift cannot redo work because the network died. Optimistic UI plus server-side idempotency (BE-44) makes "I scanned this" durable from the second it leaves the user's finger.
- **Conflict transparency**: silent server overwrites are the #1 source of "I lost my work" support tickets in offline-first apps. A one-time, dismissible toast makes the behaviour observable without breaking flow.
- **Retention loop**: an outage that surfaces a "you're offline, your work is queued" banner instead of a blank screen earns the next session.
- **Engineering predictability**: a single sync queue with explicit states makes the behaviour testable end-to-end — instead of every screen reinventing offline UX.
- **Backend symmetry**: BE-44 invested heavily in idempotency + Lamport clocks + bulk endpoints. Without this phase, none of that work surfaces to users.

## Prerequisites
- [ ] BE-44 deployed; bulk endpoints accept ≤ 200 items per call.
- [ ] FE-08 Drift sync table (`sync_queue`) exists with the columns below.
- [ ] FE-06 Dio offline queue intercepting writes when offline.
- [ ] `connectivity_plus` package + `network_info_plus` for SSID-aware sync gating.
- [ ] Sentry breadcrumbs from BE-48 for sync errors.

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/sync/sync_state.dart` | Sealed `SyncState` (idle / queued / syncing / error) + `QueueItemStatus` |
| `apps/mobile/lib/sync/sync_controller.dart` | Riverpod `AsyncNotifier<SyncState>` — orchestrator |
| `apps/mobile/lib/sync/sync_queue_repository.dart` | Drift CRUD on `sync_queue` table |
| `apps/mobile/lib/sync/sync_dispatcher.dart` | Calls BE-44 bulk endpoints with ≤ 4 in-flight throttle |
| `apps/mobile/lib/sync/conflict_resolver.dart` | Reads server-wins fields and emits user-visible conflict events |
| `apps/mobile/lib/sync/idempotency.dart` | UUID v4 generator + per-mutation key persistence |
| `apps/mobile/lib/sync/sync_indicator.dart` | The ever-present app-shell indicator (4 states) |
| `apps/mobile/lib/sync/sync_banner.dart` | Top inline banner (offline / sync error / conflict) |
| `apps/mobile/lib/sync/optimistic_mutation.dart` | Helper that wraps any write: `optimistic(local: …, remote: …)` |
| `apps/mobile/lib/sync/sync_aware_pull_to_refresh.dart` | Wraps `RadhaPullToRefresh` from FE-34 with sync flush |
| `apps/mobile/lib/features/settings/sync_queue_screen.dart` | Power-user inspection screen |
| `apps/mobile/lib/features/settings/widgets/sync_queue_row.dart` | One row per pending mutation |
| `apps/mobile/test/sync/sync_controller_test.dart` | Unit |
| `apps/mobile/test/sync/conflict_resolver_test.dart` | Unit |
| `apps/mobile/test/sync/optimistic_mutation_test.dart` | Roll-back path |
| `apps/mobile/integration_test/offline_sync_flow_test.dart` | Airplane mode E2E |

## Implementation Spec

### `sync_queue` Drift table
```sql
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  idempotency_key TEXT NOT NULL UNIQUE,
  table_family TEXT NOT NULL,           -- 'scans' | 'saved_products' | 'allergens'
  method TEXT NOT NULL,                 -- 'POST' | 'PUT' | 'DELETE'
  path TEXT NOT NULL,
  body_json TEXT NOT NULL,
  lamport_clock INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'queued', -- 'queued' | 'inflight' | 'failed' | 'applied'
  attempts INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  enqueued_at DATETIME NOT NULL,
  last_attempt_at DATETIME,
  applied_at DATETIME
);
CREATE INDEX idx_sync_queue_status ON sync_queue(status, enqueued_at);
```

### `SyncState` sealed
```dart
sealed class SyncState {
  const SyncState();
}
class SyncIdle extends SyncState { final DateTime lastSyncAt; const SyncIdle(this.lastSyncAt); }
class SyncQueued extends SyncState { final int count; const SyncQueued(this.count); }
class SyncRunning extends SyncState { final int total, done; const SyncRunning(this.total, this.done); }
class SyncError extends SyncState { final int failedCount; final String? lastErrorCode; const SyncError(this.failedCount, this.lastErrorCode); }
```

### `SyncController` orchestration
```dart
class SyncController extends AsyncNotifier<SyncState> {
  static const _maxInFlight = 4;
  static const _bulkBatchSize = 50;

  Future<void> flush() async {
    final connectivity = await ref.read(connectivityProvider.future);
    if (!connectivity.isOnline) return; // banner already up
    final queued = await _repo.fetchQueued(limit: 200);
    if (queued.isEmpty) { state = AsyncData(SyncIdle(DateTime.now())); return; }

    state = AsyncData(SyncRunning(queued.length, 0));
    final byFamily = groupBy(queued, (q) => q.tableFamily);
    int done = 0; int failed = 0;
    final futures = <Future<void>>[];
    for (final entry in byFamily.entries) {
      futures.add(_dispatcher.dispatchFamily(
        entry.key,
        entry.value,
        onItemDone: (status) {
          done++;
          if (status == 'failed') failed++;
          state = AsyncData(SyncRunning(queued.length, done));
        },
      ));
      if (futures.length >= _maxInFlight) await Future.any(futures);
    }
    await Future.wait(futures);
    state = failed > 0
      ? AsyncData(SyncError(failed, _repo.lastErrorCode()))
      : AsyncData(SyncIdle(DateTime.now()));
  }
}
```

### `optimistic_mutation.dart`
```dart
Future<T> optimistic<T>({
  required Future<T> Function() local,    // apply to Drift first
  required Future<T> Function(String idemKey) remote, // schedule send
  required Future<void> Function(T) rollback,
}) async {
  final idem = Idempotency.newKey();
  final localResult = await local();
  unawaited(() async {
    try {
      await remote(idem);
    } catch (e) {
      await rollback(localResult);
    }
  }());
  return localResult;
}
```

### Conflict resolution UX
```dart
// When BE-44 reports a server-wins resolution on a critical field, we emit
// a `SyncConflict` event into a stream consumed by the app shell.
class SyncConflict {
  final String table;
  final String field;
  final dynamic clientValue;
  final dynamic serverValue;
  final String userVisibleMessage; // i18n keyed
}

// app_shell.dart listens and shows a one-time SnackBar, never silent.
ref.listen(syncConflictStreamProvider, (prev, next) {
  next.whenData((c) {
    rootScaffold.showSnackBar(SnackBar(
      content: Text(c.userVisibleMessage),
      action: SnackBarAction(label: 'Details', onPressed: () => context.push('/settings/sync-queue')),
    ));
    Haptics.fire(HapticLevel.warning);
  });
});
```

### Sync indicator visual states
| State | Pill text | Pill color | Icon | Pulse animation |
|---|---|---|---|---|
| `SyncIdle` | "Up to date" or hidden | surface.container | check (subtle, fades after 2s) | none |
| `SyncQueued(n)` | "n waiting" | warning.container | upload arrow | none |
| `SyncRunning(t, d)` | "Syncing… d/t" | primary.container | spinner | rotating |
| `SyncError(n, code)` | "Sync failed — retry" | error.container | warning triangle | gentle pulse 2s loop |

The pill lives in the top-right of the app bar on Consumer screens, and inline above the bottom bar on Business screens (where the app bar is densely packed).

## Patterns / Reusable Widgets

| Widget / Helper | API |
|---|---|
| `SyncIndicator` | reads `syncControllerProvider`; tappable → opens sync queue screen |
| `SyncBanner` | full-width banner; auto-dismisses on `SyncIdle`; `Retry` button on `SyncError` |
| `SyncAwarePullToRefresh` | flushes queue first, then fetches `/sync/changes` |
| `optimistic(...)` helper | wraps any write to apply locally, schedule remote, roll back on fail |
| `ConflictToast` | one-time, action-equipped SnackBar with `Details` deep link |
| `SyncQueueScreen` | settings entry with rows for every pending item; allows retry / drop |
| `SyncQueueRow` | shows family, body summary, age, status, error reason |
| `Idempotency.newKey()` | UUID v4 with a 9-character entropy prefix for log readability |
| `OfflineGuard` | wraps a screen; if offline + no cached data, shows offline empty state from FE-37 |

## Configuration / Tokens

| Token | Value | Why |
|---|---|---|
| `sync.maxInFlightRequests` | 4 | Balance throughput against radio battery cost |
| `sync.bulkBatchSize` | 50 | Matches BE-44 server-side batch ceiling |
| `sync.maxQueueDepth` | 5000 | Above this, oldest queued items archive to a `sync_queue_archive` table; user gets banner |
| `sync.flushTriggerDebounceMs` | 800 | Debounces rapid mutations into one flush burst |
| `sync.flushOnConnectivityRegainDelayMs` | 1500 | Wait for radio to settle before bulk send |
| `sync.retryBaseMs` | 800 | First retry delay |
| `sync.retryMaxMs` | 60000 | Cap (1 minute) — backend handles longer with its own retry logic |
| `sync.retryMaxAttempts` | 8 | Exponential up to 1 min — hands off to user retry after |
| `sync.serverWinsFields` | `['subscriptions.tier','subscriptions.status','users.role','users.email_verified']` | Mirrors BE-44 critical fields list |
| `sync.idempotencyKeyEntropyBytes` | 16 | UUID v4 standard |
| `sync.indicator.minVisibleMs` | 600 | Don't flash "syncing" so fast users miss it |
| `sync.indicator.idleAutoHideMs` | 2000 | "Up to date" check fades after 2s |
| `sync.banner.offlineDelayMs` | 4000 | Don't show "you're offline" for transient blips |
| `sync.lamportClockField` | `sync_clock` | Each mutation increments by 1 |
| `sync.changeFetch.cursorKey` | `sync_cursor` (Drift `app_settings`) | Single per-user cursor |

## Per-Screen Application Checklist

| Screen / Phase | Optimistic UI | Pending dot | Sync banner reachable | Conflict path |
|---|---|---|---|---|
| Onboarding cards FE-10 | n/a | — | — | — |
| OTP verify FE-12 | n/a (sync) | — | — | — |
| Premium subscribe FE-13 | n/a (must be online) | — | offline blocks | server-wins on tier — toast |
| Family invite FE-14 | ✓ invite row | ✓ on row | ✓ | invite expired = server-wins toast |
| Allergen setup FE-15 | ✓ chip toggle | ✓ on family-member tab | ✓ | — |
| Scanner FE-17 | ✓ scan persists locally | — | ✓ | quota at sync time → show upgrade |
| Scan output FE-18 | ✓ save-to-list | ✓ on saved card | ✓ | — |
| Expiry calendar FE-20 | ✓ mark consumed | ✓ on day cell | ✓ | — |
| Recall inbox FE-21 | ✓ acknowledge | ✓ on row | ✓ | — |
| Shopping list FE-24 | ✓ add/tick/delete | ✓ on row | ✓ | — |
| Business dashboard FE-25 | read-only mostly | — | ✓ | OHS recompute server-wins |
| Bulk scan FE-27 | ✓ all 200 scans queued | ✓ on each | ✓ | quota at sync time |
| Expiry tracker biz FE-28 | ✓ entries | ✓ on row | ✓ | — |
| GRN wizard FE-29 | ✓ submit batch | ✓ on draft | ✓ | supplier validation server-wins |
| Inventory FE-30 | ✓ adjustments | ✓ on row | ✓ | count rule server-wins |
| Tasks FE-31 | ✓ complete | ✓ on row | ✓ | task reassigned server-wins |
| Reports FE-32 | n/a (read-only) | — | ✓ | — |
| Settings — Sync Queue | n/a | — | ✓ | — |
| Settings — Language Switcher | ✓ | — | — | — |

## Backend Integration

| Backend | Role |
|---|---|
| **BE-44 `POST /api/v1/sync/scans`** | Bulk endpoint accepting up to 50 items + idempotency keys. Per-item response shape: `{idempotencyKey, status: 'applied'\|'duplicate'\|'conflict'\|'rejected', resolution?: 'server_wins', error?}`. |
| **BE-44 `POST /api/v1/sync/saved-products`** | Same bulk shape. |
| **BE-44 `POST /api/v1/sync/allergen-profiles`** | Same bulk shape; encrypted payloads handled transparently by Dio interceptor. |
| **BE-44 `GET /api/v1/sync/changes?since=<cursor>`** | Pull-side: 60s long-poll allowed; cursor stored in `app_settings.sync_cursor`. |
| **BE-44 idempotency contract** | Same key + same payload returns the cached response. Same key + different payload returns 409 — surfaced as a hard sync error and deep-linked into the queue screen for manual drop/retry. |
| **BE-46 quotas** | A queued scan that crosses the daily limit at sync time returns 429; UI demotes the queued row to "blocked", offers "Upgrade to Premium" deep link. |
| **BE-29 analytics** | Emits `sync_completed`, `sync_failed`, `sync_conflict_resolved` events with counts. |
| **BE-48 observability** | Each sync error becomes a Sentry breadcrumb with the idempotency key. Correlation ID flows from device → server → trace. |
| **BE-47 feature flags** | Kill-switch flag `sync.enabled=false` stops all flushing; banner shows "Sync paused for maintenance". |

## Accessibility & Platform Variants

### Accessibility
- `SyncIndicator` exposes `Semantics(label: 'Sync status: <state-name>; <count> items')` and updates as `liveRegion: true` so screen readers announce transitions.
- `SyncBanner` is `liveRegion: true`; transitions are announced once per state change (debounced).
- Conflict toast: `Semantics(liveRegion: true)` with the full conflict message; `Details` action is reachable via TalkBack/VoiceOver.
- `SyncQueueRow` exposes status as part of its semantics label, so an assistive user understands `"failed: 3 attempts; rate limited"` without seeing the icon.

### Reduced motion
- Indicator pulse on `SyncError` is replaced by a 1.0 → 0.6 opacity crossfade.
- Spinner on `SyncRunning` is replaced by a static "syncing…" label that updates progress numerically every 250ms.

### Android specifics
- Doze + battery saver: outbound flushes piggy-back on existing app-foreground events. We never schedule background sync via WorkManager in v1; that's a future phase.
- Network type detection (`connectivity_plus`): on metered cellular we still sync but throttle bulk batch from 50 → 25 to reduce single-burst data cost.

### iOS specifics
- iOS NWPathMonitor used via `connectivity_plus`. Quirk: iOS reports "online" while DNS is still resolving; we additionally probe `/api/v1/health` with a 2s timeout before claiming online.
- iOS Background App Refresh disabled by default; sync runs only while app is foregrounded or briefly on resume.

### Tablet
- Sync queue screen on tablets uses a master-detail layout (queue list left, item detail right).

### Low-end devices
- Max in-flight requests drops from 4 → 2 on `MotionProfile.lowEndAuto` devices to avoid radio contention with rendering.

## Testing

### Widget tests
- `SyncIndicator` renders correct color/icon for each state.
- `SyncBanner` auto-dismisses after `SyncIdle` for `idleAutoHideMs`.
- `optimistic()` rolls back local state when remote throws.
- Idempotency key persists across app kill (Drift round-trip).
- Conflict toast appears once per conflict — duplicates suppressed.

### Golden tests
- 4 indicator states × light/dark = 8 frames.
- Sync queue screen: empty / queued / mixed / all-failed = 4 frames.

### Integration tests
- `offline_sync_flow_test.dart`:
  1. Online → 5 saves succeed without queueing.
  2. Toggle airplane mode → 10 saves enqueue → indicator shows `Queued(10)`.
  3. Restore network → indicator transitions to `Running` → `Idle` within 30s.
  4. All 10 rows acknowledged in Drift.
- `kill_during_sync_test.dart`: flush 30 items, kill app at 50% complete; cold-start; remaining 15 items flush (idempotency keys reused).
- `conflict_test.dart`: server returns `resolution: server_wins` on `subscriptions.tier`; local Drift updates to server value; toast fires once.
- `quota_at_sync_test.dart`: server returns 429 on item #51 of a 100-batch; row marked `blocked`, upgrade prompt deep-linked.

### Perf benchmarks
- 200-item flush on 4G: completes in ≤ 8s on Pixel 4a.
- 200-item flush on 2G simulated (250kbps, 600ms RTT): completes in ≤ 90s without dropping frames in the rendering thread.
- Indicator state-update repaint cost: ≤ 1ms per change (DevTools timeline).

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Online: a save call returns < 600ms; no enqueue happens; sync indicator stays `Idle` |
| T2 | Offline: 10 mutations enqueue; indicator shows `Queued(10)` within 200ms |
| T3 | Restore connectivity: queue flushes within 30s; indicator transitions through `Running` → `Idle` |
| T4 | Kill app mid-flush: cold start resumes; idempotency keys are reused (no duplicate writes server-side) |
| T5 | Pull-to-refresh: triggers flush *first*, then fetches `/sync/changes`; user sees combined progress |
| T6 | Server returns 409 on duplicate-key-different-payload: row goes to `failed`, queue screen shows reason "payload mismatch" |
| T7 | Server returns server-wins on `subscriptions.tier`: ConflictToast fires once; deep link to queue screen works |
| T8 | Server returns 429 on a queued scan: row becomes `blocked`; tapping opens the upgrade prompt sheet |
| T9 | Sync queue screen lists every pending item with table family, age, attempt count, status |
| T10 | "Retry now" on a failed row reschedules immediately; "Drop" removes it from queue and shows undo SnackBar |
| T11 | Concurrency: 4 in-flight requests max — verified by inspecting Dio adapter with synthetic 2s server latency |
| T12 | Idempotency key entropy: 1000 newly-generated keys in test all unique |
| T13 | Reduced motion on: indicator pulse replaced by opacity crossfade |
| T14 | TalkBack reads sync state changes via `liveRegion`; conflict toast announced once |
| T15 | Cold start with 5000+ items in queue: app shows `Queued(5000+)`, archives oldest 1000 to `sync_queue_archive`, banner explains the archive |

### Q&A Questions (8)

1. We ban silent server overwrites for critical fields and surface a toast. What's the threshold for non-critical fields where silent write is acceptable, and who decides per-field?
2. Idempotency keys live on the device. If a user uninstalls the app mid-flush, the keys are lost; the server may still receive the same writes from a manual retry. Is that a real risk, and what's the mitigation?
3. Maximum 4 in-flight requests was chosen for radio efficiency. On a Wi-Fi-only test fleet, we measured 8 in-flight as faster. Why not parameterize by network type?
4. Pull-to-refresh flushes the queue first. If the queue has 500 items, the user pulls and waits 30s before the new data arrives. Is the UX correct, or should we fetch + flush in parallel and reconcile?
5. Conflict resolution on `subscriptions.tier` happens silently in BE-44 (server wins always). The toast is a UX layer. What if the user disagrees with the server's resolution — is there an appeal path?
6. Sync queue archive at 5000 items: what happens to those archived rows? Do they retry forever, or is there a TTL?
7. Lamport clock vs server timestamp — how do we reconcile clock skew when a user has set their phone clock 2 hours fast deliberately?
8. The "Drop" affordance on a failed sync row deletes it permanently from device. What's the rollback if a user accidentally drops a critical mutation, and how is that paired with audit/observability?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 95% on `lib/sync/**`; integration tests green on real device with toggled airplane mode.
- [ ] Developer: 8 Q&A answered.
- [ ] Reviewer: ran a 200-mutation offline → online cycle on Pixel 4a (4G + Wi-Fi).
- [ ] Reviewer: confirmed no silent overwrites — every server-wins event surfaces a toast.
- [ ] Designer: indicator states reviewed against Figma; banner copy approved in all 6 locales.
- [ ] Accessibility reviewer: TalkBack + VoiceOver pass on indicator, banner, queue screen.

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________
**Accessibility Reviewer Signature**: ___________________________

---
**END OF FE-36 — DO NOT PROCEED WITHOUT APPROVAL**
