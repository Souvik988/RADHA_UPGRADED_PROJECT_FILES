# Phase BE-20: Report Generation Engine

## Phase Metadata

- **Phase ID**: BE-20
- **Phase Name**: Report Generation Engine
- **Section**: Backend Execution — Operations Layer
- **Depends On**: BE-01 to BE-19
- **Blocks**: BE-21 (export uses generation)
- **Estimated Duration**: 3 days
- **Complexity**: High

## Goal

Build flexible report generation engine: report types (expiry summary, EAN mismatch, scan history, inventory, GRN, task completion), async generation via Bull queue, parameter-driven queries, aggregation pipelines, caching for fast dashboards, scheduled reports, and audit trail.

## Why This Phase Matters

Reports turn data into decisions:
- Owners see store performance
- Managers identify problems
- Auditors verify compliance
- Vendors held accountable
- Premium feature for paid plans

## Prerequisites

- [ ] BE-01 to BE-19 completed
- [ ] All data sources populated
- [ ] Bull queue working

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/reports.ts` | Report metadata |
| `server/src/db/schema/report_files.ts` | Generated files |
| `server/src/db/schema/scheduled_reports.ts` | Scheduled jobs |
| `server/src/db/schema/daily_store_metrics.ts` | Pre-aggregated daily |
| `server/src/modules/reports/reports.module.ts` | Module |
| `server/src/modules/reports/reports.controller.ts` | Endpoints |
| `server/src/modules/reports/reports.service.ts` | Main service |
| `server/src/modules/reports/services/report-generator.service.ts` | Core generator |
| `server/src/modules/reports/services/report-queue.service.ts` | Async queue |
| `server/src/modules/reports/generators/expiry-summary.generator.ts` | Expiry report |
| `server/src/modules/reports/generators/ean-mismatch.generator.ts` | EAN mismatch |
| `server/src/modules/reports/generators/scan-history.generator.ts` | Scan history |
| `server/src/modules/reports/generators/task-completion.generator.ts` | Task report |
| `server/src/modules/reports/generators/dashboard-summary.generator.ts` | Dashboard data |
| `server/src/modules/reports/processors/report-generation.processor.ts` | Bull worker |
| `server/src/modules/reports/services/metrics-aggregator.service.ts` | Daily aggregations |
| `server/src/modules/reports/repositories/reports.repository.ts` | Reports data |
| `server/src/modules/reports/dto/generate-report.dto.ts` | DTOs |
| `server/src/modules/reports/dto/list-reports.dto.ts` | DTOs |
| `server/src/modules/reports/types/report.types.ts` | Types |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/reports/reports.service.ts

export interface IReportsService {
  // Generation
  generate(dto: GenerateReportDto, userId: string): Promise<ReportGenerationResult>;
  
  // Status
  getStatus(reportId: string): Promise<ReportStatus>;
  
  // Listing
  list(filters: ListReportsFilter): Promise<PaginatedResult<Report>>;
  findById(id: string): Promise<ReportWithFiles | null>;
  
  // Download
  getDownloadUrl(reportId: string, format: ReportFormat): Promise<string>;
  
  // Scheduled
  scheduleReport(dto: ScheduleReportDto): Promise<ScheduledReport>;
  cancelScheduled(id: string): Promise<void>;
  
  // Dashboard summary (live, cached)
  getDashboardSummary(storeId: string, dateRange: DateRange): Promise<DashboardSummary>;
}

export type ReportType =
  | 'expiry-summary'
  | 'ean-mismatch'
  | 'scan-history'
  | 'task-completion'
  | 'inventory-summary'
  | 'grn-history'
  | 'health-distribution'
  | 'audit-trail'
  | 'dashboard';

export type ReportFormat = 'pdf' | 'xlsx' | 'csv' | 'json';

export type ReportStatus =
  | 'pending'
  | 'generating'
  | 'completed'
  | 'failed'
  | 'expired';

export interface GenerateReportDto {
  type: ReportType;
  format: ReportFormat[];
  storeIds?: string[];
  dateRange: DateRange;
  filters?: Record<string, unknown>;
  groupBy?: string[];
  includeCharts?: boolean;
}

export interface DateRange {
  from: Date;
  to: Date;
}

export interface ReportGenerationResult {
  reportId: string;
  status: ReportStatus;
  estimatedDurationSeconds: number;
}

export interface ReportWithFiles extends Report {
  files: ReportFile[];
}

export interface DashboardSummary {
  storeId: string;
  dateRange: DateRange;
  totals: {
    scans: number;
    sessionsCompleted: number;
    expiryRecords: number;
    activeAlerts: number;
    tasksCompleted: number;
    tasksOverdue: number;
  };
  expiry: {
    green: number;
    yellow: number;
    red: number;
    expired: number;
  };
  scanHealth: {
    matched: number;
    unmatched: number;
    matchRate: number;
  };
  trends: Array<{
    date: Date;
    scans: number;
    expiryAdded: number;
    tasksCompleted: number;
  }>;
  topProducts: Array<{ productId: string; productName: string; scanCount: number }>;
  topUsers: Array<{ userId: string; userName: string; scanCount: number }>;
}
```

## Implementation Code

### 1. Reports Schema

```typescript
// server/src/db/schema/reports.ts
import { pgTable, varchar, uuid, integer, timestamp, jsonb, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns, softDeleteColumn, auditColumns } from './_base';

export const reportTypeEnum = pgEnum('report_type', [
  'expiry-summary',
  'ean-mismatch',
  'scan-history',
  'task-completion',
  'inventory-summary',
  'grn-history',
  'health-distribution',
  'audit-trail',
  'dashboard',
]);

export const reportStatusEnum = pgEnum('report_status', [
  'pending',
  'generating',
  'completed',
  'failed',
  'expired',
]);

export const reports = pgTable(
  'reports',
  {
    ...baseColumns,
    ...softDeleteColumn,
    ...auditColumns,
    tenantId: uuid('tenant_id').notNull(),
    storeId: uuid('store_id'),
    
    type: reportTypeEnum('type').notNull(),
    title: varchar('title', { length: 200 }).notNull(),
    status: reportStatusEnum('status').notNull().default('pending'),
    
    // Parameters
    parameters: jsonb('parameters').notNull(),
    
    // Date range
    dateFrom: timestamp('date_from', { withTimezone: true }),
    dateTo: timestamp('date_to', { withTimezone: true }),
    
    // Generation
    requestedBy: uuid('requested_by').notNull(),
    generationStartedAt: timestamp('generation_started_at', { withTimezone: true }),
    generationCompletedAt: timestamp('generation_completed_at', { withTimezone: true }),
    generationDurationMs: integer('generation_duration_ms'),
    
    // Results
    rowCount: integer('row_count'),
    summary: jsonb('summary'), // Quick stats for dashboard
    errorMessage: varchar('error_message', { length: 1000 }),
    
    // Expiration
    expiresAt: timestamp('expires_at', { withTimezone: true }),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    tenantTypeIdx: index('idx_reports_tenant_type').on(table.tenantId, table.type),
    storeCreatedIdx: index('idx_reports_store_created').on(table.storeId, table.createdAt),
    statusIdx: index('idx_reports_status').on(table.status),
    expiresIdx: index('idx_reports_expires').on(table.expiresAt),
  }),
);

export type Report = typeof reports.$inferSelect;
```

### 2. Daily Store Metrics (Pre-aggregated)

```typescript
// server/src/db/schema/daily_store_metrics.ts
import { pgTable, varchar, uuid, integer, timestamp, decimal, index, unique } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const dailyStoreMetrics = pgTable(
  'daily_store_metrics',
  {
    ...baseColumns,
    tenantId: uuid('tenant_id').notNull(),
    storeId: uuid('store_id').notNull(),
    date: timestamp('date', { withTimezone: true }).notNull(),
    
    // Scan metrics
    totalScans: integer('total_scans').notNull().default(0),
    uniqueProducts: integer('unique_products').notNull().default(0),
    matchedScans: integer('matched_scans').notNull().default(0),
    unmatchedScans: integer('unmatched_scans').notNull().default(0),
    
    // Sessions
    sessionsStarted: integer('sessions_started').notNull().default(0),
    sessionsCompleted: integer('sessions_completed').notNull().default(0),
    
    // Expiry
    expiryRecordsAdded: integer('expiry_records_added').notNull().default(0),
    expiredItems: integer('expired_items').notNull().default(0),
    nearExpiryItems: integer('near_expiry_items').notNull().default(0),
    alertsGenerated: integer('alerts_generated').notNull().default(0),
    alertsResolved: integer('alerts_resolved').notNull().default(0),
    
    // Tasks
    tasksCreated: integer('tasks_created').notNull().default(0),
    tasksCompleted: integer('tasks_completed').notNull().default(0),
    tasksOverdue: integer('tasks_overdue').notNull().default(0),
    averageTaskMinutes: decimal('average_task_minutes', { precision: 10, scale: 2 }),
    
    // Users
    activeUsers: integer('active_users').notNull().default(0),
  },
  (table) => ({
    storeDateIdx: unique('uniq_metrics_store_date').on(table.storeId, table.date),
    tenantDateIdx: index('idx_metrics_tenant_date').on(table.tenantId, table.date),
  }),
);

export type DailyStoreMetric = typeof dailyStoreMetrics.$inferSelect;
```

### 3. Report Generator Service

```typescript
// server/src/modules/reports/services/report-generator.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ReportsRepository } from '../repositories/reports.repository';
import { ExpirySummaryGenerator } from '../generators/expiry-summary.generator';
import { EanMismatchGenerator } from '../generators/ean-mismatch.generator';
import { ScanHistoryGenerator } from '../generators/scan-history.generator';
import { TaskCompletionGenerator } from '../generators/task-completion.generator';
import { DashboardSummaryGenerator } from '../generators/dashboard-summary.generator';
import { LoggerService } from '../../../logging/logger.service';
import { ReportType, GenerateReportDto } from '../types/report.types';

interface IReportGenerator<T> {
  generate(params: GenerateReportDto, tenantId: string): Promise<T>;
}

@Injectable()
export class ReportGeneratorService {
  private readonly logger = new Logger(ReportGeneratorService.name);
  
  private generators: Map<ReportType, IReportGenerator<any>> = new Map();

  constructor(
    private readonly reportsRepo: ReportsRepository,
    private readonly appLogger: LoggerService,
    expiryGen: ExpirySummaryGenerator,
    eanGen: EanMismatchGenerator,
    scanGen: ScanHistoryGenerator,
    taskGen: TaskCompletionGenerator,
    dashboardGen: DashboardSummaryGenerator,
  ) {
    this.generators.set('expiry-summary', expiryGen);
    this.generators.set('ean-mismatch', eanGen);
    this.generators.set('scan-history', scanGen);
    this.generators.set('task-completion', taskGen);
    this.generators.set('dashboard', dashboardGen);
  }

  async generateReport(reportId: string): Promise<void> {
    const report = await this.reportsRepo.findById(reportId);
    if (!report) throw new Error(`Report not found: ${reportId}`);
    
    const startTime = Date.now();
    
    try {
      await this.reportsRepo.update(reportId, {
        status: 'generating',
        generationStartedAt: new Date(),
      });
      
      const generator = this.generators.get(report.type as ReportType);
      if (!generator) {
        throw new Error(`No generator for type: ${report.type}`);
      }
      
      const data = await generator.generate(
        report.parameters as GenerateReportDto,
        report.tenantId,
      );
      
      const duration = Date.now() - startTime;
      
      await this.reportsRepo.update(reportId, {
        status: 'completed',
        generationCompletedAt: new Date(),
        generationDurationMs: duration,
        rowCount: this.countRows(data),
        summary: this.extractSummary(data),
      });
      
      // BE-21 will handle file generation (Excel/PDF) from this data
      
      this.appLogger.info('Report generated', {
        reportId,
        type: report.type,
        durationMs: duration,
      });
    } catch (error) {
      await this.reportsRepo.update(reportId, {
        status: 'failed',
        errorMessage: error instanceof Error ? error.message : 'Unknown',
        generationCompletedAt: new Date(),
      });
      throw error;
    }
  }

  private countRows(data: unknown): number {
    if (Array.isArray(data)) return data.length;
    if (data && typeof data === 'object' && 'rows' in data) {
      return Array.isArray((data as any).rows) ? (data as any).rows.length : 0;
    }
    return 0;
  }

  private extractSummary(data: unknown): Record<string, unknown> {
    if (data && typeof data === 'object' && 'summary' in data) {
      return (data as any).summary;
    }
    return {};
  }
}
```

### 4. Expiry Summary Generator

```typescript
// server/src/modules/reports/generators/expiry-summary.generator.ts
import { Injectable } from '@nestjs/common';
import { DbService } from '../../../db/db.service';
import { sql } from 'drizzle-orm';

@Injectable()
export class ExpirySummaryGenerator {
  constructor(private readonly db: DbService) {}

  async generate(params: any, tenantId: string): Promise<any> {
    const db = this.db.getDb();
    
    const conditions = [
      sql`tenant_id = ${tenantId}`,
      sql`deleted_at IS NULL`,
    ];
    
    if (params.storeIds?.length) {
      conditions.push(sql`store_id = ANY(ARRAY[${params.storeIds.join(',')}]::uuid[])`);
    }
    
    if (params.dateRange) {
      conditions.push(sql`expiry_date >= ${params.dateRange.from}`);
      conditions.push(sql`expiry_date <= ${params.dateRange.to}`);
    }
    
    // Main aggregation query
    const summary = await db.execute(sql`
      SELECT 
        status,
        COUNT(*) as count,
        SUM(quantity) as total_quantity
      FROM expiry_records
      WHERE ${sql.join(conditions, sql` AND `)}
      GROUP BY status
    `);
    
    // Detailed rows
    const rows = await db.execute(sql`
      SELECT 
        er.id,
        er.expiry_date,
        er.quantity,
        er.status,
        er.days_remaining,
        p.name as product_name,
        p.brand,
        p.ean,
        s.name as store_name
      FROM expiry_records er
      JOIN products p ON p.id = er.product_id
      JOIN stores s ON s.id = er.store_id
      WHERE ${sql.join(conditions, sql` AND `)}
      ORDER BY er.expiry_date ASC
      LIMIT 10000
    `);
    
    // By category
    const byCategory = await db.execute(sql`
      SELECT 
        p.category_id,
        p.sub_category,
        er.status,
        COUNT(*) as count,
        SUM(er.quantity) as total_quantity
      FROM expiry_records er
      JOIN products p ON p.id = er.product_id
      WHERE ${sql.join(conditions, sql` AND `)}
      GROUP BY p.category_id, p.sub_category, er.status
    `);
    
    return {
      summary: this.computeSummary(summary.rows),
      rows: rows.rows,
      byCategory: byCategory.rows,
      generatedAt: new Date(),
      parameters: params,
    };
  }

  private computeSummary(rows: any[]): Record<string, unknown> {
    const result = {
      total: 0,
      green: 0,
      yellow: 0,
      red: 0,
      expired: 0,
    };
    
    for (const row of rows) {
      result.total += Number(row.count);
      result[row.status as keyof typeof result] = Number(row.count);
    }
    
    return result;
  }
}
```

### 5. Dashboard Summary Generator

```typescript
// server/src/modules/reports/generators/dashboard-summary.generator.ts
import { Injectable } from '@nestjs/common';
import { DbService } from '../../../db/db.service';
import { sql } from 'drizzle-orm';
import { DashboardSummary } from '../types/report.types';

@Injectable()
export class DashboardSummaryGenerator {
  constructor(private readonly db: DbService) {}

  async generate(params: any, tenantId: string): Promise<DashboardSummary> {
    const db = this.db.getDb();
    const { storeId, dateRange } = params;
    
    // Run all queries in parallel for performance
    const [
      scanStats,
      expiryStats,
      taskStats,
      trends,
      topProducts,
      topUsers,
    ] = await Promise.all([
      this.getScanStats(db, tenantId, storeId, dateRange),
      this.getExpiryStats(db, tenantId, storeId, dateRange),
      this.getTaskStats(db, tenantId, storeId, dateRange),
      this.getTrends(db, tenantId, storeId, dateRange),
      this.getTopProducts(db, tenantId, storeId, dateRange),
      this.getTopUsers(db, tenantId, storeId, dateRange),
    ]);
    
    return {
      storeId,
      dateRange,
      totals: {
        scans: scanStats.total,
        sessionsCompleted: scanStats.sessionsCompleted,
        expiryRecords: expiryStats.total,
        activeAlerts: expiryStats.activeAlerts,
        tasksCompleted: taskStats.completed,
        tasksOverdue: taskStats.overdue,
      },
      expiry: {
        green: expiryStats.green,
        yellow: expiryStats.yellow,
        red: expiryStats.red,
        expired: expiryStats.expired,
      },
      scanHealth: {
        matched: scanStats.matched,
        unmatched: scanStats.unmatched,
        matchRate: scanStats.total > 0 
          ? Math.round((scanStats.matched / scanStats.total) * 100) 
          : 0,
      },
      trends,
      topProducts,
      topUsers,
    };
  }

  private async getScanStats(db: any, tenantId: string, storeId: string, dateRange: any) {
    const result = await db.execute(sql`
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN ean_match_status = 'matched' THEN 1 ELSE 0 END) as matched,
        SUM(CASE WHEN ean_match_status = 'unmatched' THEN 1 ELSE 0 END) as unmatched
      FROM scan_items
      WHERE tenant_id = ${tenantId}
        AND store_id = ${storeId}
        AND scanned_at >= ${dateRange.from}
        AND scanned_at <= ${dateRange.to}
    `);
    
    const sessions = await db.execute(sql`
      SELECT COUNT(*) as completed
      FROM scan_sessions
      WHERE tenant_id = ${tenantId}
        AND store_id = ${storeId}
        AND status = 'completed'
        AND ended_at >= ${dateRange.from}
        AND ended_at <= ${dateRange.to}
    `);
    
    return {
      total: Number(result.rows[0]?.total || 0),
      matched: Number(result.rows[0]?.matched || 0),
      unmatched: Number(result.rows[0]?.unmatched || 0),
      sessionsCompleted: Number(sessions.rows[0]?.completed || 0),
    };
  }

  private async getExpiryStats(db: any, tenantId: string, storeId: string, dateRange: any) {
    const result = await db.execute(sql`
      SELECT 
        status,
        COUNT(*) as count
      FROM expiry_records
      WHERE tenant_id = ${tenantId}
        AND store_id = ${storeId}
        AND deleted_at IS NULL
      GROUP BY status
    `);
    
    const alerts = await db.execute(sql`
      SELECT COUNT(*) as active
      FROM expiry_alerts
      WHERE tenant_id = ${tenantId}
        AND store_id = ${storeId}
        AND is_resolved = false
    `);
    
    const stats = { total: 0, green: 0, yellow: 0, red: 0, expired: 0 };
    for (const row of result.rows) {
      stats[row.status as keyof typeof stats] = Number(row.count);
      stats.total += Number(row.count);
    }
    
    return {
      ...stats,
      activeAlerts: Number(alerts.rows[0]?.active || 0),
    };
  }

  private async getTaskStats(db: any, tenantId: string, storeId: string, dateRange: any) {
    const result = await db.execute(sql`
      SELECT 
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
        SUM(CASE WHEN status = 'overdue' THEN 1 ELSE 0 END) as overdue
      FROM tasks
      WHERE tenant_id = ${tenantId}
        AND store_id = ${storeId}
        AND created_at >= ${dateRange.from}
        AND created_at <= ${dateRange.to}
    `);
    
    return {
      completed: Number(result.rows[0]?.completed || 0),
      overdue: Number(result.rows[0]?.overdue || 0),
    };
  }

  private async getTrends(db: any, tenantId: string, storeId: string, dateRange: any) {
    // Query daily_store_metrics (pre-aggregated)
    const result = await db.execute(sql`
      SELECT 
        date,
        total_scans as scans,
        expiry_records_added as expiry_added,
        tasks_completed
      FROM daily_store_metrics
      WHERE tenant_id = ${tenantId}
        AND store_id = ${storeId}
        AND date >= ${dateRange.from}
        AND date <= ${dateRange.to}
      ORDER BY date ASC
    `);
    
    return result.rows.map((r: any) => ({
      date: r.date,
      scans: Number(r.scans),
      expiryAdded: Number(r.expiry_added),
      tasksCompleted: Number(r.tasks_completed),
    }));
  }

  private async getTopProducts(db: any, tenantId: string, storeId: string, dateRange: any) {
    const result = await db.execute(sql`
      SELECT 
        si.product_id,
        p.name as product_name,
        COUNT(*) as scan_count
      FROM scan_items si
      LEFT JOIN products p ON p.id = si.product_id
      WHERE si.tenant_id = ${tenantId}
        AND si.store_id = ${storeId}
        AND si.scanned_at >= ${dateRange.from}
        AND si.scanned_at <= ${dateRange.to}
        AND si.product_id IS NOT NULL
      GROUP BY si.product_id, p.name
      ORDER BY scan_count DESC
      LIMIT 10
    `);
    
    return result.rows.map((r: any) => ({
      productId: r.product_id,
      productName: r.product_name || 'Unknown',
      scanCount: Number(r.scan_count),
    }));
  }

  private async getTopUsers(db: any, tenantId: string, storeId: string, dateRange: any) {
    const result = await db.execute(sql`
      SELECT 
        si.user_id,
        u.name as user_name,
        COUNT(*) as scan_count
      FROM scan_items si
      JOIN users u ON u.id = si.user_id
      WHERE si.tenant_id = ${tenantId}
        AND si.store_id = ${storeId}
        AND si.scanned_at >= ${dateRange.from}
        AND si.scanned_at <= ${dateRange.to}
      GROUP BY si.user_id, u.name
      ORDER BY scan_count DESC
      LIMIT 10
    `);
    
    return result.rows.map((r: any) => ({
      userId: r.user_id,
      userName: r.user_name,
      scanCount: Number(r.scan_count),
    }));
  }
}
```

### 6. Metrics Aggregator (Daily Cron)

```typescript
// server/src/modules/reports/services/metrics-aggregator.service.ts
import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { DbService } from '../../../db/db.service';
import { LoggerService } from '../../../logging/logger.service';
import { sql } from 'drizzle-orm';

@Injectable()
export class MetricsAggregatorService {
  constructor(
    private readonly db: DbService,
    private readonly logger: LoggerService,
  ) {}

  // Run daily at 1 AM
  @Cron(CronExpression.EVERY_DAY_AT_1AM)
  async aggregateYesterday(): Promise<void> {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);
    
    await this.aggregateForDate(yesterday);
  }

  async aggregateForDate(date: Date): Promise<void> {
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);
    
    const db = this.db.getDb();
    
    this.logger.info('Aggregating metrics for date', { date: startOfDay });
    
    // Aggregate per store, then upsert
    await db.execute(sql`
      INSERT INTO daily_store_metrics (
        tenant_id, store_id, date,
        total_scans, unique_products, matched_scans, unmatched_scans,
        sessions_started, sessions_completed,
        expiry_records_added, expired_items, near_expiry_items,
        tasks_created, tasks_completed
      )
      SELECT 
        tenant_id, store_id, ${startOfDay}::date as date,
        COUNT(DISTINCT si.id) as total_scans,
        COUNT(DISTINCT si.ean) as unique_products,
        SUM(CASE WHEN si.ean_match_status = 'matched' THEN 1 ELSE 0 END) as matched_scans,
        SUM(CASE WHEN si.ean_match_status = 'unmatched' THEN 1 ELSE 0 END) as unmatched_scans,
        0, 0, 0, 0, 0, 0, 0
      FROM scan_items si
      WHERE si.scanned_at >= ${startOfDay}
        AND si.scanned_at <= ${endOfDay}
      GROUP BY tenant_id, store_id
      ON CONFLICT (store_id, date) DO UPDATE SET
        total_scans = EXCLUDED.total_scans,
        unique_products = EXCLUDED.unique_products,
        matched_scans = EXCLUDED.matched_scans,
        unmatched_scans = EXCLUDED.unmatched_scans
    `);
    
    // Similarly aggregate other metrics (sessions, expiry, tasks)
    // ... omitted for brevity
    
    this.logger.info('Metrics aggregation complete', { date: startOfDay });
  }
}
```

### 7. Reports Service

```typescript
// server/src/modules/reports/reports.service.ts
import { Injectable } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';
import { ReportsRepository } from './repositories/reports.repository';
import { DashboardSummaryGenerator } from './generators/dashboard-summary.generator';
import { v4 as uuidv4 } from 'uuid';
import {
  IReportsService,
  GenerateReportDto,
  ReportGenerationResult,
  DashboardSummary,
} from './types/report.types';
import { NotFoundException } from '../../common/errors/business.exception';

@Injectable()
export class ReportsService implements IReportsService {
  constructor(
    private readonly reportsRepo: ReportsRepository,
    private readonly dashboardGen: DashboardSummaryGenerator,
    @InjectQueue('reports') private readonly queue: Queue,
  ) {}

  async generate(dto: GenerateReportDto, userId: string): Promise<ReportGenerationResult> {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 90); // 90 days retention
    
    const report = await this.reportsRepo.create({
      type: dto.type,
      title: this.buildTitle(dto),
      status: 'pending',
      parameters: dto,
      dateFrom: dto.dateRange.from,
      dateTo: dto.dateRange.to,
      requestedBy: userId,
      expiresAt,
    });
    
    // Queue for async processing
    await this.queue.add('generate-report', {
      reportId: report.id,
    }, {
      attempts: 3,
      backoff: { type: 'exponential', delay: 5000 },
    });
    
    return {
      reportId: report.id,
      status: 'pending',
      estimatedDurationSeconds: this.estimateDuration(dto),
    };
  }

  async getStatus(reportId: string): Promise<any> {
    const report = await this.reportsRepo.findById(reportId);
    if (!report) throw new NotFoundException('Report', reportId);
    return report;
  }

  async list(filters: any): Promise<any> {
    return this.reportsRepo.findPaginated(filters, {
      cursor: filters.cursor,
      limit: filters.limit || 50,
      orderBy: [{ field: 'createdAt', direction: 'desc' }],
    });
  }

  async findById(id: string): Promise<any> {
    return this.reportsRepo.findById(id);
  }

  async getDownloadUrl(reportId: string, format: any): Promise<string> {
    // Will be implemented in BE-21
    throw new Error('BE-21 will implement download URLs');
  }

  async scheduleReport(dto: any): Promise<any> {
    // Implementation
    throw new Error('Implement schedule logic');
  }

  async cancelScheduled(id: string): Promise<void> {
    // Implementation
  }

  async getDashboardSummary(
    storeId: string,
    dateRange: { from: Date; to: Date },
  ): Promise<DashboardSummary> {
    // Live generation, no queue (small data, fast)
    return this.dashboardGen.generate(
      { storeId, dateRange },
      'tenant-id-from-context',
    );
  }

  private buildTitle(dto: GenerateReportDto): string {
    return `${dto.type} - ${dto.dateRange.from.toISOString().split('T')[0]} to ${dto.dateRange.to.toISOString().split('T')[0]}`;
  }

  private estimateDuration(dto: GenerateReportDto): number {
    const days = Math.floor(
      (dto.dateRange.to.getTime() - dto.dateRange.from.getTime()) / (1000 * 60 * 60 * 24),
    );
    
    // Rough estimate: 1 second per day for most reports
    return Math.max(5, Math.min(300, days));
  }
}
```

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| POST | `/api/v1/reports/generate` | Bearer | Queue report |
| GET | `/api/v1/reports/:id` | Bearer | Status |
| GET | `/api/v1/reports` | Bearer | List reports |
| GET | `/api/v1/reports/:id/download` | Bearer | Download URL (BE-21) |
| GET | `/api/v1/dashboard/summary` | Bearer | Live dashboard |
| POST | `/api/v1/reports/schedule` | Bearer | Schedule recurring |
| DELETE | `/api/v1/reports/scheduled/:id` | Bearer | Cancel scheduled |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-21 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Generate Report ✅
```bash
curl -X POST .../reports/generate -d '{
  "type":"expiry-summary",
  "format":["pdf","xlsx"],
  "storeIds":["<id>"],
  "dateRange":{"from":"2024-01-01","to":"2024-12-31"}
}'
```
**Pass Criteria**: ✅ Returns reportId, status=pending

### Test 2: Status Tracking ✅
Poll status endpoint until completed
**Pass Criteria**: ✅ Status transitions: pending → generating → completed

### Test 3: Dashboard Summary ✅
```bash
curl ".../dashboard/summary?storeId=<id>&from=...&to=..."
```
**Expected**: Live data, < 500ms response
**Pass Criteria**: ✅ Fast dashboard query

### Test 4: All Report Types ✅
Generate each type:
- expiry-summary ✅
- ean-mismatch ✅
- scan-history ✅
- task-completion ✅

**Pass Criteria**: ✅ All generators work

### Test 5: Date Range Validation ✅
Invalid ranges (end before start) → 400
Future-only dates → 400
Range > 1 year → warning

**Pass Criteria**: ✅ Validation works

### Test 6: Tenant Isolation ✅
Reports only show tenant's data
**Pass Criteria**: ✅ No cross-tenant leakage

### Test 7: Daily Aggregation ✅
Run aggregator manually
Verify daily_store_metrics populated
**Pass Criteria**: ✅ Aggregation accurate

### Test 8: Report Expiration ✅
Reports expire after 90 days
**Pass Criteria**: ✅ Cleanup cron works

### Test 9: Performance — Large Report ✅
Generate 1-year scan history (100K rows)
**Expected**: Async, completes in < 2 minutes
**Pass Criteria**: ✅ Performance acceptable

### Test 10: Concurrent Reports ✅
Submit 10 reports simultaneously
**Expected**: All processed, no failures
**Pass Criteria**: ✅ Queue handles load

### Test 11: Failed Report Recovery ✅
Force a failure, verify retry
**Pass Criteria**: ✅ Bull retries work

### Test 12: Report Caching ✅
Same parameters: cached result returned (if recent)
**Pass Criteria**: ✅ Cache reduces load

### Test 13: Permissions ✅
Staff cannot generate reports → 403
Manager+ can → 200
**Pass Criteria**: ✅ Permissions enforced

### Test 14: Audit Trail ✅
Report generation logged in audit_logs
**Pass Criteria**: ✅ Compliance trail complete

### Test 15: Empty Data ✅
Generate report for store with no data
**Expected**: Empty report with summary showing zeros
**Pass Criteria**: ✅ Graceful empty state

## 🎯 Q&A Session

### Q1: Why async report generation?
**Expected**: Large reports timeout HTTP requests, async = better UX

### Q2: Why daily_store_metrics pre-aggregation?
**Expected**: Dashboard < 500ms, aggregating raw data takes minutes

### Q3: Why separate generators per type?
**Expected**: Different queries, different optimizations, easier to maintain

### Q4: How to handle very large reports?
**Expected**: Stream rows, paginate, time limit, resume capability

### Q5: Why 90-day retention?
**Expected**: Storage cost vs usefulness, regenerable from raw data

### Q6: Why dashboard parallel queries?
**Expected**: 6 sequential queries = 3s, parallel = 500ms

### Q7: How does scheduled reports work?
**Expected**: Cron job + queue, runs nightly, sends email notification

### Q8: How to scale to 100K reports/day?
**Expected**: Multiple Bull workers, partition daily_store_metrics, archive old

## 📝 Sign-Off Checklist

- [ ] All 15 tests pass
- [ ] All report types generate
- [ ] Dashboard < 500ms
- [ ] Aggregation accurate
- [ ] Async via Bull works
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-21**
**☐ CHANGES REQUESTED**

---

**END OF BE-20 — DO NOT PROCEED WITHOUT APPROVAL**
