# Phase BE-15: EAN List Import & Validation

## Phase Metadata

- **Phase ID**: BE-15
- **Phase Name**: EAN List Import & Validation
- **Section**: Backend Execution — Audit & Compliance Layer
- **Depends On**: BE-01 to BE-14
- **Blocks**: BE-16 (scan validation against EAN lists)
- **Estimated Duration**: 3 days
- **Complexity**: High

## Goal

Build robust Excel/CSV upload system for approved EAN lists: file validation, parsing with error handling, EAN format validation per row, async processing for large files, error reporting with line numbers, list versioning, EAN matching engine, and import audit trail.

## Why This Phase Matters

EAN list management is RADHA's **core compliance feature**:
- Retail chains need approved product lists
- Audit teams verify "only approved products on shelf"
- Excel is industry standard format
- Lists can have 10,000+ rows
- Errors must be specific (which row failed)
- Lists need versioning (which list active when)

Without proper EAN import:
- Manual entry of 1000s of EANs is impossible
- No audit trail
- Can't enforce compliance
- Premium feature missing

## Prerequisites

- [ ] BE-01 to BE-14 completed
- [ ] S3 ready for file uploads (BE-13)
- [ ] Bull queue configured (BE-01)

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/ean_lists.ts` | EAN list metadata |
| `server/src/db/schema/ean_list_items.ts` | Individual EANs |
| `server/src/db/schema/ean_import_errors.ts` | Failed rows |
| `server/src/db/schema/import_batches.ts` | Import job tracking |
| `server/src/modules/ean-lists/ean-lists.module.ts` | Module |
| `server/src/modules/ean-lists/ean-lists.controller.ts` | Endpoints |
| `server/src/modules/ean-lists/ean-lists.service.ts` | Business logic |
| `server/src/modules/ean-lists/services/file-upload.service.ts` | File handling |
| `server/src/modules/ean-lists/services/excel-parser.service.ts` | Excel parsing |
| `server/src/modules/ean-lists/services/csv-parser.service.ts` | CSV parsing |
| `server/src/modules/ean-lists/services/ean-validator.service.ts` | Per-row validation |
| `server/src/modules/ean-lists/services/import-processor.service.ts` | Import orchestration |
| `server/src/modules/ean-lists/services/ean-matcher.service.ts` | EAN matching engine |
| `server/src/modules/ean-lists/processors/ean-import.processor.ts` | Bull queue processor |
| `server/src/modules/ean-lists/repositories/ean-lists.repository.ts` | Lists data |
| `server/src/modules/ean-lists/repositories/ean-list-items.repository.ts` | Items data |
| `server/src/modules/ean-lists/repositories/import-errors.repository.ts` | Errors data |
| `server/src/modules/ean-lists/repositories/import-batches.repository.ts` | Batches data |
| `server/src/modules/ean-lists/dto/import-list.dto.ts` | DTOs |
| `server/src/modules/ean-lists/dto/validate-ean.dto.ts` | DTOs |
| `server/src/modules/ean-lists/utils/file-detector.utils.ts` | File type detection |
| `server/src/modules/ean-lists/types/import.types.ts` | Types |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/ean-lists/ean-lists.service.ts

export interface IEanListsService {
  // List management
  create(dto: CreateEanListDto, userId: string): Promise<EanList>;
  findById(id: string): Promise<EanListWithStats>;
  list(filters: ListEanListsFilter): Promise<PaginatedResult<EanList>>;
  update(id: string, dto: UpdateEanListDto, userId: string): Promise<EanList>;
  delete(id: string, userId: string): Promise<void>;
  
  // Activation
  activate(id: string, userId: string): Promise<EanList>;
  deactivate(id: string, userId: string): Promise<EanList>;
  
  // Import flow
  initiateImport(file: UploadedFile, dto: InitiateImportDto, userId: string): Promise<ImportInitResult>;
  getImportStatus(batchId: string): Promise<ImportStatus>;
  cancelImport(batchId: string, userId: string): Promise<void>;
  
  // Errors
  getImportErrors(batchId: string, pagination: PaginationParams): Promise<PaginatedResult<ImportError>>;
  downloadErrorsCSV(batchId: string): Promise<Buffer>;
  
  // Items query
  searchItems(listId: string, query: SearchItemsDto): Promise<PaginatedResult<EanListItem>>;
}

export interface IEanMatcherService {
  // Validate single EAN against active list
  validate(ean: string, storeId: string): Promise<EanValidationResult>;
  
  // Bulk validate
  validateBatch(eans: string[], storeId: string): Promise<Map<string, EanValidationResult>>;
  
  // Get active list for store
  getActiveListForStore(storeId: string): Promise<EanList | null>;
}

export interface IImportProcessorService {
  // Process uploaded file (called by queue)
  processImport(batchId: string): Promise<void>;
  
  // Parse and validate
  parseFile(buffer: Buffer, fileType: 'xlsx' | 'csv'): Promise<ParsedRow[]>;
  
  // Validate rows
  validateRows(rows: ParsedRow[]): { valid: ValidatedRow[]; invalid: InvalidRow[] };
  
  // Insert valid items
  insertItems(listId: string, rows: ValidatedRow[]): Promise<number>;
  
  // Record errors
  recordErrors(batchId: string, errors: InvalidRow[]): Promise<void>;
}

export interface ParsedRow {
  rowNumber: number;
  ean: string;
  productName?: string;
  brand?: string;
  notes?: string;
  rawData: Record<string, string>;
}

export interface ValidatedRow {
  ean: string;
  productName?: string;
  brand?: string;
  notes?: string;
  productId?: string; // matched in catalog
  rowNumber: number;
}

export interface InvalidRow {
  rowNumber: number;
  rawData: Record<string, string>;
  errors: string[];
}

export interface EanValidationResult {
  valid: boolean;
  ean: string;
  matched: boolean;
  listItem?: EanListItem;
  product?: Product;
  reason?: 'not_in_list' | 'list_inactive' | 'no_active_list' | 'invalid_format';
  validatedAt: Date;
}

export interface ImportInitResult {
  batchId: string;
  status: 'queued';
  estimatedRows: number;
  estimatedDurationSeconds: number;
}

export interface ImportStatus {
  batchId: string;
  status: 'queued' | 'processing' | 'completed' | 'failed' | 'cancelled';
  progress: {
    totalRows: number;
    processedRows: number;
    validRows: number;
    invalidRows: number;
    percentage: number;
  };
  startedAt?: Date;
  completedAt?: Date;
  errorMessage?: string;
}
```

## Implementation Code

### 1. EAN Lists Schema

```typescript
// server/src/db/schema/ean_lists.ts
import { pgTable, varchar, uuid, integer, boolean, timestamp, jsonb, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns, softDeleteColumn, auditColumns } from './_base';

export const eanListStatusEnum = pgEnum('ean_list_status', [
  'draft',
  'active',
  'archived',
]);

export const eanLists = pgTable(
  'ean_lists',
  {
    ...baseColumns,
    ...softDeleteColumn,
    ...auditColumns,
    tenantId: uuid('tenant_id').notNull(),
    storeId: uuid('store_id'), // Optional: store-specific list
    
    name: varchar('name', { length: 200 }).notNull(),
    description: varchar('description', { length: 500 }),
    version: integer('version').notNull().default(1),
    
    status: eanListStatusEnum('status').notNull().default('draft'),
    
    // Source
    sourceFileKey: varchar('source_file_key', { length: 500 }),
    sourceFileType: varchar('source_file_type', { length: 10 }),
    
    // Stats
    totalItems: integer('total_items').notNull().default(0),
    validatedItems: integer('validated_items').notNull().default(0),
    
    // Activation
    activatedAt: timestamp('activated_at', { withTimezone: true }),
    deactivatedAt: timestamp('deactivated_at', { withTimezone: true }),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    tenantIdx: index('idx_ean_lists_tenant').on(table.tenantId),
    storeActiveIdx: index('idx_ean_lists_store_active').on(table.storeId, table.status),
    statusIdx: index('idx_ean_lists_status').on(table.status),
  }),
);

export type EanList = typeof eanLists.$inferSelect;
export type NewEanList = typeof eanLists.$inferInsert;
```

### 2. EAN List Items Schema

```typescript
// server/src/db/schema/ean_list_items.ts
import { pgTable, varchar, uuid, jsonb, timestamp, index, unique } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';
import { eanLists } from './ean_lists';
import { products } from './products';

export const eanListItems = pgTable(
  'ean_list_items',
  {
    ...baseColumns,
    listId: uuid('list_id').notNull().references(() => eanLists.id, { onDelete: 'cascade' }),
    ean: varchar('ean', { length: 13 }).notNull(),
    productId: uuid('product_id').references(() => products.id),
    
    // Original data from import
    productName: varchar('product_name', { length: 200 }),
    brand: varchar('brand', { length: 100 }),
    notes: varchar('notes', { length: 500 }),
    
    rowNumber: integer('row_number'),
    rawData: jsonb('raw_data'),
  },
  (table) => ({
    listEanIdx: unique('uniq_ean_items_list_ean').on(table.listId, table.ean),
    eanIdx: index('idx_ean_items_ean').on(table.ean),
  }),
);

export type EanListItem = typeof eanListItems.$inferSelect;
```

### 3. Import Batches Schema

```typescript
// server/src/db/schema/import_batches.ts
import { pgTable, varchar, uuid, integer, jsonb, timestamp, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const importBatchStatusEnum = pgEnum('import_batch_status', [
  'queued',
  'processing',
  'completed',
  'failed',
  'cancelled',
]);

export const importBatches = pgTable(
  'import_batches',
  {
    ...baseColumns,
    tenantId: uuid('tenant_id').notNull(),
    listId: uuid('list_id'),
    
    importedBy: uuid('imported_by').notNull(),
    
    fileKey: varchar('file_key', { length: 500 }),
    fileName: varchar('file_name', { length: 255 }),
    fileType: varchar('file_type', { length: 10 }),
    fileSize: integer('file_size'),
    
    status: importBatchStatusEnum('status').notNull().default('queued'),
    
    // Progress
    totalRows: integer('total_rows').notNull().default(0),
    processedRows: integer('processed_rows').notNull().default(0),
    validRows: integer('valid_rows').notNull().default(0),
    invalidRows: integer('invalid_rows').notNull().default(0),
    
    // Timing
    queuedAt: timestamp('queued_at', { withTimezone: true }).defaultNow(),
    startedAt: timestamp('started_at', { withTimezone: true }),
    completedAt: timestamp('completed_at', { withTimezone: true }),
    
    errorMessage: varchar('error_message', { length: 1000 }),
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    tenantIdx: index('idx_import_batches_tenant').on(table.tenantId),
    statusIdx: index('idx_import_batches_status').on(table.status),
  }),
);

export type ImportBatch = typeof importBatches.$inferSelect;
```

### 4. Excel Parser Service

```typescript
// server/src/modules/ean-lists/services/excel-parser.service.ts
import { Injectable } from '@nestjs/common';
import * as XLSX from 'xlsx';
import { ParsedRow } from '../types/import.types';
import { ValidationException } from '../../../common/errors/business.exception';

@Injectable()
export class ExcelParserService {
  parseBuffer(buffer: Buffer): ParsedRow[] {
    let workbook: XLSX.WorkBook;
    
    try {
      workbook = XLSX.read(buffer, { type: 'buffer', cellDates: true });
    } catch (error) {
      throw new ValidationException('Invalid Excel file');
    }
    
    if (!workbook.SheetNames.length) {
      throw new ValidationException('Excel file has no sheets');
    }
    
    // Use first sheet
    const sheetName = workbook.SheetNames[0];
    const sheet = workbook.Sheets[sheetName];
    
    // Convert to JSON with headers
    const rows = XLSX.utils.sheet_to_json<Record<string, unknown>>(sheet, {
      raw: false,
      defval: '',
    });
    
    if (rows.length === 0) {
      throw new ValidationException('Excel file is empty');
    }
    
    if (rows.length > 50000) {
      throw new ValidationException('Excel file too large (max 50,000 rows)');
    }
    
    // Map to ParsedRow
    return rows.map((row, index) => {
      const normalized = this.normalizeRow(row);
      return {
        rowNumber: index + 2, // +2 because Excel is 1-indexed and header is row 1
        ean: normalized.ean,
        productName: normalized.productName,
        brand: normalized.brand,
        notes: normalized.notes,
        rawData: row as Record<string, string>,
      };
    });
  }
  
  private normalizeRow(row: Record<string, unknown>): {
    ean: string;
    productName?: string;
    brand?: string;
    notes?: string;
  } {
    // Try multiple column name variants
    const eanKeys = ['ean', 'EAN', 'Ean', 'barcode', 'Barcode', 'BARCODE', 'code', 'Code'];
    const nameKeys = ['name', 'Name', 'product_name', 'Product Name', 'productName', 'item', 'Item'];
    const brandKeys = ['brand', 'Brand', 'BRAND', 'manufacturer', 'Manufacturer'];
    const notesKeys = ['notes', 'Notes', 'remarks', 'Remarks', 'comments', 'Comments'];
    
    const findValue = (keys: string[]): string | undefined => {
      for (const key of keys) {
        if (row[key] !== undefined && row[key] !== null && String(row[key]).trim() !== '') {
          return String(row[key]).trim();
        }
      }
      return undefined;
    };
    
    return {
      ean: findValue(eanKeys) || '',
      productName: findValue(nameKeys),
      brand: findValue(brandKeys),
      notes: findValue(notesKeys),
    };
  }
}
```

### 5. CSV Parser Service

```typescript
// server/src/modules/ean-lists/services/csv-parser.service.ts
import { Injectable } from '@nestjs/common';
import { parse } from 'csv-parse/sync';
import { ParsedRow } from '../types/import.types';
import { ValidationException } from '../../../common/errors/business.exception';

@Injectable()
export class CsvParserService {
  parseBuffer(buffer: Buffer): ParsedRow[] {
    let records: Record<string, string>[];
    
    try {
      records = parse(buffer, {
        columns: true,
        skip_empty_lines: true,
        trim: true,
        relax_column_count: true,
      });
    } catch (error) {
      throw new ValidationException(
        `Invalid CSV file: ${error instanceof Error ? error.message : 'Unknown'}`,
      );
    }
    
    if (records.length === 0) {
      throw new ValidationException('CSV file is empty');
    }
    
    if (records.length > 50000) {
      throw new ValidationException('CSV file too large (max 50,000 rows)');
    }
    
    return records.map((row, index) => ({
      rowNumber: index + 2,
      ean: this.findValue(row, ['ean', 'EAN', 'barcode', 'Barcode', 'code']) || '',
      productName: this.findValue(row, ['name', 'product_name', 'Product Name']),
      brand: this.findValue(row, ['brand', 'Brand']),
      notes: this.findValue(row, ['notes', 'Notes']),
      rawData: row,
    }));
  }
  
  private findValue(row: Record<string, string>, keys: string[]): string | undefined {
    for (const key of keys) {
      if (row[key]?.trim()) return row[key].trim();
    }
    return undefined;
  }
}
```

### 6. Import Processor (Bull Queue)

```typescript
// server/src/modules/ean-lists/processors/ean-import.processor.ts
import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';
import { Logger } from '@nestjs/common';
import { ImportProcessorService } from '../services/import-processor.service';

@Processor('ean-import')
export class EanImportProcessor {
  private readonly logger = new Logger(EanImportProcessor.name);

  constructor(private readonly importProcessor: ImportProcessorService) {}

  @Process('process-import')
  async handleImport(job: Job<{ batchId: string }>): Promise<void> {
    this.logger.log(`Processing import batch: ${job.data.batchId}`);
    
    try {
      await this.importProcessor.processImport(job.data.batchId);
      this.logger.log(`Import completed: ${job.data.batchId}`);
    } catch (error) {
      this.logger.error(`Import failed: ${job.data.batchId}`, error);
      throw error; // Bull will retry based on config
    }
  }
}
```

### 7. Import Processor Service

```typescript
// server/src/modules/ean-lists/services/import-processor.service.ts
import { Injectable } from '@nestjs/common';
import { DbService } from '../../../db/db.service';
import { S3Service } from '../../../integrations/aws/s3/s3.service';
import { ExcelParserService } from './excel-parser.service';
import { CsvParserService } from './csv-parser.service';
import { EanValidatorService } from './ean-validator.service';
import { EanListItemsRepository } from '../repositories/ean-list-items.repository';
import { ImportBatchesRepository } from '../repositories/import-batches.repository';
import { ImportErrorsRepository } from '../repositories/import-errors.repository';
import { ProductsRepository } from '../../products/products.repository';
import { LoggerService } from '../../../logging/logger.service';
import {
  IImportProcessorService,
  ParsedRow,
  ValidatedRow,
  InvalidRow,
} from '../types/import.types';
import { normalizeEan } from '../../products/utils/ean.utils';

@Injectable()
export class ImportProcessorService implements IImportProcessorService {
  constructor(
    private readonly db: DbService,
    private readonly s3: S3Service,
    private readonly excelParser: ExcelParserService,
    private readonly csvParser: CsvParserService,
    private readonly validator: EanValidatorService,
    private readonly itemsRepo: EanListItemsRepository,
    private readonly batchesRepo: ImportBatchesRepository,
    private readonly errorsRepo: ImportErrorsRepository,
    private readonly productsRepo: ProductsRepository,
    private readonly logger: LoggerService,
  ) {}

  async processImport(batchId: string): Promise<void> {
    const batch = await this.batchesRepo.findById(batchId);
    if (!batch) throw new Error(`Batch not found: ${batchId}`);
    
    try {
      // Update status
      await this.batchesRepo.update(batchId, {
        status: 'processing',
        startedAt: new Date(),
      });
      
      // Download from S3
      const buffer = await this.s3.downloadObject(batch.fileKey!);
      
      // Parse based on file type
      const rows = await this.parseFile(buffer, batch.fileType as 'xlsx' | 'csv');
      
      await this.batchesRepo.update(batchId, {
        totalRows: rows.length,
      });
      
      // Validate rows
      const { valid, invalid } = this.validateRows(rows);
      
      // Process in chunks of 1000
      const chunkSize = 1000;
      let processed = 0;
      
      for (let i = 0; i < valid.length; i += chunkSize) {
        const chunk = valid.slice(i, i + chunkSize);
        await this.insertItems(batch.listId!, chunk);
        processed += chunk.length;
        
        // Update progress
        await this.batchesRepo.update(batchId, {
          processedRows: processed,
          validRows: processed,
        });
      }
      
      // Record errors
      if (invalid.length > 0) {
        await this.recordErrors(batchId, invalid);
        await this.batchesRepo.update(batchId, {
          invalidRows: invalid.length,
        });
      }
      
      // Mark complete
      await this.batchesRepo.update(batchId, {
        status: 'completed',
        completedAt: new Date(),
      });
      
      this.logger.info('Import completed', {
        batchId,
        total: rows.length,
        valid: valid.length,
        invalid: invalid.length,
      });
    } catch (error) {
      await this.batchesRepo.update(batchId, {
        status: 'failed',
        errorMessage: error instanceof Error ? error.message : 'Unknown error',
        completedAt: new Date(),
      });
      throw error;
    }
  }

  async parseFile(buffer: Buffer, fileType: 'xlsx' | 'csv'): Promise<ParsedRow[]> {
    if (fileType === 'xlsx') {
      return this.excelParser.parseBuffer(buffer);
    } else {
      return this.csvParser.parseBuffer(buffer);
    }
  }

  validateRows(rows: ParsedRow[]): {
    valid: ValidatedRow[];
    invalid: InvalidRow[];
  } {
    const valid: ValidatedRow[] = [];
    const invalid: InvalidRow[] = [];
    const seenEans = new Set<string>();
    
    for (const row of rows) {
      const errors: string[] = [];
      
      // Check EAN exists
      if (!row.ean) {
        errors.push('EAN is required');
      } else {
        // Validate format
        const validation = this.validator.validate(row.ean);
        if (!validation.valid) {
          errors.push(validation.error || 'Invalid EAN');
        } else {
          // Normalize
          const normalized = normalizeEan(row.ean);
          
          // Check duplicates within file
          if (seenEans.has(normalized)) {
            errors.push(`Duplicate EAN in file (also at row ${row.rowNumber})`);
          } else {
            seenEans.add(normalized);
            
            valid.push({
              ean: normalized,
              productName: row.productName,
              brand: row.brand,
              notes: row.notes,
              rowNumber: row.rowNumber,
            });
            continue;
          }
        }
      }
      
      invalid.push({
        rowNumber: row.rowNumber,
        rawData: row.rawData,
        errors,
      });
    }
    
    return { valid, invalid };
  }

  async insertItems(listId: string, rows: ValidatedRow[]): Promise<number> {
    return this.db.transaction(async (tx) => {
      // Try to match each EAN to existing product
      const eans = rows.map((r) => r.ean);
      const products = await this.productsRepo.findManyByEans(eans);
      const productMap = new Map(products.map((p) => [p.ean, p.id]));
      
      const items = rows.map((row) => ({
        listId,
        ean: row.ean,
        productId: productMap.get(row.ean),
        productName: row.productName,
        brand: row.brand,
        notes: row.notes,
        rowNumber: row.rowNumber,
      }));
      
      const created = await this.itemsRepo.bulkInsert(items, tx);
      return created.length;
    });
  }

  async recordErrors(batchId: string, errors: InvalidRow[]): Promise<void> {
    const errorRecords = errors.map((e) => ({
      batchId,
      rowNumber: e.rowNumber,
      rawData: e.rawData,
      errors: e.errors,
    }));
    
    // Insert in chunks of 500
    const chunkSize = 500;
    for (let i = 0; i < errorRecords.length; i += chunkSize) {
      const chunk = errorRecords.slice(i, i + chunkSize);
      await this.errorsRepo.bulkInsert(chunk);
    }
  }
}
```

### 8. EAN Matcher Service

```typescript
// server/src/modules/ean-lists/services/ean-matcher.service.ts
import { Injectable } from '@nestjs/common';
import { EanListsRepository } from '../repositories/ean-lists.repository';
import { EanListItemsRepository } from '../repositories/ean-list-items.repository';
import { ProductsRepository } from '../../products/products.repository';
import {
  IEanMatcherService,
  EanValidationResult,
} from '../types/import.types';
import { normalizeEan, validateEan } from '../../products/utils/ean.utils';

@Injectable()
export class EanMatcherService implements IEanMatcherService {
  constructor(
    private readonly listsRepo: EanListsRepository,
    private readonly itemsRepo: EanListItemsRepository,
    private readonly productsRepo: ProductsRepository,
  ) {}

  async validate(ean: string, storeId: string): Promise<EanValidationResult> {
    // Validate format
    const formatCheck = validateEan(ean);
    if (!formatCheck.valid) {
      return {
        valid: false,
        ean,
        matched: false,
        reason: 'invalid_format',
        validatedAt: new Date(),
      };
    }
    
    const normalizedEan = normalizeEan(ean);
    
    // Get active list for store
    const activeList = await this.getActiveListForStore(storeId);
    if (!activeList) {
      return {
        valid: false,
        ean: normalizedEan,
        matched: false,
        reason: 'no_active_list',
        validatedAt: new Date(),
      };
    }
    
    // Check if EAN in list
    const listItem = await this.itemsRepo.findByListAndEan(activeList.id, normalizedEan);
    
    if (!listItem) {
      return {
        valid: false,
        ean: normalizedEan,
        matched: false,
        reason: 'not_in_list',
        validatedAt: new Date(),
      };
    }
    
    // Get product if matched
    const product = listItem.productId
      ? await this.productsRepo.findById(listItem.productId)
      : undefined;
    
    return {
      valid: true,
      ean: normalizedEan,
      matched: true,
      listItem,
      product,
      validatedAt: new Date(),
    };
  }

  async validateBatch(eans: string[], storeId: string): Promise<Map<string, EanValidationResult>> {
    const results = new Map<string, EanValidationResult>();
    
    const activeList = await this.getActiveListForStore(storeId);
    if (!activeList) {
      for (const ean of eans) {
        results.set(ean, {
          valid: false,
          ean,
          matched: false,
          reason: 'no_active_list',
          validatedAt: new Date(),
        });
      }
      return results;
    }
    
    // Normalize all
    const normalized = eans.map((e) => ({ original: e, normalized: normalizeEan(e) }));
    
    // Bulk lookup
    const items = await this.itemsRepo.findManyByListAndEans(
      activeList.id,
      normalized.map((n) => n.normalized),
    );
    const itemMap = new Map(items.map((i) => [i.ean, i]));
    
    for (const { original, normalized: norm } of normalized) {
      const item = itemMap.get(norm);
      if (item) {
        results.set(original, {
          valid: true,
          ean: norm,
          matched: true,
          listItem: item,
          validatedAt: new Date(),
        });
      } else {
        results.set(original, {
          valid: false,
          ean: norm,
          matched: false,
          reason: 'not_in_list',
          validatedAt: new Date(),
        });
      }
    }
    
    return results;
  }

  async getActiveListForStore(storeId: string): Promise<EanList | null> {
    return this.listsRepo.findActiveForStore(storeId);
  }
}
```

## DTOs

```typescript
// server/src/modules/ean-lists/dto/import-list.dto.ts
import { z } from 'zod';

export const InitiateImportSchema = z.object({
  listName: z.string().min(1).max(200),
  description: z.string().max(500).optional(),
  storeId: z.string().uuid().optional(), // Store-specific list
  fileName: z.string().max(255),
  fileType: z.enum(['xlsx', 'csv']),
  fileSize: z.number().int().min(100).max(20 * 1024 * 1024), // 20MB max
});

export const ValidateEanSchema = z.object({
  ean: z.string().regex(/^\d{8,13}$/),
  storeId: z.string().uuid(),
});

export type InitiateImportDto = z.infer<typeof InitiateImportSchema>;
export type ValidateEanDto = z.infer<typeof ValidateEanSchema>;
```

## API Endpoints

| Method | Endpoint | Auth | Role | Purpose |
|---|---|---|---|---|
| POST | `/api/v1/ean-lists` | Bearer | Manager+ | Create list |
| GET | `/api/v1/ean-lists` | Bearer | Staff+ | List EAN lists |
| GET | `/api/v1/ean-lists/:id` | Bearer | Staff+ | Get list details |
| PATCH | `/api/v1/ean-lists/:id` | Bearer | Manager+ | Update list |
| POST | `/api/v1/ean-lists/:id/activate` | Bearer | Manager+ | Activate list |
| POST | `/api/v1/ean-lists/:id/deactivate` | Bearer | Manager+ | Deactivate |
| POST | `/api/v1/ean-lists/:id/import` | Bearer | Manager+ | Upload file |
| GET | `/api/v1/ean-lists/imports/:batchId` | Bearer | Manager+ | Import status |
| GET | `/api/v1/ean-lists/imports/:batchId/errors` | Bearer | Manager+ | Errors |
| GET | `/api/v1/ean-lists/imports/:batchId/errors/csv` | Bearer | Manager+ | Download errors |
| POST | `/api/v1/ean-lists/validate` | Bearer | Staff+ | Validate single EAN |
| POST | `/api/v1/ean-lists/validate/batch` | Bearer | Staff+ | Validate batch |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-16 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Create EAN List ✅

```bash
curl -X POST http://localhost:3000/api/v1/ean-lists \
  -H "Authorization: Bearer <manager-token>" \
  -d '{"name":"Q1 2024 Approved","description":"First quarter approved products"}'
```

**Pass Criteria**: ✅ List created with status=draft

---

### Test 2: Upload Excel File ✅

```bash
# Create test.xlsx with 10 EANs
curl -X POST http://localhost:3000/api/v1/ean-lists/<id>/import \
  -H "Authorization: Bearer <token>" \
  -F "file=@test.xlsx"
```

**Expected**: Returns batchId, status=queued
**Pass Criteria**: ✅ Upload accepted

---

### Test 3: Import Status ✅

```bash
curl http://localhost:3000/api/v1/ean-lists/imports/<batchId>
```

**Expected** (after a few seconds):
```json
{
  "batchId": "...",
  "status": "completed",
  "progress": {
    "totalRows": 10,
    "validRows": 9,
    "invalidRows": 1,
    "percentage": 100
  }
}
```

**Pass Criteria**: ✅ Status tracking works

---

### Test 4: Excel with Invalid EAN ✅

Upload file with bad EAN in row 5:
**Expected**: Row 5 in errors with specific message
**Pass Criteria**: ✅ Per-row error reporting

---

### Test 5: Download Errors CSV ✅

```bash
curl http://localhost:3000/api/v1/ean-lists/imports/<batchId>/errors/csv > errors.csv
```

**Expected**: CSV with rowNumber, rawData, errors
**Pass Criteria**: ✅ Errors exportable

---

### Test 6: Large File (10K rows) ✅

Upload 10,000 row Excel:
**Expected**: 
- Upload returns immediately (queued)
- Processing happens in background
- Eventually completes (~30-60 seconds)

**Pass Criteria**: ✅ Async processing works

---

### Test 7: Activate List ✅

```bash
curl -X POST http://localhost:3000/api/v1/ean-lists/<id>/activate \
  -H "Authorization: Bearer <token>"
```

**Expected**:
- Status → active
- Other lists for same store deactivated
- activatedAt timestamp set

**Pass Criteria**: ✅ Only one active per store

---

### Test 8: Validate EAN Against Active List ✅

```bash
curl -X POST http://localhost:3000/api/v1/ean-lists/validate \
  -H "Authorization: Bearer <token>" \
  -d '{"ean":"8901234567890","storeId":"<id>"}'
```

**Expected**:
```json
{
  "valid": true,
  "matched": true,
  "listItem": {...}
}
```

**Pass Criteria**: ✅ Validation works

---

### Test 9: Validate EAN Not in List ✅

EAN not in active list:
**Expected**:
```json
{
  "valid": false,
  "matched": false,
  "reason": "not_in_list"
}
```

**Pass Criteria**: ✅ Negative validation correct

---

### Test 10: Batch Validation ✅

```bash
curl -X POST http://localhost:3000/api/v1/ean-lists/validate/batch \
  -d '{"eans":["8901234567890","9999999999999"],"storeId":"<id>"}'
```

**Expected**: Map of results, single DB query
**Pass Criteria**: ✅ Bulk validation efficient

---

### Test 11: Duplicate EAN Detection ✅

Upload file with same EAN twice:
**Expected**: Second occurrence flagged as duplicate
**Pass Criteria**: ✅ Within-file dedup

---

### Test 12: Cross-File Duplicate ✅

Same EAN in active list, then re-imported:
**Expected**: Updates existing record (or rejects, based on policy)
**Pass Criteria**: ✅ Policy enforced

---

### Test 13: Import Cancellation ✅

Cancel a queued import:
**Expected**: Status=cancelled, no items inserted
**Pass Criteria**: ✅ Cancellation works

---

### Test 14: Performance ✅

10K row import:
- Parsing: < 5 seconds
- Validation: < 5 seconds  
- DB insertion: < 30 seconds
- Total: < 1 minute

**Pass Criteria**: ✅ Performance acceptable

---

### Test 15: Tenant Isolation ✅

Tenant A creates list, Tenant B tries to access:
**Expected**: 404
**Pass Criteria**: ✅ Cross-tenant blocked

---

## 🎯 Q&A Session

### Q1: Why async processing for imports?

**Expected Answer**:
- 10K rows takes 30-60 seconds
- HTTP requests timeout at 30s
- Better UX: User sees status, can leave page
- Server handles other requests
- Failures don't lose work
- Can retry on failure

---

### Q2: Why Bull queue?

**Expected Answer**:
- Battle-tested in Node.js
- Redis-backed (already in stack)
- Retries with backoff
- Job priorities
- Monitoring UI (Bull Board)
- Concurrency control

---

### Q3: Why parse Excel and CSV separately?

**Expected Answer**:
- Different libraries handle each best
- xlsx library for Excel formats
- csv-parse for CSV
- Different edge cases
- Better error messages per format

---

### Q4: Why chunked insertion (1000 at a time)?

**Expected Answer**:
- Memory: Don't hold 50K rows in memory
- Connection: Don't lock DB for too long
- Progress: Update progress between chunks
- Recovery: Failure mid-import preserves chunks
- DB params: PostgreSQL limit of 65k params

---

### Q5: How are lists versioned?

**Expected Answer**:
- Each upload creates new list (version increment)
- Old list deactivated when new activated
- Historical scans validate against list at scan time
- Audit trail preserved
- Easy rollback (reactivate old version)

---

### Q6: Why match imported items to product catalog?

**Expected Answer**:
- Pre-resolves at import time (faster scans later)
- Validates EAN actually exists
- Links to product details (name, image)
- Mobile shows full info on validation
- If product not in catalog: Trigger OFF lookup later

---

### Q7: What if same EAN imports differently?

**Expected Answer**:
- Within file: Reject second occurrence
- Across files: Latest active list wins
- Conflict policy configurable per tenant
- Audit log shows all imports
- Owners can choose which list active

---

### Q8: How would you handle 1M row imports?

**Expected Answer**:
- Stream parsing (don't load all in memory)
- Multiple workers for parallel processing
- Larger DB connection pool
- Progress reporting per 10k rows
- Database COPY command instead of INSERT
- Estimated time: 15-30 minutes

---

## 📝 Sign-Off Checklist

### Functional
- [ ] Excel upload works
- [ ] CSV upload works
- [ ] Async processing via Bull queue
- [ ] Per-row error reporting
- [ ] Errors downloadable as CSV
- [ ] Validation API works (single + batch)
- [ ] List activation enforces uniqueness

### Code Quality
- [ ] Both parsers tested with edge cases
- [ ] Chunked inserts for performance
- [ ] Transaction safety
- [ ] Error messages user-friendly

### Performance
- [ ] 10K rows < 1 minute
- [ ] Validation < 200ms (single)
- [ ] Batch validation efficient

### Tests
- [ ] All 15 tests pass
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-16**
**☐ CHANGES REQUESTED**

---

**END OF BE-15 — DO NOT PROCEED WITHOUT APPROVAL**
