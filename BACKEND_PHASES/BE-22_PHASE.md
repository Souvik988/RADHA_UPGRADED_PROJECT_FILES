# Phase BE-22: AI/OCR Wrapper (Free-first)

## Phase Metadata

- **Phase ID**: BE-22
- **Phase Name**: AI/OCR Wrapper (Free-first)
- **Section**: Backend Execution — Advanced Features Layer
- **Depends On**: BE-01 to BE-21
- **Blocks**: BE-23, mobile OCR features
- **Estimated Duration**: 3 days
- **Complexity**: High

## Goal

Build a free-first AI/OCR abstraction layer with multiple providers, fallback chains, cost tracking per tenant, rate limiting, response caching, and graceful degradation. Default to Google ML Kit (free, on-device), fallback to Open Food Facts text extraction, optional escalation to AWS Rekognition (paid).

## Why This Phase Matters

AI is RADHA's premium feature, but costs must be controlled:
- OCR for expiry dates (mobile ML Kit on-device — FREE)
- Product label recognition (OFF data — FREE)
- Health summary generation (LLM — controlled)
- Image analysis (AWS Rekognition — PAID, opt-in)

Without proper abstraction:
- Provider lock-in
- Uncontrolled costs
- Cannot test without API keys
- Difficult to switch providers
- Poor cost visibility

## Prerequisites

- [ ] BE-01 to BE-21 completed
- [ ] Media management ready (BE-13)
- [ ] Reports ready (BE-20, BE-21)

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/ai_extractions.ts` | AI/OCR results |
| `server/src/db/schema/ai_usage_log.ts` | Cost tracking |
| `server/src/db/schema/ocr_attempts.ts` | OCR attempts |
| `server/src/integrations/ai/ai.module.ts` | Module |
| `server/src/integrations/ai/services/ai-orchestrator.service.ts` | Provider chain |
| `server/src/integrations/ai/services/ocr.service.ts` | OCR abstraction |
| `server/src/integrations/ai/services/llm.service.ts` | LLM abstraction |
| `server/src/integrations/ai/services/usage-tracker.service.ts` | Cost tracking |
| `server/src/integrations/ai/providers/ml-kit.provider.ts` | Google ML Kit (mobile-side hint) |
| `server/src/integrations/ai/providers/aws-rekognition.provider.ts` | AWS Rekognition |
| `server/src/integrations/ai/providers/openai.provider.ts` | OpenAI (optional) |
| `server/src/integrations/ai/providers/mock.provider.ts` | Mock for dev |
| `server/src/integrations/ai/types/ai.types.ts` | Types |
| `server/src/integrations/ai/utils/ocr-text-parser.utils.ts` | Parse OCR text |
| `server/src/modules/ai/ai.controller.ts` | API endpoints |
| `server/src/modules/ai/ai.service.ts` | Module service |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/integrations/ai/services/ai-orchestrator.service.ts

export interface IAiOrchestratorService {
  // OCR for expiry dates
  extractExpiryDate(mediaId: string, options?: OcrOptions): Promise<OcrResult>;
  
  // OCR for batch numbers
  extractBatchNumber(mediaId: string, options?: OcrOptions): Promise<OcrResult>;
  
  // Generic text extraction
  extractText(mediaId: string, options?: OcrOptions): Promise<OcrResult>;
  
  // Product label analysis
  analyzeProductLabel(mediaId: string): Promise<LabelAnalysisResult>;
  
  // LLM tasks
  generateReportSummary(reportData: any, options?: LlmOptions): Promise<LlmResult>;
  enrichProductData(productInfo: Partial<Product>): Promise<EnrichmentResult>;
  
  // Cost tracking
  getUsage(tenantId: string, dateRange: DateRange): Promise<UsageStats>;
  getEstimatedCost(operation: AiOperation, count: number): number;
}

export interface IOcrService {
  // Provider-agnostic OCR
  extractFromImage(imageBuffer: Buffer, options?: OcrOptions): Promise<OcrResult>;
  
  // Specific patterns
  extractDates(text: string): ExtractedDate[];
  extractNumbers(text: string, pattern?: RegExp): string[];
}

export interface IUsageTrackerService {
  // Track usage
  trackUsage(record: AiUsageRecord): Promise<void>;
  
  // Check limits
  checkLimit(tenantId: string, operation: AiOperation): Promise<LimitCheckResult>;
  
  // Get usage stats
  getUsageForTenant(tenantId: string, dateRange: DateRange): Promise<UsageStats>;
  getCostBreakdown(tenantId: string, dateRange: DateRange): Promise<CostBreakdown>;
}

export type AiProvider = 'mlkit' | 'rekognition' | 'openai' | 'openfoodfacts' | 'mock';

export type AiOperation =
  | 'ocr-expiry'
  | 'ocr-batch'
  | 'ocr-text'
  | 'label-analysis'
  | 'report-summary'
  | 'product-enrichment'
  | 'image-classification';

export interface OcrOptions {
  preferredProvider?: AiProvider;
  fallbackToPaid?: boolean;
  language?: string;
  confidenceThreshold?: number;
  patterns?: RegExp[];
}

export interface OcrResult {
  success: boolean;
  text: string;
  extractedData?: ExtractedFields;
  confidence: number;
  provider: AiProvider;
  cost: number;
  durationMs: number;
  warnings?: string[];
}

export interface ExtractedFields {
  dates?: ExtractedDate[];
  numbers?: string[];
  productCodes?: string[];
  text?: string;
}

export interface ExtractedDate {
  raw: string;
  parsed: Date;
  format: string;
  confidence: number;
}

export interface LabelAnalysisResult {
  productName?: string;
  brand?: string;
  category?: string;
  ingredients?: string[];
  allergens?: string[];
  nutritionalInfo?: Record<string, number>;
  confidence: number;
  provider: AiProvider;
}

export interface LlmOptions {
  maxTokens?: number;
  temperature?: number;
  provider?: 'openai' | 'mock';
}

export interface LlmResult {
  text: string;
  tokensUsed: number;
  cost: number;
  provider: AiProvider;
  durationMs: number;
}

export interface UsageStats {
  tenantId: string;
  period: DateRange;
  byOperation: Record<AiOperation, {
    count: number;
    totalCost: number;
    avgDurationMs: number;
  }>;
  totalCost: number;
  totalCalls: number;
}

export interface AiUsageRecord {
  tenantId: string;
  operation: AiOperation;
  provider: AiProvider;
  cost: number;
  durationMs: number;
  success: boolean;
  resourceId?: string;
  metadata?: Record<string, unknown>;
}

export interface LimitCheckResult {
  allowed: boolean;
  remaining: number;
  resetAt: Date;
  reason?: string;
}
```

## Implementation Code

### 1. AI Schemas

```typescript
// server/src/db/schema/ai_extractions.ts
import { pgTable, varchar, uuid, integer, timestamp, jsonb, decimal, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const aiOperationEnum = pgEnum('ai_operation', [
  'ocr-expiry',
  'ocr-batch',
  'ocr-text',
  'label-analysis',
  'report-summary',
  'product-enrichment',
  'image-classification',
]);

export const aiProviderEnum = pgEnum('ai_provider', [
  'mlkit',
  'rekognition',
  'openai',
  'openfoodfacts',
  'mock',
]);

export const aiExtractions = pgTable(
  'ai_extractions',
  {
    ...baseColumns,
    tenantId: uuid('tenant_id').notNull(),
    
    operation: aiOperationEnum('operation').notNull(),
    provider: aiProviderEnum('provider').notNull(),
    
    // Source
    sourceType: varchar('source_type', { length: 50 }), // 'media', 'text', 'product'
    sourceId: uuid('source_id'),
    
    // Result
    success: varchar('success', { length: 5 }).notNull(),
    extractedText: varchar('extracted_text', { length: 5000 }),
    extractedData: jsonb('extracted_data'),
    confidence: decimal('confidence', { precision: 3, scale: 2 }),
    
    // Tracking
    durationMs: integer('duration_ms'),
    cost: decimal('cost', { precision: 10, scale: 6 }),
    tokensUsed: integer('tokens_used'),
    
    // User context
    userId: uuid('user_id'),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    sourceIdx: index('idx_ai_source').on(table.sourceType, table.sourceId),
    operationStatusIdx: index('idx_ai_operation_status').on(table.operation, table.success),
    tenantOperationIdx: index('idx_ai_tenant_operation').on(table.tenantId, table.operation),
  }),
);

export type AiExtraction = typeof aiExtractions.$inferSelect;
```

### 2. Usage Log Schema

```typescript
// server/src/db/schema/ai_usage_log.ts
import { pgTable, uuid, integer, timestamp, decimal, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const aiUsageLog = pgTable(
  'ai_usage_log',
  {
    ...baseColumns,
    tenantId: uuid('tenant_id').notNull(),
    userId: uuid('user_id'),
    
    operation: varchar('operation', { length: 50 }).notNull(),
    provider: varchar('provider', { length: 50 }).notNull(),
    
    cost: decimal('cost', { precision: 10, scale: 6 }).notNull().default('0'),
    durationMs: integer('duration_ms').notNull(),
    
    success: varchar('success', { length: 5 }).notNull().default('true'),
    
    // For aggregation
    yearMonth: varchar('year_month', { length: 7 }).notNull(), // YYYY-MM
    yearMonthDay: varchar('year_month_day', { length: 10 }).notNull(), // YYYY-MM-DD
  },
  (table) => ({
    tenantMonthIdx: index('idx_ai_usage_tenant_month').on(table.tenantId, table.yearMonth),
    operationIdx: index('idx_ai_usage_operation').on(table.operation),
    dailyIdx: index('idx_ai_usage_daily').on(table.tenantId, table.yearMonthDay),
  }),
);
```

### 3. AI Orchestrator Service

```typescript
// server/src/integrations/ai/services/ai-orchestrator.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '../../../config/config.service';
import { OcrService } from './ocr.service';
import { LlmService } from './llm.service';
import { UsageTrackerService } from './usage-tracker.service';
import { AwsRekognitionProvider } from '../providers/aws-rekognition.provider';
import { OpenAiProvider } from '../providers/openai.provider';
import { MockAiProvider } from '../providers/mock.provider';
import { S3Service } from '../../aws/s3/s3.service';
import { MediaService } from '../../../modules/media/media.service';
import { AiExtractionsRepository } from '../repositories/ai-extractions.repository';
import { LoggerService } from '../../../logging/logger.service';
import { RequestContextService } from '../../../common/context/request-context.service';
import {
  IAiOrchestratorService,
  OcrOptions,
  OcrResult,
  LabelAnalysisResult,
  LlmResult,
  EnrichmentResult,
  AiOperation,
  AiProvider,
} from '../types/ai.types';
import { BusinessException } from '../../../common/errors/business.exception';
import { ErrorCode } from '../../../common/errors/error-codes';

@Injectable()
export class AiOrchestratorService implements IAiOrchestratorService {
  private readonly logger = new Logger(AiOrchestratorService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly ocrService: OcrService,
    private readonly llmService: LlmService,
    private readonly usageTracker: UsageTrackerService,
    private readonly rekognition: AwsRekognitionProvider,
    private readonly openai: OpenAiProvider,
    private readonly mock: MockAiProvider,
    private readonly s3: S3Service,
    private readonly mediaService: MediaService,
    private readonly extractionsRepo: AiExtractionsRepository,
    private readonly contextService: RequestContextService,
    private readonly appLogger: LoggerService,
  ) {}

  async extractExpiryDate(mediaId: string, options: OcrOptions = {}): Promise<OcrResult> {
    const tenantId = this.contextService.getTenantId()!;
    
    // Check limits
    const limitCheck = await this.usageTracker.checkLimit(tenantId, 'ocr-expiry');
    if (!limitCheck.allowed) {
      throw new BusinessException(
        ErrorCode.PLAN_LIMIT_EXCEEDED,
        limitCheck.reason || 'AI usage limit exceeded',
      );
    }
    
    const startTime = Date.now();
    
    // Strategy: Mobile sends OCR text from ML Kit, server parses
    // OR fallback to AWS Rekognition if mobile didn't OCR
    const media = await this.mediaService.findById(mediaId);
    if (!media) {
      throw new BusinessException(ErrorCode.NOT_FOUND, 'Media not found');
    }
    
    let result: OcrResult;
    
    // Try mobile-extracted text first (passed in options)
    if ((options as any).preExtractedText) {
      result = await this.ocrService.extractFromImage(
        Buffer.from(''), // Not needed
        { ...options, preExtractedText: (options as any).preExtractedText } as any,
      );
    } else if (options.fallbackToPaid && this.config.features.enableAwsRekognition) {
      // Fall back to Rekognition for label detection
      const buffer = await this.s3.downloadObject(media.s3Key);
      result = await this.rekognition.extractText(buffer);
    } else {
      // No OCR available - return empty result
      result = {
        success: false,
        text: '',
        confidence: 0,
        provider: 'mock' as AiProvider,
        cost: 0,
        durationMs: Date.now() - startTime,
        warnings: ['No OCR provider available — use mobile ML Kit'],
      };
    }
    
    // Parse extracted text for dates
    if (result.success && result.text) {
      const dates = this.ocrService.extractDates(result.text);
      result.extractedData = { dates };
    }
    
    // Track usage
    await this.usageTracker.trackUsage({
      tenantId,
      operation: 'ocr-expiry',
      provider: result.provider,
      cost: result.cost,
      durationMs: result.durationMs,
      success: result.success,
      resourceId: mediaId,
    });
    
    // Save extraction record
    await this.extractionsRepo.create({
      operation: 'ocr-expiry',
      provider: result.provider,
      sourceType: 'media',
      sourceId: mediaId,
      success: String(result.success),
      extractedText: result.text.slice(0, 5000),
      extractedData: result.extractedData as any,
      confidence: String(result.confidence),
      durationMs: result.durationMs,
      cost: String(result.cost),
      userId: this.contextService.getUserId(),
    });
    
    return result;
  }

  async extractBatchNumber(mediaId: string, options: OcrOptions = {}): Promise<OcrResult> {
    const result = await this.extractText(mediaId, {
      ...options,
      patterns: [/[A-Z]{1,3}\d{4,8}/, /BATCH[:\s]+([A-Z0-9]+)/i],
    });
    
    if (result.success && result.text) {
      const numbers = this.ocrService.extractNumbers(result.text, /\b[A-Z]{1,3}\d{4,8}\b/);
      result.extractedData = { numbers };
    }
    
    return result;
  }

  async extractText(mediaId: string, options: OcrOptions = {}): Promise<OcrResult> {
    return this.extractExpiryDate(mediaId, options);
  }

  async analyzeProductLabel(mediaId: string): Promise<LabelAnalysisResult> {
    const tenantId = this.contextService.getTenantId()!;
    
    // Check limits
    const limitCheck = await this.usageTracker.checkLimit(tenantId, 'label-analysis');
    if (!limitCheck.allowed) {
      throw new BusinessException(
        ErrorCode.PLAN_LIMIT_EXCEEDED,
        'AI label analysis limit exceeded',
      );
    }
    
    if (!this.config.features.enableAwsRekognition) {
      return {
        confidence: 0,
        provider: 'mock' as AiProvider,
      };
    }
    
    const media = await this.mediaService.findById(mediaId);
    if (!media) {
      throw new BusinessException(ErrorCode.NOT_FOUND, 'Media not found');
    }
    
    const buffer = await this.s3.downloadObject(media.s3Key);
    return this.rekognition.analyzeProductLabel(buffer);
  }

  async generateReportSummary(reportData: any, options: any = {}): Promise<LlmResult> {
    const tenantId = this.contextService.getTenantId()!;
    
    if (!this.config.features.enableLlmSummaries) {
      // Fallback to template-based summary
      return {
        text: this.generateTemplateSummary(reportData),
        tokensUsed: 0,
        cost: 0,
        provider: 'mock' as AiProvider,
        durationMs: 5,
      };
    }
    
    return this.llmService.generateSummary(reportData, options);
  }

  async enrichProductData(productInfo: Partial<Product>): Promise<EnrichmentResult> {
    // Free path: OFF lookup (BE-11) already handled
    // Paid path: LLM enrichment
    
    if (!this.config.features.enableLlmSummaries) {
      return {
        enriched: false,
        provider: 'openfoodfacts',
        data: productInfo,
      };
    }
    
    return this.llmService.enrichProduct(productInfo);
  }

  async getUsage(tenantId: string, dateRange: DateRange): Promise<UsageStats> {
    return this.usageTracker.getUsageForTenant(tenantId, dateRange);
  }

  getEstimatedCost(operation: AiOperation, count: number): number {
    const costs: Record<AiOperation, number> = {
      'ocr-expiry': 0,           // Free (mobile ML Kit)
      'ocr-batch': 0,             // Free
      'ocr-text': 0,              // Free
      'label-analysis': 0.001,    // AWS Rekognition $0.001/image
      'report-summary': 0.005,    // OpenAI ~$0.005/summary
      'product-enrichment': 0.003,
      'image-classification': 0.001,
    };
    
    return (costs[operation] || 0) * count;
  }

  private generateTemplateSummary(reportData: any): string {
    // Simple template-based summary (no LLM needed)
    const summary = reportData.summary || {};
    const parts = [];
    
    if (summary.totalScans) {
      parts.push(`Total scans: ${summary.totalScans}`);
    }
    if (summary.matchedScans) {
      const rate = summary.totalScans > 0 
        ? Math.round((summary.matchedScans / summary.totalScans) * 100)
        : 0;
      parts.push(`Match rate: ${rate}%`);
    }
    if (summary.expiredItems) {
      parts.push(`Expired items: ${summary.expiredItems}`);
    }
    
    return parts.length > 0 
      ? `Report Summary: ${parts.join('. ')}.`
      : 'No data available for summary.';
  }
}
```

### 4. OCR Service

```typescript
// server/src/integrations/ai/services/ocr.service.ts
import { Injectable } from '@nestjs/common';
import { IOcrService, OcrOptions, OcrResult, ExtractedDate } from '../types/ai.types';

@Injectable()
export class OcrService implements IOcrService {
  
  async extractFromImage(buffer: Buffer, options: OcrOptions = {}): Promise<OcrResult> {
    // Mobile ML Kit handles actual image-to-text on device
    // Server-side OCR uses pre-extracted text
    
    const preText = (options as any).preExtractedText;
    if (preText) {
      return {
        success: true,
        text: preText,
        confidence: (options as any).confidence || 0.8,
        provider: 'mlkit',
        cost: 0,
        durationMs: 1,
      };
    }
    
    return {
      success: false,
      text: '',
      confidence: 0,
      provider: 'mock',
      cost: 0,
      durationMs: 0,
      warnings: ['No OCR provider configured server-side'],
    };
  }

  extractDates(text: string): ExtractedDate[] {
    const dates: ExtractedDate[] = [];
    const patterns = [
      { regex: /\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})\b/g, format: 'DD/MM/YYYY' },
      { regex: /\b(\d{1,2})[\/\-\.](\d{2,4})\b/g, format: 'MM/YYYY' },
      { regex: /\bEXP[:\s]*(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})\b/gi, format: 'EXP DD/MM/YYYY' },
      { regex: /\bMFG[:\s]*(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})\b/gi, format: 'MFG DD/MM/YYYY' },
    ];
    
    for (const { regex, format } of patterns) {
      let match;
      regex.lastIndex = 0;
      while ((match = regex.exec(text)) !== null) {
        const date = this.parseDate(match, format);
        if (date && this.isValidDate(date)) {
          dates.push({
            raw: match[0],
            parsed: date,
            format,
            confidence: 0.85,
          });
        }
      }
    }
    
    return dates;
  }

  extractNumbers(text: string, pattern?: RegExp): string[] {
    const regex = pattern || /\b\d+\b/g;
    return Array.from(text.matchAll(regex)).map((m) => m[0]);
  }

  private parseDate(match: RegExpMatchArray, format: string): Date | null {
    try {
      if (format.includes('DD/MM/YYYY') || format.includes('EXP') || format.includes('MFG')) {
        const day = parseInt(match[1]);
        const month = parseInt(match[2]) - 1;
        let year = parseInt(match[3]);
        if (year < 100) year += 2000;
        return new Date(year, month, day);
      }
      
      if (format === 'MM/YYYY') {
        const month = parseInt(match[1]);
        let year = parseInt(match[2]);
        if (year < 100) year += 2000;
        // Default to last day of month for expiry dates
        return new Date(year, month, 0);
      }
    } catch {
      return null;
    }
    return null;
  }

  private isValidDate(date: Date): boolean {
    if (isNaN(date.getTime())) return false;
    
    const now = new Date();
    const tenYearsAgo = new Date(now.getFullYear() - 10, 0, 1);
    const tenYearsFuture = new Date(now.getFullYear() + 10, 0, 1);
    
    return date >= tenYearsAgo && date <= tenYearsFuture;
  }
}
```

### 5. Mock Provider

```typescript
// server/src/integrations/ai/providers/mock.provider.ts
import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class MockAiProvider {
  private readonly logger = new Logger(MockAiProvider.name);

  async extractText(buffer: Buffer): Promise<any> {
    this.logger.warn('🤖 [MOCK AI] Extracting text from image');
    return {
      success: true,
      text: 'EXP: 31/12/2024 BATCH: ABC1234',
      confidence: 0.85,
      provider: 'mock',
      cost: 0,
      durationMs: 50,
    };
  }

  async analyzeLabel(buffer: Buffer): Promise<any> {
    this.logger.warn('🤖 [MOCK AI] Analyzing product label');
    return {
      productName: 'Mock Product',
      brand: 'Mock Brand',
      category: 'snacks',
      confidence: 0.80,
      provider: 'mock',
    };
  }

  async generateSummary(data: any): Promise<any> {
    return {
      text: '[Mock] Summary of report data.',
      tokensUsed: 50,
      cost: 0,
      provider: 'mock',
      durationMs: 100,
    };
  }
}
```

### 6. Usage Tracker Service

```typescript
// server/src/integrations/ai/services/usage-tracker.service.ts
import { Injectable } from '@nestjs/common';
import { DbService } from '../../../db/db.service';
import { aiUsageLog } from '../../../db/schema/ai_usage_log';
import { eq, and, gte, lte, sql } from 'drizzle-orm';
import {
  IUsageTrackerService,
  AiUsageRecord,
  LimitCheckResult,
  UsageStats,
  AiOperation,
} from '../types/ai.types';

@Injectable()
export class UsageTrackerService implements IUsageTrackerService {
  // Default monthly limits per operation (can be overridden per tenant plan)
  private readonly DEFAULT_LIMITS: Record<AiOperation, number> = {
    'ocr-expiry': 10000,         // Free, generous
    'ocr-batch': 10000,
    'ocr-text': 10000,
    'label-analysis': 100,        // Paid, controlled
    'report-summary': 100,
    'product-enrichment': 500,
    'image-classification': 500,
  };

  constructor(private readonly db: DbService) {}

  async trackUsage(record: AiUsageRecord): Promise<void> {
    const now = new Date();
    const yearMonth = now.toISOString().slice(0, 7);
    const yearMonthDay = now.toISOString().slice(0, 10);
    
    await this.db.getDb().insert(aiUsageLog).values({
      tenantId: record.tenantId,
      userId: (record as any).userId,
      operation: record.operation,
      provider: record.provider,
      cost: record.cost.toString(),
      durationMs: record.durationMs,
      success: record.success.toString(),
      yearMonth,
      yearMonthDay,
    });
  }

  async checkLimit(tenantId: string, operation: AiOperation): Promise<LimitCheckResult> {
    const limit = this.DEFAULT_LIMITS[operation] || 1000;
    
    const yearMonth = new Date().toISOString().slice(0, 7);
    
    const result = await this.db.getDb()
      .select({ count: sql<number>`count(*)::int` })
      .from(aiUsageLog)
      .where(and(
        eq(aiUsageLog.tenantId, tenantId),
        eq(aiUsageLog.operation, operation),
        eq(aiUsageLog.yearMonth, yearMonth),
        eq(aiUsageLog.success, 'true'),
      ));
    
    const used = result[0]?.count || 0;
    const remaining = Math.max(0, limit - used);
    
    // Reset at start of next month
    const resetAt = new Date();
    resetAt.setMonth(resetAt.getMonth() + 1);
    resetAt.setDate(1);
    resetAt.setHours(0, 0, 0, 0);
    
    return {
      allowed: used < limit,
      remaining,
      resetAt,
      reason: used >= limit ? `Monthly limit of ${limit} reached for ${operation}` : undefined,
    };
  }

  async getUsageForTenant(tenantId: string, dateRange: any): Promise<UsageStats> {
    const result = await this.db.getDb()
      .select({
        operation: aiUsageLog.operation,
        count: sql<number>`count(*)::int`,
        totalCost: sql<string>`sum(cost)`,
        avgDurationMs: sql<number>`avg(duration_ms)::int`,
      })
      .from(aiUsageLog)
      .where(and(
        eq(aiUsageLog.tenantId, tenantId),
        gte(aiUsageLog.createdAt, dateRange.from),
        lte(aiUsageLog.createdAt, dateRange.to),
      ))
      .groupBy(aiUsageLog.operation);
    
    const byOperation: any = {};
    let totalCost = 0;
    let totalCalls = 0;
    
    for (const row of result) {
      byOperation[row.operation] = {
        count: row.count,
        totalCost: parseFloat(row.totalCost || '0'),
        avgDurationMs: row.avgDurationMs,
      };
      totalCost += parseFloat(row.totalCost || '0');
      totalCalls += row.count;
    }
    
    return {
      tenantId,
      period: dateRange,
      byOperation,
      totalCost,
      totalCalls,
    };
  }

  async getCostBreakdown(tenantId: string, dateRange: any): Promise<any> {
    return this.getUsageForTenant(tenantId, dateRange);
  }
}
```

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| POST | `/api/v1/ai/ocr/expiry` | Bearer | OCR for expiry date |
| POST | `/api/v1/ai/ocr/batch` | Bearer | OCR for batch number |
| POST | `/api/v1/ai/ocr/text` | Bearer | Generic OCR |
| POST | `/api/v1/ai/label/analyze` | Bearer | Analyze label (paid) |
| POST | `/api/v1/ai/report/summary` | Bearer | Generate report summary |
| GET | `/api/v1/ai/usage` | Bearer | Tenant usage stats |
| GET | `/api/v1/ai/limits` | Bearer | Current limits |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-23 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: OCR Expiry Date — Mobile Pre-extracted ✅
Mobile sends image + ML Kit text:
```bash
curl -X POST .../ai/ocr/expiry -d '{
  "mediaId":"<id>",
  "preExtractedText":"EXP: 31/12/2024 BATCH: ABC1234"
}'
```
**Expected**: Returns parsed dates, confidence
**Pass Criteria**: ✅ Mobile-side OCR works, server parses

### Test 2: Date Pattern Recognition ✅
Test all date formats:
- "EXP 31/12/2024" → Dec 31, 2024 ✅
- "12/2024" → Dec 31, 2024 (last day) ✅
- "MFG 01/06/24" → Jun 1, 2024 ✅

**Pass Criteria**: ✅ All formats parsed

### Test 3: Sanity Checks ✅
- Date 50 years in past → rejected ✅
- Date 50 years in future → rejected ✅

**Pass Criteria**: ✅ Invalid dates filtered

### Test 4: Cost Tracking ✅
After OCR call:
```sql
SELECT * FROM ai_usage_log;
```
**Expected**: Entry with cost, duration, success
**Pass Criteria**: ✅ Usage logged

### Test 5: Monthly Limits ✅
Set limit to 5, make 6 calls:
**Expected**: 6th returns PLAN_LIMIT_EXCEEDED
**Pass Criteria**: ✅ Limits enforced

### Test 6: Usage Stats ✅
```bash
curl .../ai/usage
```
**Expected**: Counts and costs by operation
**Pass Criteria**: ✅ Stats accurate

### Test 7: Free vs Paid Operations ✅
- OCR (mlkit): cost = $0
- Label analysis (rekognition): cost = $0.001

**Pass Criteria**: ✅ Cost differentiation

### Test 8: Mock Provider in Dev ✅
Without real AI keys:
**Expected**: Mock returns sample data
**Pass Criteria**: ✅ Dev works without keys

### Test 9: Provider Fallback ✅
Try Rekognition (disabled) → falls back to mock
**Pass Criteria**: ✅ Graceful degradation

### Test 10: Report Summary ✅
**Expected**: Template-based if LLM disabled, AI if enabled
**Pass Criteria**: ✅ Both paths work

### Test 11: Tenant Isolation ✅
Tenant A usage doesn't affect Tenant B limits
**Pass Criteria**: ✅ Per-tenant tracking

### Test 12: AI Extraction Audit ✅
Every AI call logged in `ai_extractions`:
**Expected**: Source, result, confidence preserved
**Pass Criteria**: ✅ Compliance trail

### Test 13: Performance ✅
OCR call (mock): < 100ms
**Pass Criteria**: ✅ Fast enough

### Test 14: Error Handling ✅
Invalid mediaId → graceful error
S3 failure → graceful error
**Pass Criteria**: ✅ No crashes

### Test 15: Concurrent Calls ✅
50 concurrent OCR calls:
**Expected**: All complete, usage tracked correctly
**Pass Criteria**: ✅ No race conditions

## 🎯 Q&A Session

### Q1: Why Mobile ML Kit instead of server OCR?
**Expected**: Free, on-device privacy, no server costs, instant feedback, works offline

### Q2: Why abstract behind orchestrator?
**Expected**: Provider-agnostic, easy to swap, testable, cost control

### Q3: Why monthly limits?
**Expected**: Cost predictability, prevent runaway, plan tier differentiation

### Q4: Why save extractions?
**Expected**: Audit, debug AI quality, compliance, retraining data (future)

### Q5: How to handle low confidence?
**Expected**: Return with warnings, mobile asks user to confirm, never auto-save

### Q6: Why template summaries before LLM?
**Expected**: Free fallback, deterministic output, no API dependency, faster

### Q7: How to scale AI usage?
**Expected**: Background queue, batching, caching results, plan limits

### Q8: How to switch providers?
**Expected**: Add provider class, update orchestrator, test, deploy. No DB changes.

## 📝 Sign-Off Checklist

- [ ] All 15 tests pass
- [ ] Free path works (mobile ML Kit)
- [ ] Paid path optional (Rekognition)
- [ ] Cost tracking accurate
- [ ] Limits enforced
- [ ] Mock provider works
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-23**
**☐ CHANGES REQUESTED**

---

**END OF BE-22 — DO NOT PROCEED WITHOUT APPROVAL**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-22 (AI/OCR Wrapper) with hooks for the Image OCR Fallback (Req 38) and the AI Ingredient Explainer (Req 45).**

## Driver Requirements

- **Req 38** — `POST /api/v1/scan/image-fallback` — owned by BE-45 — uses this phase's AI/OCR abstraction.
- **Req 45** — `GET /api/v1/ingredients/{ingredient_slug}/explanation` — owned by BE-40 — uses this phase's LLM abstraction.

## Scope of Update

The v1 phase defines a vendor-agnostic AI/OCR wrapper. v2 confirms the wrapper exposes the two capabilities required:

1. `IImageRecognitionProvider` — backed by Google Cloud Vision (paid, ₹0.001/image) or self-hosted ML; consumed by BE-45.
2. `ILlmProvider` — backed by OpenAI or Claude; consumed by BE-40 with permanent caching of explanations.

This phase ships the providers; consumer phases call them.

## Files to Modify

| File Path | Change |
|---|---|
| `server/src/modules/ai/providers/google-cloud-vision.provider.ts` | New impl of `IImageRecognitionProvider` |
| `server/src/modules/ai/providers/openai.provider.ts` | New impl of `ILlmProvider` |
| `server/src/modules/ai/services/cost-tracker.service.ts` | Track per-tenant per-provider cost (per Req 38, Req 45) |

## ADDENDUM v2 Test Procedures (add 3)

| # | Test |
|---|---|
| T-v2.1 | Cost tracker increments per-tenant counters on each provider call |
| T-v2.2 | Provider abstractions are injectable so BE-45 and BE-40 can use mocks in tests |
| T-v2.3 | LLM call timing out at 10s returns a graceful failure to caller (used by BE-40) |

## ADDENDUM v2 Sign-off

- [ ] Vision provider live
- [ ] LLM provider live
- [ ] Cost tracker tested

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-22 ADDENDUM v2**
