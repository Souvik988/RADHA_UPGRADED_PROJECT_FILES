# Phase BE-28: Subscription & Entitlement Module

## Phase Metadata

- **Phase ID**: BE-28
- **Phase Name**: Subscription & Entitlement Module
- **Section**: Backend Execution — Business Operations Layer
- **Depends On**: BE-01 to BE-27
- **Blocks**: BE-29, BE-30, BE-31
- **Estimated Duration**: 2-3 days
- **Complexity**: Medium-High

## Goal

Build subscription management for SaaS monetization: 3-month free trial auto-creation, plan management (₹49 Starter / ₹99 Growth / ₹199 Pro), feature entitlements & limits, trial expiry handling, plan upgrade/downgrade, payment hooks (for future integration), and entitlement guards on API endpoints.

## Why This Phase Matters

This is **how RADHA makes money**:
- Free trial converts to paid subscribers
- Tiered plans (₹49/₹99/₹199)
- Feature gating drives upgrades
- Limits prevent abuse on free tier
- MRR tracking for business metrics
- Foundation for marketing automation

## Prerequisites

- [ ] BE-01 to BE-27 completed
- [ ] Tenants module (BE-09)
- [ ] Notifications (BE-24)
- [ ] AI usage tracking (BE-22)

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/subscription_plans.ts` | Plan definitions |
| `server/src/db/schema/plan_entitlements.ts` | Plan limits |
| `server/src/db/schema/tenant_subscriptions.ts` | Active subscriptions |
| `server/src/db/schema/subscription_events.ts` | Audit trail |
| `server/src/db/schema/payment_intents.ts` | Payment tracking (stub) |
| `server/src/modules/subscriptions/subscriptions.module.ts` | Module |
| `server/src/modules/subscriptions/subscriptions.controller.ts` | Endpoints |
| `server/src/modules/subscriptions/subscriptions.service.ts` | Main service |
| `server/src/modules/subscriptions/services/plan.service.ts` | Plan management |
| `server/src/modules/subscriptions/services/trial.service.ts` | Trial logic |
| `server/src/modules/subscriptions/services/entitlement.service.ts` | Limit checks |
| `server/src/modules/subscriptions/services/upgrade.service.ts` | Plan changes |
| `server/src/modules/subscriptions/guards/entitlement.guard.ts` | API guard |
| `server/src/modules/subscriptions/decorators/require-entitlement.decorator.ts` | Decorator |
| `server/src/modules/subscriptions/repositories/plans.repository.ts` | Data |
| `server/src/modules/subscriptions/repositories/subscriptions.repository.ts` | Data |
| `server/src/modules/subscriptions/dto/create-subscription.dto.ts` | DTOs |
| `server/src/modules/subscriptions/dto/upgrade-plan.dto.ts` | DTOs |
| `server/src/modules/subscriptions/types/subscription.types.ts` | Types |
| `server/src/modules/subscriptions/constants/default-plans.ts` | Plans |
| `server/src/jobs/cron/subscription-renewal.cron.ts` | Renewal cron |
| `server/src/jobs/cron/trial-expiry.cron.ts` | Trial cron |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/subscriptions/subscriptions.service.ts

export interface ISubscriptionsService {
  // Lifecycle
  startTrial(tenantId: string): Promise<TenantSubscription>;
  upgradeToPlan(tenantId: string, planCode: string, userId: string): Promise<TenantSubscription>;
  cancel(tenantId: string, reason: string, userId: string): Promise<TenantSubscription>;
  reactivate(tenantId: string, userId: string): Promise<TenantSubscription>;
  
  // Queries
  getCurrentSubscription(tenantId: string): Promise<TenantSubscriptionWithPlan | null>;
  getStatus(tenantId: string): Promise<SubscriptionStatusResult>;
  
  // Plans
  listPlans(): Promise<SubscriptionPlan[]>;
  getPlan(code: string): Promise<SubscriptionPlanWithEntitlements>;
  
  // Entitlements
  checkEntitlement(tenantId: string, feature: Feature): Promise<EntitlementCheck>;
  trackUsage(tenantId: string, feature: Feature, count: number): Promise<UsageResult>;
  getCurrentUsage(tenantId: string): Promise<UsageStats>;
  
  // Events
  recordEvent(dto: SubscriptionEventDto): Promise<void>;
}

export type SubscriptionStatus =
  | 'trial'
  | 'active'
  | 'expired'
  | 'cancelled'
  | 'past_due'
  | 'paused';

export type PlanCode = 'trial' | 'starter' | 'growth' | 'pro' | 'enterprise';

export type Feature =
  | 'stores'
  | 'users'
  | 'monthly_scans'
  | 'monthly_reports'
  | 'ean_lists'
  | 'ai_ocr'
  | 'ai_label_analysis'
  | 'llm_summaries'
  | 'rekognition'
  | 'priority_support'
  | 'custom_branding'
  | 'api_access'
  | 'advanced_analytics';

export interface SubscriptionPlan {
  id: string;
  code: PlanCode;
  name: string;
  price: number;        // Monthly INR
  yearlyPrice?: number;
  currency: string;     // 'INR'
  trialDays: number;
  isPublic: boolean;
  isActive: boolean;
  features: PlanFeature[];
  description: string;
}

export interface PlanFeature {
  feature: Feature;
  limit: number | 'unlimited';
  description: string;
}

export interface TenantSubscription {
  id: string;
  tenantId: string;
  planId: string;
  planCode: PlanCode;
  status: SubscriptionStatus;
  
  // Dates
  trialStartedAt?: Date;
  trialEndsAt?: Date;
  currentPeriodStart: Date;
  currentPeriodEnd: Date;
  cancelledAt?: Date;
  
  // Billing
  monthlyAmount: number;
  nextBillingDate?: Date;
  paymentMethod?: string;
  
  metadata: Record<string, unknown>;
}

export interface EntitlementCheck {
  allowed: boolean;
  feature: Feature;
  currentUsage: number;
  limit: number | 'unlimited';
  remaining: number | 'unlimited';
  resetAt?: Date;
  reason?: string;
  upgradeRequired?: boolean;
  recommendedPlan?: PlanCode;
}

export interface UsageResult {
  feature: Feature;
  newUsage: number;
  limit: number | 'unlimited';
  remaining: number | 'unlimited';
  warningTriggered?: boolean;
}

export interface UsageStats {
  tenantId: string;
  period: { from: Date; to: Date };
  byFeature: Record<Feature, {
    used: number;
    limit: number | 'unlimited';
    percentageUsed: number;
  }>;
}

export interface SubscriptionStatusResult {
  isActive: boolean;
  status: SubscriptionStatus;
  plan: SubscriptionPlan;
  trialDaysRemaining?: number;
  daysUntilRenewal?: number;
  features: Record<Feature, boolean>;
  limits: Record<Feature, number | 'unlimited'>;
  usage: UsageStats;
}

export interface SubscriptionEventDto {
  tenantId: string;
  type: SubscriptionEventType;
  oldPlanCode?: PlanCode;
  newPlanCode?: PlanCode;
  amount?: number;
  metadata?: Record<string, unknown>;
}

export type SubscriptionEventType =
  | 'trial_started'
  | 'trial_extended'
  | 'plan_upgraded'
  | 'plan_downgraded'
  | 'subscription_renewed'
  | 'subscription_cancelled'
  | 'subscription_reactivated'
  | 'payment_succeeded'
  | 'payment_failed';
```

## Implementation Code

### 1. Default Plans

```typescript
// server/src/modules/subscriptions/constants/default-plans.ts

export const DEFAULT_PLANS = [
  {
    code: 'trial',
    name: 'Free Trial',
    price: 0,
    trialDays: 90, // 3 months
    isPublic: false,
    description: '3-month free trial with full features',
    features: [
      { feature: 'stores', limit: 1, description: '1 store' },
      { feature: 'users', limit: 5, description: '5 users' },
      { feature: 'monthly_scans', limit: 5000, description: '5,000 scans/month' },
      { feature: 'monthly_reports', limit: 20, description: '20 reports/month' },
      { feature: 'ean_lists', limit: 5, description: '5 EAN lists' },
      { feature: 'ai_ocr', limit: 1000, description: '1,000 AI OCR/month' },
      { feature: 'ai_label_analysis', limit: 50, description: '50 label scans/month' },
      { feature: 'llm_summaries', limit: 20, description: '20 AI summaries/month' },
      { feature: 'priority_support', limit: 0, description: 'Email support' },
      { feature: 'api_access', limit: 0, description: 'No API access' },
    ],
  },
  {
    code: 'starter',
    name: 'Starter',
    price: 49,
    trialDays: 0,
    isPublic: true,
    description: 'For single-store retailers',
    features: [
      { feature: 'stores', limit: 1, description: '1 store' },
      { feature: 'users', limit: 5, description: '5 users' },
      { feature: 'monthly_scans', limit: 10000, description: '10,000 scans/month' },
      { feature: 'monthly_reports', limit: 50, description: '50 reports/month' },
      { feature: 'ean_lists', limit: 10, description: '10 EAN lists' },
      { feature: 'ai_ocr', limit: 2000, description: '2,000 AI OCR/month' },
      { feature: 'ai_label_analysis', limit: 100, description: '100 label scans/month' },
      { feature: 'llm_summaries', limit: 50, description: '50 AI summaries/month' },
      { feature: 'priority_support', limit: 0, description: 'Email support' },
      { feature: 'api_access', limit: 0, description: 'No API access' },
    ],
  },
  {
    code: 'growth',
    name: 'Growth',
    price: 99,
    trialDays: 0,
    isPublic: true,
    description: 'For multi-store businesses',
    features: [
      { feature: 'stores', limit: 5, description: 'Up to 5 stores' },
      { feature: 'users', limit: 20, description: '20 users' },
      { feature: 'monthly_scans', limit: 50000, description: '50,000 scans/month' },
      { feature: 'monthly_reports', limit: 200, description: '200 reports/month' },
      { feature: 'ean_lists', limit: 50, description: '50 EAN lists' },
      { feature: 'ai_ocr', limit: 10000, description: '10,000 AI OCR/month' },
      { feature: 'ai_label_analysis', limit: 500, description: '500 label scans/month' },
      { feature: 'llm_summaries', limit: 200, description: '200 AI summaries/month' },
      { feature: 'priority_support', limit: 1, description: 'Priority email + chat' },
      { feature: 'advanced_analytics', limit: 1, description: 'Advanced analytics' },
      { feature: 'api_access', limit: 0, description: 'No API access' },
    ],
  },
  {
    code: 'pro',
    name: 'Pro',
    price: 199,
    trialDays: 0,
    isPublic: true,
    description: 'For chains and enterprises',
    features: [
      { feature: 'stores', limit: 'unlimited' as const, description: 'Unlimited stores' },
      { feature: 'users', limit: 'unlimited' as const, description: 'Unlimited users' },
      { feature: 'monthly_scans', limit: 'unlimited' as const, description: 'Unlimited scans' },
      { feature: 'monthly_reports', limit: 'unlimited' as const, description: 'Unlimited reports' },
      { feature: 'ean_lists', limit: 'unlimited' as const, description: 'Unlimited EAN lists' },
      { feature: 'ai_ocr', limit: 'unlimited' as const, description: 'Unlimited AI OCR' },
      { feature: 'ai_label_analysis', limit: 5000, description: '5,000 label scans/month' },
      { feature: 'llm_summaries', limit: 1000, description: '1,000 AI summaries/month' },
      { feature: 'rekognition', limit: 1, description: 'AWS Rekognition enabled' },
      { feature: 'priority_support', limit: 1, description: 'Phone + WhatsApp support' },
      { feature: 'advanced_analytics', limit: 1, description: 'Full analytics suite' },
      { feature: 'custom_branding', limit: 1, description: 'White-label branding' },
      { feature: 'api_access', limit: 1, description: 'Full API access' },
    ],
  },
];
```

### 2. Subscription Plans Schema

```typescript
// server/src/db/schema/subscription_plans.ts
import { pgTable, varchar, uuid, integer, decimal, boolean, jsonb, index, unique } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const subscriptionPlans = pgTable(
  'subscription_plans',
  {
    ...baseColumns,
    code: varchar('code', { length: 30 }).notNull().unique(),
    name: varchar('name', { length: 100 }).notNull(),
    description: varchar('description', { length: 1000 }),
    
    // Pricing
    price: decimal('price', { precision: 10, scale: 2 }).notNull(),
    yearlyPrice: decimal('yearly_price', { precision: 10, scale: 2 }),
    currency: varchar('currency', { length: 3 }).notNull().default('INR'),
    
    // Trial
    trialDays: integer('trial_days').notNull().default(0),
    
    // Visibility
    isPublic: boolean('is_public').notNull().default(true),
    isActive: boolean('is_active').notNull().default(true),
    sortOrder: integer('sort_order').notNull().default(0),
    
    metadata: jsonb('metadata').default({}),
  },
);

export type SubscriptionPlan = typeof subscriptionPlans.$inferSelect;
```

### 3. Plan Entitlements Schema

```typescript
// server/src/db/schema/plan_entitlements.ts
import { pgTable, varchar, uuid, integer, jsonb, index, unique } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';
import { subscriptionPlans } from './subscription_plans';

export const planEntitlements = pgTable(
  'plan_entitlements',
  {
    ...baseColumns,
    planId: uuid('plan_id').notNull().references(() => subscriptionPlans.id, { onDelete: 'cascade' }),
    feature: varchar('feature', { length: 50 }).notNull(),
    limitValue: integer('limit_value'), // null = unlimited
    isUnlimited: boolean('is_unlimited').notNull().default(false),
    description: varchar('description', { length: 500 }),
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    planIdx: index('idx_entitlements_plan').on(table.planId),
    featureIdx: index('idx_entitlements_feature').on(table.feature),
    uniquePlanFeature: unique('uniq_plan_feature').on(table.planId, table.feature),
  }),
);

export type PlanEntitlement = typeof planEntitlements.$inferSelect;
```

### 4. Tenant Subscriptions Schema

```typescript
// server/src/db/schema/tenant_subscriptions.ts
import { pgTable, varchar, uuid, integer, decimal, timestamp, jsonb, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns, auditColumns } from './_base';

export const subscriptionStatusEnum = pgEnum('subscription_status', [
  'trial',
  'active',
  'expired',
  'cancelled',
  'past_due',
  'paused',
]);

export const tenantSubscriptions = pgTable(
  'tenant_subscriptions',
  {
    ...baseColumns,
    ...auditColumns,
    tenantId: uuid('tenant_id').notNull().unique(),
    planId: uuid('plan_id').notNull(),
    planCode: varchar('plan_code', { length: 30 }).notNull(),
    
    status: subscriptionStatusEnum('status').notNull().default('trial'),
    
    // Trial
    trialStartedAt: timestamp('trial_started_at', { withTimezone: true }),
    trialEndsAt: timestamp('trial_ends_at', { withTimezone: true }),
    
    // Billing period
    currentPeriodStart: timestamp('current_period_start', { withTimezone: true }).notNull(),
    currentPeriodEnd: timestamp('current_period_end', { withTimezone: true }).notNull(),
    
    // Cancellation
    cancelledAt: timestamp('cancelled_at', { withTimezone: true }),
    cancellationReason: varchar('cancellation_reason', { length: 500 }),
    
    // Billing
    monthlyAmount: decimal('monthly_amount', { precision: 10, scale: 2 }).notNull(),
    nextBillingDate: timestamp('next_billing_date', { withTimezone: true }),
    paymentMethod: varchar('payment_method', { length: 50 }),
    
    // Tracking
    lastPaymentAt: timestamp('last_payment_at', { withTimezone: true }),
    failedPaymentAttempts: integer('failed_payment_attempts').notNull().default(0),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    tenantIdx: index('idx_subscriptions_tenant').on(table.tenantId),
    statusIdx: index('idx_subscriptions_status').on(table.status),
    trialEndsIdx: index('idx_subscriptions_trial_ends').on(table.trialEndsAt),
    nextBillingIdx: index('idx_subscriptions_next_billing').on(table.nextBillingDate),
  }),
);

export type TenantSubscription = typeof tenantSubscriptions.$inferSelect;
```

### 5. Trial Service

```typescript
// server/src/modules/subscriptions/services/trial.service.ts
import { Injectable } from '@nestjs/common';
import { SubscriptionsRepository } from '../repositories/subscriptions.repository';
import { PlansRepository } from '../repositories/plans.repository';
import { DbService } from '../../../db/db.service';
import { LoggerService } from '../../../logging/logger.service';

@Injectable()
export class TrialService {
  constructor(
    private readonly db: DbService,
    private readonly subRepo: SubscriptionsRepository,
    private readonly planRepo: PlansRepository,
    private readonly logger: LoggerService,
  ) {}

  async startTrial(tenantId: string): Promise<TenantSubscription> {
    // Check if subscription already exists
    const existing = await this.subRepo.findByTenant(tenantId);
    if (existing) {
      throw new Error(`Subscription already exists for tenant ${tenantId}`);
    }
    
    const trialPlan = await this.planRepo.findByCode('trial');
    if (!trialPlan) throw new Error('Trial plan not configured');
    
    const now = new Date();
    const trialEndsAt = new Date(now);
    trialEndsAt.setDate(trialEndsAt.getDate() + trialPlan.trialDays);
    
    const subscription = await this.subRepo.create({
      tenantId,
      planId: trialPlan.id,
      planCode: 'trial',
      status: 'trial',
      trialStartedAt: now,
      trialEndsAt,
      currentPeriodStart: now,
      currentPeriodEnd: trialEndsAt,
      monthlyAmount: '0',
    });
    
    this.logger.info('Trial started', {
      tenantId,
      trialDays: trialPlan.trialDays,
      trialEndsAt,
    });
    
    return subscription;
  }

  async getDaysRemaining(tenantId: string): Promise<number> {
    const subscription = await this.subRepo.findByTenant(tenantId);
    if (!subscription || subscription.status !== 'trial') return 0;
    
    if (!subscription.trialEndsAt) return 0;
    
    const now = new Date();
    const ends = new Date(subscription.trialEndsAt);
    const diffMs = ends.getTime() - now.getTime();
    return Math.max(0, Math.ceil(diffMs / (1000 * 60 * 60 * 24)));
  }

  async expireTrials(): Promise<number> {
    // Called by cron daily
    const expiring = await this.subRepo.findExpiringTrials();
    
    let expired = 0;
    for (const sub of expiring) {
      await this.subRepo.update(sub.id, {
        status: 'expired',
        currentPeriodEnd: new Date(),
      });
      expired++;
    }
    
    return expired;
  }
}
```

### 6. Entitlement Service

```typescript
// server/src/modules/subscriptions/services/entitlement.service.ts
import { Injectable } from '@nestjs/common';
import { SubscriptionsRepository } from '../repositories/subscriptions.repository';
import { PlanEntitlementsRepository } from '../repositories/plan-entitlements.repository';
import { DbService } from '../../../db/db.service';
import { sql } from 'drizzle-orm';
import { aiUsageLog } from '../../../db/schema/ai_usage_log';
import { Feature, EntitlementCheck, UsageResult } from '../types/subscription.types';

@Injectable()
export class EntitlementService {
  constructor(
    private readonly db: DbService,
    private readonly subRepo: SubscriptionsRepository,
    private readonly entitlementsRepo: PlanEntitlementsRepository,
  ) {}

  async checkEntitlement(
    tenantId: string,
    feature: Feature,
  ): Promise<EntitlementCheck> {
    // Get current subscription
    const subscription = await this.subRepo.findByTenant(tenantId);
    if (!subscription || subscription.status === 'expired' || subscription.status === 'cancelled') {
      return {
        allowed: false,
        feature,
        currentUsage: 0,
        limit: 0,
        remaining: 0,
        reason: 'No active subscription',
        upgradeRequired: true,
      };
    }
    
    // Get entitlement
    const entitlement = await this.entitlementsRepo.findByPlanAndFeature(
      subscription.planId,
      feature,
    );
    
    if (!entitlement) {
      return {
        allowed: false,
        feature,
        currentUsage: 0,
        limit: 0,
        remaining: 0,
        reason: `Feature '${feature}' not in plan`,
        upgradeRequired: true,
      };
    }
    
    // Unlimited
    if (entitlement.isUnlimited) {
      return {
        allowed: true,
        feature,
        currentUsage: 0,
        limit: 'unlimited',
        remaining: 'unlimited',
      };
    }
    
    const limit = entitlement.limitValue || 0;
    
    // Get current usage
    const currentUsage = await this.getCurrentUsage(tenantId, feature);
    const remaining = Math.max(0, limit - currentUsage);
    
    return {
      allowed: currentUsage < limit,
      feature,
      currentUsage,
      limit,
      remaining,
      resetAt: this.getNextResetDate(),
      reason: currentUsage >= limit 
        ? `Monthly limit of ${limit} reached for ${feature}` 
        : undefined,
      upgradeRequired: currentUsage >= limit,
      recommendedPlan: this.getRecommendedPlan(subscription.planCode, feature),
    };
  }

  async trackUsage(
    tenantId: string,
    feature: Feature,
    count: number = 1,
  ): Promise<UsageResult> {
    const check = await this.checkEntitlement(tenantId, feature);
    
    if (!check.allowed && !this.isUsageFeature(feature)) {
      throw new Error(`Feature ${feature} not allowed`);
    }
    
    // Track in usage log (already exists from BE-22 for AI)
    // For non-AI features, use a generic usage table
    
    const newUsage = check.currentUsage + count;
    const limit = check.limit;
    const remaining = limit === 'unlimited' ? 'unlimited' : Math.max(0, limit - newUsage);
    
    return {
      feature,
      newUsage,
      limit,
      remaining,
      warningTriggered: limit !== 'unlimited' && newUsage >= (limit as number) * 0.8,
    };
  }

  async getCurrentUsage(tenantId: string, feature: Feature): Promise<number> {
    const yearMonth = new Date().toISOString().slice(0, 7);
    
    switch (feature) {
      case 'monthly_scans':
        return this.queryMonthlyScans(tenantId, yearMonth);
      case 'monthly_reports':
        return this.queryMonthlyReports(tenantId, yearMonth);
      case 'ai_ocr':
        return this.queryAiUsage(tenantId, yearMonth, 'ocr-expiry');
      case 'ai_label_analysis':
        return this.queryAiUsage(tenantId, yearMonth, 'label-analysis');
      case 'llm_summaries':
        return this.queryAiUsage(tenantId, yearMonth, 'report-summary');
      case 'stores':
        return this.queryStoreCount(tenantId);
      case 'users':
        return this.queryUserCount(tenantId);
      case 'ean_lists':
        return this.queryEanListCount(tenantId);
      default:
        return 0;
    }
  }

  private isUsageFeature(feature: Feature): boolean {
    return [
      'monthly_scans',
      'monthly_reports',
      'ai_ocr',
      'ai_label_analysis',
      'llm_summaries',
    ].includes(feature);
  }

  private getNextResetDate(): Date {
    const next = new Date();
    next.setMonth(next.getMonth() + 1);
    next.setDate(1);
    next.setHours(0, 0, 0, 0);
    return next;
  }

  private getRecommendedPlan(currentPlan: string, feature: Feature): any {
    // Suggest next tier
    const order = ['trial', 'starter', 'growth', 'pro'];
    const currentIdx = order.indexOf(currentPlan);
    return currentIdx < order.length - 1 ? order[currentIdx + 1] : null;
  }

  // Helper queries
  private async queryMonthlyScans(tenantId: string, yearMonth: string): Promise<number> {
    const result = await this.db.getDb().execute(sql`
      SELECT COUNT(*)::int as count
      FROM scan_items
      WHERE tenant_id = ${tenantId}
        AND TO_CHAR(scanned_at, 'YYYY-MM') = ${yearMonth}
    `);
    return Number(result.rows[0]?.count || 0);
  }

  private async queryMonthlyReports(tenantId: string, yearMonth: string): Promise<number> {
    const result = await this.db.getDb().execute(sql`
      SELECT COUNT(*)::int as count
      FROM reports
      WHERE tenant_id = ${tenantId}
        AND TO_CHAR(created_at, 'YYYY-MM') = ${yearMonth}
    `);
    return Number(result.rows[0]?.count || 0);
  }

  private async queryAiUsage(tenantId: string, yearMonth: string, operation: string): Promise<number> {
    const result = await this.db.getDb().execute(sql`
      SELECT COUNT(*)::int as count
      FROM ai_usage_log
      WHERE tenant_id = ${tenantId}
        AND year_month = ${yearMonth}
        AND operation = ${operation}
        AND success = 'true'
    `);
    return Number(result.rows[0]?.count || 0);
  }

  private async queryStoreCount(tenantId: string): Promise<number> {
    const result = await this.db.getDb().execute(sql`
      SELECT COUNT(*)::int as count
      FROM stores
      WHERE tenant_id = ${tenantId} AND deleted_at IS NULL
    `);
    return Number(result.rows[0]?.count || 0);
  }

  private async queryUserCount(tenantId: string): Promise<number> {
    const result = await this.db.getDb().execute(sql`
      SELECT COUNT(*)::int as count
      FROM users
      WHERE tenant_id = ${tenantId} AND deleted_at IS NULL AND is_active = true
    `);
    return Number(result.rows[0]?.count || 0);
  }

  private async queryEanListCount(tenantId: string): Promise<number> {
    const result = await this.db.getDb().execute(sql`
      SELECT COUNT(*)::int as count
      FROM ean_lists
      WHERE tenant_id = ${tenantId} AND deleted_at IS NULL
    `);
    return Number(result.rows[0]?.count || 0);
  }
}
```

### 7. Entitlement Guard

```typescript
// server/src/modules/subscriptions/guards/entitlement.guard.ts
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { EntitlementService } from '../services/entitlement.service';
import { REQUIRE_ENTITLEMENT_KEY } from '../decorators/require-entitlement.decorator';
import { BusinessException } from '../../../common/errors/business.exception';
import { ErrorCode } from '../../../common/errors/error-codes';

@Injectable()
export class EntitlementGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly entitlementService: EntitlementService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const feature = this.reflector.getAllAndOverride<string>(
      REQUIRE_ENTITLEMENT_KEY,
      [context.getHandler(), context.getClass()],
    );
    
    if (!feature) return true;
    
    const request = context.switchToHttp().getRequest();
    const tenantId = request.user?.tenantId;
    if (!tenantId) {
      throw new BusinessException(ErrorCode.AUTHENTICATION_REQUIRED, 'No tenant context');
    }
    
    const check = await this.entitlementService.checkEntitlement(
      tenantId,
      feature as any,
    );
    
    if (!check.allowed) {
      throw new BusinessException(
        check.upgradeRequired ? ErrorCode.PLAN_LIMIT_EXCEEDED : ErrorCode.SUBSCRIPTION_REQUIRED,
        check.reason || 'Feature not available in current plan',
        {
          metadata: {
            feature,
            currentUsage: check.currentUsage,
            limit: check.limit,
            recommendedPlan: check.recommendedPlan,
          },
        },
      );
    }
    
    return true;
  }
}
```

```typescript
// server/src/modules/subscriptions/decorators/require-entitlement.decorator.ts
import { SetMetadata } from '@nestjs/common';
import { Feature } from '../types/subscription.types';

export const REQUIRE_ENTITLEMENT_KEY = 'requireEntitlement';
export const RequireEntitlement = (feature: Feature) =>
  SetMetadata(REQUIRE_ENTITLEMENT_KEY, feature);
```

### 8. Trial Expiry Cron

```typescript
// server/src/jobs/cron/trial-expiry.cron.ts
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { TrialService } from '../../modules/subscriptions/services/trial.service';
import { NotificationsService } from '../../modules/notifications/notifications.service';
import { SubscriptionsRepository } from '../../modules/subscriptions/repositories/subscriptions.repository';

@Injectable()
export class TrialExpiryCron {
  private readonly logger = new Logger(TrialExpiryCron.name);

  constructor(
    private readonly trialService: TrialService,
    private readonly notifications: NotificationsService,
    private readonly subRepo: SubscriptionsRepository,
  ) {}

  // Run daily at 9 AM
  @Cron('0 9 * * *')
  async handleTrialExpiry(): Promise<void> {
    this.logger.log('Running trial expiry checks');
    
    // Notify users 7, 3, 1 days before trial ends
    for (const days of [7, 3, 1]) {
      const expiring = await this.subRepo.findTrialsExpiringIn(days);
      for (const sub of expiring) {
        // Send notification (BE-24)
        // notifications.sendTemplate('trial-expiring', ...)
      }
    }
    
    // Expire trials past trial_ends_at
    const expired = await this.trialService.expireTrials();
    this.logger.log(`Expired ${expired} trials`);
  }
}
```

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| GET | `/api/v1/subscriptions/plans` | Public | List public plans |
| GET | `/api/v1/subscriptions/status` | Bearer | Current status |
| GET | `/api/v1/subscriptions/usage` | Bearer | Current usage |
| POST | `/api/v1/subscriptions/upgrade` | Bearer | Upgrade plan |
| POST | `/api/v1/subscriptions/cancel` | Bearer | Cancel |
| POST | `/api/v1/subscriptions/reactivate` | Bearer | Reactivate |
| POST | `/api/v1/subscriptions/events` | System | Webhook for billing |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-29 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: New Tenant Auto-Trial ✅
Onboard tenant → trial created with 90 days
**Pass Criteria**: ✅ Auto-trial works

### Test 2: Trial Days Remaining ✅
Check 30 days into trial:
**Expected**: Returns 60 days remaining
**Pass Criteria**: ✅ Calculation correct

### Test 3: Trial Expiry Cron ✅
Run cron, expired trials marked:
**Pass Criteria**: ✅ Status changes to 'expired'

### Test 4: Entitlement Check — Allowed ✅
Trial user, scans count < 5000:
**Expected**: allowed=true
**Pass Criteria**: ✅ Within limit allowed

### Test 5: Entitlement Check — Limit Reached ✅
Scans = 5000, try to scan:
**Expected**: allowed=false, PLAN_LIMIT_EXCEEDED
**Pass Criteria**: ✅ Limits enforced

### Test 6: Unlimited Plan ✅
Pro plan user, 100k scans:
**Expected**: allowed=true (unlimited)
**Pass Criteria**: ✅ Unlimited works

### Test 7: Upgrade Plan ✅
Trial → Starter:
**Expected**: New limits applied immediately
**Pass Criteria**: ✅ Upgrade works

### Test 8: Downgrade Plan ✅
Pro → Growth:
**Expected**: Downgrade scheduled for end of billing cycle
**Pass Criteria**: ✅ No mid-cycle disruption

### Test 9: Feature Not in Plan ✅
Starter user requests API access:
**Expected**: SUBSCRIPTION_REQUIRED with recommended plan
**Pass Criteria**: ✅ Upgrade path suggested

### Test 10: Entitlement Guard ✅
Endpoint with @RequireEntitlement('api_access'):
Free trial user → 402
Pro user → 200
**Pass Criteria**: ✅ Guard enforces

### Test 11: Cancellation ✅
Cancel subscription:
**Expected**: Active until period end, then expired
**Pass Criteria**: ✅ Graceful cancellation

### Test 12: Trial Notifications ✅
7 days before expiry → notification sent
**Pass Criteria**: ✅ Trial expiring alerts

### Test 13: Usage Tracking ✅
Track scans, reports, AI calls:
**Expected**: Counters accurate
**Pass Criteria**: ✅ Usage tracked

### Test 14: 80% Warning ✅
Approaching limit:
**Expected**: warningTriggered=true at 80%
**Pass Criteria**: ✅ Pre-emptive warning

### Test 15: Plan Visibility ✅
Public can see public plans (Starter/Growth/Pro)
Trial plan hidden
**Pass Criteria**: ✅ Plan visibility correct

## 🎯 Q&A Session

### Q1: Why 3-month trial vs 14-day?
**Expected**: Indian SMB needs time to evaluate, longer commitment, better conversion data

### Q2: Why 3 paid tiers?
**Expected**: Anchor pricing, clear upgrade path, ₹49 entry, ₹199 ceiling

### Q3: Why feature gating vs full access?
**Expected**: Drives upgrades, controls costs (AI usage), business model

### Q4: How handle limit breaches?
**Expected**: Block + clear error + upgrade prompt, never silent failure

### Q5: Why cancel at period end?
**Expected**: User paid for period, fair, reduces refund disputes

### Q6: How does trial expiry work?
**Expected**: Cron checks daily, notifications 7/3/1 days before, then expires

### Q7: How to scale to 10K+ tenants?
**Expected**: Indexed queries, cache active subscriptions, async limit checks

### Q8: Future payment integration?
**Expected**: Razorpay/Stripe webhook → payment_intents → activate subscription

## 📝 Sign-Off Checklist

- [ ] All 15 tests pass
- [ ] Auto-trial works
- [ ] Limits enforced
- [ ] Upgrade/downgrade works
- [ ] Cron jobs running
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-29**
**☐ CHANGES REQUESTED**

---

**END OF BE-28 — DO NOT PROCEED WITHOUT APPROVAL**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-28 with the 4-tier subscription model, 14-day Trial Pro flow, ₹2 Trial_Verification_Charge, RBI_eMandate (UPI Autopay or e-NACH), and Family_Sharing entitlement propagation (Req 13, Req 33).**

## Driver Requirements

- **Req 13** — Tiers: Free_Consumer_Tier (₹0), Premium_Consumer_Tier (₹49/mo), Starter_Plan (₹49/mo, 1 store, 5 users, 5K scans/mo), Growth_Plan (₹99/mo), Pro_Plan (₹199/mo). Trial_Pro = 14 days full Pro features capped at Starter limits, requires payment method + ₹2 silent verification charge + RBI_eMandate setup. Auto-pay on day 14. Cancel anytime → no further charge after ₹2.
- **Req 33** — Family_Sharing: one Premium subscription covers up to 5 linked family member profiles, each with separate scan history and Allergen_Profile.

## Scope of Update

This phase already covers v1 subscription tiering and basic plan enforcement. v2 adds:

1. **New tier `premium_consumer`** with entitlements distinct from business tiers.
2. **New tier `trial_pro`** with explicit 14-day window and Pro features capped at Starter limits.
3. **Trial_Verification_Charge** flow: ₹2 charge via Razorpay/Cashfree, displayed as "₹0 Free Trial" in UI.
4. **RBI_eMandate establishment** at trial start (UPI Autopay or e-NACH).
5. **Auto-renewal trigger** at day 14 unless cancelled.
6. **Family_Sharing tables and entitlement propagation** so linked members get Premium without separate billing.
7. **Cancel-during-trial** path: stop further charges, keep ₹2 as-is, downgrade at day 14 to Free_Consumer_Tier.

## Files to Create / Modify

| File Path | Change |
|---|---|
| `server/src/modules/subscriptions/dto/tier.enum.ts` | Add `premium_consumer`, `trial_pro` |
| `server/src/modules/subscriptions/services/trial-pro.service.ts` | New — full trial lifecycle |
| `server/src/modules/subscriptions/services/payment-verification.service.ts` | New — ₹2 charge + e-mandate |
| `server/src/modules/subscriptions/services/family-sharing.service.ts` | New — invite/accept/remove/propagate |
| `server/src/modules/subscriptions/services/auto-renewal.service.ts` | New — cron-based day-14 trigger |
| `server/src/modules/subscriptions/integrations/razorpay.adapter.ts` | New |
| `server/src/modules/subscriptions/integrations/cashfree.adapter.ts` | New |
| `server/src/database/migrations/v2/2026XXXX_subscriptions_v2.sql` | New tables/columns |

## Schema

```sql
ALTER TABLE subscriptions
  ADD COLUMN tier TEXT NOT NULL CHECK (tier IN ('free_consumer','premium_consumer','trial_pro','starter','growth','pro')),
  ADD COLUMN trial_started_at TIMESTAMPTZ,
  ADD COLUMN trial_ends_at TIMESTAMPTZ,
  ADD COLUMN payment_method_token TEXT,
  ADD COLUMN payment_provider TEXT CHECK (payment_provider IN ('razorpay','cashfree')),
  ADD COLUMN emandate_reference TEXT,
  ADD COLUMN trial_verification_charge_paise INT,
  ADD COLUMN cancelled_at TIMESTAMPTZ;

CREATE TABLE family_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primary_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  member_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('pending','accepted','removed')),
  invited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  accepted_at TIMESTAMPTZ,
  removed_at TIMESTAMPTZ,
  UNIQUE(primary_user_id, member_user_id)
);

CREATE INDEX idx_family_links_primary ON family_links(primary_user_id) WHERE status='accepted';
```

## Trial Pro Lifecycle

```typescript
@Injectable()
export class TrialProService {
  async start(input: StartTrialInput): Promise<Subscription> {
    // 1. Validate user qualifies (no prior trial, business onboarding segment)
    await this.guards.assertEligible(input.userId);

    // 2. Establish payment method via provider
    const pm = await this.payments.collectMethod(input);

    // 3. Process ₹2 verification charge silently
    const charge = await this.payments.charge({
      userId: input.userId,
      amountPaise: 200,           // ₹2
      description: 'Trial verification',
      uiAmountDisplayed: 0,       // shown to user as "₹0"
    });

    // 4. Set up RBI_eMandate (UPI Autopay or e-NACH)
    const mandate = await this.payments.setupMandate({
      userId: input.userId,
      paymentMethod: pm,
      maxAmountPaise: 19_900,     // up to Pro_Plan price; user-confirmed cap
    });

    // 5. Create subscription with 14-day window
    return this.subscriptions.create({
      userId: input.userId,
      tier: 'trial_pro',
      trialStartedAt: new Date(),
      trialEndsAt: addDays(new Date(), 14),
      paymentMethodToken: pm.token,
      paymentProvider: pm.provider,
      emandateReference: mandate.reference,
      trialVerificationChargePaise: 200,
    });
  }

  async cancelDuringTrial(userId: string): Promise<void> {
    const sub = await this.subscriptions.findActive(userId);
    if (sub.tier !== 'trial_pro') throw new ConflictException('Not on trial');
    await this.payments.disableMandate(sub.emandateReference!);
    await this.subscriptions.update(sub.id, {
      cancelledAt: new Date(),
      // Keep tier='trial_pro' until trial_ends_at; auto-renewal cron will downgrade
    });
  }
}
```

## Auto-Renewal Cron

```typescript
@Cron(CronExpression.EVERY_HOUR)
async runAutoRenewal() {
  const expiring = await this.subscriptions.findTrialsEndingNow();
  for (const sub of expiring) {
    if (sub.cancelledAt) {
      await this.subscriptions.downgradeTo(sub.userId, 'free_consumer');
      continue;
    }
    try {
      await this.payments.chargeViaMandate(sub.emandateReference!, this.tierMonthlyPrice(sub.targetTier));
      await this.subscriptions.upgradeTo(sub.userId, sub.targetTier ?? 'starter');
    } catch (e) {
      await this.dunning.start(sub.userId);
    }
  }
}
```

## Family Sharing

```typescript
async invite(primaryUserId: string, mobile: string): Promise<FamilyLink> {
  const accepted = await this.repo.countAccepted(primaryUserId);
  if (accepted >= 5) throw new ConflictException('Family-sharing limit reached');
  // resolve or create invitee user, send FCM/SMS invite
  // create family_links row with status='pending'
}

async propagateEntitlements(primaryUserId: string): Promise<void> {
  const members = await this.repo.findAcceptedMembers(primaryUserId);
  for (const m of members) {
    await this.subscriptions.applyDerivedTier(m.memberUserId, 'premium_consumer', { derivedFrom: primaryUserId });
  }
}
```

## ADDENDUM v2 Test Procedures (add 7)

| # | Test |
|---|---|
| T-v2.1 | Trial start charges ₹2 and creates RBI mandate; UI sees `uiAmountDisplayed=0` |
| T-v2.2 | Day-14 cron upgrades active trials to `starter` (or chosen plan) via mandate |
| T-v2.3 | Cancel during trial → no further charge, downgrades to `free_consumer` at day 14 |
| T-v2.4 | Premium Consumer billing recurring monthly via mandate works end-to-end |
| T-v2.5 | Adding a 6th family member returns 409 Conflict |
| T-v2.6 | Removing primary user's subscription cascades and revokes all family member entitlements within 5 minutes |
| T-v2.7 | RBI e-mandate consent text is displayed at mandate setup (verified via integration test snapshot) |

## ADDENDUM v2 Q&A (add 4)

- **Q-v2.1**: What happens if Razorpay fails the ₹2 verification charge?
- **Q-v2.2**: How does the system handle a partial trial conversion (e.g., user on day 7 changes from `trial_pro → starter` voluntarily)?
- **Q-v2.3**: How are family-shared entitlements expressed in the JWT — is each member's JWT issued with `subscriptionTier='premium_consumer'` or with a derived flag?
- **Q-v2.4**: What is the dunning flow if mandate-charge fails on day 14?

## ADDENDUM v2 Sign-off

- [ ] All five tiers + trial_pro implemented
- [ ] ₹2 silent verification + e-mandate live
- [ ] Day-14 auto-renewal cron live and tested
- [ ] Family Sharing live with 5-member cap
- [ ] Cancel paths verified
- [ ] RBI compliance snapshot test in CI

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-28 ADDENDUM v2**
