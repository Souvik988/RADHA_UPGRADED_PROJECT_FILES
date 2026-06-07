# Phase FE-24: Shopping List

## 1. Phase Metadata

- **Phase ID**: FE-24
- **Phase Name**: Shopping List
- **Section**: Frontend Execution — Consumer Core
- **Depends On**: FE-04 (theme), FE-09 (haptics), FE-15 (router), BE-55 (shopping list module), BE-44 v2 (offline sync)
- **Blocks**: none on consumer-core path
- **Estimated Duration**: 3 days
- **Complexity**: Medium-High (drag-reorder + dual swipes + WhatsApp share + multi-list pager)

## 2. Goal (Engagement Angle)

A daily-use hook. The list feels physical: long-press lifts an item with a 4° tilt and a soft shadow, drop-back is satisfying. Right-swipe ticks it as purchased with a green wash; left-swipe deletes with a small confirm. WhatsApp share is one tap → opens with a pre-formatted message. Multiple lists live in a horizontal pager (a swipe-able page per list) so a user can keep "This week", "Costco", "Mom's grocery" all separate. The app bar always shows a tiny sync indicator that quietly tells the user "your changes are safe".

## 3. Why This Phase Matters (Retention Metric)

- The shopping list is one of two **daily-frequency** surfaces (alongside scanner). Target: **DAU/MAU on shopping list ≥ 0.35**.
- WhatsApp share is the highest-volume **organic acquisition** vector — every share is a brand impression. Target: **shares per active user per month ≥ 1.2**.
- Drag-reorder + swipe gestures are the moments where the app feels *premium native*, the kind beta testers describe as "buttery".
- Sync indicator (idle/syncing/error) is small but does big work — visible reassurance that offline edits are not lost is what makes BE-44 v2 *feel* trustworthy.

## 4. Prerequisites

- [ ] BE-55 — full CRUD: `POST /api/v1/shopping-lists`, `GET`, `POST .../items`, `PATCH .../items/{id}`, `DELETE .../items/{id}`
- [ ] BE-55 — `POST .../whatsapp-format` returns formatted text + `wa.me/?text=` URL
- [ ] BE-44 v2 — sync framework with idempotency keys + outbox pattern
- [ ] FE-04 — `swipeBgPositive`, `swipeBgDestructive` colour tokens
- [ ] FE-09 — Haptics: `lightImpact`, `mediumImpact`, `selectionClick`
- [ ] `url_launcher` (or `share_plus`) wired for WhatsApp deep-link

## 5. Files to Create

| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/shopping_list/shopping_list_screen.dart` | Page with horizontal pager |
| `apps/mobile/lib/features/shopping_list/widgets/list_pager_dots.dart` | Custom indicator dots |
| `apps/mobile/lib/features/shopping_list/widgets/list_page.dart` | One list page |
| `apps/mobile/lib/features/shopping_list/widgets/shopping_list_tile.dart` | Reorder + swipe tile |
| `apps/mobile/lib/features/shopping_list/widgets/add_item_bar.dart` | Pinned bottom add bar |
| `apps/mobile/lib/features/shopping_list/widgets/sync_indicator.dart` | App-bar dot (idle/syncing/error) |
| `apps/mobile/lib/features/shopping_list/widgets/empty_state_view.dart` | Lottie + add CTA |
| `apps/mobile/lib/features/shopping_list/widgets/whatsapp_share_button.dart` | App-bar action |
| `apps/mobile/lib/features/shopping_list/widgets/new_list_sheet.dart` | Create new list |
| `apps/mobile/lib/features/shopping_list/controllers/shopping_lists_controller.dart` | Riverpod for all lists |
| `apps/mobile/lib/features/shopping_list/controllers/list_items_controller.dart` | Items + optimistic CRUD |
| `apps/mobile/lib/features/shopping_list/controllers/sync_status_controller.dart` | Reads outbox queue |
| `apps/mobile/lib/features/shopping_list/services/shopping_list_repository.dart` | Drift + Dio |
| `apps/mobile/lib/features/shopping_list/services/whatsapp_share_service.dart` | Build wa.me URL |
| `apps/mobile/lib/features/shopping_list/animations/drag_lift.dart` | 4° tilt + scale + shadow |
| `apps/mobile/assets/lottie/empty_shopping_list.json` | 1500 ms loop |
| `apps/mobile/assets/lottie/sync_success_pulse.json` | 600 ms quick green pulse |
| `apps/mobile/test/features/shopping_list/shopping_list_widget_test.dart` | Widgets |
| `apps/mobile/test/features/shopping_list/shopping_list_golden_test.dart` | Goldens |
| `apps/mobile/integration_test/shopping_list_flow_test.dart` | Integration |

## 6. Screen / Widget Spec

```dart
// shopping_list_screen.dart
return Scaffold(
  appBar: AppBar(
    title: ListPagerDots(controller: pageCtrl, lists: lists),
    actions: [
      const SyncIndicator(),
      WhatsAppShareButton(listId: currentListId),
      IconButton(onPressed: _openNewListSheet, icon: const Icon(Icons.add)),
    ],
  ),
  body: lists.isEmpty
    ? const EmptyStateView()
    : PageView.builder(
        controller: pageCtrl,
        itemCount: lists.length,
        itemBuilder: (_, i) => ListPage(listId: lists[i].id),
      ),
  bottomSheet: AddItemBar(listId: currentListId),
);
```

```dart
// shopping_list_tile.dart — reorder + dismiss
return ReorderableDelayedDragStartListener(
  index: index,
  child: Dismissible(
    key: ValueKey(item.id),
    background: const _SwipeBg.purchased,        // right swipe (left → right)
    secondaryBackground: const _SwipeBg.delete,   // left swipe (right → left)
    confirmDismiss: (dir) async {
      if (dir == DismissDirection.startToEnd) {
        await ctrl.togglePurchased(item.id);
        return false;                              // keep tile; togglePurchased flips state
      }
      return await _confirmDelete(context);
    },
    child: AnimatedScale(
      scale: dragging ? 1.04 : 1,
      duration: const Duration(milliseconds: 140),
      child: Transform.rotate(
        angle: dragging ? 0.0698 : 0,             // 4° in radians
        child: Material(
          elevation: dragging ? 8 : 1,
          child: ListTile(
            title: Text(item.text,
              style: TextStyle(decoration: item.isPurchased
                ? TextDecoration.lineThrough : null)),
            trailing: const Icon(Icons.drag_handle),
          ),
        ),
      ),
    ),
  ),
);
```

```dart
// sync_indicator.dart
return AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  child: switch (status) {
    SyncStatus.idle => const _Dot(color: Colors.green),
    SyncStatus.syncing => Lottie.asset('assets/lottie/sync_success_pulse.json',
        width: 18, repeat: true),
    SyncStatus.error => const _Dot(color: Colors.red),
  },
);
```

```dart
// whatsapp_share_service.dart
Future<void> share(String listId) async {
  final res = await api.formatForWhatsapp(listId);   // returns { text, url }
  await launchUrl(Uri.parse(res.url),
    mode: LaunchMode.externalApplication);
}
```

## 7. Visual Behaviour & Interaction States

| # | State | Trigger | UI |
|---|---|---|---|
| 1 | **initial / no lists** | First-ever launch | Empty state Lottie + "Create your first list" CTA |
| 2 | **initial / one list / no items** | New list, empty | Same Lottie smaller + "Add your first item" inline copy |
| 3 | **loaded** | Items exist | List of tiles, AddItemBar pinned at bottom |
| 4 | **add-item typing** | Focus on input | Input expands to multi-line if user enters more than ~50 chars |
| 5 | **add-item submit** | Tap send / Enter | New tile slides in from top (220 ms easeOutCubic), input clears, focus retained |
| 6 | **drag-lift** | Long-press 250 ms | Tile scales to 1.04, rotates 4°, shadow elevation 8, others dim 12% |
| 7 | **drag-drop** | Release | Tile settles in 180 ms easeOutCubic; reorder PATCH queued |
| 8 | **swipe-purchase** | Right swipe | Green wash bg fills 60% of width with check; release flips state and adds line-through |
| 9 | **swipe-delete (confirm)** | Left swipe past 50% threshold | AlertDialog confirm; cancel rolls back |
| 10 | **list-pager swipe** | Horizontal swipe | PageView slides 320 ms easeInOutCubic; dots animate |
| 11 | **new-list sheet** | Tap + in app bar | Bottom sheet with name input rises 320 ms |
| 12 | **whatsapp-share tap** | Tap action | Bottom sheet preview of formatted text + Send → launches wa.me |
| 13 | **sync — idle** | All in sync | Static green dot |
| 14 | **sync — syncing** | Outbox draining | Lottie pulse (1.4 s loop) |
| 15 | **sync — error** | Last sync failed | Red dot + tap reveals retry sheet |
| 16 | **error-rate-limited (429)** | Add/PATCH 429 | Toast + add-item button briefly disabled |
| 17 | **offline** | No connectivity | Strip "Offline — changes will sync"; sync indicator stays gray |
| 18 | **accessibility-mode** | Reduced motion | Drag-lift uses scale only (no rotate); page-pager uses fade |
| 19 | **rename-list** | Long-press dot | Inline rename field + save |

## 8. Animations Inventory

### Lottie

| File | Duration | Trigger | Loop | Size |
|---|---|---|---|---|
| `empty_shopping_list.json` | 1500 ms | Empty state | Yes | ≤ 26 KB |
| `sync_success_pulse.json` | 600 ms | Sync transitions to idle | No | ≤ 14 KB |

### flutter_animate Chains

| Widget | Chain | Curves | Total |
|---|---|---|---|
| New tile entrance | `.fadeIn(160).slideY(begin: -.06, end: 0, dur: 220)` | easeOutCubic | 380 ms |
| Drag-lift on long-press | `.scaleXY(end: 1.04, dur: 140)` + `Transform.rotate(4°)` instant | easeOutBack | 140 ms |
| Drag-drop settle | `.scaleXY(end: 1, dur: 180)` + de-rotate | easeOutCubic | 180 ms |
| Swipe-purchase wash | `Dismissible` background colour transitions | linear | matches gesture |
| Tile delete collapse | `AnimatedSize` 200 ms | easeOut | 200 ms |
| List-page change | PageView curve override 320 | easeInOutCubic | 320 ms |
| New-list sheet rise | `.slideY(begin: 1, end: 0, dur: 320)` | easeOutCirc | 320 ms |
| Sync indicator state change | `AnimatedSwitcher 200` | easeInOut | 200 ms |

### Hero Transitions

None — list does not own image-heavy heroes.

### Custom Motion Budgets

- **Entrance**: ≤ 480 ms (PageView appearance + first 5 tiles staggered fade-in 60 ms each)
- **Drag-lift cycle**: ≤ 320 ms (lift 140 + drop 180)
- **Swipe action**: ≤ 380 ms (swipe + Lottie/wash overlapped)
- **Page-change**: 320 ms

## 9. Haptics

| Event | Type |
|---|---|
| Tile long-press lift | `mediumImpact` once |
| Tile drop after reorder | `lightImpact` |
| Reorder cross another tile | `selectionClick` |
| Swipe-purchase commit | `mediumImpact` |
| Swipe-delete threshold reached | `heavyImpact` |
| Confirm delete | `mediumImpact` |
| Add item submit | `lightImpact` |
| List page swap | `selectionClick` |
| WhatsApp share launch | `mediumImpact` |
| Sync error appears | `heavyImpact` |
| Empty-state CTA tap | `lightImpact` |

## 10. Microcopy

| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `shopping_list.title_default` | My shopping list | TODO | TODO | TODO | TODO | TODO |
| `shopping_list.empty_heading` | Your list is empty | TODO | TODO | TODO | TODO | TODO |
| `shopping_list.empty_body` | Add items, drag to reorder, swipe to tick or delete | TODO | TODO | TODO | TODO | TODO |
| `shopping_list.empty_cta` | Add your first item | TODO | TODO | TODO | TODO | TODO |
| `shopping_list.input_hint` | Add an item… | TODO | TODO | TODO | TODO | TODO |
| `shopping_list.delete_confirm` | Remove this item? | TODO | TODO | TODO | TODO | TODO |
| `shopping_list.share_whatsapp` | Share on WhatsApp | TODO | TODO | TODO | TODO | TODO |
| `shopping_list.share_preview_title` | Preview message | TODO | TODO | TODO | TODO | TODO |
| `shopping_list.new_list` | New list | TODO | TODO | TODO | TODO | TODO |
| `shopping_list.new_list_hint` | List name (e.g. Costco) | TODO | TODO | TODO | TODO | TODO |
| `shopping_list.sync_idle` | All saved | TODO | TODO | TODO | TODO | TODO |
| `shopping_list.sync_syncing` | Syncing… | TODO | TODO | TODO | TODO | TODO |
| `shopping_list.sync_error` | Couldn't sync — tap to retry | TODO | TODO | TODO | TODO | TODO |
| `shopping_list.offline_strip` | Offline — your changes will sync | TODO | TODO | TODO | TODO | TODO |
| `shopping_list.rate_limited` | A bit too fast — try again in a moment | TODO | TODO | TODO | TODO | TODO |

## 11. Backend Integration

### Endpoints

| Method | Path | Purpose | Source |
|---|---|---|---|
| `GET` | `/api/v1/shopping-lists` | List of lists | BE-55 |
| `POST` | `/api/v1/shopping-lists` | Create list | BE-55 |
| `PATCH` | `/api/v1/shopping-lists/{id}` | Rename / archive | BE-55 |
| `GET` | `/api/v1/shopping-lists/{id}/items` | Items | BE-55 |
| `POST` | `/api/v1/shopping-lists/{id}/items` | Add item | BE-55 |
| `PATCH` | `/api/v1/shopping-lists/{id}/items/{itemId}` | Update / toggle / reorder | BE-55 |
| `DELETE` | `/api/v1/shopping-lists/{id}/items/{itemId}` | Soft delete | BE-55 |
| `POST` | `/api/v1/shopping-lists/{id}/whatsapp-format` | Get formatted text + wa.me URL | BE-55 |

### DTOs

```ts
interface ShoppingListItemDto {
  id: string; listId: string; item: string; quantity?: string;
  notes?: string; isPurchased: boolean; orderIndex: number; createdAt: string;
}
interface WhatsappFormatDto {
  text: string;        // multi-line, prefixed "🛒 My list:"
  url: string;         // 'https://wa.me/?text=' + encoded(text)
}
```

### Idempotency Key Strategy

- Every write goes through BE-44 v2 outbox: key = `sha256(userId + operationType + payloadHash + clientLamportTs)`.
- Reorder PATCH includes `orderIndex` newValue + `If-Match` ETag of list version to avoid silent overwrites.
- Toggle-purchased: `idempotencyKey = sha256(itemId + 'purchased' + nextValue)` — repeat is no-op.

### Error → UI Mapping

| Code | UI |
|---|---|
| 401 | re-login, preserve current list |
| 403 / `entitlement.list_count_exceeded` | Sheet "Free tier allows 3 lists — Upgrade to Premium" |
| 404 / `shopping_list.not_found` | Toast + remove from local |
| 409 / `shopping_list_item.version_conflict` | Last-write-wins resolved per BE-44 v2 |
| 422 / `item.too_long` | Inline input error (max 200 chars) |
| 429 | State #16 |
| 5xx / network | Sync indicator → error; outbox holds the change |

## 12. Accessibility

- **Semantics**: Tile root `Semantics(label: '{{item}}, {{purchased? "purchased" : "not purchased"}}, item {{index+1}} of {{n}}')`. Sync indicator announces "{{state}}" on change.
- **Focus order**: AppBar back → list pager dots → sync indicator → share button → add (+) → list tiles top-down → AddItemBar.
- **Dynamic type**: Tiles wrap to multi-line at 1.5× type; AddItemBar grows in height accordingly.
- **Reduced motion**: Disable rotate on lift; disable Lottie loops; PageView uses fade transition.
- **VoiceOver script**: When user reorders, announce `"{{item}} moved to position {{n}} of {{m}}"`. After share launch, announce `"Opening WhatsApp"`.
- **Contrast**: Swipe-bg green/red foregrounds tested against white on-error / on-positive ≥ 4.5:1.

## 13. Testing

### Widget tests

- Add item from AddItemBar inserts new tile at the top.
- Long-press triggers drag-lift visuals.
- Right swipe toggles purchased; line-through styling appears.
- Left swipe past threshold opens confirm dialog.
- Tapping share launches `share_plus` with correct wa.me URL (mocked).
- Sync indicator switches between idle/syncing/error per provider state.
- Empty state CTA opens new-list sheet (or focuses input if list exists).

### Golden tests

- Populated list (light + dark)
- Empty list (light + dark + 1.5× type)
- Drag-lift mid-state
- Sync error state in app bar

### Integration tests

- Reorder operation issues correct PATCH and persists across app restart (Drift cache).
- Offline edits accumulate in outbox and drain on connectivity return.
- WhatsApp share opens external intent with correctly URL-encoded text.

## 14. Mandatory SOP

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Long-press of 250 ms triggers drag-lift with rotation 4° and scale 1.04 |
| T2 | Drop animation settles in 180 ± 20 ms |
| T3 | Right-swipe purchase toggles state and adds strikethrough |
| T4 | Left-swipe delete past 50% prompts confirm; cancel rolls back |
| T5 | Pager dots reflect current list and animate on swap (320 ms) |
| T6 | WhatsApp share launches `wa.me/?text=` with URL-encoded body |
| T7 | New-list sheet rises 320 ms and creates list on confirm |
| T8 | Sync indicator transitions: idle→syncing on add; syncing→idle on success; idle→error on failure |
| T9 | Offline mode shows strip and queues mutations to outbox |
| T10 | Mutations sync in correct order on reconnect (preserves user's reorder) |
| T11 | Idempotency key prevents duplicate adds on retry |
| T12 | Reduced motion disables rotate during lift and Lottie loops |
| T13 | Free-tier list-count enforcement shows Premium upsell on 4th create |
| T14 | VoiceOver announces reorder positions during drag |
| T15 | Memory profile under 60 MB on Pixel 4a after 100 items / 5 lists |

### Q&A Questions (8)

1. How do we keep reorder persistence consistent when 2 devices reorder simultaneously (BE-44 v2 conflict)?
2. What is the upper bound for items per list and how does the UI behave at 100+ items?
3. How do we ensure the WhatsApp deep-link works on devices without WhatsApp installed (fallback to share sheet)?
4. How is the sync indicator throttled to avoid flicker on rapid mutations?
5. What is the policy for archived lists — visible somewhere or fully hidden?
6. How do we de-duplicate items typed twice in quick succession (case-insensitive merge?)?
7. How are quantities handled in the WhatsApp-format string (qty after item or before)?
8. How does this screen evolve when voice input ships (Req 36 / BE-55 future) — what controls move where?

### Sign-off Gate

- [ ] All 15 SOP tests pass
- [ ] All 8 Q&A answered
- [ ] Designer signed off drag-lift visuals (rotation amount, shadow)
- [ ] Animation budgets respected
- [ ] WhatsApp share deep-link verified on Android + iOS
- [ ] Goldens merged

**Developer Signature**: ___________________________

**Reviewer**: ☐ APPROVED — Consumer Core (FE-17 → FE-24) COMPLETE ☐ CHANGES REQUESTED  ___________________

**Designer**: ☐ APPROVED ☐ CHANGES REQUESTED  ___________________

---

**END OF FE-24 — DO NOT PROCEED WITHOUT APPROVAL**

---

## Consumer Core Section Closeout

With FE-17 → FE-24 signed off, RADHA's consumer-side daily-use loop is complete:

- **FE-17** Scanner — entry point, the start of every session
- **FE-18** Scan Output — the money screen
- **FE-19** Product Detail — the re-engagement screen
- **FE-20** Saved Products + Calendar — the habit screen
- **FE-21** Recall Inbox — the trust screen
- **FE-22** AI Explainer — the differentiator
- **FE-23** Alternatives Carousel — the revenue surface
- **FE-24** Shopping List — the daily hook

Together these eight screens cover the complete consumer journey — from "I just opened the app" to "I shared my list with my mom." Each is engineered for a measurable retention metric, and each owns one or more delight moments that earn it the next session.
