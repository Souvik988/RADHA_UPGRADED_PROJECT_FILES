# Phase BE-12: Health Scoring Engine (Rule-based)

## Phase Metadata

- **Phase ID**: BE-12
- **Phase Name**: Health Scoring Engine
- **Section**: Backend Execution — Core Product Layer
- **Depends On**: BE-01 to BE-11
- **Blocks**: BE-13 (image health badges), reports, dashboards
- **Estimated Duration**: 2-3 days
- **Complexity**: Medium-High

## Goal

Build a rule-based health assessment engine for products: child suitability scoring, sugar/oil/sodium warnings, processed food classification, allergen alerts, versioned scoring rules (for compliance), and cached assessments. Free-first, no external API dependencies.

## Why This Phase Matters

Health scoring is RADHA's **unique differentiator**:
- Indian retail focus on child-safe products
- Schools need processed food alerts
- Pharmacies need allergen warnings
- Owners want health-grade visibility
- Compliance: Versioned rules for audit

Without health scoring:
- RADHA is just a barcode scanner
- No reason to choose RADHA over alternatives
- No premium feature for paid plans
- Mobile app missing key UX feature

## Prerequisites

- [ ] BE-01 to BE-11 completed
- [ ] Products with nutrition data exist (from BE-11)
- [ ] Database connection working

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/product_health_assessments.ts` | Assessment storage |
| `server/src/db/schema/health_rules.ts` | Versioned rule sets |
| `server/src/modules/health-scoring/health-scoring.module.ts` | Module |
| `server/src/modules/health-scoring/health-scoring.controller.ts` | Endpoints |
| `server/src/modules/health-scoring/health-scoring.service.ts` | Main service |
| `server/src/modules/health-scoring/services/scoring-engine.service.ts` | Rule engine |
| `server/src/modules/health-scoring/services/child-safety.service.ts` | Child-specific |
| `server/src/modules/health-scoring/services/allergen-detection.service.ts` | Allergen alerts |
| `server/src/modules/health-scoring/services/nutrition-grade.service.ts` | A-E grading |
| `server/src/modules/health-scoring/repositories/health-assessments.repository.ts` | Data |
| `server/src/modules/health-scoring/repositories/health-rules.repository.ts` | Rules data |
| `server/src/modules/health-scoring/rules/v1-rules.ts` | Rule version 1 |
| `server/src/modules/health-scoring/rules/v2-rules.ts` | Rule version 2 (future) |
| `server/src/modules/health-scoring/dto/score-product.dto.ts` | DTOs |
| `server/src/modules/health-scoring/types/health.types.ts` | Types |
| `server/src/modules/health-scoring/utils/score-calculator.utils.ts` | Calc utilities |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/health-scoring/health-scoring.service.ts

export interface IHealthScoringService {
  // Score a single product
  scoreProduct(productId: string): Promise<HealthAssessment>;
  
  // Recompute (force re-evaluation)
  recomputeScore(productId: string): Promise<HealthAssessment>;
  
  // Get cached assessment
  getAssessment(productId: string): Promise<HealthAssessment | null>;
  
  // Bulk scoring (for migrations or imports)
  bulkScore(productIds: string[]): Promise<HealthAssessment[]>;
  
  // Filter products by health criteria
  findHealthyProducts(filters: HealthFilters): Promise<Product[]>;
  
  // Get statistics
  getStats(tenantId: string): Promise<HealthStats>;
}

export interface IScoringEngine {
  // Run all rules and produce assessment
  evaluate(input: ScoringInput): Promise<ScoringOutput>;
  
  // Get rules by version
  getRules(version: string): HealthRule[];
  
  // Validate rule integrity
  validateRules(rules: HealthRule[]): RuleValidationResult;
}

export interface IChildSafetyService {
  // Determine child suitability
  evaluateForChildren(input: ScoringInput): ChildSafetyResult;
  
  // Age-specific recommendations
  evaluateForAge(input: ScoringInput, ageGroup: AgeGroup): AgeRecommendation;
}

export interface IAllergenDetectionService {
  // Detect allergens from nutrition + ingredients
  detectAllergens(product: Product, nutrition?: ProductNutrition): AllergenAlert[];
  
  // Check against user's allergen profile (future)
  matchUserAllergens(allergens: string[], userProfile: UserAllergenProfile): AllergenMatch[];
}

// Types

export interface ScoringInput {
  product: Product;
  nutrition?: ProductNutrition;
  ruleVersion?: string;
}

export interface ScoringOutput {
  overallGrade: 'A' | 'B' | 'C' | 'D' | 'E';
  overallScore: number; // 0-100
  childSafety: ChildSafetyResult;
  warnings: HealthWarning[];
  positives: HealthPositive[];
  allergens: AllergenAlert[];
  isProcessed: 'not' | 'lightly' | 'ultra';
  tags: string[];
  ruleVersion: string;
  computedAt: Date;
}

export interface ChildSafetyResult {
  status: 'suitable' | 'caution' | 'unsuitable';
  reasons: string[];
  ageRecommendation?: AgeGroup;
}

export interface HealthWarning {
  type: 'high_sugar' | 'high_oil' | 'high_sodium' | 'high_saturated_fat' | 'trans_fat' | 'ultra_processed' | 'artificial_sweetener' | 'other';
  severity: 'low' | 'medium' | 'high';
  message: string;
  threshold: number;
  actual: number;
  unit: string;
}

export interface HealthPositive {
  type: 'high_protein' | 'high_fiber' | 'low_sugar' | 'low_sodium' | 'no_trans_fat' | 'natural' | 'other';
  message: string;
}

export interface AllergenAlert {
  allergen: string;
  severity: 'mild' | 'moderate' | 'severe';
  source: 'declared' | 'detected' | 'cross-contamination';
}

export interface HealthRule {
  id: string;
  version: string;
  name: string;
  category: 'sugar' | 'oil' | 'sodium' | 'fat' | 'processing' | 'allergen' | 'positive';
  evaluator: (input: ScoringInput) => RuleResult;
  weight: number;
}

export interface RuleResult {
  triggered: boolean;
  score: number;
  warning?: HealthWarning;
  positive?: HealthPositive;
}

export type AgeGroup = 'infant' | 'toddler' | 'child' | 'adolescent' | 'adult';

export interface HealthFilters {
  childSafe?: boolean;
  noUltraProcessed?: boolean;
  maxSugarPer100g?: number;
  maxSodiumPer100g?: number;
  excludeAllergens?: string[];
  minGrade?: 'A' | 'B' | 'C' | 'D' | 'E';
}

export interface HealthStats {
  totalProducts: number;
  graded: { A: number; B: number; C: number; D: number; E: number };
  childSafe: number;
  ultraProcessed: number;
  withAllergens: number;
}
```

## Implementation Code

### 1. Health Assessments Schema

```typescript
// server/src/db/schema/product_health_assessments.ts
import { pgTable, uuid, varchar, jsonb, integer, timestamp, decimal, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';
import { products } from './products';

export const productHealthAssessments = pgTable(
  'product_health_assessments',
  {
    ...baseColumns,
    productId: uuid('product_id').notNull().references(() => products.id, { onDelete: 'cascade' }),
    
    overallGrade: varchar('overall_grade', { length: 1 }), // A-E
    overallScore: integer('overall_score'), // 0-100
    
    childSafetyStatus: varchar('child_safety_status', { length: 20 }), // suitable, caution, unsuitable
    childSafetyReasons: jsonb('child_safety_reasons').default([]),
    
    isProcessed: varchar('is_processed', { length: 20 }),
    
    warnings: jsonb('warnings').default([]),
    positives: jsonb('positives').default([]),
    allergens: jsonb('allergens').default([]),
    tags: jsonb('tags').default([]),
    
    ruleVersion: varchar('rule_version', { length: 10 }).notNull(),
    computedAt: timestamp('computed_at', { withTimezone: true }).notNull().defaultNow(),
    
    // Snapshot of inputs (for audit/recomputation)
    inputSnapshot: jsonb('input_snapshot'),
  },
  (table) => ({
    productIdx: index('idx_health_product').on(table.productId),
    gradeIdx: index('idx_health_grade').on(table.overallGrade),
    childSafetyIdx: index('idx_health_child_safety').on(table.childSafetyStatus),
  }),
);

export type ProductHealthAssessment = typeof productHealthAssessments.$inferSelect;
```

### 2. V1 Rules

```typescript
// server/src/modules/health-scoring/rules/v1-rules.ts
import { HealthRule } from '../types/health.types';

export const RULE_VERSION_V1 = '1.0.0';

export const v1Rules: HealthRule[] = [
  // SUGAR RULES
  {
    id: 'sugar-high',
    version: RULE_VERSION_V1,
    name: 'High Sugar Content',
    category: 'sugar',
    weight: 0.25,
    evaluator: (input) => {
      const sugar = input.nutrition?.sugars;
      if (!sugar) return { triggered: false, score: 0 };
      
      if (Number(sugar) > 22.5) {
        return {
          triggered: true,
          score: -25,
          warning: {
            type: 'high_sugar',
            severity: 'high',
            message: 'Very high sugar content',
            threshold: 22.5,
            actual: Number(sugar),
            unit: 'g/100g',
          },
        };
      } else if (Number(sugar) > 10) {
        return {
          triggered: true,
          score: -10,
          warning: {
            type: 'high_sugar',
            severity: 'medium',
            message: 'High sugar content',
            threshold: 10,
            actual: Number(sugar),
            unit: 'g/100g',
          },
        };
      }
      return { triggered: false, score: 0 };
    },
  },
  
  // OIL/FAT RULES
  {
    id: 'fat-high',
    version: RULE_VERSION_V1,
    name: 'High Fat Content',
    category: 'fat',
    weight: 0.20,
    evaluator: (input) => {
      const fat = input.nutrition?.fat;
      if (!fat) return { triggered: false, score: 0 };
      
      if (Number(fat) > 17.5) {
        return {
          triggered: true,
          score: -20,
          warning: {
            type: 'high_oil',
            severity: 'high',
            message: 'Very high fat content',
            threshold: 17.5,
            actual: Number(fat),
            unit: 'g/100g',
          },
        };
      } else if (Number(fat) > 15) {
        return {
          triggered: true,
          score: -10,
          warning: {
            type: 'high_oil',
            severity: 'medium',
            message: 'High fat content',
            threshold: 15,
            actual: Number(fat),
            unit: 'g/100g',
          },
        };
      }
      return { triggered: false, score: 0 };
    },
  },
  
  // SATURATED FAT
  {
    id: 'saturated-fat-high',
    version: RULE_VERSION_V1,
    name: 'High Saturated Fat',
    category: 'fat',
    weight: 0.15,
    evaluator: (input) => {
      const satFat = input.nutrition?.saturatedFat;
      if (!satFat) return { triggered: false, score: 0 };
      
      if (Number(satFat) > 5) {
        return {
          triggered: true,
          score: -15,
          warning: {
            type: 'high_saturated_fat',
            severity: 'high',
            message: 'High saturated fat',
            threshold: 5,
            actual: Number(satFat),
            unit: 'g/100g',
          },
        };
      }
      return { triggered: false, score: 0 };
    },
  },
  
  // TRANS FAT (always negative)
  {
    id: 'trans-fat',
    version: RULE_VERSION_V1,
    name: 'Trans Fat Detected',
    category: 'fat',
    weight: 0.20,
    evaluator: (input) => {
      const transFat = input.nutrition?.transFat;
      if (!transFat || Number(transFat) === 0) return { triggered: false, score: 0 };
      
      return {
        triggered: true,
        score: -30,
        warning: {
          type: 'trans_fat',
          severity: 'high',
          message: 'Contains trans fat',
          threshold: 0,
          actual: Number(transFat),
          unit: 'g/100g',
        },
      };
    },
  },
  
  // SODIUM
  {
    id: 'sodium-high',
    version: RULE_VERSION_V1,
    name: 'High Sodium',
    category: 'sodium',
    weight: 0.15,
    evaluator: (input) => {
      const sodium = input.nutrition?.sodium;
      if (!sodium) return { triggered: false, score: 0 };
      
      if (Number(sodium) > 600) {
        return {
          triggered: true,
          score: -15,
          warning: {
            type: 'high_sodium',
            severity: 'high',
            message: 'Very high sodium',
            threshold: 600,
            actual: Number(sodium),
            unit: 'mg/100g',
          },
        };
      } else if (Number(sodium) > 360) {
        return {
          triggered: true,
          score: -8,
          warning: {
            type: 'high_sodium',
            severity: 'medium',
            message: 'High sodium',
            threshold: 360,
            actual: Number(sodium),
            unit: 'mg/100g',
          },
        };
      }
      return { triggered: false, score: 0 };
    },
  },
  
  // ULTRA PROCESSED
  {
    id: 'ultra-processed',
    version: RULE_VERSION_V1,
    name: 'Ultra-Processed Food',
    category: 'processing',
    weight: 0.20,
    evaluator: (input) => {
      const processing = input.nutrition?.isProcessed;
      if (processing === 'ultra') {
        return {
          triggered: true,
          score: -20,
          warning: {
            type: 'ultra_processed',
            severity: 'high',
            message: 'Ultra-processed food',
            threshold: 4,
            actual: 4,
            unit: 'NOVA group',
          },
        };
      }
      return { triggered: false, score: 0 };
    },
  },
  
  // POSITIVE: HIGH PROTEIN
  {
    id: 'high-protein',
    version: RULE_VERSION_V1,
    name: 'High Protein',
    category: 'positive',
    weight: 0.10,
    evaluator: (input) => {
      const protein = input.nutrition?.protein;
      if (!protein || Number(protein) < 12) return { triggered: false, score: 0 };
      
      return {
        triggered: true,
        score: 10,
        positive: {
          type: 'high_protein',
          message: 'Good source of protein',
        },
      };
    },
  },
  
  // POSITIVE: HIGH FIBER
  {
    id: 'high-fiber',
    version: RULE_VERSION_V1,
    name: 'High Fiber',
    category: 'positive',
    weight: 0.10,
    evaluator: (input) => {
      const fiber = input.nutrition?.fiber;
      if (!fiber || Number(fiber) < 6) return { triggered: false, score: 0 };
      
      return {
        triggered: true,
        score: 10,
        positive: {
          type: 'high_fiber',
          message: 'High in fiber',
        },
      };
    },
  },
];
```

### 3. Scoring Engine

```typescript
// server/src/modules/health-scoring/services/scoring-engine.service.ts
import { Injectable } from '@nestjs/common';
import {
  IScoringEngine,
  ScoringInput,
  ScoringOutput,
  HealthRule,
  ChildSafetyResult,
} from '../types/health.types';
import { v1Rules, RULE_VERSION_V1 } from '../rules/v1-rules';
import { ChildSafetyService } from './child-safety.service';
import { AllergenDetectionService } from './allergen-detection.service';

@Injectable()
export class ScoringEngineService implements IScoringEngine {
  private readonly ruleSets = new Map<string, HealthRule[]>([
    [RULE_VERSION_V1, v1Rules],
  ]);

  constructor(
    private readonly childSafety: ChildSafetyService,
    private readonly allergenService: AllergenDetectionService,
  ) {}

  async evaluate(input: ScoringInput): Promise<ScoringOutput> {
    const version = input.ruleVersion || RULE_VERSION_V1;
    const rules = this.getRules(version);
    
    let totalScore = 100; // Start at 100 (perfect)
    const warnings = [];
    const positives = [];
    const tags: string[] = [];
    
    // Run all rules
    for (const rule of rules) {
      const result = rule.evaluator(input);
      if (!result.triggered) continue;
      
      totalScore += result.score;
      
      if (result.warning) {
        warnings.push(result.warning);
        tags.push(result.warning.type);
      }
      if (result.positive) {
        positives.push(result.positive);
        tags.push(result.positive.type);
      }
    }
    
    // Clamp score
    totalScore = Math.max(0, Math.min(100, totalScore));
    
    // Calculate grade
    const overallGrade = this.scoreToGrade(totalScore);
    
    // Child safety
    const childSafety = this.childSafety.evaluateForChildren(input);
    
    // Allergens
    const allergens = this.allergenService.detectAllergens(
      input.product,
      input.nutrition,
    );
    
    return {
      overallGrade,
      overallScore: totalScore,
      childSafety,
      warnings,
      positives,
      allergens,
      isProcessed: input.nutrition?.isProcessed || 'not',
      tags: [...new Set(tags)],
      ruleVersion: version,
      computedAt: new Date(),
    };
  }

  getRules(version: string): HealthRule[] {
    return this.ruleSets.get(version) || v1Rules;
  }

  validateRules(rules: HealthRule[]): { valid: boolean; errors: string[] } {
    const errors: string[] = [];
    const ids = new Set<string>();
    let totalWeight = 0;
    
    for (const rule of rules) {
      if (ids.has(rule.id)) {
        errors.push(`Duplicate rule ID: ${rule.id}`);
      }
      ids.add(rule.id);
      
      if (rule.weight < 0 || rule.weight > 1) {
        errors.push(`Rule ${rule.id} has invalid weight: ${rule.weight}`);
      }
      totalWeight += rule.weight;
    }
    
    return {
      valid: errors.length === 0,
      errors,
    };
  }

  private scoreToGrade(score: number): 'A' | 'B' | 'C' | 'D' | 'E' {
    if (score >= 80) return 'A';
    if (score >= 60) return 'B';
    if (score >= 40) return 'C';
    if (score >= 20) return 'D';
    return 'E';
  }
}
```

### 4. Child Safety Service

```typescript
// server/src/modules/health-scoring/services/child-safety.service.ts
import { Injectable } from '@nestjs/common';
import {
  IChildSafetyService,
  ScoringInput,
  ChildSafetyResult,
  AgeGroup,
  AgeRecommendation,
} from '../types/health.types';

@Injectable()
export class ChildSafetyService implements IChildSafetyService {
  
  evaluateForChildren(input: ScoringInput): ChildSafetyResult {
    const reasons: string[] = [];
    let status: 'suitable' | 'caution' | 'unsuitable' = 'suitable';
    
    // Check sugar
    const sugar = Number(input.nutrition?.sugars || 0);
    if (sugar > 22.5) {
      status = 'unsuitable';
      reasons.push(`Very high sugar (${sugar}g/100g)`);
    } else if (sugar > 10) {
      if (status !== 'unsuitable') status = 'caution';
      reasons.push(`High sugar (${sugar}g/100g)`);
    }
    
    // Check fat
    const fat = Number(input.nutrition?.fat || 0);
    if (fat > 17.5) {
      status = 'unsuitable';
      reasons.push(`Very high fat (${fat}g/100g)`);
    } else if (fat > 15) {
      if (status !== 'unsuitable') status = 'caution';
      reasons.push(`High fat (${fat}g/100g)`);
    }
    
    // Check trans fat (always disqualify)
    const transFat = Number(input.nutrition?.transFat || 0);
    if (transFat > 0) {
      status = 'unsuitable';
      reasons.push('Contains trans fat');
    }
    
    // Check ultra-processing
    if (input.nutrition?.isProcessed === 'ultra') {
      if (status !== 'unsuitable') status = 'caution';
      reasons.push('Ultra-processed food');
    }
    
    // Check sodium
    const sodium = Number(input.nutrition?.sodium || 0);
    if (sodium > 600) {
      if (status !== 'unsuitable') status = 'caution';
      reasons.push(`High sodium (${sodium}mg/100g)`);
    }
    
    return {
      status,
      reasons,
      ageRecommendation: this.suggestAgeGroup(input, status),
    };
  }

  evaluateForAge(input: ScoringInput, ageGroup: AgeGroup): AgeRecommendation {
    const baseResult = this.evaluateForChildren(input);
    
    // Stricter for younger children
    if (ageGroup === 'infant' || ageGroup === 'toddler') {
      if (baseResult.status === 'caution') {
        return {
          ...baseResult,
          status: 'unsuitable',
          ageGroup,
        } as any;
      }
    }
    
    return { ...baseResult, ageGroup } as any;
  }

  private suggestAgeGroup(
    input: ScoringInput,
    status: 'suitable' | 'caution' | 'unsuitable',
  ): AgeGroup | undefined {
    if (status === 'unsuitable') return undefined;
    if (status === 'caution') return 'adolescent';
    return 'child';
  }
}
```

## Database Tables Affected

| Table | Created/Modified | Purpose |
|---|---|---|
| `product_health_assessments` | CREATED | Cache scored results |
| `health_rules` | CREATED | Versioned rule storage |

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| GET | `/api/v1/products/:id/health` | Bearer | Get assessment |
| POST | `/api/v1/products/:id/health/recompute` | Bearer | Force recompute |
| POST | `/api/v1/products/health/bulk-recompute` | Admin | Recompute all |
| GET | `/api/v1/products/health/filter` | Bearer | Find by criteria |
| GET | `/api/v1/health-scoring/rules` | Bearer | Get current rules |
| GET | `/api/v1/health-scoring/stats` | Bearer | Statistics |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-13 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Score High Sugar Product ✅

```typescript
const input = {
  product: { /* product */ },
  nutrition: { sugars: 25, fat: 10, sodium: 200 },
};
const result = await engine.evaluate(input);
expect(result.warnings).toContainEqual(expect.objectContaining({ type: 'high_sugar' }));
expect(result.overallGrade).toBe('D');
expect(result.childSafety.status).toBe('unsuitable');
```

**Pass Criteria**: ✅ High sugar correctly flagged

---

### Test 2: Score Healthy Product ✅

```typescript
const input = {
  product: { /* product */ },
  nutrition: { protein: 20, fiber: 8, sugars: 2, fat: 5, sodium: 100, isProcessed: 'not' },
};
const result = await engine.evaluate(input);
expect(result.overallGrade).toBe('A');
expect(result.positives).toContainEqual(expect.objectContaining({ type: 'high_protein' }));
expect(result.childSafety.status).toBe('suitable');
```

**Pass Criteria**: ✅ Healthy products score high

---

### Test 3: Trans Fat Always Unsuitable ✅

```typescript
const input = {
  nutrition: { transFat: 1, sugars: 5, fat: 8 }, // Otherwise OK
};
const result = await engine.evaluate(input);
expect(result.childSafety.status).toBe('unsuitable');
expect(result.overallScore).toBeLessThan(70);
```

**Pass Criteria**: ✅ Trans fat is hard fail

---

### Test 4: Missing Nutrition Data ✅

```typescript
const input = { product: { /* product */ } }; // No nutrition
const result = await engine.evaluate(input);
expect(result.warnings).toHaveLength(0);
expect(result.tags).toContain('insufficient_data');
```

**Pass Criteria**: ✅ Handles missing data gracefully

---

### Test 5: Cached Assessment ✅

```bash
# First call - computes
curl http://localhost:3000/api/v1/products/<id>/health
# Time: ~50ms

# Second call - returns cached
curl http://localhost:3000/api/v1/products/<id>/health
# Time: <10ms
```

**Pass Criteria**: ✅ Caching works

---

### Test 6: Force Recompute ✅

```bash
curl -X POST http://localhost:3000/api/v1/products/<id>/health/recompute \
  -H "Authorization: Bearer <token>"
```

**Expected**: Re-evaluates rules, updates DB
**Pass Criteria**: ✅ Manual recompute works

---

### Test 7: Filter by Health Criteria ✅

```bash
curl "http://localhost:3000/api/v1/products/health/filter?childSafe=true&minGrade=B"
```

**Expected**: Returns only products matching criteria
**Pass Criteria**: ✅ Filtering works

---

### Test 8: Rule Validation ✅

```typescript
const validation = engine.validateRules(v1Rules);
expect(validation.valid).toBe(true);
```

**Pass Criteria**: ✅ Rule integrity verified

---

### Test 9: Ultra-Processed Detection ✅

Test with NOVA 4 product:
```typescript
const result = await engine.evaluate({ nutrition: { isProcessed: 'ultra' } });
expect(result.tags).toContain('ultra_processed');
expect(result.warnings).toContainEqual(expect.objectContaining({ type: 'ultra_processed' }));
```

**Pass Criteria**: ✅ Processing level affects score

---

### Test 10: Allergen Detection ✅

```typescript
const product = { /* with peanut category */ };
const nutrition = { containsAllergens: ['peanuts', 'milk'] };
const result = await engine.evaluate({ product, nutrition });
expect(result.allergens).toHaveLength(2);
```

**Pass Criteria**: ✅ Allergens detected

---

### Test 11: Bulk Scoring ✅

```bash
curl -X POST http://localhost:3000/api/v1/products/health/bulk-recompute \
  -H "Authorization: Bearer <admin>" \
  -d '{"productIds":["id1","id2","id3"]}'
```

**Expected**: All products scored, returned
**Pass Criteria**: ✅ Bulk scoring works

---

### Test 12: Rule Version Tracking ✅

Check DB:
```sql
SELECT rule_version, COUNT(*) FROM product_health_assessments GROUP BY rule_version;
```

**Expected**: All assessments have version
**Pass Criteria**: ✅ Version traceability

---

### Test 13: Stats Endpoint ✅

```bash
curl http://localhost:3000/api/v1/health-scoring/stats
```

**Expected**:
```json
{
  "totalProducts": 1000,
  "graded": { "A": 100, "B": 200, "C": 350, "D": 250, "E": 100 },
  "childSafe": 500,
  "ultraProcessed": 200
}
```

**Pass Criteria**: ✅ Stats accurate

---

### Test 14: Performance ✅

```bash
time curl http://localhost:3000/api/v1/products/<id>/health
# Expected: < 50ms (cached) or < 100ms (compute)
```

**Pass Criteria**: ✅ Fast scoring

---

### Test 15: Score Stability ✅

Run scoring 100 times on same product:
**Expected**: Same score each time (deterministic)
**Pass Criteria**: ✅ Rules are pure functions

---

## 🎯 Q&A Session

### Q1: Why rule-based instead of ML?

**Expected Answer**:
- Transparency — owners can explain decisions
- Consistency — same input → same output
- Compliance — regulators understand rules
- No training data needed
- Free — no ML infrastructure
- Easy to update — change rule, recompute

---

### Q2: Why versioned rules?

**Expected Answer**:
- Compliance: Audit trail of "what rules at time of decision"
- Backward compat: Old assessments stay valid
- Migration: Recompute over time, not all at once
- Testing: Can A/B test new rule versions
- Rollback: Revert to old rules if issues

---

### Q3: How thresholds were chosen?

**Expected Answer**:
- WHO recommendations for sugar/fat/sodium
- FSSAI (India) guidelines
- Nutri-Score (European standard)
- Indian retail context
- Pediatric guidelines for child safety
- Conservative on health (better safe than sorry)

---

### Q4: Why cache assessments?

**Expected Answer**:
- Computation: 50-100ms per product
- Lookup: < 5ms
- Recomputation only on rule version change
- Trade-off: Storage vs CPU
- Stale data acceptable (rules change rarely)

---

### Q5: How to handle products with no nutrition data?

**Expected Answer**:
- Don't fail, return partial assessment
- Tag with 'insufficient_data'
- Show "Data Unavailable" in mobile UI
- Encourage users to update product
- Score defaults to neutral (50)

---

### Q6: Allergen detection limitations?

**Expected Answer**:
- Relies on declared allergens (OFF data)
- Cross-contamination not always declared
- Trace allergens may be missed
- No medical advice — just alerts
- User confirms before relying

---

### Q7: How would rule v2 differ from v1?

**Expected Answer**:
- Lower thresholds (stricter)
- Add new rules (artificial sweeteners)
- Adjust weights based on data
- Add positive rules (organic, fortified)
- Region-specific rules (Indian palate)

---

### Q8: Could ML enhance this?

**Expected Answer**:
- Future: ML for category-specific thresholds
- Future: Personalized recommendations
- Future: Predict NOVA from ingredients
- Not now: Need data first
- Always: Keep rules as fallback (transparent)

---

## 📝 Sign-Off Checklist

### Functional
- [ ] All 15 tests pass
- [ ] Rule engine produces consistent scores
- [ ] Child safety logic correct
- [ ] Allergens detected
- [ ] Caching works
- [ ] Filtering works

### Code Quality
- [ ] Rules are pure functions
- [ ] No external API dependencies
- [ ] Versioning implemented
- [ ] All thresholds documented

### Performance
- [ ] Score computation < 100ms
- [ ] Cached lookup < 10ms
- [ ] Bulk scoring efficient

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

- [ ] Thresholds match WHO/FSSAI guidelines
- [ ] Rule versioning works
- [ ] No medical claims (just alerts)
- [ ] Tested with diverse product types

**☐ APPROVED — Proceed to BE-13**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF BE-12 — DO NOT PROCEED WITHOUT APPROVAL**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-12 with comprehensive scan output (Req 4) and Allergen_Profile matching at scan time (Req 32).**

## Driver Requirements

- **Req 4** — `GET /api/v1/products/{ean}/scan?mode=basic|comprehensive` with mode-specific response shapes including age-band child safety, ingredient PROS/CONS, consumption guidance, healthier alternatives.
- **Req 32** — When a Comprehensive_Scan_Output is requested, match product ingredients/allergens against the active Allergen_Profile and include matching flags.
- **Req 9 (BE-12 sub-section)** — Health_Indicator continues to use rule-based scoring without external API calls in the scan response path.

## Scope of Update

The Health Scoring engine must produce TWO output shapes from the same product data:

- **Basic_Scan_Output**: name, brand, traffic-light Health_Indicator, expiry status. Already covered in v1.
- **Comprehensive_Scan_Output**: full ingredients list, allergens, PROS, CONS with risks, age-band safety (infant 0-2, toddler 2-5, child 5-12, adolescent 12-18), consumption guidance, healthier-alternatives slot.

A separate phase (BE-41) provides the Healthier Alternatives recommendation list; this phase exposes the slot but defers selection to BE-41.
A separate phase (BE-37) owns the Allergen_Profile data; this phase merely consumes it via an injected `IAllergenProfileService`.

## Files to Modify

| File Path | Change |
|---|---|
| `server/src/modules/health-scoring/dto/scan-response.dto.ts` | Add `BasicScanOutputDto`, `ComprehensiveScanOutputDto` |
| `server/src/modules/health-scoring/services/health-scoring.service.ts` | Implement `score(ean, mode, allergenProfileId?)` |
| `server/src/modules/health-scoring/services/age-band-safety.service.ts` | New — age-band classification |
| `server/src/modules/health-scoring/services/consumption-guidance.service.ts` | New — guidance text generation |
| `server/src/modules/health-scoring/services/__tests__/comprehensive-output.spec.ts` | New |

## DTO Snippet

```typescript
export class BasicScanOutputDto {
  @ApiProperty() ean!: string;
  @ApiProperty() name!: string;
  @ApiProperty() brand!: string;
  @ApiProperty({ enum: ['green', 'yellow', 'red', 'data_unavailable'] })
  healthStatus!: HealthStatus;
  @ApiProperty({ enum: ['green', 'yellow', 'red', 'unknown'] })
  expiryStatus!: ExpiryStatus;
}

export class ComprehensiveScanOutputDto extends BasicScanOutputDto {
  @ApiProperty({ type: [String] }) ingredients!: string[];
  @ApiProperty({ type: [String] }) allergensDetected!: string[];
  @ApiProperty({ type: [String] }) pros!: string[];
  @ApiProperty({ type: [HealthConDto] }) cons!: HealthConDto[];
  @ApiProperty({ type: AgeBandSafetyDto }) ageBandSafety!: AgeBandSafetyDto;
  @ApiProperty() consumptionGuidance!: string;
  @ApiProperty({ type: [HealthierAlternativeStubDto] }) healthierAlternatives!: HealthierAlternativeStubDto[];
  @ApiProperty({ type: [AllergenMatchDto] }) allergenProfileMatches!: AllergenMatchDto[];
}

export class AgeBandSafetyDto {
  infantSafe!: boolean;          // 0-2 years
  toddlerSafe!: boolean;         // 2-5 years
  childSafe!: boolean;           // 5-12 years
  adolescentSafe!: boolean;      // 12-18 years
  rationale!: string;
}
```

## Service Contract (additions)

```typescript
export interface IHealthScoringService {
  // v1 method retained
  scoreBasic(ean: string): Promise<BasicScanOutputDto>;

  // NEW in v2
  scoreComprehensive(
    ean: string,
    options?: { allergenProfileId?: string; locale?: string },
  ): Promise<ComprehensiveScanOutputDto>;
}
```

## Allergen Matching Hook

```typescript
// Inside scoreComprehensive
const profile = options?.allergenProfileId
  ? await this.allergenProfiles.get(options.allergenProfileId)
  : undefined;

const matches = profile
  ? this.matchAllergens(product.ingredients, profile.tags)
  : [];

return {
  ...basic,
  ingredients: product.ingredients,
  allergensDetected: product.allergens,
  pros: this.computePros(product),
  cons: this.computeCons(product),
  ageBandSafety: this.ageBandService.classify(product),
  consumptionGuidance: this.guidanceService.generate(product),
  healthierAlternatives: [], // populated by BE-41 caller, not in this phase
  allergenProfileMatches: matches,
};
```

## ADDENDUM v2 Test Procedures (add 5)

| # | Test |
|---|---|
| T-v2.1 | `mode=basic` returns shape exactly equal to `BasicScanOutputDto` keys |
| T-v2.2 | `mode=comprehensive` returns full shape including age-band safety and consumption guidance |
| T-v2.3 | When nutritional data missing → `healthStatus = 'data_unavailable'`, all scoring degrades gracefully |
| T-v2.4 | When `allergenProfileId` provided, ingredients matching profile tags appear in `allergenProfileMatches` |
| T-v2.5 | Comprehensive scoring completes within 200 ms for cache-warm products |

## ADDENDUM v2 Q&A (add 3)

- **Q-v2.1**: How does the system avoid an N+1 query when comprehensive scanning across multiple products in a session?
- **Q-v2.2**: Where is the consumption-guidance template stored and how is it localized for Hindi/Tamil/Telugu/Bengali/Marathi (Req 34)?
- **Q-v2.3**: How does the engine ensure `healthierAlternatives` slot is opt-in only for Premium_Consumer or Comprehensive-eligible users (Req 35)?

## ADDENDUM v2 Sign-off

- [ ] Both modes implemented and tested (T-v2.1, T-v2.2)
- [ ] Allergen_Profile matching wired (T-v2.4)
- [ ] Performance budget held (T-v2.5)
- [ ] Localization hooks reserved
- [ ] No external API calls during scan response path

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-12 ADDENDUM v2**
