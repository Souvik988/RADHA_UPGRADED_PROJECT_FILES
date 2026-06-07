# Phase BE-18: Expiry Tracking & Alerts

## Phase Metadata

- **Phase ID**: BE-18
- **Phase Name**: Expiry Tracking & Alerts
- **Section**: Backend Execution — Audit & Compliance Layer
- **Depends On**: BE-01 to BE-17
- **Blocks**: BE-19 (tasks), BE-24 (notifications), BE-26 (GRN)
- **Estimated Duration**: 2-3 days
- **Complexity**: Medium-High
- **Priority**: HIGH (key differentiator)

## Goal

Build comprehensive expiry tracking system: per-category expiry thresholds, real-time status calculation (green/yellow/red), expiry records linked to scans/GRN, near-expiry alert generation, expiry forecasting, batch-aware tracking, OCR-extracted date validation, and expiry dashboard data.

## Why This Phase Matters

Expiry tracking is RADHA's **core retail value proposition**:
- Pharmacies: legal liability for expired meds
- Grocery: 8-15% revenue loss from expired stock
- School canteens: child safety regulations
- Reduces waste, increases compliance
- Key differentiator from generic POS systems

Without proper expiry tracking:
- Manual expiry checks fail (human error)
- Expired products on shelf = lawsuits
- No data for vendor accountability
- Cannot suggest discounts proactively

## Prerequisites

- [ ] BE-01 to BE-17 completed
- [ ] Scan items have expiry data (BE-16)
- [ ] Health scoring works (BE-12)
- [ ] Product catalog exists (BE-10)

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/expiry_records.ts` | Expiry tracking |
| `server/src/db/schema/expiry_thresholds.ts` | Category thresholds |
| `server/src/db/schema/expiry_alerts.ts` | Active alerts |
| `server/src/modules/expiry/expiry.module.ts` | Module |
| `server/src/modules/expiry/expiry.controller.ts` | Endpoints |
| `server/src/modules/expiry/expiry.service.ts` | Business logic |
| `server/src/modules/expiry/services/expiry-calculator.service.ts` | Status calc |
| `server/src/modules/expiry/services/expiry-threshold.service.ts` | Threshold mgmt |
| `server/src/modules/expiry/services/expiry-forecast.service.ts` | Forecasting |
| `server/src/modules/expiry/services/expiry-alert.service.ts` | Alert generation |
| `server/src/modules/expiry/services/ocr-date-validator.service.ts` | OCR date validation |
| `server/src/modules/expiry/repositories/expiry-records.repository.ts` | Records |
| `server/src/modules/expiry/repositories/expiry-thresholds.repository.ts` | Thresholds |
| `server/src/modules/expiry/repositories/expiry-alerts.repository.ts` | Alerts |
| `server/src/modules/expiry/dto/create-expiry-record.dto.ts` | DTOs |
| `server/src/modules/expiry/dto/expiry-query.dto.ts` | DTOs |
| `server/src/modules/expiry/types/expiry.types.ts` | Types |
| `server/src/modules/expiry/utils/expiry-rules.utils.ts` | Calculation rules |
| `server/src/modules/expiry/constants/default-thresholds.ts` | Default values |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/expiry/expiry.service.ts

export interface IExpiryService {
  // Records
  createRecord(dto: CreateExpiryRecordDto, userId: string): Promise<ExpiryRecord>;
  findRecord(id: string): Promise<ExpiryRecord | null>;
  
  // Queries
  findByProduct(productId: string, storeId: string): Promise<ExpiryRecord[]>;
  findByStore(storeId: string, filters: ExpiryFilters): Promise<PaginatedResult<ExpiryRecord>>;
  findNearExpiry(storeId: string, daysAhead: number): Promise<ExpiryRecord[]>;
  findExpired(storeId: string): Promise<ExpiryRecord[]>;
  
  // Aggregations
  getStoreStats(storeId: string): Promise<ExpiryStats>;
  getCategoryStats(storeId: string): Promise<CategoryExpiryStats[]>;
  
  // Thresholds
  getThreshold(category: string, tenantId: string): Promise<ExpiryThreshold>;
  setThreshold(dto: SetThresholdDto, userId: string): Promise<ExpiryThreshold>;
  
  // Forecast
  forecast(storeId: string, daysAhead: number): Promise<ExpiryForecast>;
  
  // Alerts
  getActiveAlerts(storeId: string): Promise<ExpiryAlert[]>;
  acknowledgeAlert(alertId: string, userId: string): Promise<void>;
  
  // Recalculate (when thresholds change)
  recalculateForStore(storeId: string): Promise<RecalculationResult>;
}

export interface IExpiryCalculator {
  calculateStatus(
    expiryDate: Date,
    threshold: ExpiryThreshold,
    referenceDate?: Date,
  ): ExpiryStatus;
  
  daysUntilExpiry(expiryDate: Date, referenceDate?: Date): number;
  
  isExpired(expiryDate: Date, referenceDate?: Date): boolean;
  
  getStatusColor(status: ExpiryStatus): 'green' | 'yellow' | 'red' | 'gray';
}

export interface IExpiryAlertService {
  // Generate alerts based on current state
  generateAlertsForStore(storeId: string): Promise<ExpiryAlert[]>;
  
  // Mark alert as acknowledged
  acknowledge(alertId: string, userId: string, notes?: string): Promise<void>;
  
  // Mark resolved (item removed/sold/discounted)
  resolve(alertId: string, userId: string, resolution: AlertResolution): Promise<void>;
  
  // Cleanup old alerts
  cleanupOldAlerts(daysOld: number): Promise<number>;
}

export type ExpiryStatus = 'green' | 'yellow' | 'red' | 'expired' | 'unknown';

export interface ExpiryThreshold {
  category: string;
  tenantId?: string; // Tenant-specific override
  yellowDays: number; // Days before yellow status
  redDays: number;    // Days before red status
  isDefault: boolean;
}

export interface CreateExpiryRecordDto {
  productId: string;
  storeId: string;
  expiryDate: Date;
  manufactureDate?: Date;
  batchNumber?: string;
  quantity: number;
  source: 'scan' | 'grn' | 'manual' | 'ocr';
  sourceId?: string; // scanItemId, grnItemId, etc.
  shelfLocation?: string;
  notes?: string;
}

export interface ExpiryFilters {
  status?: ExpiryStatus[];
  category?: string;
  productId?: string;
  fromDate?: Date;
  toDate?: Date;
  daysAhead?: number;
  cursor?: string;
  limit?: number;
}

export interface ExpiryStats {
  storeId: string;
  total: number;
  green: number;
  yellow: number;
  red: number;
  expired: number;
  byCategory: Record<string, { green: number; yellow: number; red: number }>;
  totalValue?: number; // If product cost data available
  potentialLoss?: number;
}

export interface CategoryExpiryStats {
  category: string;
  green: number;
  yellow: number;
  red: number;
  expired: number;
  averageDaysRemaining: number;
}

export interface ExpiryForecast {
  storeId: string;
  daysAhead: number;
  forecast: Array<{
    date: Date;
    expiringCount: number;
    expiringProducts: Array<{ productId: string; productName: string; quantity: number }>;
  }>;
}

export interface ExpiryAlert {
  id: string;
  storeId: string;
  productId: string;
  productName: string;
  expiryRecordId: string;
  status: ExpiryStatus;
  daysRemaining: number;
  quantity: number;
  shelfLocation?: string;
  isAcknowledged: boolean;
  acknowledgedBy?: string;
  acknowledgedAt?: Date;
  isResolved: boolean;
  resolvedAt?: Date;
  resolution?: string;
  createdAt: Date;
}

export type AlertResolution =
  | 'discounted'
  | 'sold'
  | 'removed'
  | 'returned'
  | 'donated'
  | 'discarded';
```

## Implementation Code

### 1. Expiry Records Schema

```typescript
// server/src/db/schema/expiry_records.ts
import { pgTable, varchar, uuid, integer, timestamp, jsonb, pgEnum, decimal, index } from 'drizzle-orm/pg-core';
import { baseColumns, softDeleteColumn, auditColumns } from './_base';

export const expiryStatusEnum = pgEnum('expiry_record_status', [
  'green',
  'yellow',
  'red',
  'expired',
  'unknown',
]);

export const expirySourceEnum = pgEnum('expiry_source', [
  'scan',
  'grn',
  'manual',
  'ocr',
]);

export const expiryRecords = pgTable(
  'expiry_records',
  {
    ...baseColumns,
    ...softDeleteColumn,
    ...auditColumns,
    tenantId: uuid('tenant_id').notNull(),
    storeId: uuid('store_id').notNull(),
    productId: uuid('product_id').notNull(),
    
    // Dates
    expiryDate: timestamp('expiry_date', { withTimezone: true }).notNull(),
    manufactureDate: timestamp('manufacture_date', { withTimezone: true }),
    
    // Identity
    batchNumber: varchar('batch_number', { length: 100 }),
    
    // Quantity
    quantity: integer('quantity').notNull().default(1),
    remainingQuantity: integer('remaining_quantity').notNull(),
    
    // Status (denormalized for performance)
    status: expiryStatusEnum('status').notNull().default('unknown'),
    daysRemaining: integer('days_remaining'),
    lastStatusUpdate: timestamp('last_status_update', { withTimezone: true }).defaultNow(),
    
    // Source
    source: expirySourceEnum('source').notNull(),
    sourceId: uuid('source_id'),
    
    // Context
    shelfLocation: varchar('shelf_location', { length: 100 }),
    notes: varchar('notes', { length: 500 }),
    
    // Resolution
    resolvedAt: timestamp('resolved_at', { withTimezone: true }),
    resolutionType: varchar('resolution_type', { length: 50 }),
    resolutionNotes: varchar('resolution_notes', { length: 500 }),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    storeStatusDateIdx: index('idx_expiry_store_status_date').on(
      table.storeId,
      table.status,
      table.expiryDate,
    ),
    productStoreIdx: index('idx_expiry_product_store').on(table.productId, table.storeId),
    expiryDateIdx: index('idx_expiry_date').on(table.expiryDate),
    batchIdx: index('idx_expiry_batch').on(table.batchNumber),
  }),
);

export type ExpiryRecord = typeof expiryRecords.$inferSelect;
export type NewExpiryRecord = typeof expiryRecords.$inferInsert;
```

### 2. Expiry Thresholds Schema

```typescript
// server/src/db/schema/expiry_thresholds.ts
import { pgTable, varchar, uuid, integer, jsonb, index, unique } from 'drizzle-orm/pg-core';
import { baseColumns, auditColumns } from './_base';

export const expiryThresholds = pgTable(
  'expiry_thresholds',
  {
    ...baseColumns,
    ...auditColumns,
    tenantId: uuid('tenant_id'), // null for default/global
    
    category: varchar('category', { length: 100 }).notNull(),
    yellowDays: integer('yellow_days').notNull().default(30),
    redDays: integer('red_days').notNull().default(7),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    tenantCategoryIdx: unique('uniq_thresholds_tenant_category').on(
      table.tenantId,
      table.category,
    ),
    categoryIdx: index('idx_thresholds_category').on(table.category),
  }),
);

export type ExpiryThreshold = typeof expiryThresholds.$inferSelect;
```

### 3. Expiry Alerts Schema

```typescript
// server/src/db/schema/expiry_alerts.ts
import { pgTable, varchar, uuid, integer, timestamp, boolean, jsonb, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const expiryAlerts = pgTable(
  'expiry_alerts',
  {
    ...baseColumns,
    tenantId: uuid('tenant_id').notNull(),
    storeId: uuid('store_id').notNull(),
    expiryRecordId: uuid('expiry_record_id').notNull(),
    productId: uuid('product_id').notNull(),
    
    status: varchar('status', { length: 20 }).notNull(), // yellow or red
    daysRemaining: integer('days_remaining'),
    quantity: integer('quantity').notNull(),
    
    isAcknowledged: boolean('is_acknowledged').notNull().default(false),
    acknowledgedBy: uuid('acknowledged_by'),
    acknowledgedAt: timestamp('acknowledged_at', { withTimezone: true }),
    acknowledgedNotes: varchar('acknowledged_notes', { length: 500 }),
    
    isResolved: boolean('is_resolved').notNull().default(false),
    resolvedBy: uuid('resolved_by'),
    resolvedAt: timestamp('resolved_at', { withTimezone: true }),
    resolution: varchar('resolution', { length: 50 }),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    storeActiveIdx: index('idx_alerts_store_active').on(
      table.storeId,
      table.isAcknowledged,
      table.isResolved,
    ),
    statusIdx: index('idx_alerts_status').on(table.status),
    expiryRecordIdx: index('idx_alerts_expiry_record').on(table.expiryRecordId),
  }),
);

export type ExpiryAlert = typeof expiryAlerts.$inferSelect;
```

### 4. Default Thresholds

```typescript
// server/src/modules/expiry/constants/default-thresholds.ts

export const DEFAULT_EXPIRY_THRESHOLDS: Array<{
  category: string;
  yellowDays: number;
  redDays: number;
  description: string;
}> = [
  {
    category: 'dairy',
    yellowDays: 7,
    redDays: 2,
    description: 'Milk, yogurt, cheese — short shelf life',
  },
  {
    category: 'meat-seafood',
    yellowDays: 5,
    redDays: 1,
    description: 'Fresh meat, seafood — very short shelf life',
  },
  {
    category: 'bakery',
    yellowDays: 7,
    redDays: 2,
    description: 'Bread, pastries — short shelf life',
  },
  {
    category: 'fruits-vegetables',
    yellowDays: 5,
    redDays: 1,
    description: 'Fresh produce — perishable',
  },
  {
    category: 'frozen',
    yellowDays: 30,
    redDays: 7,
    description: 'Frozen foods',
  },
  {
    category: 'snacks',
    yellowDays: 30,
    redDays: 7,
    description: 'Chips, biscuits, etc.',
  },
  {
    category: 'beverages',
    yellowDays: 60,
    redDays: 14,
    description: 'Soft drinks, juices',
  },
  {
    category: 'medicine',
    yellowDays: 90,
    redDays: 30,
    description: 'Pharmaceuticals — strict regulations',
  },
  {
    category: 'cosmetics',
    yellowDays: 60,
    redDays: 14,
    description: 'Personal care products',
  },
  {
    category: 'household',
    yellowDays: 180,
    redDays: 30,
    description: 'Cleaning supplies',
  },
  {
    category: 'baby',
    yellowDays: 30,
    redDays: 7,
    description: 'Baby food, diapers',
  },
  {
    category: 'pet',
    yellowDays: 60,
    redDays: 14,
    description: 'Pet food and supplies',
  },
  {
    category: 'other',
    yellowDays: 30,
    redDays: 7,
    description: 'Default for uncategorized',
  },
];
```

### 5. Expiry Calculator

```typescript
// server/src/modules/expiry/services/expiry-calculator.service.ts
import { Injectable } from '@nestjs/common';
import {
  IExpiryCalculator,
  ExpiryStatus,
  ExpiryThreshold,
} from '../types/expiry.types';

@Injectable()
export class ExpiryCalculatorService implements IExpiryCalculator {
  
  calculateStatus(
    expiryDate: Date,
    threshold: ExpiryThreshold,
    referenceDate: Date = new Date(),
  ): ExpiryStatus {
    if (!expiryDate) return 'unknown';
    
    const days = this.daysUntilExpiry(expiryDate, referenceDate);
    
    if (days < 0) return 'expired';
    if (days <= threshold.redDays) return 'red';
    if (days <= threshold.yellowDays) return 'yellow';
    return 'green';
  }
  
  daysUntilExpiry(expiryDate: Date, referenceDate: Date = new Date()): number {
    const expiryTime = new Date(expiryDate).getTime();
    const refTime = referenceDate.getTime();
    const diffMs = expiryTime - refTime;
    return Math.floor(diffMs / (1000 * 60 * 60 * 24));
  }
  
  isExpired(expiryDate: Date, referenceDate: Date = new Date()): boolean {
    return this.daysUntilExpiry(expiryDate, referenceDate) < 0;
  }
  
  getStatusColor(status: ExpiryStatus): 'green' | 'yellow' | 'red' | 'gray' {
    if (status === 'green') return 'green';
    if (status === 'yellow') return 'yellow';
    if (status === 'red' || status === 'expired') return 'red';
    return 'gray';
  }
}
```

### 6. Expiry Service (Main)

```typescript
// server/src/modules/expiry/expiry.service.ts
import { Injectable } from '@nestjs/common';
import { ExpiryRecordsRepository } from './repositories/expiry-records.repository';
import { ExpiryThresholdsRepository } from './repositories/expiry-thresholds.repository';
import { ExpiryAlertsRepository } from './repositories/expiry-alerts.repository';
import { ExpiryCalculatorService } from './services/expiry-calculator.service';
import { ExpiryAlertService } from './services/expiry-alert.service';
import { ProductsRepository } from '../products/products.repository';
import { DbService } from '../../db/db.service';
import { LoggerService } from '../../logging/logger.service';
import {
  IExpiryService,
  CreateExpiryRecordDto,
  ExpiryFilters,
  ExpiryStats,
  ExpiryStatus,
  ExpiryThreshold,
} from './types/expiry.types';
import { NotFoundException } from '../../common/errors/business.exception';

@Injectable()
export class ExpiryService implements IExpiryService {
  constructor(
    private readonly db: DbService,
    private readonly recordsRepo: ExpiryRecordsRepository,
    private readonly thresholdsRepo: ExpiryThresholdsRepository,
    private readonly alertsRepo: ExpiryAlertsRepository,
    private readonly calculator: ExpiryCalculatorService,
    private readonly alertService: ExpiryAlertService,
    private readonly productsRepo: ProductsRepository,
    private readonly logger: LoggerService,
  ) {}

  async createRecord(
    dto: CreateExpiryRecordDto,
    userId: string,
  ): Promise<ExpiryRecord> {
    // Get product to determine category
    const product = await this.productsRepo.findById(dto.productId);
    if (!product) throw new NotFoundException('Product', dto.productId);
    
    // Get threshold for category
    const threshold = await this.getThreshold(
      product.subCategory || 'other',
      product.tenantId,
    );
    
    // Calculate status
    const status = this.calculator.calculateStatus(dto.expiryDate, threshold);
    const daysRemaining = this.calculator.daysUntilExpiry(dto.expiryDate);
    
    // Create record in transaction
    return this.db.transaction(async (tx) => {
      const record = await this.recordsRepo.create({
        storeId: dto.storeId,
        productId: dto.productId,
        expiryDate: dto.expiryDate,
        manufactureDate: dto.manufactureDate,
        batchNumber: dto.batchNumber,
        quantity: dto.quantity,
        remainingQuantity: dto.quantity,
        status,
        daysRemaining,
        source: dto.source,
        sourceId: dto.sourceId,
        shelfLocation: dto.shelfLocation,
        notes: dto.notes,
      }, tx);
      
      // Generate alert if needed
      if (status === 'yellow' || status === 'red' || status === 'expired') {
        await this.alertService.createAlert({
          expiryRecordId: record.id,
          storeId: record.storeId,
          productId: record.productId,
          status: status === 'expired' ? 'red' : status,
          daysRemaining,
          quantity: dto.quantity,
        }, tx);
      }
      
      return record;
    });
  }

  async findRecord(id: string): Promise<ExpiryRecord | null> {
    return this.recordsRepo.findById(id);
  }

  async findByProduct(productId: string, storeId: string): Promise<ExpiryRecord[]> {
    return this.recordsRepo.findMany({ productId, storeId });
  }

  async findByStore(
    storeId: string,
    filters: ExpiryFilters,
  ): Promise<PaginatedResult<ExpiryRecord>> {
    return this.recordsRepo.findPaginated(
      { storeId, ...(filters.status && { status: filters.status }) },
      {
        cursor: filters.cursor,
        limit: filters.limit || 50,
        orderBy: [{ field: 'expiryDate', direction: 'asc' }],
      },
    );
  }

  async findNearExpiry(storeId: string, daysAhead: number): Promise<ExpiryRecord[]> {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() + daysAhead);
    
    return this.recordsRepo.findNearExpiry(storeId, cutoffDate);
  }

  async findExpired(storeId: string): Promise<ExpiryRecord[]> {
    return this.recordsRepo.findMany({ storeId, status: 'expired' });
  }

  async getStoreStats(storeId: string): Promise<ExpiryStats> {
    const stats = await this.recordsRepo.getStatsForStore(storeId);
    return stats;
  }

  async getCategoryStats(storeId: string): Promise<CategoryExpiryStats[]> {
    return this.recordsRepo.getStatsByCategory(storeId);
  }

  async getThreshold(category: string, tenantId: string): Promise<ExpiryThreshold> {
    // First try tenant-specific
    const tenantSpecific = await this.thresholdsRepo.findByCategory(category, tenantId);
    if (tenantSpecific) return tenantSpecific;
    
    // Fall back to global default
    const global = await this.thresholdsRepo.findByCategory(category, null);
    if (global) return global;
    
    // Final fallback: hardcoded defaults
    return {
      category,
      yellowDays: 30,
      redDays: 7,
      isDefault: true,
    } as ExpiryThreshold;
  }

  async setThreshold(dto: any, userId: string): Promise<ExpiryThreshold> {
    return this.thresholdsRepo.upsert(dto);
  }

  async forecast(storeId: string, daysAhead: number): Promise<any> {
    return this.recordsRepo.getForecast(storeId, daysAhead);
  }

  async getActiveAlerts(storeId: string): Promise<ExpiryAlert[]> {
    return this.alertsRepo.findActive(storeId);
  }

  async acknowledgeAlert(alertId: string, userId: string): Promise<void> {
    await this.alertService.acknowledge(alertId, userId);
  }

  async recalculateForStore(storeId: string): Promise<RecalculationResult> {
    const records = await this.recordsRepo.findMany({ storeId });
    let updated = 0;
    
    for (const record of records) {
      const product = await this.productsRepo.findById(record.productId);
      if (!product) continue;
      
      const threshold = await this.getThreshold(
        product.subCategory || 'other',
        product.tenantId,
      );
      
      const newStatus = this.calculator.calculateStatus(record.expiryDate, threshold);
      const newDaysRemaining = this.calculator.daysUntilExpiry(record.expiryDate);
      
      if (newStatus !== record.status || newDaysRemaining !== record.daysRemaining) {
        await this.recordsRepo.update(record.id, {
          status: newStatus,
          daysRemaining: newDaysRemaining,
          lastStatusUpdate: new Date(),
        });
        updated++;
      }
    }
    
    return { totalRecords: records.length, updated };
  }
}
```

### 7. OCR Date Validator

```typescript
// server/src/modules/expiry/services/ocr-date-validator.service.ts
import { Injectable } from '@nestjs/common';

@Injectable()
export class OcrDateValidatorService {
  
  validateExtractedDate(
    extractedText: string,
    confidenceScore: number,
  ): { valid: boolean; date?: Date; format?: string; warning?: string } {
    // Try multiple date formats
    const formats = [
      { regex: /(\d{2})[\/-](\d{2})[\/-](\d{4})/, format: 'DD/MM/YYYY' },
      { regex: /(\d{2})[\/-](\d{4})/, format: 'MM/YYYY' },
      { regex: /(\d{4})[\/-](\d{2})[\/-](\d{2})/, format: 'YYYY/MM/DD' },
      { regex: /(\d{2})[\.\s](\d{2})[\.\s](\d{4})/, format: 'DD MM YYYY' },
    ];
    
    for (const { regex, format } of formats) {
      const match = extractedText.match(regex);
      if (!match) continue;
      
      const date = this.parseMatch(match, format);
      if (!date) continue;
      
      // Sanity checks
      const now = new Date();
      const tenYearsAgo = new Date();
      tenYearsAgo.setFullYear(tenYearsAgo.getFullYear() - 10);
      
      const tenYearsFuture = new Date();
      tenYearsFuture.setFullYear(tenYearsFuture.getFullYear() + 10);
      
      if (date < tenYearsAgo) {
        return {
          valid: false,
          date,
          format,
          warning: 'Date is more than 10 years in the past',
        };
      }
      
      if (date > tenYearsFuture) {
        return {
          valid: false,
          date,
          format,
          warning: 'Date is more than 10 years in the future',
        };
      }
      
      // Low confidence warning
      const warning = confidenceScore < 0.7
        ? 'Low OCR confidence - please verify date manually'
        : undefined;
      
      return { valid: true, date, format, warning };
    }
    
    return { valid: false, warning: 'No date pattern detected' };
  }
  
  private parseMatch(match: RegExpMatchArray, format: string): Date | null {
    try {
      switch (format) {
        case 'DD/MM/YYYY':
        case 'DD MM YYYY':
          return new Date(`${match[3]}-${match[2]}-${match[1]}`);
        case 'MM/YYYY':
          // Last day of month
          return new Date(parseInt(match[2]), parseInt(match[1]), 0);
        case 'YYYY/MM/DD':
          return new Date(`${match[1]}-${match[2]}-${match[3]}`);
        default:
          return null;
      }
    } catch {
      return null;
    }
  }
}
```

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| POST | `/api/v1/expiry-records` | Bearer | Create expiry record |
| GET | `/api/v1/expiry-records` | Bearer | List with filters |
| GET | `/api/v1/expiry-records/:id` | Bearer | Get single |
| GET | `/api/v1/expiry-records/near-expiry` | Bearer | Near expiry |
| GET | `/api/v1/expiry-records/expired` | Bearer | Expired items |
| GET | `/api/v1/expiry-records/forecast` | Bearer | Forecast |
| GET | `/api/v1/expiry-records/stats` | Bearer | Store stats |
| GET | `/api/v1/expiry-records/stats/by-category` | Bearer | Category stats |
| GET | `/api/v1/expiry-thresholds` | Bearer | List thresholds |
| PUT | `/api/v1/expiry-thresholds` | Bearer | Set threshold |
| POST | `/api/v1/expiry-records/recalculate` | Bearer | Recalc all |
| GET | `/api/v1/expiry-alerts` | Bearer | Active alerts |
| POST | `/api/v1/expiry-alerts/:id/acknowledge` | Bearer | Ack alert |
| POST | `/api/v1/expiry-alerts/:id/resolve` | Bearer | Resolve alert |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-19 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Status Calculation ✅

```typescript
const today = new Date('2024-06-01');
const inFiveDays = new Date('2024-06-06');
const inTwentyDays = new Date('2024-06-21');
const expired = new Date('2024-05-25');

// Default threshold: yellow=30, red=7
expect(calculator.calculateStatus(inFiveDays, threshold, today)).toBe('red');
expect(calculator.calculateStatus(inTwentyDays, threshold, today)).toBe('yellow');
expect(calculator.calculateStatus(expired, threshold, today)).toBe('expired');
```

**Pass Criteria**: ✅ All status transitions correct

---

### Test 2: Create Expiry Record ✅

```bash
curl -X POST http://localhost:3000/api/v1/expiry-records \
  -d '{
    "productId":"<id>",
    "storeId":"<id>",
    "expiryDate":"2024-12-31",
    "batchNumber":"BATCH001",
    "quantity":50,
    "source":"scan"
  }'
```

**Expected**: Record created, status calculated automatically
**Pass Criteria**: ✅ Creation works

---

### Test 3: Auto-Alert Generation ✅

Create record with expiry < threshold:
**Expected**: Alert auto-generated in same transaction
**Pass Criteria**: ✅ Alerts generated automatically

---

### Test 4: Category-Specific Thresholds ✅

Test dairy (yellow=7, red=2) vs frozen (yellow=30, red=7):
- Same expiry date, different categories
- Different statuses

**Pass Criteria**: ✅ Category awareness works

---

### Test 5: Near Expiry Query ✅

```bash
curl ".../expiry-records/near-expiry?daysAhead=30&storeId=<id>"
```

**Expected**: Returns yellow + red items expiring within 30 days
**Pass Criteria**: ✅ Filter works

---

### Test 6: Store Stats ✅

```bash
curl ".../expiry-records/stats?storeId=<id>"
```

**Expected**:
```json
{
  "total": 500,
  "green": 300,
  "yellow": 150,
  "red": 50,
  "expired": 0,
  "byCategory": {...}
}
```

**Pass Criteria**: ✅ Stats accurate

---

### Test 7: Forecast ✅

```bash
curl ".../expiry-records/forecast?daysAhead=30&storeId=<id>"
```

**Expected**: Day-by-day count of items expiring
**Pass Criteria**: ✅ Forecast accurate

---

### Test 8: Tenant Threshold Override ✅

Tenant sets custom threshold for dairy (yellow=14):
**Expected**: Tenant's records use 14 days, not default 7
**Pass Criteria**: ✅ Override works

---

### Test 9: Acknowledge Alert ✅

```bash
curl -X POST .../expiry-alerts/<id>/acknowledge \
  -d '{"notes":"Will discount today"}'
```

**Expected**: Alert marked acknowledged but not resolved
**Pass Criteria**: ✅ Acknowledgment tracked

---

### Test 10: Resolve Alert ✅

```bash
curl -X POST .../expiry-alerts/<id>/resolve \
  -d '{"resolution":"discounted"}'
```

**Expected**: Alert resolved, removed from active list
**Pass Criteria**: ✅ Resolution works

---

### Test 11: OCR Date Validation ✅

```typescript
const result = validator.validateExtractedDate('EXP: 31/12/2024', 0.85);
expect(result.valid).toBe(true);
expect(result.date).toEqual(new Date('2024-12-31'));
```

**Pass Criteria**: ✅ OCR dates parsed correctly

---

### Test 12: Future Date Sanity ✅

```typescript
const result = validator.validateExtractedDate('EXP: 31/12/2099', 0.9);
expect(result.warning).toContain('10 years');
```

**Pass Criteria**: ✅ Sanity checks catch bad OCR

---

### Test 13: Recalculate ✅

Change tenant threshold, recalculate:
**Expected**: All records updated with new statuses
**Pass Criteria**: ✅ Bulk recalc works

---

### Test 14: Performance ✅

10K expiry records query for store:
```bash
time curl ".../expiry-records?storeId=<id>"
```

**Expected**: < 200ms with proper indexes
**Pass Criteria**: ✅ Indexes used

---

### Test 15: Daily Status Update ✅

Cron job (BE-24 will run daily) marks status changes:
**Expected**: Today's "yellow" becomes "red" tomorrow
**Pass Criteria**: ✅ Daily updates work

---

## 🎯 Q&A Session

### Q1: Why category-specific thresholds?

**Expected Answer**:
- Dairy expires in days, frozen in months
- Same threshold doesn't fit all
- Industry standard practice
- Configurable per tenant
- Better alert relevance

---

### Q2: Why denormalize status on record?

**Expected Answer**:
- Fast queries (no calculation needed)
- Indexed for filtering
- Cron job updates daily
- Real-time status on read also works
- Trade-off: Stale until cron runs

---

### Q3: Why separate alerts table?

**Expected Answer**:
- Different lifecycle (acknowledge, resolve)
- Multiple users can interact
- Audit trail of decisions
- Notifications reference (BE-24)
- Reports use alert data

---

### Q4: How does cron update statuses?

**Expected Answer**:
- BE-24 will add daily cron job
- Runs at midnight in store timezone
- Recalculates daysRemaining
- Updates status if changed
- Generates new alerts as needed
- Resolves alerts for items now expired

---

### Q5: Why support batch numbers?

**Expected Answer**:
- Same product, different batches, different expiry
- Pharmaceutical compliance requires batch
- Recalls based on batch (BE-26)
- Auditability
- Inventory tracking (BE-27)

---

### Q6: How would you handle vendor accountability?

**Expected Answer**:
- Track expiry at GRN time (BE-26)
- Calculate days remaining on receipt
- Link batch to vendor
- Aggregate metrics: "Vendor X delivers stock with avg 60 days remaining"
- Reports for negotiation
- Future: Vendor scorecard

---

### Q7: Why OCR date validation?

**Expected Answer**:
- OCR is error-prone (8 vs B, 0 vs O)
- Sanity checks prevent obvious errors
- Confidence score from ML Kit
- User confirms before saving
- Better UX than failing silently

---

### Q8: How to handle products without expiry?

**Expected Answer**:
- Status = 'unknown'
- Don't generate alerts
- Show in separate dashboard section
- Encourage user to add expiry on next scan
- Some products legitimately don't expire (batteries, toys)

---

## 📝 Sign-Off Checklist

### Functional
- [ ] Expiry records created
- [ ] Status calculation accurate
- [ ] Category thresholds work
- [ ] Tenant overrides work
- [ ] Auto-alerts generated
- [ ] Near-expiry query works
- [ ] Forecast accurate
- [ ] OCR date validation
- [ ] Acknowledge/resolve flow

### Performance
- [ ] 10K records query < 200ms
- [ ] Status calc < 1ms
- [ ] Stats query < 100ms

### Tests
- [ ] All 15 tests pass
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-19**
**☐ CHANGES REQUESTED**

---

**END OF BE-18 — DO NOT PROCEED WITHOUT APPROVAL**
