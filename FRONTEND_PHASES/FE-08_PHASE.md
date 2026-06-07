# Phase FE-08: Local DB (Drift) + Offline-First

## Phase Metadata
- **Phase ID**: FE-08
- **Section**: Layer 1 — Foundation
- **Depends On**: FE-06 (API client + offline queue gateway), FE-07 (auth state)
- **Blocks**: FE-17+ (every feature that reads/writes data), FE-36 (sync UI)
- **Estimated Duration**: 4-5 days
- **Complexity**: High

## Goal
Stand up the on-device data layer using Drift 2.18 (sqflite/sqlite3). Mirror the server's user-scoped tables for everything the app reads/writes daily — products (cache), scans (history), saved products, expiry items, allergen profiles, family members, recall alerts, shopping list, OHS snapshots — and ship a robust **sync queue** that backs FE-06's offline gateway. Conflict resolution hooks line up with BE-44's Lamport-clock policy: server-side fields win for security-sensitive data, client wins on user-authored content within a 5-minute window, otherwise newest write wins.

By the end of this phase, the app works in airplane mode for everything except OTP / payments. Data flows: write goes to Drift first, sync worker pushes to backend, server response reconciles back. Reads come from Drift (reactive `Stream<List<…>>`) so screens update without explicit refresh.

## Why This Phase Matters
- **Indian retail = unreliable internet.** Tier-2/3 cities, basement aisles, transit travel — the app must keep working. Offline-first is product, not polish.
- **Reactive streams from Drift** turn every screen into a live view: a scan committed in scanner → calendar updates instantly without manual refresh.
- **A documented conflict policy** prevents silent data loss the moment two devices in a family edit the same shopping list.
- **The sync queue is the bridge** between FE-06 (offline gateway) and BE-44 (server idempotency). Both ends are useless without this.
- **Reactive UI without polling** is a battery / data win — important for the 50% of users on metered plans.

## Prerequisites
- [ ] Backend: BE-44 (sync + idempotency), BE-37/38/39/55 (data the client mirrors).
- [ ] Earlier FE: FE-06, FE-07.
- [ ] Schema: server schema notes from BE-09/BE-10/BE-37 etc. (we mirror, don't invent).
- [ ] Storage budget: target ≤ 80 MB after 6 months of typical usage; eviction rules built-in.

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/db/radha_database.dart` | Drift database root |
| `apps/mobile/lib/db/tables/products_cache.dart` | Cached product details |
| `apps/mobile/lib/db/tables/scans.dart` | Local scan history |
| `apps/mobile/lib/db/tables/saved_products.dart` | "Saved" list |
| `apps/mobile/lib/db/tables/expiry_items.dart` | Calendar items |
| `apps/mobile/lib/db/tables/allergen_profiles.dart` | per family member |
| `apps/mobile/lib/db/tables/family_members.dart` | mirror |
| `apps/mobile/lib/db/tables/recall_alerts.dart` | inbox + read state |
| `apps/mobile/lib/db/tables/shopping_list_items.dart` | mirror |
| `apps/mobile/lib/db/tables/ohs_snapshots.dart` | business |
| `apps/mobile/lib/db/tables/sync_queue.dart` | outbox table |
| `apps/mobile/lib/db/tables/sync_pull_cursors.dart` | last-pulled-at per resource |
| `apps/mobile/lib/db/tables/conflict_log.dart` | for FE-36 UX |
| `apps/mobile/lib/db/dao/*.dart` | one DAO per domain |
| `apps/mobile/lib/db/migrations/m1_initial.dart` | schema v1 |
| `apps/mobile/lib/sync/sync_engine.dart` | push + pull orchestration |
| `apps/mobile/lib/sync/sync_worker.dart` | runs on connectivity-up + scheduled |
| `apps/mobile/lib/sync/conflict_resolver.dart` | implements policy |
| `apps/mobile/lib/sync/lamport_clock.dart` | client-side clock |
| `apps/mobile/lib/sync/offline_queue_gateway_impl.dart` | concrete impl of FE-06 interface |
| `apps/mobile/lib/sync/sync_status_provider.dart` | Riverpod for FE-36 banner |
| `apps/mobile/lib/db/encryption/sqlcipher_init.dart` | optional encryption setup |
| `apps/mobile/lib/db/eviction/cache_evictor.dart` | LRU eviction for products_cache |
| `apps/mobile/test/db/migration_test.dart` | schema migration |
| `apps/mobile/test/sync/conflict_resolver_test.dart` | conflict policy |
| `apps/mobile/test/sync/sync_engine_test.dart` | push/pull |
| `apps/mobile/integration_test/offline_to_online_test.dart` | end-to-end |

## Schema Sketch (Drift DSL)

```dart
// db/tables/sync_queue.dart
class SyncQueue extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();                 // owner
  TextColumn get tenantId => text().nullable()();    // for business writes
  TextColumn get resource => text()();               // 'scan', 'saved_product', 'shopping_list_item'...
  TextColumn get operation => text()();              // 'create' | 'update' | 'delete'
  TextColumn get idempotencyKey => text()();          // sent in header
  TextColumn get path => text()();                   // '/api/v1/scans'
  TextColumn get method => text()();                 // POST/PATCH/DELETE
  TextColumn get bodyJson => text()();               // serialized
  IntColumn get attempt => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  IntColumn get lamportTs => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get nextAttemptAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending | inflight | failed | done
  @override
  Set<Column> get primaryKey => {id};
}
```

```dart
// db/tables/saved_products.dart
class SavedProducts extends Table {
  TextColumn get id => text()();             // server id when synced; client uuid before
  TextColumn get userId => text()();
  TextColumn get ean => text()();
  TextColumn get nickname => text().nullable()();
  DateTimeColumn get savedAt => dateTime()();
  IntColumn get lamportTs => integer()();
  TextColumn get serverEtag => text().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<Set<Column>> get uniqueKeys => [{userId, ean}];
}
```

Pattern repeats: `lamportTs`, `serverEtag`, `isDirty`, `isDeleted` on every mirrored table.

## Lamport Clock

```dart
class LamportClock {
  int _local = 0;
  int tick() => ++_local;
  int observe(int remote) => _local = max(_local, remote) + 1;
  int peek() => _local;
}
```

Persisted to `sync_pull_cursors` so the clock survives app restart.

## Conflict Resolver

```dart
enum ConflictRule { serverWins, clientWins, latestWins, merge }

class ConflictResolver {
  Future<MergedRow> resolve({
    required ResourceKind kind,
    required Map<String,dynamic> local,
    required Map<String,dynamic> remote,
    required int localLamport,
    required int remoteLamport,
  }) async {
    final rule = _rulesFor(kind);
    switch (rule) {
      case ConflictRule.serverWins:
        return MergedRow(remote, source: 'server');
      case ConflictRule.clientWins:
        return MergedRow(local, source: 'client');
      case ConflictRule.latestWins:
        return MergedRow(localLamport > remoteLamport ? local : remote,
                         source: localLamport > remoteLamport ? 'client' : 'server');
      case ConflictRule.merge:
        // Field-level: arrays union, scalars latest-wins
        return _merge(local, remote, localLamport, remoteLamport);
    }
  }
  ConflictRule _rulesFor(ResourceKind k) => switch (k) {
    ResourceKind.subscriptionTier => ConflictRule.serverWins,
    ResourceKind.role => ConflictRule.serverWins,
    ResourceKind.emailVerified => ConflictRule.serverWins,
    ResourceKind.savedProduct => ConflictRule.latestWins,
    ResourceKind.shoppingListItem => ConflictRule.merge,
    ResourceKind.allergenProfile => ConflictRule.latestWins,
    ResourceKind.scan => ConflictRule.clientWins, // scan is client-authored
    _ => ConflictRule.latestWins,
  };
}
```

Conflict events written to `conflict_log` so FE-36 can surface a banner "Resolved 3 conflicts" with history.

## Sync Engine

```dart
class SyncEngine {
  final RadhaDatabase db;
  final RadhaApiClient api;
  final ConflictResolver resolver;

  Future<void> runOnce() async {
    await _push(); // Drain queue
    await _pull(); // For each resource, GET ?since=<cursor>
  }

  Future<void> _push() async {
    final pending = await db.syncQueue.pendingNextAttempt();
    for (final row in pending) {
      await db.syncQueue.markInflight(row.id);
      try {
        final res = await api.dio.request(row.path,
          options: Options(method: row.method, headers: {'Idempotency-Key': row.idempotencyKey}),
          data: jsonDecode(row.bodyJson),
        );
        await _applyServerResponse(row, res.data);
        await db.syncQueue.markDone(row.id);
      } on DioException catch (e) {
        final err = ErrorMapper.fromDio(e);
        if (err is _Conflict) {
          await _resolveConflict(row, err);
          await db.syncQueue.markDone(row.id);
        } else if (err is _RateLimited) {
          await db.syncQueue.scheduleRetry(row.id, after: err.retryAfter);
        } else if (err is _NetworkUnavailable) {
          await db.syncQueue.scheduleRetry(row.id, after: const Duration(seconds: 30));
        } else {
          await db.syncQueue.markFailed(row.id, err);
        }
      }
    }
  }

  Future<void> _pull() async {
    for (final r in _resources) {
      final cursor = await db.cursors.get(r);
      final res = await api.dio.get('/api/v1/sync/${r.path}', queryParameters: {
        if (cursor != null) 'since': cursor.toIso8601String(),
        'lamport': lamport.peek(),
      });
      for (final row in res.data['rows']) {
        await _applyPulledRow(r, row);
      }
      await db.cursors.set(r, DateTime.parse(res.data['serverNow']));
    }
  }
}
```

## Sync Worker

```dart
class SyncWorker {
  final SyncEngine engine;
  StreamSubscription? _connectivitySub;
  Timer? _periodic;

  void start() {
    // Run on connectivity restore
    _connectivitySub = ref.read(connectivityProvider.stream).listen((online) {
      if (online) engine.runOnce();
    });
    // Periodic catch-up every 60s while foregrounded
    _periodic = Timer.periodic(const Duration(seconds: 60), (_) {
      if (ref.read(appLifecycleProvider) == AppLifecycleState.resumed) engine.runOnce();
    });
    // Immediate on start
    engine.runOnce();
  }
}
```

Background-mode sync uses Workmanager (Android) and BGTaskScheduler (iOS) — opt-in by user, deferred to FE-36 polish.

## Reactive Reads

```dart
class SavedProductsDao {
  Stream<List<SavedProduct>> watchAllForUser(String userId) =>
      (db.select(db.savedProducts)
        ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
        .watch();
}
```

Screens use:
```dart
final stream = ref.watch(savedProductsStreamProvider);
return stream.when(
  data: (rows) => SavedProductsList(rows),
  loading: () => RadhaSkeleton.savedList(),
  error: (e, _) => ErrorState(error: e),
);
```

A new scan committed → DAO writes → stream emits → list re-renders. No manual refresh.

## Eviction

`products_cache` accumulates as users scan — a heavy user can hit thousands of rows. Evict LRU rows older than 90 days OR when cache exceeds 30 MB.

```dart
class CacheEvictor {
  Future<void> evictIfNeeded() async {
    final size = await db.products.cacheSizeBytes();
    if (size < 30 * 1024 * 1024) return;
    await db.products.deleteOldestUntilUnder(20 * 1024 * 1024);
  }
}
```

Runs on app resume + after every 100 cache writes.

## Encryption (optional, gated by feature flag)

For business-mode users handling supplier data, an opt-in setting enables SQLCipher with a key derived from `flutter_secure_storage`. Default OFF in v1 to keep startup quick on low-end devices; covered in FE-40 release prep.

## Visual Behaviour (Sync diagnostics screen — dev-only)

| State | Visual |
|---|---|
| **Idle (online, queue empty)** | Green status pill "Synced · just now". |
| **Pushing (queue: 3 items)** | Pill turns brand-color "Syncing 3 items…" with progress arc. |
| **Pulling** | "Updating from server" + Lottie spinner small. |
| **Offline** | Pill turns warning "Offline · 5 pending" (count from `sync_queue`). |
| **Conflict resolved** | Snackbar "Resolved 1 conflict — server kept newer change" + light haptic. |
| **Sync error (5xx)** | Pill warning "Sync paused · retry in 30 s" + spinner; retry runs automatically. |
| **Sync forbidden (401)** | Pill error "Sign in to sync" + tappable to OTP route. |
| **Cache evicted** | Toast bottom "Cleared old cache (15 MB recovered)". |
| **Tap pill** | Opens detail bottom sheet showing queue rows: resource, operation, last error, attempt count. |
| **Long-press pill** | Force-sync menu: "Run now", "Wipe queue", "Reset cursors" (dev only). |

## Animations
- **Pill state changes**: 200 ms `motion.normal` color + width tween via `AnimatedContainer`.
- **Sync progress arc**: indeterminate `CircularProgressIndicator` 24 dp.
- **Conflict snackbar**: 240 ms `motion.slow` slide-up.
- **Queue chip count change**: 200 ms scale-bump 0.95 → 1.05 → 1.0.
- **Bottom sheet rows**: 60 ms stagger with cap 8 (per FE-04 rule).

## Accessibility
- Pill announces state plus count: "Sync status: synced. 0 pending."
- Bottom sheet rows announced as "Sync item: scan create, attempt 1 of 3, queued at 09:14."
- Conflict log surfaces an accessible announcement on resolution.
- All semantics labels respect locale (English first; localized in FE-35).

## Testing
- **Migration test**: schema v1 boots clean; v1 → v1 idempotent.
- **DAO tests**: each DAO writes/reads/streams correctly; reactive stream emits on insert.
- **Sync engine push**: queue with 3 rows → 3 API calls in correct order with idempotency keys; success marks done.
- **Sync engine push (conflict)**: 409 from server triggers `ConflictResolver`; conflict_log gets an entry; queue marked done.
- **Sync engine pull**: server returns rows + `serverNow` cursor; cursor saved; rows applied with lamport reconcile.
- **Conflict resolver**: 12 cases covering serverWins, clientWins, latestWins, merge; each rule mapped per resource kind.
- **Lamport clock**: `tick()` monotonic; `observe(remote)` advances to `max+1`.
- **Eviction**: insert 5000 cache rows of 8 KB each (40 MB) → evictor brings cache to ≤ 20 MB.
- **Worker**: connectivity false → online: `engine.runOnce` called once.
- **Worker**: foregrounded > 60 s with no network change: periodic timer fires.
- **Integration (offline → online)**:
  1. Go offline.
  2. Submit 3 scans, save 2 products.
  3. Drift has 5 rows; sync_queue has 5.
  4. Go online → engine drains; queue empty in ≤ 8 s; backend has all 5.
- **Integration (race)**: same EAN saved twice in 200 ms while offline → de-dup via unique key, sync queue has 1 row.
- **Performance**: bulk insert 1000 scans in ≤ 2 s; reactive stream emits ≤ 50 ms after each insert.

## Risk Assessment
| Risk | Likelihood | Mitigation |
|---|---|---|
| sqflite blocking UI thread on big writes | High | Drift uses isolate-backed worker (`drift/native.dart` with `IsolateNativeDatabase`); long writes in background. |
| Schema migration corrupts user DB | High | Migration tests for each version step; backup-restore tool ships in dev menu; production migrations are wrapped in transactions. |
| Conflict policy disagrees with backend | High | Policy table reviewed jointly with BE-44 owner; integration tests run real backend in CI nightly. |
| Sync queue grows unbounded if server perma-fails | Medium | After 10 failed attempts, mark `failed`, surface to UI; user can wipe. |
| Idempotency key reused after server commit but before client knows | Medium | BE-44 caches keys 24 h; client retries within 24 h hit cache safely. |
| Reactive stream re-emits cause UI thrashing | Medium | DAOs use `distinct()`; selectors use `Selector` to scope rebuild. |
| Drift codegen stale | Medium | `build_runner` runs in CI; PR fails on diff. |
| User changes account → old data leaks into new session | Critical | `wipeUserData()` on logout; re-keyed DB on user switch (rare flow). |

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Schema migration runs on a fresh device DB without error. |
| T2 | Inserting a saved-product reactively emits to `watchAllForUser` within 50 ms. |
| T3 | Going offline + saving 3 products + going online → backend has all 3 with correct idempotency keys. |
| T4 | A 409 from backend on push triggers a conflict_log entry; queue marked done; UI shows resolved-conflict snackbar. |
| T5 | Lamport clock survives app kill: peek() after restart equals last persisted value. |
| T6 | Sync pull with `since=<cursor>` updates cursor to server's `serverNow` after success. |
| T7 | Cache evictor brings products_cache below 20 MB after exceeding 30 MB threshold. |
| T8 | After logout, `saved_products` table has 0 rows. |
| T9 | 1000-row bulk insert finishes in ≤ 2 s on Pixel 4a. |
| T10 | Reactive stream survives a Drift transaction rollback (no spurious emit on rollback). |
| T11 | Sync queue prefers older `created_at` first (FIFO) when running push. |
| T12 | Same EAN saved twice while offline produces a single sync_queue row (unique constraint). |
| T13 | Conflict resolver returns `serverWins` for `subscriptionTier` even when local lamport is newer. |
| T14 | Worker triggers on `connectivityProvider` flipping to true, but not on subsequent `true` re-emits. |
| T15 | After 10 consecutive failed attempts, queue row is marked `failed` and visible in dev sync screen. |

### Q&A Questions (8)

1. Why mirror server tables on device instead of caching only what the user opened? What's the storage budget rationale?
2. How does a Drift reactive stream interact with Riverpod — what's the bridge widget?
3. Why is `subscriptionTier` `serverWins` while `savedProduct` is `latestWins`? Where is this policy documented?
4. How do we reset cursors when a backend resource changes shape (e.g. BE-37 v3)?
5. What's the queue TTL — how long do we hold a queued mutation before declaring it dead?
6. How does sync coexist with FE-22's SSE stream (long-running connection)?
7. What's the upgrade path for SQLCipher if we enable it later — does the unencrypted DB migrate?
8. Why a FIFO queue vs prioritization (e.g. recall ack should fly first)? When would we add priority?

## Sign-off Gate
- [ ] Developer: 15 tests pass.
- [ ] Developer: 8 Q&A answered in handoff.
- [ ] Developer: Conflict policy table signed off by BE-44 owner.
- [ ] Reviewer: Audited `wipeUserData()` SQL — no orphan tables left.
- [ ] Reviewer: Confirmed Drift workers run off main thread (verified by `dart:isolate` trace).
- [ ] Reviewer: Confirmed reactive UI binding doesn't thrash on bulk insert (DevTools timeline ≤ 5 frame builds for 100 inserts).

**Developer Signature**: ___________________________

**☐ APPROVED — Layer 1 Foundation Complete**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF FE-08 — Layer 1 Foundation phases (FE-01..FE-08) complete; proceed to Layer 2 onboarding (FE-09)**
