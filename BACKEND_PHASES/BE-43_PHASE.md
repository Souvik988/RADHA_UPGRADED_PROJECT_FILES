# Phase BE-43: Referral Program

## Phase Metadata
- **Phase ID**: BE-43
- **Depends On**: BE-08 v2, BE-28 v2, BE-29 v2
- **Estimated Duration**: 1-2 days

## Goal
Implement Req 42. Each user has a unique `referral_code`. New signups can use a code to grant 1 free month of Premium_Consumer to both inviter and invitee.

## Schema
```sql
ALTER TABLE users
  ADD COLUMN referral_code TEXT UNIQUE,
  ADD COLUMN referred_by_user_id UUID REFERENCES users(id);

CREATE TABLE referral_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  source_referral_user_id UUID NOT NULL REFERENCES users(id),
  reward_type TEXT NOT NULL DEFAULT 'premium_consumer_month',
  granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  applied_to_subscription_id UUID
);
```

## Service
```typescript
async applyReferralOnSignup(newUserId: string, code: string) {
  if (!code) return;
  const inviter = await this.users.findByReferralCode(code);
  if (!inviter || inviter.id === newUserId) return; // self-ref or invalid → silently no reward
  await this.users.update(newUserId, { referredByUserId: inviter.id });
  await this.grantOneMonthPremium(inviter.id, newUserId);
  await this.grantOneMonthPremium(newUserId, inviter.id);
}
```

## API
| Method | Path |
|---|---|
| GET | `/api/v1/referrals/me` (returns user's code + reward summary) |
| POST | `/api/v1/referrals/apply` (called during signup with `code`) |

## SOP
**Tests (15)**: unique code generation, self-ref rejected silently, invalid code rejected silently, reward grants 1 month to BOTH parties, business-tier inviter gets credit not discount, idempotent apply, abuse prevention (max 50 codes per IP/24h), code regeneration on demand, per-user cap on rewards (10/month), audit logged, PostHog events emitted, RLS-safe writes, SMS/FCM optional sharing link generation, deeplink format, fraud check via mobile-number duplicate detection.

**Q&A (8)**: How do we detect fraudulent self-refs across multiple devices? How is the code embedded in deeplinks? What is the FTC/India ASCI compliance for referral wording? How does the system handle a user who already has Premium when receiving a reward? How do we cap rewards if a user invites 1000 people? How does this interact with Trial Pro auto-conversion? How does cancellation interact with active rewards? How are referrals tracked in PostHog funnels?

### Sign-off (standard).

---
**END OF BE-43**
