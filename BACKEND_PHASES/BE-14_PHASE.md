# Phase BE-14: Product Search & Filtering

## Phase Metadata

- **Phase ID**: BE-14
- **Phase Name**: Product Search & Filtering
- **Section**: Backend Execution — Core Product Layer
- **Depends On**: BE-01 to BE-13
- **Blocks**: BE-15 (EAN matching uses search)
- **Estimated Duration**: 2 days
- **Complexity**: Medium

## Goal

Build production-grade product search using PostgreSQL full-text search: tsvector indexing, multi-field search (name, brand, EAN, category), autocomplete suggestions, faceted filtering, search analytics, query optimization, and ranking by relevance + popularity.

## Why This Phase Matters

Mobile users need to find products fast:
- Without search, users only find by exact EAN
- Manual product creation needs duplicate detection
- Reports filter products by name/category
- Admin needs to manage 1000s of products
- Audit needs product lookup by partial info

## Prerequisites

- [ ] BE-01 to BE-13 completed
- [ ] PostgreSQL with pg_trgm extension
- [ ] Products table populated

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/migrations/XXX_add_search_indexes.sql` | tsvector + trigram indexes |
| `server/src/modules/products/services/product-search.service.ts` | Search logic |
| `server/src/modules/products/services/search-analytics.service.ts` | Track searches |
| `server/src/modules/products/services/autocomplete.service.ts` | Auto-suggestions |
| `server/src/db/schema/search_queries.ts` | Search history |
| `server/src/db/schema/popular_products.ts` | Popularity tracking |
| `server/src/modules/products/repositories/search.repository.ts` | Search queries |
| `server/src/modules/products/dto/search-products.dto.ts` | Search DTO |
| `server/src/modules/products/dto/autocomplete.dto.ts` | Autocomplete DTO |
| `server/src/modules/products/utils/search-query-builder.ts` | Query builder |
| `server/src/modules/products/utils/search-ranking.utils.ts` | Ranking algorithm |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/products/services/product-search.service.ts

export interface IProductSearchService {
  // Main search
  search(query: SearchProductsDto, tenantId: string): Promise<SearchResult>;
  
  // Autocomplete suggestions
  autocomplete(query: AutocompleteDto, tenantId: string): Promise<AutocompleteResult>;
  
  // Find similar products (e.g., for duplicate detection)
  findSimilar(productId: string, limit?: number): Promise<Product[]>;
  
  // Faceted search (counts per category, brand, etc.)
  getFacets(query: SearchProductsDto, tenantId: string): Promise<SearchFacets>;
  
  // Popular products
  getPopular(tenantId: string, limit?: number): Promise<Product[]>;
  
  // Recently scanned
  getRecentlyScanned(tenantId: string, userId: string, limit?: number): Promise<Product[]>;
}

export interface SearchProductsDto {
  q?: string;
  ean?: string;
  brand?: string;
  category?: string;
  healthGrade?: ('A' | 'B' | 'C' | 'D' | 'E')[];
  childSafe?: boolean;
  excludeProcessed?: boolean;
  status?: 'active' | 'discontinued';
  cursor?: string;
  limit?: number;
  orderBy?: 'relevance' | 'name' | 'createdAt' | 'popularity';
  orderDirection?: 'asc' | 'desc';
}

export interface SearchResult {
  data: ProductWithDetails[];
  total: number;
  nextCursor: string | null;
  facets?: SearchFacets;
  query: string;
  durationMs: number;
}

export interface AutocompleteDto {
  q: string;
  limit?: number;
  type?: 'name' | 'brand' | 'all';
}

export interface AutocompleteResult {
  suggestions: AutocompleteSuggestion[];
  durationMs: number;
}

export interface AutocompleteSuggestion {
  text: string;
  type: 'product' | 'brand' | 'category';
  productId?: string;
  matchedField: string;
}

export interface SearchFacets {
  categories: Array<{ id: string; name: string; count: number }>;
  brands: Array<{ name: string; count: number }>;
  healthGrades: Array<{ grade: string; count: number }>;
  processingLevels: Array<{ level: string; count: number }>;
}
```

## Implementation Code

### 1. Search Indexes Migration

```sql
-- server/src/db/migrations/XXX_add_search_indexes.sql

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Add tsvector column to products
ALTER TABLE products 
  ADD COLUMN IF NOT EXISTS search_tsv tsvector;

-- Function to update tsvector
CREATE OR REPLACE FUNCTION products_search_tsv_update() RETURNS trigger AS $$
BEGIN
  NEW.search_tsv := 
    setweight(to_tsvector('english', COALESCE(NEW.name, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.brand, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'C') ||
    setweight(to_tsvector('english', COALESCE(NEW.ean, '')), 'D');
  RETURN NEW;
END
$$ LANGUAGE plpgsql;

-- Trigger to auto-update on insert/update
DROP TRIGGER IF EXISTS products_search_tsv_trigger ON products;
CREATE TRIGGER products_search_tsv_trigger
  BEFORE INSERT OR UPDATE OF name, brand, description, ean
  ON products
  FOR EACH ROW
  EXECUTE FUNCTION products_search_tsv_update();

-- GIN index for fast full-text search
CREATE INDEX IF NOT EXISTS idx_products_search_tsv 
  ON products USING GIN (search_tsv);

-- Trigram indexes for fuzzy matching
CREATE INDEX IF NOT EXISTS idx_products_name_trgm 
  ON products USING GIN (name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_products_brand_trgm 
  ON products USING GIN (brand gin_trgm_ops);

-- Composite index for tenant-scoped search
CREATE INDEX IF NOT EXISTS idx_products_tenant_search
  ON products (tenant_id) INCLUDE (id, name, brand, ean)
  WHERE deleted_at IS NULL;

-- Backfill existing products
UPDATE products SET search_tsv = 
  setweight(to_tsvector('english', COALESCE(name, '')), 'A') ||
  setweight(to_tsvector('english', COALESCE(brand, '')), 'B') ||
  setweight(to_tsvector('english', COALESCE(description, '')), 'C') ||
  setweight(to_tsvector('english', COALESCE(ean, '')), 'D')
WHERE search_tsv IS NULL;
```

### 2. Search Repository

```typescript
// server/src/modules/products/repositories/search.repository.ts
import { Injectable } from '@nestjs/common';
import { sql, and, eq, ilike, or, inArray, desc, asc } from 'drizzle-orm';
import { DbService } from '../../../db/db.service';
import { products } from '../../../db/schema/products';
import { productHealthAssessments } from '../../../db/schema/product_health_assessments';
import { RequestContextService } from '../../../common/context/request-context.service';
import { encodeCursor, decodeCursor } from '../../../db/repositories/pagination.utils';

@Injectable()
export class SearchRepository {
  constructor(
    private readonly db: DbService,
    private readonly contextService: RequestContextService,
  ) {}

  async fullTextSearch(params: {
    query: string;
    tenantId: string;
    filters: {
      categories?: string[];
      brands?: string[];
      healthGrades?: string[];
      excludeProcessed?: boolean;
    };
    cursor?: string;
    limit: number;
    orderBy: string;
  }): Promise<{ data: any[]; total: number; nextCursor: string | null }> {
    const db = this.db.getDb();
    
    // Build WHERE conditions
    const conditions = [
      eq(products.tenantId, params.tenantId),
      sql`${products.deletedAt} IS NULL`,
    ];
    
    if (params.query) {
      // Use full-text search with ranking
      conditions.push(sql`
        ${products.searchTsv} @@ plainto_tsquery('english', ${params.query})
        OR ${products.name} ILIKE ${'%' + params.query + '%'}
        OR ${products.brand} ILIKE ${'%' + params.query + '%'}
      `);
    }
    
    if (params.filters.categories?.length) {
      conditions.push(inArray(products.categoryId, params.filters.categories));
    }
    
    if (params.filters.brands?.length) {
      conditions.push(inArray(products.brand, params.filters.brands));
    }
    
    // Build ORDER BY
    let orderBy;
    if (params.orderBy === 'relevance' && params.query) {
      orderBy = sql`ts_rank(${products.searchTsv}, plainto_tsquery('english', ${params.query})) DESC`;
    } else if (params.orderBy === 'name') {
      orderBy = asc(products.name);
    } else if (params.orderBy === 'popularity') {
      // Will be implemented with popular_products table
      orderBy = desc(products.createdAt);
    } else {
      orderBy = desc(products.createdAt);
    }
    
    // Execute query
    const rows = await db
      .select()
      .from(products)
      .leftJoin(
        productHealthAssessments,
        eq(productHealthAssessments.productId, products.id),
      )
      .where(and(...conditions))
      .orderBy(orderBy)
      .limit(params.limit + 1);
    
    const hasMore = rows.length > params.limit;
    const data = hasMore ? rows.slice(0, -1) : rows;
    
    // Get total count (separate query for performance)
    const [{ count }] = await db
      .select({ count: sql`count(*)::int` })
      .from(products)
      .where(and(...conditions));
    
    const nextCursor = hasMore && data.length > 0
      ? encodeCursor(data[data.length - 1] as Record<string, unknown>, [
          { field: 'id', direction: 'desc' },
        ])
      : null;
    
    return { data, total: Number(count), nextCursor };
  }

  async getAutocompleteSuggestions(
    query: string,
    tenantId: string,
    limit: number,
  ): Promise<Array<{ text: string; type: string; productId?: string }>> {
    const db = this.db.getDb();
    
    // Use trigram similarity for fuzzy matching
    const suggestions = await db
      .select({
        id: products.id,
        name: products.name,
        brand: products.brand,
      })
      .from(products)
      .where(and(
        eq(products.tenantId, tenantId),
        sql`${products.deletedAt} IS NULL`,
        sql`${products.name} ILIKE ${query + '%'} OR ${products.brand} ILIKE ${query + '%'}`,
      ))
      .orderBy(sql`similarity(${products.name}, ${query}) DESC`)
      .limit(limit);
    
    return suggestions.map((s) => ({
      text: s.name,
      type: 'product',
      productId: s.id,
    }));
  }

  async getFacets(tenantId: string): Promise<{
    categories: Array<{ id: string; name: string; count: number }>;
    brands: Array<{ name: string; count: number }>;
    healthGrades: Array<{ grade: string; count: number }>;
  }> {
    const db = this.db.getDb();
    
    const [categories, brands, grades] = await Promise.all([
      // Categories with counts
      db.execute(sql`
        SELECT category_id as id, COUNT(*) as count
        FROM products
        WHERE tenant_id = ${tenantId} AND deleted_at IS NULL AND category_id IS NOT NULL
        GROUP BY category_id
        ORDER BY count DESC
        LIMIT 20
      `),
      
      // Brands with counts
      db.execute(sql`
        SELECT brand as name, COUNT(*) as count
        FROM products
        WHERE tenant_id = ${tenantId} AND deleted_at IS NULL AND brand IS NOT NULL
        GROUP BY brand
        ORDER BY count DESC
        LIMIT 20
      `),
      
      // Health grades
      db.execute(sql`
        SELECT pha.overall_grade as grade, COUNT(*) as count
        FROM product_health_assessments pha
        JOIN products p ON p.id = pha.product_id
        WHERE p.tenant_id = ${tenantId} AND p.deleted_at IS NULL
        GROUP BY pha.overall_grade
      `),
    ]);
    
    return {
      categories: (categories.rows as { id: string; count: number }[]).map((r) => ({
        id: r.id,
        name: r.id,
        count: Number(r.count),
      })),
      brands: (brands.rows as { name: string; count: number }[]).map((r) => ({
        name: r.name,
        count: Number(r.count),
      })),
      healthGrades: (grades.rows as { grade: string; count: number }[]).map((r) => ({
        grade: r.grade,
        count: Number(r.count),
      })),
    };
  }
}
```

### 3. Search Service

```typescript
// server/src/modules/products/services/product-search.service.ts
import { Injectable } from '@nestjs/common';
import { SearchRepository } from '../repositories/search.repository';
import { SearchAnalyticsService } from './search-analytics.service';
import {
  IProductSearchService,
  SearchProductsDto,
  SearchResult,
  AutocompleteDto,
  AutocompleteResult,
  SearchFacets,
} from '../types/search.types';

@Injectable()
export class ProductSearchService implements IProductSearchService {
  constructor(
    private readonly searchRepo: SearchRepository,
    private readonly analytics: SearchAnalyticsService,
  ) {}

  async search(
    query: SearchProductsDto,
    tenantId: string,
  ): Promise<SearchResult> {
    const startTime = Date.now();
    
    const result = await this.searchRepo.fullTextSearch({
      query: query.q || '',
      tenantId,
      filters: {
        categories: query.category ? [query.category] : undefined,
        brands: query.brand ? [query.brand] : undefined,
        healthGrades: query.healthGrade,
        excludeProcessed: query.excludeProcessed,
      },
      cursor: query.cursor,
      limit: query.limit || 50,
      orderBy: query.orderBy || 'relevance',
    });
    
    // Track analytics (async, don't block response)
    if (query.q) {
      this.analytics.trackSearch({
        query: query.q,
        tenantId,
        resultCount: result.total,
        durationMs: Date.now() - startTime,
      }).catch(() => {}); // Fire and forget
    }
    
    return {
      ...result,
      query: query.q || '',
      durationMs: Date.now() - startTime,
    };
  }

  async autocomplete(
    query: AutocompleteDto,
    tenantId: string,
  ): Promise<AutocompleteResult> {
    const startTime = Date.now();
    
    if (query.q.length < 2) {
      return { suggestions: [], durationMs: 0 };
    }
    
    const suggestions = await this.searchRepo.getAutocompleteSuggestions(
      query.q,
      tenantId,
      query.limit || 10,
    );
    
    return {
      suggestions: suggestions.map((s) => ({
        text: s.text,
        type: s.type as any,
        productId: s.productId,
        matchedField: 'name',
      })),
      durationMs: Date.now() - startTime,
    };
  }

  async findSimilar(productId: string, limit: number = 10): Promise<Product[]> {
    // Will use trigram similarity on name + same brand/category
    // Implementation in repository
    return [];
  }

  async getFacets(
    query: SearchProductsDto,
    tenantId: string,
  ): Promise<SearchFacets> {
    const facets = await this.searchRepo.getFacets(tenantId);
    
    return {
      ...facets,
      processingLevels: [
        { level: 'not', count: 0 },
        { level: 'lightly', count: 0 },
        { level: 'ultra', count: 0 },
      ],
    };
  }

  async getPopular(tenantId: string, limit: number = 20): Promise<Product[]> {
    // Implementation: query popular_products table
    return [];
  }

  async getRecentlyScanned(
    tenantId: string,
    userId: string,
    limit: number = 20,
  ): Promise<Product[]> {
    // Implementation: query scan_items joined with products
    return [];
  }
}
```

### 4. Search DTOs

```typescript
// server/src/modules/products/dto/search-products.dto.ts
import { z } from 'zod';

export const SearchProductsSchema = z.object({
  q: z.string().min(1).max(100).optional(),
  ean: z.string().regex(/^\d{8,13}$/).optional(),
  brand: z.string().max(100).optional(),
  category: z.string().uuid().optional(),
  healthGrade: z.array(z.enum(['A', 'B', 'C', 'D', 'E'])).optional(),
  childSafe: z.coerce.boolean().optional(),
  excludeProcessed: z.coerce.boolean().optional(),
  status: z.enum(['active', 'discontinued']).optional(),
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
  orderBy: z.enum(['relevance', 'name', 'createdAt', 'popularity']).default('relevance'),
  orderDirection: z.enum(['asc', 'desc']).default('desc'),
  includeFacets: z.coerce.boolean().default(false),
});

export type SearchProductsDto = z.infer<typeof SearchProductsSchema>;
```

```typescript
// server/src/modules/products/dto/autocomplete.dto.ts
import { z } from 'zod';

export const AutocompleteSchema = z.object({
  q: z.string().min(2).max(50),
  limit: z.coerce.number().int().min(1).max(20).default(10),
  type: z.enum(['name', 'brand', 'all']).default('all'),
});

export type AutocompleteDto = z.infer<typeof AutocompleteSchema>;
```

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| GET | `/api/v1/products/search` | Bearer | Full search |
| GET | `/api/v1/products/autocomplete` | Bearer | Autocomplete |
| GET | `/api/v1/products/facets` | Bearer | Faceted counts |
| GET | `/api/v1/products/popular` | Bearer | Popular products |
| GET | `/api/v1/products/:id/similar` | Bearer | Similar products |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-15 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Full-Text Search ✅

```bash
curl "http://localhost:3000/api/v1/products/search?q=chocolate" \
  -H "Authorization: Bearer <token>"
```

**Expected**: Returns matching products ranked by relevance
**Pass Criteria**: ✅ Search returns matches

---

### Test 2: Search with Typo (Trigram) ✅

```bash
curl "http://localhost:3000/api/v1/products/search?q=chocolat" \
  -H "Authorization: Bearer <token>"
```

**Expected**: Still finds "chocolate" products (trigram fuzzy match)
**Pass Criteria**: ✅ Fuzzy matching works

---

### Test 3: Multi-field Search ✅

Search for brand name "Cadbury":
```bash
curl "http://localhost:3000/api/v1/products/search?q=Cadbury"
```

**Expected**: Finds products with brand=Cadbury (B-weight in tsvector)
**Pass Criteria**: ✅ Brand search works

---

### Test 4: Filter by Category ✅

```bash
curl "http://localhost:3000/api/v1/products/search?category=<uuid>"
```

**Expected**: Only products in that category
**Pass Criteria**: ✅ Category filter works

---

### Test 5: Filter by Health Grade ✅

```bash
curl "http://localhost:3000/api/v1/products/search?healthGrade=A&healthGrade=B"
```

**Expected**: Only A and B grade products
**Pass Criteria**: ✅ Health grade filter works

---

### Test 6: Autocomplete ✅

```bash
curl "http://localhost:3000/api/v1/products/autocomplete?q=cho"
```

**Expected**: Returns 10 suggestions starting with "cho"
**Pass Criteria**: ✅ Autocomplete works, < 50ms

---

### Test 7: Facets ✅

```bash
curl "http://localhost:3000/api/v1/products/search?q=snack&includeFacets=true"
```

**Expected**: Includes facets object with category/brand/grade counts
**Pass Criteria**: ✅ Facets calculated

---

### Test 8: Pagination ✅

```bash
# First page
curl ".../search?q=chocolate&limit=10"
# Use nextCursor in response
curl ".../search?q=chocolate&limit=10&cursor=<from-prev>"
```

**Expected**: No overlap, sequential results
**Pass Criteria**: ✅ Pagination works

---

### Test 9: Performance — 10K Products ✅

Seed 10,000 products, search:
```bash
time curl ".../search?q=chocolate"
# Expected: < 100ms
```

**Pass Criteria**: ✅ Fast search at scale

---

### Test 10: Tenant Isolation ✅

User from Tenant A searches:
**Expected**: Only Tenant A products returned
**Pass Criteria**: ✅ No cross-tenant leakage

---

### Test 11: Empty Query ✅

```bash
curl ".../search?q="
```

**Expected**: Returns recent products (no error)
**Pass Criteria**: ✅ Handles empty query

---

### Test 12: SQL Injection Attempt ✅

```bash
curl ".../search?q=' OR 1=1 --"
```

**Expected**: Treated as literal text (Drizzle parameterizes)
**Pass Criteria**: ✅ SQL injection prevented

---

### Test 13: Search Analytics ✅

After searches, check:
```sql
SELECT * FROM search_queries WHERE tenant_id = '...' ORDER BY created_at DESC LIMIT 10;
```

**Expected**: Recent searches logged
**Pass Criteria**: ✅ Analytics tracked

---

### Test 14: Index Usage ✅

```sql
EXPLAIN ANALYZE SELECT * FROM products 
WHERE tenant_id = '...' AND search_tsv @@ plainto_tsquery('chocolate');
```

**Expected**: Uses GIN index, < 10ms
**Pass Criteria**: ✅ Indexes used correctly

---

### Test 15: Ranking ✅

Search for "Coca Cola":
**Expected**: 
- Coca-Cola products first (name match)
- Coca brand products second
- Cola category products third

**Pass Criteria**: ✅ Relevance ranking works

---

## 🎯 Q&A Session

### Q1: Why PostgreSQL FTS instead of Elasticsearch?

**Expected Answer**:
- Already have PostgreSQL (no new infrastructure)
- 10K products: PG FTS plenty fast
- Simpler ops (one less service)
- ACID with main data
- Free (no Elastic cloud costs)
- Migration path: Move to ES when > 1M products

---

### Q2: Why tsvector with weights?

**Expected Answer**:
- Different fields have different importance
- Name match > Brand match > Description match
- A=name (highest), B=brand, C=description, D=ean
- Ranking algorithm uses weights
- Standard PG FTS pattern

---

### Q3: Why pg_trgm extension?

**Expected Answer**:
- Handles typos ("chocolat" matches "chocolate")
- Substring matching ("oco" finds "chocolate")
- Similarity scoring
- Backup when full-text doesn't match
- Indexed via GIN for performance

---

### Q4: Why separate count query?

**Expected Answer**:
- `COUNT(*)` over full result set is expensive
- With LIMIT, you only get partial count
- Some apps use approximate counts
- Cache count for popular queries
- Trade-off: Accurate count vs speed

---

### Q5: How does relevance ranking work?

**Expected Answer**:
- ts_rank() function in PostgreSQL
- Considers: word frequency, position, weights
- Higher rank = more relevant
- Custom boosting possible (popular products)
- Returned in ORDER BY

---

### Q6: Why facets in same query?

**Expected Answer**:
- Modern search UIs expect facets
- Without facets: "Show me categories you have"
- With facets: "Show me X products of which 50 in category Y"
- Helps users refine search
- Performance: Run as separate parallel queries

---

### Q7: How to handle search with no results?

**Expected Answer**:
- Return empty array (not error)
- Suggest related queries
- Show popular products
- Track failed searches for product additions
- Frontend shows helpful message

---

### Q8: Search analytics use cases?

**Expected Answer**:
- Find products users search but don't have
- Detect spelling issues users have
- Optimize for popular queries
- Detect trends (seasonal products)
- Improve search ranking with data

---

## 📝 Sign-Off Checklist

### Functional
- [ ] Full-text search works
- [ ] Trigram fuzzy matching works
- [ ] Filters work (category, brand, grade)
- [ ] Autocomplete returns suggestions
- [ ] Facets calculated correctly
- [ ] Pagination works

### Security
- [ ] Tenant isolation maintained
- [ ] SQL injection prevented (Drizzle params)
- [ ] Rate limiting on search

### Performance
- [ ] Search < 100ms for 10K products
- [ ] Autocomplete < 50ms
- [ ] Facets < 200ms
- [ ] Indexes used (verify EXPLAIN)

### Tests
- [ ] All 15 tests pass
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-15**
**☐ CHANGES REQUESTED**

---

**END OF BE-14 — DO NOT PROCEED WITHOUT APPROVAL**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-14 with explicit fuzzy-search SLOs and tenant scoping rules from Req 39.**

## Driver Requirement

- **Req 39** — `GET /api/v1/products/search?q=...` returns the top 20 fuzzy matches within 500 ms for queries up to 80 chars. Cache hits via Cache_Layer 5-minute TTL. Tenant scoping aligns with all other product endpoints.

## Scope of Update

The v1 search engine exists. v2 just hardens contract and SLOs:

1. Public global search returns from the public Product_Catalog (cross-tenant catalog).
2. Tenant-scoped search variants (saved products, inventory) honor `Tenant_Scope_Middleware`.
3. Common queries hit Cache_Layer with 5-minute TTL (per Req 39 / Req 43 alignment).
4. Top-20 cap is enforced and non-overridable for free tier.

## Files to Modify

| File Path | Change |
|---|---|
| `server/src/modules/search/controllers/search.controller.ts` | Add `?q` validation (1..80 chars), top-20 cap |
| `server/src/modules/search/services/search.service.ts` | Wrap with Cache_Layer 5-min TTL |

## ADDENDUM v2 Test Procedures (add 2)

| # | Test |
|---|---|
| T-v2.1 | Search returns ≤ 20 results in ≤ 500 ms (P95) |
| T-v2.2 | Tenant-scoped search (saved products) does NOT return cross-tenant rows |

## ADDENDUM v2 Sign-off

- [ ] SLO test green at P95
- [ ] Cache TTL applied
- [ ] Tenant scoping verified

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-14 ADDENDUM v2**
