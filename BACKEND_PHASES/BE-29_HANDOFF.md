# BE-29 Session Handoff: Analytics & Lead Ingestion

## Session Metadata
- **Phase ID**: BE-29
- **Phase Name**: Analytics & Lead Ingestion
- **Estimated Duration**: 2 days
- **Previous Phase**: BE-28 — Subscriptions
- **Next Phase**: BE-30 — Client In-App Dashboard API

## What Was Completed

### Files Created
- [ ] website_events, marketing_leads, app_usage_events tables
- [ ] owner_daily_metrics (pre-aggregated)
- [ ] WebsiteAnalyticsService
- [ ] AppAnalyticsService
- [ ] LeadsService
- [ ] OwnerMetricsAggregatorService (cron)
- [ ] FunnelService
- [ ] All repositories and DTOs

### Features
- [ ] Public website event tracking (no auth)
- [ ] Privacy-respecting (hashed visitor IDs)
- [ ] Country-only geo (GDPR compliant)
- [ ] UTM tracking
- [ ] Lead capture with spam detection
- [ ] Lead status workflow
- [ ] Mobile app usage tracking
- [ ] Daily metrics aggregation (cron)
- [ ] MRR calculation
- [ ] DAU/MAU calculation
- [ ] Conversion funnels

### Tests
- [ ] 15 tests passing
- [ ] Privacy verified
- [ ] Aggregation idempotent
- [ ] Coverage > 85%

## What's Ready for BE-30

**Important Architecture Note**: BE-30 was originally "Owner Dashboard" but per user clarification, we're splitting it:

- **BE-30**: Client In-App Dashboard API (for tenants in mobile app)
- **BE-31**: App Owner Dashboard API (private web for app developer)

BE-29 provides data for both:
- Tenants see their own usage (in BE-30)
- App owner sees aggregated SaaS metrics (in BE-31)

## Known Issues
- **Debt**: Basic spam detection only
- **Debt**: No bot detection
- **Debt**: No A/B test tracking
- **Warning**: Privacy compliance must be thorough

## Context for BE-30
BE-30 will build:
- Client in-app dashboard APIs
- Tenant-scoped (only their data)
- Real-time KPIs for store owners
- Their team activity, scans, expiry, tasks

## Sign-off
- [ ] All 15 tests pass
- [ ] Privacy verified
- [ ] Aggregation works
- [ ] Ready for BE-30
