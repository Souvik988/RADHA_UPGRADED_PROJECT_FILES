# Phase FE-21: Recall Alerts Inbox

## 1. Phase Metadata

- **Phase ID**: FE-21
- **Phase Name**: Recall Alerts Inbox
- **Section**: Frontend Execution — Consumer Core
- **Depends On**: FE-04 (theme), FE-09 (haptics), FE-15 (router), FE-19 (deep-link target), BE-39 (recall sweep + FCM), BE-24 v2 (notifications), BE-32 v2 (rate limit)
- **Blocks**: none on the consumer-core path; touched by FE-32 (notifications centre)
- **Estimated Duration**: 2-3 days
- **Complexity**: Medium (priority list + FCM hand-off + foreground banner)

## 2. Goal (Engagement Angle)

A trust-builder. When the FSSAI feed flags a product the user has saved, RADHA reaches them — silently if they're not in the app, with a sliding **in-app banner** if they are. The inbox itself is a calm, severity-coded list with an "Acknowledge" button that confirms the user has *seen* the warning and clears the badge. Stale alerts auto-archive after 30 days so the list never feels like a graveyard.

## 3. Why This Phase Matters (Retention Metric)

- Recall alerts are RADHA's biggest **earned-trust** moment. Beta users in research said "I'd recommend this app to my mom *just* for this feature."
- Target: **acknowledge-rate ≥ 65%** within 24 h of receipt; **deep-link CTR ≥ 50%** to the affected saved product.
- Push-to-foreground transition matters: if a user is *in the app* when a recall fires, an iOS-style banner is far more polite than a system notification. We do both: server fires FCM, app intercepts when foregrounded and shows in-app instead.
- Engagement: each acknowledge fires a ~600 ms confetti-shield Lottie that subtly rewards the user for closing the loop.

## 4. Prerequisites

- [ ] BE-39 — `GET /api/v1/recall-alerts?status=unread|all` returns priority list
- [ ] BE-39 — `POST /api/v1/recall-alerts/{id}/acknowledge` clears badge
- [ ] BE-24 v2 — FCM topic `recall_alerts.user.{id}` and inbox-style payload
- [ ] BE-39 — Stale auto-archive policy (30 days) implemented server-side; client just respects `archived: true` flag
- [ ] FE-04 — Severity colours (`severityHigh`, `severityMed`, `severityLow`)
- [ ] FE-09 — `HapticsService.notificationSuccess()` exposed
- [ ] FCM SDK initialised in `main.dart` with foreground handler

## 5. Files to Create

| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/recall_alerts/recall_inbox_screen.dart` | Inbox list page |
| `apps/mobile/lib/features/recall_alerts/widgets/recall_alert_tile.dart` | Severity-coloured list item |
| `apps/mobile/lib/features/recall_alerts/widgets/severity_dot.dart` | 8 dp coloured dot + tooltip |
| `apps/mobile/lib/features/recall_alerts/widgets/foreground_recall_banner.dart` | In-app top banner |
| `apps/mobile/lib/features/recall_alerts/widgets/acknowledge_button.dart` | Morph button with success Lottie |
| `apps/mobile/lib/features/recall_alerts/widgets/empty_inbox_view.dart` | Calm empty state |
| `apps/mobile/lib/features/recall_alerts/widgets/archived_section_header.dart` | Toggle row to show archived |
| `apps/mobile/lib/features/recall_alerts/controllers/recall_inbox_controller.dart` | Riverpod list + counters |
| `apps/mobile/lib/features/recall_alerts/controllers/foreground_alert_controller.dart` | Listens to FCM in-app stream |
| `apps/mobile/lib/features/recall_alerts/services/recall_alerts_repository.dart` | Drift cache + Dio API |
| `apps/mobile/lib/features/recall_alerts/services/fcm_message_handler.dart` | Translates FCM payload → in-app banner |
| `apps/mobile/lib/features/recall_alerts/animations/severity_pulse.dart` | High-severity tile aura |
| `apps/mobile/assets/lottie/acknowledge_success.json` | 700 ms shield-check |
| `apps/mobile/assets/lottie/empty_inbox_calm.json` | 1800 ms gentle wave |
| `apps/mobile/test/features/recall_alerts/recall_inbox_widget_test.dart` | Widgets |
| `apps/mobile/test/features/recall_alerts/recall_inbox_golden_test.dart` | Goldens |
| `apps/mobile/integration_test/recall_alerts_flow_test.dart` | Integration |

## 6. Screen / Widget Spec

```dart
// recall_inbox_screen.dart
return Scaffold(
  appBar: AppBar(title: const Text('Recall alerts'), actions: [
    if (state.unreadCount > 0) Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(child: Text('${state.unreadCount} new')),
    ),
  ]),
  body: state.when(
    loading: () => const _ShimmerList(itemCount: 6),
    error: (e, _) => _InboxError(error: e),
    data: (alerts) {
      if (alerts.isEmpty) return const EmptyInboxView();
      return CustomScrollView(slivers: [
        SliverList(delegate: SliverChildBuilderDelegate(
          (ctx, i) => RecallAlertTile(alert: alerts.unread[i]),
          childCount: alerts.unread.length,
        )),
        SliverToBoxAdapter(child: ArchivedSectionHeader(count: alerts.archived.length)),
        if (state.showArchived) SliverList(delegate: SliverChildBuilderDelegate(
          (ctx, i) => RecallAlertTile(alert: alerts.archived[i], dimmed: true),
          childCount: alerts.archived.length,
        )),
      ]);
    },
  ),
);
```

```dart
// foreground_recall_banner.dart
return AnimatedSlide(
  offset: visible ? Offset.zero : const Offset(0, -1),
  duration: const Duration(milliseconds: 280),
  curve: Curves.easeOutCubic,
  child: Material(
    elevation: 6,
    color: scheme.errorContainer,
    child: SafeArea(child: Row(children: [
      const Icon(Icons.warning_amber),
      Expanded(child: Text(alert.title)),
      TextButton(onPressed: openInbox, child: const Text('View')),
      IconButton(onPressed: dismiss, icon: const Icon(Icons.close)),
    ])),
  ),
);
```

```dart
// acknowledge_button.dart — morph
return AnimatedSwitcher(
  duration: const Duration(milliseconds: 240),
  child: state == 'idle'
    ? FilledButton.icon(onPressed: _ack, icon: const Icon(Icons.check), label: const Text('Acknowledge'))
    : Lottie.asset('assets/lottie/acknowledge_success.json',
        repeat: false, onLoaded: (c) => c.duration = 700.ms),
);
```

## 7. Visual Behaviour & Interaction States

| # | State | Trigger | UI |
|---|---|---|---|
| 1 | **initial** | Mount | Shimmer list 6 bones, AppBar shows "—" until counter resolves |
| 2 | **loaded — empty** | 0 alerts (read or unread) | Lottie `empty_inbox_calm` + "All clear" copy |
| 3 | **loaded — unread present** | At least one unread alert | Tiles render newest-first, severity dots colored, high-severity tile auras |
| 4 | **archived hidden** (default) | Initial | Header "{{n}} archived alerts ▾" |
| 5 | **archived shown** | Tap header | `AnimatedSize` reveals dimmed archived tiles |
| 6 | **acknowledge tapped** | Tap button on tile | Button morphs to Lottie shield-check 700 ms; tile fades to `archived: true` 240 ms after |
| 7 | **deep-link tap** | Tap tile body | Navigates to FE-19 with the affected `savedProductId` |
| 8 | **foreground FCM banner** | App in foreground when push arrives | Banner slides down 280 ms easeOutCubic, auto-dismiss 6 s if no tap |
| 9 | **error-network** | List fetch fails | Cached list + retry pill, AppBar shows "Couldn't refresh" |
| 10 | **offline** | Connectivity none | Strip "Showing cached alerts"; ack queues to outbox |
| 11 | **rate-limited** | 429 on ack | Snackbar with countdown; button briefly disabled |
| 12 | **permission-denied (notifications)** | Push permission denied | Top card "Allow notifications to get recall alerts" → opens settings |
| 13 | **stale auto-archived** | Server returns `archived: true` w/ reason `stale_30_days` | Tile collapsed by default |
| 14 | **accessibility-mode** | Reduced motion | No severity-aura pulse, banner uses fade not slide |
| 15 | **realtime stream** | New alert arrives via FCM while inbox open | New tile slides in from top 240 ms + soft haptic |
| 16 | **error-validation** | Server returns malformed alert (defensive) | Single-tile fallback "Alert format error — tap to refresh" |

## 8. Animations Inventory

### Lottie

| File | Duration | Trigger | Loop | Size |
|---|---|---|---|---|
| `acknowledge_success.json` | 700 ms | Acknowledge tap | No | ≤ 24 KB |
| `empty_inbox_calm.json` | 1800 ms | Empty state | Yes | ≤ 28 KB |

### flutter_animate Chains

| Widget | Chain | Curves | Total |
|---|---|---|---|
| High-severity tile aura | `.shimmer(dur: 1600, color: errorContainer.withOpacity(.30))` (loop) | — | 1600 ms loop |
| Foreground banner slide-down | `.slideY(begin: -1, end: 0, dur: 280)` + auto-fade-out at 6 s | easeOutCubic | 280 ms in, 200 ms out |
| Acknowledge morph | `AnimatedSwitcher 240` then Lottie 700 | easeInOut | 940 ms |
| Tile fade after ack | `.fadeOut(dur: 240)` then list rebuild | easeOut | 240 ms |
| New-arrival tile slide-in | `.slideY(begin: -.2, end: 0, dur: 240).fadeIn(180)` | easeOutCubic | 240 ms |
| Archived header rotate | `.rotate(begin: 0, end: .5, dur: 200)` | easeOut | 200 ms |
| Empty-state hero | `.fadeIn(220).slideY(begin: .04, end: 0, dur: 280)` | easeOutCubic | 500 ms |

### Hero Transitions

| From | To | Tag | Curve | Duration |
|---|---|---|---|---|
| Tile thumbnail (saved product image) | FE-19 parallax hero | `product-{ean}-image` | easeInOutCubic | 360 ms |

### Custom Motion Budgets

- **Entrance**: ≤ 480 ms (shimmer fade + list slide-in)
- **Foreground banner**: ≤ 280 ms slide; auto-dismiss 6000 ms with 200 ms fade-out
- **Acknowledge cycle**: ≤ 940 ms total (morph 240 + Lottie 700)

## 9. Haptics

| Event | Type |
|---|---|
| Foreground banner appears | `mediumImpact` once |
| Tile tap (deep-link) | `lightImpact` |
| Acknowledge tap | `mediumImpact` |
| Acknowledge success (Lottie complete) | `notificationSuccess` (or `heavyImpact` on Android) |
| New realtime tile arrival | `lightImpact` |
| Archived header expand | `selectionClick` |
| Permission-denied card tap | `mediumImpact` |
| Rate-limited (429) | `heavyImpact` |

## 10. Microcopy

| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `recall_inbox.title` | Recall alerts | TODO | TODO | TODO | TODO | TODO |
| `recall_inbox.empty_heading` | All clear | TODO | TODO | TODO | TODO | TODO |
| `recall_inbox.empty_body` | We'll let you know if any of your saved products are recalled | TODO | TODO | TODO | TODO | TODO |
| `recall_inbox.unread_chip` | {{n}} new | TODO | TODO | TODO | TODO | TODO |
| `recall_inbox.acknowledge` | Acknowledge | TODO | TODO | TODO | TODO | TODO |
| `recall_inbox.archived_header` | {{n}} archived alerts | TODO | TODO | TODO | TODO | TODO |
| `recall_inbox.banner_title` | {{product}} has been recalled | TODO | TODO | TODO | TODO | TODO |
| `recall_inbox.banner_view` | View | TODO | TODO | TODO | TODO | TODO |
| `recall_inbox.severity_high` | Urgent | TODO | TODO | TODO | TODO | TODO |
| `recall_inbox.severity_med` | Important | TODO | TODO | TODO | TODO | TODO |
| `recall_inbox.severity_low` | For your info | TODO | TODO | TODO | TODO | TODO |
| `recall_inbox.permission_card` | Allow notifications to get recall alerts | TODO | TODO | TODO | TODO | TODO |
| `recall_inbox.error_network` | Couldn't refresh. Pull to retry. | TODO | TODO | TODO | TODO | TODO |
| `recall_inbox.cached_strip` | Showing cached alerts | TODO | TODO | TODO | TODO | TODO |

## 11. Backend Integration

### Endpoints

| Method | Path | Purpose | Source |
|---|---|---|---|
| `GET` | `/api/v1/recall-alerts?status=all&cursor=...` | Paginated inbox | BE-39 |
| `POST` | `/api/v1/recall-alerts/{id}/acknowledge` | Mark acknowledged | BE-39 |
| `GET` | `/api/v1/recall-alerts/unread-count` | Tiny endpoint for badge polling | BE-39 |
| (FCM topic) | `recall_alerts.user.{id}` | Push payload | BE-24 v2 / BE-39 |

### DTOs

```ts
interface RecallAlertDto {
  id: string;
  feedEntryId: string;
  productEan: string;
  productName: string;
  productImageUrl?: string;
  reason: string;
  severity: 'low'|'med'|'high';
  recalledAt: string;
  acknowledged: boolean;
  archived: boolean;
  archivedReason?: 'user_ack'|'stale_30_days';
  savedProductId?: string;        // deep-link target if user has it saved
}
```

### FCM Payload Shape

```json
{ "category": "recall_alert",
  "title": "Product Recall",
  "body": "{{product}} has been recalled: {{reason}}",
  "data": { "alertId": "uuid", "savedProductId": "uuid", "severity": "high" } }
```

### Idempotency Key Strategy

- Acknowledge: `idempotencyKey = sha256(alertId + 'ack')` — repeat is no-op.
- Banner-dismiss: client-only, no API call.

### Error → UI Mapping

| Code | UI |
|---|---|
| 401 | re-login, preserve deep-link |
| 403 | Should not happen for own alerts; log Sentry |
| 404 / `recall_alert.not_found` | Snackbar "Already cleared" + refresh |
| 410 / `recall_alert.archived_by_server` | Tile fades, list refreshes |
| 429 | Disable button + countdown |
| 5xx / network | Retry pill, action queues |

## 12. Accessibility

- **Semantics**: Tile root `Semantics(label: 'Recall alert: {{product}}, severity {{level}}, {{date}}')`. Acknowledge button `Semantics(button: true, label: 'Acknowledge alert')`.
- **Focus order**: AppBar → unread chip → tiles top-down → archived header → archived tiles (when expanded).
- **Dynamic type**: Tile titles `titleMedium` scale to 1.5×; image thumbnail kept at 56 dp.
- **Reduced motion**: Disable severity-aura pulse, banner uses fade.
- **VoiceOver script**: On foreground banner appearance, announce `"Recall alert: {{product}}. Severity {{level}}. Double tap to view."`.
- **Contrast**: Severity dot has accompanying text label always visible; not color-only.

## 13. Testing

### Widget tests

- Tiles render in newest-first order.
- High-severity tile aura applied only when `severity == 'high'`.
- Acknowledge button morphs and fires API exactly once on rapid double-tap.
- Foreground banner auto-dismiss at 6 s.
- Archived section expands and collapses via header tap.
- Empty state renders Lottie + correct CTA.

### Golden tests

- Inbox with 3 unread (mixed severities) light + dark
- Empty state full-page (light + dark + 1.5× type)
- Foreground banner overlay
- Permission-denied card

### Integration tests

- FCM payload arrival with app in foreground → banner shows; with app in background → system notification only.
- Tap banner View → navigates to FE-19 with correct `savedProductId`.
- Acknowledge flow from inbox: optimistic UI, rollback on 5xx.

## 14. Mandatory SOP

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | List paginates with cursor and renders newest-first |
| T2 | Severity color/text mapping matches BE-39 contract |
| T3 | High-severity tile aura loops at 1600 ms cadence |
| T4 | Acknowledge button completes morph + Lottie within 940 ms |
| T5 | Acknowledge is idempotent on rapid double-tap |
| T6 | Foreground banner appears within 200 ms of FCM in-app message |
| T7 | Foreground banner auto-dismisses at 6000 ± 200 ms |
| T8 | Tap-to-view from banner deep-links correctly to FE-19 |
| T9 | Archived section is hidden by default and respects show/hide toggle |
| T10 | Stale auto-archived (`stale_30_days`) tiles render as dimmed |
| T11 | Permission-denied card opens OS settings on tap |
| T12 | Offline mode shows cached alerts + queues acks via outbox |
| T13 | New realtime tile slides in cleanly when inbox is open |
| T14 | Reduced motion disables aura and uses fade for banner |
| T15 | VoiceOver announces banner content exactly once |

### Q&A Questions (8)

1. How do we de-duplicate banner + system notification when the app is on the foreground vs. just resumed?
2. How is the unread badge in the home tab kept consistent with this screen's counter?
3. What is the strategy for *very* old alerts that never got acknowledged — do they archive forever or stay in inbox?
4. How do we handle the case where a user uninstalls and reinstalls — do their unacknowledged alerts re-fire on first launch?
5. What is the logic when a user *was* a Premium family member but downgrades — do they still receive recall alerts for shared products?
6. How do we test in CI that BE-39's auto-archive policy is being respected client-side?
7. What is the rollback if BE-39 returns malformed payloads (missing severity, missing product image)?
8. How does this screen behave for a user with notifications globally disabled — do alerts still appear in this inbox?

### Sign-off Gate

- [ ] All 15 SOP tests pass
- [ ] All 8 Q&A answered
- [ ] Designer signed off severity colours and banner styling
- [ ] FCM foreground/background interception verified on Android + iOS
- [ ] Goldens merged

**Developer Signature**: ___________________________

**Reviewer**: ☐ APPROVED — Proceed to FE-22 ☐ CHANGES REQUESTED  ___________________

**Designer**: ☐ APPROVED ☐ CHANGES REQUESTED  ___________________

---

**END OF FE-21 — DO NOT PROCEED WITHOUT APPROVAL**
