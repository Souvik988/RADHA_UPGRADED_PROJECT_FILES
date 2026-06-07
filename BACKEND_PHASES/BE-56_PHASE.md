# Phase BE-56: Barcode Learning Service (Community)

## Phase Metadata
- **Phase ID**: BE-56
- **Depends On**: BE-13 v2 (presigned upload), BE-11 v2 (OFF upsert), BE-29 v2 (analytics)
- **Estimated Duration**: 2-3 days

## Goal
Per Req 46, allow users to submit India-specific products not in Open Food Facts. Moderation queue. Approved entries become public. Flag-3 re-moderation.

## Schema
```sql
CREATE TABLE barcode_learning_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submitter_user_id UUID NOT NULL REFERENCES users(id),
  ean TEXT NOT NULL,
  brand TEXT, name TEXT, category TEXT,
  s3_object_keys TEXT[],
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','approved','rejected','flagged')),
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  moderated_at TIMESTAMPTZ,
  moderated_by UUID REFERENCES users(id)
);

CREATE TABLE barcode_learning_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_ean TEXT NOT NULL,
  flagger_user_id UUID NOT NULL REFERENCES users(id),
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(product_ean, flagger_user_id)
);
```

## API
- `POST /api/v1/products/learn` (submit)
- `GET /api/v1/admin/learn/queue` (moderator)
- `POST /api/v1/admin/learn/:id/approve` (moderator)
- `POST /api/v1/admin/learn/:id/reject` (moderator)
- `POST /api/v1/products/:ean/flag` (user)

## Re-moderation rule
When a product accumulates 3 unique flags, status flips back to `pending` and re-enters the moderator queue.

## SOP
**Tests (15)**: submit creates row pending; queue lists pending only; approve upserts to Product_Catalog; reject does not; flag-3 triggers re-moderation; moderator role enforced; submitter event in PostHog; image storage 7-day lifecycle (from BE-13); rate limit 10 submissions/user/day; duplicate EAN submission consolidates; PII stripped from submission; sentry on bulk-flag burst; tenant-public after approval (no tenant column); audit log; conflict resolution if multiple submissions for same EAN.

**Q&A (8)**: How are moderators trained? Anti-vandalism rate-limit? Reputation system for submitters? How is duplicate flagging avoided? Right-to-correct vs right-to-erase? Liability for moderator decisions? Integration with FSSAI database for verification? Long-tail brand corrections?

### Sign-off (standard).

---
**END OF BE-56**
