import { DomainConflictException } from '@/common/errors/business.exception';
import { TrialService } from '@/modules/subscriptions/services/trial.service';
import { SubscriptionsService } from '@/modules/subscriptions/subscriptions.service';

import { TenantOnboardingService } from '../services/tenant-onboarding.service';
import type { TenantsRepository } from '../repositories/tenants.repository';

const fakeLogger = () => ({ info: jest.fn(), warn: jest.fn(), error: jest.fn(), debug: jest.fn() });

describe('TenantOnboardingService.validateSubdomain', () => {
  const buildSvc = (existing: { subdomain: string } | null): TenantOnboardingService => {
    const tenants = {
      findBySubdomain: jest.fn().mockResolvedValue(existing),
    } as unknown as TenantsRepository;
    return new TenantOnboardingService(
      {} as never,
      tenants,
      { logAction: jest.fn() } as never,
      {} as never,
      { startTrial: jest.fn() } as never,
      fakeLogger() as never,
    );
  };

  it.each(['admin', 'api', 'www', 'app', 'support', 'help', 'demo'])(
    'rejects reserved subdomain %s',
    async (sub) => {
      const result = await buildSvc(null).validateSubdomain(sub);
      expect(result.valid).toBe(false);
      expect(result.reason).toBe('Reserved subdomain');
    },
  );

  it('rejects an already-taken subdomain', async () => {
    const result = await buildSvc({ subdomain: 'taken' }).validateSubdomain('taken');
    expect(result.valid).toBe(false);
    expect(result.reason).toBe('Subdomain already taken');
  });

  it('accepts a fresh subdomain', async () => {
    const result = await buildSvc(null).validateSubdomain('fresh-shop');
    expect(result.valid).toBe(true);
  });
});

describe('TenantOnboardingService.onboard', () => {
  it('throws DomainConflictException for reserved subdomain before touching the DB', async () => {
    const tenants = {
      findBySubdomain: jest.fn().mockResolvedValue(null),
    } as unknown as TenantsRepository;
    const db = { transaction: jest.fn() };
    const svc = new TenantOnboardingService(
      db as never,
      tenants,
      { logAction: jest.fn() } as never,
      {} as never,
      { startTrial: jest.fn() } as never,
      fakeLogger() as never,
    );

    await expect(
      svc.onboard({
        businessName: 'X',
        subdomain: 'admin',
        ownerName: 'Y',
        email: 'a@b.com',
        mobile: '9876543210',
        storeName: 'S',
        country: 'IN',
      }),
    ).rejects.toBeInstanceOf(DomainConflictException);
    expect(db.transaction).not.toHaveBeenCalled();
  });
});

/**
 * Defect D9 regression guard — self-service onboarding must leave the
 * tenant with a trial subscription so `GET /subscriptions/status` resolves
 * (it 404'd before, breaking the mobile entitlement provider).
 *
 * Wires the *real* `TrialService` + `SubscriptionsService` facade over an
 * in-memory `tenant_subscriptions` store, so the onboard → status flow is
 * exercised end-to-end through the service layer without a database.
 */
describe('TenantOnboardingService.onboard → trial subscription (D9)', () => {
  const TENANT_ID = '00000000-0000-0000-0000-0000000000aa';
  const OWNER_ID = '00000000-0000-0000-0000-0000000000bb';
  const STORE_ID = '00000000-0000-0000-0000-0000000000cc';
  const TRIAL_DAYS = 90;

  const baseDto = (overrides: Record<string, unknown> = {}) => ({
    businessName: 'Fresh Mart',
    subdomain: 'fresh-mart',
    ownerName: 'Asha',
    email: 'asha@example.com',
    mobile: '9876543210',
    storeName: 'Fresh Mart HSR',
    country: 'IN',
    ...overrides,
  });

  const wire = (opts: { trialPlanMissing?: boolean } = {}) => {
    // In-memory tenant_subscriptions, keyed by tenantId.
    const subStore = new Map<string, Record<string, unknown>>();

    const subRepo = {
      findByTenant: jest.fn(async (tenantId: string) => subStore.get(tenantId) ?? null),
      create: jest.fn(async (data: Record<string, unknown>) => {
        const row = { id: 'sub-1', ...data };
        subStore.set(data.tenantId as string, row);
        return row;
      }),
    };

    const plansRepo = {
      findByCode: jest.fn(async (code: string) =>
        code === 'trial' && !opts.trialPlanMissing
          ? { id: 'plan-trial', code: 'trial', trialDays: TRIAL_DAYS }
          : null,
      ),
      findById: jest.fn(async (id: string) => ({ id, code: 'trial', trialDays: TRIAL_DAYS })),
    };

    const eventsRepo = { create: jest.fn().mockResolvedValue(undefined) };
    const subAudit = { logAction: jest.fn().mockResolvedValue(undefined) };
    const logger = fakeLogger();

    // Real trial lifecycle service over the in-memory repos.
    const trial = new TrialService(
      subRepo as never,
      plansRepo as never,
      eventsRepo as never,
      subAudit as never,
      logger as never,
    );

    // Real facade; getStatus only touches subRepo, plansRepo, trial,
    // entitlement.getCurrentUsage and plan.attachEntitlements.
    const planSvc = {
      attachEntitlements: jest.fn(async (plan: Record<string, unknown>) => ({
        ...plan,
        features: [],
      })),
    };
    const entitlementSvc = { getCurrentUsage: jest.fn(async () => ({})) };
    const subscriptions = new SubscriptionsService(
      subRepo as never,
      plansRepo as never,
      eventsRepo as never,
      trial,
      {} as never, // upgrade — unused in this flow
      entitlementSvc as never,
      planSvc as never,
    );
    const startTrialSpy = jest.spyOn(subscriptions, 'startTrial');

    // Onboarding transaction — yields tenant, owner, store from the
    // ordered insert chain (the 4th insert, user_store_access, has no
    // `.returning()` and is simply awaited).
    const txMock = {
      insert: jest.fn().mockReturnValue({
        values: jest.fn().mockReturnValue({
          returning: jest
            .fn()
            .mockResolvedValueOnce([{ id: TENANT_ID, status: 'trial' }])
            .mockResolvedValueOnce([{ id: OWNER_ID }])
            .mockResolvedValue([{ id: STORE_ID }]),
        }),
      }),
    };
    const db = { transaction: jest.fn(async (cb: (tx: unknown) => unknown) => cb(txMock)) };
    const tenants = { findBySubdomain: jest.fn().mockResolvedValue(null) };
    const onboardAudit = { logAction: jest.fn().mockResolvedValue(undefined) };

    const onboarding = new TenantOnboardingService(
      db as never,
      tenants as never,
      onboardAudit as never,
      {} as never,
      subscriptions,
      logger as never,
    );

    return { onboarding, subscriptions, startTrialSpy, logger };
  };

  it('starts a trial so GET /subscriptions/status returns 200 with status "trial"', async () => {
    const { onboarding, subscriptions, startTrialSpy } = wire();

    const result = await onboarding.onboard(baseDto());

    // Trial started for the freshly-created tenant.
    expect(startTrialSpy).toHaveBeenCalledWith(TENANT_ID);
    // trialEndsAt now comes from the real subscription, not a fake +90d.
    expect(result.trialEndsAt).toBeInstanceOf(Date);

    // The previously-404ing status endpoint now resolves as a trial.
    const status = await subscriptions.getStatus(TENANT_ID);
    expect(status.status).toBe('trial');
    expect(status.isActive).toBe(true);
    expect(status.trialDaysRemaining).toBeGreaterThan(0);
  });

  it('stays non-fatal and logs if the trial subscription cannot be created', async () => {
    const { onboarding, subscriptions, logger } = wire({ trialPlanMissing: true });

    // Onboarding still succeeds (tenant/owner/store are already committed).
    const result = await onboarding.onboard(baseDto());
    expect(result.tenant.id).toBe(TENANT_ID);
    expect(result.trialEndsAt).toBeInstanceOf(Date); // computed fallback

    // The failure is surfaced via the logger rather than thrown.
    expect(logger.error).toHaveBeenCalledWith(
      'tenant.onboard.trial_start_failed',
      expect.objectContaining({ tenantId: TENANT_ID }),
    );

    // No subscription row was written, so status still 404s.
    await expect(subscriptions.getStatus(TENANT_ID)).rejects.toBeDefined();
  });
});
