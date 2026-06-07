# Phase BE-27: Lightweight Inventory Module

## Phase Metadata

- **Phase ID**: BE-27
- **Phase Name**: Lightweight Inventory Module
- **Section**: Backend Execution — Business Operations Layer
- **Depends On**: BE-01 to BE-26
- **Blocks**: BE-28, BE-30 (dashboards use inventory)
- **Estimated Duration**: 3-4 days
- **Complexity**: High

## Goal

Build lightweight inventory tracking: stock in/out movements, batch-level quantity, low-stock alerts with configurable rules, stock counts (physical inventory), variance tracking, GRN integration (auto stock-in), expiry-aware deductions, and movement audit trail. Stays operational, NOT a full ERP/POS.

## Why This Phase Matters

Inventory closes the loop:
- GRN brings stock IN (BE-26)
- Sales/expiry takes stock OUT
- Real-time visibility into what's on shelf
- Low-stock alerts prevent stockouts
- Counts catch shrinkage/theft
- Foundation for premium upsells (BE-28)

## Prerequisites

- [ ] BE-01 to BE-26 completed
- [ ] GRN posting (BE-26)
- [ ] Products & expiry (BE-10, BE-18)
- [ ] Notifications (BE-24) for alerts

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/inventory_items.ts` | Current stock per product/store |
| `server/src/db/schema/inventory_batches.ts` | Per-batch quantity |
| `server/src/db/schema/stock_movements.ts` | Movement audit trail |
| `server/src/db/schema/low_stock_rules.ts` | Threshold config |
| `server/src/db/schema/low_stock_alerts.ts` | Active alerts |
| `server/src/db/schema/stock_counts.ts` | Physical counts |
| `server/src/db/schema/stock_count_lines.ts` | Count lines |
| `server/src/modules/inventory/inventory.module.ts` | Module |
| `server/src/modules/inventory/inventory.controller.ts` | Endpoints |
| `server/src/modules/inventory/inventory.service.ts` | Business logic |
| `server/src/modules/inventory/services/stock-movement.service.ts` | Movements |
| `server/src/modules/inventory/services/low-stock-alert.service.ts` | Alerts |
| `server/src/modules/inventory/services/stock-count.service.ts` | Counts |
| `server/src/modules/inventory/services/inventory-aggregator.service.ts` | Stats |
| `server/src/modules/inventory/repositories/inventory-items.repository.ts` | Data |
| `server/src/modules/inventory/repositories/stock-movements.repository.ts` | Data |
| `server/src/modules/inventory/repositories/low-stock-alerts.repository.ts` | Data |
| `server/src/modules/inventory/dto/stock-in.dto.ts` | DTOs |
| `server/src/modules/inventory/dto/stock-out.dto.ts` | DTOs |
| `server/src/modules/inventory/dto/stock-count.dto.ts` | DTOs |
| `server/src/modules/inventory/types/inventory.types.ts` | Types |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/inventory/inventory.service.ts

export interface IInventoryService {
  // Stock movements
  stockIn(dto: StockInDto, userId: string): Promise<StockMovementResult>;
  stockOut(dto: StockOutDto, userId: string): Promise<StockMovementResult>;
  adjust(dto: AdjustStockDto, userId: string): Promise<StockMovementResult>;
  
  // Queries
  getCurrentStock(productId: string, storeId: string): Promise<InventoryItem | null>;
  getStockByBatch(productId: string, storeId: string): Promise<InventoryBatch[]>;
  listStock(filters: ListInventoryDto): Promise<PaginatedResult<InventoryItemWithProduct>>;
  
  // Stats
  getStoreSummary(storeId: string): Promise<InventorySummary>;
  getCategoryBreakdown(storeId: string): Promise<CategoryBreakdown[]>;
  
  // Low stock
  getLowStockAlerts(storeId: string): Promise<LowStockAlert[]>;
  setLowStockRule(dto: LowStockRuleDto, userId: string): Promise<LowStockRule>;
  
  // Counts
  startStockCount(dto: StartCountDto, userId: string): Promise<StockCount>;
  recordCountLine(countId: string, dto: CountLineDto, userId: string): Promise<StockCountLine>;
  completeCount(countId: string, userId: string): Promise<StockCountResult>;
  
  // Movements history
  getMovementHistory(filters: MovementFilters): Promise<PaginatedResult<StockMovement>>;
}

export type StockMovementType =
  | 'in'           // GRN, manual addition
  | 'out'          // Sale, expiry, damage
  | 'adjustment'   // Count variance
  | 'transfer';    // Between stores (future)

export type StockMovementReason =
  | 'grn_post'        // From GRN
  | 'manual_in'       // Manual stock in
  | 'sale'            // Sold
  | 'expired'         // Removed for expiry
  | 'damaged'         // Damaged goods
  | 'returned'        // Customer return
  | 'theft'           // Stolen
  | 'count_adjustment' // From physical count
  | 'correction';     // Manual correction

export interface StockInDto {
  productId: string;
  storeId: string;
  quantity: number;
  reason: StockMovementReason;
  batchNumber?: string;
  expiryDate?: Date;
  unitCost?: number;
  reference?: string; // GRN ID, etc.
  notes?: string;
}

export interface StockOutDto {
  productId: string;
  storeId: string;
  quantity: number;
  reason: StockMovementReason;
  batchNumber?: string; // Specific batch (FIFO if not specified)
  notes?: string;
}

export interface AdjustStockDto {
  productId: string;
  storeId: string;
  newQuantity: number;
  reason: StockMovementReason;
  notes?: string;
}

export interface StockMovementResult {
  movement: StockMovement;
  inventoryItem: InventoryItem;
  newQuantity: number;
  alertsGenerated: number;
}

export interface InventorySummary {
  storeId: string;
  totalProducts: number;
  totalQuantity: number;
  totalValue?: number;
  byCategory: Record<string, { count: number; quantity: number }>;
  lowStockCount: number;
  expiringSoonCount: number;
  expiredCount: number;
}

export interface LowStockRuleDto {
  productId?: string;     // Specific product
  category?: string;      // All in category
  storeId: string;
  threshold: number;
  enabled: boolean;
}

export interface StockCountResult {
  countId: string;
  totalProducts: number;
  variances: number;
  totalVarianceQuantity: number;
  adjustmentsCreated: number;
}
```

## Implementation Code

### 1. Inventory Items Schema

```typescript
// server/src/db/schema/inventory_items.ts
import { pgTable, varchar, uuid, integer, decimal, timestamp, jsonb, index, unique } from 'drizzle-orm/pg-core';
import { baseColumns, softDeleteColumn, auditColumns } from './_base';

export const inventoryItems = pgTable(
  'inventory_items',
  {
    ...baseColumns,
    ...softDeleteColumn,
    ...auditColumns,
    tenantId: uuid('tenant_id').notNull(),
    storeId: uuid('store_id').notNull(),
    productId: uuid('product_id').notNull(),
    
    // Current stock (sum of all batches)
    quantity: integer('quantity').notNull().default(0),
    reservedQuantity: integer('reserved_quantity').notNull().default(0),
    availableQuantity: integer('available_quantity').notNull().default(0),
    
    // Threshold (denormalized from rules)
    lowStockThreshold: integer('low_stock_threshold'),
    isLowStock: varchar('is_low_stock', { length: 5 }).notNull().default('false'),
    
    // Latest activity
    lastMovementAt: timestamp('last_movement_at', { withTimezone: true }),
    lastInAt: timestamp('last_in_at', { withTimezone: true }),
    lastOutAt: timestamp('last_out_at', { withTimezone: true }),
    
    // Stats
    totalIn: integer('total_in').notNull().default(0),
    totalOut: integer('total_out').notNull().default(0),
    
    // Optional valuation
    averageUnitCost: decimal('average_unit_cost', { precision: 10, scale: 2 }),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    productStoreIdx: unique('uniq_inventory_product_store').on(
      table.productId,
      table.storeId,
    ),
    storeIdx: index('idx_inventory_store').on(table.storeId),
    lowStockIdx: index('idx_inventory_low_stock').on(table.storeId, table.isLowStock),
  }),
);

export type InventoryItem = typeof inventoryItems.$inferSelect;
```

### 2. Inventory Batches Schema

```typescript
// server/src/db/schema/inventory_batches.ts
import { pgTable, varchar, uuid, integer, timestamp, jsonb, index, unique } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const inventoryBatches = pgTable(
  'inventory_batches',
  {
    ...baseColumns,
    inventoryItemId: uuid('inventory_item_id').notNull(),
    tenantId: uuid('tenant_id').notNull(),
    storeId: uuid('store_id').notNull(),
    productId: uuid('product_id').notNull(),
    
    batchNumber: varchar('batch_number', { length: 100 }),
    
    quantity: integer('quantity').notNull().default(0),
    
    // Dates
    expiryDate: timestamp('expiry_date', { withTimezone: true }),
    manufactureDate: timestamp('manufacture_date', { withTimezone: true }),
    receivedAt: timestamp('received_at', { withTimezone: true }).notNull().defaultNow(),
    
    // Source
    sourceType: varchar('source_type', { length: 30 }), // 'grn', 'manual', 'transfer'
    sourceId: uuid('source_id'),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    inventoryItemIdx: index('idx_batches_inventory_item').on(table.inventoryItemId),
    productStoreIdx: index('idx_batches_product_store').on(table.productId, table.storeId),
    expiryIdx: index('idx_batches_expiry').on(table.expiryDate),
    uniqueProductStoreBatch: unique('uniq_batches_product_store_batch').on(
      table.productId,
      table.storeId,
      table.batchNumber,
    ),
  }),
);

export type InventoryBatch = typeof inventoryBatches.$inferSelect;
```

### 3. Stock Movements Schema

```typescript
// server/src/db/schema/stock_movements.ts
import { pgTable, varchar, uuid, integer, decimal, timestamp, jsonb, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const stockMovementTypeEnum = pgEnum('stock_movement_type', [
  'in',
  'out',
  'adjustment',
  'transfer',
]);

export const stockMovementReasonEnum = pgEnum('stock_movement_reason', [
  'grn_post',
  'manual_in',
  'sale',
  'expired',
  'damaged',
  'returned',
  'theft',
  'count_adjustment',
  'correction',
]);

export const stockMovements = pgTable(
  'stock_movements',
  {
    ...baseColumns,
    tenantId: uuid('tenant_id').notNull(),
    storeId: uuid('store_id').notNull(),
    productId: uuid('product_id').notNull(),
    
    type: stockMovementTypeEnum('type').notNull(),
    reason: stockMovementReasonEnum('reason').notNull(),
    
    // Quantities
    quantity: integer('quantity').notNull(), // Positive = in, negative = out
    quantityBefore: integer('quantity_before').notNull(),
    quantityAfter: integer('quantity_after').notNull(),
    
    // Batch reference
    batchNumber: varchar('batch_number', { length: 100 }),
    inventoryBatchId: uuid('inventory_batch_id'),
    
    // Source
    sourceType: varchar('source_type', { length: 30 }),
    sourceId: uuid('source_id'),
    
    // Cost (optional)
    unitCost: decimal('unit_cost', { precision: 10, scale: 2 }),
    totalCost: decimal('total_cost', { precision: 14, scale: 2 }),
    
    // Actor
    userId: uuid('user_id').notNull(),
    
    notes: varchar('notes', { length: 500 }),
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    productStoreCreatedIdx: index('idx_movements_product_store_created').on(
      table.productId,
      table.storeId,
      table.createdAt,
    ),
    storeCreatedIdx: index('idx_movements_store_created').on(table.storeId, table.createdAt),
    typeIdx: index('idx_movements_type').on(table.type),
    sourceIdx: index('idx_movements_source').on(table.sourceType, table.sourceId),
  }),
);

export type StockMovement = typeof stockMovements.$inferSelect;
```

### 4. Stock Movement Service

```typescript
// server/src/modules/inventory/services/stock-movement.service.ts
import { Injectable } from '@nestjs/common';
import { DbService } from '../../../db/db.service';
import { InventoryItemsRepository } from '../repositories/inventory-items.repository';
import { InventoryBatchesRepository } from '../repositories/inventory-batches.repository';
import { StockMovementsRepository } from '../repositories/stock-movements.repository';
import { LowStockAlertService } from './low-stock-alert.service';
import {
  StockInDto,
  StockOutDto,
  AdjustStockDto,
  StockMovementResult,
} from '../types/inventory.types';
import {
  BusinessException,
  NotFoundException,
} from '../../../common/errors/business.exception';
import { ErrorCode } from '../../../common/errors/error-codes';

@Injectable()
export class StockMovementService {
  constructor(
    private readonly db: DbService,
    private readonly itemsRepo: InventoryItemsRepository,
    private readonly batchesRepo: InventoryBatchesRepository,
    private readonly movementsRepo: StockMovementsRepository,
    private readonly alertService: LowStockAlertService,
  ) {}

  async stockIn(dto: StockInDto, userId: string): Promise<StockMovementResult> {
    return this.db.transaction(async (tx) => {
      // Get or create inventory item
      let item = await this.itemsRepo.findByProductAndStore(
        dto.productId,
        dto.storeId,
      );
      
      const quantityBefore = item?.quantity || 0;
      const quantityAfter = quantityBefore + dto.quantity;
      
      if (!item) {
        item = await this.itemsRepo.create({
          productId: dto.productId,
          storeId: dto.storeId,
          quantity: dto.quantity,
          availableQuantity: dto.quantity,
          totalIn: dto.quantity,
          lastInAt: new Date(),
          lastMovementAt: new Date(),
        }, tx);
      } else {
        item = await this.itemsRepo.update(item.id, {
          quantity: quantityAfter,
          availableQuantity: quantityAfter - item.reservedQuantity,
          totalIn: item.totalIn + dto.quantity,
          lastInAt: new Date(),
          lastMovementAt: new Date(),
        }, tx);
      }
      
      // Update or create batch
      let batch;
      if (dto.batchNumber) {
        const existingBatch = await this.batchesRepo.findByBatchNumber(
          dto.productId,
          dto.storeId,
          dto.batchNumber,
        );
        
        if (existingBatch) {
          batch = await this.batchesRepo.update(existingBatch.id, {
            quantity: existingBatch.quantity + dto.quantity,
          }, tx);
        } else {
          batch = await this.batchesRepo.create({
            inventoryItemId: item.id,
            productId: dto.productId,
            storeId: dto.storeId,
            batchNumber: dto.batchNumber,
            quantity: dto.quantity,
            expiryDate: dto.expiryDate,
            sourceType: this.reasonToSourceType(dto.reason),
            sourceId: dto.reference ? this.parseReference(dto.reference) : undefined,
          }, tx);
        }
      }
      
      // Record movement
      const movement = await this.movementsRepo.create({
        productId: dto.productId,
        storeId: dto.storeId,
        type: 'in',
        reason: dto.reason,
        quantity: dto.quantity,
        quantityBefore,
        quantityAfter,
        batchNumber: dto.batchNumber,
        inventoryBatchId: batch?.id,
        sourceType: this.reasonToSourceType(dto.reason),
        sourceId: dto.reference ? this.parseReference(dto.reference) : undefined,
        unitCost: dto.unitCost?.toString(),
        totalCost: dto.unitCost ? (dto.unitCost * dto.quantity).toString() : undefined,
        userId,
        notes: dto.notes,
      }, tx);
      
      // Check low stock (in case threshold changed)
      const alertsGenerated = await this.alertService.checkAndCreate(item, tx);
      
      return {
        movement,
        inventoryItem: item,
        newQuantity: quantityAfter,
        alertsGenerated,
      };
    });
  }

  async stockOut(dto: StockOutDto, userId: string): Promise<StockMovementResult> {
    return this.db.transaction(async (tx) => {
      const item = await this.itemsRepo.findByProductAndStore(
        dto.productId,
        dto.storeId,
      );
      
      if (!item) {
        throw new NotFoundException('InventoryItem');
      }
      
      // Check sufficient stock
      if (item.availableQuantity < dto.quantity) {
        throw new BusinessException(
          ErrorCode.INSUFFICIENT_STOCK,
          `Available: ${item.availableQuantity}, requested: ${dto.quantity}`,
        );
      }
      
      const quantityBefore = item.quantity;
      const quantityAfter = quantityBefore - dto.quantity;
      
      // FIFO batch deduction (use specific batch if provided)
      let remainingToDeduct = dto.quantity;
      let batchUsed;
      
      if (dto.batchNumber) {
        const batch = await this.batchesRepo.findByBatchNumber(
          dto.productId,
          dto.storeId,
          dto.batchNumber,
        );
        if (!batch || batch.quantity < dto.quantity) {
          throw new BusinessException(
            ErrorCode.INSUFFICIENT_STOCK,
            'Insufficient stock in specified batch',
          );
        }
        await this.batchesRepo.update(batch.id, {
          quantity: batch.quantity - dto.quantity,
        }, tx);
        batchUsed = batch;
      } else {
        // FIFO: use oldest batches first (by expiry date)
        const batches = await this.batchesRepo.findFifoBatches(
          dto.productId,
          dto.storeId,
        );
        
        for (const batch of batches) {
          if (remainingToDeduct === 0) break;
          
          const deductFromBatch = Math.min(batch.quantity, remainingToDeduct);
          await this.batchesRepo.update(batch.id, {
            quantity: batch.quantity - deductFromBatch,
          }, tx);
          
          remainingToDeduct -= deductFromBatch;
          if (!batchUsed) batchUsed = batch;
        }
      }
      
      // Update inventory item
      const updated = await this.itemsRepo.update(item.id, {
        quantity: quantityAfter,
        availableQuantity: quantityAfter - item.reservedQuantity,
        totalOut: item.totalOut + dto.quantity,
        lastOutAt: new Date(),
        lastMovementAt: new Date(),
      }, tx);
      
      // Record movement
      const movement = await this.movementsRepo.create({
        productId: dto.productId,
        storeId: dto.storeId,
        type: 'out',
        reason: dto.reason,
        quantity: -dto.quantity, // Negative for out
        quantityBefore,
        quantityAfter,
        batchNumber: dto.batchNumber || batchUsed?.batchNumber,
        inventoryBatchId: batchUsed?.id,
        userId,
        notes: dto.notes,
      }, tx);
      
      // Check low stock
      const alertsGenerated = await this.alertService.checkAndCreate(updated, tx);
      
      return {
        movement,
        inventoryItem: updated,
        newQuantity: quantityAfter,
        alertsGenerated,
      };
    });
  }

  async adjust(dto: AdjustStockDto, userId: string): Promise<StockMovementResult> {
    return this.db.transaction(async (tx) => {
      const item = await this.itemsRepo.findByProductAndStore(
        dto.productId,
        dto.storeId,
      );
      
      if (!item) throw new NotFoundException('InventoryItem');
      
      const quantityBefore = item.quantity;
      const adjustment = dto.newQuantity - quantityBefore;
      
      const updated = await this.itemsRepo.update(item.id, {
        quantity: dto.newQuantity,
        availableQuantity: dto.newQuantity - item.reservedQuantity,
        lastMovementAt: new Date(),
      }, tx);
      
      const movement = await this.movementsRepo.create({
        productId: dto.productId,
        storeId: dto.storeId,
        type: 'adjustment',
        reason: dto.reason,
        quantity: adjustment,
        quantityBefore,
        quantityAfter: dto.newQuantity,
        userId,
        notes: dto.notes,
      }, tx);
      
      const alertsGenerated = await this.alertService.checkAndCreate(updated, tx);
      
      return {
        movement,
        inventoryItem: updated,
        newQuantity: dto.newQuantity,
        alertsGenerated,
      };
    });
  }

  private reasonToSourceType(reason: string): string {
    const map: Record<string, string> = {
      grn_post: 'grn',
      manual_in: 'manual',
      count_adjustment: 'count',
    };
    return map[reason] || 'other';
  }

  private parseReference(ref: string): string | undefined {
    // Parse formats like "grn:uuid" or just uuid
    if (ref.includes(':')) return ref.split(':')[1];
    return ref;
  }
}
```

### 5. Low Stock Alert Service

```typescript
// server/src/modules/inventory/services/low-stock-alert.service.ts
import { Injectable } from '@nestjs/common';
import { LowStockAlertsRepository } from '../repositories/low-stock-alerts.repository';
import { LowStockRulesRepository } from '../repositories/low-stock-rules.repository';
import { ProductsRepository } from '../../products/products.repository';
import { NotificationsService } from '../../notifications/notifications.service';

@Injectable()
export class LowStockAlertService {
  constructor(
    private readonly alertsRepo: LowStockAlertsRepository,
    private readonly rulesRepo: LowStockRulesRepository,
    private readonly productsRepo: ProductsRepository,
    private readonly notificationsService: NotificationsService,
  ) {}

  async checkAndCreate(inventoryItem: any, tx: any): Promise<number> {
    // Get applicable rule
    const rule = await this.rulesRepo.findApplicableRule(
      inventoryItem.productId,
      inventoryItem.storeId,
    );
    
    if (!rule || !rule.enabled) return 0;
    
    const isLow = inventoryItem.quantity <= rule.threshold;
    
    if (isLow) {
      // Check existing active alert
      const existing = await this.alertsRepo.findActiveForItem(
        inventoryItem.productId,
        inventoryItem.storeId,
      );
      
      if (!existing) {
        // Create alert
        await this.alertsRepo.create({
          productId: inventoryItem.productId,
          storeId: inventoryItem.storeId,
          inventoryItemId: inventoryItem.id,
          threshold: rule.threshold,
          currentQuantity: inventoryItem.quantity,
          isResolved: false,
        }, tx);
        
        // Update inventory flag
        await this.itemsRepo.update(inventoryItem.id, {
          isLowStock: 'true',
          lowStockThreshold: rule.threshold,
        }, tx);
        
        // Notify (async, after transaction)
        // Will be fired after transaction commits
        return 1;
      }
    } else {
      // Resolve any active alerts
      await this.alertsRepo.resolveForItem(
        inventoryItem.productId,
        inventoryItem.storeId,
        tx,
      );
      
      await this.itemsRepo.update(inventoryItem.id, {
        isLowStock: 'false',
      }, tx);
    }
    
    return 0;
  }
}
```

## API Endpoints

| Method | Endpoint | Auth | Role | Purpose |
|---|---|---|---|---|
| POST | `/api/v1/inventory/stock-in` | Bearer | Manager+ | Add stock |
| POST | `/api/v1/inventory/stock-out` | Bearer | Manager+ | Remove stock |
| POST | `/api/v1/inventory/adjust` | Bearer | Manager+ | Adjust quantity |
| GET | `/api/v1/inventory/counts` | Bearer | Staff+ | List inventory |
| GET | `/api/v1/inventory/items/:id` | Bearer | Staff+ | Get item details |
| GET | `/api/v1/inventory/batches` | Bearer | Staff+ | List batches |
| GET | `/api/v1/inventory/movements` | Bearer | Manager+ | Movement history |
| GET | `/api/v1/inventory/low-stock` | Bearer | Manager+ | Low stock alerts |
| POST | `/api/v1/inventory/low-stock-rules` | Bearer | Manager+ | Set threshold |
| POST | `/api/v1/inventory/stock-counts` | Bearer | Manager+ | Start count |
| POST | `/api/v1/inventory/stock-counts/:id/lines` | Bearer | Staff+ | Record count |
| POST | `/api/v1/inventory/stock-counts/:id/complete` | Bearer | Manager+ | Finalize count |
| GET | `/api/v1/inventory/summary` | Bearer | Staff+ | Store summary |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-28 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Stock In ✅
**Pass Criteria**: ✅ inventory_items created/updated, batch created, movement recorded

### Test 2: Stock Out ✅
**Pass Criteria**: ✅ Quantity reduced, FIFO batch deduction

### Test 3: Insufficient Stock ✅
Stock out > available → 422 INSUFFICIENT_STOCK
**Pass Criteria**: ✅ Negative stock prevented

### Test 4: Stock Adjustment ✅
**Pass Criteria**: ✅ Quantity set to new value, variance recorded

### Test 5: GRN Integration ✅
Post GRN (BE-26) → stock_movements created automatically
**Pass Criteria**: ✅ Atomic with GRN posting

### Test 6: Low Stock Alert Generation ✅
Stock falls below threshold → alert created
**Pass Criteria**: ✅ Alert created automatically

### Test 7: Low Stock Alert Resolution ✅
Stock rises above threshold → alert resolved
**Pass Criteria**: ✅ Alert auto-resolves

### Test 8: FIFO Batch Logic ✅
Multiple batches with different expiries:
**Expected**: Oldest expiry deducted first
**Pass Criteria**: ✅ FIFO works

### Test 9: Specific Batch Deduction ✅
Stock out with batchNumber:
**Expected**: Only that batch reduced
**Pass Criteria**: ✅ Targeted deduction

### Test 10: Stock Count ✅
Start count, record lines, complete:
**Expected**: Variances calculated, adjustments created
**Pass Criteria**: ✅ Physical inventory works

### Test 11: Movement History ✅
**Pass Criteria**: ✅ All movements queryable

### Test 12: Concurrent Stock Out ✅
Two simultaneous stock outs:
**Expected**: One succeeds, other gets accurate count
**Pass Criteria**: ✅ No race conditions

### Test 13: Tenant Isolation ✅
**Pass Criteria**: ✅ Cross-tenant blocked

### Test 14: Inventory Summary ✅
**Pass Criteria**: ✅ Accurate counts by category

### Test 15: Audit Trail ✅
**Pass Criteria**: ✅ All movements logged with user, reason, timestamp

## 🎯 Q&A Session

### Q1: Why batch-level tracking?
**Expected**: Recall by batch, FIFO accuracy, expiry awareness, vendor traceability

### Q2: Why FIFO default?
**Expected**: Industry standard for perishables, reduces waste, matches expiry tracking

### Q3: Why prevent negative stock?
**Expected**: Data integrity, real-world reality, force corrections explicitly

### Q4: Why denormalize quantity on inventory_items?
**Expected**: Fast queries, real-time UI, sum-of-batches expensive

### Q5: How handle GRN posting concurrency?
**Expected**: Serializable transaction (BE-26), ensures atomic inventory updates

### Q6: Why separate alerts table?
**Expected**: Lifecycle (created/resolved), notification triggers, history

### Q7: Why physical counts?
**Expected**: Reality check, shrinkage detection, audit compliance, theft tracking

### Q8: How scale to high transaction volumes?
**Expected**: Indexed queries, partitioning by store/date if needed, async aggregations

## 📝 Sign-Off Checklist

- [ ] All 15 tests pass
- [ ] FIFO logic verified
- [ ] Low stock alerts work
- [ ] GRN integration works
- [ ] No negative stock
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-28**
**☐ CHANGES REQUESTED**

---

**END OF BE-27 — DO NOT PROCEED WITHOUT APPROVAL**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-27 (Inventory Module) with metric extraction for the Inventory Accuracy component of Operational Health Score (Req 29).**

## Driver Requirement

- **Req 29** — Inventory Accuracy component (20% weight): variance between counted stock and system stock.

## Scope of Update

Inventory module behaviour is unchanged. v2 adds a read-side query the OHS calculator (BE-30 ADDENDUM v2) calls daily.

## Files to Create

| File Path | Change |
|---|---|
| `server/src/modules/inventory/queries/inventory-accuracy-metrics.query.ts` | New |

```typescript
export interface InventoryAccuracyMetrics {
  varianceRate: number;         // 0..1, lower is better
  countsPerformed: number;
  windowDays: number;
}

@Injectable()
export class InventoryAccuracyMetricsQuery {
  async forStore(tenantId: string, storeId: string, windowDays = 30): Promise<InventoryAccuracyMetrics> {
    // Aggregate from stock_counts vs system_stock at point of count
    // ...
  }
}
```

## ADDENDUM v2 Test Procedures (add 2)

| # | Test |
|---|---|
| T-v2.1 | Returns 0.0 variance if all counts equal system stock |
| T-v2.2 | Returns nonzero variance proportional to absolute counted-vs-system delta |

## ADDENDUM v2 Sign-off

- [ ] Metrics query implemented and exported
- [ ] Consumed correctly by BE-30 OHS service

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-27 ADDENDUM v2**
