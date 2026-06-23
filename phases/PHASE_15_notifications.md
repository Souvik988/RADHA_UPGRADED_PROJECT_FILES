# PHASE 15 — Notifications

## Goal
Build the Notifications screen: inbox, preferences, mark-read / mark-all-read, and admin/owner test
send — plus wire the top-bar bell to the real inbox.

## Depends on
Phases 02, 04 (bell), 05.

## Doc references
- Doc 1 §6.17 (`/notifications/*`).
- Doc 2 §5.12 (Notifications spec), §4.13 (toast/banner), §4.14 (activity item).
- Doc 3 §A.3.11 (notification functions), §B.8 (throttle polling).

## Scope (in)
- `app/(dash)/notifications/page.tsx` — inbox + preferences tabs.
- `features/notifications/notifications.queries.ts` / `.actions.ts` / `.schema.ts`.
- Components: `inbox-list.tsx` (`GET /notifications`, mark read `/:id/read`, `/read-all`),
  `preferences.tsx` (`GET/PATCH /notifications/preferences`), `test-send.tsx` (admin/owner,
  `/notifications/test`), `fcm-register.tsx` (web push token register/unregister, optional).
- Wire `notifications-bell` (Phase 04) to open this inbox + reflect unread count.

## Out of scope
Broadcast comms (🆕, Phase 18). Building notification types in backend.

## Step-by-step
1. Inbox list (mono timestamps, type glyph tint); mark-read on open, mark-all-read action.
2. Preferences tab: toggles per channel/type → `PATCH /notifications/preferences`.
3. Test send (admin/owner only): pick a type → `POST /notifications/test` (202).
4. Optional web push: register/unregister FCM token.
5. Bell reflects unread (throttled poll). States: skeleton list, empty ("You're all caught up"),
   error retry. Verify.

## API wiring
- `GET /notifications`, `GET/PATCH /notifications/preferences`, `POST /notifications/read-all`,
  `POST /notifications/:id/read`, `POST /notifications/test` (admin/owner, 202),
  `POST/DELETE /notifications/fcm-token`.

## Design spec
- Doc 2 §5.12. Activity-style rows; `aria-live` for new arrivals; unread = accent-tint dot. Mono
  timestamps. One orange CTA (Send test, gated). Preferences as clean toggle list.

## Security checks
- Test send gated to admin/owner; API re-enforces. Throttle bell poll + inbox refresh (§B.8).
- No PII leakage in toasts/logs; honest data only.

## Acceptance criteria
- [ ] Inbox lists notifications; mark-read + mark-all-read work; bell unread count reflects state.
- [ ] Preferences load + save. Test send gated to admin/owner.
- [ ] All states designed; throttled polling; `build`+`typecheck` clean.

## Verification
- `npm run typecheck && npm run build`.
- User: open inbox, mark items read, change a preference, send a test (admin/owner), confirm bell count updates.

## Rollback note
Additive under `features/notifications/` + the page + bell wiring. No shared-layer/backend changes.
