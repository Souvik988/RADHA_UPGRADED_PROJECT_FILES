# Phase BE-31: App Owner Dashboard API

## Phase Metadata

- **Phase ID**: BE-31
- **Phase Name**: App Owner Dashboard API
- **Section**: Backend Execution — Business Operations Layer
- **Depends On**: BE-01 to BE-30
- **Blocks**: BE-32, BE-33 (final hardening)
- **Estimated Duration**: 2-3 days
- **Complexity**: High
- **Priority**: HIGH (your business intelligence)

## Goal

Build the **App Owner's private dashboard API** — for YOU, the developer who built RADHA. This is a separate dashboard, accessed via a private Next.js web app. Shows aggregated SaaS metrics: business growth, revenue, marketing performance, user acquisition, retention, churn, AI cost monitoring. **Strictly admin-only**, with comprehensive audit logging. Does NOT expose tenant business data (only counts and metadata).

## Why This Phase Matters

This is YOUR business intelligence:
- See if RADHA is growing
- Track MRR, ARR, churn, LTV
- Monitor marketing campaigns
- Identify problem tenants (high support cost)
- Cost monitoring (AI, SMS, AWS)
- Make data-driven decisions
- Investor metrics

**Without this**: You're flying blind on your own business.

## Critical Privacy Boundary

The App Owner can see:
- ✅ Tenant names, contact info, subscription status
- ✅ Aggregate counts (X scans this month, Y reports generated)
- ✅ Marketing analytics (anonymous visitors)
- ✅ Business metrics (MRR, conversion, churn)
- ✅ Cost data (AI usage costs, SMS costs)

The App Owner CANNOT see:
- ❌ Actual product data of any tenant
- ❌ Specific scans, EAN lists, inventory items
- ❌ Specific tasks, GRN line items
- ❌ Customer scan content
- ❌ Personal data of tenant users (just counts)

**Even though the database stores everything, the API enforces this boundary.**

## Prerequisites

- [ ] BE-01 to BE-30 completed
- [ ] Owner role exists (BE-08)
- [ ] Owner daily metrics aggregation (BE-29)
- [ ] All data sources populated

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/owner_dashboard_access_log.ts` | Audit owner access |
| `server/src/modules/owner-dashboard/owner-dashboard.module.ts` | Module |
| `server/src/modules/owner-dashboard/owner-dashboard.controller.ts` | Endpoints |
| `server/src/modules/owner-dashboard/services/owner-overview.service.ts` | Main KPIs |
| `server/src/modules/owner-dashboard/services/saas-metrics.service.ts` | MRR, churn, LTV |
| `server/src/modules/owner-dashboard/services/tenant-management.service.ts` | Tenant list/details |
| `server/src/modules/owner-dashboard/services/marketing-analytics.service.ts` | Website + leads |
| `server/src/modules/owner-dashboard/services/cost-monitoring.service.ts` | AI/SMS/AWS costs |
| `server/src/modules/owner-dashboard/services/user-activity.service.ts` | DAU/MAU |
| `server/src/modules/owner-dashboard/services/subscription-analytics.service.ts` | Plans |
| `server/src/modules/owner-dashboard/guards/owner-only.guard.ts` | Access control |
| `server/src/modules/owner-dashboard/guards/owner-access-logger.guard.ts` | Audit |
| `server/src/modules/owner-dashboard/repositories/owner-access-log.repository.ts` | Logs |
| `server/src/modules/owner-dashboard/dto/dashboard-query.dto.ts` | DTOs |
| `server/src/modules/owner-dashboard/dto/tenant-search.dto.ts` | DTOs |
| `server/src/modules/owner-dashboard/types/owner-dashboard.types.ts` | Types |
| `server/src/modules/owner-dashboard/utils/data-redactor.utils.ts` | Privacy helpers |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/owner-dashboard/owner-dashboard.module.ts

export interface IOwnerOverviewService {
  // Main dashboard
  getOverview(dateRange: DateRange): Promise<OwnerOverview>;
  
  // Real-time stats
  getRealTimeStats(): Promise<RealTimeStats>;
  
  // Comparison metrics
  getPeriodComparison(currentRange: DateRange, previousRange: DateRange): Promise<PeriodComparison>;
}

export interface ISaasMetricsService {
  // Revenue metrics
  getMrr(date?: Date): Promise<MrrData>;
  getMrrGrowth(months: number): Promise<MrrGrowthData>;
  
  // Customer metrics
  getChurnRate(period: 'monthly' | 'quarterly'): Promise<ChurnData>;
  getCustomerLifetimeValue(): Promise<LtvData>;
  getNetRevenueRetention(): Promise<NrrData>;
  
  // Cohort analysis
  getCohortRetention(cohortMonth: string): Promise<CohortData>;
  
  // Conversion
  getTrialConversion(dateRange: DateRange): Promise<ConversionData>;
}

export interface ITenantManagementService {
  // Tenant list (with metadata only, NOT data)
  listTenants(filters: TenantSearchDto): Promise<PaginatedResult<TenantSummary>>;
  
  // Tenant detail (counts only, no actual content)
  getTenantSummary(tenantId: string): Promise<TenantSummary>;
  
  // Health monitoring
  getTenantHealth(tenantId: string): Promise<TenantHealth>;
  
  // Operations
  flagTenant(tenantId: string, reason: string, userId: string): Promise<void>;
  exportTenantData(tenantId: string, userId: string): Promise<string>; // GDPR
}

export interface IMarketingAnalyticsService {
  getWebsiteAnalytics(dateRange: DateRange): Promise<WebsiteAnalytics>;
  getFunnelAnalysis(dateRange: DateRange): Promise<FunnelAnalysis>;
  getCampaignPerformance(dateRange: DateRange): Promise<CampaignData[]>;
  getTrafficSources(dateRange: DateRange): Promise<TrafficSourceData[]>;
}

export interface ICostMonitoringService {
  getCurrentMonthCosts(): Promise<MonthlyCosts>;
  getCostTrends(months: number): Promise<CostTrendData>;
  getCostPerTenant(): Promise<TenantCost[]>;
  getCostBreakdown(category: 'ai' | 'sms' | 'aws' | 'all'): Promise<CostBreakdown>;
  getProfitability(): Promise<ProfitabilityData>;
}

// Types

export interface OwnerOverview {
  generatedAt: Date;
  
  // Quick KPIs
  kpis: {
    activeTenants: number;
    activeTenantsGrowth: number; // % vs last period
    mrr: number;
    mrrGrowth: number;
    newTenantsThisMonth: number;
    churnRate: number;
    averageRevenuePerUser: number;
  };
  
  // Trends (last 12 months)
  trends: {
    mrr: DataPoint[];
    activeTenants: DataPoint[];
    newTenants: DataPoint[];
    churnedTenants: DataPoint[];
  };
  
  // Plan distribution
  planDistribution: Array<{
    plan: string;
    count: number;
    revenue: number;
    percentage: number;
  }>;
  
  // Marketing
  marketing: {
    websiteVisitorsThisMonth: number;
    leadsThisMonth: number;
    conversionRate: number;
    topReferrers: Array<{ source: string; count: number }>;
  };
  
  // Costs
  costs: {
    thisMonth: number;
    lastMonth: number;
    aiCost: number;
    smsCost: number;
    awsCost: number;
    profitMargin: number;
  };
  
  // Health
  systemHealth: {
    apiUptime: number; // %
    avgResponseTime: number; // ms
    errorRate: number; // %
    activeAlerts: number;
  };
}

export interface RealTimeStats {
  currentActiveSessions: number;
  scansLastHour: number;
  apiRequestsPerMinute: number;
  errorsLastHour: number;
  newSignupsToday: number;
}

export interface MrrData {
  current: number;
  arr: number; // Annualized
  newMrr: number;
  expansionMrr: number;
  contractionMrr: number;
  churnedMrr: number;
  netNewMrr: number;
  asOfDate: Date;
}

export interface ChurnData {
  rate: number; // %
  voluntaryRate: number;
  involuntaryRate: number; // payment failures
  churnedTenants: number;
  churnedMrr: number;
  reasons: Array<{ reason: string; count: number }>;
}

export interface LtvData {
  averageLtv: number;
  byPlan: Record<string, number>;
  paybackPeriodDays: number;
  cacToLtvRatio: number;
}

export interface CohortData {
  cohortMonth: string;
  initialCount: number;
  retentionByMonth: number[]; // % retained at month 1, 2, 3...
}

export interface TenantSummary {
  id: string;
  name: string;
  subdomain: string;
  ownerName: string;
  ownerEmail: string;
  contactMobile: string;
  
  // Subscription
  planCode: string;
  status: string;
  trialEndsAt?: Date;
  monthlyAmount: number;
  signupDate: Date;
  lastLoginAt?: Date;
  
  // Aggregate usage (NO actual data)
  metrics: {
    storeCount: number;
    userCount: number;
    monthlyScans: number;
    monthlyReports: number;
    aiCallsThisMonth: number;
    storageUsedMb: number;
  };
  
  // Health indicators
  health: {
    score: number; // 0-100
    isAtRisk: boolean;
    daysSinceLastLogin: number;
    supportTicketCount: number;
    flagged: boolean;
  };
}

export interface TenantHealth {
  tenantId: string;
  overallScore: number;
  
  indicators: {
    paymentHealth: 'good' | 'warning' | 'critical';
    usageHealth: 'good' | 'warning' | 'critical';
    engagementHealth: 'good' | 'warning' | 'critical';
    supportHealth: 'good' | 'warning' | 'critical';
  };
  
  signals: Array<{
    type: 'positive' | 'negative';
    message: string;
    severity: 'low' | 'medium' | 'high';
  }>;
  
  recommendations: string[];
}

export interface MonthlyCosts {
  month: string;
  total: number;
  byCategory: {
    ai: number;
    sms: number;
    aws: { ec2: number; rds: number; s3: number; cloudfront: number; ses: number };
    other: number;
  };
  perTenantAverage: number;
  costToMrrRatio: number; // %
}

export interface ProfitabilityData {
  revenue: number;        // MRR * 12
  costs: number;          // Annualized costs
  grossProfit: number;
  grossMargin: number;    // %
  costPerUser: number;
  revenuePerUser: number;
  ltv: number;
  cac: number;
  paybackPeriodMonths: number;
}
```

## Implementation Code

### 1. Owner Access Log Schema

```typescript
// server/src/db/schema/owner_dashboard_access_log.ts
import { pgTable, varchar, uuid, timestamp, jsonb, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const ownerDashboardAccessLog = pgTable(
  'owner_dashboard_access_log',
  {
    ...baseColumns,
    userId: uuid('user_id').notNull(),
    
    action: varchar('action', { length: 100 }).notNull(),
    endpoint: varchar('endpoint', { length: 200 }).notNull(),
    method: varchar('method', { length: 10 }).notNull(),
    
    // Tenant accessed (if applicable)
    targetTenantId: uuid('target_tenant_id'),
    
    // Request details
    queryParams: jsonb('query_params'),
    
    // Response
    statusCode: varchar('status_code', { length: 5 }),
    durationMs: varchar('duration_ms', { length: 10 }),
    
    // Context
    ipAddress: varchar('ip_address', { length: 45 }),
    userAgent: varchar('user_agent', { length: 500 }),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    userIdx: index('idx_owner_access_user').on(table.userId),
    targetIdx: index('idx_owner_access_target').on(table.targetTenantId),
    createdIdx: index('idx_owner_access_created').on(table.createdAt),
  }),
);

export type OwnerAccessLog = typeof ownerDashboardAccessLog.$inferSelect;
```

### 2. Owner-Only Guard

```typescript
// server/src/modules/owner-dashboard/guards/owner-only.guard.ts
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ConfigService } from '../../../config/config.service';
import { ForbiddenException } from '../../../common/errors/business.exception';
import { ErrorCode } from '../../../common/errors/error-codes';

@Injectable()
export class OwnerOnlyGuard implements CanActivate {
  // Hardcoded list of owner user IDs (VERY restrictive)
  private readonly OWNER_USER_IDS: Set<string>;

  constructor(
    private readonly reflector: Reflector,
    private readonly config: ConfigService,
  ) {
    // Owner IDs from secure config (not exposed)
    const ids = this.config.get<string>('OWNER_USER_IDS') || '';
    this.OWNER_USER_IDS = new Set(ids.split(',').filter(Boolean));
  }

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    
    if (!user) {
      throw new ForbiddenException('Authentication required', ErrorCode.AUTHENTICATION_REQUIRED);
    }
    
    // CRITICAL: Multiple checks
    
    // 1. Must be admin role
    if (user.role !== 'admin') {
      throw new ForbiddenException(
        'Owner dashboard access requires admin role',
        ErrorCode.ROLE_REQUIRED,
      );
    }
    
    // 2. Must be in owner whitelist (extra security layer)
    if (!this.OWNER_USER_IDS.has(user.id)) {
      throw new ForbiddenException(
        'Access denied to owner dashboard',
        ErrorCode.INSUFFICIENT_PERMISSIONS,
      );
    }
    
    // 3. Must have specific permission
    if (!user.permissions?.includes('owner:dashboard')) {
      throw new ForbiddenException(
        'Owner dashboard permission required',
        ErrorCode.INSUFFICIENT_PERMISSIONS,
      );
    }
    
    return true;
  }
}
```

### 3. Owner Access Logger Guard

```typescript
// server/src/modules/owner-dashboard/guards/owner-access-logger.guard.ts
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { OwnerAccessLogRepository } from '../repositories/owner-access-log.repository';

@Injectable()
export class OwnerAccessLoggerGuard implements CanActivate {
  constructor(private readonly logRepo: OwnerAccessLogRepository) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    
    if (!user) return true; // Other guards will handle
    
    // Log the access (async, doesn't block)
    this.logRepo.create({
      userId: user.id,
      action: context.getHandler().name,
      endpoint: request.url,
      method: request.method,
      targetTenantId: request.params?.tenantId || request.query?.tenantId,
      queryParams: request.query,
      ipAddress: request.ip,
      userAgent: request.headers['user-agent'],
    }).catch(() => {
      // Logging failure should not block access
    });
    
    return true;
  }
}
```

### 4. Owner Overview Service

```typescript
// server/src/modules/owner-dashboard/services/owner-overview.service.ts
import { Injectable } from '@nestjs/common';
import { DbService } from '../../../db/db.service';
import { SaasMetricsService } from './saas-metrics.service';
import { MarketingAnalyticsService } from './marketing-analytics.service';
import { CostMonitoringService } from './cost-monitoring.service';
import { sql } from 'drizzle-orm';
import { OwnerOverview } from '../types/owner-dashboard.types';

@Injectable()
export class OwnerOverviewService {
  constructor(
    private readonly db: DbService,
    private readonly saasMetrics: SaasMetricsService,
    private readonly marketing: MarketingAnalyticsService,
    private readonly costs: CostMonitoringService,
  ) {}

  async getOverview(dateRange: any): Promise<OwnerOverview> {
    // Run all queries in parallel for performance
    const [
      kpis,
      trends,
      planDist,
      marketingData,
      costData,
      systemHealth,
    ] = await Promise.all([
      this.getKpis(dateRange),
      this.getTrends(),
      this.getPlanDistribution(),
      this.marketing.getWebsiteAnalytics(dateRange),
      this.costs.getCurrentMonthCosts(),
      this.getSystemHealth(),
    ]);
    
    return {
      generatedAt: new Date(),
      kpis,
      trends,
      planDistribution: planDist,
      marketing: {
        websiteVisitorsThisMonth: marketingData.totalVisitors,
        leadsThisMonth: marketingData.conversions.contactFormSubmissions,
        conversionRate: marketingData.totalVisitors > 0
          ? (marketingData.conversions.contactFormSubmissions / marketingData.totalVisitors) * 100
          : 0,
        topReferrers: [], // From marketing service
      },
      costs: {
        thisMonth: costData.total,
        lastMonth: 0, // Would calculate from history
        aiCost: costData.byCategory.ai,
        smsCost: costData.byCategory.sms,
        awsCost: 
          costData.byCategory.aws.ec2 +
          costData.byCategory.aws.rds +
          costData.byCategory.aws.s3 +
          costData.byCategory.aws.cloudfront,
        profitMargin: 0, // Calculated from MRR vs costs
      },
      systemHealth,
    };
  }

  private async getKpis(dateRange: any): Promise<any> {
    const db = this.db.getDb();
    
    // Active tenants
    const tenants = await db.execute(sql`
      SELECT 
        COUNT(*) FILTER (WHERE status = 'active' OR status = 'trial')::int as active,
        COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days')::int as new_this_month
      FROM tenant_subscriptions
    `);
    
    // MRR
    const mrr = await db.execute(sql`
      SELECT COALESCE(SUM(monthly_amount), 0)::numeric as mrr
      FROM tenant_subscriptions
      WHERE status = 'active'
    `);
    
    // Churn
    const churn = await db.execute(sql`
      SELECT COUNT(*)::int as churned
      FROM tenant_subscriptions
      WHERE status = 'cancelled'
        AND cancelled_at >= NOW() - INTERVAL '30 days'
    `);
    
    const activeTenants = Number((tenants.rows[0] as any)?.active || 0);
    const newThisMonth = Number((tenants.rows[0] as any)?.new_this_month || 0);
    const mrrValue = Number((mrr.rows[0] as any)?.mrr || 0);
    const churned = Number((churn.rows[0] as any)?.churned || 0);
    
    return {
      activeTenants,
      activeTenantsGrowth: 0, // Would compare to previous period
      mrr: mrrValue,
      mrrGrowth: 0,
      newTenantsThisMonth: newThisMonth,
      churnRate: activeTenants > 0 ? (churned / activeTenants) * 100 : 0,
      averageRevenuePerUser: activeTenants > 0 ? mrrValue / activeTenants : 0,
    };
  }

  private async getTrends(): Promise<any> {
    const db = this.db.getDb();
    
    const trends = await db.execute(sql`
      SELECT 
        date,
        mrr,
        active_tenants,
        new_tenants,
        cancelled_tenants
      FROM owner_daily_metrics
      WHERE date >= NOW() - INTERVAL '12 months'
      ORDER BY date ASC
    `);
    
    return {
      mrr: trends.rows.map((r: any) => ({ date: r.date, value: Number(r.mrr) })),
      activeTenants: trends.rows.map((r: any) => ({ date: r.date, value: Number(r.active_tenants) })),
      newTenants: trends.rows.map((r: any) => ({ date: r.date, value: Number(r.new_tenants) })),
      churnedTenants: trends.rows.map((r: any) => ({ date: r.date, value: Number(r.cancelled_tenants) })),
    };
  }

  private async getPlanDistribution(): Promise<any[]> {
    const db = this.db.getDb();
    
    const result = await db.execute(sql`
      SELECT 
        plan_code,
        COUNT(*)::int as count,
        SUM(monthly_amount)::numeric as revenue
      FROM tenant_subscriptions
      WHERE status = 'active'
      GROUP BY plan_code
      ORDER BY revenue DESC
    `);
    
    const total = result.rows.reduce((sum: number, r: any) => sum + Number(r.count), 0);
    
    return result.rows.map((r: any) => ({
      plan: r.plan_code,
      count: Number(r.count),
      revenue: Number(r.revenue || 0),
      percentage: total > 0 ? (Number(r.count) / total) * 100 : 0,
    }));
  }

  async getRealTimeStats(): Promise<any> {
    const db = this.db.getDb();
    
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    
    const [scans, errors, signups] = await Promise.all([
      db.execute(sql`
        SELECT COUNT(*)::int as count
        FROM scan_items
        WHERE scanned_at >= ${oneHourAgo}
      `),
      db.execute(sql`
        SELECT COUNT(*)::int as count
        FROM audit_logs
        WHERE success = false
          AND created_at >= ${oneHourAgo}
      `),
      db.execute(sql`
        SELECT COUNT(*)::int as count
        FROM tenants
        WHERE created_at >= CURRENT_DATE
      `),
    ]);
    
    return {
      currentActiveSessions: 0, // Would query Redis sessions
      scansLastHour: Number((scans.rows[0] as any)?.count || 0),
      apiRequestsPerMinute: 0, // Would query metrics
      errorsLastHour: Number((errors.rows[0] as any)?.count || 0),
      newSignupsToday: Number((signups.rows[0] as any)?.count || 0),
    };
  }

  async getPeriodComparison(currentRange: any, previousRange: any): Promise<any> {
    // Compare two periods side-by-side
    const [current, previous] = await Promise.all([
      this.getKpis(currentRange),
      this.getKpis(previousRange),
    ]);
    
    return {
      current,
      previous,
      changes: {
        activeTenants: this.percentChange(current.activeTenants, previous.activeTenants),
        mrr: this.percentChange(current.mrr, previous.mrr),
        newTenants: this.percentChange(current.newTenantsThisMonth, previous.newTenantsThisMonth),
      },
    };
  }

  private percentChange(current: number, previous: number): number {
    if (previous === 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }

  private async getSystemHealth(): Promise<any> {
    // Would integrate with monitoring system (CloudWatch)
    return {
      apiUptime: 99.95,
      avgResponseTime: 150,
      errorRate: 0.1,
      activeAlerts: 0,
    };
  }
}
```

### 5. SaaS Metrics Service

```typescript
// server/src/modules/owner-dashboard/services/saas-metrics.service.ts
import { Injectable } from '@nestjs/common';
import { DbService } from '../../../db/db.service';
import { sql } from 'drizzle-orm';

@Injectable()
export class SaasMetricsService {
  constructor(private readonly db: DbService) {}

  async getMrr(date?: Date): Promise<any> {
    const db = this.db.getDb();
    const refDate = date || new Date();
    
    const result = await db.execute(sql`
      SELECT 
        SUM(monthly_amount)::numeric as mrr,
        SUM(monthly_amount) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days')::numeric as new_mrr,
        SUM(monthly_amount) FILTER (WHERE status = 'cancelled' AND cancelled_at >= NOW() - INTERVAL '30 days')::numeric as churned_mrr
      FROM tenant_subscriptions
      WHERE status = 'active' OR (status = 'cancelled' AND cancelled_at >= NOW() - INTERVAL '30 days')
    `);
    
    const row = result.rows[0] as any;
    const mrr = Number(row?.mrr || 0);
    const newMrr = Number(row?.new_mrr || 0);
    const churnedMrr = Number(row?.churned_mrr || 0);
    
    return {
      current: mrr,
      arr: mrr * 12,
      newMrr,
      expansionMrr: 0, // Plan upgrades
      contractionMrr: 0, // Plan downgrades
      churnedMrr,
      netNewMrr: newMrr - churnedMrr,
      asOfDate: refDate,
    };
  }

  async getMrrGrowth(months: number): Promise<any> {
    const db = this.db.getDb();
    
    const result = await db.execute(sql`
      SELECT 
        TO_CHAR(date, 'YYYY-MM') as month,
        AVG(mrr)::numeric as mrr
      FROM owner_daily_metrics
      WHERE date >= NOW() - INTERVAL '${months} months'
      GROUP BY TO_CHAR(date, 'YYYY-MM')
      ORDER BY month ASC
    `);
    
    return {
      data: result.rows.map((r: any) => ({
        month: r.month,
        mrr: Number(r.mrr),
      })),
    };
  }

  async getChurnRate(period: 'monthly' | 'quarterly'): Promise<any> {
    const db = this.db.getDb();
    const interval = period === 'monthly' ? '30 days' : '90 days';
    
    const result = await db.execute(sql.raw(`
      WITH active_at_start AS (
        SELECT COUNT(*)::int as count
        FROM tenant_subscriptions
        WHERE created_at < NOW() - INTERVAL '${interval}'
          AND (status = 'active' OR (status = 'cancelled' AND cancelled_at >= NOW() - INTERVAL '${interval}'))
      ),
      churned AS (
        SELECT 
          COUNT(*)::int as total,
          COUNT(*) FILTER (WHERE cancellation_reason NOT LIKE '%payment%')::int as voluntary,
          COUNT(*) FILTER (WHERE cancellation_reason LIKE '%payment%')::int as involuntary,
          SUM(monthly_amount)::numeric as churned_mrr
        FROM tenant_subscriptions
        WHERE status = 'cancelled'
          AND cancelled_at >= NOW() - INTERVAL '${interval}'
      )
      SELECT 
        active_at_start.count as initial,
        churned.total,
        churned.voluntary,
        churned.involuntary,
        churned.churned_mrr
      FROM active_at_start, churned
    `));
    
    const row = result.rows[0] as any;
    const initial = Number(row?.initial || 0);
    const total = Number(row?.total || 0);
    const voluntary = Number(row?.voluntary || 0);
    const involuntary = Number(row?.involuntary || 0);
    
    return {
      rate: initial > 0 ? (total / initial) * 100 : 0,
      voluntaryRate: initial > 0 ? (voluntary / initial) * 100 : 0,
      involuntaryRate: initial > 0 ? (involuntary / initial) * 100 : 0,
      churnedTenants: total,
      churnedMrr: Number(row?.churned_mrr || 0),
      reasons: [], // Would aggregate cancellation_reason
    };
  }

  async getCustomerLifetimeValue(): Promise<any> {
    const db = this.db.getDb();
    
    // Simplified LTV: (Avg Monthly Revenue) * (Avg Customer Lifetime in months)
    const result = await db.execute(sql`
      SELECT 
        AVG(monthly_amount)::numeric as avg_revenue,
        plan_code,
        AVG(EXTRACT(EPOCH FROM (
          COALESCE(cancelled_at, NOW()) - created_at
        ))/86400/30)::numeric as avg_lifetime_months
      FROM tenant_subscriptions
      WHERE plan_code != 'trial'
      GROUP BY plan_code
    `);
    
    const byPlan: Record<string, number> = {};
    let totalLtv = 0;
    let count = 0;
    
    for (const row of result.rows as any[]) {
      const ltv = Number(row.avg_revenue) * Number(row.avg_lifetime_months || 12);
      byPlan[row.plan_code] = ltv;
      totalLtv += ltv;
      count++;
    }
    
    return {
      averageLtv: count > 0 ? totalLtv / count : 0,
      byPlan,
      paybackPeriodDays: 0, // Would need CAC data
      cacToLtvRatio: 0,
    };
  }

  async getNetRevenueRetention(): Promise<any> {
    // NRR = (Starting MRR + Expansion - Churn - Contraction) / Starting MRR
    const db = this.db.getDb();
    
    const result = await db.execute(sql`
      SELECT 
        SUM(monthly_amount) FILTER (WHERE created_at < NOW() - INTERVAL '30 days')::numeric as starting_mrr,
        SUM(monthly_amount) FILTER (WHERE status = 'cancelled' AND cancelled_at >= NOW() - INTERVAL '30 days')::numeric as churned_mrr
      FROM tenant_subscriptions
    `);
    
    const row = result.rows[0] as any;
    const starting = Number(row?.starting_mrr || 0);
    const churned = Number(row?.churned_mrr || 0);
    
    const nrr = starting > 0 ? ((starting - churned) / starting) * 100 : 100;
    
    return {
      nrr,
      startingMrr: starting,
      churnedMrr: churned,
      expansionMrr: 0,
      contractionMrr: 0,
    };
  }

  async getCohortRetention(cohortMonth: string): Promise<any> {
    const db = this.db.getDb();
    
    const result = await db.execute(sql.raw(`
      WITH cohort AS (
        SELECT id, created_at
        FROM tenant_subscriptions
        WHERE TO_CHAR(created_at, 'YYYY-MM') = '${cohortMonth}'
      ),
      retention AS (
        SELECT 
          generate_series(0, 11) as month_offset,
          COUNT(*) FILTER (
            WHERE status = 'active' 
              OR (status = 'cancelled' AND cancelled_at > created_at + (INTERVAL '1 month' * generate_series(0, 11)))
          )::int as retained
        FROM cohort, generate_series(0, 11)
        GROUP BY month_offset
      )
      SELECT * FROM retention ORDER BY month_offset
    `));
    
    const cohortSize = result.rows[0]?.retained || 0;
    
    return {
      cohortMonth,
      initialCount: Number(cohortSize),
      retentionByMonth: result.rows.map((r: any) => 
        cohortSize > 0 ? (Number(r.retained) / Number(cohortSize)) * 100 : 0,
      ),
    };
  }

  async getTrialConversion(dateRange: any): Promise<any> {
    const db = this.db.getDb();
    
    const result = await db.execute(sql`
      SELECT 
        COUNT(*) FILTER (WHERE plan_code = 'trial' AND created_at BETWEEN ${dateRange.from} AND ${dateRange.to})::int as total_trials,
        COUNT(*) FILTER (
          WHERE plan_code != 'trial' 
            AND created_at BETWEEN ${dateRange.from} AND ${dateRange.to}
            AND tenant_id IN (
              SELECT tenant_id FROM tenant_subscriptions 
              WHERE plan_code = 'trial' AND created_at BETWEEN ${dateRange.from} AND ${dateRange.to}
            )
        )::int as converted
      FROM tenant_subscriptions
    `);
    
    const row = result.rows[0] as any;
    const trials = Number(row?.total_trials || 0);
    const converted = Number(row?.converted || 0);
    
    return {
      totalTrials: trials,
      converted,
      conversionRate: trials > 0 ? (converted / trials) * 100 : 0,
    };
  }
}
```

### 6. Tenant Management Service

```typescript
// server/src/modules/owner-dashboard/services/tenant-management.service.ts
import { Injectable } from '@nestjs/common';
import { DbService } from '../../../db/db.service';
import { TenantsRepository } from '../../tenants/tenants.repository';
import { sql } from 'drizzle-orm';

@Injectable()
export class TenantManagementService {
  constructor(
    private readonly db: DbService,
    private readonly tenantsRepo: TenantsRepository,
  ) {}

  async listTenants(filters: any): Promise<any> {
    const db = this.db.getDb();
    
    // CRITICAL: Returns metadata only, NOT business data
    const result = await db.execute(sql`
      SELECT 
        t.id,
        t.name,
        t.subdomain,
        t.contact_email,
        t.contact_mobile,
        t.created_at as signup_date,
        ts.plan_code,
        ts.status,
        ts.trial_ends_at,
        ts.monthly_amount,
        u.name as owner_name,
        u.last_login_at,
        
        -- Aggregate counts ONLY
        (SELECT COUNT(*)::int FROM stores WHERE tenant_id = t.id AND deleted_at IS NULL) as store_count,
        (SELECT COUNT(*)::int FROM users WHERE tenant_id = t.id AND deleted_at IS NULL) as user_count,
        (SELECT COUNT(*)::int FROM scan_items WHERE tenant_id = t.id AND scanned_at >= DATE_TRUNC('month', NOW())) as monthly_scans,
        (SELECT COUNT(*)::int FROM reports WHERE tenant_id = t.id AND created_at >= DATE_TRUNC('month', NOW())) as monthly_reports,
        (SELECT COUNT(*)::int FROM ai_usage_log WHERE tenant_id = t.id AND year_month = TO_CHAR(NOW(), 'YYYY-MM')) as ai_calls
        
      FROM tenants t
      LEFT JOIN tenant_subscriptions ts ON ts.tenant_id = t.id
      LEFT JOIN users u ON u.tenant_id = t.id AND u.role = 'owner'
      WHERE t.deleted_at IS NULL
      ORDER BY t.created_at DESC
      LIMIT ${filters.limit || 50}
    `);
    
    return {
      data: result.rows.map((r: any) => ({
        id: r.id,
        name: r.name,
        subdomain: r.subdomain,
        ownerName: r.owner_name,
        ownerEmail: r.contact_email,
        contactMobile: r.contact_mobile,
        planCode: r.plan_code,
        status: r.status,
        trialEndsAt: r.trial_ends_at,
        monthlyAmount: Number(r.monthly_amount || 0),
        signupDate: r.signup_date,
        lastLoginAt: r.last_login_at,
        metrics: {
          storeCount: Number(r.store_count),
          userCount: Number(r.user_count),
          monthlyScans: Number(r.monthly_scans),
          monthlyReports: Number(r.monthly_reports),
          aiCallsThisMonth: Number(r.ai_calls),
          storageUsedMb: 0, // Would calculate from media_assets
        },
        health: {
          score: this.calculateTenantHealth(r),
          isAtRisk: this.isTenantAtRisk(r),
          daysSinceLastLogin: r.last_login_at
            ? Math.floor((Date.now() - new Date(r.last_login_at).getTime()) / (1000 * 60 * 60 * 24))
            : 999,
          supportTicketCount: 0, // Future
          flagged: false,
        },
      })),
      hasMore: false,
      nextCursor: null,
    };
  }

  async getTenantSummary(tenantId: string): Promise<any> {
    // Same as list, but for one tenant
    const list = await this.listTenants({ limit: 1, tenantId });
    return list.data[0] || null;
  }

  async getTenantHealth(tenantId: string): Promise<any> {
    // Multi-factor health analysis
    const summary = await this.getTenantSummary(tenantId);
    if (!summary) return null;
    
    const signals = [];
    let paymentHealth: any = 'good';
    let usageHealth: any = 'good';
    let engagementHealth: any = 'good';
    
    // Payment health
    if (summary.status === 'past_due') {
      paymentHealth = 'critical';
      signals.push({ type: 'negative', message: 'Payment past due', severity: 'high' });
    } else if (summary.status === 'cancelled') {
      paymentHealth = 'critical';
      signals.push({ type: 'negative', message: 'Subscription cancelled', severity: 'high' });
    }
    
    // Usage health
    if (summary.metrics.monthlyScans === 0 && summary.status === 'active') {
      usageHealth = 'warning';
      signals.push({ type: 'negative', message: 'No scans this month', severity: 'medium' });
    }
    
    // Engagement health
    if (summary.health.daysSinceLastLogin > 30) {
      engagementHealth = 'critical';
      signals.push({ type: 'negative', message: '30+ days since last login', severity: 'high' });
    } else if (summary.health.daysSinceLastLogin > 7) {
      engagementHealth = 'warning';
      signals.push({ type: 'negative', message: 'Inactive for a week', severity: 'medium' });
    }
    
    const recommendations = [];
    if (paymentHealth === 'critical') recommendations.push('Reach out about payment');
    if (usageHealth === 'warning') recommendations.push('Send re-engagement email');
    if (engagementHealth === 'critical') recommendations.push('Schedule customer success call');
    
    return {
      tenantId,
      overallScore: summary.health.score,
      indicators: {
        paymentHealth,
        usageHealth,
        engagementHealth,
        supportHealth: 'good',
      },
      signals,
      recommendations,
    };
  }

  async flagTenant(tenantId: string, reason: string, userId: string): Promise<void> {
    // Mark tenant for special attention (support escalation)
    await this.tenantsRepo.update(tenantId, {
      metadata: { flagged: true, flagReason: reason, flaggedBy: userId, flaggedAt: new Date() },
    });
  }

  async exportTenantData(tenantId: string, userId: string): Promise<string> {
    // GDPR: User has right to export
    // This is the ONE TIME owner can access tenant data — for compliance
    // Returns S3 URL with audit log
    
    // BE-32 will fully implement
    return 'https://exports.s3.aws/tenant-export.zip';
  }

  private calculateTenantHealth(row: any): number {
    let score = 100;
    
    if (row.status !== 'active' && row.status !== 'trial') score -= 50;
    if (row.last_login_at) {
      const daysSince = Math.floor(
        (Date.now() - new Date(row.last_login_at).getTime()) / (1000 * 60 * 60 * 24),
      );
      score -= Math.min(40, daysSince);
    } else {
      score -= 30;
    }
    
    if (Number(row.monthly_scans) === 0) score -= 20;
    
    return Math.max(0, score);
  }

  private isTenantAtRisk(row: any): boolean {
    return this.calculateTenantHealth(row) < 50;
  }
}
```

### 7. Cost Monitoring Service

```typescript
// server/src/modules/owner-dashboard/services/cost-monitoring.service.ts
import { Injectable } from '@nestjs/common';
import { DbService } from '../../../db/db.service';
import { sql } from 'drizzle-orm';

@Injectable()
export class CostMonitoringService {
  constructor(private readonly db: DbService) {}

  async getCurrentMonthCosts(): Promise<any> {
    const db = this.db.getDb();
    const yearMonth = new Date().toISOString().slice(0, 7);
    
    // AI costs
    const aiCost = await db.execute(sql`
      SELECT COALESCE(SUM(cost), 0)::numeric as total
      FROM ai_usage_log
      WHERE year_month = ${yearMonth}
    `);
    
    // SMS costs (estimated from OTP attempts)
    const smsCount = await db.execute(sql`
      SELECT COUNT(*)::int as count
      FROM otp_attempts
      WHERE TO_CHAR(created_at, 'YYYY-MM') = ${yearMonth}
    `);
    
    const smsCost = Number((smsCount.rows[0] as any)?.count || 0) * 0.20; // ₹0.20 per SMS
    
    // Active tenants (for per-tenant calculation)
    const tenants = await db.execute(sql`
      SELECT COUNT(*)::int as count
      FROM tenant_subscriptions
      WHERE status IN ('active', 'trial')
    `);
    
    const activeTenants = Number((tenants.rows[0] as any)?.count || 1);
    
    // MRR for ratio
    const mrr = await db.execute(sql`
      SELECT COALESCE(SUM(monthly_amount), 0)::numeric as mrr
      FROM tenant_subscriptions
      WHERE status = 'active'
    `);
    
    const mrrValue = Number((mrr.rows[0] as any)?.mrr || 0);
    
    // AWS costs would come from AWS Cost Explorer API (placeholder)
    const awsCosts = {
      ec2: 50,    // ~$50/month
      rds: 100,   // ~$100/month
      s3: 20,     // ~$20/month
      cloudfront: 10,
      ses: 5,
    };
    
    const total = Number(aiCost.rows[0]?.total || 0) + smsCost + 
      awsCosts.ec2 + awsCosts.rds + awsCosts.s3 + awsCosts.cloudfront + awsCosts.ses;
    
    return {
      month: yearMonth,
      total,
      byCategory: {
        ai: Number((aiCost.rows[0] as any)?.total || 0),
        sms: smsCost,
        aws: awsCosts,
        other: 0,
      },
      perTenantAverage: total / activeTenants,
      costToMrrRatio: mrrValue > 0 ? (total / mrrValue) * 100 : 0,
    };
  }

  async getCostTrends(months: number): Promise<any> {
    // Implementation to query historical cost data
    return { data: [] };
  }

  async getCostPerTenant(): Promise<any[]> {
    const db = this.db.getDb();
    const yearMonth = new Date().toISOString().slice(0, 7);
    
    const result = await db.execute(sql`
      SELECT 
        t.id as tenant_id,
        t.name as tenant_name,
        COALESCE(SUM(au.cost), 0)::numeric as ai_cost,
        (SELECT COUNT(*) FROM otp_attempts oa 
          WHERE oa.mobile IN (SELECT mobile FROM users WHERE tenant_id = t.id)
            AND TO_CHAR(oa.created_at, 'YYYY-MM') = ${yearMonth}
        )::numeric * 0.20 as sms_cost,
        ts.monthly_amount as revenue
      FROM tenants t
      LEFT JOIN tenant_subscriptions ts ON ts.tenant_id = t.id
      LEFT JOIN ai_usage_log au ON au.tenant_id = t.id AND au.year_month = ${yearMonth}
      WHERE t.deleted_at IS NULL
      GROUP BY t.id, t.name, ts.monthly_amount
      ORDER BY ai_cost DESC
      LIMIT 50
    `);
    
    return result.rows.map((r: any) => ({
      tenantId: r.tenant_id,
      tenantName: r.tenant_name,
      revenue: Number(r.revenue || 0),
      costs: {
        ai: Number(r.ai_cost),
        sms: Number(r.sms_cost),
        total: Number(r.ai_cost) + Number(r.sms_cost),
      },
      profitMargin: Number(r.revenue) > 0 
        ? ((Number(r.revenue) - Number(r.ai_cost) - Number(r.sms_cost)) / Number(r.revenue)) * 100
        : 0,
    }));
  }

  async getCostBreakdown(category: any): Promise<any> {
    return this.getCurrentMonthCosts();
  }

  async getProfitability(): Promise<any> {
    const costs = await this.getCurrentMonthCosts();
    const db = this.db.getDb();
    
    const mrr = await db.execute(sql`
      SELECT COALESCE(SUM(monthly_amount), 0)::numeric as mrr
      FROM tenant_subscriptions
      WHERE status = 'active'
    `);
    
    const mrrValue = Number((mrr.rows[0] as any)?.mrr || 0);
    const annualRevenue = mrrValue * 12;
    const annualCosts = costs.total * 12;
    const grossProfit = annualRevenue - annualCosts;
    
    return {
      revenue: annualRevenue,
      costs: annualCosts,
      grossProfit,
      grossMargin: annualRevenue > 0 ? (grossProfit / annualRevenue) * 100 : 0,
      costPerUser: 0, // Would need user count
      revenuePerUser: 0,
      ltv: 0,
      cac: 0,
      paybackPeriodMonths: 0,
    };
  }
}
```

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| GET | `/api/v1/owner/overview` | Owner | Main dashboard |
| GET | `/api/v1/owner/realtime` | Owner | Real-time stats |
| GET | `/api/v1/owner/saas/mrr` | Owner | MRR data |
| GET | `/api/v1/owner/saas/churn` | Owner | Churn analysis |
| GET | `/api/v1/owner/saas/ltv` | Owner | LTV metrics |
| GET | `/api/v1/owner/saas/cohorts` | Owner | Cohort retention |
| GET | `/api/v1/owner/saas/funnel` | Owner | Conversion funnel |
| GET | `/api/v1/owner/tenants` | Owner | Tenant list (counts only) |
| GET | `/api/v1/owner/tenants/:id` | Owner | Tenant summary |
| GET | `/api/v1/owner/tenants/:id/health` | Owner | Health analysis |
| POST | `/api/v1/owner/tenants/:id/flag` | Owner | Flag tenant |
| POST | `/api/v1/owner/tenants/:id/export` | Owner | GDPR export (audit) |
| GET | `/api/v1/owner/marketing/website` | Owner | Website analytics |
| GET | `/api/v1/owner/marketing/leads` | Owner | Leads list |
| GET | `/api/v1/owner/costs/current` | Owner | Current costs |
| GET | `/api/v1/owner/costs/per-tenant` | Owner | Cost per tenant |
| GET | `/api/v1/owner/costs/profitability` | Owner | P&L summary |
| GET | `/api/v1/owner/access-log` | Owner | View own access log |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-32 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Owner-Only Access ✅
Non-owner tries to access:
**Expected**: 403 INSUFFICIENT_PERMISSIONS
**Pass Criteria**: ✅ Strict access enforced

### Test 2: Multi-Layer Auth ✅
- Admin role ✅
- Owner whitelist ✅
- Specific permission ✅

All three required:
**Pass Criteria**: ✅ Defense in depth

### Test 3: Access Logging ✅
Every owner API call logged:
```sql
SELECT * FROM owner_dashboard_access_log;
```
**Pass Criteria**: ✅ Audit trail comprehensive

### Test 4: NO Tenant Data Leakage ✅
Critical test: Owner cannot see scan content, products, etc.
**Expected**: Endpoints return ONLY counts and metadata
**Pass Criteria**: ✅ Privacy boundary holds

### Test 5: Overview Performance ✅
**Pass Criteria**: ✅ < 2 seconds (parallel queries)

### Test 6: MRR Accuracy ✅
**Pass Criteria**: ✅ Matches manual calculation

### Test 7: Churn Calculation ✅
**Pass Criteria**: ✅ Correct rate calculation

### Test 8: Cohort Analysis ✅
**Pass Criteria**: ✅ Retention curves correct

### Test 9: Tenant List Privacy ✅
Returns: name, email, plan, counts
NO: products, scans, inventory content
**Pass Criteria**: ✅ Privacy enforced

### Test 10: Tenant Health Score ✅
**Pass Criteria**: ✅ Multi-factor calculation

### Test 11: Cost Per Tenant ✅
**Pass Criteria**: ✅ AI + SMS costs aggregated

### Test 12: Profitability Calculation ✅
**Pass Criteria**: ✅ Revenue - Costs = Profit

### Test 13: GDPR Export Audit ✅
Export tenant data → audit log entry
**Pass Criteria**: ✅ Compliance trail

### Test 14: Real-time Stats ✅
**Pass Criteria**: ✅ Updates every minute

### Test 15: Conversion Funnel ✅
Visitors → Pricing → Trial → Paid
**Pass Criteria**: ✅ Each step accurate

## 🎯 Q&A Session

### Q1: Why separate dashboard for app owner?
**Expected**: Different audience (you vs tenants), different data scope, different privacy needs, different deployment (private vs Play Store)

### Q2: Why multiple auth layers?
**Expected**: Defense in depth — role + whitelist + permission + audit. One failure doesn't compromise

### Q3: Why log every access?
**Expected**: Compliance, security audit, accountability, can detect insider threats

### Q4: Why aggregate counts not raw data?
**Expected**: Privacy commitment to tenants, GDPR compliance, less liability, better trust

### Q5: How calculate MRR correctly?
**Expected**: Sum monthly_amount of active subscriptions, exclude trials, normalize annual to monthly

### Q6: How handle ARR vs MRR?
**Expected**: ARR = MRR * 12 (simple), exclude one-time charges

### Q7: How calculate LTV?
**Expected**: Avg Revenue Per User * Avg Customer Lifetime, simplified formula for SMB SaaS

### Q8: When OK to access tenant data?
**Expected**: NEVER except: GDPR export request, security investigation (logged), tenant explicit support permission

## 📝 Sign-Off Checklist

- [ ] All 15 tests pass
- [ ] Privacy boundary verified
- [ ] Multi-layer auth works
- [ ] Access logging comprehensive
- [ ] All metrics accurate
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

### Critical Privacy Verification
- [ ] Manually attempted to access tenant business data → fails
- [ ] All endpoints reviewed for data leakage
- [ ] Audit log entries verified
- [ ] No raw user data in responses

**☐ APPROVED — Proceed to BE-32**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF BE-31 — DO NOT PROCEED WITHOUT APPROVAL**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-31 (App Owner Dashboard) with the strict privacy boundary required by Req 15.**

## Driver Requirements

- **Req 15** — App Owner Dashboard sees tenant names + signup dates + tiers + MRR + aggregate counts + feature usage + AI/OCR cost + PostHog dashboards. It MUST NEVER see tenant product data, scan content, inventory line items, task content, EAN list content, or family member personal data. Endpoints requesting tenant content return HTTP 403. Database stores everything encrypted (TDE) for tenant data recovery.

## Scope of Update

This phase exists in v1 and provides the dashboard. v2 hardens it so:

1. A dedicated database role (`radha_owner_dashboard_role`) is used.
2. RLS bypass is allowed only for explicit aggregate views.
3. Any attempt to read tenant content fields via the dashboard scope returns 403.
4. The encrypted-at-rest guarantee (PostgreSQL TDE) is documented and enforced (delegated to BE-33).
5. Admin Impersonation (Req 51) is the one approved flow for support staff to act as a user, and it is implemented in BE-53.

## Forbidden Fields (Hard List)

The following columns are **forbidden** in any Owner_Dashboard query path:

```typescript
export const OWNER_DASHBOARD_FORBIDDEN_COLUMNS = new Set<string>([
  // Products
  'products.name', 'products.brand', 'products.ingredients', 'products.nutritional_data',
  'products.image_url', 'products.allergens',
  // Scans
  'scans.ean', 'scans.batch_number', 'scans.product_name',
  // Inventory
  'inventory.product_id', 'inventory.batch_number', 'inventory.quantity',
  // Tasks
  'tasks.title', 'tasks.description',
  // EAN lists
  'ean_lists.eans',
  // Saved products / family
  'saved_products.product_id', 'allergen_profiles.tags', 'family_members.display_name',
]);
```

## Allowed Aggregate Views

Whitelist of views the Owner Dashboard may query:

```sql
CREATE MATERIALIZED VIEW owner_dashboard_tenant_summary AS
SELECT
  t.id AS tenant_id,
  t.name AS tenant_name,
  t.created_at AS signup_at,
  s.tier AS subscription_tier,
  COUNT(DISTINCT u.id) AS user_count,
  COUNT(DISTINCT st.id) AS store_count,
  -- aggregate counts only — NO content
  (SELECT COUNT(*) FROM scans WHERE tenant_id = t.id) AS total_scans,
  (SELECT COUNT(*) FROM inventory WHERE tenant_id = t.id) AS total_inventory_items,
  (SELECT COUNT(*) FROM tasks WHERE tenant_id = t.id) AS total_tasks,
  (SELECT COUNT(*) FROM grns WHERE tenant_id = t.id) AS total_grns
FROM tenants t
LEFT JOIN subscriptions s ON s.tenant_id = t.id AND s.status = 'active'
LEFT JOIN users u ON u.tenant_id = t.id
LEFT JOIN stores st ON st.tenant_id = t.id
GROUP BY t.id, t.name, t.created_at, s.tier;

REVOKE ALL ON owner_dashboard_tenant_summary FROM PUBLIC;
GRANT SELECT ON owner_dashboard_tenant_summary TO radha_owner_dashboard_role;
```

## Endpoint Guard

```typescript
@Injectable()
export class OwnerDashboardScopeGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const handler = context.getHandler();
    const allowed = Reflect.getMetadata('owner_dashboard_allowed_view', handler);
    if (!allowed) {
      throw new ForbiddenException('Owner Dashboard requested non-aggregate view');
    }
    return true;
  }
}

// Decorator on every Owner_Dashboard endpoint
export const OwnerDashboardView = (viewName: string) =>
  SetMetadata('owner_dashboard_allowed_view', viewName);
```

## Endpoint Example

```typescript
@Controller('/api/v1/owner-dashboard')
@UseGuards(AdminAuthGuard, OwnerDashboardScopeGuard)
export class OwnerDashboardController {
  @Get('/tenants')
  @OwnerDashboardView('owner_dashboard_tenant_summary')
  async listTenants(): Promise<TenantSummaryDto[]> {
    return this.dashboard.fromMaterializedView('owner_dashboard_tenant_summary');
  }

  @Get('/tenants/:id/scans')        // ❌ NOT ALLOWED
  async readTenantScans() {
    // Missing @OwnerDashboardView decorator → guard throws 403
    throw new ForbiddenException();
  }
}
```

## ADDENDUM v2 Test Procedures (add 6)

| # | Test |
|---|---|
| T-v2.1 | Owner Dashboard can read aggregate counts for any tenant |
| T-v2.2 | Owner Dashboard cannot read product names, scan EANs, inventory items, task content (all return 403) |
| T-v2.3 | Materialized view has zero raw content columns |
| T-v2.4 | `OwnerDashboardScopeGuard` rejects any handler missing `@OwnerDashboardView` |
| T-v2.5 | Property test: For all (tenant_id, content_endpoint) pairs, dashboard returns 403 |
| T-v2.6 | Database role `radha_owner_dashboard_role` cannot SELECT from raw `products` / `scans` / `tasks` |

## ADDENDUM v2 Q&A (add 3)

- **Q-v2.1**: How is the `radha_owner_dashboard_role` created and what RLS policies bypass it?
- **Q-v2.2**: When the App Owner needs to debug a tenant issue, what is the approved alternative path? (Hint: Req 51 + BE-53)
- **Q-v2.3**: How is the materialized view refresh scheduled, and does the refresh process bypass RLS safely?

## ADDENDUM v2 Sign-off

- [ ] Forbidden-fields list maintained in code
- [ ] Aggregate-only materialized view live
- [ ] Scope guard rejects non-aggregate handlers
- [ ] Property test confirms 403 on all content endpoints
- [ ] Database role permissions verified

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-31 ADDENDUM v2**
