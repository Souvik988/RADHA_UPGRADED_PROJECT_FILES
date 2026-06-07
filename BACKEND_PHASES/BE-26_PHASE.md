# Phase BE-26: GRN (Goods Receipt Note) Module

## Phase Metadata

- **Phase ID**: BE-26
- **Phase Name**: GRN (Goods Receipt Note) Module
- **Section**: Backend Execution — Business Operations Layer
- **Depends On**: BE-01 to BE-25
- **Blocks**: BE-27 (inventory uses GRN postings)
- **Estimated Duration**: 3-4 days
- **Complexity**: High

## Goal

Build comprehensive GRN system: vendor inward tracking, line items with batch/expiry, draft/posted/cancelled workflow, transactional posting that updates inventory atomically, supplier performance metric updates, audit trail, and integration with expiry tracking (BE-18).

## Why This Phase Matters

GRN is the **inward gateway** for stock:
- Track WHO delivered (supplier accountability)
- Capture batch + expiry at receipt (compliance)
- Single source of truth for stock IN
- Vendor performance metrics (BE-25)
- Reduces manual data entry
- Audit trail for regulators

Without GRN:
- Stock arrives invisible to system
- No batch traceability for recalls
- Cannot hold suppliers accountable
- Manual inventory entry error-prone

## Prerequisites

- [ ] BE-01 to BE-25 completed
- [ ] Suppliers module (BE-25)
- [ ] Products catalog (BE-10)
- [ ] Expiry tracking (BE-18)
- [ ] Tasks module (BE-19)

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/grn_headers.ts` | GRN main record |
| `server/src/db/schema/grn_items.ts` | Line items |
| `server/src/db/schema/grn_events.ts` | Audit trail |
| `server/src/modules/grn/grn.module.ts` | Module |
| `server/src/modules/grn/grn.controller.ts` | Endpoints |
| `server/src/modules/grn/grn.service.ts` | Business logic |
| `server/src/modules/grn/services/grn-posting.service.ts` | Atomic posting |
| `server/src/modules/grn/services/grn-validation.service.ts` | Pre-post validation |
| `server/src/modules/grn/services/grn-reversal.service.ts` | Cancel posted GRN |
| `server/src/modules/grn/repositories/grn-headers.repository.ts` | Headers data |
| `server/src/modules/grn/repositories/grn-items.repository.ts` | Items data |
| `server/src/modules/grn/repositories/grn-events.repository.ts` | Events data |
| `server/src/modules/grn/dto/create-grn.dto.ts` | DTOs |
| `server/src/modules/grn/dto/grn-item.dto.ts` | DTOs |
| `server/src/modules/grn/dto/post-grn.dto.ts` | DTOs |
| `server/src/modules/grn/types/grn.types.ts` | Types |
| `server/src/modules/grn/utils/grn-number-generator.utils.ts` | Auto-numbering |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/grn/grn.service.ts

export interface IGrnService {
  // Draft management
  createDraft(dto: CreateGrnDto, userId: string): Promise<Grn>;
  updateDraft(id: string, dto: UpdateGrnDto, userId: string): Promise<Grn>;
  
  // Items
  addItems(grnId: string, items: GrnItemDto[], userId: string): Promise<GrnItem[]>;
  updateItem(itemId: string, dto: UpdateGrnItemDto, userId: string): Promise<GrnItem>;
  removeItem(itemId: string, userId: string): Promise<void>;
  
  // Workflow
  validate(id: string): Promise<ValidationResult>;
  post(id: string, userId: string): Promise<PostResult>;
  cancel(id: string, reason: string, userId: string): Promise<Grn>;
  reverse(id: string, reason: string, userId: string): Promise<ReverseResult>;
  
  // Queries
  findById(id: string): Promise<GrnWithDetails | null>;
  list(filters: ListGrnsDto): Promise<PaginatedResult<Grn>>;
  listForSupplier(supplierId: string, filters: any): Promise<PaginatedResult<Grn>>;
  
  // Stats
  getStats(filters: GrnStatsFilters): Promise<GrnStats>;
}

export type GrnStatus =
  | 'draft'
  | 'pending_review'
  | 'posted'
  | 'cancelled'
  | 'reversed';

export interface CreateGrnDto {
  supplierId: string;
  storeId: string;
  invoiceNumber: string;
  invoiceDate: Date;
  inwardDate: Date;
  
  // Optional
  poNumber?: string;
  expectedDeliveryDate?: Date;
  
  // Amounts (for tracking, not accounting)
  subtotal?: number;
  taxAmount?: number;
  totalAmount?: number;
  
  // Initial items
  items?: GrnItemDto[];
  
  notes?: string;
  metadata?: Record<string, unknown>;
}

export interface GrnItemDto {
  productId?: string;
  ean: string;
  productName?: string; // If not in catalog
  quantity: number;
  unit?: string;
  
  // Critical for compliance
  batchNumber?: string;
  manufactureDate?: Date;
  expiryDate?: Date;
  
  // Pricing
  unitPrice?: number;
  taxPercent?: number;
  
  notes?: string;
}

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
  warnings: ValidationWarning[];
}

export interface ValidationError {
  field: string;
  itemId?: string;
  message: string;
}

export interface ValidationWarning {
  type: 'short_shelf_life' | 'price_variance' | 'duplicate_batch' | 'unknown_product';
  message: string;
  itemId?: string;
}

export interface PostResult {
  grn: Grn;
  inventoryUpdates: InventoryUpdate[];
  expiryRecordsCreated: number;
  alertsGenerated: number;
}

export interface InventoryUpdate {
  productId: string;
  storeId: string;
  batchNumber?: string;
  quantityAdded: number;
  newTotal: number;
}

export interface ReverseResult {
  originalGrn: Grn;
  reversedAt: Date;
  inventoryReverted: number;
}

export interface GrnWithDetails extends Grn {
  supplier: Supplier;
  items: GrnItemWithProduct[];
  events: GrnEvent[];
}

export interface GrnItemWithProduct extends GrnItem {
  product?: Product;
  expiryStatus?: 'green' | 'yellow' | 'red' | 'expired';
}

export interface GrnStats {
  total: number;
  byStatus: Record<GrnStatus, number>;
  totalAmount: number;
  totalItems: number;
  averageDeliveryDays: number;
  shortShelfLifeCount: number;
  topSuppliers: Array<{ supplierId: string; name: string; grnCount: number; amount: number }>;
}
```

## Implementation Code

### 1. GRN Headers Schema

```typescript
// server/src/db/schema/grn_headers.ts
import { pgTable, varchar, uuid, integer, decimal, timestamp, jsonb, pgEnum, index, unique } from 'drizzle-orm/pg-core';
import { baseColumns, softDeleteColumn, auditColumns } from './_base';

export const grnStatusEnum = pgEnum('grn_status', [
  'draft',
  'pending_review',
  'posted',
  'cancelled',
  'reversed',
]);

export const grnHeaders = pgTable(
  'grn_headers',
  {
    ...baseColumns,
    ...softDeleteColumn,
    ...auditColumns,
    tenantId: uuid('tenant_id').notNull(),
    storeId: uuid('store_id').notNull(),
    
    // Identifier
    grnNumber: varchar('grn_number', { length: 50 }).notNull(),
    
    // Supplier
    supplierId: uuid('supplier_id').notNull(),
    
    // Invoice details
    invoiceNumber: varchar('invoice_number', { length: 100 }).notNull(),
    invoiceDate: timestamp('invoice_date', { withTimezone: true }).notNull(),
    poNumber: varchar('po_number', { length: 100 }),
    
    // Dates
    inwardDate: timestamp('inward_date', { withTimezone: true }).notNull(),
    expectedDeliveryDate: timestamp('expected_delivery_date', { withTimezone: true }),
    orderDate: timestamp('order_date', { withTimezone: true }),
    
    // Status
    status: grnStatusEnum('status').notNull().default('draft'),
    
    // Amounts (for vendor accountability, not accounting)
    subtotal: decimal('subtotal', { precision: 14, scale: 2 }),
    taxAmount: decimal('tax_amount', { precision: 14, scale: 2 }),
    totalAmount: decimal('total_amount', { precision: 14, scale: 2 }),
    
    // Stats
    totalItems: integer('total_items').notNull().default(0),
    totalQuantity: integer('total_quantity').notNull().default(0),
    minExpiryRemainingDays: integer('min_expiry_remaining_days'),
    shortShelfLifeCount: integer('short_shelf_life_count').notNull().default(0),
    
    // Posting
    postedAt: timestamp('posted_at', { withTimezone: true }),
    postedBy: uuid('posted_by'),
    
    // Cancellation
    cancelledAt: timestamp('cancelled_at', { withTimezone: true }),
    cancelledBy: uuid('cancelled_by'),
    cancellationReason: varchar('cancellation_reason', { length: 500 }),
    
    // Reversal
    reversedAt: timestamp('reversed_at', { withTimezone: true }),
    reversedBy: uuid('reversed_by'),
    reversalReason: varchar('reversal_reason', { length: 500 }),
    reversalGrnId: uuid('reversal_grn_id'),
    
    notes: varchar('notes', { length: 2000 }),
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    tenantStoreIdx: index('idx_grn_tenant_store').on(table.tenantId, table.storeId),
    storeStatusDateIdx: index('idx_grn_store_status_date').on(
      table.storeId,
      table.status,
      table.inwardDate,
    ),
    supplierIdx: index('idx_grn_supplier').on(table.supplierId),
    invoiceIdx: index('idx_grn_invoice').on(table.invoiceNumber),
    statusIdx: index('idx_grn_status').on(table.status),
    uniqueGrnNumber: unique('uniq_grn_number_tenant').on(table.tenantId, table.grnNumber),
    uniqueInvoiceSupplier: unique('uniq_grn_invoice_supplier').on(
      table.supplierId,
      table.invoiceNumber,
    ),
  }),
);

export type Grn = typeof grnHeaders.$inferSelect;
export type NewGrn = typeof grnHeaders.$inferInsert;
```

### 2. GRN Items Schema

```typescript
// server/src/db/schema/grn_items.ts
import { pgTable, varchar, uuid, integer, decimal, timestamp, jsonb, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';
import { grnHeaders } from './grn_headers';

export const grnItems = pgTable(
  'grn_items',
  {
    ...baseColumns,
    grnId: uuid('grn_id').notNull().references(() => grnHeaders.id, { onDelete: 'cascade' }),
    tenantId: uuid('tenant_id').notNull(),
    storeId: uuid('store_id').notNull(),
    
    // Product
    productId: uuid('product_id'),
    ean: varchar('ean', { length: 13 }).notNull(),
    productNameSnapshot: varchar('product_name_snapshot', { length: 200 }),
    
    // Quantities
    quantity: integer('quantity').notNull(),
    unit: varchar('unit', { length: 20 }).default('pcs'),
    
    // Batch & expiry (CRITICAL)
    batchNumber: varchar('batch_number', { length: 100 }),
    manufactureDate: timestamp('manufacture_date', { withTimezone: true }),
    expiryDate: timestamp('expiry_date', { withTimezone: true }),
    expiryRemainingDays: integer('expiry_remaining_days'),
    
    // Pricing (optional)
    unitPrice: decimal('unit_price', { precision: 10, scale: 2 }),
    taxPercent: decimal('tax_percent', { precision: 5, scale: 2 }),
    totalPrice: decimal('total_price', { precision: 14, scale: 2 }),
    
    // Linking after post
    expiryRecordId: uuid('expiry_record_id'),
    inventoryItemId: uuid('inventory_item_id'),
    stockMovementId: uuid('stock_movement_id'),
    
    notes: varchar('notes', { length: 500 }),
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    grnIdx: index('idx_grn_items_grn').on(table.grnId),
    eanIdx: index('idx_grn_items_ean').on(table.ean),
    productIdx: index('idx_grn_items_product').on(table.productId),
    batchIdx: index('idx_grn_items_batch').on(table.batchNumber),
  }),
);

export type GrnItem = typeof grnItems.$inferSelect;
```

### 3. GRN Events Schema

```typescript
// server/src/db/schema/grn_events.ts
import { pgTable, varchar, uuid, jsonb, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const grnEventTypeEnum = pgEnum('grn_event_type', [
  'created',
  'updated',
  'item_added',
  'item_updated',
  'item_removed',
  'submitted_for_review',
  'approved',
  'posted',
  'cancelled',
  'reversed',
]);

export const grnEvents = pgTable(
  'grn_events',
  {
    ...baseColumns,
    grnId: uuid('grn_id').notNull(),
    type: grnEventTypeEnum('type').notNull(),
    actorId: uuid('actor_id').notNull(),
    notes: varchar('notes', { length: 1000 }),
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    grnCreatedIdx: index('idx_grn_events_grn_created').on(table.grnId, table.createdAt),
    typeIdx: index('idx_grn_events_type').on(table.type),
  }),
);
```

### 4. GRN Posting Service (Atomic)

```typescript
// server/src/modules/grn/services/grn-posting.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { DbService } from '../../../db/db.service';
import { GrnHeadersRepository } from '../repositories/grn-headers.repository';
import { GrnItemsRepository } from '../repositories/grn-items.repository';
import { GrnEventsRepository } from '../repositories/grn-events.repository';
import { GrnValidationService } from './grn-validation.service';
import { ProductsRepository } from '../../products/products.repository';
import { ExpiryService } from '../../expiry/expiry.service';
import { SupplierPerformanceService } from '../../suppliers/services/supplier-performance.service';
import { AuditLogService } from '../../../observability/audit-log.service';
import { LoggerService } from '../../../logging/logger.service';
import { PostResult, InventoryUpdate } from '../types/grn.types';
import {
  BusinessException,
  NotFoundException,
} from '../../../common/errors/business.exception';
import { ErrorCode } from '../../../common/errors/error-codes';

@Injectable()
export class GrnPostingService {
  private readonly logger = new Logger(GrnPostingService.name);

  constructor(
    private readonly db: DbService,
    private readonly headersRepo: GrnHeadersRepository,
    private readonly itemsRepo: GrnItemsRepository,
    private readonly eventsRepo: GrnEventsRepository,
    private readonly validator: GrnValidationService,
    private readonly productsRepo: ProductsRepository,
    private readonly expiryService: ExpiryService,
    private readonly supplierPerf: SupplierPerformanceService,
    private readonly auditLog: AuditLogService,
    private readonly appLogger: LoggerService,
  ) {}

  async post(grnId: string, userId: string): Promise<PostResult> {
    // 1. Fetch GRN
    const grn = await this.headersRepo.findById(grnId);
    if (!grn) throw new NotFoundException('GRN', grnId);
    
    if (grn.status !== 'draft' && grn.status !== 'pending_review') {
      throw new BusinessException(
        ErrorCode.GRN_ALREADY_POSTED,
        `Cannot post GRN in ${grn.status} status`,
      );
    }
    
    // 2. Validate
    const validation = await this.validator.validate(grnId);
    if (!validation.valid) {
      throw new BusinessException(
        ErrorCode.VALIDATION_ERROR,
        'GRN validation failed',
        { metadata: { errors: validation.errors } },
      );
    }
    
    // 3. Get items
    const items = await this.itemsRepo.findByGrn(grnId);
    if (items.length === 0) {
      throw new BusinessException(
        ErrorCode.VALIDATION_ERROR,
        'Cannot post GRN with no items',
      );
    }
    
    // 4. ATOMIC TRANSACTION
    return this.db.transaction(async (tx) => {
      const inventoryUpdates: InventoryUpdate[] = [];
      let expiryRecordsCreated = 0;
      let alertsGenerated = 0;
      let minExpiryDays = Infinity;
      let shortShelfLifeCount = 0;
      
      // 4a. For each line item:
      for (const item of items) {
        // Resolve product (create if doesn't exist in catalog)
        let productId = item.productId;
        if (!productId) {
          const existing = await this.productsRepo.findByEan(item.ean);
          if (existing) {
            productId = existing.id;
            await this.itemsRepo.update(item.id, { productId }, tx);
          } else {
            // Auto-create product from GRN data
            const newProduct = await this.productsRepo.create({
              ean: item.ean,
              name: item.productNameSnapshot || `Product ${item.ean}`,
              status: 'pending_review',
              dataSource: 'grn',
            }, tx);
            productId = newProduct.id;
            await this.itemsRepo.update(item.id, { productId }, tx);
          }
        }
        
        // Create expiry record (BE-18)
        if (item.expiryDate) {
          const expiryRecord = await this.expiryService.createRecord({
            productId,
            storeId: grn.storeId,
            expiryDate: item.expiryDate,
            manufactureDate: item.manufactureDate || undefined,
            batchNumber: item.batchNumber || undefined,
            quantity: item.quantity,
            source: 'grn',
            sourceId: item.id,
            notes: item.notes || undefined,
          }, userId);
          
          await this.itemsRepo.update(item.id, {
            expiryRecordId: expiryRecord.id,
            expiryRemainingDays: this.daysUntilExpiry(item.expiryDate),
          }, tx);
          
          expiryRecordsCreated++;
          
          const days = this.daysUntilExpiry(item.expiryDate);
          minExpiryDays = Math.min(minExpiryDays, days);
          
          if (days < 30) {
            shortShelfLifeCount++;
          }
        }
        
        // BE-27 will handle inventory updates here
        // For now, just track what would happen
        inventoryUpdates.push({
          productId,
          storeId: grn.storeId,
          batchNumber: item.batchNumber || undefined,
          quantityAdded: item.quantity,
          newTotal: item.quantity, // Will be calculated in BE-27
        });
      }
      
      // 4b. Update GRN status
      const postedAt = new Date();
      const updated = await this.headersRepo.update(grnId, {
        status: 'posted',
        postedAt,
        postedBy: userId,
        minExpiryRemainingDays: minExpiryDays === Infinity ? null : minExpiryDays,
        shortShelfLifeCount,
      }, tx);
      
      // 4c. Update supplier performance
      const deliveryDays = grn.orderDate
        ? Math.floor(
            (new Date(grn.inwardDate).getTime() - new Date(grn.orderDate).getTime()) /
              (1000 * 60 * 60 * 24),
          )
        : 0;
      
      await this.supplierPerf.updateMetrics(grn.supplierId, {
        grnId: grn.id,
        deliveryDays,
        expiryRemainingDays: minExpiryDays === Infinity ? 999 : minExpiryDays,
        shortShelfLife: shortShelfLifeCount > 0,
        amount: grn.totalAmount ? Number(grn.totalAmount) : undefined,
      });
      
      // 4d. Log event
      await this.eventsRepo.create({
        grnId,
        type: 'posted',
        actorId: userId,
        notes: 'GRN posted to inventory',
        metadata: {
          totalItems: items.length,
          minExpiryDays,
          shortShelfLifeCount,
        },
      }, tx);
      
      // 4e. Audit log
      await this.auditLog.logAction({
        action: 'CREATE',
        resourceType: 'GrnPosting',
        resourceId: grnId,
        userId,
        tenantId: grn.tenantId,
        success: true,
        metadata: {
          itemsPosted: items.length,
          totalQuantity: items.reduce((sum, i) => sum + i.quantity, 0),
        },
      });
      
      this.appLogger.info('GRN posted successfully', {
        grnId,
        itemsCount: items.length,
        shortShelfLifeCount,
      });
      
      return {
        grn: updated,
        inventoryUpdates,
        expiryRecordsCreated,
        alertsGenerated,
      };
    }, { isolationLevel: 'serializable' }); // Serializable to prevent race conditions
  }

  private daysUntilExpiry(expiryDate: Date): number {
    const now = new Date();
    const expiry = new Date(expiryDate);
    return Math.floor((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
  }
}
```

### 5. GRN Validation Service

```typescript
// server/src/modules/grn/services/grn-validation.service.ts
import { Injectable } from '@nestjs/common';
import { GrnHeadersRepository } from '../repositories/grn-headers.repository';
import { GrnItemsRepository } from '../repositories/grn-items.repository';
import { ProductsRepository } from '../../products/products.repository';
import {
  ValidationResult,
  ValidationError,
  ValidationWarning,
} from '../types/grn.types';

@Injectable()
export class GrnValidationService {
  constructor(
    private readonly headersRepo: GrnHeadersRepository,
    private readonly itemsRepo: GrnItemsRepository,
    private readonly productsRepo: ProductsRepository,
  ) {}

  async validate(grnId: string): Promise<ValidationResult> {
    const grn = await this.headersRepo.findById(grnId);
    if (!grn) {
      return {
        valid: false,
        errors: [{ field: 'id', message: 'GRN not found' }],
        warnings: [],
      };
    }
    
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];
    
    // Header validation
    if (!grn.invoiceNumber) {
      errors.push({ field: 'invoiceNumber', message: 'Invoice number required' });
    }
    if (!grn.supplierId) {
      errors.push({ field: 'supplierId', message: 'Supplier required' });
    }
    if (!grn.inwardDate) {
      errors.push({ field: 'inwardDate', message: 'Inward date required' });
    }
    
    // Items validation
    const items = await this.itemsRepo.findByGrn(grnId);
    if (items.length === 0) {
      errors.push({ field: 'items', message: 'At least one item required' });
    }
    
    const seenBatches = new Set<string>();
    
    for (const item of items) {
      // Required fields
      if (!item.ean) {
        errors.push({ field: 'ean', itemId: item.id, message: 'EAN required' });
      }
      if (!item.quantity || item.quantity <= 0) {
        errors.push({ field: 'quantity', itemId: item.id, message: 'Quantity must be > 0' });
      }
      
      // Expiry date sanity
      if (item.expiryDate && item.manufactureDate) {
        if (item.expiryDate <= item.manufactureDate) {
          errors.push({
            field: 'expiryDate',
            itemId: item.id,
            message: 'Expiry must be after manufacture date',
          });
        }
      }
      
      // Past expiry date (warning, not error - might be intentional)
      if (item.expiryDate && new Date(item.expiryDate) < new Date()) {
        warnings.push({
          type: 'short_shelf_life',
          message: `Item ${item.ean} is already expired`,
          itemId: item.id,
        });
      }
      
      // Short shelf life warning
      if (item.expiryDate) {
        const daysRemaining = Math.floor(
          (new Date(item.expiryDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24),
        );
        if (daysRemaining < 30 && daysRemaining > 0) {
          warnings.push({
            type: 'short_shelf_life',
            message: `Item ${item.ean} has only ${daysRemaining} days until expiry`,
            itemId: item.id,
          });
        }
      }
      
      // Duplicate batch in same GRN
      if (item.batchNumber) {
        const key = `${item.ean}-${item.batchNumber}`;
        if (seenBatches.has(key)) {
          warnings.push({
            type: 'duplicate_batch',
            message: `Duplicate batch ${item.batchNumber} for EAN ${item.ean}`,
            itemId: item.id,
          });
        }
        seenBatches.add(key);
      }
      
      // Unknown product
      if (!item.productId) {
        const existing = await this.productsRepo.findByEan(item.ean);
        if (!existing) {
          warnings.push({
            type: 'unknown_product',
            message: `Product ${item.ean} not in catalog. Will be auto-created.`,
            itemId: item.id,
          });
        }
      }
    }
    
    return {
      valid: errors.length === 0,
      errors,
      warnings,
    };
  }
}
```

### 6. GRN Service (Main)

```typescript
// server/src/modules/grn/grn.service.ts
import { Injectable } from '@nestjs/common';
import { GrnHeadersRepository } from './repositories/grn-headers.repository';
import { GrnItemsRepository } from './repositories/grn-items.repository';
import { GrnEventsRepository } from './repositories/grn-events.repository';
import { GrnPostingService } from './services/grn-posting.service';
import { GrnValidationService } from './services/grn-validation.service';
import { GrnNumberGenerator } from './utils/grn-number-generator.utils';
import { DbService } from '../../db/db.service';
import { SuppliersRepository } from '../suppliers/repositories/suppliers.repository';
import {
  IGrnService,
  CreateGrnDto,
  UpdateGrnDto,
  GrnItemDto,
  GrnWithDetails,
  PostResult,
  ReverseResult,
} from './types/grn.types';
import {
  NotFoundException,
  BusinessException,
} from '../../common/errors/business.exception';
import { ErrorCode } from '../../common/errors/error-codes';

@Injectable()
export class GrnService implements IGrnService {
  constructor(
    private readonly db: DbService,
    private readonly headersRepo: GrnHeadersRepository,
    private readonly itemsRepo: GrnItemsRepository,
    private readonly eventsRepo: GrnEventsRepository,
    private readonly suppliersRepo: SuppliersRepository,
    private readonly postingService: GrnPostingService,
    private readonly validationService: GrnValidationService,
    private readonly numberGenerator: GrnNumberGenerator,
  ) {}

  async createDraft(dto: CreateGrnDto, userId: string): Promise<Grn> {
    // Verify supplier
    const supplier = await this.suppliersRepo.findById(dto.supplierId);
    if (!supplier) throw new NotFoundException('Supplier', dto.supplierId);
    if (supplier.status !== 'active') {
      throw new BusinessException(
        ErrorCode.BUSINESS_RULE_VIOLATION,
        `Cannot create GRN for ${supplier.status} supplier`,
      );
    }
    
    return this.db.transaction(async (tx) => {
      // Generate GRN number
      const grnNumber = await this.numberGenerator.generate(supplier.tenantId);
      
      // Create header
      const grn = await this.headersRepo.create({
        grnNumber,
        supplierId: dto.supplierId,
        storeId: dto.storeId,
        invoiceNumber: dto.invoiceNumber,
        invoiceDate: dto.invoiceDate,
        inwardDate: dto.inwardDate,
        poNumber: dto.poNumber,
        expectedDeliveryDate: dto.expectedDeliveryDate,
        subtotal: dto.subtotal?.toString(),
        taxAmount: dto.taxAmount?.toString(),
        totalAmount: dto.totalAmount?.toString(),
        notes: dto.notes,
        metadata: dto.metadata,
        status: 'draft',
      }, tx);
      
      // Add initial items if provided
      if (dto.items && dto.items.length > 0) {
        await this.addItemsInternal(grn.id, dto.items, userId, tx);
      }
      
      // Log event
      await this.eventsRepo.create({
        grnId: grn.id,
        type: 'created',
        actorId: userId,
      }, tx);
      
      return grn;
    });
  }

  async addItems(grnId: string, items: GrnItemDto[], userId: string): Promise<GrnItem[]> {
    return this.db.transaction(async (tx) => {
      return this.addItemsInternal(grnId, items, userId, tx);
    });
  }

  async post(id: string, userId: string): Promise<PostResult> {
    return this.postingService.post(id, userId);
  }

  async cancel(id: string, reason: string, userId: string): Promise<Grn> {
    const grn = await this.headersRepo.findById(id);
    if (!grn) throw new NotFoundException('GRN', id);
    
    if (grn.status === 'posted') {
      throw new BusinessException(
        ErrorCode.GRN_ALREADY_POSTED,
        'Cannot cancel posted GRN. Use reverse instead.',
      );
    }
    
    return this.db.transaction(async (tx) => {
      const updated = await this.headersRepo.update(id, {
        status: 'cancelled',
        cancelledAt: new Date(),
        cancelledBy: userId,
        cancellationReason: reason,
      }, tx);
      
      await this.eventsRepo.create({
        grnId: id,
        type: 'cancelled',
        actorId: userId,
        notes: reason,
      }, tx);
      
      return updated;
    });
  }

  async reverse(id: string, reason: string, userId: string): Promise<ReverseResult> {
    // Reversing creates a counter-GRN that cancels out the original
    // Implementation: complex, similar to GRN posting but with negative quantities
    throw new Error('Implement GRN reversal');
  }

  async findById(id: string): Promise<GrnWithDetails | null> {
    const grn = await this.headersRepo.findById(id);
    if (!grn) return null;
    
    const [supplier, items, events] = await Promise.all([
      this.suppliersRepo.findById(grn.supplierId),
      this.itemsRepo.findByGrn(id),
      this.eventsRepo.findByGrn(id),
    ]);
    
    return {
      ...grn,
      supplier: supplier!,
      items: items as any,
      events,
    };
  }

  async list(filters: any): Promise<any> {
    return this.headersRepo.findPaginated(filters, {
      cursor: filters.cursor,
      limit: filters.limit || 50,
      orderBy: [{ field: 'inwardDate', direction: 'desc' }],
    });
  }

  async listForSupplier(supplierId: string, filters: any): Promise<any> {
    return this.headersRepo.findPaginated(
      { ...filters, supplierId },
      { ...filters, orderBy: [{ field: 'inwardDate', direction: 'desc' }] },
    );
  }

  async validate(id: string): Promise<any> {
    return this.validationService.validate(id);
  }

  async updateDraft(id: string, dto: any, userId: string): Promise<any> {
    const grn = await this.headersRepo.findById(id);
    if (!grn) throw new NotFoundException('GRN', id);
    if (grn.status !== 'draft') {
      throw new BusinessException(
        ErrorCode.GRN_ALREADY_POSTED,
        'Can only update draft GRNs',
      );
    }
    return this.headersRepo.update(id, dto);
  }

  async updateItem(itemId: string, dto: any, userId: string): Promise<any> {
    return this.itemsRepo.update(itemId, dto);
  }

  async removeItem(itemId: string, userId: string): Promise<void> {
    await this.itemsRepo.delete(itemId);
  }

  async getStats(filters: any): Promise<any> {
    return this.headersRepo.getStats(filters);
  }

  private async addItemsInternal(
    grnId: string,
    items: GrnItemDto[],
    userId: string,
    tx: any,
  ): Promise<GrnItem[]> {
    const grn = await this.headersRepo.findById(grnId);
    if (!grn) throw new NotFoundException('GRN', grnId);
    
    const created = [];
    let totalQty = 0;
    
    for (const item of items) {
      const expiryRemainingDays = item.expiryDate
        ? Math.floor((new Date(item.expiryDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24))
        : null;
      
      const totalPrice = item.unitPrice && item.quantity 
        ? (item.unitPrice * item.quantity).toString() 
        : undefined;
      
      const grnItem = await this.itemsRepo.create({
        grnId,
        tenantId: grn.tenantId,
        storeId: grn.storeId,
        ean: item.ean,
        productId: item.productId,
        productNameSnapshot: item.productName,
        quantity: item.quantity,
        unit: item.unit || 'pcs',
        batchNumber: item.batchNumber,
        manufactureDate: item.manufactureDate,
        expiryDate: item.expiryDate,
        expiryRemainingDays,
        unitPrice: item.unitPrice?.toString(),
        taxPercent: item.taxPercent?.toString(),
        totalPrice,
        notes: item.notes,
      }, tx);
      
      created.push(grnItem);
      totalQty += item.quantity;
    }
    
    // Update header stats
    await this.headersRepo.update(grnId, {
      totalItems: grn.totalItems + items.length,
      totalQuantity: grn.totalQuantity + totalQty,
    }, tx);
    
    return created;
  }
}
```

### 7. DTOs

```typescript
// server/src/modules/grn/dto/create-grn.dto.ts
import { z } from 'zod';

export const GrnItemSchema = z.object({
  productId: z.string().uuid().optional(),
  ean: z.string().regex(/^\d{8,13}$/),
  productName: z.string().max(200).optional(),
  quantity: z.number().int().positive().max(1000000),
  unit: z.string().max(20).default('pcs'),
  batchNumber: z.string().max(100).optional(),
  manufactureDate: z.coerce.date().optional(),
  expiryDate: z.coerce.date().optional(),
  unitPrice: z.number().nonnegative().optional(),
  taxPercent: z.number().min(0).max(100).optional(),
  notes: z.string().max(500).optional(),
}).refine(
  (data) => !data.expiryDate || !data.manufactureDate || data.expiryDate > data.manufactureDate,
  { message: 'Expiry must be after manufacture date', path: ['expiryDate'] },
);

export const CreateGrnSchema = z.object({
  supplierId: z.string().uuid(),
  storeId: z.string().uuid(),
  invoiceNumber: z.string().min(1).max(100),
  invoiceDate: z.coerce.date(),
  inwardDate: z.coerce.date(),
  poNumber: z.string().max(100).optional(),
  expectedDeliveryDate: z.coerce.date().optional(),
  subtotal: z.number().nonnegative().optional(),
  taxAmount: z.number().nonnegative().optional(),
  totalAmount: z.number().nonnegative().optional(),
  items: z.array(GrnItemSchema).optional(),
  notes: z.string().max(2000).optional(),
  metadata: z.record(z.unknown()).optional(),
});

export type CreateGrnDto = z.infer<typeof CreateGrnSchema>;
export type GrnItemDto = z.infer<typeof GrnItemSchema>;
```

## API Endpoints

| Method | Endpoint | Auth | Role | Purpose |
|---|---|---|---|---|
| POST | `/api/v1/grn` | Bearer | Manager+ | Create draft |
| GET | `/api/v1/grn` | Bearer | Staff+ | List GRNs |
| GET | `/api/v1/grn/:id` | Bearer | Staff+ | Get details |
| PATCH | `/api/v1/grn/:id` | Bearer | Manager+ | Update draft |
| POST | `/api/v1/grn/:id/items` | Bearer | Manager+ | Add items |
| PATCH | `/api/v1/grn/:id/items/:itemId` | Bearer | Manager+ | Update item |
| DELETE | `/api/v1/grn/:id/items/:itemId` | Bearer | Manager+ | Remove item |
| POST | `/api/v1/grn/:id/validate` | Bearer | Manager+ | Pre-post check |
| POST | `/api/v1/grn/:id/post` | Bearer | Manager+ | Post to inventory |
| POST | `/api/v1/grn/:id/cancel` | Bearer | Manager+ | Cancel draft |
| POST | `/api/v1/grn/:id/reverse` | Bearer | Owner | Reverse posted |
| GET | `/api/v1/grn/stats` | Bearer | Manager+ | Statistics |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-27 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Create Draft GRN ✅
**Pass Criteria**: ✅ Auto-generates GRN number, status=draft

### Test 2: Add Items ✅
With batch + expiry:
**Pass Criteria**: ✅ Items added, totals updated

### Test 3: Validate Before Post ✅
**Expected**: Returns errors + warnings (short shelf life, etc.)
**Pass Criteria**: ✅ All checks run

### Test 4: Post GRN — Atomic ✅
Post creates: GRN updated, expiry records, supplier perf updated
**Pass Criteria**: ✅ All updates in single transaction

### Test 5: Cannot Post Twice ✅
Already posted → 422 GRN_ALREADY_POSTED
**Pass Criteria**: ✅ Idempotent

### Test 6: Cancel Draft ✅
**Pass Criteria**: ✅ Draft cancelled, audit logged

### Test 7: Cannot Cancel Posted ✅
Posted GRN cancel → 422
**Pass Criteria**: ✅ Use reverse instead

### Test 8: Auto-create Product ✅
Item with EAN not in catalog:
**Expected**: Product auto-created with status=pending_review
**Pass Criteria**: ✅ Catalog grows from GRNs

### Test 9: Expiry Records Created ✅
Items with expiry date → expiry_records created (BE-18 integration)
**Pass Criteria**: ✅ Expiry tracking populated

### Test 10: Supplier Performance Updated ✅
After posting, supplier metrics updated
**Pass Criteria**: ✅ Vendor accountability data flows

### Test 11: Short Shelf Life Detection ✅
Items < 30 days expiry → counted in shortShelfLifeCount
**Pass Criteria**: ✅ Risk visibility

### Test 12: Duplicate Invoice ✅
Same supplier + invoice number → 409
**Pass Criteria**: ✅ Duplicate prevention

### Test 13: Validation Warnings ✅
Past expiry → warning (not error)
**Pass Criteria**: ✅ Allows overrides with awareness

### Test 14: Tenant Isolation ✅
**Pass Criteria**: ✅ Cross-tenant blocked

### Test 15: Audit Trail ✅
All events in grn_events
**Pass Criteria**: ✅ Compliance trail

## 🎯 Q&A Session

### Q1: Why draft → posted workflow?
**Expected**: Two-step ensures verification before stock impact, allows corrections

### Q2: Why serializable transaction for posting?
**Expected**: Prevents race conditions in concurrent postings, atomic stock updates

### Q3: Why product name snapshot?
**Expected**: Audit — what was claimed at receipt time, immutable record

### Q4: Why supplier+invoice uniqueness?
**Expected**: Prevents duplicate GRN entries, data integrity

### Q5: How handle returned items?
**Expected**: Reverse GRN creates counter-entry, doesn't delete original (audit)

### Q6: Why warn but allow short shelf life?
**Expected**: Sometimes intentional (clearance, special promo), user knows context

### Q7: How does this integrate with inventory (BE-27)?
**Expected**: Posting triggers stock movements, inventory_items created/updated

### Q8: Why update supplier performance immediately?
**Expected**: Real-time vendor scoring, dashboards stay current, accountability visible

## 📝 Sign-Off Checklist

- [ ] All 15 tests pass
- [ ] Atomic posting verified
- [ ] Expiry integration works
- [ ] Supplier metrics updated
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-27**
**☐ CHANGES REQUESTED**

---

**END OF BE-26 — DO NOT PROCEED WITHOUT APPROVAL**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-26 (GRN Module) with metric extraction for the Vendor Quality component of Operational Health Score (Req 29).**

## Driver Requirement

- **Req 29** — Vendor Quality component (10% weight): on-time GRN delivery rate + batch consistency.

## Scope of Update

GRN module behaviour is unchanged. v2 adds a read-side query the OHS calculator (BE-30 ADDENDUM v2) calls daily.

## Files to Create

| File Path | Change |
|---|---|
| `server/src/modules/grn/queries/vendor-quality-metrics.query.ts` | New |

```typescript
export interface VendorQualityMetrics {
  onTimeDeliveryRate: number;     // 0..1
  batchConsistencyScore: number;  // 0..1
  windowDays: number;
}

@Injectable()
export class VendorQualityMetricsQuery {
  async forStore(tenantId: string, storeId: string, windowDays = 30): Promise<VendorQualityMetrics> {
    // Aggregate from grns + grn_lines for the rolling window
    // ...
  }
}
```

## ADDENDUM v2 Test Procedures (add 2)

| # | Test |
|---|---|
| T-v2.1 | Returns 1.0 if every GRN was delivered on or before promised date |
| T-v2.2 | Returns batch consistency rate based on supplier batch numbering rules |

## ADDENDUM v2 Sign-off

- [ ] Metrics query implemented and exported
- [ ] Consumed correctly by BE-30 OHS service

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-26 ADDENDUM v2**
