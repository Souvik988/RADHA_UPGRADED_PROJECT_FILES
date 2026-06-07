# Phase BE-10: Product Catalog & EAN Lookup

## Phase Metadata

- **Phase ID**: BE-10
- **Phase Name**: Product Catalog & EAN Lookup
- **Section**: Backend Execution — Core Product Layer
- **Depends On**: BE-01 to BE-09
- **Blocks**: BE-11, BE-12, BE-13, BE-14, BE-15, BE-16
- **Estimated Duration**: 2-3 days
- **Complexity**: Medium-High

## Goal

Implement the foundational product catalog with: EAN lookup (cached + fallback ready for BE-11), product CRUD with validation, EAN format validation (EAN-8, EAN-13, UPC-A, UPC-E), product categories taxonomy, image URL management, manufacturer info, packaging info, and search-ready data structures.

## Why This Phase Matters

Products are the **central entity** in RADHA. Every scan, expiry record, GRN line item, inventory entry, and report references products.

Without proper product catalog:
- Scans fail to identify products
- Expiry tracking impossible
- Inventory counts useless
- Reports lack context
- User experience is broken (just barcodes, no names)

## Prerequisites

- [ ] BE-01 to BE-09 completed
- [ ] Multi-tenancy infrastructure ready
- [ ] Database health check working
- [ ] Repository pattern established

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/products.ts` | Products table |
| `server/src/db/schema/product_categories.ts` | Category taxonomy |
| `server/src/db/schema/product_nutrition.ts` | Nutrition data |
| `server/src/db/schema/product_sources.ts` | Data source tracking |
| `server/src/modules/products/products.module.ts` | Products module |
| `server/src/modules/products/products.controller.ts` | Product endpoints |
| `server/src/modules/products/products.service.ts` | Product business logic |
| `server/src/modules/products/products.repository.ts` | Product data (tenant-scoped) |
| `server/src/modules/products/services/product-lookup.service.ts` | EAN lookup orchestration |
| `server/src/modules/products/services/product-validator.service.ts` | EAN format validation |
| `server/src/modules/products/services/product-categories.service.ts` | Categories |
| `server/src/modules/products/repositories/product-nutrition.repository.ts` | Nutrition data |
| `server/src/modules/products/repositories/product-categories.repository.ts` | Categories |
| `server/src/modules/products/dto/create-product.dto.ts` | DTOs |
| `server/src/modules/products/dto/update-product.dto.ts` | DTOs |
| `server/src/modules/products/dto/product-lookup-query.dto.ts` | DTOs |
| `server/src/modules/products/dto/product-search-query.dto.ts` | DTOs |
| `server/src/modules/products/utils/ean.utils.ts` | EAN validation/normalization |
| `server/src/modules/products/utils/category.utils.ts` | Category helpers |
| `server/src/modules/products/constants/product-categories.constants.ts` | Predefined categories |
| `server/src/modules/products/types/product.types.ts` | Type definitions |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/products/services/product-lookup.service.ts

export interface IProductLookupService {
  // Main lookup with fallback chain
  lookupByEan(
    ean: string,
    options?: LookupOptions,
  ): Promise<ProductLookupResult>;
  
  // Multiple EANs in one call
  lookupBatch(eans: string[]): Promise<Map<string, ProductLookupResult>>;
  
  // Force refresh from external sources
  refreshProduct(productId: string): Promise<Product>;
}

// server/src/modules/products/products.service.ts

export interface IProductsService {
  // CRUD
  create(dto: CreateProductDto, userId: string): Promise<Product>;
  findById(id: string): Promise<ProductWithDetails>;
  update(id: string, dto: UpdateProductDto, userId: string): Promise<Product>;
  delete(id: string, userId: string): Promise<void>;
  
  // EAN-specific
  findByEan(ean: string): Promise<ProductWithDetails | null>;
  lookupByEan(ean: string, options?: LookupOptions): Promise<ProductLookupResult>;
  
  // Search & List
  search(query: ProductSearchQuery): Promise<PaginatedResult<Product>>;
  listByCategory(category: string, pagination: PaginationParams): Promise<PaginatedResult<Product>>;
  
  // Bulk
  bulkCreate(dtos: CreateProductDto[], userId: string): Promise<BulkCreateResult>;
  
  // Categories
  listCategories(): Promise<ProductCategory[]>;
}

export interface LookupOptions {
  includeNutrition?: boolean;
  includeHealth?: boolean;
  forceRefresh?: boolean;
  fallbackToExternal?: boolean;
}

export interface ProductLookupResult {
  found: boolean;
  product?: ProductWithDetails;
  source: 'database' | 'open-food-facts' | 'manual' | 'cached';
  cached: boolean;
  externalApiCalled: boolean;
  durationMs: number;
}

export interface ProductWithDetails extends Product {
  nutrition?: ProductNutrition | null;
  healthAssessment?: ProductHealthAssessment | null;
  category?: ProductCategory;
}

export interface BulkCreateResult {
  successful: Product[];
  failed: { dto: CreateProductDto; error: string }[];
  totalSuccess: number;
  totalFailed: number;
}
```

## Implementation Code

### 1. Products Schema

```typescript
// server/src/db/schema/products.ts
import { pgTable, varchar, uuid, boolean, timestamp, jsonb, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns, softDeleteColumn, auditColumns, tenantScopeColumn } from './_base';

export const productStatusEnum = pgEnum('product_status', [
  'active',
  'discontinued',
  'pending_review',
  'rejected',
]);

export const products = pgTable(
  'products',
  {
    ...baseColumns,
    ...softDeleteColumn,
    ...auditColumns,
    tenantId: uuid('tenant_id').notNull(),
    
    // Identity
    ean: varchar('ean', { length: 13 }).notNull(),
    name: varchar('name', { length: 200 }).notNull(),
    brand: varchar('brand', { length: 100 }),
    manufacturer: varchar('manufacturer', { length: 200 }),
    
    // Classification
    categoryId: uuid('category_id'),
    subCategory: varchar('sub_category', { length: 100 }),
    productType: varchar('product_type', { length: 50 }),
    
    // Display
    imageUrl: varchar('image_url', { length: 500 }),
    description: varchar('description', { length: 1000 }),
    
    // Packaging
    packageSize: varchar('package_size', { length: 50 }),
    packageUnit: varchar('package_unit', { length: 20 }),
    packageType: varchar('package_type', { length: 50 }),
    
    // Status
    status: productStatusEnum('status').notNull().default('active'),
    isVerified: boolean('is_verified').notNull().default(false),
    
    // Source tracking
    dataSource: varchar('data_source', { length: 50 }).default('manual'),
    externalId: varchar('external_id', { length: 100 }),
    
    // Search
    searchVector: varchar('search_vector', { length: 1000 }),
    
    // Metadata
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    eanIdx: index('idx_products_ean').on(table.ean),
    tenantEanIdx: index('idx_products_tenant_ean').on(table.tenantId, table.ean),
    tenantCategoryIdx: index('idx_products_tenant_category').on(table.tenantId, table.categoryId),
    brandIdx: index('idx_products_brand').on(table.brand),
    nameIdx: index('idx_products_name').on(table.name),
    statusIdx: index('idx_products_tenant_status').on(table.tenantId, table.status),
  }),
);

export type Product = typeof products.$inferSelect;
export type NewProduct = typeof products.$inferInsert;
```

### 2. Product Nutrition Schema

```typescript
// server/src/db/schema/product_nutrition.ts
import { pgTable, uuid, decimal, varchar, jsonb, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';
import { products } from './products';

export const productNutrition = pgTable(
  'product_nutrition',
  {
    ...baseColumns,
    productId: uuid('product_id').notNull().references(() => products.id, { onDelete: 'cascade' }),
    
    // Per 100g/100ml
    servingSize: decimal('serving_size', { precision: 10, scale: 2 }),
    servingUnit: varchar('serving_unit', { length: 10 }), // g, ml
    
    // Macros (per serving)
    calories: decimal('calories', { precision: 8, scale: 2 }),
    protein: decimal('protein', { precision: 8, scale: 2 }),
    carbohydrates: decimal('carbohydrates', { precision: 8, scale: 2 }),
    sugars: decimal('sugars', { precision: 8, scale: 2 }),
    fat: decimal('fat', { precision: 8, scale: 2 }),
    saturatedFat: decimal('saturated_fat', { precision: 8, scale: 2 }),
    transFat: decimal('trans_fat', { precision: 8, scale: 2 }),
    fiber: decimal('fiber', { precision: 8, scale: 2 }),
    sodium: decimal('sodium', { precision: 8, scale: 2 }), // mg
    
    // Indicators
    containsAllergens: jsonb('contains_allergens').default([]),
    isProcessed: varchar('is_processed', { length: 20 }), // not, lightly, ultra
    
    // Metadata
    dataSource: varchar('data_source', { length: 50 }).default('manual'),
    confidence: decimal('confidence', { precision: 3, scale: 2 }), // 0-1
  },
  (table) => ({
    productIdx: index('idx_nutrition_product').on(table.productId),
  }),
);

export type ProductNutrition = typeof productNutrition.$inferSelect;
```

### 3. EAN Validation Utility

```typescript
// server/src/modules/products/utils/ean.utils.ts

export type EanFormat = 'EAN-8' | 'EAN-13' | 'UPC-A' | 'UPC-E' | 'INVALID';

export function detectEanFormat(ean: string): EanFormat {
  const cleaned = ean.replace(/\D/g, '');
  
  if (cleaned.length === 8) return 'EAN-8';
  if (cleaned.length === 13) return 'EAN-13';
  if (cleaned.length === 12) return 'UPC-A';
  if (cleaned.length === 6) return 'UPC-E';
  return 'INVALID';
}

export function validateEan(ean: string): { valid: boolean; format: EanFormat; error?: string } {
  const cleaned = ean.replace(/\D/g, '');
  const format = detectEanFormat(cleaned);
  
  if (format === 'INVALID') {
    return {
      valid: false,
      format,
      error: `Invalid EAN length: ${cleaned.length}. Expected 8, 12, or 13 digits.`,
    };
  }
  
  // Check digit validation for EAN-13
  if (format === 'EAN-13') {
    const checkDigit = calculateEan13CheckDigit(cleaned.slice(0, 12));
    if (parseInt(cleaned[12]) !== checkDigit) {
      return {
        valid: false,
        format,
        error: 'Invalid EAN-13 check digit',
      };
    }
  }
  
  // Check digit validation for EAN-8
  if (format === 'EAN-8') {
    const checkDigit = calculateEan8CheckDigit(cleaned.slice(0, 7));
    if (parseInt(cleaned[7]) !== checkDigit) {
      return {
        valid: false,
        format,
        error: 'Invalid EAN-8 check digit',
      };
    }
  }
  
  return { valid: true, format };
}

export function normalizeEan(ean: string): string {
  const cleaned = ean.replace(/\D/g, '');
  
  // Convert UPC-A (12 digits) to EAN-13 by prepending '0'
  if (cleaned.length === 12) {
    return '0' + cleaned;
  }
  
  // Expand UPC-E (6) to UPC-A (12) → EAN-13 (13)
  if (cleaned.length === 6) {
    const upcA = expandUpcE(cleaned);
    return '0' + upcA;
  }
  
  return cleaned;
}

function calculateEan13CheckDigit(first12: string): number {
  let sum = 0;
  for (let i = 0; i < 12; i++) {
    const digit = parseInt(first12[i]);
    sum += i % 2 === 0 ? digit : digit * 3;
  }
  return (10 - (sum % 10)) % 10;
}

function calculateEan8CheckDigit(first7: string): number {
  let sum = 0;
  for (let i = 0; i < 7; i++) {
    const digit = parseInt(first7[i]);
    sum += i % 2 === 0 ? digit * 3 : digit;
  }
  return (10 - (sum % 10)) % 10;
}

function expandUpcE(upcE: string): string {
  // UPC-E to UPC-A expansion algorithm
  const last = upcE[5];
  const first5 = upcE.slice(0, 5);
  
  if (last === '0' || last === '1' || last === '2') {
    return `0${first5.slice(0, 2)}${last}0000${first5.slice(2)}`;
  } else if (last === '3') {
    return `0${first5.slice(0, 3)}00000${first5.slice(3)}`;
  } else if (last === '4') {
    return `0${first5.slice(0, 4)}00000${first5.slice(4)}`;
  } else {
    return `0${first5}0000${last}`;
  }
}
```

### 4. Product Lookup Service

```typescript
// server/src/modules/products/services/product-lookup.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ProductsRepository } from '../products.repository';
import { ProductNutritionRepository } from '../repositories/product-nutrition.repository';
import { LoggerService } from '../../../logging/logger.service';
import {
  IProductLookupService,
  ProductLookupResult,
  LookupOptions,
} from '../types/product.types';
import { normalizeEan, validateEan } from '../utils/ean.utils';
import { ValidationException } from '../../../common/errors/business.exception';

@Injectable()
export class ProductLookupService implements IProductLookupService {
  private readonly logger = new Logger(ProductLookupService.name);

  constructor(
    private readonly productsRepo: ProductsRepository,
    private readonly nutritionRepo: ProductNutritionRepository,
    private readonly appLogger: LoggerService,
  ) {}

  async lookupByEan(
    ean: string,
    options: LookupOptions = {},
  ): Promise<ProductLookupResult> {
    const startTime = Date.now();

    // 1. Validate EAN format
    const validation = validateEan(ean);
    if (!validation.valid) {
      throw new ValidationException(validation.error || 'Invalid EAN', {
        field: 'ean',
        value: ean,
      });
    }

    const normalizedEan = normalizeEan(ean);

    // 2. Try local database first (tenant-scoped)
    const product = await this.productsRepo.findByEan(normalizedEan);
    
    if (product && !options.forceRefresh) {
      const enriched = await this.enrichProduct(product, options);
      return {
        found: true,
        product: enriched,
        source: 'database',
        cached: false,
        externalApiCalled: false,
        durationMs: Date.now() - startTime,
      };
    }

    // 3. Fallback to external sources (BE-11 will implement)
    if (options.fallbackToExternal !== false) {
      // BE-11 will inject OpenFoodFactsService here
      this.appLogger.info('External lookup not yet implemented (BE-11)', {
        ean: normalizedEan,
      });
    }

    return {
      found: false,
      source: 'database',
      cached: false,
      externalApiCalled: false,
      durationMs: Date.now() - startTime,
    };
  }

  async lookupBatch(eans: string[]): Promise<Map<string, ProductLookupResult>> {
    const results = new Map<string, ProductLookupResult>();
    
    // Validate and normalize all EANs
    const validEans = eans
      .map((ean) => ({ original: ean, normalized: normalizeEan(ean), validation: validateEan(ean) }))
      .filter((item) => item.validation.valid);

    // Batch query for valid EANs
    const products = await this.productsRepo.findManyByEans(
      validEans.map((v) => v.normalized),
    );
    
    const productMap = new Map(products.map((p) => [p.ean, p]));
    
    for (const item of validEans) {
      const product = productMap.get(item.normalized);
      if (product) {
        const enriched = await this.enrichProduct(product, {});
        results.set(item.original, {
          found: true,
          product: enriched,
          source: 'database',
          cached: false,
          externalApiCalled: false,
          durationMs: 0,
        });
      } else {
        results.set(item.original, {
          found: false,
          source: 'database',
          cached: false,
          externalApiCalled: false,
          durationMs: 0,
        });
      }
    }

    return results;
  }

  async refreshProduct(productId: string): Promise<Product> {
    // BE-11 will implement external API refresh
    const product = await this.productsRepo.findById(productId);
    if (!product) throw new Error('Product not found');
    return product;
  }

  private async enrichProduct(
    product: Product,
    options: LookupOptions,
  ): Promise<ProductWithDetails> {
    const enriched: ProductWithDetails = { ...product };

    if (options.includeNutrition !== false) {
      enriched.nutrition = await this.nutritionRepo.findByProductId(product.id);
    }

    // Health assessment will be added in BE-12
    
    return enriched;
  }
}
```

### 5. DTOs with Zod

```typescript
// server/src/modules/products/dto/create-product.dto.ts
import { z } from 'zod';

export const CreateProductSchema = z.object({
  ean: z.string()
    .regex(/^\d{8,13}$/, 'EAN must be 8-13 digits'),
  name: z.string()
    .min(1, 'Product name required')
    .max(200, 'Name too long'),
  brand: z.string().max(100).optional(),
  manufacturer: z.string().max(200).optional(),
  categoryId: z.string().uuid().optional(),
  subCategory: z.string().max(100).optional(),
  productType: z.string().max(50).optional(),
  imageUrl: z.string().url().max(500).optional(),
  description: z.string().max(1000).optional(),
  packageSize: z.string().max(50).optional(),
  packageUnit: z.enum(['g', 'kg', 'ml', 'l', 'pcs', 'pack']).optional(),
  packageType: z.string().max(50).optional(),
  
  // Optional nutrition data
  nutrition: z.object({
    servingSize: z.number().positive().optional(),
    servingUnit: z.enum(['g', 'ml']).optional(),
    calories: z.number().nonnegative().optional(),
    protein: z.number().nonnegative().optional(),
    carbohydrates: z.number().nonnegative().optional(),
    sugars: z.number().nonnegative().optional(),
    fat: z.number().nonnegative().optional(),
    saturatedFat: z.number().nonnegative().optional(),
    fiber: z.number().nonnegative().optional(),
    sodium: z.number().nonnegative().optional(),
    isProcessed: z.enum(['not', 'lightly', 'ultra']).optional(),
    containsAllergens: z.array(z.string()).optional(),
  }).optional(),
});

export type CreateProductDto = z.infer<typeof CreateProductSchema>;
```

```typescript
// server/src/modules/products/dto/product-search-query.dto.ts
import { z } from 'zod';

export const ProductSearchQuerySchema = z.object({
  q: z.string().min(1).max(100).optional(),
  category: z.string().uuid().optional(),
  brand: z.string().max(100).optional(),
  status: z.enum(['active', 'discontinued', 'pending_review']).optional(),
  isVerified: z.coerce.boolean().optional(),
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
  orderBy: z.enum(['name', 'createdAt', 'updatedAt']).default('createdAt'),
  orderDirection: z.enum(['asc', 'desc']).default('desc'),
});

export type ProductSearchQuery = z.infer<typeof ProductSearchQuerySchema>;
```

## Database Tables Affected

| Table | Created/Modified | Key Indexes |
|---|---|---|
| `products` | CREATED | ean, tenant+ean, tenant+category, brand, name, status |
| `product_nutrition` | CREATED | product_id |
| `product_categories` | CREATED | tenant+name |
| `product_sources` | CREATED | product_id, source |

## API Endpoints

| Method | Endpoint | Auth | Role | Permission | Purpose |
|---|---|---|---|---|---|
| GET | `/api/v1/products/lookup/:ean` | Bearer | Staff+ | `products:read` | EAN lookup |
| POST | `/api/v1/products/lookup/batch` | Bearer | Staff+ | `products:read` | Batch lookup |
| POST | `/api/v1/products` | Bearer | Manager+ | `products:write` | Create product |
| GET | `/api/v1/products` | Bearer | Staff+ | `products:read` | Search products |
| GET | `/api/v1/products/:id` | Bearer | Staff+ | `products:read` | Get product |
| PATCH | `/api/v1/products/:id` | Bearer | Manager+ | `products:write` | Update product |
| DELETE | `/api/v1/products/:id` | Bearer | Owner | `products:delete` | Soft delete |
| POST | `/api/v1/products/bulk` | Bearer | Manager+ | `products:bulk-import` | Bulk create |
| GET | `/api/v1/products/categories` | Bearer | Staff+ | `products:read` | List categories |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-11 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: EAN Format Validation ✅

```typescript
// Test all formats
expect(validateEan('1234567890123').valid).toBe(true); // EAN-13 valid
expect(validateEan('1234567890124').valid).toBe(false); // bad check digit
expect(validateEan('12345678').valid).toBe(true); // EAN-8 valid
expect(validateEan('123456').valid).toBe(true); // UPC-E valid
expect(validateEan('123').valid).toBe(false); // too short
```

**Pass Criteria**: ✅ Validation rejects invalid, accepts valid

---

### Test 2: EAN Normalization ✅

```typescript
expect(normalizeEan('123456789012')).toBe('0123456789012'); // UPC-A → EAN-13
expect(normalizeEan('1234567890123')).toBe('1234567890123'); // already EAN-13
expect(normalizeEan('12-34-56-78-90-12-3')).toBe('1234567890123'); // strip non-digits
```

**Pass Criteria**: ✅ Normalization works for all formats

---

### Test 3: Create Product ✅

```bash
curl -X POST http://localhost:3000/api/v1/products \
  -H "Authorization: Bearer <manager-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "ean":"8901234567890",
    "name":"Test Snack",
    "brand":"TestBrand",
    "categoryId":"<uuid>",
    "packageSize":"100",
    "packageUnit":"g",
    "nutrition":{
      "servingSize":30,
      "servingUnit":"g",
      "calories":150,
      "sugars":12,
      "fat":8
    }
  }'
```

**Expected**: 201 with new product
**Verification**: Both `products` and `product_nutrition` rows created
**Pass Criteria**: ✅ Atomic create works

---

### Test 4: EAN Lookup — Database Hit ✅

```bash
curl http://localhost:3000/api/v1/products/lookup/8901234567890 \
  -H "Authorization: Bearer <token>"
```

**Expected (200)**:
```json
{
  "data": {
    "found": true,
    "product": { "id": "...", "ean": "8901234567890", ... },
    "source": "database",
    "durationMs": <number>
  }
}
```

**Pass Criteria**: ✅ Returns product from DB

---

### Test 5: EAN Lookup — Not Found ✅

```bash
curl http://localhost:3000/api/v1/products/lookup/9999999999999 \
  -H "Authorization: Bearer <token>"
```

**Expected (200)**:
```json
{
  "data": {
    "found": false,
    "source": "database"
  }
}
```

**Note**: BE-11 will add Open Food Facts fallback
**Pass Criteria**: ✅ Returns found=false for unknown EAN

---

### Test 6: Invalid EAN Format ✅

```bash
curl http://localhost:3000/api/v1/products/lookup/abc123 \
  -H "Authorization: Bearer <token>"
```

**Expected**: 400 with VALIDATION_ERROR
**Pass Criteria**: ✅ Bad EANs rejected

---

### Test 7: Batch Lookup ✅

```bash
curl -X POST http://localhost:3000/api/v1/products/lookup/batch \
  -H "Authorization: Bearer <token>" \
  -d '{"eans":["8901234567890","9999999999999","invalid"]}'
```

**Expected**: 200 with results map for each EAN
**Pass Criteria**: ✅ Batch lookup works, mixes found/not-found

---

### Test 8: Search Products ✅

```bash
curl "http://localhost:3000/api/v1/products?q=snack&category=<uuid>&limit=20" \
  -H "Authorization: Bearer <token>"
```

**Expected**: Paginated results matching query
**Pass Criteria**: ✅ Search returns relevant results

---

### Test 9: Cross-Tenant Isolation ✅

User from Tenant A tries to lookup product from Tenant B:
```bash
curl http://localhost:3000/api/v1/products/<tenant-b-product-id> \
  -H "Authorization: Bearer <tenant-a-token>"
```

**Expected**: 404 (because TenantScopedRepository filters by tenant)
**Pass Criteria**: ✅ Cross-tenant access blocked

---

### Test 10: Update Product ✅

```bash
curl -X PATCH http://localhost:3000/api/v1/products/<id> \
  -H "Authorization: Bearer <manager-token>" \
  -d '{"name":"Updated Name"}'
```

**Expected**: 200, product updated, audit log entry
**Pass Criteria**: ✅ Update works with audit

---

### Test 11: Delete Product (Soft Delete) ✅

```bash
curl -X DELETE http://localhost:3000/api/v1/products/<id> \
  -H "Authorization: Bearer <owner-token>"
```

**Expected**: 204
**Verification**: 
- Product `deletedAt` set
- Subsequent lookup returns 404
- DB still has record (soft delete)

**Pass Criteria**: ✅ Soft delete works

---

### Test 12: Bulk Create ✅

```bash
curl -X POST http://localhost:3000/api/v1/products/bulk \
  -H "Authorization: Bearer <manager-token>" \
  -d '{"products":[{"ean":"...","name":"..."},...]}'
```

**Expected**: Returns successful + failed counts
**Pass Criteria**: ✅ Bulk operation handles partial success

---

### Test 13: Permissions ✅

Staff user tries to create product:
```bash
curl -X POST http://localhost:3000/api/v1/products \
  -H "Authorization: Bearer <staff-token>" \
  -d '{...}'
```

**Expected**: 403 INSUFFICIENT_PERMISSIONS
**Pass Criteria**: ✅ Permission check enforced

---

### Test 14: Performance ✅

```sql
EXPLAIN ANALYZE SELECT * FROM products 
WHERE tenant_id = '...' AND ean = '8901234567890' 
AND deleted_at IS NULL;
```

**Expected**: Index Scan using `idx_products_tenant_ean`, < 5ms
**Pass Criteria**: ✅ Query uses correct index

---

### Test 15: EAN Check Digit Validation ✅

```typescript
// EAN-13 with wrong check digit
expect(validateEan('1234567890124').valid).toBe(false);
expect(validateEan('1234567890124').error).toContain('check digit');

// Correct check digit
expect(validateEan('1234567890128').valid).toBe(true);
```

**Pass Criteria**: ✅ Check digit validation works

---

## 🎯 Q&A Session

### Q1: Why normalize all EANs to 13 digits?

**Expected Answer**:
- Single format simplifies storage and queries
- UPC-A (12 digits) → EAN-13 by prepending '0'
- UPC-E (6 digits) → expand to UPC-A → EAN-13
- All barcodes can be queried with same logic
- Industry standard (GS1 specs)

---

### Q2: Why both index on `ean` AND `(tenant_id, ean)`?

**Expected Answer**:
- `ean` alone: For global lookups (not tenant-aware)
- `(tenant_id, ean)`: For tenant-scoped lookups (most common)
- Composite index supports both prefix queries
- Trade-off: Storage cost vs query performance
- Critical for multi-tenant scaling

---

### Q3: Why separate nutrition table?

**Expected Answer**:
- Many products won't have nutrition data
- Avoids NULL columns in main table (storage waste)
- Allows independent updates (refresh nutrition without touching product)
- Better for queries that don't need nutrition
- Foreign key with CASCADE delete

---

### Q4: How to handle products with same EAN across tenants?

**Expected Answer**:
- Each tenant has their own version (different categorization, etc.)
- EAN globally identifies a product
- Tenant-specific data: name override, custom category, store-specific pricing
- Open Food Facts cache (BE-11) is shared (global, no tenant_id)
- Trade-off: Some duplication for tenant flexibility

---

### Q5: Why store original EAN format in `dataSource`?

**Expected Answer**:
- Audit trail of where product data came from
- Different sources have different reliability
- Allows re-fetching from same source
- Useful for debugging
- Compliance (some industries require source tracking)

---

### Q6: How does the lookup chain work?

**Expected Answer**:
1. Validate EAN format (reject invalid)
2. Normalize to EAN-13
3. Check local DB (tenant-scoped, fastest)
4. If not found, check Open Food Facts (BE-11) — global cache first
5. If not in cache, hit OFF API
6. Cache result globally + create tenant-specific copy
7. Total time: < 100ms for cached, < 3s for external

---

### Q7: Why support EAN-8 alongside EAN-13?

**Expected Answer**:
- Smaller products (chocolate bars, single chewing gum)
- Required by retail compliance
- ML Kit on mobile detects both
- Some Indian local products use EAN-8
- Better UX: don't reject "unknown" formats

---

### Q8: What's the data flow for a successful scan?

**Expected Answer**:
1. Mobile scans → gets EAN string
2. Mobile calls `GET /products/lookup/:ean`
3. Backend validates EAN
4. Backend queries `products` table (tenant-scoped)
5. If found, returns product with nutrition + health (BE-12)
6. If not found, Open Food Facts fallback (BE-11)
7. Mobile displays product details, allows scan submission
8. Scan submission (BE-16) creates scan_item with product_id reference

---

## 📝 Sign-Off Checklist

### Functional
- [ ] EAN validation handles all formats
- [ ] Check digit validation works
- [ ] EAN normalization works
- [ ] Product CRUD works
- [ ] Lookup by EAN works
- [ ] Batch lookup works
- [ ] Search with filters works
- [ ] Bulk create works
- [ ] Soft delete works

### Multi-tenancy
- [ ] Cross-tenant access blocked
- [ ] tenant_id auto-set in inserts
- [ ] Queries auto-scoped by tenant

### Code Quality
- [ ] ProductsRepository extends TenantScopedRepository
- [ ] No raw SQL outside utilities
- [ ] All DTOs have Zod schemas
- [ ] Service interfaces fully defined

### Performance
- [ ] EAN lookup < 50ms (DB hit)
- [ ] Indexes used for all queries (verify with EXPLAIN)
- [ ] Batch lookup uses single query (not N queries)

### Tests
- [ ] All 15 tests pass
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

### Critical Checks
- [ ] EAN check digit validation matches GS1 spec
- [ ] All multi-tenant queries verified
- [ ] No raw SQL in services
- [ ] Indexes verified in production-equivalent DB

**☐ APPROVED — Proceed to BE-11**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF BE-10 — DO NOT PROCEED WITHOUT APPROVAL**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-10 with the dual-mode scan endpoint (Req 4).**

## Driver Requirement

- **Req 4** — `GET /api/v1/products/{ean}/scan?mode=basic|comprehensive` returning either Basic_Scan_Output or Comprehensive_Scan_Output. Default mode = `basic` if param omitted. Mobile_App default depends on user tier; user can toggle and choice is persisted.

## Scope of Update

Add the scan endpoint. The actual basic/comprehensive payload generation is delegated to BE-12 (Health Scoring) and BE-41 (Healthier Alternatives). This phase owns the routing, the `?mode` query param, the entitlement check (Premium tier required for `comprehensive` if quota-gated), and persistence of per-user mode preference.

## Files to Create / Modify

| File Path | Change |
|---|---|
| `server/src/modules/products/controllers/scan.controller.ts` | New |
| `server/src/modules/products/dto/scan-mode-toggle.dto.ts` | New |
| `server/src/modules/products/services/scan-mode-preference.service.ts` | New |
| `server/src/database/migrations/v2/2026XXXX_user_scan_mode_preference.sql` | New column |

## Schema

```sql
ALTER TABLE users ADD COLUMN preferred_scan_mode TEXT NOT NULL DEFAULT 'basic'
  CHECK (preferred_scan_mode IN ('basic','comprehensive'));
```

## Endpoint

```typescript
@Controller('/api/v1/products')
export class ScanController {
  constructor(
    private readonly health: HealthScoringService,
    private readonly alternatives: HealthyAlternativesEngine,
    private readonly entitlements: EntitlementsService,
    private readonly preferences: ScanModePreferenceService,
  ) {}

  @Get('/:ean/scan')
  @UseGuards(JwtAuthGuard)
  async scan(
    @Param('ean') ean: string,
    @Query('mode') mode: 'basic' | 'comprehensive' | undefined,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<BasicScanOutputDto | ComprehensiveScanOutputDto> {
    const resolved = mode ?? 'basic';

    if (resolved === 'comprehensive') {
      const ent = this.entitlements.get(user);
      if (!ent.comprehensiveScanAccess) {
        // Free Consumer requesting comprehensive → 402 Payment Required
        throw new PaymentRequiredException('comprehensive scan requires Premium Consumer or higher');
      }
    }

    if (resolved === 'basic') return this.health.scoreBasic(ean);

    const comprehensive = await this.health.scoreComprehensive(ean, {
      allergenProfileId: user.activeAllergenProfileId,
      locale: user.preferredLocale,
    });
    comprehensive.healthierAlternatives = await this.alternatives.recommend(ean, user);
    return comprehensive;
  }

  @Put('/scan-mode-preference')
  @UseGuards(JwtAuthGuard)
  async setPreference(@Body() dto: ScanModeToggleDto, @CurrentUser() user: AuthenticatedUser) {
    return this.preferences.set(user.id, dto.mode);
  }
}
```

## ADDENDUM v2 Test Procedures (add 4)

| # | Test |
|---|---|
| T-v2.1 | Omitting `mode` defaults to `basic` and returns Basic_Scan_Output shape |
| T-v2.2 | `mode=comprehensive` from Free Consumer → 402 Payment Required |
| T-v2.3 | `mode=comprehensive` from Premium Consumer → returns Comprehensive_Scan_Output |
| T-v2.4 | Toggling preference persists and is reflected in subsequent default behavior |

## ADDENDUM v2 Q&A (add 2)

- **Q-v2.1**: How does this endpoint behave for a Trial Pro business user — basic by default, comprehensive on toggle?
- **Q-v2.2**: How are the daily scan quota counters from BE-46 incremented from this endpoint?

## ADDENDUM v2 Sign-off

- [ ] Scan endpoint live with mode routing
- [ ] Entitlement check returning 402 for Free Consumer comprehensive
- [ ] Preference persistence verified

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-10 ADDENDUM v2**
