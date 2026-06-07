# Phase BE-25: Suppliers Module

## Phase Metadata

- **Phase ID**: BE-25
- **Phase Name**: Suppliers Module
- **Section**: Backend Execution — Business Operations Layer
- **Depends On**: BE-01 to BE-24
- **Blocks**: BE-26 (GRN needs suppliers), BE-27
- **Estimated Duration**: 1-2 days
- **Complexity**: Low-Medium

## Goal

Build supplier (vendor) management: tenant-scoped supplier directory, contact information, performance tracking (delivery times, expiry quality), categorization, status management (active/inactive/blacklisted), import/export, and integration hooks for GRN.

## Why This Phase Matters

GRN module (BE-26) needs suppliers:
- Track who delivered what when
- Vendor accountability for short-shelf-life items
- Communication channels (email, phone)
- Performance metrics for negotiation
- Compliance (vendor verification)

## Prerequisites

- [ ] BE-01 to BE-24 completed
- [ ] Multi-tenancy working

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/suppliers.ts` | Suppliers table |
| `server/src/db/schema/supplier_contacts.ts` | Multiple contacts |
| `server/src/db/schema/supplier_performance.ts` | Metrics |
| `server/src/modules/suppliers/suppliers.module.ts` | Module |
| `server/src/modules/suppliers/suppliers.controller.ts` | Endpoints |
| `server/src/modules/suppliers/suppliers.service.ts` | Business logic |
| `server/src/modules/suppliers/services/supplier-performance.service.ts` | Metrics |
| `server/src/modules/suppliers/services/supplier-import.service.ts` | Bulk import |
| `server/src/modules/suppliers/repositories/suppliers.repository.ts` | Data access |
| `server/src/modules/suppliers/repositories/supplier-contacts.repository.ts` | Contacts |
| `server/src/modules/suppliers/dto/create-supplier.dto.ts` | DTOs |
| `server/src/modules/suppliers/dto/update-supplier.dto.ts` | DTOs |
| `server/src/modules/suppliers/dto/list-suppliers.dto.ts` | DTOs |
| `server/src/modules/suppliers/dto/import-suppliers.dto.ts` | DTOs |
| `server/src/modules/suppliers/types/supplier.types.ts` | Types |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/suppliers/suppliers.service.ts

export interface ISuppliersService {
  // CRUD
  create(dto: CreateSupplierDto, userId: string): Promise<Supplier>;
  findById(id: string): Promise<SupplierWithContacts | null>;
  list(filters: ListSuppliersDto): Promise<PaginatedResult<Supplier>>;
  update(id: string, dto: UpdateSupplierDto, userId: string): Promise<Supplier>;
  delete(id: string, userId: string): Promise<void>;
  
  // Status
  activate(id: string, userId: string): Promise<Supplier>;
  deactivate(id: string, userId: string): Promise<Supplier>;
  blacklist(id: string, reason: string, userId: string): Promise<Supplier>;
  
  // Contacts
  addContact(supplierId: string, dto: AddContactDto): Promise<SupplierContact>;
  removeContact(contactId: string): Promise<void>;
  
  // Search
  search(query: string, filters?: any): Promise<Supplier[]>;
  
  // Performance
  getPerformance(supplierId: string): Promise<SupplierPerformance>;
  updatePerformance(supplierId: string, metrics: PerformanceMetrics): Promise<void>;
  
  // Import/Export
  bulkImport(file: Buffer, userId: string): Promise<ImportResult>;
  exportAll(format: 'xlsx' | 'csv'): Promise<Buffer>;
}

export type SupplierStatus = 'active' | 'inactive' | 'blacklisted' | 'pending';

export interface CreateSupplierDto {
  name: string;
  legalName?: string;
  gstNumber?: string;
  panNumber?: string;
  category?: string;
  description?: string;
  
  // Contact
  email?: string;
  phone?: string;
  alternatePhone?: string;
  whatsappNumber?: string;
  
  // Address
  addressLine1?: string;
  addressLine2?: string;
  city?: string;
  state?: string;
  pincode?: string;
  country?: string;
  
  // Business
  paymentTerms?: string;
  deliveryDays?: number;
  minimumOrderAmount?: number;
  
  metadata?: Record<string, unknown>;
}

export interface SupplierWithContacts extends Supplier {
  contacts: SupplierContact[];
  performance?: SupplierPerformance;
}

export interface AddContactDto {
  name: string;
  designation?: string;
  email?: string;
  phone?: string;
  isPrimary?: boolean;
}

export interface SupplierPerformance {
  supplierId: string;
  totalGrns: number;
  averageDeliveryDays: number;
  avgExpiryRemainingDays: number;
  shortShelfLifeIncidents: number;  // Items < 30 days remaining at delivery
  qualityScore: number;              // 0-100
  reliabilityScore: number;          // 0-100
  lastDeliveryDate?: Date;
  totalAmountDelivered?: number;
}

export interface PerformanceMetrics {
  grnId: string;
  deliveryDays: number;
  expiryRemainingDays: number;
  shortShelfLife: boolean;
  amount?: number;
}

export interface ListSuppliersDto {
  q?: string;
  status?: SupplierStatus[];
  category?: string;
  city?: string;
  cursor?: string;
  limit?: number;
}

export interface ImportResult {
  totalRows: number;
  imported: number;
  skipped: number;
  failed: number;
  errors: Array<{ row: number; error: string }>;
}
```

## Implementation Code

### 1. Suppliers Schema

```typescript
// server/src/db/schema/suppliers.ts
import { pgTable, varchar, uuid, integer, decimal, timestamp, jsonb, pgEnum, index, unique } from 'drizzle-orm/pg-core';
import { baseColumns, softDeleteColumn, auditColumns } from './_base';

export const supplierStatusEnum = pgEnum('supplier_status', [
  'active',
  'inactive',
  'blacklisted',
  'pending',
]);

export const suppliers = pgTable(
  'suppliers',
  {
    ...baseColumns,
    ...softDeleteColumn,
    ...auditColumns,
    tenantId: uuid('tenant_id').notNull(),
    
    // Identity
    name: varchar('name', { length: 200 }).notNull(),
    legalName: varchar('legal_name', { length: 200 }),
    code: varchar('code', { length: 50 }),
    
    // Indian compliance
    gstNumber: varchar('gst_number', { length: 15 }),
    panNumber: varchar('pan_number', { length: 10 }),
    
    // Classification
    category: varchar('category', { length: 100 }),
    description: varchar('description', { length: 1000 }),
    
    // Status
    status: supplierStatusEnum('status').notNull().default('pending'),
    blacklistReason: varchar('blacklist_reason', { length: 500 }),
    blacklistedAt: timestamp('blacklisted_at', { withTimezone: true }),
    
    // Primary contact
    email: varchar('email', { length: 255 }),
    phone: varchar('phone', { length: 20 }),
    alternatePhone: varchar('alternate_phone', { length: 20 }),
    whatsappNumber: varchar('whatsapp_number', { length: 20 }),
    
    // Address
    addressLine1: varchar('address_line_1', { length: 255 }),
    addressLine2: varchar('address_line_2', { length: 255 }),
    city: varchar('city', { length: 100 }),
    state: varchar('state', { length: 100 }),
    pincode: varchar('pincode', { length: 10 }),
    country: varchar('country', { length: 2 }).default('IN'),
    
    // Business terms
    paymentTerms: varchar('payment_terms', { length: 100 }), // e.g., "Net 30", "COD"
    deliveryDays: integer('delivery_days'),
    minimumOrderAmount: decimal('minimum_order_amount', { precision: 12, scale: 2 }),
    
    // Performance (denormalized for fast queries)
    totalGrns: integer('total_grns').notNull().default(0),
    averageDeliveryDays: decimal('average_delivery_days', { precision: 5, scale: 2 }),
    qualityScore: integer('quality_score'),     // 0-100
    reliabilityScore: integer('reliability_score'), // 0-100
    lastDeliveryDate: timestamp('last_delivery_date', { withTimezone: true }),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    tenantIdx: index('idx_suppliers_tenant').on(table.tenantId),
    tenantStatusIdx: index('idx_suppliers_tenant_status').on(table.tenantId, table.status),
    nameIdx: index('idx_suppliers_name').on(table.name),
    cityIdx: index('idx_suppliers_city').on(table.city),
    gstIdx: index('idx_suppliers_gst').on(table.gstNumber),
    uniqueTenantCode: unique('uniq_suppliers_tenant_code').on(table.tenantId, table.code),
  }),
);

export type Supplier = typeof suppliers.$inferSelect;
export type NewSupplier = typeof suppliers.$inferInsert;
```

### 2. Supplier Contacts

```typescript
// server/src/db/schema/supplier_contacts.ts
import { pgTable, varchar, uuid, boolean, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';
import { suppliers } from './suppliers';

export const supplierContacts = pgTable(
  'supplier_contacts',
  {
    ...baseColumns,
    supplierId: uuid('supplier_id').notNull().references(() => suppliers.id, { onDelete: 'cascade' }),
    name: varchar('name', { length: 100 }).notNull(),
    designation: varchar('designation', { length: 100 }),
    email: varchar('email', { length: 255 }),
    phone: varchar('phone', { length: 20 }),
    isPrimary: boolean('is_primary').notNull().default(false),
    notes: varchar('notes', { length: 500 }),
  },
  (table) => ({
    supplierIdx: index('idx_supplier_contacts_supplier').on(table.supplierId),
    primaryIdx: index('idx_supplier_contacts_primary').on(table.supplierId, table.isPrimary),
  }),
);

export type SupplierContact = typeof supplierContacts.$inferSelect;
```

### 3. Suppliers Service

```typescript
// server/src/modules/suppliers/suppliers.service.ts
import { Injectable } from '@nestjs/common';
import { SuppliersRepository } from './repositories/suppliers.repository';
import { SupplierContactsRepository } from './repositories/supplier-contacts.repository';
import { SupplierPerformanceService } from './services/supplier-performance.service';
import { DbService } from '../../db/db.service';
import { AuditLogService } from '../../observability/audit-log.service';
import {
  ISuppliersService,
  CreateSupplierDto,
  UpdateSupplierDto,
  SupplierWithContacts,
  AddContactDto,
} from './types/supplier.types';
import {
  NotFoundException,
  ValidationException,
} from '../../common/errors/business.exception';

@Injectable()
export class SuppliersService implements ISuppliersService {
  constructor(
    private readonly db: DbService,
    private readonly repo: SuppliersRepository,
    private readonly contactsRepo: SupplierContactsRepository,
    private readonly performanceService: SupplierPerformanceService,
    private readonly auditLog: AuditLogService,
  ) {}

  async create(dto: CreateSupplierDto, userId: string): Promise<Supplier> {
    // Validate GST format if provided
    if (dto.gstNumber && !this.isValidGst(dto.gstNumber)) {
      throw new ValidationException('Invalid GST number format', {
        field: 'gstNumber',
        value: dto.gstNumber,
      });
    }
    
    // Validate PAN format
    if (dto.panNumber && !this.isValidPan(dto.panNumber)) {
      throw new ValidationException('Invalid PAN format', {
        field: 'panNumber',
      });
    }
    
    // Generate code if not provided
    const code = dto.code || await this.generateCode(dto.name);
    
    return this.db.transaction(async (tx) => {
      const supplier = await this.repo.create({
        ...dto,
        code,
        status: 'active',
      }, tx);
      
      await this.auditLog.logAction({
        action: 'CREATE',
        resourceType: 'Supplier',
        resourceId: supplier.id,
        userId,
        tenantId: supplier.tenantId,
        success: true,
      });
      
      return supplier;
    });
  }

  async findById(id: string): Promise<SupplierWithContacts | null> {
    const supplier = await this.repo.findById(id);
    if (!supplier) return null;
    
    const contacts = await this.contactsRepo.findBySupplier(id);
    const performance = await this.performanceService.getPerformance(id);
    
    return {
      ...supplier,
      contacts,
      performance,
    };
  }

  async list(filters: any): Promise<any> {
    return this.repo.findPaginated(filters, {
      cursor: filters.cursor,
      limit: filters.limit || 50,
      orderBy: [{ field: 'name', direction: 'asc' }],
    });
  }

  async update(id: string, dto: UpdateSupplierDto, userId: string): Promise<Supplier> {
    const updated = await this.repo.update(id, dto);
    
    await this.auditLog.logAction({
      action: 'UPDATE',
      resourceType: 'Supplier',
      resourceId: id,
      userId,
      tenantId: updated.tenantId,
      success: true,
    });
    
    return updated;
  }

  async delete(id: string, userId: string): Promise<void> {
    await this.repo.softDelete(id, userId);
    
    await this.auditLog.logAction({
      action: 'DELETE',
      resourceType: 'Supplier',
      resourceId: id,
      userId,
      tenantId: 'tenant-id',
      success: true,
    });
  }

  async activate(id: string, userId: string): Promise<Supplier> {
    return this.repo.update(id, { status: 'active' });
  }

  async deactivate(id: string, userId: string): Promise<Supplier> {
    return this.repo.update(id, { status: 'inactive' });
  }

  async blacklist(id: string, reason: string, userId: string): Promise<Supplier> {
    const updated = await this.repo.update(id, {
      status: 'blacklisted',
      blacklistReason: reason,
      blacklistedAt: new Date(),
    });
    
    await this.auditLog.logAction({
      action: 'UPDATE',
      resourceType: 'Supplier',
      resourceId: id,
      userId,
      tenantId: updated.tenantId,
      success: true,
      metadata: { action: 'blacklist', reason },
    });
    
    return updated;
  }

  async addContact(supplierId: string, dto: AddContactDto): Promise<SupplierContact> {
    // If marked primary, unset others
    if (dto.isPrimary) {
      await this.contactsRepo.unsetPrimaryForSupplier(supplierId);
    }
    
    return this.contactsRepo.create({
      supplierId,
      ...dto,
    });
  }

  async removeContact(contactId: string): Promise<void> {
    await this.contactsRepo.delete(contactId);
  }

  async search(query: string, filters?: any): Promise<Supplier[]> {
    return this.repo.search(query, filters);
  }

  async getPerformance(supplierId: string): Promise<any> {
    return this.performanceService.getPerformance(supplierId);
  }

  async updatePerformance(supplierId: string, metrics: any): Promise<void> {
    await this.performanceService.updateMetrics(supplierId, metrics);
  }

  async bulkImport(file: Buffer, userId: string): Promise<any> {
    // Implementation would use BE-15 patterns for Excel/CSV parsing
    throw new Error('Implement bulk import');
  }

  async exportAll(format: 'xlsx' | 'csv'): Promise<Buffer> {
    // Implementation would use BE-21 export patterns
    throw new Error('Implement export');
  }

  private isValidGst(gst: string): boolean {
    return /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/.test(gst);
  }

  private isValidPan(pan: string): boolean {
    return /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(pan);
  }

  private async generateCode(name: string): Promise<string> {
    const prefix = name.replace(/[^A-Z0-9]/gi, '').slice(0, 4).toUpperCase();
    const timestamp = Date.now().toString().slice(-4);
    return `SUP-${prefix}-${timestamp}`;
  }
}
```

### 4. Supplier Performance Service

```typescript
// server/src/modules/suppliers/services/supplier-performance.service.ts
import { Injectable } from '@nestjs/common';
import { SuppliersRepository } from '../repositories/suppliers.repository';
import { DbService } from '../../../db/db.service';
import { sql } from 'drizzle-orm';
import { SupplierPerformance, PerformanceMetrics } from '../types/supplier.types';

@Injectable()
export class SupplierPerformanceService {
  constructor(
    private readonly db: DbService,
    private readonly repo: SuppliersRepository,
  ) {}

  async getPerformance(supplierId: string): Promise<SupplierPerformance> {
    const supplier = await this.repo.findById(supplierId);
    if (!supplier) throw new Error('Supplier not found');
    
    // Get aggregated stats from grn_headers (BE-26 will populate)
    const result = await this.db.getDb().execute(sql`
      SELECT 
        COUNT(*) as total_grns,
        AVG(EXTRACT(EPOCH FROM (inward_date - order_date))/86400) as avg_delivery_days,
        AVG(min_expiry_remaining_days) as avg_expiry_remaining,
        SUM(CASE WHEN min_expiry_remaining_days < 30 THEN 1 ELSE 0 END) as short_shelf_life_count,
        MAX(inward_date) as last_delivery
      FROM grn_headers
      WHERE supplier_id = ${supplierId}
        AND status = 'posted'
    `);
    
    const row = (result.rows[0] || {}) as any;
    
    const totalGrns = Number(row.total_grns || 0);
    const shortShelfLife = Number(row.short_shelf_life_count || 0);
    
    // Calculate scores
    const reliabilityScore = totalGrns > 0
      ? Math.max(0, 100 - Math.round((shortShelfLife / totalGrns) * 100))
      : 50;
    
    const qualityScore = supplier.qualityScore || 75;
    
    return {
      supplierId,
      totalGrns,
      averageDeliveryDays: Number(row.avg_delivery_days || 0),
      avgExpiryRemainingDays: Number(row.avg_expiry_remaining || 0),
      shortShelfLifeIncidents: shortShelfLife,
      qualityScore,
      reliabilityScore,
      lastDeliveryDate: row.last_delivery,
    };
  }

  async updateMetrics(supplierId: string, metrics: PerformanceMetrics): Promise<void> {
    // Update denormalized fields on supplier
    const supplier = await this.repo.findById(supplierId);
    if (!supplier) return;
    
    const newTotalGrns = supplier.totalGrns + 1;
    const oldAvg = Number(supplier.averageDeliveryDays || 0);
    const newAvg = (oldAvg * supplier.totalGrns + metrics.deliveryDays) / newTotalGrns;
    
    await this.repo.update(supplierId, {
      totalGrns: newTotalGrns,
      averageDeliveryDays: newAvg.toString(),
      lastDeliveryDate: new Date(),
    });
  }
}
```

### 5. DTOs

```typescript
// server/src/modules/suppliers/dto/create-supplier.dto.ts
import { z } from 'zod';

export const CreateSupplierSchema = z.object({
  name: z.string().min(1).max(200),
  legalName: z.string().max(200).optional(),
  code: z.string().max(50).optional(),
  gstNumber: z.string()
    .regex(/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/, 'Invalid GST format')
    .optional(),
  panNumber: z.string()
    .regex(/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/, 'Invalid PAN format')
    .optional(),
  category: z.string().max(100).optional(),
  description: z.string().max(1000).optional(),
  
  email: z.string().email().optional(),
  phone: z.string().max(20).optional(),
  alternatePhone: z.string().max(20).optional(),
  whatsappNumber: z.string().regex(/^[6-9]\d{9}$/).optional(),
  
  addressLine1: z.string().max(255).optional(),
  addressLine2: z.string().max(255).optional(),
  city: z.string().max(100).optional(),
  state: z.string().max(100).optional(),
  pincode: z.string().regex(/^\d{6}$/).optional(),
  country: z.string().length(2).default('IN'),
  
  paymentTerms: z.string().max(100).optional(),
  deliveryDays: z.number().int().min(0).max(365).optional(),
  minimumOrderAmount: z.number().min(0).optional(),
  
  metadata: z.record(z.unknown()).optional(),
});

export type CreateSupplierDto = z.infer<typeof CreateSupplierSchema>;
```

## API Endpoints

| Method | Endpoint | Auth | Role | Purpose |
|---|---|---|---|---|
| POST | `/api/v1/suppliers` | Bearer | Manager+ | Create |
| GET | `/api/v1/suppliers` | Bearer | Staff+ | List |
| GET | `/api/v1/suppliers/:id` | Bearer | Staff+ | Get details |
| PATCH | `/api/v1/suppliers/:id` | Bearer | Manager+ | Update |
| DELETE | `/api/v1/suppliers/:id` | Bearer | Manager+ | Soft delete |
| POST | `/api/v1/suppliers/:id/activate` | Bearer | Manager+ | Activate |
| POST | `/api/v1/suppliers/:id/deactivate` | Bearer | Manager+ | Deactivate |
| POST | `/api/v1/suppliers/:id/blacklist` | Bearer | Manager+ | Blacklist |
| POST | `/api/v1/suppliers/:id/contacts` | Bearer | Manager+ | Add contact |
| DELETE | `/api/v1/suppliers/contacts/:id` | Bearer | Manager+ | Remove contact |
| GET | `/api/v1/suppliers/:id/performance` | Bearer | Manager+ | Performance |
| POST | `/api/v1/suppliers/import` | Bearer | Manager+ | Bulk import |
| GET | `/api/v1/suppliers/export` | Bearer | Manager+ | Export all |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-26 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Create Supplier ✅
**Pass Criteria**: ✅ Supplier created with auto-generated code

### Test 2: GST Validation ✅
Invalid GST → 400
Valid GST (15 chars, format) → 201
**Pass Criteria**: ✅ GST regex enforced

### Test 3: PAN Validation ✅
Invalid PAN → 400
Valid PAN (10 chars, format) → 201
**Pass Criteria**: ✅ PAN regex enforced

### Test 4: Multiple Contacts ✅
Add 3 contacts to supplier:
**Expected**: All saved, only one primary
**Pass Criteria**: ✅ Multi-contact works

### Test 5: Primary Contact ✅
Set new contact as primary:
**Expected**: Old primary unset, new is primary
**Pass Criteria**: ✅ Primary uniqueness enforced

### Test 6: Status Transitions ✅
- active → inactive ✅
- active → blacklisted (with reason) ✅
- blacklisted → active (admin override) ✅
**Pass Criteria**: ✅ All transitions work

### Test 7: Search ✅
```bash
curl ".../suppliers?q=Acme&category=dairy"
```
**Expected**: Filtered results
**Pass Criteria**: ✅ Search works

### Test 8: Performance Metrics ✅
After GRNs created (BE-26):
**Expected**: Performance data calculated
**Pass Criteria**: ✅ Metrics aggregated

### Test 9: Tenant Isolation ✅
**Pass Criteria**: ✅ Cross-tenant blocked

### Test 10: Code Uniqueness ✅
Two suppliers with same code in same tenant: → 409
Same code in different tenant: → OK
**Pass Criteria**: ✅ Tenant-scoped uniqueness

### Test 11: Soft Delete ✅
**Pass Criteria**: ✅ deletedAt set, hidden from list

### Test 12: Bulk Import ✅
Upload CSV with 100 suppliers:
**Pass Criteria**: ✅ All imported, errors per row

### Test 13: Export ✅
**Pass Criteria**: ✅ XLSX/CSV with all suppliers

### Test 14: Audit Trail ✅
**Pass Criteria**: ✅ All changes logged

### Test 15: Validation Errors ✅
- Empty name → 400
- Invalid pincode → 400
- Invalid mobile → 400
**Pass Criteria**: ✅ All validations work

## 🎯 Q&A Session

### Q1: Why store GST/PAN?
**Expected**: Indian compliance, tax filing, vendor verification, government audits

### Q2: Why multiple contacts per supplier?
**Expected**: Real businesses have multiple people (sales, accounting, delivery)

### Q3: Why denormalize performance on supplier?
**Expected**: Fast list queries, dashboard performance, recalculated periodically

### Q4: Why blacklist vs delete?
**Expected**: Audit trail, prevent re-adding accidentally, compliance

### Q5: Why supplier code?
**Expected**: User-friendly identifier, easier than UUID in conversations

### Q6: How to handle duplicate suppliers?
**Expected**: Code uniqueness, GST uniqueness check, search before create

### Q7: Why per-tenant suppliers?
**Expected**: Each retail business has different vendors, isolation, privacy

### Q8: How to track supplier accountability?
**Expected**: Performance metrics, short-shelf-life count, GRN history, scoring

## 📝 Sign-Off Checklist

- [ ] All 15 tests pass
- [ ] GST/PAN validation works
- [ ] Multiple contacts work
- [ ] Status transitions work
- [ ] Tenant isolation verified
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-26**
**☐ CHANGES REQUESTED**

---

**END OF BE-25 — DO NOT PROCEED WITHOUT APPROVAL**
