# Phase BE-30: Client In-App Dashboard API

## Phase Metadata

- **Phase ID**: BE-30
- **Phase Name**: Client In-App Dashboard API
- **Section**: Backend Execution — Business Operations Layer
- **Depends On**: BE-01 to BE-29
- **Blocks**: BE-31 (Owner Dashboard)
- **Estimated Duration**: 2 days
- **Complexity**: Medium

## Goal

Build dashboard APIs for the **mobile app's in-app dashboard** that retail business owners (tenants) see when they log in. Strictly tenant-scoped — shows ONLY their business data: their stores, scans, expiry alerts, tasks, inventory, GRN, supplier performance, team activity. Real-time, fast, mobile-optimized.

## Why This Phase Matters

This is what tenants see EVERY DAY in the mobile app:
- Daily KPIs at a glance
- Quick actions for common tasks
- Alerts requiring attention
- Trend visibility
- Team performance

Without this:
- Mobile app feels empty
- No insights for users
- No reason to open app daily
- Poor retention

**Privacy boundary**: Tenants see ONLY their data, never other tenants' data.

## Prerequisites

- [ ] BE-01 to BE-29 completed
- [ ] All data sources populated
- [ ] Authorization (BE-08, BE-09) working

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/modules/client-dashboard/client-dashboard.module.ts` | Module |
| `server/src/modules/client-dashboard/client-dashboard.controller.ts` | Endpoints |
| `server/src/modules/client-dashboard/services/dashboard.service.ts` | Main service |
| `server/src/modules/client-dashboard/services/kpi.service.ts` | KPI calculations |
| `server/src/modules/client-dashboard/services/quick-action.service.ts` | Quick actions |
| `server/src/modules/client-dashboard/services/alerts-summary.service.ts` | Alert aggregation |
| `server/src/modules/client-dashboard/services/trends.service.ts` | Trend data |
| `server/src/modules/client-dashboard/services/team-performance.service.ts` | Team stats |
| `server/src/modules/client-dashboard/services/dashboard-cache.service.ts` | Caching layer |
| `server/src/modules/client-dashboard/dto/dashboard-query.dto.ts` | DTOs |
| `server/src/modules/client-dashboard/types/dashboard.types.ts` | Types |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/client-dashboard/services/dashboard.service.ts

export interface IClientDashboardService {
  // Main dashboard (one-shot for mobile)
  getDashboard(storeId: string, options?: DashboardOptions): Promise<ClientDashboard>;
  
  // Specific sections (for refresh)
  getKpis(storeId: string, dateRange: DateRange): Promise<DashboardKpis>;
  getAlerts(storeId: string): Promise<DashboardAlerts>;
  getQuickActions(storeId: string, userId: string): Promise<QuickAction[]>;
  getTrends(storeId: string, dateRange: DateRange): Promise<TrendData>;
  getTeamPerformance(storeId: string, dateRange: DateRange): Promise<TeamStats>;
  getRecentActivity(storeId: string, limit?: number): Promise<ActivityFeed>;
  
  // Multi-store summary (for owners with multiple stores)
  getMultiStoreSummary(tenantId: string): Promise<MultiStoreSummary>;
}

export interface DashboardOptions {
  dateRange?: DateRange;
  includeKpis?: boolean;
  includeAlerts?: boolean;
  includeTrends?: boolean;
  includeTeam?: boolean;
}

export interface ClientDashboard {
  storeId: string;
  storeName: string;
  generatedAt: Date;
  
  // Today's KPIs
  kpis: DashboardKpis;
  
  // Active alerts requiring attention
  alerts: DashboardAlerts;
  
  // Quick actions
  quickActions: QuickAction[];
  
  // Trend data (last 30 days)
  trends: TrendData;
  
  // Team performance (this week)
  team: TeamStats;
  
  // Recent activity
  recentActivity: ActivityFeed;
  
  // Subscription status
  subscriptionStatus: {
    plan: string;
    status: string;
    trialDaysRemaining?: number;
    usagePercentage: number;
  };
}

export interface DashboardKpis {
  // Today
  scansToday: number;
  scansThisWeek: number;
  scansThisMonth: number;
  
  // Expiry
  expiringNextWeek: number;
  expiredItems: number;
  
  // Tasks
  pendingTasks: number;
  overdueTasks: number;
  completedToday: number;
  
  // Inventory
  totalProducts: number;
  lowStockItems: number;
  
  // Compliance
  eanMatchRate: number; // Percentage
  
  // Trends (vs previous period)
  trends: {
    scans: TrendDirection;
    expiry: TrendDirection;
    tasks: TrendDirection;
    inventory: TrendDirection;
  };
}

export type TrendDirection = 'up' | 'down' | 'flat';

export interface DashboardAlerts {
  total: number;
  critical: AlertItem[];     // Need immediate action
  warning: AlertItem[];      // Should be addressed soon
  info: AlertItem[];         // FYI
}

export interface AlertItem {
  id: string;
  type: 'expiry_red' | 'expiry_yellow' | 'low_stock' | 'task_overdue' | 'ean_mismatch_spike' | 'system';
  title: string;
  description: string;
  count: number;
  actionUrl?: string;
  createdAt: Date;
}

export interface QuickAction {
  id: string;
  type: 'scan' | 'add_product' | 'create_grn' | 'create_task' | 'view_alerts' | 'generate_report';
  label: string;
  icon: string;
  badgeCount?: number;
  enabled: boolean;
  reason?: string; // Why disabled (subscription limit etc)
}

export interface TrendData {
  scans: DataPoint[];
  expiryAdded: DataPoint[];
  tasksCompleted: DataPoint[];
  inventoryMovements: DataPoint[];
}

export interface DataPoint {
  date: Date;
  value: number;
}

export interface TeamStats {
  totalMembers: number;
  activeToday: number;
  topScanners: Array<{
    userId: string;
    userName: string;
    scanCount: number;
    avatarUrl?: string;
  }>;
  taskCompletionLeaders: Array<{
    userId: string;
    userName: string;
    completedCount: number;
    completionRate: number;
  }>;
}

export interface ActivityFeed {
  items: ActivityItem[];
  hasMore: boolean;
}

export interface ActivityItem {
  id: string;
  type: 'scan' | 'task_completed' | 'grn_posted' | 'product_added' | 'expiry_alert';
  actorName: string;
  actorAvatarUrl?: string;
  action: string;
  target: string;
  timestamp: Date;
  metadata?: Record<string, unknown>;
}

export interface MultiStoreSummary {
  tenantId: string;
  totalStores: number;
  stores: Array<{
    storeId: string;
    storeName: string;
    scansToday: number;
    expiryAlerts: number;
    pendingTasks: number;
    healthScore: number; // 0-100
  }>;
  aggregateKpis: DashboardKpis;
}
```

## Implementation Code

### 1. Dashboard Service

```typescript
// server/src/modules/client-dashboard/services/dashboard.service.ts
import { Injectable } from '@nestjs/common';
import { KpiService } from './kpi.service';
import { AlertsSummaryService } from './alerts-summary.service';
import { QuickActionService } from './quick-action.service';
import { TrendsService } from './trends.service';
import { TeamPerformanceService } from './team-performance.service';
import { DashboardCacheService } from './dashboard-cache.service';
import { StoresRepository } from '../../stores/stores.repository';
import { SubscriptionsService } from '../../subscriptions/subscriptions.service';
import { RequestContextService } from '../../../common/context/request-context.service';
import {
  IClientDashboardService,
  ClientDashboard,
  DashboardOptions,
} from '../types/dashboard.types';
import { NotFoundException } from '../../../common/errors/business.exception';

@Injectable()
export class ClientDashboardService implements IClientDashboardService {
  constructor(
    private readonly kpiService: KpiService,
    private readonly alertsService: AlertsSummaryService,
    private readonly quickActionService: QuickActionService,
    private readonly trendsService: TrendsService,
    private readonly teamService: TeamPerformanceService,
    private readonly cacheService: DashboardCacheService,
    private readonly storesRepo: StoresRepository,
    private readonly subscriptionsService: SubscriptionsService,
    private readonly contextService: RequestContextService,
  ) {}

  async getDashboard(
    storeId: string,
    options: DashboardOptions = {},
  ): Promise<ClientDashboard> {
    // Tenant scope verification (TenantScopedRepository handles this)
    const store = await this.storesRepo.findById(storeId);
    if (!store) throw new NotFoundException('Store', storeId);
    
    const tenantId = this.contextService.getTenantId()!;
    const userId = this.contextService.getUserId()!;
    
    // Try cache first (5 min TTL)
    const cacheKey = `dashboard:${storeId}:${userId}`;
    const cached = await this.cacheService.get(cacheKey);
    if (cached) return cached;
    
    // Default date range (last 30 days)
    const now = new Date();
    const dateRange = options.dateRange || {
      from: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000),
      to: now,
    };
    
    // Run all queries in parallel
    const [
      kpis,
      alerts,
      quickActions,
      trends,
      team,
      recentActivity,
      subscriptionStatus,
    ] = await Promise.all([
      this.kpiService.getKpis(storeId, dateRange),
      this.alertsService.getAlerts(storeId),
      this.quickActionService.getQuickActions(storeId, userId),
      this.trendsService.getTrends(storeId, dateRange),
      this.teamService.getTeamStats(storeId, dateRange),
      this.getRecentActivity(storeId, 20),
      this.getSubscriptionStatus(tenantId),
    ]);
    
    const dashboard: ClientDashboard = {
      storeId,
      storeName: store.name,
      generatedAt: new Date(),
      kpis,
      alerts,
      quickActions,
      trends,
      team,
      recentActivity,
      subscriptionStatus,
    };
    
    // Cache for 5 minutes
    await this.cacheService.set(cacheKey, dashboard, 300);
    
    return dashboard;
  }

  async getKpis(storeId: string, dateRange: any): Promise<any> {
    return this.kpiService.getKpis(storeId, dateRange);
  }

  async getAlerts(storeId: string): Promise<any> {
    return this.alertsService.getAlerts(storeId);
  }

  async getQuickActions(storeId: string, userId: string): Promise<any> {
    return this.quickActionService.getQuickActions(storeId, userId);
  }

  async getTrends(storeId: string, dateRange: any): Promise<any> {
    return this.trendsService.getTrends(storeId, dateRange);
  }

  async getTeamPerformance(storeId: string, dateRange: any): Promise<any> {
    return this.teamService.getTeamStats(storeId, dateRange);
  }

  async getRecentActivity(storeId: string, limit: number = 20): Promise<any> {
    // Aggregates from multiple sources: scans, tasks, GRN, etc.
    // Returns chronological feed
    return {
      items: [], // Implementation aggregates from audit_logs
      hasMore: false,
    };
  }

  async getMultiStoreSummary(tenantId: string): Promise<any> {
    const stores = await this.storesRepo.findManyByTenant(tenantId);
    
    const storeStats = await Promise.all(
      stores.map(async (store) => {
        const kpis = await this.kpiService.getKpis(store.id, {
          from: new Date(Date.now() - 24 * 60 * 60 * 1000),
          to: new Date(),
        });
        
        return {
          storeId: store.id,
          storeName: store.name,
          scansToday: kpis.scansToday,
          expiryAlerts: kpis.expiringNextWeek + kpis.expiredItems,
          pendingTasks: kpis.pendingTasks,
          healthScore: this.calculateHealthScore(kpis),
        };
      }),
    );
    
    // Aggregate KPIs
    const aggregateKpis = this.aggregateKpis(
      await Promise.all(stores.map((s) => this.kpiService.getKpis(s.id, {
        from: new Date(Date.now() - 24 * 60 * 60 * 1000),
        to: new Date(),
      }))),
    );
    
    return {
      tenantId,
      totalStores: stores.length,
      stores: storeStats,
      aggregateKpis,
    };
  }

  private async getSubscriptionStatus(tenantId: string): Promise<any> {
    const status = await this.subscriptionsService.getStatus(tenantId);
    return {
      plan: status.plan.code,
      status: status.status,
      trialDaysRemaining: status.trialDaysRemaining,
      usagePercentage: this.calculateUsagePercentage(status.usage),
    };
  }

  private calculateUsagePercentage(usage: any): number {
    // Average usage % across features
    const features = Object.values(usage.byFeature || {}) as any[];
    if (features.length === 0) return 0;
    
    const total = features.reduce((sum, f) => sum + (f.percentageUsed || 0), 0);
    return Math.round(total / features.length);
  }

  private calculateHealthScore(kpis: any): number {
    // Simple health score based on KPIs
    let score = 100;
    
    // Deduct for issues
    if (kpis.overdueTasks > 0) score -= Math.min(20, kpis.overdueTasks * 5);
    if (kpis.expiredItems > 0) score -= Math.min(30, kpis.expiredItems * 3);
    if (kpis.lowStockItems > 0) score -= Math.min(20, kpis.lowStockItems * 2);
    if (kpis.eanMatchRate < 90) score -= (90 - kpis.eanMatchRate);
    
    return Math.max(0, score);
  }

  private aggregateKpis(allKpis: any[]): any {
    return {
      scansToday: allKpis.reduce((sum, k) => sum + k.scansToday, 0),
      scansThisWeek: allKpis.reduce((sum, k) => sum + k.scansThisWeek, 0),
      scansThisMonth: allKpis.reduce((sum, k) => sum + k.scansThisMonth, 0),
      expiringNextWeek: allKpis.reduce((sum, k) => sum + k.expiringNextWeek, 0),
      expiredItems: allKpis.reduce((sum, k) => sum + k.expiredItems, 0),
      pendingTasks: allKpis.reduce((sum, k) => sum + k.pendingTasks, 0),
      overdueTasks: allKpis.reduce((sum, k) => sum + k.overdueTasks, 0),
      completedToday: allKpis.reduce((sum, k) => sum + k.completedToday, 0),
      totalProducts: allKpis.reduce((sum, k) => sum + k.totalProducts, 0),
      lowStockItems: allKpis.reduce((sum, k) => sum + k.lowStockItems, 0),
      eanMatchRate: allKpis.length > 0
        ? allKpis.reduce((sum, k) => sum + k.eanMatchRate, 0) / allKpis.length
        : 0,
    };
  }
}
```

### 2. KPI Service

```typescript
// server/src/modules/client-dashboard/services/kpi.service.ts
import { Injectable } from '@nestjs/common';
import { DbService } from '../../../db/db.service';
import { sql } from 'drizzle-orm';

@Injectable()
export class KpiService {
  constructor(private readonly db: DbService) {}

  async getKpis(storeId: string, dateRange: any): Promise<any> {
    const db = this.db.getDb();
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const weekAgo = new Date(today);
    weekAgo.setDate(weekAgo.getDate() - 7);
    
    const monthAgo = new Date(today);
    monthAgo.setMonth(monthAgo.getMonth() - 1);
    
    const nextWeek = new Date(today);
    nextWeek.setDate(nextWeek.getDate() + 7);
    
    // Run all queries in parallel for performance
    const [scanStats, expiryStats, taskStats, inventoryStats, eanStats] = await Promise.all([
      // Scans
      db.execute(sql`
        SELECT 
          COUNT(*) FILTER (WHERE scanned_at >= ${today})::int as today,
          COUNT(*) FILTER (WHERE scanned_at >= ${weekAgo})::int as week,
          COUNT(*) FILTER (WHERE scanned_at >= ${monthAgo})::int as month
        FROM scan_items
        WHERE store_id = ${storeId}
      `),
      
      // Expiry
      db.execute(sql`
        SELECT 
          COUNT(*) FILTER (WHERE status = 'red' OR status = 'yellow')::int as expiring_soon,
          COUNT(*) FILTER (WHERE status = 'expired')::int as expired
        FROM expiry_records
        WHERE store_id = ${storeId} AND deleted_at IS NULL
      `),
      
      // Tasks
      db.execute(sql`
        SELECT 
          COUNT(*) FILTER (WHERE status = 'pending')::int as pending,
          COUNT(*) FILTER (WHERE status = 'overdue')::int as overdue,
          COUNT(*) FILTER (WHERE status = 'completed' AND completed_at >= ${today})::int as completed_today
        FROM tasks
        WHERE store_id = ${storeId} AND deleted_at IS NULL
      `),
      
      // Inventory
      db.execute(sql`
        SELECT 
          COUNT(*)::int as total,
          COUNT(*) FILTER (WHERE is_low_stock = 'true')::int as low_stock
        FROM inventory_items
        WHERE store_id = ${storeId} AND deleted_at IS NULL
      `),
      
      // EAN match rate
      db.execute(sql`
        SELECT 
          COUNT(*) FILTER (WHERE ean_match_status IN ('matched', 'unmatched'))::int as total_validated,
          COUNT(*) FILTER (WHERE ean_match_status = 'matched')::int as matched
        FROM scan_items
        WHERE store_id = ${storeId}
          AND scanned_at >= ${weekAgo}
      `),
    ]);
    
    const scans = scanStats.rows[0] as any;
    const expiry = expiryStats.rows[0] as any;
    const tasks = taskStats.rows[0] as any;
    const inventory = inventoryStats.rows[0] as any;
    const ean = eanStats.rows[0] as any;
    
    const totalValidated = Number(ean?.total_validated || 0);
    const matched = Number(ean?.matched || 0);
    const matchRate = totalValidated > 0 ? Math.round((matched / totalValidated) * 100) : 100;
    
    // Calculate trends (compare to previous period)
    const trends = await this.calculateTrends(storeId, dateRange);
    
    return {
      scansToday: Number(scans?.today || 0),
      scansThisWeek: Number(scans?.week || 0),
      scansThisMonth: Number(scans?.month || 0),
      expiringNextWeek: Number(expiry?.expiring_soon || 0),
      expiredItems: Number(expiry?.expired || 0),
      pendingTasks: Number(tasks?.pending || 0),
      overdueTasks: Number(tasks?.overdue || 0),
      completedToday: Number(tasks?.completed_today || 0),
      totalProducts: Number(inventory?.total || 0),
      lowStockItems: Number(inventory?.low_stock || 0),
      eanMatchRate: matchRate,
      trends,
    };
  }

  private async calculateTrends(storeId: string, dateRange: any): Promise<any> {
    const db = this.db.getDb();
    
    // Compare current vs previous period
    const periodLength = dateRange.to.getTime() - dateRange.from.getTime();
    const previousFrom = new Date(dateRange.from.getTime() - periodLength);
    
    const result = await db.execute(sql`
      SELECT 
        (SELECT COUNT(*)::int FROM scan_items WHERE store_id = ${storeId} AND scanned_at BETWEEN ${dateRange.from} AND ${dateRange.to}) as current_scans,
        (SELECT COUNT(*)::int FROM scan_items WHERE store_id = ${storeId} AND scanned_at BETWEEN ${previousFrom} AND ${dateRange.from}) as previous_scans
    `);
    
    const current = Number((result.rows[0] as any)?.current_scans || 0);
    const previous = Number((result.rows[0] as any)?.previous_scans || 0);
    
    return {
      scans: this.getDirection(current, previous),
      expiry: 'flat', // Would compare expiry records
      tasks: 'flat',
      inventory: 'flat',
    };
  }

  private getDirection(current: number, previous: number): 'up' | 'down' | 'flat' {
    if (previous === 0) return current > 0 ? 'up' : 'flat';
    const change = (current - previous) / previous;
    if (change > 0.05) return 'up';
    if (change < -0.05) return 'down';
    return 'flat';
  }
}
```

### 3. Alerts Summary Service

```typescript
// server/src/modules/client-dashboard/services/alerts-summary.service.ts
import { Injectable } from '@nestjs/common';
import { DbService } from '../../../db/db.service';
import { sql } from 'drizzle-orm';

@Injectable()
export class AlertsSummaryService {
  constructor(private readonly db: DbService) {}

  async getAlerts(storeId: string): Promise<any> {
    const db = this.db.getDb();
    
    const [expiryAlerts, lowStockAlerts, taskAlerts] = await Promise.all([
      // Expiry alerts
      db.execute(sql`
        SELECT 
          status,
          COUNT(*)::int as count
        FROM expiry_alerts
        WHERE store_id = ${storeId}
          AND is_resolved = false
        GROUP BY status
      `),
      
      // Low stock alerts
      db.execute(sql`
        SELECT COUNT(*)::int as count
        FROM low_stock_alerts
        WHERE store_id = ${storeId}
          AND is_resolved = false
      `),
      
      // Overdue tasks
      db.execute(sql`
        SELECT COUNT(*)::int as count
        FROM tasks
        WHERE store_id = ${storeId}
          AND status = 'overdue'
          AND deleted_at IS NULL
      `),
    ]);
    
    const expiryByStatus: Record<string, number> = {};
    for (const row of expiryAlerts.rows as any[]) {
      expiryByStatus[row.status] = Number(row.count);
    }
    
    const critical = [];
    const warning = [];
    
    if (expiryByStatus.red > 0) {
      critical.push({
        id: 'expiry-red',
        type: 'expiry_red',
        title: `${expiryByStatus.red} items expired or expiring this week`,
        description: 'Remove from shelf immediately',
        count: expiryByStatus.red,
        actionUrl: '/expiry?status=red',
        createdAt: new Date(),
      });
    }
    
    if (expiryByStatus.yellow > 0) {
      warning.push({
        id: 'expiry-yellow',
        type: 'expiry_yellow',
        title: `${expiryByStatus.yellow} items expiring soon`,
        description: 'Plan discounts or rotation',
        count: expiryByStatus.yellow,
        actionUrl: '/expiry?status=yellow',
        createdAt: new Date(),
      });
    }
    
    const lowStockCount = Number((lowStockAlerts.rows[0] as any)?.count || 0);
    if (lowStockCount > 0) {
      warning.push({
        id: 'low-stock',
        type: 'low_stock',
        title: `${lowStockCount} products running low`,
        description: 'Place reorder soon',
        count: lowStockCount,
        actionUrl: '/inventory/low-stock',
        createdAt: new Date(),
      });
    }
    
    const overdueCount = Number((taskAlerts.rows[0] as any)?.count || 0);
    if (overdueCount > 0) {
      critical.push({
        id: 'tasks-overdue',
        type: 'task_overdue',
        title: `${overdueCount} tasks overdue`,
        description: 'Reassign or extend deadline',
        count: overdueCount,
        actionUrl: '/tasks?status=overdue',
        createdAt: new Date(),
      });
    }
    
    return {
      total: critical.length + warning.length,
      critical,
      warning,
      info: [],
    };
  }
}
```

### 4. Dashboard Cache Service

```typescript
// server/src/modules/client-dashboard/services/dashboard-cache.service.ts
import { Injectable, OnModuleInit } from '@nestjs/common';
import Redis from 'ioredis';
import { ConfigService } from '../../../config/config.service';

@Injectable()
export class DashboardCacheService implements OnModuleInit {
  private redis!: Redis;
  private readonly KEY_PREFIX = 'dashboard:';

  constructor(private readonly config: ConfigService) {}

  onModuleInit() {
    this.redis = new Redis({
      host: this.config.redis.host,
      port: this.config.redis.port,
      password: this.config.redis.password,
      keyPrefix: this.config.redis.keyPrefix,
    });
  }

  async get<T>(key: string): Promise<T | null> {
    try {
      const value = await this.redis.get(`${this.KEY_PREFIX}${key}`);
      return value ? JSON.parse(value) : null;
    } catch {
      return null;
    }
  }

  async set(key: string, value: any, ttlSeconds: number = 300): Promise<void> {
    try {
      await this.redis.setex(
        `${this.KEY_PREFIX}${key}`,
        ttlSeconds,
        JSON.stringify(value),
      );
    } catch {
      // Cache failure should not break app
    }
  }

  async invalidate(pattern: string): Promise<void> {
    try {
      const keys = await this.redis.keys(`${this.KEY_PREFIX}${pattern}*`);
      if (keys.length > 0) {
        await this.redis.del(...keys);
      }
    } catch {
      // Best-effort
    }
  }
}
```

## API Endpoints

| Method | Endpoint | Auth | Role | Purpose |
|---|---|---|---|---|
| GET | `/api/v1/dashboard` | Bearer | Staff+ | Full dashboard for store |
| GET | `/api/v1/dashboard/kpis` | Bearer | Staff+ | KPIs only |
| GET | `/api/v1/dashboard/alerts` | Bearer | Staff+ | Active alerts |
| GET | `/api/v1/dashboard/quick-actions` | Bearer | Staff+ | Quick action buttons |
| GET | `/api/v1/dashboard/trends` | Bearer | Manager+ | Trend data |
| GET | `/api/v1/dashboard/team` | Bearer | Manager+ | Team performance |
| GET | `/api/v1/dashboard/activity` | Bearer | Staff+ | Recent activity |
| GET | `/api/v1/dashboard/multi-store` | Bearer | Owner | Multi-store summary |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-31 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Full Dashboard ✅
```bash
curl .../dashboard?storeId=<id>
```
**Expected**: All sections populated in single response
**Pass Criteria**: ✅ Dashboard returns < 1 second

### Test 2: Tenant Isolation ✅
User from Tenant A requests Tenant B store dashboard:
**Expected**: 404 (TenantScopedRepository blocks)
**Pass Criteria**: ✅ Cross-tenant blocked

### Test 3: Store-Level Access ✅
User without access to store:
**Expected**: 403 STORE_ACCESS_DENIED
**Pass Criteria**: ✅ Store check enforced

### Test 4: KPIs Accuracy ✅
**Pass Criteria**: ✅ All counts match raw queries

### Test 5: Alert Aggregation ✅
**Pass Criteria**: ✅ Alerts grouped by severity correctly

### Test 6: Quick Actions Disabled ✅
Trial user at AI limit → AI quick action disabled with reason
**Pass Criteria**: ✅ Subscription-aware

### Test 7: Trends Calculation ✅
Compare to previous period:
**Pass Criteria**: ✅ Trend direction accurate

### Test 8: Team Performance ✅
**Pass Criteria**: ✅ Top scanners ranked correctly

### Test 9: Recent Activity ✅
**Pass Criteria**: ✅ Chronological feed from multiple sources

### Test 10: Multi-Store Summary ✅
Owner with 5 stores:
**Pass Criteria**: ✅ All stores summarized + aggregated

### Test 11: Caching ✅
First call: < 800ms (cold)
Second call: < 50ms (cached)
**Pass Criteria**: ✅ Redis caching works

### Test 12: Cache Invalidation ✅
After scan, dashboard updates:
**Pass Criteria**: ✅ Stale data prevented

### Test 13: Performance — 10K records ✅
Store with 10K scans, 1K products:
**Pass Criteria**: ✅ Dashboard < 1.5s

### Test 14: Concurrent Requests ✅
50 simultaneous dashboard requests:
**Pass Criteria**: ✅ All succeed, cache helps

### Test 15: Subscription Status ✅
Show plan, trial days, usage %:
**Pass Criteria**: ✅ Accurate subscription info

## 🎯 Q&A Session

### Q1: Why one-shot dashboard endpoint?
**Expected**: Mobile network efficient, single render, parallel queries server-side

### Q2: Why parallel queries?
**Expected**: 6 sequential = 3s, parallel = 500ms, dramatically better UX

### Q3: Why 5-min cache?
**Expected**: Real-time-ish, reduces DB load 90%, acceptable freshness

### Q4: Why tenant-scoped?
**Expected**: CRITICAL privacy boundary, prevents leakage, foundation of trust

### Q5: How to keep dashboard fast at scale?
**Expected**: Indexed queries, denormalized counts, Redis cache, daily aggregations

### Q6: Why subscription-aware quick actions?
**Expected**: Users see what they can do, prevents frustration, drives upgrades

### Q7: How handle multi-store owners?
**Expected**: Aggregate view + drill-down, both available

### Q8: Why separate from owner dashboard?
**Expected**: Different data scope, different access, different UI, privacy

## 📝 Sign-Off Checklist

- [ ] All 15 tests pass
- [ ] Tenant isolation verified
- [ ] Performance benchmarks met
- [ ] Caching works
- [ ] Subscription integration works
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-31**
**☐ CHANGES REQUESTED**

---

**END OF BE-30 — DO NOT PROCEED WITHOUT APPROVAL**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-30 (Client In-App Dashboard) with the Operational Health Score calculation and 30-day trend (Req 29).**

## Driver Requirements

- **Req 29** — Operational_Health_Score (0–100) computed daily from 6 weighted components: Compliance 25%, Expiry Management 20%, Inventory Accuracy 20%, Task Completion 15%, Team Activity 10%, Vendor Quality 10%. Algorithm versioned (e.g., "v1.2"). 30-day trend on Client_Dashboard. ±10 point day-over-day change triggers FCM to Owner.

## Scope of Update

The v1 Client Dashboard exposed simple metrics. v2 adds a dedicated `OperationalHealthScoreService` that runs daily and exposes the score, the per-component breakdown, the 30-day trend, and the algorithm version, all served by the dashboard endpoint.

## Files to Create / Modify

| File Path | Change |
|---|---|
| `server/src/modules/dashboard/services/operational-health-score.service.ts` | New |
| `server/src/modules/dashboard/services/components/compliance.calculator.ts` | New |
| `server/src/modules/dashboard/services/components/expiry-management.calculator.ts` | New |
| `server/src/modules/dashboard/services/components/inventory-accuracy.calculator.ts` | New |
| `server/src/modules/dashboard/services/components/task-completion.calculator.ts` | New |
| `server/src/modules/dashboard/services/components/team-activity.calculator.ts` | New |
| `server/src/modules/dashboard/services/components/vendor-quality.calculator.ts` | New |
| `server/src/modules/dashboard/jobs/health-score-daily.job.ts` | New cron (daily 02:00 IST) |
| `server/src/database/migrations/v2/2026XXXX_health_scores.sql` | New table |

## Schema

```sql
CREATE TABLE operational_health_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  store_id UUID REFERENCES stores(id),
  computed_for_date DATE NOT NULL,
  algorithm_version TEXT NOT NULL,    -- e.g., "v1.2"
  total_score NUMERIC(5,2) NOT NULL CHECK (total_score BETWEEN 0 AND 100),
  compliance_component NUMERIC(5,2) NOT NULL,
  expiry_component NUMERIC(5,2) NOT NULL,
  inventory_component NUMERIC(5,2) NOT NULL,
  task_component NUMERIC(5,2) NOT NULL,
  team_activity_component NUMERIC(5,2) NOT NULL,
  vendor_quality_component NUMERIC(5,2) NOT NULL,
  raw_inputs JSONB NOT NULL,           -- snapshot of inputs for audit
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (tenant_id, store_id, computed_for_date, algorithm_version)
);

CREATE INDEX idx_ohs_trend ON operational_health_scores(tenant_id, store_id, computed_for_date DESC);
```

## Calculator Pattern

```typescript
export interface IComponentCalculator {
  readonly name: string;
  readonly weight: number;     // 0..1, sums to 1 across all components
  compute(input: ComponentInput): Promise<ComponentResult>;
}

export interface ComponentResult {
  rawScore: number;            // 0..100 component score
  rawInputs: Record<string, unknown>;
}
```

## Score Service

```typescript
@Injectable()
export class OperationalHealthScoreService {
  static readonly ALGORITHM_VERSION = 'v1.0';

  constructor(
    private readonly compliance: ComplianceCalculator,
    private readonly expiry: ExpiryCalculator,
    private readonly inventory: InventoryAccuracyCalculator,
    private readonly tasks: TaskCompletionCalculator,
    private readonly team: TeamActivityCalculator,
    private readonly vendor: VendorQualityCalculator,
  ) {}

  async computeForStore(tenantId: string, storeId: string, date: Date): Promise<HealthScoreSnapshot> {
    const calculators: IComponentCalculator[] = [
      this.compliance,    // weight 0.25
      this.expiry,        // weight 0.20
      this.inventory,     // weight 0.20
      this.tasks,         // weight 0.15
      this.team,          // weight 0.10
      this.vendor,        // weight 0.10
    ];

    const results = await Promise.all(calculators.map(c => c.compute({ tenantId, storeId, date })));
    const total = calculators.reduce((sum, c, i) => sum + c.weight * results[i].rawScore, 0);

    return {
      total,
      breakdown: Object.fromEntries(calculators.map((c, i) => [c.name, results[i].rawScore])),
      rawInputs: Object.fromEntries(calculators.map((c, i) => [c.name, results[i].rawInputs])),
      algorithmVersion: OperationalHealthScoreService.ALGORITHM_VERSION,
    };
  }
}
```

## Daily Cron + Drop Alert

```typescript
@Cron('0 2 * * *', { timeZone: 'Asia/Kolkata' })
async runDailyHealthScores() {
  for (const { tenantId, storeId } of await this.tenants.activeBusinessStores()) {
    const today = await this.scores.computeForStore(tenantId, storeId, new Date());
    await this.scores.persist(tenantId, storeId, today);

    const prev = await this.scores.previousDay(tenantId, storeId);
    if (prev && Math.abs(today.total - prev.total) >= 10) {
      await this.notifications.send({
        tenantId,
        category: 'operational_health_alert',
        title: 'Health Score changed by 10+ points',
        body: `New score: ${today.total.toFixed(1)} (was ${prev.total.toFixed(1)})`,
      });
    }
  }
}
```

## Dashboard Endpoint Update

```typescript
@Get('/health-score')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('owner', 'manager')
async getHealthScore(@CurrentTenant() tenantId: string, @Query('storeId') storeId: string) {
  return {
    latest: await this.scores.latest(tenantId, storeId),
    trend30d: await this.scores.trend(tenantId, storeId, 30),
    algorithmVersion: OperationalHealthScoreService.ALGORITHM_VERSION,
  };
}
```

## ADDENDUM v2 Test Procedures (add 6)

| # | Test |
|---|---|
| T-v2.1 | Score for a store with 100% perfect inputs ≈ 100; with worst inputs ≈ 0 |
| T-v2.2 | Component weights sum to exactly 1.0 |
| T-v2.3 | Algorithm version persisted with each row |
| T-v2.4 | 30-day trend endpoint returns up to 30 daily snapshots in order |
| T-v2.5 | Day-over-day delta of 10+ triggers an FCM notification (subject to Notification_Preferences) |
| T-v2.6 | Property test: For all valid (tenant, store, date) inputs, total score ∈ [0, 100] |

## ADDENDUM v2 Q&A (add 3)

- **Q-v2.1**: Why is algorithm version stored per row instead of globally? (Hint: Req 29 historical-validity rule)
- **Q-v2.2**: How does the system avoid double-computing for the same date if the cron runs twice (idempotency)?
- **Q-v2.3**: When the algorithm changes from v1.0 to v1.1, how does the dashboard render the trend so old and new scores aren't mixed misleadingly?

## ADDENDUM v2 Sign-off

- [ ] All 6 component calculators implemented
- [ ] Daily cron live and idempotent
- [ ] Algorithm versioning persisted
- [ ] 30-day trend endpoint live
- [ ] Drop-alert FCM tested

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-30 ADDENDUM v2**
