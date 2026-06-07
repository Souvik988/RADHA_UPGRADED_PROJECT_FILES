# BE-36 Handoff — Premium Consumer + Family Sharing
- Premium subscription endpoints live, mandate-backed billing on day-30 cycle.
- Family Sharing endpoints live with 5-member cap.
- 15 tests + 8 Q&A complete.

## Files
`server/src/modules/subscriptions/services/{premium-consumer,family-sharing}.service.ts`
`server/src/modules/subscriptions/controllers/{premium-consumer,family-sharing}.controller.ts`

## Context for BE-37
Allergen_Profile (next phase) MUST scope per-member when family sharing is active. Use `family_links.member_user_id` as the scope key, not `primary_user_id`.

## Rollback
DELETE FROM family_links WHERE created_at >= '<deploy>';
UPDATE subscriptions SET tier='free_consumer' WHERE tier='premium_consumer';

**End of BE-36 Handoff**
