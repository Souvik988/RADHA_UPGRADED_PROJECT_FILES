import { ConflictException, Injectable } from '@nestjs/common';

import { DbService } from '@/db/db.service';
import { stores, tenants, userStoreAccess } from '@/db/schema/tenants';
import { users } from '@/db/schema/users';
import { AuditLogService } from '@/observability/audit-log.service';
import { AppAnalyticsService } from '@/modules/analytics/services/app-analytics.service';
import { SubscriptionsService } from '@/modules/subscriptions/subscriptions.service';
import { eq } from 'drizzle-orm';

import type { ActivateBusinessDto } from '../dto/activate-business.dto';

/**
 * BE-35 — Business Activation Service.
 *
 * Upgrades a Consumer to Owner role by creating a business tenant,
 * first store, and optionally starting a Trial Pro subscription.
 * Everything runs in a single DB transaction.
 */
export interface ActivateBusinessInput extends ActivateBusinessDto {
  userId: string;
}

export interface ActivateBusinessResult {
  newRole: 'owner';
  newTenantId: string;
  newStoreId: string;
  trialStarted: boolean;
  trialEndsAt?: string;
}

@Injectable()
export class BusinessActivationService {
  constructor(
    private readonly db: DbService,
    private readonly subscriptions: SubscriptionsService,
    private readonly analytics: AppAnalyticsService,
    private readonly audit: AuditLogService,
  ) {}

  async activate(input: ActivateBusinessInput): Promise<ActivateBusinessResult> {
    const result = await this.db.transaction(async (tx) => {
      // 1. Verify user is a Consumer
      const [user] = await tx
        .select()
        .from(users)
        .where(eq(users.id, input.userId))
        .limit(1);

      if (!user) {
        throw new ConflictException('User not found');
      }
      if (user.role !== 'consumer') {
        throw new ConflictException('User is not a Consumer; cannot activate business.');
      }

      // 2. Create new business tenant
      const [tenant] = await tx
        .insert(tenants)
        .values({
          name: input.businessName,
          kind: 'business',
          status: 'active',
          plan: 'free',
        })
        .returning();

      // 3. Create the user's first Store under this tenant
      const [store] = await tx
        .insert(stores)
        .values({
          tenantId: tenant.id,
          name: input.storeName,
          code: 'STORE-001',
          type: input.preset === 'pharmacy' ? 'pharmacy' : 'retail',
          addressLine1: input.storeAddressLine1,
          city: input.storeCity,
          state: input.storeState,
          pincode: input.storePincode,
          createdBy: input.userId,
        })
        .returning();

      // 4. Grant owner access to the new store
      await tx.insert(userStoreAccess).values({
        userId: input.userId,
        storeId: store.id,
        accessLevel: 'admin',
        isActive: true,
        grantedBy: input.userId,
      });

      // 5. Upgrade user role to owner and link to new tenant
      await tx
        .update(users)
        .set({
          role: 'owner',
          tenantId: tenant.id,
          subscriptionTier: input.acceptTrialPro ? 'trial_pro' : 'free_consumer',
          onboardingSegment: input.preset ?? user.onboardingSegment,
        })
        .where(eq(users.id, input.userId));

      return { tenant, store };
    });

    // 6. Start Trial Pro (outside transaction since it uses its own sub-services)
    let trialStarted = false;
    let trialEndsAt: string | undefined;
    if (input.acceptTrialPro) {
      try {
        const trialSub = await this.subscriptions.startTrial(result.tenant.id);
        trialStarted = true;
        if (trialSub && 'currentPeriodEnd' in trialSub && trialSub.currentPeriodEnd) {
          trialEndsAt = (trialSub.currentPeriodEnd as Date).toISOString();
        }
      } catch {
        // Trial start failure is non-fatal; user still gets activated
        trialStarted = false;
      }
    }

    // 7. Emit analytics event
    try {
      await this.analytics.trackEvent(
        {
          eventType: 'feature_use',
          category: 'activation',
          action: 'business_activation',
          label: input.preset ?? 'unknown',
          metadata: {
            tenantId: result.tenant.id,
            storeId: result.store.id,
            trialStarted,
          },
        },
        input.userId,
        result.tenant.id,
      );
    } catch {
      // Analytics failure is non-fatal
    }

    // 8. Audit log
    await this.audit.logAction({
      action: 'CREATE',
      resourceType: 'Tenant',
      resourceId: result.tenant.id,
      userId: input.userId,
      tenantId: result.tenant.id,
      success: true,
      metadata: {
        event: 'business_mode_activated',
        storeId: result.store.id,
        preset: input.preset,
        trialStarted,
      },
    });

    return {
      newRole: 'owner',
      newTenantId: result.tenant.id,
      newStoreId: result.store.id,
      trialStarted,
      trialEndsAt,
    };
  }
}
