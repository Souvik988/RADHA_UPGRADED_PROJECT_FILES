# Phase BE-54: Daily Insights Job + Weekly Digest

## Phase Metadata
- **Phase ID**: BE-54
- **Depends On**: BE-24 v2 (FCM), BE-29 v2 (analytics), BE-12 v2 (comprehensive output)
- **Estimated Duration**: 2 days

## Goal
Per Req 47, weekly per-Consumer digest summarizing scans, savings, recall alerts, and recommended alternatives, delivered via FCM. Respects opt-out.

## Schema
```sql
CREATE TABLE consumer_weekly_digests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  week_starting DATE NOT NULL,
  scans_count INT NOT NULL,
  high_sugar_count INT NOT NULL,
  recall_count INT NOT NULL,
  alternatives_recommended INT NOT NULL,
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  delivered_at TIMESTAMPTZ,
  UNIQUE(user_id, week_starting)
);
```

## Cron
Sunday 08:00 IST → for each active Consumer, compute week-summary, persist row, send FCM (subject to Notification_Preferences).

## SOP
15 tests + 8 Q&A (similar pattern to BE-39 sweep).

### Sign-off (standard).

---
**END OF BE-54**
