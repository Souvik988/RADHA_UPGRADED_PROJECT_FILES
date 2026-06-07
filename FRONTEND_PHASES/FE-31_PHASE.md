# Phase FE-31: Tasks Inbox + Detail + Complete

## Phase Metadata
- **Phase ID**: FE-31
- **Phase Name**: Tasks Inbox + Detail + Complete
- **Section**: Frontend Execution — Business + Owner (Layer 4)
- **Depends On**: FE-04 (motion tokens), FE-05 (GoRouter + deep links), FE-06 (API client + retry), FE-07 (Riverpod auth + role provider), FE-08 (Drift offline outbox), FE-30 (some tasks act on inventory items — recount, restock, mark-damaged), BE-19 (`GET /api/v1/tasks?status=`, `POST /api/v1/tasks`, `GET /api/v1/tasks/{id}`, `PATCH /api/v1/tasks/{id}/assign`, `PATCH /api/v1/tasks/{id}/status`, `POST /api/v1/tasks/{id}/complete`), BE-31 (S3 presigned upload for evidence photos), BE-24 (FCM push lands on this phase via deep link)
- **Blocks**: FE-32 (reports include task completion stats: assigned-to-completed median, overdue %, evidence coverage %)
- **Estimated Duration**: 3–4 days
- **Complexity**: Medium

## Goal
Tasks are the daily handle a manager uses to run the store and the to-do board a staff member opens first thing in the morning. FE-31 ships the **three-filter inbox** (My Tasks · All · Completed), a **detail screen** with status transitions and evidence upload, and a manager-only **Create task** sheet gated on role. A push notification (BE-24) about a new assignment deep-links straight to the detail screen — no app-shell hop, no lost context.

The flow is tight: tap a task on the inbox → status transitions in two taps (`pending → in_progress → completed`) → evidence photo uploaded via S3 presigned URL while the user is still on the screen → completion posts → row strikes through and shifts to Completed. Evidence upload runs in parallel with status changes; a slow upload never blocks a completion.

## Why This Phase Matters
- **The single screen managers and staff share daily.** Onboarding (FE-10..FE-16) gets a user once. The dashboard (FE-25) is glanceable. Tasks is where the day actually happens — every staff member's first open is the inbox, every manager's last close is "what got missed."
- **Time savings** — paper task lists average 8 minutes per shift just to reconcile. With deep-linkable, evidence-attached tasks, the manager skips the recap. ~₹100/day saved on a 6-staff store.
- **Compliance evidence**: a "clean refrigerator at 2 PM" task with a timestamped photo is the difference between "we promised we did it" and "here is the proof." Auditors love this.
- **Push-driven retention**: a task assignment that lands as a push notification and deep-links straight to the detail screen earns a ~22% same-day completion rate vs. ~9% for tasks discovered passively. Deep linking is the multiplier.
- **Permissions awareness**: evidence upload requests both camera and photo-library permissions — re-checked at the moment the user taps "Add evidence," not cached. Camera-denied users still see the photo-library path; both-denied users see a non-blocking advisory and can complete without evidence (server tracks `evidence_provided: false`).

## Prerequisites
- [ ] Backend: `GET /api/v1/tasks?status=pending|in_progress|completed&assignee=me|all&storeId=&cursor=` (BE-19)
- [ ] Backend: `POST /api/v1/tasks` body `{ title, description?, assigneeId, dueAt, type, refs?: { ean?, inventoryItemId? } }` → `{ id, ... }` (BE-19, manager-gated)
- [ ] Backend: `GET /api/v1/tasks/{id}` → full task + audit trail (BE-19)
- [ ] Backend: `PATCH /api/v1/tasks/{id}/assign` body `{ assigneeId }` (BE-19)
- [ ] Backend: `PATCH /api/v1/tasks/{id}/status` body `{ status: 'in_progress' | 'paused' | 'cancelled' }` (BE-19)
- [ ] Backend: `POST /api/v1/tasks/{id}/complete` body `{ evidenceMediaIds: string[], notes? }` (BE-19)
- [ ] Backend: `POST /api/v1/media/presign` body `{ kind: 'task_evidence', taskId, contentType }` → `{ uploadUrl, mediaId, fields }` (BE-31)
- [ ] FE-05 GoRouter route `/business/tasks/:taskId` registered with deep-link host `radha://task/{id}` and `https://app.radha.app/task/{id}`
- [ ] FE-08 Drift outbox table `task_outbox` for offline status changes and evidence linkages
- [ ] Lottie pack additions:
  - `task_complete_success.json` — 1100ms one-shot, ≤ 78 KB
  - `evidence_upload_progress.json` — 1.4s loop, ≤ 22 KB (drives the upload progress indicator)
- [ ] FCM payload contract: `{ kind: 'task_assigned', taskId, dueAt, title }` already shipped by FE-21/BE-24

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/business/tasks/tasks_inbox_screen.dart` | Three-filter inbox host (My / All / Completed) |
| `apps/mobile/lib/features/business/tasks/task_detail_screen.dart` | Detail with status timeline + evidence + complete CTA |
| `apps/mobile/lib/features/business/tasks/create_task_sheet.dart` | Manager-only create sheet (role-gated by server probe) |
| `apps/mobile/lib/features/business/tasks/tasks_controller.dart` | Riverpod inbox `Notifier<TasksInboxState>` |
| `apps/mobile/lib/features/business/tasks/task_detail_controller.dart` | Riverpod detail `Notifier<TaskDetailState>` |
| `apps/mobile/lib/features/business/tasks/tasks_state.dart` | Sealed states + filter enum + status enum |
| `apps/mobile/lib/features/business/tasks/data/tasks_repository.dart` | Wraps BE-19 |
| `apps/mobile/lib/features/business/tasks/data/evidence_uploader.dart` | Wraps BE-31 presign + S3 PUT with progress |
| `apps/mobile/lib/features/business/tasks/data/task_outbox.dart` | Drift outbox + replay |
| `apps/mobile/lib/features/business/tasks/widgets/filter_segmented.dart` | My / All / Completed segmented control |
| `apps/mobile/lib/features/business/tasks/widgets/task_row.dart` | Inbox tile (title, due chip, assignee avatar, status dot) |
| `apps/mobile/lib/features/business/tasks/widgets/due_chip.dart` | Today / Tomorrow / Overdue / Date pill |
| `apps/mobile/lib/features/business/tasks/widgets/status_timeline.dart` | Vertical timeline of status transitions |
| `apps/mobile/lib/features/business/tasks/widgets/evidence_grid.dart` | 3-up grid with upload progress overlays |
| `apps/mobile/lib/features/business/tasks/widgets/evidence_picker_sheet.dart` | Camera / Gallery / Cancel sheet with permission re-check |
| `apps/mobile/lib/features/business/tasks/widgets/complete_button.dart` | Animated CTA: pending → in_progress → completed |
| `apps/mobile/lib/features/business/tasks/widgets/assignee_avatar.dart` | Avatar with status ring |
| `apps/mobile/lib/features/business/tasks/widgets/role_gated.dart` | Wraps Create-task FAB; hides on non-manager + 403-forces re-hide |
| `apps/mobile/test/features/business/tasks/tasks_controller_test.dart` | Unit |
| `apps/mobile/test/features/business/tasks/task_detail_controller_test.dart` | Unit |
| `apps/mobile/test/features/business/tasks/golden/task_states.dart` | Goldens (light + dark + RTL) |
| `apps/mobile/integration_test/tasks_flow_test.dart` | Patrol E2E + push deep-link |

## Screen / Widget Spec

```dart
// tasks_state.dart
enum TaskFilter { mine, all, completed }
enum TaskStatus { pending, inProgress, paused, completed, cancelled }

sealed class TasksInboxState { const TasksInboxState(); }
class TasksLoading extends TasksInboxState { const TasksLoading(); }
class TasksLoaded extends TasksInboxState {
  final TaskFilter filter;
  final List<TaskSummary> items;
  final String? nextCursor;
  final bool refreshing;
  const TasksLoaded({...});
}
class TasksError extends TasksInboxState {
  final String code;
  final TasksLoaded? lastGood;
  const TasksError(this.code, this.lastGood);
}

sealed class TaskDetailState { const TaskDetailState(); }
class TaskDetailLoading extends TaskDetailState { const TaskDetailLoading(); }
class TaskDetailLoaded extends TaskDetailState {
  final Task task;
  final List<EvidenceUpload> uploads;   // includes in-progress
  final TaskStatus optimisticStatus;    // diverges from task.status during transitions
  final bool offlineQueued;
  const TaskDetailLoaded({...});
}
class TaskDetailNotFound extends TaskDetailState { const TaskDetailNotFound(); }

class EvidenceUpload {
  final String localId;
  final double progress;        // 0.0..1.0
  final String? mediaId;        // set after S3 PUT 200
  final String? error;
  final bool fromCamera;
  const EvidenceUpload({...});
}
```

```dart
// tasks_controller.dart
abstract interface class TasksController {
  void switchFilter(TaskFilter filter);
  Future<void> refresh();
  Future<void> loadMore();
  Future<TaskSummary> createTask(CreateTaskInput input); // throws on 403
}

// task_detail_controller.dart
abstract interface class TaskDetailController {
  Future<void> moveToInProgress();
  Future<void> pause();
  Future<void> addEvidenceFromCamera();
  Future<void> addEvidenceFromGallery();
  void cancelEvidenceUpload(String localId);
  Future<void> complete({String? notes});
  Future<void> reassign(String userId);
}
```

```dart
// role_gated.dart
class RoleGated extends ConsumerWidget {
  final Widget child;
  final Set<Role> required; // e.g. {Role.manager, Role.admin}
  const RoleGated({required this.child, required this.required, super.key});
  // Reads from `roleProvider` (FE-07). Hides on local role mismatch.
  // The hidden state is purely cosmetic — server still 403s if a stale role lets the UI render the FAB.
}
```

### `TaskRow`
- 64dp tall. Left: 4dp accent stripe colored by status (`pending` slate, `inProgress` blue, `completed` green, `paused` amber, `cancelled` muted). Center: title (1 line), sub-line "Due {dueChip} · {assigneeName}". Right: `AssigneeAvatar` with status ring.
- Tap: pushes `task_detail_screen.dart` with `Hero(tag: RadhaHero.task(task.id))` from the row to the detail header.
- Long-press (manager only): action sheet — Reassign · Edit · Cancel.
- Swipe right: quick start (`pending → inProgress`).
- Swipe left: snooze 1 hour (local-only flag, surfaces re-fire toast at +1h).

## Visual Behaviour & Interaction States

| # | State | Visual |
|---|---|---|
| 1 | **Inbox loading** | Skeleton rows (5) with shimmer at `motion.normal` cycle; segmented control already interactable |
| 2 | **Inbox loaded — My Tasks** | Rows fade in with `tight` stagger; due chips colored by urgency; manager FAB visible |
| 3 | **Inbox empty (My Tasks)** | "All caught up" illustration + microcopy; manager FAB still visible |
| 4 | **Filter switch** | Segmented control slides to selection (`motion.fast`); list cross-fades (180ms) |
| 5 | **Pull-to-refresh** | Standard rebound at `motion.normal`; success haptic on completion |
| 6 | **Detail loading** | Header placeholder + timeline skeleton |
| 7 | **Detail loaded (pending)** | Title large; due chip prominent; CTA "Start" full-width primary; evidence grid empty |
| 8 | **Detail in_progress** | CTA morphs to "Complete"; status timeline shows pending ✓ → in_progress (current); pause icon button visible |
| 9 | **Evidence picker open** | Bottom sheet (camera / gallery / cancel); permission probe before either action |
| 10 | **Evidence uploading** | Tile in grid shows local thumbnail + Lottie ring + percentage; cancel button overlay; non-blocking — user can still tap Complete |
| 11 | **Evidence upload error** | Tile darkens; error icon; tap to retry |
| 12 | **Complete pressed (online)** | Button collapses to spinner; on 200, full-screen `task_complete_success.json` (1100ms one-shot); detail auto-pops to inbox; row in inbox strikes through and slides to Completed filter (with cross-filter Hero kept silent — single Hero rule) |
| 13 | **Complete pressed (offline)** | Outbox entry created; detail header gets a cloud-off badge; success Lottie still plays (the local truth is "you finished it") |
| 14 | **Detail not found / 404** | Empty state with "This task is gone" and "Back to inbox" CTA |
| 15 | **Push deep-link cold start** | App boots → splash → tasks detail (no inbox flash); back button respects deep-link semantics (pops to inbox, not back to launcher) |
| 16 | **Role demoted on Create** | Server returns 403 on `POST /tasks`; sheet surfaces "Your role no longer allows this"; FAB self-hides on next tick |
| 17 | **Camera + Gallery both denied** | Evidence sheet shows non-blocking advisory; "Continue without evidence" path remains |
| 18 | **Reduced motion** | Lottie success replaced with a static green check; status timeline transitions are instant; row stagger removed |
| 19 | **Dark mode** | Status accent stripes use luminance-mapped tokens; evidence grid background `M3 surfaceContainerHighest` |
| 20 | **RTL** | Segmented control reverses; swipe directions invert (right-swipe = snooze) |
| 21 | **Dynamic type xxLarge** | Filter chips wrap to 2 rows; due chip moves below the title; CTA wraps to two lines |

## Animations

Tasks motion budget is moderate. The two earned moments are completion (success sheet) and the in-progress transition (status timeline pulse). Everything else is muted to keep daily-use fatigue low.

- **Lottie**:
  - `task_complete_success.json` — 1100ms one-shot on `POST /complete` ack (or local optimistic when offline)
  - `evidence_upload_progress.json` — 1.4s loop on each in-flight evidence tile
- **flutter_animate chains**:
  - Inbox row enter: stagger `tight` (28ms), `.fadeIn(motion.fast).slideY(begin: 0.04)`
  - Filter cross-fade: 180ms `swiftOut`
  - Status timeline tick: each row in the timeline `.fadeIn(motion.fast).slideX(begin: 0.04)`
  - Complete button morph: width-tween to circle over 200ms, spinner inside, then expand back as success Lottie unfolds
  - Strike-through on completed row: `.tween` on text decoration over 240ms
  - Pull-to-refresh rebound: `motion.normal` `Curves.easeOutQuint`
- **Hero**: `Hero(tag: RadhaHero.task(taskId))` from inbox row to detail header. Single Hero per route, enforced by FE-33.
- **Custom**: status accent stripe pulses once (1.04× width) when status changes, 240ms `expressive`

## Haptics
- **selection** — filter segmented control, swipe-to-snooze reveal
- **light** — task row tap, evidence tile tap, status pause
- **medium** — task moved to `in_progress`
- **success** — task completion (pattern fires alongside Lottie)
- **warning** — evidence upload error, push deep-link to a 404 task
- **heavy** — role demoted modal on Create (rare)

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `tasks.title` | "Tasks" | "कार्य" | "பணிகள்" | "పనులు" | "কাজ" | "कामे" |
| `tasks.filter.mine` | "Mine" | "मेरे" | "என்னுடைய" | "నావి" | "আমার" | "माझे" |
| `tasks.filter.all` | "All" | "सभी" | "எல்லாம்" | "అన్నీ" | "সব" | "सर्व" |
| `tasks.filter.completed` | "Done" | "पूरे" | "முடிந்தது" | "పూర్తి" | "সম্পন্ন" | "पूर्ण" |
| `tasks.empty.mine` | "All caught up" | "सब पूरा" | "அனைத்தும் முடிந்தது" | "అంతా పూర్తి" | "সব শেষ" | "सर्व पूर्ण" |
| `tasks.due.today` | "Today" | "आज" | "இன்று" | "ఈరోజు" | "আজ" | "आज" |
| `tasks.due.tomorrow` | "Tomorrow" | "कल" | "நாளை" | "రేపు" | "আগামীকাল" | "उद्या" |
| `tasks.due.overdue` | "Overdue" | "देर" | "தாமதம்" | "ఆలస్యం" | "বিলম্বিত" | "उशीर" |
| `tasks.cta.start` | "Start" | "शुरू" | "தொடங்கு" | "ప్రారంభించు" | "শুরু" | "सुरू करा" |
| `tasks.cta.complete` | "Complete" | "पूरा करें" | "முடி" | "పూర్తి చేయి" | "সম্পন্ন" | "पूर्ण करा" |
| `tasks.cta.pause` | "Pause" | "रोकें" | "இடைநிறுத்து" | "పాజ్" | "বিরতি" | "थांबवा" |
| `tasks.evidence.add` | "Add evidence" | "साक्ष्य जोड़ें" | "சாட்சி சேர்" | "సాక్ష్యం జోడించండి" | "প্রমাণ যোগ" | "पुरावा जोडा" |
| `tasks.evidence.camera` | "Camera" | "कैमरा" | "கேமரா" | "కెమెరా" | "ক্যামেরা" | "कॅमेरा" |
| `tasks.evidence.gallery` | "Gallery" | "गैलरी" | "கேலரி" | "గ్యాలరీ" | "গ্যালারি" | "गॅलरी" |
| `tasks.evidence.skip` | "Continue without evidence" | "बिना साक्ष्य" | "சாட்சியின்றி" | "సాక్ష్యం లేకుండా" | "প্রমাণ ছাড়া" | "पुराव्याशिवाय" |
| `tasks.success` | "Task completed" | "कार्य पूरा" | "பணி முடிந்தது" | "పని పూర్తి" | "কাজ সম্পন্ন" | "काम पूर्ण" |
| `tasks.create` | "New task" | "नया कार्य" | "புதிய பணி" | "కొత్త పని" | "নতুন কাজ" | "नवीन काम" |
| `tasks.role.denied` | "Your role no longer allows this" | "आपकी भूमिका अनुमत नहीं" | "உங்கள் பாத்திரம் அனுமதிக்காது" | "మీ పాత్ర అనుమతించదు" | "আপনার ভূমিকা অনুমোদিত নয়" | "तुमची भूमिका परवानगी देत नाही" |

## Backend Integration

- **GET /api/v1/tasks** query `status, assignee, storeId, cursor` → cursor page of `TaskSummary`. Cached in Drift for offline replay; cache key `(filter, storeId)`.
- **POST /api/v1/tasks** (manager-only). UI calls with role probe; on 403 the FAB self-hides.
- **GET /api/v1/tasks/{id}** → full task + transition audit trail. Cached for offline read; `If-None-Match` ETag handled.
- **PATCH /api/v1/tasks/{id}/assign** → reassign sheet (manager-only).
- **PATCH /api/v1/tasks/{id}/status** → status changes (`pending → inProgress → paused → inProgress`). Optimistic UI keeps `optimisticStatus` until ack.
- **POST /api/v1/tasks/{id}/complete** body `{ evidenceMediaIds, notes? }` → `200 { task }`. The response carries the canonical timestamps that overwrite optimistic ones.
- **POST /api/v1/media/presign** body `{ kind: 'task_evidence', taskId, contentType }` → `{ uploadUrl, mediaId, fields }`. The UI does the S3 PUT directly with progress; on 200 the `mediaId` is local-state-attached. The completion call references it.

### Idempotency
Status changes use `Idempotency-Key: task-status-{taskId}-{attemptUuid}`; completion uses `task-complete-{taskId}-{attemptUuid}`. Replays return the canonical task without double-emitting audit rows.

### Deep linking (FE-05 + this phase)
GoRouter route `/business/tasks/:taskId` is registered with both `radha://` and `https://` host families. The push payload from BE-24 is `{ kind: 'task_assigned', taskId, dueAt, title }`; the FE-21/FE-36 router-level handler parses it and pushes the route. On cold start, the splash → detail handoff bypasses the inbox flash by using `pushReplacement` from the boot sequence — verified by integration test.

A 404 deep-link (e.g., the task was cancelled before the push fired) lands on the `TaskDetailNotFound` state with a "Back to inbox" CTA, not on a generic error page.

### Permissions (re-check, never cached)
The evidence picker re-checks `Permission.camera.status` and `Permission.photos.status` (or `Permission.storage` on Android pre-13) at the moment of the tap, every time:

```dart
Future<void> addEvidenceFromCamera() async {
  final status = await Permission.camera.request();
  if (status.isPermanentlyDenied) {
    await _showRationaleSheet(); // FE-17 sheet, "Open settings" deep-link
    return;
  }
  if (!status.isGranted) return;
  // ...launch camera, presign, PUT, link mediaId.
}
```

Both-denied users see the non-blocking advisory and can still complete; the server records `evidence_provided: false` for reporting.

### Evidence upload flow
1. User picks an image. UI creates `EvidenceUpload(localId, progress: 0)` and renders a tile.
2. UI calls `POST /api/v1/media/presign` → `{ uploadUrl, mediaId, fields }`.
3. UI does an S3 PUT with `Dio` `onSendProgress`; the tile's Lottie ring tracks the progress.
4. On 200, `mediaId` is attached to the upload entry. On error, the tile shows a retry icon.
5. `complete()` collects `mediaId`s for all 200-state uploads and posts `POST /api/v1/tasks/{id}/complete`.

A slow upload never blocks completion. If the user taps Complete before all uploads finish, the UI surfaces a 200ms confirmation: "Two uploads still pending — complete now and they'll attach when done?" If confirmed, completion proceeds without those `mediaId`s; the still-running uploads land via a follow-up `PATCH /tasks/{id}/evidence` after they resolve. (BE-19 supports post-completion evidence attach within 24h.)

### Error code → UI mapping
| HTTP | Error code | UI |
|---|---|---|
| 200 | — | success Lottie + strike-through + filter shift |
| 400 | `validation_error` | inline form error in Create sheet |
| 401 | `unauthorized` | force `/login` |
| 403 | `not_in_role` | role-demoted modal on Create; FAB self-hides on next provider tick |
| 404 | `task_not_found` | `TaskDetailNotFound` empty state |
| 409 | `status_conflict` | refresh task and re-show CTA |
| 410 | `task_cancelled` | banner "Cancelled — you can't complete this" |
| 413 | `evidence_too_large` | inline tile error "Try a smaller photo" |
| 429 | `rate_limited` | toast; CTA disabled 30s |
| 5xx / network | — | offline outbox path; success Lottie still plays |

## Charts & Data Viz
The detail screen status timeline doubles as a chart: each transition is a row with timestamp + actor + status icon. No separate chart widget. Long-press on the timeline reveals raw timestamps in tooltips.

The inbox header shows a small **today / overdue** counter strip (e.g., "3 due today · 1 overdue") rendered as text-only — no chart — to keep cold-start weight low.

## Accessibility
- Filter segmented control: `Semantics(button: true, selected: ...)` per option; announces "Mine, 1 of 3, selected"
- Task row: full label "Task: {title}, due {humanizedDue}, assigned to {name}, status {status}"
- Status timeline: ordered list with `Semantics(label: 'Step {n}: {status} at {time}')`
- Complete button: announces "Complete task. Double-tap to mark complete"
- Evidence tile: announces "Photo {n} of {count}, upload {percentage} percent" while in-flight
- Reduced motion: success Lottie replaced with static check; row stagger removed; filter cross-fade replaced with instant switch
- Dynamic type xxLarge: filter chips wrap; CTA wraps to two lines; evidence grid drops to 2-up
- High contrast: status accent stripes use luminance-mapped tokens
- Focus order: app bar back → filter → list → FAB (manager only)
- TalkBack/VoiceOver: success sheet reads "Task completed. Returning to inbox."
- Voice input on Create-task title and notes fields

## Testing

### Unit
- `tasks_controller_test.dart`: filter switch updates state; pagination cursor advances; refresh dedupes by `id`
- `task_detail_controller_test.dart`: optimistic status transitions; rollback on 409; outbox enqueue on offline; evidence upload progress reducer
- `evidence_uploader_test.dart`: S3 PUT respects `onSendProgress`; cancel cleanly aborts; retry resets progress to 0
- Idempotency key uniqueness per attempt

### Widget
- Three-filter inbox renders correct tile count per filter
- Manager-only FAB shows when `roleProvider == manager`, hides when `staff`
- Role probe 403 on Create surfaces the demoted modal and re-hides FAB
- Evidence picker re-checks permission on every entry; permanently-denied path opens rationale sheet
- Both-denied path keeps "Continue without evidence" available
- `CompleteButton` morph animation plays once and not again on rebuild
- Reduced motion: no morph, no Lottie, no stagger
- RTL: segmented control reverses; swipe directions invert

### Golden (light + dark + RTL)
- 9 anchor states × 3 themes × 3 sizes = 81 goldens
  - inbox-loading, inbox-mine-empty, inbox-mine-loaded, inbox-completed, detail-pending, detail-in-progress, detail-uploading, detail-success, detail-not-found

### Integration (Patrol)
- Happy path: tap row → detail → start → add 2 evidence photos → complete → success Lottie → row strike-through in inbox
- Push deep-link cold start: simulated FCM payload → app boots straight to detail (no inbox flash)
- Push deep-link to a 404 task → `TaskDetailNotFound` with "Back to inbox" CTA
- Offline complete: airplane mode → complete → outbox queued → reconnect → server-side audit row appears
- Manager Create with role probe 403 → demoted modal → FAB hides
- Camera permission permanently denied → rationale sheet → settings deep-link
- Evidence upload mid-flight → tap Complete → confirmation sheet → completion succeeds; uploads attach via post-complete PATCH

### Perf
- Pixel 4a release build: filter switch < 60ms paint; detail open < 240ms p95 with cached task; full upload of a 1.2 MB photo to S3 in < 4s on 4G
- 200-row inbox scroll at 60fps (jank rate < 1%)

## Risk Assessment

| Risk | Likelihood | Mitigation |
|---|---|---|
| Push deep-link races the auth bootstrap and lands on `/login` instead of the task | Medium | FE-05 deep-link queue holds the route until `authStateProvider` resolves; integration test simulates cold start with expired token + push payload |
| Evidence upload hangs on flaky 3G and blocks the user from completing | High | Upload is non-blocking; completion CTA available always; post-complete evidence attach window of 24h on the server |
| Role probe is stale and lets a demoted user see the Create FAB | Medium | FAB is cosmetic-only; server is the source of truth; 403 surfaces the demoted modal and triggers a role re-fetch |
| Camera permission cached as granted at app launch but revoked between sessions | Medium | Re-check on every evidence-picker entry; rationale sheet on permanently-denied |
| Optimistic status transition diverges from server canonical state on 409 | Medium | Detail controller refetches task on 409 and re-renders timeline |
| Inbox cache stale after a server-side reassignment lands as push | Low | Push handler invalidates inbox cache for affected `(filter, storeId)` keys |
| Photo too large (12 MP+ with HDR) exceeds S3 PUT size and 413s | Medium | Upload pipeline downscales to 2048px max edge before PUT; integration test forces 12 MP input |
| Completion success Lottie keeps the user on the detail screen for too long | Low | Auto-pop after Lottie completes (1100ms); skip-on-tap leaves immediately |

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Inbox renders three filters; switching from My to All updates the row count and applies `tight` stagger |
| T2 | Push notification with `kind: task_assigned` deep-links straight to the detail screen on cold start, with no inbox flash |
| T3 | Pending → in_progress transition optimistically updates the timeline and the CTA morphs to "Complete" within 80ms |
| T4 | Evidence picker re-checks camera permission on every entry; permanently-denied path opens the rationale sheet, not a black surface |
| T5 | Both camera and photos denied: "Continue without evidence" CTA remains; completion succeeds with `evidence_provided: false` |
| T6 | Mid-flight evidence upload + tap Complete: confirmation sheet appears; completion succeeds; uploads attach via post-complete PATCH within 24h window |
| T7 | Photo > 4 MB downscales to ≤ 2048px max edge before S3 PUT; PUT succeeds in < 4s on simulated 4G |
| T8 | Idempotency replay (same key) on `POST /complete` returns the canonical task without double-emitting an audit row |
| T9 | Offline completion: airplane mode, tap Complete, success Lottie plays, outbox queues; reconnect drains and the server records the audit row |
| T10 | Manager-only Create FAB hides when local role is `staff` and reveals when role flips to `manager` |
| T11 | Role probe 403 on `POST /tasks` surfaces the demoted modal and re-hides the FAB on the next provider tick |
| T12 | 409 status_conflict on a status PATCH refetches the task and re-renders the timeline; no stale optimistic state remains |
| T13 | Reduced motion: no Lottie success, no row stagger, instant filter cross-fade |
| T14 | TalkBack reads "Task completed, returning to inbox" on completion success |
| T15 | 200-row inbox scroll on a Pixel 4a release build maintains < 1% jank rate |

### Q&A Questions (8)
1. How does the deep-link handler queue a push payload that arrives before the auth bootstrap completes — and what's the timeout before it gives up?
2. What's the contract between optimistic status changes and the server canonical timestamps — does the UI ever show a future-dated transition?
3. Why is evidence upload allowed to outlive the completion call, and what happens to a `mediaId` that 200s after the task has already been marked complete?
4. How does the manager-only FAB stay honest when the local role is stale by minutes?
5. What happens when a push notification fires for a task that's already been cancelled by the manager — does the UI surface a graceful empty state, and how is the FCM dedupe key managed?
6. How do we keep evidence uploads from burning user data on metered networks — is there a "Wi-Fi only" toggle and where does it live?
7. What's the analytics taxonomy for `task_completed` so the Owner Dashboard can compute median time-to-complete per task type and per assignee?
8. How do we handle a task whose `refs.inventoryItemId` points to an inventory row that was deleted (FE-30) between assignment and completion?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 90% on `lib/features/business/tasks/**`; deep-link cold start verified
- [ ] Developer: 8 Q&A answered in the handoff doc
- [ ] Reviewer: push deep-link tested on real Android + iOS hardware; evidence upload tested on flaky 3G
- [ ] Reviewer: confirmed role gating is cosmetic-only and server is the source of truth
- [ ] Designer (motion review): completion success and timeline transitions reviewed on hardware
- [ ] Accessibility reviewer: TalkBack + VoiceOver flows verified end-to-end
- [ ] PM: Microcopy reviewed in all 6 languages

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________
**Accessibility Reviewer Signature**: ___________________________

---
**END OF FE-31 — DO NOT PROCEED WITHOUT APPROVAL**
