# Phase BE-41: Healthy Alternatives + Affiliate Engine

## Phase Metadata
- **Phase ID**: BE-41
- **Depends On**: BE-10 v2 (scan endpoint), BE-12 v2 (comprehensive scoring), BE-29 v2 (analytics)
- **Estimated Duration**: 2-3 days

## Goal
Implement Req 35. `Healthy_Alternatives_Engine` selects up to 3 healthier alternatives per scanned product. `Affiliate_Engine` attaches affiliate links to Amazon/Flipkart with click tracking and revenue aggregation in Owner Dashboard.

## Schema
```sql
CREATE TABLE affiliate_partners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  affiliate_id TEXT NOT NULL,
  link_template TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE affiliate_clicks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  source_product_ean TEXT NOT NULL,
  alternative_product_ean TEXT NOT NULL,
  partner_id UUID NOT NULL REFERENCES affiliate_partners(id),
  clicked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE affiliate_revenue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id UUID NOT NULL REFERENCES affiliate_partners(id),
  amount_paise INT NOT NULL,
  attributed_click_id UUID REFERENCES affiliate_clicks(id),
  reported_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

## Service
```typescript
async recommend(sourceEan: string, user: AuthenticatedUser): Promise<HealthierAlternativeDto[]> {
  const ent = this.entitlements.get(user);
  if (!ent.affiliateAlternatives) return [];
  const candidates = await this.products.findHealthierThan(sourceEan, { limit: 3 });
  return candidates.map(c => ({
    ean: c.ean, name: c.name, brand: c.brand,
    healthScore: c.healthScore,
    affiliateLink: this.affiliate.buildLink(c.ean, this.preferPartner(user)),
  }));
}
```

## API
| Method | Path | Description |
|---|---|---|
| GET | `/api/v1/products/:ean/alternatives` | Top 3 healthier alternatives |
| POST | `/api/v1/affiliate/clicks` | Track outbound click |
| POST | `/api/v1/affiliate/revenue` | Webhook from partners (HMAC-signed) |

## SOP
**Tests (15)**: returns top 3 by health-score delta, gated by entitlement, no recommendations if score delta < threshold, links contain affiliate ID, click endpoint logs row, revenue aggregation totals correctly per partner, BE-10 v2 endpoint returns alternatives slot populated, RLS-safe (clicks scoped per user), partner inactive → no link, fallback partner cycling, A/B test slot for partner selection, click events emitted to PostHog, multi-language alternative names, performance < 200ms, no PII in click row.

**Q&A (8)**: How does the scoring threshold avoid recommending nearly identical products? What is the legal disclosure for affiliate income (FTC-style)? How does revenue webhook authentication work? How are partner links rotated when affiliate IDs change? How do we comply with Amazon/Flipkart TOS? Can users disable seeing alternatives? How do we prevent click fraud? How does this engine evolve to ML-based recommendations later?

### Sign-off (standard).

---
**END OF BE-41**
