# Phase BE-36: Premium Consumer Tier + Family Sharing

## Phase Metadata
- **Phase ID**: BE-36
- **Depends On**: BE-08 v2, BE-28 v2
- **Blocks**: BE-37, BE-38, BE-40, BE-41, BE-42
- **Estimated Duration**: 2-3 days

## Goal
Ship the Premium_Consumer_Tier (₹49/mo) subscription and the Family Sharing feature (Req 33). Premium subscriptions are billed against the user's personal tenant via the RBI_eMandate established in BE-28 v2. Family Sharing entitlements are derived for up to 5 linked members.

## Files to Create
| File Path | Purpose |
|---|---|
| `server/src/modules/subscriptions/services/premium-consumer.service.ts` | Subscribe / cancel |
| `server/src/modules/subscriptions/services/family-sharing.service.ts` | Invite / accept / remove |
| `server/src/modules/subscriptions/controllers/premium-consumer.controller.ts` | API |
| `server/src/modules/subscriptions/controllers/family-sharing.controller.ts` | API |
| `server/src/modules/subscriptions/dto/premium-subscribe.dto.ts` | DTO |
| `server/src/modules/subscriptions/dto/family-invite.dto.ts` | DTO |

## Key Service

```typescript
@Injectable()
export class PremiumConsumerService {
  async subscribe(userId: string, paymentMethodToken: string): Promise<Subscription> {
    const mandate = await this.payments.setupMandate({
      userId, paymentMethodToken, maxAmountPaise: 4900,
    });
    const sub = await this.subs.create({
      userId, tier: 'premium_consumer',
      monthlyPricePaise: 4900,
      emandateReference: mandate.reference,
      nextRenewalAt: addDays(new Date(), 30),
    });
    await this.events.emit(userId, sub.tenantId, {
      name: 'subscription_purchased', props: { tier: 'premium_consumer', amount_paise: 4900 },
    });
    return sub;
  }

  async cancel(userId: string): Promise<void> {
    const sub = await this.subs.findActive(userId);
    await this.payments.disableMandate(sub.emandateReference!);
    await this.subs.update(sub.id, { cancelledAt: new Date(), cancelAtPeriodEnd: true });
    await this.familySharing.revokeAllDerivedFromPrimary(userId);
  }
}
```

## API
| Method | Path | Description |
|---|---|---|
| POST | `/api/v1/subscriptions/premium-consumer` | Subscribe (collects payment method) |
| DELETE | `/api/v1/subscriptions/premium-consumer` | Cancel at period end |
| POST | `/api/v1/family/invite` | Invite member by mobile |
| POST | `/api/v1/family/accept` | Accept an invitation |
| DELETE | `/api/v1/family/members/:id` | Remove member |
| GET | `/api/v1/family/members` | List members |

## Mandatory Testing/Q&A SOP
**Test Procedures (15)**: subscribe → mandate created; cancel → mandate disabled; family invite → SMS sent; accept → entitlements propagate; 6th member rejected with 409; remove → derived entitlement revoked within 5 min; primary cancel → all derived members downgrade; idempotent re-subscribe; renewal at day 30; failed mandate charge → dunning; concurrent invite race produces single row; member count enforced via DB constraint not just app; family members get separate scan history; family members get separate Allergen_Profile; OHS scoring unaffected.

**Q&A (8)**: How is JWT updated when subscription changes mid-session? How does the system handle a member who already has a Premium subscription before being invited? When primary user activates Business, do family members keep Premium? What happens if a family member uninstalls then reinstalls — is link preserved? How is the 5-member cap atomic under high concurrency? What is the dunning policy for failed Premium renewal? How does cancellation interact with currently-running Comprehensive scans? Can a removed family member rejoin?

### Developer Sign-off / Reviewer Approval (standard format).

---
**END OF BE-36**
