# Phase BE-24: Notifications & Background Jobs

## Phase Metadata

- **Phase ID**: BE-24
- **Phase Name**: Notifications & Background Jobs
- **Section**: Backend Execution — Advanced Features Layer
- **Depends On**: BE-01 to BE-23
- **Blocks**: All scheduled functionality
- **Estimated Duration**: 2-3 days
- **Complexity**: Medium-High

## Goal

Build comprehensive notification system (email, SMS, push) and background job infrastructure (cron jobs, scheduled reports, daily aggregations, cleanup tasks). Multi-channel notification preferences per user, template management, delivery tracking, retry logic, and quiet hours.

## Why This Phase Matters

Notifications keep users engaged:
- Expiry alerts (BE-18) reach users
- Task assignments notify staff
- Reports email when ready (BE-21)
- OTP via SMS (already BE-06)
- Daily digest emails

Background jobs maintain the system:
- Daily expiry status updates (BE-18)
- Daily metrics aggregation (BE-20)
- Session auto-expiration (BE-16)
- Cleanup of old data
- Scheduled report generation

## Prerequisites

- [ ] BE-01 to BE-23 completed
- [ ] AWS SES verified domain
- [ ] FCM project (for push)
- [ ] MSG91 working (BE-06)

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/notifications.ts` | Notification log |
| `server/src/db/schema/notification_preferences.ts` | User prefs |
| `server/src/db/schema/notification_templates.ts` | Templates |
| `server/src/modules/notifications/notifications.module.ts` | Module |
| `server/src/modules/notifications/notifications.controller.ts` | Endpoints |
| `server/src/modules/notifications/notifications.service.ts` | Main service |
| `server/src/modules/notifications/services/email-notification.service.ts` | Email |
| `server/src/modules/notifications/services/sms-notification.service.ts` | SMS |
| `server/src/modules/notifications/services/push-notification.service.ts` | Push (FCM) |
| `server/src/modules/notifications/services/notification-router.service.ts` | Channel routing |
| `server/src/modules/notifications/services/template-renderer.service.ts` | Templates |
| `server/src/modules/notifications/services/preference-manager.service.ts` | User prefs |
| `server/src/modules/notifications/processors/notification.processor.ts` | Bull worker |
| `server/src/modules/notifications/repositories/notifications.repository.ts` | Data |
| `server/src/integrations/fcm/fcm.service.ts` | Firebase Cloud Messaging |
| `server/src/jobs/cron/daily-aggregation.cron.ts` | Daily metrics cron |
| `server/src/jobs/cron/expiry-status-update.cron.ts` | Expiry recalc cron |
| `server/src/jobs/cron/session-cleanup.cron.ts` | Session expiry cron |
| `server/src/jobs/cron/data-retention.cron.ts` | Data cleanup cron |
| `server/src/jobs/cron/scheduled-reports.cron.ts` | Scheduled reports cron |
| `server/src/jobs/jobs.module.ts` | Jobs module |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/notifications/notifications.service.ts

export interface INotificationsService {
  // Send notification
  send(dto: SendNotificationDto): Promise<NotificationResult>;
  
  // Send to multiple users
  sendBulk(dto: SendBulkNotificationDto): Promise<BulkNotificationResult>;
  
  // Template-based
  sendTemplate<T extends NotificationTemplate>(
    template: T,
    recipients: NotificationRecipient[],
    data: TemplateData[T],
  ): Promise<NotificationResult[]>;
  
  // Preferences
  getPreferences(userId: string): Promise<NotificationPreferences>;
  updatePreferences(userId: string, dto: UpdatePreferencesDto): Promise<NotificationPreferences>;
  
  // History
  getHistory(userId: string, filters: HistoryFilters): Promise<PaginatedResult<Notification>>;
  
  // Mark as read
  markAsRead(notificationId: string, userId: string): Promise<void>;
}

export type NotificationChannel = 'email' | 'sms' | 'push' | 'in-app';

export type NotificationCategory =
  | 'auth'           // OTP, login alerts
  | 'expiry-alert'   // Near-expiry, expired
  | 'task'           // Assignments, completions
  | 'report'         // Report ready
  | 'system'         // Maintenance, updates
  | 'marketing';     // Promotions (opt-in)

export type NotificationTemplate =
  | 'task-assigned'
  | 'task-completed'
  | 'task-overdue'
  | 'expiry-near'
  | 'expiry-red'
  | 'report-ready'
  | 'login-alert'
  | 'daily-digest'
  | 'weekly-report'
  | 'subscription-renewal'
  | 'trial-expiring';

export interface SendNotificationDto {
  userId: string;
  channels: NotificationChannel[];
  category: NotificationCategory;
  subject: string;
  body: string;
  bodyHtml?: string;
  data?: Record<string, unknown>;
  priority?: 'low' | 'normal' | 'high' | 'urgent';
  scheduledFor?: Date;
}

export interface NotificationRecipient {
  userId: string;
  email?: string;
  mobile?: string;
  fcmToken?: string;
}

export interface NotificationPreferences {
  userId: string;
  channels: {
    email: boolean;
    sms: boolean;
    push: boolean;
    inApp: boolean;
  };
  categories: Record<NotificationCategory, boolean>;
  quietHours?: {
    enabled: boolean;
    start: string; // HH:MM
    end: string;
    timezone: string;
  };
  digestFrequency?: 'realtime' | 'daily' | 'weekly';
}

export interface NotificationResult {
  notificationId: string;
  status: 'sent' | 'queued' | 'failed';
  channels: Array<{
    channel: NotificationChannel;
    delivered: boolean;
    error?: string;
  }>;
}

export interface BulkNotificationResult {
  totalRecipients: number;
  successful: number;
  failed: number;
  errors: Array<{ userId: string; error: string }>;
}
```

## Implementation Code

### 1. Notifications Schema

```typescript
// server/src/db/schema/notifications.ts
import { pgTable, varchar, uuid, integer, timestamp, jsonb, boolean, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const notificationStatusEnum = pgEnum('notification_status', [
  'queued',
  'sent',
  'delivered',
  'read',
  'failed',
  'bounced',
]);

export const notificationChannelEnum = pgEnum('notification_channel', [
  'email',
  'sms',
  'push',
  'in-app',
]);

export const notifications = pgTable(
  'notifications',
  {
    ...baseColumns,
    tenantId: uuid('tenant_id').notNull(),
    userId: uuid('user_id').notNull(),
    
    category: varchar('category', { length: 50 }).notNull(),
    template: varchar('template', { length: 50 }),
    
    subject: varchar('subject', { length: 200 }).notNull(),
    body: varchar('body', { length: 2000 }).notNull(),
    bodyHtml: varchar('body_html', { length: 10000 }),
    
    priority: varchar('priority', { length: 10 }).notNull().default('normal'),
    
    // Channels
    channels: jsonb('channels').notNull().default([]),
    
    // Per-channel status
    emailStatus: notificationStatusEnum('email_status'),
    smsStatus: notificationStatusEnum('sms_status'),
    pushStatus: notificationStatusEnum('push_status'),
    inAppStatus: notificationStatusEnum('in_app_status'),
    
    // Read state
    isRead: boolean('is_read').notNull().default(false),
    readAt: timestamp('read_at', { withTimezone: true }),
    
    // Delivery
    sentAt: timestamp('sent_at', { withTimezone: true }),
    scheduledFor: timestamp('scheduled_for', { withTimezone: true }),
    
    // Linking
    relatedResourceType: varchar('related_resource_type', { length: 50 }),
    relatedResourceId: uuid('related_resource_id'),
    
    data: jsonb('data').default({}),
    error: varchar('error', { length: 1000 }),
  },
  (table) => ({
    userCreatedIdx: index('idx_notifications_user_created').on(table.userId, table.createdAt),
    unreadIdx: index('idx_notifications_unread').on(table.userId, table.isRead),
    categoryIdx: index('idx_notifications_category').on(table.category),
    scheduledIdx: index('idx_notifications_scheduled').on(table.scheduledFor),
  }),
);
```

### 2. Notifications Service

```typescript
// server/src/modules/notifications/notifications.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';
import { v4 as uuidv4 } from 'uuid';
import { NotificationsRepository } from './repositories/notifications.repository';
import { PreferenceManagerService } from './services/preference-manager.service';
import { NotificationRouterService } from './services/notification-router.service';
import { TemplateRendererService } from './services/template-renderer.service';
import { LoggerService } from '../../logging/logger.service';
import {
  INotificationsService,
  SendNotificationDto,
  NotificationResult,
  NotificationTemplate,
  NotificationRecipient,
  NotificationChannel,
} from './types/notification.types';

@Injectable()
export class NotificationsService implements INotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly repo: NotificationsRepository,
    private readonly preferences: PreferenceManagerService,
    private readonly router: NotificationRouterService,
    private readonly templates: TemplateRendererService,
    private readonly appLogger: LoggerService,
    @InjectQueue('notifications') private readonly queue: Queue,
  ) {}

  async send(dto: SendNotificationDto): Promise<NotificationResult> {
    // Get user preferences
    const prefs = await this.preferences.getPreferences(dto.userId);
    
    // Filter channels by preferences
    const allowedChannels = dto.channels.filter((channel) => {
      // Check category preference
      if (!prefs.categories[dto.category]) return false;
      
      // Check channel preference
      const channelKey = channel === 'in-app' ? 'inApp' : channel;
      return prefs.channels[channelKey as keyof typeof prefs.channels];
    });
    
    if (allowedChannels.length === 0) {
      this.appLogger.info('Notification blocked by preferences', {
        userId: dto.userId,
        category: dto.category,
      });
      return {
        notificationId: 'blocked',
        status: 'failed',
        channels: [],
      };
    }
    
    // Check quiet hours (for non-urgent)
    if (dto.priority !== 'urgent' && this.isQuietHours(prefs)) {
      // Schedule for after quiet hours
      const scheduledFor = this.getNextActiveTime(prefs);
      dto.scheduledFor = scheduledFor;
    }
    
    // Create notification record
    const notification = await this.repo.create({
      userId: dto.userId,
      category: dto.category,
      subject: dto.subject,
      body: dto.body,
      bodyHtml: dto.bodyHtml,
      priority: dto.priority || 'normal',
      channels: allowedChannels,
      scheduledFor: dto.scheduledFor,
      data: dto.data,
    });
    
    // Queue or send immediately
    if (dto.scheduledFor && dto.scheduledFor > new Date()) {
      const delay = dto.scheduledFor.getTime() - Date.now();
      await this.queue.add(
        'send-notification',
        { notificationId: notification.id },
        { delay, attempts: 3 },
      );
      
      return {
        notificationId: notification.id,
        status: 'queued',
        channels: allowedChannels.map((c) => ({ channel: c, delivered: false })),
      };
    }
    
    // Send immediately
    return this.dispatchNotification(notification.id);
  }

  async sendBulk(dto: any): Promise<any> {
    const results = await Promise.allSettled(
      dto.recipients.map((userId: string) =>
        this.send({
          ...dto,
          userId,
          channels: dto.channels,
        }),
      ),
    );
    
    const successful = results.filter((r) => r.status === 'fulfilled' && (r.value as any).status !== 'failed').length;
    const failed = results.length - successful;
    
    return {
      totalRecipients: results.length,
      successful,
      failed,
      errors: results
        .filter((r) => r.status === 'rejected')
        .map((r, i) => ({
          userId: dto.recipients[i],
          error: (r as any).reason?.message || 'Unknown',
        })),
    };
  }

  async sendTemplate<T extends NotificationTemplate>(
    template: T,
    recipients: NotificationRecipient[],
    data: any,
  ): Promise<NotificationResult[]> {
    const rendered = await this.templates.render(template, data);
    
    const results = [];
    for (const recipient of recipients) {
      const result = await this.send({
        userId: recipient.userId,
        channels: ['email', 'in-app'],
        category: this.templateToCategory(template),
        subject: rendered.subject,
        body: rendered.body,
        bodyHtml: rendered.html,
        data: { template, ...data },
      });
      results.push(result);
    }
    
    return results;
  }

  async getPreferences(userId: string): Promise<any> {
    return this.preferences.getPreferences(userId);
  }

  async updatePreferences(userId: string, dto: any): Promise<any> {
    return this.preferences.updatePreferences(userId, dto);
  }

  async getHistory(userId: string, filters: any): Promise<any> {
    return this.repo.findPaginated(
      { userId },
      {
        cursor: filters.cursor,
        limit: filters.limit || 50,
        orderBy: [{ field: 'createdAt', direction: 'desc' }],
      },
    );
  }

  async markAsRead(notificationId: string, userId: string): Promise<void> {
    await this.repo.update(notificationId, {
      isRead: true,
      readAt: new Date(),
    });
  }

  private async dispatchNotification(notificationId: string): Promise<NotificationResult> {
    const notification = await this.repo.findById(notificationId);
    if (!notification) throw new Error('Notification not found');
    
    const channels = notification.channels as NotificationChannel[];
    const channelResults = await this.router.sendToChannels(notification, channels);
    
    // Update statuses
    const updates: Record<string, any> = { sentAt: new Date() };
    for (const result of channelResults) {
      const statusKey = result.channel === 'in-app' ? 'inAppStatus' : `${result.channel}Status`;
      updates[statusKey] = result.delivered ? 'sent' : 'failed';
    }
    
    await this.repo.update(notificationId, updates);
    
    return {
      notificationId,
      status: channelResults.some((r) => r.delivered) ? 'sent' : 'failed',
      channels: channelResults,
    };
  }

  private templateToCategory(template: NotificationTemplate): NotificationCategory {
    if (template.startsWith('task-')) return 'task';
    if (template.startsWith('expiry-')) return 'expiry-alert';
    if (template === 'report-ready') return 'report';
    if (template === 'login-alert') return 'auth';
    return 'system';
  }

  private isQuietHours(prefs: any): boolean {
    if (!prefs.quietHours?.enabled) return false;
    
    const now = new Date();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();
    const currentTime = currentHour * 60 + currentMinute;
    
    const [startH, startM] = prefs.quietHours.start.split(':').map(Number);
    const [endH, endM] = prefs.quietHours.end.split(':').map(Number);
    const startTime = startH * 60 + startM;
    const endTime = endH * 60 + endM;
    
    if (startTime <= endTime) {
      return currentTime >= startTime && currentTime < endTime;
    } else {
      // Overnight quiet hours (e.g., 22:00-07:00)
      return currentTime >= startTime || currentTime < endTime;
    }
  }

  private getNextActiveTime(prefs: any): Date {
    const next = new Date();
    const [endH, endM] = prefs.quietHours.end.split(':').map(Number);
    next.setHours(endH, endM, 0, 0);
    if (next <= new Date()) {
      next.setDate(next.getDate() + 1);
    }
    return next;
  }
}
```

### 3. Cron Jobs

```typescript
// server/src/jobs/cron/expiry-status-update.cron.ts
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { ExpiryService } from '../../modules/expiry/expiry.service';
import { TenantsRepository } from '../../modules/tenants/tenants.repository';

@Injectable()
export class ExpiryStatusUpdateCron {
  private readonly logger = new Logger(ExpiryStatusUpdateCron.name);

  constructor(
    private readonly expiryService: ExpiryService,
    private readonly tenantsRepo: TenantsRepository,
  ) {}

  // Run daily at 2 AM
  @Cron(CronExpression.EVERY_DAY_AT_2AM)
  async updateAllStatuses(): Promise<void> {
    this.logger.log('Starting daily expiry status update');
    
    const tenants = await this.tenantsRepo.findActive();
    let totalUpdated = 0;
    
    for (const tenant of tenants) {
      try {
        // For each tenant, recalculate all stores
        // Implementation: query stores per tenant, recalc each
        // const stores = await this.storesRepo.findByTenant(tenant.id);
        // for (const store of stores) {
        //   const result = await this.expiryService.recalculateForStore(store.id);
        //   totalUpdated += result.updated;
        // }
      } catch (error) {
        this.logger.error(`Failed for tenant ${tenant.id}`, error);
      }
    }
    
    this.logger.log(`Expiry status update complete: ${totalUpdated} records updated`);
  }
}
```

```typescript
// server/src/jobs/cron/session-cleanup.cron.ts
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { ScanSessionsRepository } from '../../modules/scans/repositories/scan-sessions.repository';

@Injectable()
export class SessionCleanupCron {
  private readonly logger = new Logger(SessionCleanupCron.name);

  constructor(private readonly sessionsRepo: ScanSessionsRepository) {}

  // Run every hour
  @Cron(CronExpression.EVERY_HOUR)
  async expireInactiveSessions(): Promise<void> {
    const cutoff = new Date();
    cutoff.setHours(cutoff.getHours() - 4); // 4 hours of inactivity
    
    const expired = await this.sessionsRepo.expireInactive(cutoff);
    
    if (expired > 0) {
      this.logger.log(`Expired ${expired} inactive sessions`);
    }
  }
}
```

```typescript
// server/src/jobs/cron/data-retention.cron.ts
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { DbService } from '../../db/db.service';
import { sql } from 'drizzle-orm';

@Injectable()
export class DataRetentionCron {
  private readonly logger = new Logger(DataRetentionCron.name);

  constructor(private readonly db: DbService) {}

  // Run weekly on Sunday at 3 AM
  @Cron('0 3 * * 0')
  async cleanupOldData(): Promise<void> {
    this.logger.log('Starting weekly data retention cleanup');
    
    const db = this.db.getDb();
    
    // Cleanup expired OTP attempts (older than 30 days)
    await db.execute(sql`
      DELETE FROM otp_attempts 
      WHERE created_at < NOW() - INTERVAL '30 days'
    `);
    
    // Cleanup old notifications (older than 90 days, read)
    await db.execute(sql`
      DELETE FROM notifications 
      WHERE created_at < NOW() - INTERVAL '90 days' 
        AND is_read = true
    `);
    
    // Cleanup expired reports
    await db.execute(sql`
      DELETE FROM reports 
      WHERE expires_at < NOW()
    `);
    
    // Cleanup expired sessions
    await db.execute(sql`
      DELETE FROM user_sessions 
      WHERE expires_at < NOW() - INTERVAL '7 days'
    `);
    
    this.logger.log('Data retention cleanup complete');
  }
}
```

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| GET | `/api/v1/notifications` | Bearer | List notifications |
| POST | `/api/v1/notifications/:id/read` | Bearer | Mark as read |
| POST | `/api/v1/notifications/read-all` | Bearer | Mark all read |
| GET | `/api/v1/notifications/preferences` | Bearer | Get preferences |
| PATCH | `/api/v1/notifications/preferences` | Bearer | Update preferences |
| POST | `/api/v1/notifications/test` | Admin | Send test notification |
| POST | `/api/v1/notifications/fcm-token` | Bearer | Register FCM token |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-25 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Send Email Notification ✅
**Pass Criteria**: ✅ Email delivered (mock/SES), DB record created

### Test 2: Send SMS Notification ✅
**Pass Criteria**: ✅ SMS via MSG91 (mock in dev)

### Test 3: Push Notification ✅
**Pass Criteria**: ✅ FCM message sent

### Test 4: Multi-Channel ✅
Send to email + push + in-app:
**Pass Criteria**: ✅ All channels delivered

### Test 5: Preference Filtering ✅
User disables email category:
**Expected**: Email skipped, others sent
**Pass Criteria**: ✅ Preferences respected

### Test 6: Quiet Hours ✅
Set 22:00-07:00 quiet hours, send at 23:00:
**Expected**: Scheduled for 07:00 next day
**Pass Criteria**: ✅ Quiet hours work

### Test 7: Urgent Bypasses Quiet Hours ✅
Priority='urgent' during quiet hours:
**Expected**: Sent immediately
**Pass Criteria**: ✅ Override works

### Test 8: Template Rendering ✅
Send 'task-assigned' with data:
**Expected**: Subject + body + HTML rendered
**Pass Criteria**: ✅ Templates work

### Test 9: Bulk Send ✅
Send to 100 users:
**Expected**: All processed, partial failures handled
**Pass Criteria**: ✅ Bulk works

### Test 10: Daily Aggregation Cron ✅
Manually trigger:
**Expected**: daily_store_metrics populated
**Pass Criteria**: ✅ Cron works

### Test 11: Expiry Status Cron ✅
Run cron, check expiry records:
**Expected**: Statuses updated
**Pass Criteria**: ✅ Recalc cron works

### Test 12: Session Cleanup Cron ✅
Old sessions auto-expire:
**Pass Criteria**: ✅ Cleanup runs

### Test 13: Data Retention ✅
Old data cleaned up:
**Pass Criteria**: ✅ Retention enforced

### Test 14: Notification History ✅
**Pass Criteria**: ✅ Paginated history works

### Test 15: Mark as Read ✅
**Pass Criteria**: ✅ Read state updates

## 🎯 Q&A Session

### Q1: Why multi-channel?
**Expected**: Different urgencies, user preferences, redundancy

### Q2: Why quiet hours?
**Expected**: Don't wake users at night, professional courtesy, GDPR

### Q3: Why FCM for push?
**Expected**: Free, Google-backed, iOS+Android support

### Q4: Why cron jobs vs queues?
**Expected**: Cron for time-based, queue for event-based

### Q5: Why data retention?
**Expected**: Compliance, storage costs, performance

### Q6: How handle SES bounces?
**Expected**: Webhook → mark email invalid, suppress future sends

### Q7: How scale notifications?
**Expected**: Bull workers, batching, AWS SES has high limits

### Q8: Notification storms?
**Expected**: Rate limit per user, digest mode, throttling

## 📝 Sign-Off Checklist

- [ ] All 15 tests pass
- [ ] All channels work
- [ ] Preferences respected
- [ ] Cron jobs running
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-25**
**☐ CHANGES REQUESTED**

---

**END OF BE-24 — DO NOT PROCEED WITHOUT APPROVAL**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-24 with the FCM-first notification stack (Req 28), the Recall Sweep cron (Req 31), the Daily Insights cron (Req 47), and Notification_Preferences enforcement (Req 28).**

## Driver Requirements

- **Req 28** — Notification stack: FCM primary, In-App secondary, AWS SES tertiary, MSG91 SMS only for OTP. Per-User per-category Notification_Preferences. SES 62K/month budget warning. FCM permanent-failure token invalidation.
- **Req 31** — `Recall_Sweep_Job` cron (daily) fetches FSSAI feed, matches against saved products, fires FCM with retry/backoff and Sentry on failure.
- **Req 47** — Weekly `Daily_Insights_Job` per-Consumer digest delivered via FCM, respects opt-out.

## Scope of Update

This phase already provides the BullMQ infrastructure and the abstract Notification interface. v2 adds:

1. **FCM channel implementation** as the primary push channel.
2. **AWS SES channel implementation** as the tertiary email channel.
3. **In-App channel implementation** writing to `notifications` table (read by mobile via `GET /api/v1/notifications`).
4. **Notification_Preferences table + service** with per-category opt-out enforcement.
5. **Channel router** that selects channel(s) per notification type using preferences.
6. **SES budget watcher** logging warnings near the 62K/month free-tier ceiling.
7. **FCM permanent-failure handler** marking device tokens invalid.

The Recall_Sweep_Job (Req 31) and Daily_Insights_Job (Req 47) themselves live in their dedicated phases (BE-39 and BE-54) but consume the channels and preferences defined here.

## Files to Create / Modify

| File Path | Change |
|---|---|
| `server/src/modules/notifications/channels/fcm.channel.ts` | New — wraps Firebase Admin SDK |
| `server/src/modules/notifications/channels/ses.channel.ts` | New — wraps `@aws-sdk/client-ses` |
| `server/src/modules/notifications/channels/in-app.channel.ts` | New — writes to `notifications` table |
| `server/src/modules/notifications/services/preferences.service.ts` | New |
| `server/src/modules/notifications/services/channel-router.service.ts` | New |
| `server/src/modules/notifications/services/ses-budget-watcher.service.ts` | New |
| `server/src/modules/notifications/services/fcm-token-cleanup.service.ts` | New |
| `server/src/database/migrations/v2/2026XXXX_notifications_v2.sql` | New tables: `notification_preferences`, `device_tokens`, `notifications` |

## Schema

```sql
CREATE TABLE device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  invalidated_at TIMESTAMPTZ,
  invalidation_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_used_at TIMESTAMPTZ
);

CREATE TABLE notification_preferences (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category TEXT NOT NULL,         -- 'expiry_alert', 'recall_alert', 'marketing', 'business_activation', 'daily_insights', etc.
  channel TEXT NOT NULL,          -- 'fcm', 'in_app', 'email', 'sms'
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (user_id, category, channel)
);

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 days')
);

CREATE INDEX idx_notifications_user_unread
  ON notifications(user_id, created_at DESC)
  WHERE read_at IS NULL;
```

## Channel Router

```typescript
@Injectable()
export class ChannelRouterService {
  constructor(
    private readonly fcm: FcmChannel,
    private readonly ses: SesChannel,
    private readonly inApp: InAppChannel,
    private readonly preferences: PreferencesService,
  ) {}

  async deliver(req: NotificationRequest): Promise<DeliveryReceipt[]> {
    const enabled = await this.preferences.enabledChannelsFor(req.userId, req.category);

    const tasks: Promise<DeliveryReceipt>[] = [];
    if (enabled.has('fcm'))    tasks.push(this.fcm.send(req));
    if (enabled.has('in_app')) tasks.push(this.inApp.send(req));
    if (enabled.has('email'))  tasks.push(this.ses.send(req));
    // SMS is intentionally not used for any non-OTP category

    return Promise.all(tasks);
  }
}
```

## SES Budget Watcher

```typescript
@Injectable()
export class SesBudgetWatcherService {
  private readonly FREE_TIER_LIMIT = 62_000;

  @Cron(CronExpression.EVERY_HOUR)
  async checkUsage() {
    const used = await this.ses.monthToDateSendCount();
    if (used / this.FREE_TIER_LIMIT >= 0.85) {
      this.logger.warn(`SES free-tier usage at ${(used / this.FREE_TIER_LIMIT * 100).toFixed(1)}%`);
      await this.ownerAlerts.send('SES budget warning', { used, limit: this.FREE_TIER_LIMIT });
    }
  }
}
```

## FCM Token Cleanup

```typescript
async handlePermanentFailure(token: string, reason: 'unregistered' | 'invalid_argument') {
  await this.deviceTokens.update(
    { token },
    { is_active: false, invalidated_at: new Date(), invalidation_reason: reason },
  );
}
```

## ADDENDUM v2 Test Procedures (add 6)

| # | Test |
|---|---|
| T-v2.1 | Notification with category=`marketing` is suppressed if user opts out of marketing |
| T-v2.2 | FCM unregistered token marks `device_tokens.is_active=false` |
| T-v2.3 | SES budget watcher logs warning at 85% of 62K free tier |
| T-v2.4 | Channel router runs FCM + in-app + email in parallel for a recall alert |
| T-v2.5 | SMS channel is never selected for any category other than `otp` |
| T-v2.6 | In-app notifications older than 30 days are pruned by the cleanup cron |

## ADDENDUM v2 Q&A (add 3)

- **Q-v2.1**: How are Notification_Preferences seeded for a brand-new user?
- **Q-v2.2**: How does the system handle a user with multiple devices (e.g., phone + tablet) so they receive one notification per device but only one in-app entry?
- **Q-v2.3**: What is the retry policy when FCM returns a transient error vs permanent error?

## ADDENDUM v2 Sign-off

- [ ] FCM channel live and tested with Firebase Admin SDK
- [ ] SES channel live and tested
- [ ] In-app channel live and tested
- [ ] Preferences enforcement verified
- [ ] Token invalidation working
- [ ] SMS limited to OTP only

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-24 ADDENDUM v2**
