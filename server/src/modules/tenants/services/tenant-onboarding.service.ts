import { Injectable } from '@nestjs/common';

import { DomainConflictException } from '@/common/errors/business.exception';
import { ErrorCode } from '@/common/errors/error-codes';
import { ConfigService } from '@/config/config.service';
import { DbService } from '@/db/db.service';
import { TenantRow, StoreRow, stores, tenants, userStoreAccess } from '@/db/schema/tenants';
import { UserRow, users } from '@/db/schema/users';
import { LoggerService } from '@/logging/logger.service';
import { SubscriptionsService } from '@/modules/subscriptions/subscriptions.service';
import { AuditLogService } from '@/observability/audit-log.service';

import { OnboardTenantDto } from '../dto/onboard-tenant.dto';
import { TenantsRepository } from '../repositories/tenants.repository';

const RESERVED_SUBDOMAINS = new Set([
  'admin',
  'api',
  'www',
  'app',
  'support',
  'help',
  'demo',
  'mail',
  'staging',
  'public',
]);

export interface OnboardingResult {
  tenant: TenantRow;
  owner: UserRow;
  store: StoreRow;
  trialEndsAt: Date;
}

/**
 * BE-09 self-service onboarding.
 *
 *   - Validates subdomain.
 *   - In a single transaction: creates tenant + owner + first store +
 *     user_store_access(admin).
 *   - After the transaction commits, starts the trial subscription via
 *     `SubscriptionsService.startTrial` (BE-28) so the tenant gets a
 *     `tenant_subscriptions` row and `GET /subscriptions/status`
 *     resolves (otherwise it 404s and the mobile entitlement provider
 *     breaks — defect D9). This mirrors how `business-activation`
 *     starts the trial *after* its own transaction, because the
 *     subscription repositories use the global pool rather than this
 *     onboarding `tx`.
 */
@Injectable()
export class TenantOnboardingService {
  constructor(
    private readonly db: DbService,
    private readonly tenants: TenantsRepository,
    private readonly audit: AuditLogService,
    private readonly _config: ConfigService,
    private readonly subscriptions: SubscriptionsService,
    private readonly logger: LoggerService,
  ) {}

  async validateSubdomain(subdomain: string): Promise<{ valid: boolean; reason?: string }> {
    if (RESERVED_SUBDOMAINS.has(subdomain)) {
      return { valid: false, reason: 'Reserved subdomain' };
    }
    const existing = await this.tenants.findBySubdomain(subdomain);
    if (existing) return { valid: false, reason: 'Subdomain already taken' };
    return { valid: true };
  }

  async onboard(dto: OnboardTenantDto): Promise<OnboardingResult> {
    const check = await this.validateSubdomain(dto.subdomain);
    if (!check.valid) {
      throw new DomainConflictException(
        check.reason ?? 'Subdomain unavailable',
        ErrorCode.DUPLICATE_RESOURCE,
        { metadata: { subdomain: dto.subdomain } },
      );
    }

    const result = await this.db.transaction(async (tx) => {
      const [tenant] = await tx
        .insert(tenants)
        .values({
          name: dto.businessName,
          kind: 'business',
          status: 'trial',
          subdomain: dto.subdomain,
          plan: 'trial',
          industry: dto.industry,
          country: dto.country,
          contactEmail: dto.email,
          contactMobile: dto.mobile,
        })
        .returning();

      const [owner] = await tx
        .insert(users)
        .values({
          tenantId: tenant.id,
          mobile: dto.mobile,
          email: dto.email,
          name: dto.ownerName,
          role: 'owner',
          subscriptionTier: 'trial_pro',
          isVerified: false,
          isActive: true,
        })
        .returning();

      const [store] = await tx
        .insert(stores)
        .values({
          tenantId: tenant.id,
          name: dto.storeName,
          code: 'STORE-001',
          type: 'retail',
          addressLine1: dto.storeAddress,
          city: dto.storeCity,
          state: dto.storeState,
          pincode: dto.storePincode,
          createdBy: owner.id,
        })
        .returning();

      await tx.insert(userStoreAccess).values({
        userId: owner.id,
        storeId: store.id,
        accessLevel: 'admin',
        isActive: true,
        grantedBy: owner.id,
      });

      return {
        tenant: tenant as TenantRow,
        owner: owner as UserRow,
        store: store as StoreRow,
      };
    });

    await this.audit.logAction({
      action: 'CREATE',
      resourceType: 'Tenant',
      resourceId: result.tenant.id,
      userId: result.owner.id,
      tenantId: result.tenant.id,
      success: true,
      metadata: { onboarding: true, subdomain: dto.subdomain },
    });

    // Start the trial subscription post-commit. A failure here is
    // non-fatal — the tenant/owner/store are already persisted, so we
    // log loudly (this is how a missing `trial` plan seed would surface)
    // and fall back to a computed trial-end date rather than orphaning
    // the onboarding response or leaving a half-created tenant.
    const fallbackTrialEndsAt = new Date(Date.now() + 90 * 24 * 60 * 60 * 1000);
    let trialEndsAt = fallbackTrialEndsAt;
    try {
      const subscription = await this.subscriptions.startTrial(result.tenant.id);
      trialEndsAt = subscription.trialEndsAt ?? subscription.currentPeriodEnd ?? fallbackTrialEndsAt;
    } catch (err) {
      this.logger.error('tenant.onboard.trial_start_failed', {
        tenantId: result.tenant.id,
        error: { name: (err as Error).name, message: (err as Error).message },
      });
    }

    return { ...result, trialEndsAt };
  }
}
