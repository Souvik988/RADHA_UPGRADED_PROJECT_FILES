# Phase BE-34: Onboarding Self-Selection API

## Phase Metadata

- **Phase ID**: BE-34
- **Phase Name**: Onboarding Self-Selection API
- **Section**: Backend Execution — Identity v2
- **Depends On**: BE-06, BE-08, BE-09 (with v2 ADDENDUMS), BE-29
- **Blocks**: BE-35 (Business Activation Touchpoints)
- **Estimated Duration**: 2 days
- **Complexity**: Medium

## Goal

Implement the backend support for the single onboarding screen described in Req 26: a 2x3 grid of six tap-cards. The user picks one of `personal | business_owner | parent | pharmacy | institution | auditor_invited`. The backend persists the selection on the user, routes the user to the right post-onboarding flow, and emits an `onboarding_segment_selected` analytics event.

## Why This Phase Matters

- Mobile_App ships with industry-grade Lottie + Flutter animation work (FE phase) — this phase delivers the exact API contract that screen needs.
- Captures the highest-leverage business-activation signal at signup (per the strategy session).
- Required input for Req 27 (Business Activation Touchpoints) and Req 13 (Trial Pro flow).

## Prerequisites

- [ ] BE-06 (OTP) v2 complete — `bypassOnboarding` flag in JWT
- [ ] BE-08 (Roles) v2 complete — Consumer role is canonical
- [ ] BE-09 (Multi-tenancy) v2 complete — personal tenant bootstrap
- [ ] BE-29 (Analytics) v2 complete — PostHog SDK + locked event taxonomy

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/modules/onboarding/onboarding.module.ts` | Module wire |
| `server/src/modules/onboarding/controllers/onboarding.controller.ts` | API surface |
| `server/src/modules/onboarding/services/onboarding.service.ts` | Routing logic |
| `server/src/modules/onboarding/dto/select-segment.dto.ts` | Zod-validated DTO |
| `server/src/modules/onboarding/dto/onboarding-routing.dto.ts` | Response DTO |
| `server/src/modules/onboarding/types/segment.enum.ts` | Segment enum |
| `server/src/database/migrations/v2/2026XXXX_user_onboarding_segment.sql` | Schema change |
| `server/src/modules/onboarding/__tests__/onboarding.controller.spec.ts` | Controller tests |
| `server/src/modules/onboarding/__tests__/onboarding.service.spec.ts` | Service tests |

## Schema

```sql
ALTER TABLE users
  ADD COLUMN onboarding_segment TEXT
    CHECK (onboarding_segment IN ('personal','business_owner','parent','pharmacy','institution','auditor_invited')),
  ADD COLUMN onboarding_segment_selected_at TIMESTAMPTZ;
```

## Service Interface

```typescript
export type OnboardingSegment =
  | 'personal'
  | 'business_owner'
  | 'parent'
  | 'pharmacy'
  | 'institution'
  | 'auditor_invited';

export interface OnboardingRoutingDto {
  nextScreen:
    | 'consumer_home'
    | 'consumer_home_with_allergen_setup'
    | 'business_activation_flow'
    | 'auditor_invitation_token_entry';
  segment: OnboardingSegment;
  presetForBusinessActivation?: 'business_owner' | 'pharmacy' | 'institution';
  bypassedOnboarding: boolean;
}

export interface IOnboardingService {
  selectSegment(userId: string, segment: OnboardingSegment): Promise<OnboardingRoutingDto>;
}
```

## Implementation

```typescript
// onboarding.service.ts
@Injectable()
export class OnboardingService implements IOnboardingService {
  constructor(
    @InjectRepository(UserEntity) private readonly users: Repository<UserEntity>,
    private readonly events: EventEmitterService,
  ) {}

  async selectSegment(userId: string, segment: OnboardingSegment): Promise<OnboardingRoutingDto> {
    const user = await this.users.findOneByOrFail({ id: userId });
    if (user.onboarding_segment) {
      // Idempotent: re-selection allowed but routing target is recomputed
    }

    user.onboarding_segment = segment;
    user.onboarding_segment_selected_at = new Date();
    await this.users.save(user);

    await this.events.emit(userId, user.tenant_id, {
      name: 'onboarding_segment_selected',
      props: { segment },
    });

    return this.routeFor(segment);
  }

  private routeFor(segment: OnboardingSegment): OnboardingRoutingDto {
    switch (segment) {
      case 'personal':
        return { segment, nextScreen: 'consumer_home', bypassedOnboarding: false };
      case 'parent':
        return { segment, nextScreen: 'consumer_home_with_allergen_setup', bypassedOnboarding: false };
      case 'business_owner':
      case 'pharmacy':
      case 'institution':
        return {
          segment,
          nextScreen: 'business_activation_flow',
          presetForBusinessActivation: segment,
          bypassedOnboarding: false,
        };
      case 'auditor_invited':
        return { segment, nextScreen: 'auditor_invitation_token_entry', bypassedOnboarding: false };
    }
  }
}
```

## Controller

```typescript
@Controller('/api/v1/onboarding')
@UseGuards(JwtAuthGuard)
export class OnboardingController {
  constructor(private readonly onboarding: OnboardingService) {}

  @Post('/segment')
  @HttpCode(200)
  async selectSegment(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: SelectSegmentDto,
  ): Promise<OnboardingRoutingDto> {
    return this.onboarding.selectSegment(user.id, dto.segment);
  }
}
```

## DTO

```typescript
import { z } from 'zod';
import { createZodDto } from '@anatine/zod-nestjs';

const SelectSegmentSchema = z.object({
  segment: z.enum(['personal', 'business_owner', 'parent', 'pharmacy', 'institution', 'auditor_invited']),
});

export class SelectSegmentDto extends createZodDto(SelectSegmentSchema) {}
```

## API Endpoints

| Method | Path | Description | Auth |
|---|---|---|---|
| POST | `/api/v1/onboarding/segment` | Persist user's segment selection and return next-screen routing | JWT |

### Request

```json
{ "segment": "business_owner" }
```

### Response 200

```json
{
  "segment": "business_owner",
  "nextScreen": "business_activation_flow",
  "presetForBusinessActivation": "business_owner",
  "bypassedOnboarding": false
}
```

### Errors

| Code | Reason |
|---|---|
| 400 | Invalid segment value |
| 401 | Missing/invalid JWT |
| 409 | Cannot re-select after Business_Activation completed |

## Mandatory Testing / Q&A SOP

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | POST with valid `personal` returns `nextScreen='consumer_home'` |
| T2 | POST with valid `parent` returns `nextScreen='consumer_home_with_allergen_setup'` |
| T3 | POST with `business_owner` returns `nextScreen='business_activation_flow'` and preset matches |
| T4 | POST with `pharmacy` returns business preset = `pharmacy` |
| T5 | POST with `institution` returns business preset = `institution` |
| T6 | POST with `auditor_invited` returns `nextScreen='auditor_invitation_token_entry'` |
| T7 | POST with invalid segment returns 400 |
| T8 | POST without JWT returns 401 |
| T9 | DB column `onboarding_segment` is set to the chosen value |
| T10 | DB column `onboarding_segment_selected_at` is set to current timestamp |
| T11 | Analytics event `onboarding_segment_selected` is emitted with the segment |
| T12 | Idempotent: calling twice with same segment returns same routing |
| T13 | After Business_Activation completes, re-selecting `personal` returns 409 |
| T14 | Concurrent calls produce a single canonical write (no race) |
| T15 | The endpoint p95 latency under 200 RPS is < 200 ms |

### Q&A Questions (8)

1. How does the routing for `auditor_invited` differ from BE-06's pending-invitation auto-onboarding path?
2. How is the `bypassedOnboarding` flag in JWT (set by BE-06) related to whether this endpoint is ever called?
3. What is the correct response if a user hits this endpoint with the same segment twice within seconds?
4. How does the analytics event from this phase tie to the `business_mode_activated` event from BE-35?
5. Why is the segment stored on the `users` table rather than a separate `onboarding_history` table?
6. How does this endpoint interact with Notification_Preferences seeding?
7. How do we preserve historical segment choice when a user later changes mode from Consumer to Business?
8. What is the rollback procedure if a user accidentally selects the wrong segment after onboarding?

### Developer Sign-off

- [ ] All 15 tests pass
- [ ] All 8 Q&A answered in handoff
- [ ] Code reviewed
- [ ] Coverage > 90%

**Developer Signature**: ___________________________

### Reviewer Approval

- [ ] Routing logic reviewed
- [ ] Schema migration reviewed
- [ ] Analytics event reviewed
- [ ] No PII exposed in responses

**☐ APPROVED — Proceed to BE-35**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF BE-34 — DO NOT PROCEED WITHOUT APPROVAL**
