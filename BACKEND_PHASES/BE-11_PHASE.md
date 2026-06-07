# Phase BE-11: Open Food Facts Integration

## Phase Metadata

- **Phase ID**: BE-11
- **Phase Name**: Open Food Facts Integration
- **Section**: Backend Execution — Core Product Layer
- **Depends On**: BE-01 to BE-10
- **Blocks**: BE-12 (Health Scoring needs nutrition data)
- **Estimated Duration**: 2 days
- **Complexity**: Medium

## Goal

Integrate the Open Food Facts (OFF) API as a free product enrichment source. Build a global cache layer (no tenant_id), graceful fallback chain, OFF response mapping, rate limiting (be polite to free API), retry logic, circuit breaker, and feature flag controls.

## Why This Phase Matters

Without OFF integration:
- Users must manually create EVERY product
- Mobile app shows "Unknown product" for most scans
- No nutrition data → BE-12 health scoring impossible
- Poor UX → users abandon RADHA
- Wasted opportunity (OFF has 2M+ products free)

OFF gives RADHA instant access to product database without paid APIs.

## Prerequisites

- [ ] BE-01 to BE-10 completed
- [ ] Internet connectivity
- [ ] Redis running (for rate limiting + caching)

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/open_food_facts_cache.ts` | Global OFF cache (no tenant_id) |
| `server/src/integrations/open-food-facts/off.module.ts` | OFF module |
| `server/src/integrations/open-food-facts/off.service.ts` | OFF API wrapper |
| `server/src/integrations/open-food-facts/off-cache.service.ts` | Cache layer |
| `server/src/integrations/open-food-facts/off-mapper.service.ts` | Map OFF → Product |
| `server/src/integrations/open-food-facts/off-circuit-breaker.service.ts` | Circuit breaker |
| `server/src/integrations/open-food-facts/repositories/off-cache.repository.ts` | Cache data |
| `server/src/integrations/open-food-facts/types/off.types.ts` | OFF API types |
| `server/src/integrations/open-food-facts/utils/off-response.utils.ts` | Response parsers |
| `server/src/integrations/open-food-facts/constants/off.constants.ts` | API endpoints, headers |
| All `__tests__/` files |

## Files to Modify

| File | Required Change |
|---|---|
| `server/src/modules/products/services/product-lookup.service.ts` | Add OFF fallback |
| `server/src/modules/products/products.service.ts` | Use OFF for new products |

## Service Interfaces

```typescript
// server/src/integrations/open-food-facts/off.service.ts

export interface IOpenFoodFactsService {
  // Lookup with cache + circuit breaker
  lookupByEan(ean: string): Promise<OffProduct | null>;
  
  // Search by name (less common)
  searchByName(query: string, limit?: number): Promise<OffProduct[]>;
  
  // Health check
  isHealthy(): Promise<boolean>;
  
  // Stats
  getStats(): OffStats;
}

export interface IOffCacheService {
  get(ean: string): Promise<OffCacheEntry | null>;
  set(ean: string, data: unknown, ttlSeconds?: number): Promise<void>;
  invalidate(ean: string): Promise<void>;
  refresh(ean: string): Promise<OffCacheEntry | null>;
  getStats(): Promise<{ hits: number; misses: number; size: number }>;
}

export interface IOffMapperService {
  mapToProduct(off: OffProduct): MappedProductData;
  mapToNutrition(off: OffProduct): MappedNutritionData | null;
  extractCategory(off: OffProduct): string | null;
  extractAllergens(off: OffProduct): string[];
  detectProcessingLevel(off: OffProduct): 'not' | 'lightly' | 'ultra';
}

export interface OffProduct {
  code: string;
  product_name?: string;
  product_name_en?: string;
  brands?: string;
  categories?: string;
  categories_tags?: string[];
  image_url?: string;
  image_front_url?: string;
  image_small_url?: string;
  ingredients_text?: string;
  ingredients_tags?: string[];
  allergens?: string;
  allergens_tags?: string[];
  nova_group?: number; // 1-4 processing level
  nutrition_grades?: string; // a-e
  ecoscore_grade?: string;
  packaging?: string;
  quantity?: string;
  serving_size?: string;
  nutriments?: OffNutriments;
  countries_tags?: string[];
  manufacturing_places?: string;
  origins?: string;
  stores?: string;
  labels_tags?: string[];
}

export interface OffNutriments {
  energy_100g?: number;
  energy_kcal_100g?: number;
  proteins_100g?: number;
  carbohydrates_100g?: number;
  sugars_100g?: number;
  fat_100g?: number;
  'saturated-fat_100g'?: number;
  'trans-fat_100g'?: number;
  fiber_100g?: number;
  salt_100g?: number;
  sodium_100g?: number;
}

export interface MappedProductData {
  ean: string;
  name: string;
  brand?: string;
  manufacturer?: string;
  category?: string;
  subCategory?: string;
  imageUrl?: string;
  packageSize?: string;
  packageUnit?: string;
  description?: string;
  dataSource: 'open-food-facts';
  externalId: string;
}

export interface MappedNutritionData {
  servingSize?: number;
  servingUnit?: string;
  calories?: number;
  protein?: number;
  carbohydrates?: number;
  sugars?: number;
  fat?: number;
  saturatedFat?: number;
  transFat?: number;
  fiber?: number;
  sodium?: number;
  containsAllergens: string[];
  isProcessed: 'not' | 'lightly' | 'ultra';
  dataSource: 'open-food-facts';
  confidence: number;
}

export interface OffCacheEntry {
  ean: string;
  data: OffProduct;
  fetchedAt: Date;
  expiresAt: Date;
  hitCount: number;
}

export interface OffStats {
  totalRequests: number;
  cacheHits: number;
  cacheMisses: number;
  apiSuccess: number;
  apiFailures: number;
  circuitState: 'closed' | 'open' | 'half-open';
  averageResponseMs: number;
}
```

## Implementation Code

### 1. OFF Cache Schema (Global)

```typescript
// server/src/db/schema/open_food_facts_cache.ts
import { pgTable, varchar, jsonb, timestamp, integer, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const openFoodFactsCache = pgTable(
  'open_food_facts_cache',
  {
    ...baseColumns,
    // NOTE: NO tenant_id — this is a GLOBAL cache shared across tenants
    ean: varchar('ean', { length: 13 }).notNull().unique(),
    rawData: jsonb('raw_data').notNull(),
    productName: varchar('product_name', { length: 200 }),
    brand: varchar('brand', { length: 100 }),
    fetchedAt: timestamp('fetched_at', { withTimezone: true }).notNull().defaultNow(),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    hitCount: integer('hit_count').notNull().default(0),
    lastAccessedAt: timestamp('last_accessed_at', { withTimezone: true }).defaultNow(),
    apiVersion: varchar('api_version', { length: 10 }).default('v0'),
    fetchSuccess: varchar('fetch_success', { length: 5 }).default('true'),
  },
  (table) => ({
    eanIdx: index('idx_off_cache_ean').on(table.ean),
    expiresIdx: index('idx_off_cache_expires').on(table.expiresAt),
    accessedIdx: index('idx_off_cache_accessed').on(table.lastAccessedAt),
  }),
);

export type OffCacheRecord = typeof openFoodFactsCache.$inferSelect;
export type NewOffCacheRecord = typeof openFoodFactsCache.$inferInsert;
```

### 2. Circuit Breaker Service

```typescript
// server/src/integrations/open-food-facts/off-circuit-breaker.service.ts
import { Injectable, Logger } from '@nestjs/common';

type CircuitState = 'closed' | 'open' | 'half-open';

@Injectable()
export class OffCircuitBreakerService {
  private readonly logger = new Logger(OffCircuitBreakerService.name);

  private state: CircuitState = 'closed';
  private failureCount = 0;
  private successCount = 0;
  private lastFailureTime?: Date;
  private nextAttemptTime?: Date;

  // Thresholds
  private readonly FAILURE_THRESHOLD = 5;
  private readonly SUCCESS_THRESHOLD = 2;
  private readonly TIMEOUT_MS = 60000; // 1 minute

  isAllowed(): boolean {
    if (this.state === 'closed') return true;
    
    if (this.state === 'open') {
      if (this.nextAttemptTime && new Date() >= this.nextAttemptTime) {
        this.transitionTo('half-open');
        return true;
      }
      return false;
    }
    
    // half-open: allow limited requests
    return true;
  }

  recordSuccess(): void {
    this.failureCount = 0;
    
    if (this.state === 'half-open') {
      this.successCount++;
      if (this.successCount >= this.SUCCESS_THRESHOLD) {
        this.transitionTo('closed');
      }
    }
  }

  recordFailure(): void {
    this.failureCount++;
    this.lastFailureTime = new Date();
    this.successCount = 0;
    
    if (this.state === 'half-open') {
      this.transitionTo('open');
    } else if (this.failureCount >= this.FAILURE_THRESHOLD) {
      this.transitionTo('open');
    }
  }

  getState(): CircuitState {
    return this.state;
  }

  private transitionTo(newState: CircuitState): void {
    this.logger.warn(`Circuit breaker: ${this.state} → ${newState}`, {
      failureCount: this.failureCount,
      successCount: this.successCount,
    });
    
    this.state = newState;
    
    if (newState === 'open') {
      this.nextAttemptTime = new Date(Date.now() + this.TIMEOUT_MS);
      this.successCount = 0;
    } else if (newState === 'closed') {
      this.failureCount = 0;
      this.successCount = 0;
      this.nextAttemptTime = undefined;
    }
  }
}
```

### 3. OFF API Service

```typescript
// server/src/integrations/open-food-facts/off.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '../../config/config.service';
import { LoggerService } from '../../logging/logger.service';
import { OffCacheService } from './off-cache.service';
import { OffCircuitBreakerService } from './off-circuit-breaker.service';
import {
  IOpenFoodFactsService,
  OffProduct,
  OffStats,
} from './types/off.types';
import { OFF_BASE_URL, OFF_API_VERSION, OFF_USER_AGENT } from './constants/off.constants';
import { ExternalServiceException } from '../../common/errors/business.exception';
import { ErrorCode } from '../../common/errors/error-codes';

@Injectable()
export class OpenFoodFactsService implements IOpenFoodFactsService {
  private readonly logger = new Logger(OpenFoodFactsService.name);
  
  // Stats
  private totalRequests = 0;
  private cacheHits = 0;
  private cacheMisses = 0;
  private apiSuccess = 0;
  private apiFailures = 0;
  private responseTimes: number[] = [];

  constructor(
    private readonly config: ConfigService,
    private readonly appLogger: LoggerService,
    private readonly cache: OffCacheService,
    private readonly circuitBreaker: OffCircuitBreakerService,
  ) {}

  async lookupByEan(ean: string): Promise<OffProduct | null> {
    this.totalRequests++;
    const startTime = Date.now();

    // 1. Check cache first
    const cached = await this.cache.get(ean);
    if (cached) {
      this.cacheHits++;
      this.appLogger.debug('OFF cache hit', { ean });
      return cached.data;
    }
    this.cacheMisses++;

    // 2. Check circuit breaker
    if (!this.circuitBreaker.isAllowed()) {
      this.appLogger.warn('OFF circuit breaker open, skipping API call', { ean });
      return null;
    }

    // 3. Fetch from OFF API
    try {
      const product = await this.fetchFromApi(ean);
      
      const duration = Date.now() - startTime;
      this.responseTimes.push(duration);
      if (this.responseTimes.length > 100) this.responseTimes.shift();
      
      this.circuitBreaker.recordSuccess();
      this.apiSuccess++;
      
      // Cache result (or absence)
      await this.cache.set(ean, product, 30 * 24 * 60 * 60); // 30 days
      
      return product;
    } catch (error) {
      this.circuitBreaker.recordFailure();
      this.apiFailures++;
      
      this.appLogger.error('OFF API call failed', {
        ean,
        error: error instanceof Error ? error.message : 'Unknown',
      });
      
      // Don't throw — gracefully return null
      return null;
    }
  }

  async searchByName(query: string, limit: number = 10): Promise<OffProduct[]> {
    if (!this.circuitBreaker.isAllowed()) {
      return [];
    }

    try {
      const url = `${OFF_BASE_URL}/cgi/search.pl?` + new URLSearchParams({
        search_terms: query,
        page_size: String(limit),
        json: '1',
      });

      const response = await this.makeRequest(url);
      const data = await response.json() as { products?: OffProduct[] };
      
      this.circuitBreaker.recordSuccess();
      return data.products || [];
    } catch (error) {
      this.circuitBreaker.recordFailure();
      this.appLogger.error('OFF search failed', { query, error });
      return [];
    }
  }

  async isHealthy(): Promise<boolean> {
    try {
      const response = await this.makeRequest(`${OFF_BASE_URL}/api/v2/product/3017620422003.json`, 5000);
      return response.ok;
    } catch {
      return false;
    }
  }

  getStats(): OffStats {
    const avgResponseMs = this.responseTimes.length > 0
      ? this.responseTimes.reduce((a, b) => a + b, 0) / this.responseTimes.length
      : 0;

    return {
      totalRequests: this.totalRequests,
      cacheHits: this.cacheHits,
      cacheMisses: this.cacheMisses,
      apiSuccess: this.apiSuccess,
      apiFailures: this.apiFailures,
      circuitState: this.circuitBreaker.getState(),
      averageResponseMs: Math.round(avgResponseMs),
    };
  }

  private async fetchFromApi(ean: string): Promise<OffProduct | null> {
    const url = `${OFF_BASE_URL}/api/${OFF_API_VERSION}/product/${ean}.json`;
    const response = await this.makeRequest(url);
    
    if (!response.ok) {
      throw new Error(`OFF API returned ${response.status}`);
    }
    
    const data = await response.json() as {
      status: number;
      status_verbose: string;
      product?: OffProduct;
    };
    
    if (data.status !== 1 || !data.product) {
      // Product not found in OFF
      return null;
    }
    
    return data.product;
  }

  private async makeRequest(url: string, timeoutMs: number = 5000): Promise<Response> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);
    
    try {
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'User-Agent': OFF_USER_AGENT,
          'Accept': 'application/json',
        },
        signal: controller.signal,
      });
      return response;
    } finally {
      clearTimeout(timeout);
    }
  }
}
```

### 4. OFF Mapper Service

```typescript
// server/src/integrations/open-food-facts/off-mapper.service.ts
import { Injectable } from '@nestjs/common';
import {
  IOffMapperService,
  OffProduct,
  MappedProductData,
  MappedNutritionData,
} from './types/off.types';

@Injectable()
export class OffMapperService implements IOffMapperService {
  
  mapToProduct(off: OffProduct): MappedProductData {
    return {
      ean: off.code,
      name: this.extractName(off),
      brand: this.extractBrand(off),
      manufacturer: off.manufacturing_places || undefined,
      category: this.extractCategory(off) || undefined,
      subCategory: this.extractSubCategory(off),
      imageUrl: off.image_front_url || off.image_url,
      packageSize: this.extractQuantity(off),
      packageUnit: this.extractQuantityUnit(off),
      description: off.ingredients_text?.slice(0, 1000),
      dataSource: 'open-food-facts',
      externalId: off.code,
    };
  }

  mapToNutrition(off: OffProduct): MappedNutritionData | null {
    if (!off.nutriments) return null;
    
    const n = off.nutriments;
    
    // OFF returns per 100g/100ml
    const hasAnyData = !!(
      n.energy_kcal_100g ||
      n.proteins_100g ||
      n.carbohydrates_100g ||
      n.fat_100g
    );
    
    if (!hasAnyData) return null;
    
    return {
      servingSize: 100, // OFF data is per 100g
      servingUnit: 'g',
      calories: n.energy_kcal_100g,
      protein: n.proteins_100g,
      carbohydrates: n.carbohydrates_100g,
      sugars: n.sugars_100g,
      fat: n.fat_100g,
      saturatedFat: n['saturated-fat_100g'],
      transFat: n['trans-fat_100g'],
      fiber: n.fiber_100g,
      sodium: n.sodium_100g ? n.sodium_100g * 1000 : undefined, // g → mg
      containsAllergens: this.extractAllergens(off),
      isProcessed: this.detectProcessingLevel(off),
      dataSource: 'open-food-facts',
      confidence: this.calculateConfidence(off),
    };
  }

  extractCategory(off: OffProduct): string | null {
    if (!off.categories_tags || off.categories_tags.length === 0) return null;
    
    // First category tag is most general
    return this.cleanTag(off.categories_tags[0]);
  }

  extractAllergens(off: OffProduct): string[] {
    if (!off.allergens_tags) return [];
    return off.allergens_tags.map((tag) => this.cleanTag(tag));
  }

  detectProcessingLevel(off: OffProduct): 'not' | 'lightly' | 'ultra' {
    // NOVA group: 1-4
    // 1: Unprocessed, 2: Processed culinary ingredients
    // 3: Processed foods, 4: Ultra-processed
    if (off.nova_group === 1 || off.nova_group === 2) return 'not';
    if (off.nova_group === 3) return 'lightly';
    if (off.nova_group === 4) return 'ultra';
    
    // Heuristic fallback if no NOVA group
    if (off.ingredients_text && off.ingredients_text.length > 500) return 'ultra';
    if (off.ingredients_text && off.ingredients_text.length > 200) return 'lightly';
    return 'not';
  }

  private extractName(off: OffProduct): string {
    return off.product_name_en || off.product_name || `Product ${off.code}`;
  }

  private extractBrand(off: OffProduct): string | undefined {
    if (!off.brands) return undefined;
    return off.brands.split(',')[0].trim();
  }

  private extractSubCategory(off: OffProduct): string | undefined {
    if (!off.categories_tags || off.categories_tags.length < 2) return undefined;
    return this.cleanTag(off.categories_tags[1]);
  }

  private extractQuantity(off: OffProduct): string | undefined {
    if (!off.quantity) return undefined;
    const match = off.quantity.match(/(\d+(?:\.\d+)?)/);
    return match ? match[1] : undefined;
  }

  private extractQuantityUnit(off: OffProduct): string | undefined {
    if (!off.quantity) return undefined;
    const match = off.quantity.toLowerCase().match(/(g|kg|ml|l|oz)/);
    return match ? match[1] : undefined;
  }

  private cleanTag(tag: string): string {
    // OFF tags like "en:dairy-products" → "Dairy Products"
    return tag
      .replace(/^[a-z]+:/, '')
      .replace(/-/g, ' ')
      .replace(/\b\w/g, (c) => c.toUpperCase());
  }

  private calculateConfidence(off: OffProduct): number {
    let score = 0;
    let maxScore = 0;
    
    const checks = [
      { has: !!off.product_name, weight: 0.2 },
      { has: !!off.brands, weight: 0.1 },
      { has: !!off.categories_tags?.length, weight: 0.15 },
      { has: !!off.image_url, weight: 0.1 },
      { has: !!off.nutriments?.energy_kcal_100g, weight: 0.2 },
      { has: !!off.ingredients_text, weight: 0.15 },
      { has: !!off.nova_group, weight: 0.1 },
    ];
    
    for (const check of checks) {
      maxScore += check.weight;
      if (check.has) score += check.weight;
    }
    
    return Math.round((score / maxScore) * 100) / 100;
  }
}
```

### 5. Update ProductLookupService

```typescript
// server/src/modules/products/services/product-lookup.service.ts (UPDATED)
@Injectable()
export class ProductLookupService implements IProductLookupService {
  constructor(
    private readonly productsRepo: ProductsRepository,
    private readonly nutritionRepo: ProductNutritionRepository,
    private readonly appLogger: LoggerService,
    // NEW IN BE-11:
    private readonly offService: OpenFoodFactsService,
    private readonly offMapper: OffMapperService,
    private readonly db: DbService,
  ) {}

  async lookupByEan(
    ean: string,
    options: LookupOptions = {},
  ): Promise<ProductLookupResult> {
    const startTime = Date.now();
    const validation = validateEan(ean);
    if (!validation.valid) {
      throw new ValidationException(validation.error || 'Invalid EAN');
    }
    const normalizedEan = normalizeEan(ean);

    // 1. Try local database
    const local = await this.productsRepo.findByEan(normalizedEan);
    if (local && !options.forceRefresh) {
      const enriched = await this.enrichProduct(local, options);
      return {
        found: true,
        product: enriched,
        source: 'database',
        cached: false,
        externalApiCalled: false,
        durationMs: Date.now() - startTime,
      };
    }

    // 2. NEW IN BE-11: Try Open Food Facts
    if (options.fallbackToExternal !== false) {
      const offProduct = await this.offService.lookupByEan(normalizedEan);
      
      if (offProduct) {
        // Map and save to local DB
        const productData = this.offMapper.mapToProduct(offProduct);
        const nutritionData = this.offMapper.mapToNutrition(offProduct);
        
        // Create in tenant's catalog
        const newProduct = await this.db.transaction(async (tx) => {
          const product = await this.productsRepo.create(productData, tx);
          if (nutritionData) {
            await this.nutritionRepo.create({
              ...nutritionData,
              productId: product.id,
            }, tx);
          }
          return product;
        });
        
        const enriched = await this.enrichProduct(newProduct, options);
        return {
          found: true,
          product: enriched,
          source: 'open-food-facts',
          cached: false,
          externalApiCalled: true,
          durationMs: Date.now() - startTime,
        };
      }
    }

    return {
      found: false,
      source: 'database',
      cached: false,
      externalApiCalled: true,
      durationMs: Date.now() - startTime,
    };
  }
}
```

## Database Tables Affected

| Table | Operation | Purpose |
|---|---|---|
| `open_food_facts_cache` | CREATED | Global OFF response cache |
| `products` | INSERT | Auto-created from OFF lookups |
| `product_nutrition` | INSERT | Auto-created from OFF nutrition |

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| GET | `/api/v1/products/lookup/:ean` | Bearer | Updated to include OFF fallback |
| GET | `/api/v1/admin/integrations/off/stats` | Admin | OFF integration metrics |
| POST | `/api/v1/admin/integrations/off/cache/refresh/:ean` | Admin | Force cache refresh |
| GET | `/api/v1/admin/integrations/off/health` | Admin | OFF health check |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-12 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: OFF Cache Miss → API Call → Cache Set ✅

```bash
# Use a known EAN (Nutella)
curl http://localhost:3000/api/v1/products/lookup/3017620422003 \
  -H "Authorization: Bearer <token>"
```

**Expected (200)**:
```json
{
  "data": {
    "found": true,
    "source": "open-food-facts",
    "externalApiCalled": true,
    "product": {
      "name": "Nutella",
      "brand": "Ferrero",
      "ean": "3017620422003"
    }
  }
}
```

**Verification**:
- Row in `open_food_facts_cache`
- Row in `products` (tenant-scoped)
- Row in `product_nutrition`

**Pass Criteria**: ✅ External lookup creates local copies

---

### Test 2: OFF Cache Hit ✅

Same EAN, second call:
```bash
curl http://localhost:3000/api/v1/products/lookup/3017620422003 \
  -H "Authorization: Bearer <token>"
```

**Expected**: 
- `source: "database"` (now found locally)
- `externalApiCalled: false`
- Response time < 50ms

**Pass Criteria**: ✅ Second call hits local DB, no external API

---

### Test 3: Unknown EAN ✅

```bash
curl http://localhost:3000/api/v1/products/lookup/9999999999999 \
  -H "Authorization: Bearer <token>"
```

**Expected**:
- `found: false`
- OFF API called and returned not found
- Cache still updated (negative cache)

**Pass Criteria**: ✅ Negative results cached too

---

### Test 4: Circuit Breaker — Open After Failures ✅

Force OFF API failures (mock or block network), make 6 requests:
**Expected**:
- Requests 1-5: Try OFF, fail
- Request 6+: Circuit open, skip OFF immediately
- Logs: "OFF circuit breaker open"

**Pass Criteria**: ✅ Circuit prevents cascade failures

---

### Test 5: Circuit Breaker — Half-Open Recovery ✅

After circuit open, wait 60 seconds:
**Expected**:
- Next request transitions to half-open
- If successful, transitions to closed
- If fails, transitions back to open

**Pass Criteria**: ✅ Recovery mechanism works

---

### Test 6: Cache TTL ✅

Set cache TTL low (60 seconds for testing):
1. First lookup: cache miss, API call
2. Second lookup (within 60s): cache hit
3. Wait 65 seconds
4. Third lookup: cache miss again, API call

**Pass Criteria**: ✅ TTL respected

---

### Test 7: OFF Mapping Correctness ✅

Lookup Nutella (3017620422003):
**Expected fields populated**:
- name: "Nutella" or "Pâte à tartiner Nutella"
- brand: "Ferrero"
- imageUrl: starts with "https://"
- nutrition.calories: ~539
- nutrition.sugars: ~56
- nutrition.fat: ~30
- isProcessed: "ultra" (NOVA 4)
- containsAllergens: includes "milk", "nuts"

**Pass Criteria**: ✅ All fields mapped correctly

---

### Test 8: Confidence Score ✅

```typescript
const confidence = mapper.calculateConfidence(nutellaProduct);
expect(confidence).toBeGreaterThan(0.8); // Well-documented product
```

**Pass Criteria**: ✅ Confidence scores reasonable

---

### Test 9: NOVA Group Mapping ✅

| NOVA | Mapped to |
|---|---|
| 1 | not |
| 2 | not |
| 3 | lightly |
| 4 | ultra |

**Pass Criteria**: ✅ All NOVA groups mapped

---

### Test 10: Stats Endpoint ✅

```bash
curl http://localhost:3000/api/v1/admin/integrations/off/stats \
  -H "Authorization: Bearer <admin-token>"
```

**Expected**:
```json
{
  "data": {
    "totalRequests": 25,
    "cacheHits": 15,
    "cacheMisses": 10,
    "apiSuccess": 9,
    "apiFailures": 1,
    "circuitState": "closed",
    "averageResponseMs": 234
  }
}
```

**Pass Criteria**: ✅ Stats track correctly

---

### Test 11: Health Check ✅

```bash
curl http://localhost:3000/api/v1/admin/integrations/off/health
```

**Expected**: 200 if OFF reachable, 503 if not

**Pass Criteria**: ✅ Health check works

---

### Test 12: Cache Cleanup ✅

Run cleanup job (cron will run BE-24):
```sql
SELECT count(*) FROM open_food_facts_cache 
WHERE expires_at < NOW();
```

**Expected**: Count decreases over time
**Pass Criteria**: ✅ Expired entries cleaned

---

### Test 13: Tenant Isolation Maintained ✅

Two tenants lookup same EAN:
**Expected**:
- OFF cache: 1 row (shared globally)
- products table: 2 rows (one per tenant)
- product_nutrition: 2 rows

**Pass Criteria**: ✅ Cache shared, tenant data isolated

---

### Test 14: Rate Limiting ✅

Lookup 100 different EANs in rapid succession:
**Expected**: 
- Some are throttled (be polite to OFF)
- Background queue catches up
- No errors, just delays

**Pass Criteria**: ✅ OFF API not overwhelmed

---

### Test 15: Force Refresh ✅

```bash
curl -X POST http://localhost:3000/api/v1/admin/integrations/off/cache/refresh/3017620422003 \
  -H "Authorization: Bearer <admin-token>"
```

**Expected**: Cache invalidated, fresh fetch from OFF
**Pass Criteria**: ✅ Manual refresh works

---

## 🎯 Q&A Session

### Q1: Why a global cache (no tenant_id)?

**Expected Answer**:
- OFF data is universal — same EAN gives same data globally
- Storing per-tenant wastes 90%+ of storage
- Cache hit rate higher with shared cache
- No privacy concern (OFF data is public)
- Tenant-specific data lives in `products` table

---

### Q2: Why a circuit breaker?

**Expected Answer**:
- Prevents cascading failures when OFF is down
- Saves time (don't wait for timeouts)
- Reduces server load during OFF outages
- Auto-recovery (half-open state)
- Protects user experience

---

### Q3: Why 30-day TTL for cache?

**Expected Answer**:
- OFF data changes slowly (products don't change often)
- Reduces API calls (~95% cache hits after warm)
- Reasonable freshness for retail
- Manual refresh available for corrections
- Trade-off: Storage vs API load

---

### Q4: Why save OFF products to local catalog?

**Expected Answer**:
- Faster subsequent lookups (no external dependency)
- Tenant can customize (rename, recategorize)
- Works during OFF outages
- Reports work even if OFF unavailable
- Each tenant gets their own version (multi-tenant model)

---

### Q5: How do you handle OFF rate limits?

**Expected Answer**:
- OFF allows ~1 req/sec for free
- We use circuit breaker as soft rate limit
- Cache reduces actual API calls drastically
- Could add explicit rate limiter (BE-31)
- User-Agent header identifies us
- Be polite — OFF is a free service

---

### Q6: What's NOVA classification?

**Expected Answer**:
- Food processing classification (1-4)
- 1: Unprocessed (fruits, veggies)
- 2: Culinary ingredients (oil, salt)
- 3: Processed (cheese, bread)
- 4: Ultra-processed (Nutella, soda)
- Used for child safety scoring (BE-12)

---

### Q7: What if OFF returns wrong data?

**Expected Answer**:
- User can edit product (overrides OFF data)
- Override stored as 'manual' source
- Future OFF refreshes don't override manual edits
- Trust signal: confidence score
- Admin can blocklist specific EANs

---

### Q8: How would you scale OFF integration?

**Expected Answer**:
- Cache layer (already done)
- Circuit breaker (already done)
- Background pre-warming for popular EANs
- Multiple OFF mirrors (if available)
- CDN for OFF images
- Self-hosted OFF (optional, complex)

---

## 📝 Sign-Off Checklist

### Functional
- [ ] OFF lookup returns real data for known EANs
- [ ] Cache works (hit/miss tracked)
- [ ] Circuit breaker opens after 5 failures
- [ ] Circuit breaker recovers after 60s
- [ ] Mapping populates all fields correctly
- [ ] Tenant isolation maintained
- [ ] Stats endpoint shows accurate data

### Code Quality
- [ ] Circuit breaker tested (open/closed/half-open)
- [ ] Cache TTL respected
- [ ] No retry loops (don't retry failed OFF calls aggressively)
- [ ] User-Agent header set
- [ ] All errors logged but not thrown to user

### Performance
- [ ] Cache hit < 5ms
- [ ] Cache miss + OFF call < 3s
- [ ] No blocking of request thread
- [ ] No memory leaks in stats tracking

### Tests
- [ ] All 15 tests pass
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

- [ ] Tested with real OFF API
- [ ] Verified graceful degradation when OFF unavailable
- [ ] Confirmed tenant isolation
- [ ] Cache strategy reviewed

**☐ APPROVED — Proceed to BE-12**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF BE-11 — DO NOT PROCEED WITHOUT APPROVAL**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-11 with comprehensive-data fetch coverage and the BE-45 image-fallback pipeline integration (Req 4, Req 38).**

## Driver Requirements

- **Req 4** — Comprehensive output requires full ingredients, allergens, and nutritional data. Open Food Facts is the primary free source.
- **Req 38** — When EAN is undecodable, the system falls back to image OCR which lands in the catalog via the same OFF/upsert pathway.

## Scope of Update

The v1 OFF integration fetched basic fields. v2 confirms that the comprehensive fields (`ingredients`, `allergens_tags`, `nutriments`, `nova_group`) are persisted on every fetch, and that image-fallback writes use the same upsert path so cache + dedup work identically.

## Files to Modify

| File Path | Change |
|---|---|
| `server/src/modules/open-food-facts/dto/off-product.dto.ts` | Ensure `ingredients`, `allergens_tags`, `nova_group`, `nutriments` are mapped |
| `server/src/modules/open-food-facts/services/off.service.ts` | Add `fetchOrUpsert(ean)` reused by BE-45 image-fallback |

## ADDENDUM v2 Test Procedures (add 3)

| # | Test |
|---|---|
| T-v2.1 | OFF fetch persists `ingredients`, `allergens_tags`, `nova_group`, `nutriments` in `products` table |
| T-v2.2 | `fetchOrUpsert` is idempotent: calling twice produces a single row |
| T-v2.3 | Cache hit path returns within 50 ms (Cache_Layer 24h TTL from BE-32 ADDENDUM v2) |

## ADDENDUM v2 Q&A (add 2)

- **Q-v2.1**: When OFF data is incomplete, how does the system signal "data unavailable" downstream (e.g., to BE-12 Health Scoring)?
- **Q-v2.2**: How does the system attribute community-submitted data (Req 46, BE-56) vs OFF data on the same product?

## ADDENDUM v2 Sign-off

- [ ] Comprehensive fields confirmed in storage
- [ ] `fetchOrUpsert` reused by BE-45
- [ ] Cache TTL aligned with BE-32

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-11 ADDENDUM v2**
