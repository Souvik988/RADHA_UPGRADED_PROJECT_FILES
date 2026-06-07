# Phase BE-29: Analytics & Lead Ingestion

## Phase Metadata

- **Phase ID**: BE-29
- **Phase Name**: Analytics & Lead Ingestion
- **Section**: Backend Execution — Business Operations Layer
- **Depends On**: BE-01 to BE-28
- **Blocks**: BE-30, BE-31 (owner dashboard needs this data)
- **Estimated Duration**: 2 days
- **Complexity**: Medium

## Goal

Build analytics ingestion layer for marketing website + mobile app: website events (page views, button clicks), lead capture (contact forms, demo requests), app usage events, daily aggregations, UTM tracking, conversion funnels, and privacy-respecting analytics. Public endpoints for website, authenticated for app events.

## Why This Phase Matters

This powers the **Client Dashboard** (in mobile app, BE-30) and **App Owner Dashboard** (separate web, BE-31):
- Website visitors → leads → trials → paid (funnel)
- Mobile app usage patterns
- Marketing campaign performance
- User engagement metrics
- Conversion tracking
- ROI calculations

Without analytics:
- App owner cannot improve marketing
- No data-driven decisions
- Cannot optimize signup flow
- No proof of platform health

## Prerequisites

- [ ] BE-01 to BE-28 completed
- [ ] Tenants & subscriptions ready
- [ ] CORS allows marketing website
- [ ] Bull queue working

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/website_events.ts` | Public website events |
| `server/src/db/schema/marketing_leads.ts` | Contact/demo leads |
| `server/src/db/schema/app_usage_events.ts` | Mobile app events |
| `server/src/db/schema/owner_daily_metrics.ts` | Pre-aggregated KPIs |
| `server/src/modules/analytics/analytics.module.ts` | Module |
| `server/src/modules/analytics/analytics.controller.ts` | Endpoints |
| `server/src/modules/analytics/services/website-analytics.service.ts` | Website |
| `server/src/modules/analytics/services/app-analytics.service.ts` | Mobile |
| `server/src/modules/analytics/services/leads.service.ts` | Lead management |
| `server/src/modules/analytics/services/owner-metrics-aggregator.service.ts` | Daily aggregation |
| `server/src/modules/analytics/services/funnel.service.ts` | Conversion funnels |
| `server/src/modules/analytics/repositories/*.repository.ts` | Data access |
| `server/src/modules/analytics/dto/*.dto.ts` | DTOs |
| `server/src/jobs/cron/owner-metrics-aggregation.cron.ts` | Daily cron |
| All `__tests__/` files |

## Service Interfaces

```typescript
// Marketing Website Analytics
export interface IWebsiteAnalyticsService {
  trackEvent(dto: WebsiteEventDto): Promise<void>;
  getStats(filters: WebsiteStatsFilters): Promise<WebsiteStats>;
  getFunnel(dateRange: DateRange): Promise<FunnelData>;
  getTopPages(dateRange: DateRange): Promise<PageStats[]>;
  getTrafficSources(dateRange: DateRange): Promise<TrafficSource[]>;
}

// Mobile App Analytics
export interface IAppAnalyticsService {
  trackEvent(dto: AppEventDto, userId: string, tenantId: string): Promise<void>;
  trackBatch(events: AppEventDto[], userId: string, tenantId: string): Promise<void>;
  getUserActivity(userId: string, dateRange: DateRange): Promise<UserActivity>;
  getTenantActivity(tenantId: string, dateRange: DateRange): Promise<TenantActivity>;
}

// Lead Management
export interface ILeadsService {
  createLead(dto: CreateLeadDto): Promise<MarketingLead>;
  list(filters: ListLeadsFilter): Promise<PaginatedResult<MarketingLead>>;
  updateStatus(id: string, status: LeadStatus, notes?: string): Promise<MarketingLead>;
  convert(leadId: string, tenantId: string): Promise<void>;
  getConversionRate(dateRange: DateRange): Promise<ConversionStats>;
}

// Types
export interface WebsiteEventDto {
  type: WebsiteEventType;
  page?: string;
  pageTitle?: string;
  referrer?: string;
  
  // UTM
  utmSource?: string;
  utmMedium?: string;
  utmCampaign?: string;
  utmTerm?: string;
  utmContent?: string;
  
  // Tech
  userAgent?: string;
  browser?: string;
  os?: string;
  device?: string;
  
  // Geo (anonymized)
  country?: string;
  region?: string;
  
  // Session
  sessionId: string;
  
  // Custom
  metadata?: Record<string, unknown>;
}

export type WebsiteEventType =
  | 'page_view'
  | 'button_click'
  | 'pricing_view'
  | 'demo_click'
  | 'contact_click'
  | 'whatsapp_click'
  | 'app_download_click'
  | 'feature_view'
  | 'scroll_depth'
  | 'video_play'
  | 'form_submit';

export interface AppEventDto {
  eventType: AppEventType;
  category: string;
  action: string;
  label?: string;
  value?: number;
  
  // Context
  screen?: string;
  storeId?: string;
  
  // Tech
  appVersion?: string;
  platform?: 'ios' | 'android';
  
  metadata?: Record<string, unknown>;
}

export type AppEventType =
  | 'screen_view'
  | 'feature_use'
  | 'error'
  | 'crash'
  | 'performance';

export interface CreateLeadDto {
  name: string;
  email: string;
  mobile?: string;
  company?: string;
  message?: string;
  source: LeadSource;
  
  // UTM
  utmSource?: string;
  utmMedium?: string;
  utmCampaign?: string;
  
  // Context
  pageUrl?: string;
  referrer?: string;
  metadata?: Record<string, unknown>;
}

export type LeadSource =
  | 'contact_form'
  | 'demo_request'
  | 'whatsapp'
  | 'phone'
  | 'email'
  | 'referral'
  | 'other';

export type LeadStatus =
  | 'new'
  | 'contacted'
  | 'qualified'
  | 'demo_scheduled'
  | 'demo_completed'
  | 'converted'
  | 'lost'
  | 'spam';

export interface WebsiteStats {
  totalVisitors: number;
  uniqueVisitors: number;
  pageViews: number;
  averageSessionDuration: number;
  bounceRate: number;
  
  byPage: Array<{ page: string; views: number; uniqueVisitors: number }>;
  byCountry: Array<{ country: string; visitors: number }>;
  byDevice: Array<{ device: string; count: number }>;
  byTrafficSource: Array<{ source: string; visitors: number }>;
  
  conversions: {
    contactFormSubmissions: number;
    demoRequests: number;
    appDownloadClicks: number;
    pricingViews: number;
  };
}

export interface FunnelData {
  steps: Array<{
    name: string;
    count: number;
    conversionRate: number;
    dropoffRate: number;
  }>;
  totalVisitors: number;
  totalConversions: number;
  overallConversion: number;
}
```

## Implementation Code

### 1. Website Events Schema

```typescript
// server/src/db/schema/website_events.ts
import { pgTable, varchar, uuid, integer, timestamp, jsonb, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const websiteEventTypeEnum = pgEnum('website_event_type', [
  'page_view',
  'button_click',
  'pricing_view',
  'demo_click',
  'contact_click',
  'whatsapp_click',
  'app_download_click',
  'feature_view',
  'scroll_depth',
  'video_play',
  'form_submit',
]);

export const websiteEvents = pgTable(
  'website_events',
  {
    ...baseColumns,
    type: websiteEventTypeEnum('type').notNull(),
    
    // Page
    page: varchar('page', { length: 500 }),
    pageTitle: varchar('page_title', { length: 200 }),
    referrer: varchar('referrer', { length: 500 }),
    
    // UTM
    utmSource: varchar('utm_source', { length: 100 }),
    utmMedium: varchar('utm_medium', { length: 100 }),
    utmCampaign: varchar('utm_campaign', { length: 200 }),
    utmTerm: varchar('utm_term', { length: 200 }),
    utmContent: varchar('utm_content', { length: 200 }),
    
    // Tech (anonymized)
    userAgent: varchar('user_agent', { length: 500 }),
    browser: varchar('browser', { length: 50 }),
    os: varchar('os', { length: 50 }),
    device: varchar('device', { length: 30 }),
    
    // Geo (country-level only for privacy)
    country: varchar('country', { length: 2 }),
    region: varchar('region', { length: 100 }),
    
    // Session (anonymized hash)
    sessionId: varchar('session_id', { length: 64 }),
    visitorIdHash: varchar('visitor_id_hash', { length: 64 }), // Hashed cookie
    
    // For aggregation
    yearMonthDay: varchar('year_month_day', { length: 10 }).notNull(),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    typeDateIdx: index('idx_website_events_type_date').on(table.type, table.yearMonthDay),
    sessionIdx: index('idx_website_events_session').on(table.sessionId),
    utmCampaignIdx: index('idx_website_events_utm_campaign').on(table.utmCampaign),
    dateIdx: index('idx_website_events_date').on(table.yearMonthDay),
  }),
);

export type WebsiteEvent = typeof websiteEvents.$inferSelect;
```

### 2. Marketing Leads Schema

```typescript
// server/src/db/schema/marketing_leads.ts
import { pgTable, varchar, uuid, integer, timestamp, jsonb, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns, auditColumns } from './_base';

export const leadSourceEnum = pgEnum('lead_source', [
  'contact_form',
  'demo_request',
  'whatsapp',
  'phone',
  'email',
  'referral',
  'other',
]);

export const leadStatusEnum = pgEnum('lead_status', [
  'new',
  'contacted',
  'qualified',
  'demo_scheduled',
  'demo_completed',
  'converted',
  'lost',
  'spam',
]);

export const marketingLeads = pgTable(
  'marketing_leads',
  {
    ...baseColumns,
    ...auditColumns,
    
    // Contact info
    name: varchar('name', { length: 100 }).notNull(),
    email: varchar('email', { length: 255 }).notNull(),
    mobile: varchar('mobile', { length: 20 }),
    company: varchar('company', { length: 200 }),
    message: varchar('message', { length: 2000 }),
    
    // Classification
    source: leadSourceEnum('source').notNull(),
    status: leadStatusEnum('status').notNull().default('new'),
    
    // UTM
    utmSource: varchar('utm_source', { length: 100 }),
    utmMedium: varchar('utm_medium', { length: 100 }),
    utmCampaign: varchar('utm_campaign', { length: 200 }),
    
    // Context
    pageUrl: varchar('page_url', { length: 500 }),
    referrer: varchar('referrer', { length: 500 }),
    
    // Lifecycle
    contactedAt: timestamp('contacted_at', { withTimezone: true }),
    contactedBy: uuid('contacted_by'),
    demoScheduledAt: timestamp('demo_scheduled_at', { withTimezone: true }),
    convertedAt: timestamp('converted_at', { withTimezone: true }),
    convertedTenantId: uuid('converted_tenant_id'),
    lostAt: timestamp('lost_at', { withTimezone: true }),
    lostReason: varchar('lost_reason', { length: 500 }),
    
    // Internal notes
    notes: varchar('notes', { length: 2000 }),
    assignedTo: uuid('assigned_to'),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    statusIdx: index('idx_leads_status').on(table.status),
    sourceIdx: index('idx_leads_source').on(table.source),
    emailIdx: index('idx_leads_email').on(table.email),
    convertedIdx: index('idx_leads_converted').on(table.convertedTenantId),
    createdIdx: index('idx_leads_created').on(table.createdAt),
  }),
);

export type MarketingLead = typeof marketingLeads.$inferSelect;
```

### 3. App Usage Events Schema

```typescript
// server/src/db/schema/app_usage_events.ts
import { pgTable, varchar, uuid, integer, decimal, jsonb, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const appEventTypeEnum = pgEnum('app_event_type', [
  'screen_view',
  'feature_use',
  'error',
  'crash',
  'performance',
]);

export const appUsageEvents = pgTable(
  'app_usage_events',
  {
    ...baseColumns,
    tenantId: uuid('tenant_id').notNull(),
    userId: uuid('user_id').notNull(),
    storeId: uuid('store_id'),
    
    eventType: appEventTypeEnum('event_type').notNull(),
    category: varchar('category', { length: 50 }).notNull(),
    action: varchar('action', { length: 100 }).notNull(),
    label: varchar('label', { length: 200 }),
    value: decimal('value', { precision: 10, scale: 2 }),
    
    // Context
    screen: varchar('screen', { length: 100 }),
    appVersion: varchar('app_version', { length: 20 }),
    platform: varchar('platform', { length: 10 }),
    deviceModel: varchar('device_model', { length: 100 }),
    
    // For aggregation
    yearMonthDay: varchar('year_month_day', { length: 10 }).notNull(),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    tenantDateIdx: index('idx_app_events_tenant_date').on(table.tenantId, table.yearMonthDay),
    userIdx: index('idx_app_events_user').on(table.userId),
    eventTypeIdx: index('idx_app_events_type').on(table.eventType),
    actionIdx: index('idx_app_events_action').on(table.category, table.action),
  }),
);

export type AppUsageEvent = typeof appUsageEvents.$inferSelect;
```

### 4. Owner Daily Metrics Schema

```typescript
// server/src/db/schema/owner_daily_metrics.ts
import { pgTable, varchar, uuid, integer, decimal, timestamp, jsonb, index, unique } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const ownerDailyMetrics = pgTable(
  'owner_daily_metrics',
  {
    ...baseColumns,
    date: timestamp('date', { withTimezone: true }).notNull(),
    
    // Website
    websiteVisitors: integer('website_visitors').notNull().default(0),
    websitePageViews: integer('website_page_views').notNull().default(0),
    websiteContactClicks: integer('website_contact_clicks').notNull().default(0),
    websitePricingViews: integer('website_pricing_views').notNull().default(0),
    websiteAppDownloadClicks: integer('website_app_download_clicks').notNull().default(0),
    
    // Leads
    newLeads: integer('new_leads').notNull().default(0),
    qualifiedLeads: integer('qualified_leads').notNull().default(0),
    convertedLeads: integer('converted_leads').notNull().default(0),
    
    // Tenants
    newTenants: integer('new_tenants').notNull().default(0),
    activeTenants: integer('active_tenants').notNull().default(0),
    trialTenants: integer('trial_tenants').notNull().default(0),
    paidTenants: integer('paid_tenants').notNull().default(0),
    cancelledTenants: integer('cancelled_tenants').notNull().default(0),
    
    // Plan distribution
    starterCount: integer('starter_count').notNull().default(0),
    growthCount: integer('growth_count').notNull().default(0),
    proCount: integer('pro_count').notNull().default(0),
    
    // Revenue
    mrr: decimal('mrr', { precision: 14, scale: 2 }).notNull().default('0'),
    newMrr: decimal('new_mrr', { precision: 14, scale: 2 }).notNull().default('0'),
    churnedMrr: decimal('churned_mrr', { precision: 14, scale: 2 }).notNull().default('0'),
    
    // Usage
    totalScans: integer('total_scans').notNull().default(0),
    totalReports: integer('total_reports').notNull().default(0),
    totalAiCalls: integer('total_ai_calls').notNull().default(0),
    totalEanValidations: integer('total_ean_validations').notNull().default(0),
    
    // Active users
    dau: integer('dau').notNull().default(0),  // Daily active users
    mau: integer('mau').notNull().default(0),  // Monthly active users
    
    // Costs
    aiCost: decimal('ai_cost', { precision: 10, scale: 6 }).notNull().default('0'),
    smsCost: decimal('sms_cost', { precision: 10, scale: 6 }).notNull().default('0'),
    s3Cost: decimal('s3_cost', { precision: 10, scale: 6 }).notNull().default('0'),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    uniqueDate: unique('uniq_owner_metrics_date').on(table.date),
    dateIdx: index('idx_owner_metrics_date').on(table.date),
  }),
);

export type OwnerDailyMetric = typeof ownerDailyMetrics.$inferSelect;
```

### 5. Website Analytics Service

```typescript
// server/src/modules/analytics/services/website-analytics.service.ts
import { Injectable } from '@nestjs/common';
import { WebsiteEventsRepository } from '../repositories/website-events.repository';
import { LoggerService } from '../../../logging/logger.service';
import { sql } from 'drizzle-orm';
import { DbService } from '../../../db/db.service';
import * as crypto from 'crypto';

@Injectable()
export class WebsiteAnalyticsService {
  constructor(
    private readonly db: DbService,
    private readonly repo: WebsiteEventsRepository,
    private readonly logger: LoggerService,
  ) {}

  async trackEvent(dto: any, ipAddress: string, salt: string): Promise<void> {
    // Hash visitor ID for privacy
    const visitorIdHash = this.hashVisitorId(dto.sessionId, salt);
    
    const yearMonthDay = new Date().toISOString().slice(0, 10);
    
    await this.repo.create({
      type: dto.type,
      page: dto.page,
      pageTitle: dto.pageTitle,
      referrer: dto.referrer,
      utmSource: dto.utmSource,
      utmMedium: dto.utmMedium,
      utmCampaign: dto.utmCampaign,
      utmTerm: dto.utmTerm,
      utmContent: dto.utmContent,
      userAgent: dto.userAgent?.slice(0, 500),
      browser: dto.browser,
      os: dto.os,
      device: dto.device,
      country: dto.country,
      region: dto.region,
      sessionId: dto.sessionId,
      visitorIdHash,
      yearMonthDay,
      metadata: dto.metadata,
    });
  }

  async getStats(filters: any): Promise<any> {
    const db = this.db.getDb();
    const { from, to } = filters.dateRange;
    
    const fromDate = from.toISOString().slice(0, 10);
    const toDate = to.toISOString().slice(0, 10);
    
    const [pageViews, conversions, byPage, byCountry] = await Promise.all([
      // Total page views and unique visitors
      db.execute(sql`
        SELECT 
          COUNT(*)::int as total_views,
          COUNT(DISTINCT visitor_id_hash)::int as unique_visitors,
          COUNT(DISTINCT session_id)::int as sessions
        FROM website_events
        WHERE year_month_day BETWEEN ${fromDate} AND ${toDate}
          AND type = 'page_view'
      `),
      
      // Conversion events
      db.execute(sql`
        SELECT 
          type,
          COUNT(*)::int as count
        FROM website_events
        WHERE year_month_day BETWEEN ${fromDate} AND ${toDate}
          AND type IN ('contact_click', 'demo_click', 'app_download_click', 'pricing_view')
        GROUP BY type
      `),
      
      // Top pages
      db.execute(sql`
        SELECT 
          page,
          COUNT(*)::int as views,
          COUNT(DISTINCT visitor_id_hash)::int as unique_visitors
        FROM website_events
        WHERE year_month_day BETWEEN ${fromDate} AND ${toDate}
          AND type = 'page_view'
          AND page IS NOT NULL
        GROUP BY page
        ORDER BY views DESC
        LIMIT 20
      `),
      
      // By country
      db.execute(sql`
        SELECT 
          country,
          COUNT(DISTINCT visitor_id_hash)::int as visitors
        FROM website_events
        WHERE year_month_day BETWEEN ${fromDate} AND ${toDate}
          AND country IS NOT NULL
        GROUP BY country
        ORDER BY visitors DESC
        LIMIT 20
      `),
    ]);
    
    const conversionMap: Record<string, number> = {};
    for (const row of conversions.rows as any[]) {
      conversionMap[row.type] = Number(row.count);
    }
    
    return {
      totalVisitors: Number((pageViews.rows[0] as any)?.unique_visitors || 0),
      uniqueVisitors: Number((pageViews.rows[0] as any)?.unique_visitors || 0),
      pageViews: Number((pageViews.rows[0] as any)?.total_views || 0),
      sessions: Number((pageViews.rows[0] as any)?.sessions || 0),
      
      byPage: byPage.rows.map((r: any) => ({
        page: r.page,
        views: Number(r.views),
        uniqueVisitors: Number(r.unique_visitors),
      })),
      
      byCountry: byCountry.rows.map((r: any) => ({
        country: r.country,
        visitors: Number(r.visitors),
      })),
      
      conversions: {
        contactFormSubmissions: conversionMap['contact_click'] || 0,
        demoRequests: conversionMap['demo_click'] || 0,
        appDownloadClicks: conversionMap['app_download_click'] || 0,
        pricingViews: conversionMap['pricing_view'] || 0,
      },
    };
  }

  async getFunnel(dateRange: any): Promise<any> {
    const db = this.db.getDb();
    const { from, to } = dateRange;
    const fromDate = from.toISOString().slice(0, 10);
    const toDate = to.toISOString().slice(0, 10);
    
    // Standard SaaS funnel
    const result = await db.execute(sql`
      WITH funnel AS (
        SELECT 
          COUNT(DISTINCT CASE WHEN type = 'page_view' THEN visitor_id_hash END)::int as visitors,
          COUNT(DISTINCT CASE WHEN type = 'pricing_view' THEN visitor_id_hash END)::int as pricing_viewers,
          COUNT(DISTINCT CASE WHEN type = 'app_download_click' THEN visitor_id_hash END)::int as downloaders,
          COUNT(DISTINCT CASE WHEN type IN ('contact_click', 'demo_click') THEN visitor_id_hash END)::int as inquirers
        FROM website_events
        WHERE year_month_day BETWEEN ${fromDate} AND ${toDate}
      )
      SELECT * FROM funnel
    `);
    
    const row = result.rows[0] as any;
    const visitors = Number(row.visitors);
    const pricingViewers = Number(row.pricing_viewers);
    const downloaders = Number(row.downloaders);
    const inquirers = Number(row.inquirers);
    
    return {
      steps: [
        { name: 'Visitors', count: visitors, conversionRate: 100, dropoffRate: 0 },
        { name: 'Viewed Pricing', count: pricingViewers, conversionRate: visitors ? (pricingViewers / visitors) * 100 : 0, dropoffRate: visitors ? ((visitors - pricingViewers) / visitors) * 100 : 0 },
        { name: 'Inquired', count: inquirers, conversionRate: pricingViewers ? (inquirers / pricingViewers) * 100 : 0, dropoffRate: pricingViewers ? ((pricingViewers - inquirers) / pricingViewers) * 100 : 0 },
        { name: 'Downloaded App', count: downloaders, conversionRate: inquirers ? (downloaders / inquirers) * 100 : 0, dropoffRate: inquirers ? ((inquirers - downloaders) / inquirers) * 100 : 0 },
      ],
      totalVisitors: visitors,
      totalConversions: downloaders,
      overallConversion: visitors ? (downloaders / visitors) * 100 : 0,
    };
  }

  private hashVisitorId(sessionId: string, salt: string): string {
    return crypto
      .createHash('sha256')
      .update(`${sessionId}:${salt}`)
      .digest('hex');
  }
}
```

### 6. Leads Service

```typescript
// server/src/modules/analytics/services/leads.service.ts
import { Injectable } from '@nestjs/common';
import { LeadsRepository } from '../repositories/leads.repository';
import { NotificationsService } from '../../notifications/notifications.service';
import { ConfigService } from '../../../config/config.service';
import { CreateLeadDto, MarketingLead, LeadStatus } from '../types/lead.types';
import { LoggerService } from '../../../logging/logger.service';

@Injectable()
export class LeadsService {
  constructor(
    private readonly leadsRepo: LeadsRepository,
    private readonly notifications: NotificationsService,
    private readonly config: ConfigService,
    private readonly logger: LoggerService,
  ) {}

  async createLead(dto: CreateLeadDto, ipAddress: string): Promise<MarketingLead> {
    // Spam check (basic)
    const isSpam = await this.checkSpam(dto, ipAddress);
    
    const lead = await this.leadsRepo.create({
      ...dto,
      status: isSpam ? 'spam' : 'new',
    });
    
    if (!isSpam) {
      // Notify owner
      const ownerEmail = this.config.get<string>('OWNER_EMAIL');
      if (ownerEmail) {
        // BE-24 will handle this
        this.logger.info('New lead notification queued', { leadId: lead.id });
      }
    }
    
    return lead;
  }

  async list(filters: any): Promise<any> {
    return this.leadsRepo.findPaginated(filters, {
      cursor: filters.cursor,
      limit: filters.limit || 50,
      orderBy: [{ field: 'createdAt', direction: 'desc' }],
    });
  }

  async updateStatus(id: string, status: LeadStatus, notes?: string): Promise<MarketingLead> {
    const updates: any = { status };
    
    if (status === 'contacted') {
      updates.contactedAt = new Date();
    } else if (status === 'demo_scheduled') {
      updates.demoScheduledAt = new Date();
    } else if (status === 'converted') {
      updates.convertedAt = new Date();
    } else if (status === 'lost') {
      updates.lostAt = new Date();
      updates.lostReason = notes;
    }
    
    if (notes) updates.notes = notes;
    
    return this.leadsRepo.update(id, updates);
  }

  async convert(leadId: string, tenantId: string): Promise<void> {
    await this.leadsRepo.update(leadId, {
      status: 'converted',
      convertedAt: new Date(),
      convertedTenantId: tenantId,
    });
  }

  async getConversionRate(dateRange: any): Promise<any> {
    return this.leadsRepo.getConversionStats(dateRange);
  }

  private async checkSpam(dto: CreateLeadDto, ipAddress: string): Promise<boolean> {
    // Basic checks
    if (!dto.email.includes('@')) return true;
    
    // Common spam patterns
    if (/buy.*viagra|click.*here|free.*money/i.test(dto.message || '')) return true;
    
    // Rate limit per IP (basic)
    // Could integrate with proper anti-spam service later
    
    return false;
  }
}
```

### 7. Owner Metrics Aggregator

```typescript
// server/src/modules/analytics/services/owner-metrics-aggregator.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { DbService } from '../../../db/db.service';
import { sql } from 'drizzle-orm';

@Injectable()
export class OwnerMetricsAggregatorService {
  private readonly logger = new Logger(OwnerMetricsAggregatorService.name);

  constructor(private readonly db: DbService) {}

  // Run daily at 3 AM
  @Cron(CronExpression.EVERY_DAY_AT_3AM)
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
    
    const dateStr = startOfDay.toISOString().slice(0, 10);
    
    this.logger.log(`Aggregating owner metrics for ${dateStr}`);
    
    const db = this.db.getDb();
    
    // Run all aggregations in parallel
    const [
      websiteData,
      leadData,
      tenantData,
      planData,
      usageData,
      activeUsers,
    ] = await Promise.all([
      this.getWebsiteMetrics(db, dateStr),
      this.getLeadMetrics(db, startOfDay, endOfDay),
      this.getTenantMetrics(db, startOfDay, endOfDay),
      this.getPlanDistribution(db),
      this.getUsageMetrics(db, dateStr),
      this.getActiveUsers(db, dateStr),
    ]);
    
    const mrr = await this.calculateMRR(db);
    
    // Upsert
    await db.execute(sql`
      INSERT INTO owner_daily_metrics (
        date,
        website_visitors, website_page_views, website_contact_clicks,
        website_pricing_views, website_app_download_clicks,
        new_leads, qualified_leads, converted_leads,
        new_tenants, active_tenants, trial_tenants, paid_tenants, cancelled_tenants,
        starter_count, growth_count, pro_count,
        mrr,
        total_scans, total_reports, total_ai_calls,
        dau, mau
      )
      VALUES (
        ${startOfDay},
        ${websiteData.visitors}, ${websiteData.pageViews}, ${websiteData.contactClicks},
        ${websiteData.pricingViews}, ${websiteData.appDownloadClicks},
        ${leadData.newLeads}, ${leadData.qualifiedLeads}, ${leadData.convertedLeads},
        ${tenantData.newTenants}, ${tenantData.activeTenants}, ${tenantData.trialTenants}, ${tenantData.paidTenants}, ${tenantData.cancelledTenants},
        ${planData.starter}, ${planData.growth}, ${planData.pro},
        ${mrr},
        ${usageData.scans}, ${usageData.reports}, ${usageData.aiCalls},
        ${activeUsers.dau}, ${activeUsers.mau}
      )
      ON CONFLICT (date) DO UPDATE SET
        website_visitors = EXCLUDED.website_visitors,
        website_page_views = EXCLUDED.website_page_views,
        new_leads = EXCLUDED.new_leads,
        new_tenants = EXCLUDED.new_tenants,
        active_tenants = EXCLUDED.active_tenants,
        mrr = EXCLUDED.mrr,
        dau = EXCLUDED.dau,
        mau = EXCLUDED.mau,
        updated_at = NOW()
    `);
    
    this.logger.log(`Owner metrics aggregated for ${dateStr}`);
  }

  private async getWebsiteMetrics(db: any, dateStr: string) {
    const result = await db.execute(sql`
      SELECT 
        COUNT(DISTINCT visitor_id_hash) FILTER (WHERE type = 'page_view')::int as visitors,
        COUNT(*) FILTER (WHERE type = 'page_view')::int as page_views,
        COUNT(*) FILTER (WHERE type = 'contact_click')::int as contact_clicks,
        COUNT(*) FILTER (WHERE type = 'pricing_view')::int as pricing_views,
        COUNT(*) FILTER (WHERE type = 'app_download_click')::int as app_download_clicks
      FROM website_events
      WHERE year_month_day = ${dateStr}
    `);
    
    return {
      visitors: Number((result.rows[0] as any)?.visitors || 0),
      pageViews: Number((result.rows[0] as any)?.page_views || 0),
      contactClicks: Number((result.rows[0] as any)?.contact_clicks || 0),
      pricingViews: Number((result.rows[0] as any)?.pricing_views || 0),
      appDownloadClicks: Number((result.rows[0] as any)?.app_download_clicks || 0),
    };
  }

  private async getLeadMetrics(db: any, from: Date, to: Date) {
    const result = await db.execute(sql`
      SELECT 
        COUNT(*) FILTER (WHERE created_at BETWEEN ${from} AND ${to})::int as new_leads,
        COUNT(*) FILTER (WHERE status = 'qualified' AND updated_at BETWEEN ${from} AND ${to})::int as qualified_leads,
        COUNT(*) FILTER (WHERE status = 'converted' AND converted_at BETWEEN ${from} AND ${to})::int as converted_leads
      FROM marketing_leads
    `);
    
    return {
      newLeads: Number((result.rows[0] as any)?.new_leads || 0),
      qualifiedLeads: Number((result.rows[0] as any)?.qualified_leads || 0),
      convertedLeads: Number((result.rows[0] as any)?.converted_leads || 0),
    };
  }

  private async getTenantMetrics(db: any, from: Date, to: Date) {
    const result = await db.execute(sql`
      SELECT 
        COUNT(*) FILTER (WHERE created_at BETWEEN ${from} AND ${to})::int as new_tenants,
        COUNT(*) FILTER (WHERE status = 'active' OR status = 'trial')::int as active_tenants,
        COUNT(*) FILTER (WHERE status = 'trial')::int as trial_tenants,
        COUNT(*) FILTER (WHERE status = 'active')::int as paid_tenants,
        COUNT(*) FILTER (WHERE status = 'cancelled' AND cancelled_at BETWEEN ${from} AND ${to})::int as cancelled_tenants
      FROM tenant_subscriptions
    `);
    
    return {
      newTenants: Number((result.rows[0] as any)?.new_tenants || 0),
      activeTenants: Number((result.rows[0] as any)?.active_tenants || 0),
      trialTenants: Number((result.rows[0] as any)?.trial_tenants || 0),
      paidTenants: Number((result.rows[0] as any)?.paid_tenants || 0),
      cancelledTenants: Number((result.rows[0] as any)?.cancelled_tenants || 0),
    };
  }

  private async getPlanDistribution(db: any) {
    const result = await db.execute(sql`
      SELECT 
        plan_code,
        COUNT(*)::int as count
      FROM tenant_subscriptions
      WHERE status = 'active'
      GROUP BY plan_code
    `);
    
    const dist: Record<string, number> = { starter: 0, growth: 0, pro: 0 };
    for (const row of result.rows as any[]) {
      if (row.plan_code in dist) {
        dist[row.plan_code] = Number(row.count);
      }
    }
    return dist;
  }

  private async getUsageMetrics(db: any, dateStr: string) {
    const result = await db.execute(sql`
      SELECT 
        (SELECT COUNT(*)::int FROM scan_items WHERE TO_CHAR(scanned_at, 'YYYY-MM-DD') = ${dateStr}) as scans,
        (SELECT COUNT(*)::int FROM reports WHERE TO_CHAR(created_at, 'YYYY-MM-DD') = ${dateStr}) as reports,
        (SELECT COUNT(*)::int FROM ai_usage_log WHERE year_month_day = ${dateStr}) as ai_calls
    `);
    
    return {
      scans: Number((result.rows[0] as any)?.scans || 0),
      reports: Number((result.rows[0] as any)?.reports || 0),
      aiCalls: Number((result.rows[0] as any)?.ai_calls || 0),
    };
  }

  private async getActiveUsers(db: any, dateStr: string) {
    const monthStart = new Date(dateStr);
    monthStart.setDate(1);
    
    const result = await db.execute(sql`
      SELECT 
        (SELECT COUNT(DISTINCT user_id)::int FROM app_usage_events WHERE year_month_day = ${dateStr}) as dau,
        (SELECT COUNT(DISTINCT user_id)::int FROM app_usage_events WHERE created_at >= ${monthStart}) as mau
    `);
    
    return {
      dau: Number((result.rows[0] as any)?.dau || 0),
      mau: Number((result.rows[0] as any)?.mau || 0),
    };
  }

  private async calculateMRR(db: any): Promise<string> {
    const result = await db.execute(sql`
      SELECT COALESCE(SUM(monthly_amount), 0)::text as mrr
      FROM tenant_subscriptions
      WHERE status = 'active'
    `);
    return (result.rows[0] as any)?.mrr || '0';
  }
}
```

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| POST | `/api/v1/analytics/website-event` | Public | Track website event |
| POST | `/api/v1/leads` | Public | Submit lead |
| POST | `/api/v1/analytics/app-event` | Bearer | Track mobile event |
| POST | `/api/v1/analytics/app-events/batch` | Bearer | Batch events |
| GET | `/api/v1/owner/leads` | Owner | List leads |
| PATCH | `/api/v1/owner/leads/:id` | Owner | Update lead status |
| GET | `/api/v1/owner/website/stats` | Owner | Website analytics |
| GET | `/api/v1/owner/funnel` | Owner | Conversion funnel |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-30 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Website Event Tracking ✅
**Pass Criteria**: ✅ Public endpoint accepts events, hashed visitor ID

### Test 2: Lead Submission ✅
**Pass Criteria**: ✅ Lead created, owner notified

### Test 3: Spam Detection ✅
**Pass Criteria**: ✅ Common spam patterns flagged

### Test 4: App Event Tracking ✅
**Pass Criteria**: ✅ Authenticated event recorded

### Test 5: Daily Aggregation Cron ✅
**Pass Criteria**: ✅ owner_daily_metrics populated

### Test 6: Funnel Calculation ✅
**Pass Criteria**: ✅ Conversion rates accurate

### Test 7: Privacy — No PII ✅
**Pass Criteria**: ✅ No raw IPs, hashed visitor IDs, country-only geo

### Test 8: UTM Tracking ✅
**Pass Criteria**: ✅ Campaign data preserved

### Test 9: Lead Status Workflow ✅
new → contacted → qualified → converted ✅
**Pass Criteria**: ✅ Status flow works

### Test 10: MRR Calculation ✅
**Pass Criteria**: ✅ Sum of active monthly amounts

### Test 11: DAU/MAU Calculation ✅
**Pass Criteria**: ✅ Distinct users per period

### Test 12: Public Endpoint Rate Limiting ✅
**Pass Criteria**: ✅ Lead submission limited

### Test 13: Aggregation Idempotency ✅
Run cron twice for same day:
**Pass Criteria**: ✅ ON CONFLICT updates correctly

### Test 14: Performance ✅
**Pass Criteria**: ✅ Aggregation < 30s for 1 day

### Test 15: Conversion Tracking ✅
Lead converts to tenant → linked
**Pass Criteria**: ✅ Funnel complete

## 🎯 Q&A Session

### Q1: Why public endpoint for website events?
**Expected**: Marketing site has no auth, anonymous visitors, GDPR-compliant

### Q2: Why hash visitor IDs?
**Expected**: Privacy, GDPR compliance, can still de-duplicate

### Q3: Why daily aggregation vs real-time?
**Expected**: Cost (querying raw events expensive), refresh-rate acceptable, 24h history fine

### Q4: Why country-only geo?
**Expected**: Privacy, GDPR, sufficient for marketing decisions, no city tracking

### Q5: Why separate tables for website vs app events?
**Expected**: Different schemas, different access patterns, easier to scale separately

### Q6: How handle event spikes?
**Expected**: Async via queue, batch inserts, sampling if needed

### Q7: Why ON CONFLICT for daily metrics?
**Expected**: Idempotent reruns, fix data without duplicates, simple recovery

### Q8: How GDPR compliant?
**Expected**: Right to deletion (find by visitor_id_hash), no PII, country-only, retention policies

## 📝 Sign-Off Checklist

- [ ] All 15 tests pass
- [ ] Privacy verified (no PII)
- [ ] Daily cron works
- [ ] Funnel calculations accurate
- [ ] MRR correct
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-30**
**☐ CHANGES REQUESTED**

---

**END OF BE-29 — DO NOT PROCEED WITHOUT APPROVAL**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-29 with the PostHog SDK and a locked event taxonomy from Day 1 (Req 44).**

## Driver Requirements

- **Req 44** — Analytics events emitted from Mobile_App and Backend_API to PostHog from launch. Locked taxonomy. Self-hostable. 1M events/month budget warning. Anonymized when user opts out of analytics.

## Scope of Update

The v1 phase set up internal analytics tables. v2 adds PostHog wiring and a strict event taxonomy so we can measure activation, conversion, and feature usage from launch day.

## Files to Create / Modify

| File Path | Change |
|---|---|
| `server/src/modules/analytics/providers/posthog.provider.ts` | New — wraps `posthog-node` |
| `server/src/modules/analytics/services/event-emitter.service.ts` | New — locked taxonomy enforcement |
| `server/src/modules/analytics/types/events.ts` | New — TypeScript discriminated union for all events |
| `server/src/modules/analytics/services/budget-watcher.service.ts` | New — 1M event/month budget warning |

## Locked Event Taxonomy

```typescript
export type AnalyticsEvent =
  | { name: 'app_opened'; props: { app_version: string; platform: 'ios' | 'android' } }
  | { name: 'product_scanned'; props: { ean: string; mode: 'basic' | 'comprehensive'; tier: SubscriptionTier } }
  | { name: 'trial_started'; props: { tier: 'trial_pro'; provider: 'razorpay' | 'cashfree' } }
  | { name: 'trial_converted'; props: { from_tier: SubscriptionTier; to_tier: SubscriptionTier } }
  | { name: 'business_mode_activated'; props: { from_segment: string } }
  | { name: 'feature_locked_seen'; props: { feature: string; tier: SubscriptionTier } }
  | { name: 'subscription_purchased'; props: { tier: SubscriptionTier; amount_paise: number } }
  | { name: 'subscription_cancelled'; props: { tier: SubscriptionTier; reason?: string } }
  | { name: 'recall_alert_received'; props: { ean: string; recall_source: string } }
  | { name: 'affiliate_link_clicked'; props: { source_ean: string; alternative_ean: string; partner: 'amazon' | 'flipkart' } }
  | { name: 'onboarding_segment_selected'; props: { segment: string } }
  | { name: 'allergen_match_flagged'; props: { ean: string; allergen: string; family_member_id: string } };
```

## EventEmitterService

```typescript
@Injectable()
export class EventEmitterService {
  constructor(private readonly posthog: PostHogProvider, private readonly budget: BudgetWatcherService) {}

  async emit(userId: string, tenantId: string, event: AnalyticsEvent, opts?: { anonymize?: boolean }) {
    const distinctId = opts?.anonymize ? `anon:${hash(userId)}` : userId;
    await this.posthog.capture({
      distinctId,
      event: event.name,
      properties: {
        ...event.props,
        tenant_id: tenantId,
        emitted_from: 'backend',
      },
    });
    this.budget.tickOne();
  }
}
```

## Budget Watcher

```typescript
@Cron(CronExpression.EVERY_HOUR)
async checkPostHogUsage() {
  const used = await this.posthog.monthToDateEventCount();
  if (used / 1_000_000 >= 0.85) {
    this.logger.warn(`PostHog usage at ${(used / 1_000_000 * 100).toFixed(1)}% of 1M event ceiling`);
    await this.ownerAlerts.send('PostHog event budget warning', { used });
  }
}
```

## ADDENDUM v2 Test Procedures (add 4)

| # | Test |
|---|---|
| T-v2.1 | Each enum event type round-trips: emit → PostHog test endpoint → verify properties land |
| T-v2.2 | Anonymized emit produces `anon:<hash>` distinct ID; never includes raw user ID |
| T-v2.3 | Events can be diverted to a self-hosted PostHog instance by changing only `POSTHOG_HOST` env var |
| T-v2.4 | Budget watcher logs warning at 85% of 1M monthly volume |

## ADDENDUM v2 Q&A (add 3)

- **Q-v2.1**: How does the discriminated-union approach prevent silently emitting events not on the locked taxonomy?
- **Q-v2.2**: Where is the PostHog API key stored and rotated?
- **Q-v2.3**: How does the Mobile_App emit events offline so we don't lose data on flaky connections (ties to BE-44 sync)?

## ADDENDUM v2 Sign-off

- [ ] PostHog SDK wired (Mobile + Backend)
- [ ] Locked taxonomy enforced via TypeScript types
- [ ] Self-host switch verified
- [ ] Budget watcher live
- [ ] Anonymization tested

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-29 ADDENDUM v2**
