# File: PRODUCTION_CHECKLIST.md

# RADHA Production Readiness Checklist

## Frontend Readiness
- [ ] Flutter release build works for Android and iOS.
- [ ] Scanner permissions and fallback manual entry tested.
- [ ] Every screen has loading/empty/error/success states.
- [ ] Admin web has role-gated pages.

## Backend Readiness
- [ ] DTO validation on every route.
- [ ] Risky routes have rate limits.
- [ ] Controllers are thin.
- [ ] Business logic in services.
- [ ] DB access in repositories only.
- [ ] Logs redact PII.
- [ ] SMS/AI/AWS wrappers tested.

## Database Readiness
- [ ] All migrations run from empty DB.
- [ ] Required indexes exist.
- [ ] EXPLAIN plans reviewed for hot queries.
- [ ] Backup enabled.
- [ ] Restore drill complete.
- [ ] Connection pool configured.

## AWS Readiness
- [ ] S3 bucket private.
- [ ] Presigned URL flow works.
- [ ] CloudFront configured.
- [ ] RDS backups enabled.
- [ ] Secrets stored outside repo.
- [ ] IAM least privilege.

## SMS/AI Readiness
- [ ] OTP send/verify works.
- [ ] Abuse limits enabled.
- [ ] AI wrapper uses free-first defaults.
- [ ] OCR output requires user confirmation.
- [ ] Health scoring is rule-based and versioned.

## Launch Readiness
- [ ] Domain active.
- [ ] Privacy Policy and Terms published.
- [ ] Admin account provisioned.
- [ ] Demo tenant/store seeded.
- [ ] Monitoring alerts active.
- [ ] Rollback plan documented.
---

## 2026-05-15 Upgrade Patch: Added Production Checks

## Inventory and GRN Readiness
- [ ] GRN posting creates stock movements transactionally.
- [ ] Posted GRN cannot be silently edited.
- [ ] Stock cannot go negative without approved correction.
- [ ] Stock in/out requires reason, actor, store, product, and timestamp.
- [ ] Low-stock alerts open and resolve correctly.
- [ ] Inventory counts match stock movement history.
- [ ] Expiry-tracked stock is visible batch-wise.

## Subscription Readiness
- [ ] 3-month free trial start/end is stored per tenant.
- [ ] ₹49/₹99/₹199 plans are data-driven.
- [ ] Entitlement guard blocks expired or over-limit tenant access.
- [ ] Trial expiry messaging is clear in mobile app.
- [ ] Subscription events are append-only.

## Owner Dashboard Readiness
- [ ] Owner dashboard requires owner-only role.
- [ ] Tenant admins cannot access owner APIs.
- [ ] Website events, leads, app events, and subscription metrics are collected.
- [ ] Dashboard rollups load without scanning raw event tables.
- [ ] PII is minimized and logs redact sensitive identifiers.

## Marketing Website Readiness
- [ ] Pricing page explains trial and plans.
- [ ] Contact/demo form works.
- [ ] WhatsApp/contact clicks are tracked.
- [ ] Privacy Policy and Terms are published.
- [ ] App download CTA tracking works.

