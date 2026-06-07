# Phase BE-35: Business Activation Endpoint + Touchpoints

## Phase Metadata

- **Phase ID**: BE-35
- **Phase Name**: Business Activation Endpoint + Touchpoints
- **Section**: Backend Execution — Identity v2
- **Depends On**: BE-08 v2, BE-09 v2, BE-28 v2, BE-29 v2, BE-34
- **Blocks**: Mobile FE Business Activation flow
- **Estimated Duration**: 2-3 days
- **Complexity**: Medium-High

## Goal

Deliver the backend for Req 27 — `POST /api/v1/account/activate-business` plus the 7 touchpoint surfaces:
1. Onboarding self-selection (BE-34, already wired)
2. Smart banner after 5+ scans
3. Home screen card on Consumer home
4. Heavy-scan trigger at 50+ scans/week
5. Profile screen prominent CTA
6. Day-7 push notification (FCM via BE-24)
7. Limit-triggered prompt at 6th save attempt

The endpoint upgrades a Consumer to Owner role, creates a real business tenant + at least one Store, and emits `business_mode_activated` analytics event.

## Why This Phase Matters

This is the conversion engine. It protects the revenue funnel by surfacing business mode at multiple low-friction moments rather than burying it in Settings.

## Prerequisites

- [ ] BE-08 v2 (Consumer role + capabilities)
- [ ] BE-09 v2 (RLS, personal-tenant bootstrap)
- [ ] BE-28 v2 (Trial Pro flow, since activation can offer trial)
- [ ] BE-29 v2 (Analytics)
- [ ] BE-34 (Onboarding segment selection)
- [ ] BE-24 v2 (FCM channel for day-7 push)

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/modules/business-activation/business-activation.module.ts` | Module wire |
| `server/src/modules/business-activation/controllers/business-activation.controller.ts` | API |
| `server/src/modules/business-activation/services/business-activation.service.ts` | Activation logic |
| `server/src/modules/business-activation/services/touchpoint-rules.service.ts` | Touchpoint eligibility rules |
| `server/src/modules/business-activation/services/touchpoint-counter.service.ts` | Track scan counts/week |
| `server/src/modules/business-activation/dto/activate-business.dto.ts` | Zod DTO |
| `server/src/modules/business-activation/jobs/day7-push.job.ts` | Day-7 FCM cron |
| `server/src/modules/business-activation/__tests__/*` | Tests |

## Service Interfaces

```typescript
export interface ActivateBusinessInput {
  userId: string;
  businessName: string;            // 1..120 chars
  storeName: string;               // 1..120 chars
  storeAddressLine1?: string;
  storeCity?: string;
  storeState?: string;
  storePincode?: string;
  preset?: 'business_owner' | 'pharmacy' | 'institution';
  acceptTrialPro: boolean;         // If true, BE-28 trial flow is initiated
}

export interface ActivateBusinessResult {
  newRole: 'owner';
  newTenantId: string;
  newStoreId: string;
  trialStarted: boolean;
  trialEndsAt?: string;            // ISO date if trial started
}

export interface IBusinessActivationService {
  activate(input: ActivateBusinessInput): Promise<ActivateBusinessResult>;
}

export interface TouchpointEligibility {
  banner5Scans: boolean;
  homeCard: boolean;
  heavyScanWeekly: boolean;
  profileCta: boolean;
  saveLimitPrompt: boolean;
}

export interface ITouchpointRulesService {
  evaluate(userId: string): Promise<TouchpointEligibility>;
}
```

## Activation Logic

```typescript
@Injectable()
export class BusinessActivationService implements IBusinessActivationService {
  constructor(
    private readonly users: UsersRepository,
    private readonly tenants: TenantsRepository,
    private readonly stores: StoresRepository,
    private readonly subscriptions: SubscriptionsService,
    private readonly trialPro: TrialProService,
    private readonly events: EventEmitterService,
    @InjectDataSource() private readonly ds: DataSource,
  ) {}

  async activate(input: ActivateBusinessInput): Promise<ActivateBusinessResult> {
    return this.ds.transaction(async (tx) => {
      const user = await tx.getRepository(UserEntity).findOneByOrFail({ id: input.userId });
      if (user.role !== 'consumer') {
        throw new ConflictException('User is not a Consumer; cannot activate business.');
      }

      // 1. Create new business tenant
      const tenant = await tx.getRepository(TenantEntity).save({
        name: input.businessName,
        kind: 'business',
      });

      // 2. Create the user's first Store under this tenant
      const store = await tx.getRepository(StoreEntity).save({
        tenant_id: tenant.id,
        name: input.storeName,
        address_line_1: input.storeAddressLine1,
        city: input.storeCity,
        state: input.storeState,
        pincode: input.storePincode,
        preset: input.preset,
      });

      // 3. Migrate user role from consumer to owner under new tenant
      // The personal-tenant data stays on the original tenant; the user is now a member of both
      // (modelled as user_tenants junction; primary_tenant becomes the business one for business-mode UI)
      await tx.getRepository(UserTenantEntity).save({
        user_id: user.id,
        tenant_id: tenant.id,
        role: 'owner',
        is_primary: true,
      });
      await tx.getRepository(UserEntity).update(user.id, {
        role: 'owner',
        active_tenant_id: tenant.id,
      });

      // 4. Optionally start Trial Pro
      let trialStarted = false;
      let trialEndsAt: Date | undefined;
      if (input.acceptTrialPro) {
        const trial = await this.trialPro.start({ userId: user.id, tenantId: tenant.id });
        trialStarted = true;
        trialEndsAt = trial.trialEndsAt;
      } else {
        await this.subscriptions.assignFreeBaseline(tenant.id);
      }

      await this.events.emit(user.id, tenant.id, {
        name: 'business_mode_activated',
        props: { from_segment: input.preset ?? 'unknown' },
      });

      return {
        newRole: 'owner',
        newTenantId: tenant.id,
        newStoreId: store.id,
        trialStarted,
        trialEndsAt: trialEndsAt?.toISOString(),
      };
    });
  }
}
```

## Touchpoint Rules

```typescript
@Injectable()
export class TouchpointRulesService implements ITouchpointRulesService {
  async evaluate(userId: string): Promise<TouchpointEligibility> {
    const counts = await this.counter.snapshot(userId);
    return {
      banner5Scans: counts.totalScans >= 5,
      homeCard: true,           // always shown on Consumer home (Req 27.4)
      heavyScanWeekly: counts.scansThisWeek >= 50,
      profileCta: true,         // always shown on profile (Req 27.6)
      saveLimitPrompt: counts.savedProducts >= 5, // about to hit 6th
    };
  }
}
```

## Day-7 Push Job

```typescript
@Cron('0 9 * * *', { timeZone: 'Asia/Kolkata' })
async runDay7Push() {
  const candidates = await this.users.consumersLoggedInDailyForLast7Days();
  for (const user of candidates) {
    if (await this.alreadySent('business_activation_day7', user.id)) continue;
    await this.notifications.send({
      userId: user.id,
      category: 'business_activation',
      title: 'Running a shop or business?',
      body: 'Manage inventory, expiry, and scans in RADHA. Try the 14-day Pro trial.',
    });
    await this.markSent('business_activation_day7', user.id);
  }
}
```

## API Endpoint

```typescript
@Controller('/api/v1/account')
@UseGuards(JwtAuthGuard, RolesGuard)
export class BusinessActivationController {
  @Post('/activate-business')
  @Roles('consumer')             // Only Consumer can call this
  async activate(@CurrentUser() user: AuthenticatedUser, @Body() dto: ActivateBusinessDto) {
    return this.svc.activate({ userId: user.id, ...dto });
  }

  @Get('/touchpoints')
  async touchpoints(@CurrentUser() user: AuthenticatedUser): Promise<TouchpointEligibility> {
    return this.rules.evaluate(user.id);
  }
}
```

## Mandatory Testing / Q&A SOP

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Consumer activates business → role=`owner`, new tenant created, store created |
| T2 | Activation with `acceptTrialPro=true` → trial subscription created (BE-28 path) |
| T3 | Activation with `acceptTrialPro=false` → free baseline subscription |
| T4 | Already-Owner user calling activate-business → 409 |
| T5 | Touchpoints endpoint returns banner5Scans=false for user with <5 scans |
| T6 | After 5 scans, banner5Scans flips to true |
| T7 | After 50 weekly scans, heavyScanWeekly=true |
| T8 | At 5 saved products, saveLimitPrompt=true (about to hit 6th) |
| T9 | Day-7 push job sends FCM to qualifying users only once |
| T10 | Activation event lands in PostHog with correct preset label |
| T11 | Activation runs in a single DB transaction; rollback if any step fails |
| T12 | New tenant inherits PostgreSQL_RLS isolation (BE-09 v2) |
| T13 | Profile CTA always returns true regardless of scan count |
| T14 | Save-limit prompt does not fire for Premium Consumer (no save quota) |
| T15 | Activation with empty store/business name returns 400 |

### Q&A Questions (8)

1. How does the system handle a user who has many family-shared profiles when they activate business?
2. How are existing Consumer-tenant data (saved products, allergen profile) preserved when role changes to Owner?
3. What is the correct UX when a user fails the ₹2 verification charge during Trial Pro start?
4. How does the system avoid sending duplicate day-7 push notifications across timezone boundaries?
5. When activation fails partway through, what does the user see and what data is left behind?
6. How does the touchpoint scan-count counter handle offline-queued scans (BE-44 sync)?
7. Why is touchpoint evaluation a separate endpoint instead of being embedded in JWT?
8. How does this phase coordinate with BE-34's `presetForBusinessActivation` to avoid asking the user the same question twice?

### Developer Sign-off

- [ ] All 15 tests pass
- [ ] All 8 Q&A answered
- [ ] Coverage > 85%
- [ ] Day-7 cron tested in staging

**Developer Signature**: ___________________________

### Reviewer Approval

- [ ] Transaction integrity verified
- [ ] Tenant isolation verified
- [ ] Trial Pro path tested end-to-end
- [ ] Analytics event verified

**☐ APPROVED — Proceed to BE-36**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF BE-35 — DO NOT PROCEED WITHOUT APPROVAL**
