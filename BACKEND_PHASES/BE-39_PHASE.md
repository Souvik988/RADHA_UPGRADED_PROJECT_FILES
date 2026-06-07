# Phase BE-39: Recall Alert Sweep + FSSAI Feed

## Phase Metadata
- **Phase ID**: BE-39
- **Depends On**: BE-24 v2 (FCM), BE-32 v2 (cache), BE-48 (Sentry)
- **Estimated Duration**: 2 days

## Goal
Implement Req 31 — daily `Recall_Sweep_Job` that fetches the FSSAI public recall feed (and any other configured government feeds), matches against every saved product, and pushes a notification per match.

## Files
- `server/src/modules/recall/recall.module.ts`
- `server/src/modules/recall/services/recall-sweep.service.ts`
- `server/src/modules/recall/services/recall-feed.service.ts`
- `server/src/modules/recall/jobs/recall-sweep.job.ts`
- `server/src/modules/recall/integrations/fssai-feed.adapter.ts`

## Schema
```sql
CREATE TABLE recall_feed_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source TEXT NOT NULL,            -- 'fssai' etc.
  ean TEXT,
  brand TEXT,
  product_name TEXT,
  batch_number TEXT,
  reason TEXT NOT NULL,
  recalled_at DATE NOT NULL,
  raw JSONB NOT NULL,
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_recall_feed_ean ON recall_feed_entries(ean);

CREATE TABLE recall_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  saved_product_id UUID REFERENCES saved_products(id) ON DELETE CASCADE,
  recall_feed_entry_id UUID NOT NULL REFERENCES recall_feed_entries(id),
  acknowledged_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, recall_feed_entry_id, saved_product_id)
);
ALTER TABLE recall_alerts ENABLE ROW LEVEL SECURITY;
```

## Cron
```typescript
@Cron('0 5 * * *', { timeZone: 'Asia/Kolkata' })
async runDailySweep() {
  const entries = await this.feed.fetchAll();
  for (const e of entries) {
    await this.recall.persistFeedEntry(e);
    const matches = await this.recall.findMatchingSavedProducts(e);
    for (const m of matches) {
      const alert = await this.recall.createAlert(m.userId, m.savedProductId, e.id);
      await this.notifications.send({
        userId: m.userId, category: 'recall_alert',
        title: 'Product Recall', body: `${e.product_name} has been recalled: ${e.reason}`,
        data: { alertId: alert.id },
      });
    }
  }
}
```

## SOP
**Tests (15)**: feed fetch retry up to 3 with backoff; Sentry alert on full failure; idempotent dedupe by (user, feed_entry, saved_product); FCM sent only if Notification_Preferences allow; cache 1h; cross-tenant matches not allowed; matches on EAN, brand+name fuzzy, batch number; backfill historical feed; performance for 100k saved products and 50 recalls; ack endpoint marks acknowledged_at; user can opt out of category; family sharing matches per linked member; deletion of saved product cascades alerts; pagination on list endpoint; SLO: full sweep completes within 10 min.

**Q&A (8)**: How are non-EAN matches scored? How do we avoid spamming users when many products are recalled? What are FSSAI's terms of use for the feed? Where is feed URL configured? How are feed schema changes handled? How does the system detect a feed-publisher format change? What is the rollback if a faulty feed entry is fetched? How are alerts for inactive users (haven't logged in for 30+ days) handled?

### Sign-off (standard).

---
**END OF BE-39**
