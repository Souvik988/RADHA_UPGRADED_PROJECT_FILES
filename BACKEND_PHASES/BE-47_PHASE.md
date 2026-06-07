# Phase BE-47: Feature Flags (Unleash/GrowthBook)

## Phase Metadata
- **Phase ID**: BE-47
- **Depends On**: BE-29 v2 (analytics)
- **Estimated Duration**: 2 days

## Goal
Per Req 48, integrate an open-source feature-flag service (Unleash or GrowthBook) for boolean flags, multivariate flags, and gradual rollout. Backend evaluates flags using a stable bucket key. Mobile_App applies new flag values within 5 minutes.

## Files
- `server/src/modules/feature-flags/feature-flags.module.ts`
- `server/src/modules/feature-flags/services/feature-flags.service.ts`
- `server/src/modules/feature-flags/providers/unleash.provider.ts`
- `server/src/modules/feature-flags/providers/growthbook.provider.ts`
- `server/src/modules/feature-flags/decorators/feature-flag.decorator.ts`

## Service
```typescript
@Injectable()
export class FeatureFlagsService {
  constructor(@Inject('FF_PROVIDER') private readonly provider: IFlagProvider, private readonly events: EventEmitterService) {}

  async isEnabled(flagName: string, user: AuthenticatedUser): Promise<boolean> {
    const variant = await this.provider.evaluate(flagName, this.bucketKey(user));
    await this.events.emit(user.id, user.tenantId, {
      name: 'feature_flag_evaluated' as any,
      props: { flag: flagName, variant },
    } as any);
    return variant === 'on';
  }

  async getVariant(flagName: string, user: AuthenticatedUser): Promise<string> {
    return this.provider.evaluate(flagName, this.bucketKey(user));
  }

  private bucketKey(user: AuthenticatedUser): string { return user.id; }
}
```

## SOP
**Tests (15)**: boolean flag returns expected value; multivariate returns one of allowed variants; gradual rollout 50% bucketing stable; provider down → returns default value + Sentry warn; new flag applied to Mobile within 5 min; flag changes emitted to PostHog; A/B test cohort persistence; per-tenant overrides supported; per-environment isolation (dev/staging/prod); flag cleanup audit; performance < 5ms cached evaluation; secure config (no flag values leaked to non-auth); rollback by global kill-switch; voice features behind a flag (Req 36 alignment); Trial Pro changes behind a flag.

**Q&A (8)**: Choose Unleash or GrowthBook? How are flags namespaced? Audit log for flag changes? How does this interact with the JWT-encoded subscription tier? Mobile caching strategy? Performance under high RPS? Test environment for flag evaluation? Compliance for A/B tests on minors?

### Sign-off (standard).

---
**END OF BE-47**
