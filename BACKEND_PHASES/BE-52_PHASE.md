# Phase BE-52: RADHA Verified Badge

## Phase Metadata
- **Phase ID**: BE-52
- **Depends On**: BE-30 v2 (OHS), BE-28 v2 (Pro tier)
- **Estimated Duration**: 1-2 days

## Goal
Per Req 54, issue "RADHA Verified" badge to Pro_Plan tenants whose Operational_Health_Score >= 75 for 30 consecutive days. Revoke if < 70 for 7 consecutive days. Provide downloadable PNG/SVG assets. Public verification endpoint.

## Schema
```sql
CREATE TABLE radha_verified_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL UNIQUE REFERENCES tenants(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('issued','revoked')),
  issued_at TIMESTAMPTZ NOT NULL,
  last_score NUMERIC(5,2),
  revoked_at TIMESTAMPTZ,
  revoked_reason TEXT
);
```

## Daily Cron
```typescript
@Cron('0 3 * * *', { timeZone: 'Asia/Kolkata' })
async run() {
  for (const tenant of await this.tenants.proPlan()) {
    const last30 = await this.scores.last30Days(tenant.id);
    const last7 = last30.slice(-7);
    const badge = await this.repo.findOne({ where: { tenantId: tenant.id } });
    if (!badge && last30.every(s => s.total >= 75) && last30.length >= 30) {
      await this.issue(tenant.id);
    }
    if (badge?.status === 'issued' && last7.every(s => s.total < 70) && last7.length >= 7) {
      await this.revoke(tenant.id, 'OHS below 70 for 7 days');
    }
  }
}
```

## API
- `GET /api/v1/badges/me` (tenant fetches its badge status + downloadable assets)
- `GET /api/v1/verify/{tenant_slug}` (public verification)

## SOP
**Tests (15)**: badge issued at 30-day eligibility; badge revoked at 7-day breach; revoked badge can be re-issued after re-eligibility; only Pro plan eligible; non-Pro returns no badge; PNG/SVG download URLs valid; verify endpoint public-readable; FCM + email on issue/revoke; OHS algorithm version compatibility (Req 29); idempotent issue (no duplicate); audit logged; cache 1h on verify endpoint; multi-store handling (per tenant, not per store); tenant slug uniqueness; deletion of tenant revokes badge.

**Q&A (8)**: How is tenant_slug generated? PII concerns for public verify? Rate limit on verify endpoint? Asset CDN strategy? Branding guidelines for badge use? Legal exposure of issuing badges? How are downgrades from Pro handled (immediate revoke)? When OHS algorithm version changes, does the badge persist?

### Sign-off (standard).

---
**END OF BE-52**
