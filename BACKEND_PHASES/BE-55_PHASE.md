# Phase BE-55: Shopping List Module

## Phase Metadata
- **Phase ID**: BE-55
- **Depends On**: BE-44 v2 (sync), BE-09 v2
- **Estimated Duration**: 1-2 days

## Goal
Per Req 47 (list portion), text-input shopping list with optional WhatsApp send. v1 is text-only (voice deferred to v2 per Req 36).

## Schema
```sql
CREATE TABLE shopping_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT 'My Shopping List',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  archived_at TIMESTAMPTZ
);
CREATE TABLE shopping_list_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  list_id UUID NOT NULL REFERENCES shopping_lists(id) ON DELETE CASCADE,
  item TEXT NOT NULL,
  quantity TEXT,
  notes TEXT,
  is_purchased BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

## API
- `POST /api/v1/shopping-lists` (create)
- `GET /api/v1/shopping-lists` (list)
- `POST /api/v1/shopping-lists/:id/items` (add item)
- `POST /api/v1/shopping-lists/:id/whatsapp-format` (returns formatted text for whatsapp:// share)

## SOP
**Tests (15)**: CRUD; sync via BE-44 idempotency; archive workflow; whatsapp formatting; max 100 items per list; tenant scope on items; item ordering; share link format follows wa.me URL spec; concurrent edits; deletion soft; offline-edits sync; PostHog event on share; performance < 100ms; export-to-clipboard variant; pagination on items.

**Q&A (8)**: Future voice input integration plan? How does this evolve to grocery delivery (kirana integration)? Item normalization for analytics? Multi-language item input? OCR import from photo of paper list? How is family-shared list scoped? How do we prevent abuse of WhatsApp share for spam?

### Sign-off (standard).

---
**END OF BE-55**
