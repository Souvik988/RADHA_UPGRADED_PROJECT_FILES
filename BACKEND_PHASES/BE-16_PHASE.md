# Phase BE-16: Scan Session Management

## Phase Metadata

- **Phase ID**: BE-16
- **Phase Name**: Scan Session Management
- **Section**: Backend Execution — Audit & Compliance Layer
- **Depends On**: BE-01 to BE-15
- **Blocks**: BE-17, BE-18, BE-20 (reports use scan data)
- **Estimated Duration**: 3 days
- **Complexity**: High
- **Priority**: CRITICAL (core feature)

## Goal

Build the core scanning workflow: scan session lifecycle, individual scan item recording, EAN validation integration, real-time scan stats, duplicate detection within session, location tagging, scan metadata (device, timestamp, user), session completion with summaries, and audit trail for compliance.

## Why This Phase Matters

**Scanning IS the core RADHA feature.** This phase enables:
- Mobile scanner workflow (most-used feature)
- EAN validation against approved lists (BE-15 integration)
- Audit trail for compliance
- Real-time feedback to users
- Foundation for all reporting (BE-20)
- Bulk scan processing (BE-17)

Without this, RADHA is just a product catalog—not an audit platform.

## Prerequisites

- [ ] BE-01 to BE-15 completed
- [ ] EAN matcher service ready (BE-15)
- [ ] Product lookup ready (BE-10, BE-11)
- [ ] Health scoring ready (BE-12)
- [ ] Tenant/store scoping working (BE-09)

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/scan_sessions.ts` | Session metadata |
| `server/src/db/schema/scan_items.ts` | Individual scans |
| `server/src/db/schema/scan_session_summaries.ts` | Aggregated stats |
| `server/src/modules/scans/scans.module.ts` | Module |
| `server/src/modules/scans/scans.controller.ts` | Endpoints |
| `server/src/modules/scans/scans.service.ts` | Business logic |
| `server/src/modules/scans/services/scan-session.service.ts` | Session lifecycle |
| `server/src/modules/scans/services/scan-item.service.ts` | Item recording |
| `server/src/modules/scans/services/scan-summary.service.ts` | Stats aggregation |
| `server/src/modules/scans/services/duplicate-detector.service.ts` | Within-session dedup |
| `server/src/modules/scans/repositories/scan-sessions.repository.ts` | Sessions data |
| `server/src/modules/scans/repositories/scan-items.repository.ts` | Items data |
| `server/src/modules/scans/dto/create-session.dto.ts` | DTOs |
| `server/src/modules/scans/dto/scan-item.dto.ts` | DTOs |
| `server/src/modules/scans/dto/end-session.dto.ts` | DTOs |
| `server/src/modules/scans/dto/list-sessions.dto.ts` | DTOs |
| `server/src/modules/scans/types/scan.types.ts` | Types |
| `server/src/modules/scans/utils/scan-stats.utils.ts` | Stats calculation |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/scans/services/scan-session.service.ts

export interface IScanSessionService {
  // Lifecycle
  create(dto: CreateSessionDto, userId: string): Promise<ScanSession>;
  findById(id: string): Promise<ScanSessionWithStats | null>;
  end(id: string, dto: EndSessionDto, userId: string): Promise<ScanSession>;
  abandon(id: string, userId: string): Promise<ScanSession>;
  
  // Listing
  listForUser(userId: string, filters: ListSessionsFilter): Promise<PaginatedResult<ScanSession>>;
  listForStore(storeId: string, filters: ListSessionsFilter): Promise<PaginatedResult<ScanSession>>;
  
  // Active session
  getActiveSession(userId: string, storeId: string): Promise<ScanSession | null>;
  
  // Summaries
  getSessionSummary(sessionId: string): Promise<SessionSummary>;
  getDailyStats(storeId: string, date: Date): Promise<DailyStats>;
}

// server/src/modules/scans/services/scan-item.service.ts

export interface IScanItemService {
  // Recording
  recordScan(sessionId: string, dto: ScanItemDto, userId: string): Promise<ScanItemResult>;
  
  // Bulk
  recordBatch(sessionId: string, items: ScanItemDto[], userId: string): Promise<ScanItemResult[]>;
  
  // Queries
  listForSession(sessionId: string, pagination: PaginationParams): Promise<PaginatedResult<ScanItem>>;
  findById(id: string): Promise<ScanItem | null>;
  
  // Special
  findDuplicateInSession(sessionId: string, ean: string): Promise<ScanItem | null>;
  removeFromSession(itemId: string, userId: string): Promise<void>;
}

export interface CreateSessionDto {
  storeId: string;
  type: ScanSessionType;
  taskId?: string;
  eanListId?: string; // Optional: validate against specific list
  metadata?: Record<string, unknown>;
}

export type ScanSessionType = 
  | 'audit'         // Compliance audit
  | 'shelf-check'   // Daily shelf verification
  | 'expiry-check'  // Expiry date capture
  | 'inventory'     // Stock count
  | 'training'      // Practice mode
  | 'general';      // General purpose

export type ScanSessionStatus =
  | 'active'        // Currently scanning
  | 'completed'     // User completed
  | 'abandoned'     // User left without completing
  | 'expired';      // Auto-expired

export interface ScanItemDto {
  ean: string;
  scannedAt: Date;
  productId?: string; // If known
  expiryDate?: Date;
  manufactureDate?: Date;
  batchNumber?: string;
  quantity?: number;
  shelfLocation?: string;
  notes?: string;
  imageMediaId?: string;
  latitude?: number;
  longitude?: number;
  deviceId?: string;
}

export interface ScanItemResult {
  scanItem: ScanItem;
  product?: Product;
  eanValidation?: EanValidationResult;
  expiryStatus?: ExpiryStatus;
  isDuplicate: boolean;
  duplicateOf?: ScanItem;
  warnings: ScanWarning[];
}

export interface ScanWarning {
  type: 'duplicate_in_session' | 'unmatched_ean' | 'expired_product' | 'near_expiry' | 'health_warning';
  message: string;
  severity: 'info' | 'warning' | 'error';
}

export interface SessionSummary {
  sessionId: string;
  totalScans: number;
  uniqueProducts: number;
  matchedEans: number;
  unmatchedEans: number;
  expiredItems: number;
  nearExpiryItems: number;
  warningsCount: number;
  durationSeconds: number;
  scanRate: number; // scans per minute
}

export interface DailyStats {
  date: Date;
  totalSessions: number;
  totalScans: number;
  byType: Record<ScanSessionType, number>;
  byUser: Array<{ userId: string; count: number }>;
}
```

## Implementation Code

### 1. Scan Sessions Schema

```typescript
// server/src/db/schema/scan_sessions.ts
import { pgTable, varchar, uuid, integer, timestamp, jsonb, pgEnum, index, decimal } from 'drizzle-orm/pg-core';
import { baseColumns, softDeleteColumn, auditColumns } from './_base';

export const scanSessionTypeEnum = pgEnum('scan_session_type', [
  'audit',
  'shelf-check',
  'expiry-check',
  'inventory',
  'training',
  'general',
]);

export const scanSessionStatusEnum = pgEnum('scan_session_status', [
  'active',
  'completed',
  'abandoned',
  'expired',
]);

export const scanSessions = pgTable(
  'scan_sessions',
  {
    ...baseColumns,
    ...softDeleteColumn,
    ...auditColumns,
    tenantId: uuid('tenant_id').notNull(),
    storeId: uuid('store_id').notNull(),
    userId: uuid('user_id').notNull(),
    
    type: scanSessionTypeEnum('type').notNull().default('general'),
    status: scanSessionStatusEnum('status').notNull().default('active'),
    
    // Optional links
    taskId: uuid('task_id'),
    eanListId: uuid('ean_list_id'),
    
    // Stats (denormalized for performance)
    totalScans: integer('total_scans').notNull().default(0),
    uniqueProducts: integer('unique_products').notNull().default(0),
    matchedEans: integer('matched_eans').notNull().default(0),
    unmatchedEans: integer('unmatched_eans').notNull().default(0),
    expiredItems: integer('expired_items').notNull().default(0),
    nearExpiryItems: integer('near_expiry_items').notNull().default(0),
    
    // Timing
    startedAt: timestamp('started_at', { withTimezone: true }).notNull().defaultNow(),
    endedAt: timestamp('ended_at', { withTimezone: true }),
    lastActivityAt: timestamp('last_activity_at', { withTimezone: true }).defaultNow(),
    durationSeconds: integer('duration_seconds'),
    
    // Location
    startLatitude: decimal('start_latitude', { precision: 10, scale: 7 }),
    startLongitude: decimal('start_longitude', { precision: 10, scale: 7 }),
    
    // Device
    deviceId: varchar('device_id', { length: 255 }),
    deviceModel: varchar('device_model', { length: 100 }),
    appVersion: varchar('app_version', { length: 20 }),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    tenantStoreIdx: index('idx_scan_sessions_tenant_store').on(table.tenantId, table.storeId),
    storeCreatedIdx: index('idx_scan_sessions_store_created').on(table.storeId, table.startedAt),
    userActiveIdx: index('idx_scan_sessions_user_active').on(table.userId, table.status),
    statusIdx: index('idx_scan_sessions_status').on(table.status),
    typeIdx: index('idx_scan_sessions_type').on(table.tenantId, table.type),
  }),
);

export type ScanSession = typeof scanSessions.$inferSelect;
export type NewScanSession = typeof scanSessions.$inferInsert;
```

### 2. Scan Items Schema

```typescript
// server/src/db/schema/scan_items.ts
import { pgTable, varchar, uuid, integer, timestamp, jsonb, pgEnum, decimal, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const expiryStatusEnum = pgEnum('expiry_status', [
  'green',     // > 30 days
  'yellow',    // 7-30 days
  'red',       // < 7 days or expired
  'unknown',   // No expiry date provided
]);

export const eanMatchStatusEnum = pgEnum('ean_match_status', [
  'matched',     // EAN in approved list
  'unmatched',   // EAN not in approved list
  'no_list',     // No active list
  'invalid',     // Invalid EAN format
  'unchecked',   // Not validated yet
]);

export const scanItems = pgTable(
  'scan_items',
  {
    ...baseColumns,
    sessionId: uuid('session_id').notNull(),
    tenantId: uuid('tenant_id').notNull(),
    storeId: uuid('store_id').notNull(),
    userId: uuid('user_id').notNull(),
    
    // Product
    ean: varchar('ean', { length: 13 }).notNull(),
    productId: uuid('product_id'),
    productNameSnapshot: varchar('product_name_snapshot', { length: 200 }),
    brandSnapshot: varchar('brand_snapshot', { length: 100 }),
    
    // Validation
    eanMatchStatus: eanMatchStatusEnum('ean_match_status').notNull().default('unchecked'),
    expiryStatus: expiryStatusEnum('expiry_status').default('unknown'),
    
    // Capture details
    scannedAt: timestamp('scanned_at', { withTimezone: true }).notNull(),
    expiryDate: timestamp('expiry_date', { withTimezone: true }),
    manufactureDate: timestamp('manufacture_date', { withTimezone: true }),
    batchNumber: varchar('batch_number', { length: 100 }),
    quantity: integer('quantity').default(1),
    shelfLocation: varchar('shelf_location', { length: 100 }),
    notes: varchar('notes', { length: 500 }),
    imageMediaId: uuid('image_media_id'),
    
    // Location
    latitude: decimal('latitude', { precision: 10, scale: 7 }),
    longitude: decimal('longitude', { precision: 10, scale: 7 }),
    
    // Device
    deviceId: varchar('device_id', { length: 255 }),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    sessionIdx: index('idx_scan_items_session').on(table.sessionId),
    storeCreatedIdx: index('idx_scan_items_store_created').on(table.storeId, table.scannedAt),
    eanIdx: index('idx_scan_items_ean').on(table.ean),
    productIdx: index('idx_scan_items_product').on(table.productId),
    matchStatusIdx: index('idx_scan_items_match_status').on(table.eanMatchStatus),
    expiryStatusIdx: index('idx_scan_items_expiry_status').on(table.expiryStatus),
  }),
);

export type ScanItem = typeof scanItems.$inferSelect;
export type NewScanItem = typeof scanItems.$inferInsert;
```

### 3. Scan Session Service

```typescript
// server/src/modules/scans/services/scan-session.service.ts
import { Injectable } from '@nestjs/common';
import { ScanSessionsRepository } from '../repositories/scan-sessions.repository';
import { ScanItemsRepository } from '../repositories/scan-items.repository';
import { DbService } from '../../../db/db.service';
import { AuditLogService } from '../../../observability/audit-log.service';
import { LoggerService } from '../../../logging/logger.service';
import {
  IScanSessionService,
  CreateSessionDto,
  EndSessionDto,
  ScanSessionWithStats,
  SessionSummary,
} from '../types/scan.types';
import {
  NotFoundException,
  BusinessException,
} from '../../../common/errors/business.exception';
import { ErrorCode } from '../../../common/errors/error-codes';

@Injectable()
export class ScanSessionService implements IScanSessionService {
  // Auto-expire sessions after 4 hours of inactivity
  private readonly INACTIVITY_TIMEOUT_MS = 4 * 60 * 60 * 1000;

  constructor(
    private readonly db: DbService,
    private readonly sessionsRepo: ScanSessionsRepository,
    private readonly itemsRepo: ScanItemsRepository,
    private readonly auditLog: AuditLogService,
    private readonly logger: LoggerService,
  ) {}

  async create(dto: CreateSessionDto, userId: string): Promise<ScanSession> {
    // Check for active session (only one active per user per store)
    const existing = await this.getActiveSession(userId, dto.storeId);
    if (existing) {
      throw new BusinessException(
        ErrorCode.CONFLICT,
        'Active scan session already exists. End it first.',
        { metadata: { activeSessionId: existing.id } },
      );
    }

    const session = await this.sessionsRepo.create({
      storeId: dto.storeId,
      userId,
      type: dto.type,
      status: 'active',
      taskId: dto.taskId,
      eanListId: dto.eanListId,
      startedAt: new Date(),
      lastActivityAt: new Date(),
      metadata: dto.metadata,
    });

    await this.auditLog.logAction({
      action: 'CREATE',
      resourceType: 'ScanSession',
      resourceId: session.id,
      userId,
      tenantId: session.tenantId,
      success: true,
      metadata: { type: dto.type, storeId: dto.storeId },
    });

    return session;
  }

  async findById(id: string): Promise<ScanSessionWithStats | null> {
    const session = await this.sessionsRepo.findById(id);
    if (!session) return null;

    return {
      ...session,
      summary: await this.getSessionSummary(id),
    };
  }

  async end(id: string, dto: EndSessionDto, userId: string): Promise<ScanSession> {
    const session = await this.sessionsRepo.findById(id);
    if (!session) throw new NotFoundException('ScanSession', id);
    
    if (session.userId !== userId) {
      throw new BusinessException(
        ErrorCode.FORBIDDEN,
        'Cannot end session belonging to another user',
      );
    }
    
    if (session.status !== 'active') {
      throw new BusinessException(
        ErrorCode.SCAN_SESSION_CLOSED,
        `Session is already ${session.status}`,
      );
    }

    const endedAt = new Date();
    const durationSeconds = Math.floor(
      (endedAt.getTime() - new Date(session.startedAt).getTime()) / 1000,
    );

    return this.db.transaction(async (tx) => {
      // Update session
      const updated = await this.sessionsRepo.update(id, {
        status: 'completed',
        endedAt,
        durationSeconds,
        ...(dto.notes && { metadata: { ...session.metadata, endNotes: dto.notes } }),
      }, tx);

      // Refresh denormalized stats
      await this.refreshSessionStats(id, tx);

      await this.auditLog.logAction({
        action: 'UPDATE',
        resourceType: 'ScanSession',
        resourceId: id,
        userId,
        tenantId: session.tenantId,
        success: true,
        metadata: { 
          status: 'completed', 
          durationSeconds,
          totalScans: updated.totalScans,
        },
      });

      return updated;
    });
  }

  async abandon(id: string, userId: string): Promise<ScanSession> {
    const session = await this.sessionsRepo.findById(id);
    if (!session) throw new NotFoundException('ScanSession', id);
    
    if (session.status !== 'active') return session;

    return this.sessionsRepo.update(id, {
      status: 'abandoned',
      endedAt: new Date(),
    });
  }

  async getActiveSession(userId: string, storeId: string): Promise<ScanSession | null> {
    return this.sessionsRepo.findActiveForUser(userId, storeId);
  }

  async getSessionSummary(sessionId: string): Promise<SessionSummary> {
    const session = await this.sessionsRepo.findById(sessionId);
    if (!session) throw new NotFoundException('ScanSession', sessionId);
    
    const items = await this.itemsRepo.findBySession(sessionId);
    
    const uniqueEans = new Set(items.map((i) => i.ean));
    const matched = items.filter((i) => i.eanMatchStatus === 'matched').length;
    const unmatched = items.filter((i) => i.eanMatchStatus === 'unmatched').length;
    const expired = items.filter((i) => i.expiryStatus === 'red').length;
    const nearExpiry = items.filter((i) => i.expiryStatus === 'yellow').length;
    
    const startTime = new Date(session.startedAt).getTime();
    const endTime = session.endedAt 
      ? new Date(session.endedAt).getTime() 
      : Date.now();
    const durationSeconds = Math.floor((endTime - startTime) / 1000);
    const scanRate = durationSeconds > 0 
      ? (items.length / durationSeconds) * 60 
      : 0;
    
    return {
      sessionId,
      totalScans: items.length,
      uniqueProducts: uniqueEans.size,
      matchedEans: matched,
      unmatchedEans: unmatched,
      expiredItems: expired,
      nearExpiryItems: nearExpiry,
      warningsCount: unmatched + expired + nearExpiry,
      durationSeconds,
      scanRate: Math.round(scanRate * 10) / 10,
    };
  }

  async listForUser(userId: string, filters: any): Promise<any> {
    return this.sessionsRepo.findPaginated(
      { userId },
      { 
        cursor: filters.cursor, 
        limit: filters.limit || 50, 
        orderBy: [{ field: 'startedAt', direction: 'desc' }] 
      },
    );
  }

  async listForStore(storeId: string, filters: any): Promise<any> {
    return this.sessionsRepo.findPaginated(
      { storeId },
      { 
        cursor: filters.cursor, 
        limit: filters.limit || 50, 
        orderBy: [{ field: 'startedAt', direction: 'desc' }] 
      },
    );
  }

  async getDailyStats(storeId: string, date: Date): Promise<any> {
    return this.sessionsRepo.getDailyStats(storeId, date);
  }

  private async refreshSessionStats(sessionId: string, tx?: any): Promise<void> {
    const items = await this.itemsRepo.findBySession(sessionId);
    
    const stats = {
      totalScans: items.length,
      uniqueProducts: new Set(items.map((i) => i.ean)).size,
      matchedEans: items.filter((i) => i.eanMatchStatus === 'matched').length,
      unmatchedEans: items.filter((i) => i.eanMatchStatus === 'unmatched').length,
      expiredItems: items.filter((i) => i.expiryStatus === 'red').length,
      nearExpiryItems: items.filter((i) => i.expiryStatus === 'yellow').length,
    };
    
    await this.sessionsRepo.update(sessionId, stats, tx);
  }
}
```

### 4. Scan Item Service

```typescript
// server/src/modules/scans/services/scan-item.service.ts
import { Injectable } from '@nestjs/common';
import { ScanItemsRepository } from '../repositories/scan-items.repository';
import { ScanSessionsRepository } from '../repositories/scan-sessions.repository';
import { ProductLookupService } from '../../products/services/product-lookup.service';
import { EanMatcherService } from '../../ean-lists/services/ean-matcher.service';
import { DuplicateDetectorService } from './duplicate-detector.service';
import { DbService } from '../../../db/db.service';
import { LoggerService } from '../../../logging/logger.service';
import {
  IScanItemService,
  ScanItemDto,
  ScanItemResult,
  ScanWarning,
} from '../types/scan.types';
import { normalizeEan } from '../../products/utils/ean.utils';
import {
  NotFoundException,
  BusinessException,
} from '../../../common/errors/business.exception';
import { ErrorCode } from '../../../common/errors/error-codes';

@Injectable()
export class ScanItemService implements IScanItemService {
  constructor(
    private readonly db: DbService,
    private readonly itemsRepo: ScanItemsRepository,
    private readonly sessionsRepo: ScanSessionsRepository,
    private readonly productLookup: ProductLookupService,
    private readonly eanMatcher: EanMatcherService,
    private readonly duplicateDetector: DuplicateDetectorService,
    private readonly logger: LoggerService,
  ) {}

  async recordScan(
    sessionId: string,
    dto: ScanItemDto,
    userId: string,
  ): Promise<ScanItemResult> {
    // Verify session is active
    const session = await this.sessionsRepo.findById(sessionId);
    if (!session) throw new NotFoundException('ScanSession', sessionId);
    if (session.status !== 'active') {
      throw new BusinessException(
        ErrorCode.SCAN_SESSION_CLOSED,
        'Cannot scan into a closed session',
      );
    }
    if (session.userId !== userId) {
      throw new BusinessException(ErrorCode.FORBIDDEN, 'Not your session');
    }

    const normalizedEan = normalizeEan(dto.ean);

    // Look up product (will create from OFF if needed)
    const productResult = await this.productLookup.lookupByEan(normalizedEan);
    const product = productResult.product;

    // Validate against EAN list (if applicable)
    let eanValidation = undefined;
    if (session.eanListId || true) { // Always validate if active list
      eanValidation = await this.eanMatcher.validate(normalizedEan, session.storeId);
    }

    // Check for duplicate in session
    const duplicate = await this.duplicateDetector.findDuplicate(
      sessionId,
      normalizedEan,
      dto.batchNumber,
    );

    // Calculate expiry status
    const expiryStatus = this.calculateExpiryStatus(dto.expiryDate);

    // Build warnings
    const warnings: ScanWarning[] = [];
    if (duplicate) {
      warnings.push({
        type: 'duplicate_in_session',
        message: 'This EAN was already scanned in this session',
        severity: 'warning',
      });
    }
    if (eanValidation && !eanValidation.matched) {
      warnings.push({
        type: 'unmatched_ean',
        message: 'Product not in approved list',
        severity: 'error',
      });
    }
    if (expiryStatus === 'red') {
      warnings.push({
        type: 'expired_product',
        message: 'Product is expired',
        severity: 'error',
      });
    } else if (expiryStatus === 'yellow') {
      warnings.push({
        type: 'near_expiry',
        message: 'Product expires within 30 days',
        severity: 'warning',
      });
    }

    // Map to scan item
    const eanMatchStatus = eanValidation
      ? eanValidation.matched ? 'matched' : eanValidation.reason === 'no_active_list' ? 'no_list' : 'unmatched'
      : 'unchecked';

    return this.db.transaction(async (tx) => {
      // Insert scan item
      const scanItem = await this.itemsRepo.create({
        sessionId,
        tenantId: session.tenantId,
        storeId: session.storeId,
        userId,
        ean: normalizedEan,
        productId: product?.id,
        productNameSnapshot: product?.name,
        brandSnapshot: product?.brand,
        eanMatchStatus,
        expiryStatus,
        scannedAt: dto.scannedAt,
        expiryDate: dto.expiryDate,
        manufactureDate: dto.manufactureDate,
        batchNumber: dto.batchNumber,
        quantity: dto.quantity || 1,
        shelfLocation: dto.shelfLocation,
        notes: dto.notes,
        imageMediaId: dto.imageMediaId,
        latitude: dto.latitude?.toString(),
        longitude: dto.longitude?.toString(),
        deviceId: dto.deviceId,
      }, tx);

      // Update session activity
      await this.sessionsRepo.update(sessionId, {
        lastActivityAt: new Date(),
        totalScans: session.totalScans + 1,
        ...(eanMatchStatus === 'matched' && { matchedEans: session.matchedEans + 1 }),
        ...(eanMatchStatus === 'unmatched' && { unmatchedEans: session.unmatchedEans + 1 }),
        ...(expiryStatus === 'red' && { expiredItems: session.expiredItems + 1 }),
        ...(expiryStatus === 'yellow' && { nearExpiryItems: session.nearExpiryItems + 1 }),
      }, tx);

      return {
        scanItem,
        product,
        eanValidation,
        expiryStatus,
        isDuplicate: !!duplicate,
        duplicateOf: duplicate || undefined,
        warnings,
      };
    });
  }

  async recordBatch(
    sessionId: string,
    items: ScanItemDto[],
    userId: string,
  ): Promise<ScanItemResult[]> {
    const results: ScanItemResult[] = [];
    
    // Process sequentially to maintain order and update session stats correctly
    for (const item of items) {
      try {
        const result = await this.recordScan(sessionId, item, userId);
        results.push(result);
      } catch (error) {
        this.logger.error('Failed to record scan in batch', {
          sessionId,
          ean: item.ean,
          error: error instanceof Error ? error.message : 'Unknown',
        });
        // Continue with rest of batch
      }
    }
    
    return results;
  }

  async listForSession(sessionId: string, pagination: any): Promise<any> {
    return this.itemsRepo.findPaginated(
      { sessionId },
      {
        cursor: pagination.cursor,
        limit: pagination.limit || 50,
        orderBy: [{ field: 'scannedAt', direction: 'desc' }],
      },
    );
  }

  async findById(id: string): Promise<ScanItem | null> {
    return this.itemsRepo.findById(id);
  }

  async findDuplicateInSession(sessionId: string, ean: string): Promise<ScanItem | null> {
    return this.duplicateDetector.findDuplicate(sessionId, normalizeEan(ean));
  }

  async removeFromSession(itemId: string, userId: string): Promise<void> {
    const item = await this.itemsRepo.findById(itemId);
    if (!item) throw new NotFoundException('ScanItem', itemId);
    
    // Soft delete (preserve audit trail)
    await this.itemsRepo.softDelete(itemId, userId);
  }

  private calculateExpiryStatus(expiryDate?: Date): 'green' | 'yellow' | 'red' | 'unknown' {
    if (!expiryDate) return 'unknown';
    
    const now = new Date();
    const daysUntilExpiry = Math.floor(
      (expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24),
    );
    
    if (daysUntilExpiry < 7) return 'red';
    if (daysUntilExpiry <= 30) return 'yellow';
    return 'green';
  }
}
```

### 5. DTOs

```typescript
// server/src/modules/scans/dto/create-session.dto.ts
import { z } from 'zod';

export const CreateSessionSchema = z.object({
  storeId: z.string().uuid(),
  type: z.enum(['audit', 'shelf-check', 'expiry-check', 'inventory', 'training', 'general']),
  taskId: z.string().uuid().optional(),
  eanListId: z.string().uuid().optional(),
  startLatitude: z.number().min(-90).max(90).optional(),
  startLongitude: z.number().min(-180).max(180).optional(),
  deviceId: z.string().max(255).optional(),
  deviceModel: z.string().max(100).optional(),
  appVersion: z.string().max(20).optional(),
  metadata: z.record(z.unknown()).optional(),
});

export type CreateSessionDto = z.infer<typeof CreateSessionSchema>;
```

```typescript
// server/src/modules/scans/dto/scan-item.dto.ts
import { z } from 'zod';

export const ScanItemSchema = z.object({
  ean: z.string().regex(/^\d{8,13}$/, 'EAN must be 8-13 digits'),
  scannedAt: z.coerce.date(),
  productId: z.string().uuid().optional(),
  expiryDate: z.coerce.date().optional(),
  manufactureDate: z.coerce.date().optional(),
  batchNumber: z.string().max(100).optional(),
  quantity: z.number().int().min(1).default(1),
  shelfLocation: z.string().max(100).optional(),
  notes: z.string().max(500).optional(),
  imageMediaId: z.string().uuid().optional(),
  latitude: z.number().min(-90).max(90).optional(),
  longitude: z.number().min(-180).max(180).optional(),
  deviceId: z.string().max(255).optional(),
}).refine(
  (data) => !data.expiryDate || !data.manufactureDate || data.expiryDate > data.manufactureDate,
  { message: 'Expiry date must be after manufacture date', path: ['expiryDate'] },
);

export type ScanItemDto = z.infer<typeof ScanItemSchema>;
```

## API Endpoints

| Method | Endpoint | Auth | Role | Purpose |
|---|---|---|---|---|
| POST | `/api/v1/scan-sessions` | Bearer | Staff+ | Create session |
| GET | `/api/v1/scan-sessions` | Bearer | Staff+ | List sessions |
| GET | `/api/v1/scan-sessions/active` | Bearer | Staff+ | Get active session |
| GET | `/api/v1/scan-sessions/:id` | Bearer | Staff+ | Get session details |
| POST | `/api/v1/scan-sessions/:id/end` | Bearer | Staff+ | End session |
| POST | `/api/v1/scan-sessions/:id/abandon` | Bearer | Staff+ | Abandon session |
| GET | `/api/v1/scan-sessions/:id/summary` | Bearer | Staff+ | Get summary |
| POST | `/api/v1/scan-sessions/:id/items` | Bearer | Staff+ | Record scan |
| POST | `/api/v1/scan-sessions/:id/items/batch` | Bearer | Staff+ | Bulk scan |
| GET | `/api/v1/scan-sessions/:id/items` | Bearer | Staff+ | List items |
| DELETE | `/api/v1/scan-sessions/:id/items/:itemId` | Bearer | Staff+ | Remove item |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-17 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Create Scan Session ✅

```bash
curl -X POST http://localhost:3000/api/v1/scan-sessions \
  -H "Authorization: Bearer <token>" \
  -d '{"storeId":"<store-id>","type":"audit"}'
```

**Expected**: 201, session created with status=active
**Pass Criteria**: ✅ Session creation works

---

### Test 2: Cannot Create Duplicate Active Session ✅

Create one session, try to create another for same user/store:
**Expected**: 409 with reference to active session
**Pass Criteria**: ✅ One active session per user/store

---

### Test 3: Record Scan Item ✅

```bash
curl -X POST http://localhost:3000/api/v1/scan-sessions/<id>/items \
  -d '{"ean":"8901234567890","scannedAt":"2024-01-01T10:00:00Z"}'
```

**Expected Response**:
```json
{
  "scanItem": {...},
  "product": {...},
  "eanValidation": {"matched": true},
  "expiryStatus": "unknown",
  "isDuplicate": false,
  "warnings": []
}
```

**Pass Criteria**: ✅ Scan recorded with full enrichment

---

### Test 4: EAN Match Status ✅

Scan EAN in active list:
**Expected**: `eanMatchStatus: "matched"`

Scan EAN NOT in list:
**Expected**: `eanMatchStatus: "unmatched"`, warning generated

**Pass Criteria**: ✅ EAN validation integrated

---

### Test 5: Expiry Status Calculation ✅

| Days until expiry | Expected status |
|---|---|
| 60 days | green |
| 20 days | yellow |
| 5 days | red |
| -1 day | red |
| not provided | unknown |

**Pass Criteria**: ✅ All cases handled correctly

---

### Test 6: Duplicate Detection ✅

Scan same EAN twice in same session:
**Expected**: Second scan has `isDuplicate: true`
**Pass Criteria**: ✅ Duplicates flagged but recorded

---

### Test 7: Session Stats Auto-Update ✅

After scanning 10 items (5 matched, 3 unmatched, 2 expired):
```bash
curl http://localhost:3000/api/v1/scan-sessions/<id>
```

**Expected**:
- totalScans: 10
- matchedEans: 5
- unmatchedEans: 3
- expiredItems: 2

**Pass Criteria**: ✅ Stats accurate

---

### Test 8: End Session ✅

```bash
curl -X POST http://localhost:3000/api/v1/scan-sessions/<id>/end \
  -d '{"notes":"Audit complete"}'
```

**Expected**: 
- Status → completed
- endedAt set
- durationSeconds calculated
- Audit log entry created

**Pass Criteria**: ✅ Session ends cleanly

---

### Test 9: Cannot Scan into Closed Session ✅

Try to scan into a completed session:
**Expected**: 422 with SCAN_SESSION_CLOSED
**Pass Criteria**: ✅ State enforced

---

### Test 10: Session Summary ✅

```bash
curl http://localhost:3000/api/v1/scan-sessions/<id>/summary
```

**Expected**: Detailed stats including scanRate (scans/min)
**Pass Criteria**: ✅ Summary accurate

---

### Test 11: Batch Scanning ✅

```bash
curl -X POST .../scan-sessions/<id>/items/batch \
  -d '{"items":[{"ean":"...","scannedAt":"..."}, ...]}'
```

**Expected**: All items recorded, results returned
**Pass Criteria**: ✅ Batch works, partial failures handled

---

### Test 12: Cross-User Session Access ✅

User A tries to scan into User B's session:
**Expected**: 403
**Pass Criteria**: ✅ Session ownership enforced

---

### Test 13: Cross-Tenant Isolation ✅

Tenant A user tries to scan Tenant B session:
**Expected**: 404 (TenantScopedRepository blocks)
**Pass Criteria**: ✅ Multi-tenancy enforced

---

### Test 14: Performance — 100 Scans ✅

```bash
time # ... 100 scans in succession
```

**Expected**: < 30 seconds total (300ms per scan)
**Pass Criteria**: ✅ Performance acceptable

---

### Test 15: Audit Log ✅

After scan operations, check:
```sql
SELECT * FROM audit_logs WHERE resource_type = 'ScanSession';
```

**Expected**: All session lifecycle events logged
**Pass Criteria**: ✅ Comprehensive audit trail

---

## 🎯 Q&A Session

### Q1: Why one active session per user/store?

**Expected Answer**:
- Prevents data confusion (which session is the scan in?)
- Simpler UX (resume vs start new)
- Better audit trail
- Real-world workflow (one auditor doing one task at a time)
- Allows abandoning before starting new

---

### Q2: Why denormalize stats on session?

**Expected Answer**:
- Performance: Don't query items table every time
- Real-time UI updates (mobile shows running counts)
- Reports faster (no aggregation needed)
- Trade-off: Stats can drift if not careful
- Mitigation: Refresh on session end

---

### Q3: Why product name snapshot?

**Expected Answer**:
- Products can be renamed (BE-10 update)
- Audit needs original name at scan time
- Reports need historical accuracy
- Compliance: "What was scanned" must be preserved
- Trade-off: Storage vs immutability

---

### Q4: How does duplicate detection work?

**Expected Answer**:
- Within session: Same EAN + same batch
- Different batches OK (legitimate)
- Different shelf locations OK
- Configurable per session type
- Warning, not error (user decides)

---

### Q5: Why support batch scanning?

**Expected Answer**:
- Mobile may queue scans when offline
- Sync all at once when online
- Faster than individual API calls
- Better UX (no waiting between scans)
- Atomic from user perspective

---

### Q6: How are auto-expired sessions handled?

**Expected Answer**:
- Cron job (BE-24) checks daily
- Active sessions with no activity > 4 hours
- Auto-marked as 'expired'
- Stats finalized
- User sees in history
- Cannot resume (must start new)

---

### Q7: Why optional EAN list validation?

**Expected Answer**:
- Not all stores have approved lists
- Some scans are for general inventory
- Training mode shouldn't validate
- Configurable per session type
- Defaults to validate if active list exists

---

### Q8: What's the scan flow on mobile?

**Expected Answer**:
1. User opens scanner
2. Mobile creates session (POST /scan-sessions)
3. ML Kit scans EAN
4. Mobile calls product lookup
5. Mobile calls scan record (with optional expiry/batch)
6. Server validates against EAN list
7. Server returns enriched scan + warnings
8. Mobile shows result, allows next scan
9. User ends session when done

---

## 📝 Sign-Off Checklist

### Functional
- [ ] Session creation works
- [ ] One active session enforcement
- [ ] Scan recording with full enrichment
- [ ] EAN validation integrated
- [ ] Expiry status calculation
- [ ] Duplicate detection
- [ ] Stats auto-update
- [ ] Session end works
- [ ] Batch scanning works

### Code Quality
- [ ] Service interfaces complete
- [ ] All DTOs have Zod schemas
- [ ] Transaction safety
- [ ] Tenant scoping enforced

### Performance
- [ ] Single scan < 300ms
- [ ] Batch of 100 < 30s
- [ ] Stats query < 50ms

### Tests
- [ ] All 15 tests pass
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-17**
**☐ CHANGES REQUESTED**

---

**END OF BE-16 — DO NOT PROCEED WITHOUT APPROVAL**
