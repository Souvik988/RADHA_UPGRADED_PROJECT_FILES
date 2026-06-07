# Phase BE-46: Free-Tier Rate Limiting & Quotas

## Phase Metadata
- **Phase ID**: BE-46
- **Depends On**: BE-08 v2 (entitlements), BE-32 v2 (Redis)
- **Estimated Duration**: 1-2 days

## Goal
Implement Req 40. Per-User daily scan and saved-product quotas tracked in Redis with daily reset at 00:00 IST.

## Quota Table
| Tier | Scans/day | Saved Products | Notes |
|---|---|---|---|
| Free Consumer | 50 | 5 | Reset at 00:00 IST |
| Premium Consumer | ∞ | ∞ | Subject to Req 24 global rate limit (100 RPM) |
| Trial Pro | 5,000/month | ∞ | Starter limits |
| Starter | 5,000/month | ∞ | Plan limits |

## Service
```typescript
@Injectable()
export class RateLimitService {
  async checkAndIncrement(userId: string, kind: 'scan' | 'save'): Promise<RateLimitResult> {
    const ent = await this.entitlements.forUser(userId);
    const limit = kind === 'scan' ? ent.scansPerDay : ent.savedProductsLimit;
    if (limit === Number.POSITIVE_INFINITY) return { allowed: true };
    const key = `quota:${userId}:${kind}:${this.todayIST()}`;
    const count = await this.redis.incr(key);
    await this.redis.expire(key, this.secondsUntilMidnightIST());
    if (count > limit) return {
      allowed: false,
      quota: kind, limit, used: count, resetAt: this.midnightISTAsIso(),
    };
    return { allowed: true };
  }
}
```

## Guard
Applied to scan/save endpoints; on quota exceeded returns HTTP 429 with structured body.

## SOP
**Tests (15)**: Free consumer 51st scan in a day → 429; Premium has no limit; daily reset at 00:00 IST; reset survives Redis restart (acceptable: counters live in Redis only); Starter monthly limit enforced via separate counter; quota body includes resetAt; Mobile_App displays correct upgrade prompt; quota checked before any DB write; quota safe under concurrency (Redis INCR atomic); audit logged at exceed events; PostHog event `feature_locked_seen`; OPS alarm if Redis unavailable falls open or closed (decision logged); quota counters cleaned after expiration; tenant-aware (per user, not per device); offline-queued operations checked at sync time.

**Q&A (8)**: Redis unavailable — fail open or closed? How is monthly counter implemented vs daily? How does this interact with BE-44 sync (offline scans count toward today's quota)? How is the IST reset boundary computed? Performance impact of every endpoint hitting Redis? How are quota changes propagated mid-session? What is the overage policy for paying customers (soft cap)? Anti-abuse for shared accounts?

### Sign-off (standard).

---
**END OF BE-46**
