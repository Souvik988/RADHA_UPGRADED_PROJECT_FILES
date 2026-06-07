# Phase BE-50: Webhooks for Pro Tier

## Phase Metadata
- **Phase ID**: BE-50
- **Depends On**: BE-08 v2 (Pro tier check), BE-29 v2
- **Estimated Duration**: 2-3 days

## Goal
Per Req 52, deliver outbound webhooks to Pro_Plan tenants for key events. HMAC-SHA256 signed. Up to 5 endpoints per tenant. 5 retries with exponential backoff capped at 1 hour. Failed deliveries persisted 7 days for replay.

## Schema
```sql
CREATE TABLE webhook_endpoints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  secret BYTEA NOT NULL,                -- KMS-encrypted
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  events TEXT[] NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE webhook_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  endpoint_id UUID NOT NULL REFERENCES webhook_endpoints(id) ON DELETE CASCADE,
  event_name TEXT NOT NULL,
  payload JSONB NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending','succeeded','failed')),
  attempts INT NOT NULL DEFAULT 0,
  last_attempt_at TIMESTAMPTZ,
  next_retry_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days')
);
```

## Events
- `product.created`, `product.updated`
- `inventory.updated`
- `grn.posted`
- `task.completed`
- `scan_session.ended`

## Delivery
```typescript
async deliver(delivery: WebhookDelivery) {
  const sig = this.signHmacSha256(JSON.stringify(delivery.payload), delivery.endpoint.secret);
  try {
    const res = await fetch(delivery.endpoint.url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-Radha-Signature': sig, 'X-Radha-Event': delivery.eventName },
      body: JSON.stringify(delivery.payload),
      signal: AbortSignal.timeout(10_000),
    });
    if (res.ok) return this.markSucceeded(delivery.id);
    throw new Error(`HTTP ${res.status}`);
  } catch (e) {
    return this.scheduleRetry(delivery);
  }
}
```

## API
- `POST /api/v1/webhooks/endpoints` (Pro only)
- `GET /api/v1/webhooks/endpoints`
- `DELETE /api/v1/webhooks/endpoints/:id`
- `GET /api/v1/webhooks/deliveries?status=failed` (replay/list)
- `POST /api/v1/webhooks/deliveries/:id/replay`

## SOP
**Tests (15)**: HMAC-SHA256 verified; non-Pro tenant returns 402; 5-endpoint cap enforced; retries 5 times with exponential backoff; replay endpoint resends; failed deliveries kept 7 days; secrets KMS-encrypted; signature header present; idempotency via delivery ID; tenant-scoped reads; performance for 1000 deliveries/min; mTLS optional; webhook URL validation (no internal IPs); rate limit on incoming admin actions; PII scrubbing per event.

**Q&A (8)**: How to prevent SSRF (internal IP delivery)? Replay protection at receiver? When does a permanently-failing endpoint get auto-disabled? Customer-visible delivery dashboard? PCI/financial event scrubbing? mTLS adoption path? How does this interact with PostHog backfill? Scaling delivery worker?

### Sign-off (standard).

---
**END OF BE-50**
