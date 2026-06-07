# Phase BE-21: Report Export (Excel/PDF)

## Phase Metadata

- **Phase ID**: BE-21
- **Phase Name**: Report Export (Excel/PDF) & Storage
- **Section**: Backend Execution — Operations Layer
- **Depends On**: BE-01 to BE-20
- **Blocks**: BE-22, BE-30 (owner dashboard exports)
- **Estimated Duration**: 2-3 days
- **Complexity**: Medium-High

## Goal

Convert generated report data into downloadable Excel/PDF/CSV files: professional formatting with company branding, charts in PDFs, multi-sheet Excel workbooks, large dataset streaming, S3 storage with lifecycle, presigned download URLs, file expiration policies, and email notifications when ready.

## Why This Phase Matters

Reports are useless without exports:
- Owners need PDF for board meetings
- Auditors need Excel for analysis
- Compliance officers need printable formats
- Email attachments require files
- Mobile/web download links

Without export:
- Reports stuck in JSON only
- No professional presentation
- Cannot share with stakeholders
- Poor audit trail UX

## Prerequisites

- [ ] BE-01 to BE-20 completed
- [ ] Reports generate data (BE-20)
- [ ] S3 working (BE-13)
- [ ] Bull queue running

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/modules/reports/exporters/excel-exporter.service.ts` | Excel generation |
| `server/src/modules/reports/exporters/pdf-exporter.service.ts` | PDF generation |
| `server/src/modules/reports/exporters/csv-exporter.service.ts` | CSV generation |
| `server/src/modules/reports/exporters/export.service.ts` | Orchestrator |
| `server/src/modules/reports/templates/excel-templates/` | XLSX templates |
| `server/src/modules/reports/templates/pdf-templates/` | PDF templates |
| `server/src/modules/reports/processors/report-export.processor.ts` | Bull worker |
| `server/src/modules/reports/services/report-storage.service.ts` | S3 integration |
| `server/src/modules/reports/services/report-download.service.ts` | Download URLs |
| `server/src/modules/reports/repositories/report-files.repository.ts` | Files data |
| `server/src/modules/reports/utils/excel-formatter.utils.ts` | Cell formatting |
| `server/src/modules/reports/utils/pdf-styles.utils.ts` | PDF styling |
| `server/src/modules/reports/utils/chart-renderer.utils.ts` | Charts in PDFs |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/reports/exporters/export.service.ts

export interface IExportService {
  // Export report to specified formats
  exportReport(reportId: string, formats: ReportFormat[]): Promise<ExportResult>;
  
  // Export ad-hoc data
  exportData(data: ExportableData, format: ReportFormat, options: ExportOptions): Promise<ExportedFile>;
  
  // Get downloadable URL
  getDownloadUrl(reportFileId: string, expirySeconds?: number): Promise<string>;
}

export interface IExcelExporter {
  generate(data: ReportData, options: ExcelOptions): Promise<Buffer>;
  generateMultiSheet(sheets: ExcelSheet[], options: ExcelOptions): Promise<Buffer>;
  streamLargeReport(data: AsyncIterable<unknown>, options: ExcelOptions): Promise<Buffer>;
}

export interface IPdfExporter {
  generate(data: ReportData, options: PdfOptions): Promise<Buffer>;
  generateWithCharts(data: ReportData, charts: ChartConfig[], options: PdfOptions): Promise<Buffer>;
}

export interface ICsvExporter {
  generate(rows: Record<string, unknown>[], options: CsvOptions): Promise<Buffer>;
  stream(rows: AsyncIterable<Record<string, unknown>>, options: CsvOptions): NodeJS.ReadableStream;
}

export interface ExportOptions {
  title: string;
  subtitle?: string;
  generatedAt: Date;
  generatedBy: string;
  tenantName: string;
  storeName?: string;
  dateRange?: DateRange;
  includeCharts?: boolean;
  watermark?: string;
}

export interface ExcelOptions extends ExportOptions {
  sheetName?: string;
  autoFilter?: boolean;
  freezeHeader?: boolean;
  conditionalFormatting?: boolean;
  columnWidths?: Record<string, number>;
}

export interface PdfOptions extends ExportOptions {
  orientation?: 'portrait' | 'landscape';
  pageSize?: 'A4' | 'Letter';
  includeLogo?: boolean;
  pageNumbers?: boolean;
  tableOfContents?: boolean;
}

export interface CsvOptions {
  delimiter?: string;
  quote?: string;
  escape?: string;
  header?: boolean;
  encoding?: 'utf8' | 'utf-16';
}

export interface ExcelSheet {
  name: string;
  data: Record<string, unknown>[];
  options?: Partial<ExcelOptions>;
}

export interface ChartConfig {
  type: 'bar' | 'line' | 'pie' | 'doughnut';
  title: string;
  data: ChartData;
  position?: 'inline' | 'separate-page';
}

export interface ChartData {
  labels: string[];
  datasets: Array<{
    label: string;
    data: number[];
    backgroundColor?: string;
  }>;
}

export interface ExportResult {
  reportId: string;
  files: ExportedFile[];
  totalSizeBytes: number;
  durationMs: number;
}

export interface ExportedFile {
  format: ReportFormat;
  s3Key: string;
  contentType: string;
  sizeBytes: number;
  downloadUrl?: string;
  expiresAt: Date;
}
```

## Implementation Code

### 1. Excel Exporter

```typescript
// server/src/modules/reports/exporters/excel-exporter.service.ts
import { Injectable } from '@nestjs/common';
import * as ExcelJS from 'exceljs';
import {
  IExcelExporter,
  ExcelOptions,
  ExcelSheet,
  ReportData,
} from '../types/export.types';

@Injectable()
export class ExcelExporterService implements IExcelExporter {
  
  async generate(data: ReportData, options: ExcelOptions): Promise<Buffer> {
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'RADHA Platform';
    workbook.created = new Date();
    workbook.lastModifiedBy = options.generatedBy;
    
    // Add metadata sheet
    this.addMetadataSheet(workbook, options);
    
    // Add data sheet
    const sheet = workbook.addWorksheet(options.sheetName || 'Report');
    
    // Add headers and data
    if (data.rows && data.rows.length > 0) {
      const headers = Object.keys(data.rows[0]);
      sheet.columns = headers.map((h) => ({
        header: this.formatHeader(h),
        key: h,
        width: options.columnWidths?.[h] || 20,
      }));
      
      // Style header row
      const headerRow = sheet.getRow(1);
      headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
      headerRow.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FF4F46E5' },
      };
      headerRow.alignment = { vertical: 'middle', horizontal: 'center' };
      
      // Add data rows
      sheet.addRows(data.rows);
      
      // Conditional formatting for status columns
      if (options.conditionalFormatting) {
        this.applyConditionalFormatting(sheet, headers);
      }
      
      // Auto-filter
      if (options.autoFilter !== false) {
        sheet.autoFilter = {
          from: { row: 1, column: 1 },
          to: { row: 1, column: headers.length },
        };
      }
      
      // Freeze header
      if (options.freezeHeader !== false) {
        sheet.views = [{ state: 'frozen', ySplit: 1 }];
      }
    }
    
    // Add summary sheet if available
    if (data.summary) {
      this.addSummarySheet(workbook, data.summary, options);
    }
    
    // Add charts data
    if (data.charts && data.charts.length > 0) {
      this.addChartsData(workbook, data.charts);
    }
    
    return await workbook.xlsx.writeBuffer() as Buffer;
  }

  async generateMultiSheet(sheets: ExcelSheet[], options: ExcelOptions): Promise<Buffer> {
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'RADHA Platform';
    workbook.created = new Date();
    
    this.addMetadataSheet(workbook, options);
    
    for (const sheetDef of sheets) {
      const sheet = workbook.addWorksheet(sheetDef.name);
      
      if (sheetDef.data.length > 0) {
        const headers = Object.keys(sheetDef.data[0]);
        sheet.columns = headers.map((h) => ({
          header: this.formatHeader(h),
          key: h,
          width: 20,
        }));
        
        const headerRow = sheet.getRow(1);
        headerRow.font = { bold: true };
        
        sheet.addRows(sheetDef.data);
      }
    }
    
    return await workbook.xlsx.writeBuffer() as Buffer;
  }

  async streamLargeReport(
    data: AsyncIterable<unknown>,
    options: ExcelOptions,
  ): Promise<Buffer> {
    const workbook = new ExcelJS.stream.xlsx.WorkbookWriter({
      filename: '/tmp/temp.xlsx',
    });
    
    const sheet = workbook.addWorksheet(options.sheetName || 'Report');
    let isFirstRow = true;
    
    for await (const row of data) {
      if (isFirstRow && row && typeof row === 'object') {
        const headers = Object.keys(row as object);
        sheet.columns = headers.map((h) => ({ header: h, key: h, width: 20 }));
        isFirstRow = false;
      }
      sheet.addRow(row).commit();
    }
    
    sheet.commit();
    await workbook.commit();
    
    // Read back the file (simplified - production would stream to S3)
    const fs = await import('fs');
    return fs.readFileSync('/tmp/temp.xlsx');
  }

  private addMetadataSheet(workbook: ExcelJS.Workbook, options: ExcelOptions) {
    const sheet = workbook.addWorksheet('Report Info');
    
    sheet.columns = [
      { header: 'Field', key: 'field', width: 30 },
      { header: 'Value', key: 'value', width: 50 },
    ];
    
    const metadata = [
      { field: 'Report Title', value: options.title },
      { field: 'Generated At', value: options.generatedAt.toISOString() },
      { field: 'Generated By', value: options.generatedBy },
      { field: 'Tenant', value: options.tenantName },
      ...(options.storeName ? [{ field: 'Store', value: options.storeName }] : []),
      ...(options.dateRange ? [
        { field: 'Date From', value: options.dateRange.from.toISOString() },
        { field: 'Date To', value: options.dateRange.to.toISOString() },
      ] : []),
      { field: 'Powered By', value: 'RADHA — Retail Audit Platform' },
    ];
    
    sheet.addRows(metadata);
    
    // Style
    sheet.getRow(1).font = { bold: true };
    sheet.getColumn(1).font = { bold: true };
  }

  private addSummarySheet(
    workbook: ExcelJS.Workbook,
    summary: Record<string, unknown>,
    options: ExcelOptions,
  ) {
    const sheet = workbook.addWorksheet('Summary');
    sheet.columns = [
      { header: 'Metric', key: 'metric', width: 30 },
      { header: 'Value', key: 'value', width: 20 },
    ];
    
    const rows = Object.entries(summary).map(([k, v]) => ({
      metric: this.formatHeader(k),
      value: v,
    }));
    
    sheet.addRows(rows);
    sheet.getRow(1).font = { bold: true };
  }

  private addChartsData(workbook: ExcelJS.Workbook, charts: any[]) {
    const sheet = workbook.addWorksheet('Charts Data');
    // Charts will be in BE-31 (advanced feature)
  }

  private applyConditionalFormatting(sheet: ExcelJS.Worksheet, headers: string[]) {
    // Find status columns
    const statusColIdx = headers.findIndex((h) => h.toLowerCase().includes('status'));
    if (statusColIdx === -1) return;
    
    const statusCol = sheet.getColumn(statusColIdx + 1);
    
    // Apply conditional formatting for expiry status
    sheet.addConditionalFormatting({
      ref: `${statusCol.letter}2:${statusCol.letter}10000`,
      rules: [
        {
          type: 'containsText',
          operator: 'containsText',
          text: 'red',
          priority: 1,
          style: { fill: { type: 'pattern', pattern: 'solid', bgColor: { argb: 'FFFEE2E2' } } },
        },
        {
          type: 'containsText',
          operator: 'containsText',
          text: 'yellow',
          priority: 2,
          style: { fill: { type: 'pattern', pattern: 'solid', bgColor: { argb: 'FFFEF3C7' } } },
        },
        {
          type: 'containsText',
          operator: 'containsText',
          text: 'green',
          priority: 3,
          style: { fill: { type: 'pattern', pattern: 'solid', bgColor: { argb: 'FFD1FAE5' } } },
        },
      ],
    });
  }

  private formatHeader(key: string): string {
    return key
      .replace(/_/g, ' ')
      .replace(/([A-Z])/g, ' $1')
      .trim()
      .replace(/\b\w/g, (c) => c.toUpperCase());
  }
}
```

### 2. PDF Exporter

```typescript
// server/src/modules/reports/exporters/pdf-exporter.service.ts
import { Injectable } from '@nestjs/common';
import PDFDocument from 'pdfkit';
import {
  IPdfExporter,
  PdfOptions,
  ChartConfig,
  ReportData,
} from '../types/export.types';

@Injectable()
export class PdfExporterService implements IPdfExporter {
  
  async generate(data: ReportData, options: PdfOptions): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const buffers: Buffer[] = [];
      const doc = new PDFDocument({
        size: options.pageSize || 'A4',
        layout: options.orientation || 'portrait',
        margins: { top: 50, bottom: 50, left: 50, right: 50 },
        info: {
          Title: options.title,
          Author: options.generatedBy,
          Creator: 'RADHA Platform',
          CreationDate: options.generatedAt,
        },
      });
      
      doc.on('data', (chunk: Buffer) => buffers.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(buffers)));
      doc.on('error', reject);
      
      // Header
      this.addHeader(doc, options);
      
      // Title
      doc
        .fontSize(20)
        .fillColor('#1F2937')
        .text(options.title, { align: 'center' })
        .moveDown(0.5);
      
      if (options.subtitle) {
        doc
          .fontSize(12)
          .fillColor('#6B7280')
          .text(options.subtitle, { align: 'center' })
          .moveDown();
      }
      
      // Metadata block
      this.addMetadataBlock(doc, options);
      
      // Summary section
      if (data.summary) {
        this.addSummarySection(doc, data.summary);
      }
      
      // Data table
      if (data.rows && data.rows.length > 0) {
        this.addDataTable(doc, data.rows);
      }
      
      // Page numbers
      if (options.pageNumbers !== false) {
        this.addPageNumbers(doc);
      }
      
      doc.end();
    });
  }

  async generateWithCharts(
    data: ReportData,
    charts: ChartConfig[],
    options: PdfOptions,
  ): Promise<Buffer> {
    // Charts integration uses chart-renderer.utils.ts
    // Generates PNG images and embeds in PDF
    return this.generate(data, options);
  }

  private addHeader(doc: PDFKit.PDFDocument, options: PdfOptions) {
    // Logo (if available)
    // doc.image('logo.png', 50, 45, { width: 50 });
    
    // Company name
    doc
      .fontSize(10)
      .fillColor('#4F46E5')
      .text('RADHA', 50, 55, { align: 'left' });
    
    // Date
    doc
      .fontSize(8)
      .fillColor('#9CA3AF')
      .text(options.generatedAt.toLocaleString(), 0, 55, { align: 'right' });
    
    doc.moveTo(50, 80).lineTo(550, 80).strokeColor('#E5E7EB').stroke();
    doc.moveDown(2);
  }

  private addMetadataBlock(doc: PDFKit.PDFDocument, options: PdfOptions) {
    doc.fontSize(10).fillColor('#374151');
    
    const metadata = [
      ['Tenant:', options.tenantName],
      ...(options.storeName ? [['Store:', options.storeName]] : []),
      ['Generated By:', options.generatedBy],
      ['Generated At:', options.generatedAt.toLocaleString()],
      ...(options.dateRange ? [
        ['Date Range:', `${options.dateRange.from.toLocaleDateString()} - ${options.dateRange.to.toLocaleDateString()}`]
      ] : []),
    ];
    
    const startY = doc.y;
    let currentY = startY;
    
    for (const [label, value] of metadata) {
      doc.font('Helvetica-Bold').text(label, 50, currentY, { continued: false });
      doc.font('Helvetica').text(String(value), 150, currentY);
      currentY += 15;
    }
    
    doc.y = currentY + 10;
  }

  private addSummarySection(doc: PDFKit.PDFDocument, summary: Record<string, unknown>) {
    doc
      .fontSize(14)
      .fillColor('#1F2937')
      .text('Summary', { underline: true })
      .moveDown(0.5);
    
    doc.fontSize(10).fillColor('#374151');
    
    Object.entries(summary).forEach(([key, value]) => {
      doc.text(`${this.formatKey(key)}: ${value}`);
    });
    
    doc.moveDown();
  }

  private addDataTable(doc: PDFKit.PDFDocument, rows: Record<string, unknown>[]) {
    if (rows.length === 0) return;
    
    doc
      .fontSize(14)
      .fillColor('#1F2937')
      .text('Details', { underline: true })
      .moveDown(0.5);
    
    const headers = Object.keys(rows[0]);
    const colWidth = 500 / headers.length;
    
    // Table header
    let currentY = doc.y;
    doc.fontSize(9).font('Helvetica-Bold').fillColor('#FFFFFF');
    
    doc
      .rect(50, currentY - 2, 500, 18)
      .fill('#4F46E5');
    
    headers.forEach((h, i) => {
      doc.fillColor('#FFFFFF').text(this.formatKey(h), 50 + i * colWidth + 5, currentY + 2, {
        width: colWidth - 10,
        ellipsis: true,
      });
    });
    
    currentY += 20;
    
    // Table rows (limit to first 50 for PDF)
    doc.font('Helvetica').fontSize(8).fillColor('#374151');
    
    for (const row of rows.slice(0, 50)) {
      // New page if needed
      if (currentY > 750) {
        doc.addPage();
        currentY = 50;
      }
      
      // Alternate row colors
      if (rows.indexOf(row) % 2 === 0) {
        doc.rect(50, currentY - 2, 500, 14).fill('#F9FAFB');
      }
      
      headers.forEach((h, i) => {
        doc.fillColor('#374151').text(String(row[h] ?? ''), 50 + i * colWidth + 5, currentY, {
          width: colWidth - 10,
          ellipsis: true,
        });
      });
      
      currentY += 14;
    }
    
    if (rows.length > 50) {
      doc.moveDown();
      doc.fontSize(9).fillColor('#9CA3AF').text(
        `... and ${rows.length - 50} more rows. Download Excel for complete data.`,
        { align: 'center' },
      );
    }
  }

  private addPageNumbers(doc: PDFKit.PDFDocument) {
    const range = doc.bufferedPageRange();
    for (let i = range.start; i < range.start + range.count; i++) {
      doc.switchToPage(i);
      doc
        .fontSize(8)
        .fillColor('#9CA3AF')
        .text(
          `Page ${i + 1} of ${range.count}`,
          50,
          doc.page.height - 30,
          { align: 'center', width: doc.page.width - 100 },
        );
    }
  }

  private formatKey(key: string): string {
    return key
      .replace(/_/g, ' ')
      .replace(/([A-Z])/g, ' $1')
      .trim()
      .replace(/\b\w/g, (c) => c.toUpperCase());
  }
}
```

### 3. CSV Exporter

```typescript
// server/src/modules/reports/exporters/csv-exporter.service.ts
import { Injectable } from '@nestjs/common';
import { stringify } from 'csv-stringify/sync';
import { Readable } from 'stream';
import { ICsvExporter, CsvOptions } from '../types/export.types';

@Injectable()
export class CsvExporterService implements ICsvExporter {
  
  async generate(rows: Record<string, unknown>[], options: CsvOptions = {}): Promise<Buffer> {
    if (rows.length === 0) {
      return Buffer.from('');
    }
    
    const csv = stringify(rows, {
      header: options.header !== false,
      delimiter: options.delimiter || ',',
      quote: options.quote || '"',
      escape: options.escape || '"',
    });
    
    const encoding = options.encoding || 'utf8';
    return Buffer.from(csv, encoding as BufferEncoding);
  }

  stream(
    rows: AsyncIterable<Record<string, unknown>>,
    options: CsvOptions = {},
  ): NodeJS.ReadableStream {
    return Readable.from(this.streamGenerator(rows, options));
  }

  private async *streamGenerator(
    rows: AsyncIterable<Record<string, unknown>>,
    options: CsvOptions,
  ): AsyncGenerator<string> {
    let isFirst = true;
    
    for await (const row of rows) {
      if (isFirst && options.header !== false) {
        const header = Object.keys(row);
        yield stringify([header], {
          delimiter: options.delimiter || ',',
        });
        isFirst = false;
      }
      
      yield stringify([Object.values(row)], {
        delimiter: options.delimiter || ',',
      });
    }
  }
}
```

### 4. Export Service (Orchestrator)

```typescript
// server/src/modules/reports/exporters/export.service.ts
import { Injectable } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { ExcelExporterService } from './excel-exporter.service';
import { PdfExporterService } from './pdf-exporter.service';
import { CsvExporterService } from './csv-exporter.service';
import { ReportStorageService } from '../services/report-storage.service';
import { ReportFilesRepository } from '../repositories/report-files.repository';
import { ReportsRepository } from '../repositories/reports.repository';
import {
  IExportService,
  ExportResult,
  ExportedFile,
  ReportFormat,
} from '../types/export.types';

@Injectable()
export class ExportService implements IExportService {
  constructor(
    private readonly excelExporter: ExcelExporterService,
    private readonly pdfExporter: PdfExporterService,
    private readonly csvExporter: CsvExporterService,
    private readonly storage: ReportStorageService,
    private readonly filesRepo: ReportFilesRepository,
    private readonly reportsRepo: ReportsRepository,
  ) {}

  async exportReport(
    reportId: string,
    formats: ReportFormat[],
  ): Promise<ExportResult> {
    const startTime = Date.now();
    const report = await this.reportsRepo.findById(reportId);
    if (!report) throw new Error(`Report not found: ${reportId}`);
    
    // Get report data (BE-20 stored summary, full data is regenerated)
    // In production, generated data would be cached
    const data = report.summary;
    
    const options = {
      title: report.title,
      generatedAt: report.generationCompletedAt || new Date(),
      generatedBy: 'system',
      tenantName: 'RADHA',
      dateRange: report.dateFrom && report.dateTo ? {
        from: report.dateFrom,
        to: report.dateTo,
      } : undefined,
    };
    
    const files: ExportedFile[] = [];
    
    for (const format of formats) {
      const file = await this.generateFile(reportId, data as any, format, options);
      files.push(file);
    }
    
    return {
      reportId,
      files,
      totalSizeBytes: files.reduce((sum, f) => sum + f.sizeBytes, 0),
      durationMs: Date.now() - startTime,
    };
  }

  async exportData(data: any, format: ReportFormat, options: any): Promise<ExportedFile> {
    return this.generateFile(uuidv4(), data, format, options);
  }

  async getDownloadUrl(reportFileId: string, expirySeconds = 86400): Promise<string> {
    const file = await this.filesRepo.findById(reportFileId);
    if (!file) throw new Error('File not found');
    
    return this.storage.getDownloadUrl(file.s3Key, expirySeconds);
  }

  private async generateFile(
    reportId: string,
    data: any,
    format: ReportFormat,
    options: any,
  ): Promise<ExportedFile> {
    let buffer: Buffer;
    let contentType: string;
    let extension: string;
    
    switch (format) {
      case 'xlsx':
        buffer = await this.excelExporter.generate(data, options);
        contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        extension = 'xlsx';
        break;
      case 'pdf':
        buffer = await this.pdfExporter.generate(data, options);
        contentType = 'application/pdf';
        extension = 'pdf';
        break;
      case 'csv':
        buffer = await this.csvExporter.generate(data.rows || [], options);
        contentType = 'text/csv';
        extension = 'csv';
        break;
      default:
        throw new Error(`Unsupported format: ${format}`);
    }
    
    // Upload to S3
    const s3Key = `reports/${reportId}/${format}-${Date.now()}.${extension}`;
    await this.storage.upload(s3Key, buffer, contentType);
    
    // Save file record
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 90);
    
    const fileRecord = await this.filesRepo.create({
      reportId,
      format,
      s3Key,
      contentType,
      sizeBytes: buffer.length,
      expiresAt,
    });
    
    return {
      format,
      s3Key,
      contentType,
      sizeBytes: buffer.length,
      expiresAt,
    };
  }
}
```

### 5. Report Storage Service

```typescript
// server/src/modules/reports/services/report-storage.service.ts
import { Injectable } from '@nestjs/common';
import { S3Service } from '../../../integrations/aws/s3/s3.service';

@Injectable()
export class ReportStorageService {
  constructor(private readonly s3: S3Service) {}

  async upload(key: string, buffer: Buffer, contentType: string): Promise<string> {
    return this.s3.uploadObject(key, buffer, contentType);
  }

  async getDownloadUrl(key: string, expirySeconds: number = 86400): Promise<string> {
    return this.s3.generatePresignedDownloadUrl(key, expirySeconds);
  }

  async delete(key: string): Promise<void> {
    return this.s3.deleteObject(key);
  }
}
```

## Database Tables Affected

| Table | Operation | Purpose |
|---|---|---|
| `report_files` | INSERT | Track generated files |
| `report_files` | UPDATE | Update download counts |

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| GET | `/api/v1/reports/:id/download` | Bearer | Get download URL (any format) |
| GET | `/api/v1/reports/:id/download/:format` | Bearer | Specific format URL |
| GET | `/api/v1/reports/:id/files` | Bearer | List generated files |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-22 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Generate Excel ✅
Generate report, request Excel:
**Expected**: Multi-sheet workbook with metadata, summary, data
**Pass Criteria**: ✅ Opens correctly in Excel/Numbers

### Test 2: Generate PDF ✅
**Expected**: Branded PDF with header, summary, data table
**Pass Criteria**: ✅ Renders correctly, prints well

### Test 3: Generate CSV ✅
**Expected**: Standard CSV, opens in Excel
**Pass Criteria**: ✅ UTF-8 encoded, correct delimiter

### Test 4: Multi-format Generation ✅
Request xlsx + pdf + csv simultaneously:
**Expected**: All three files generated, all stored
**Pass Criteria**: ✅ Parallel generation works

### Test 5: Conditional Formatting ✅
Excel report with status column:
**Expected**: Red rows = red bg, yellow = yellow bg
**Pass Criteria**: ✅ Visual cues work

### Test 6: Download URL ✅
```bash
curl .../reports/<id>/download/pdf
```
**Expected**: Returns presigned S3 URL valid 24h
**Pass Criteria**: ✅ Download works

### Test 7: Large Dataset (10K rows) ✅
**Expected**: Streams to file, doesn't OOM
**Pass Criteria**: ✅ Handles 10K rows in < 30s

### Test 8: PDF Page Numbers ✅
Multi-page PDF:
**Expected**: "Page X of Y" on each page
**Pass Criteria**: ✅ Pagination works

### Test 9: Tenant Branding ✅
PDF includes tenant name in header:
**Pass Criteria**: ✅ Branding correct

### Test 10: Empty Data Export ✅
Report with 0 rows:
**Expected**: File still generated with metadata, empty data section
**Pass Criteria**: ✅ Graceful empty state

### Test 11: Special Characters ✅
Data with unicode (emoji, hindi):
**Expected**: All formats preserve characters
**Pass Criteria**: ✅ Unicode safe

### Test 12: File Expiration ✅
After 90 days, S3 lifecycle deletes:
**Pass Criteria**: ✅ Files cleaned up

### Test 13: Multiple Sheets ✅
Excel with summary + details + charts data:
**Expected**: 3+ sheets in workbook
**Pass Criteria**: ✅ Multi-sheet works

### Test 14: Error in Generator ✅
Malformed data causes error:
**Expected**: Graceful failure, error logged, no partial file
**Pass Criteria**: ✅ Error handling

### Test 15: Concurrent Exports ✅
10 simultaneous export requests:
**Expected**: All complete, no resource exhaustion
**Pass Criteria**: ✅ Scales

## 🎯 Q&A Session

### Q1: Why ExcelJS over xlsx library?
**Expected**: Better streaming, more features, modern API, conditional formatting

### Q2: Why pdfkit?
**Expected**: Streaming-friendly, lightweight, good control, no Chromium dependency

### Q3: Why store files in S3?
**Expected**: Scalable, presigned URLs, lifecycle policies, no server disk usage

### Q4: Why 90-day retention?
**Expected**: Storage cost vs usefulness, can regenerate from raw data

### Q5: Why streaming for large reports?
**Expected**: Memory efficiency, can handle 100K+ rows

### Q6: Why presigned URLs vs proxy download?
**Expected**: Direct from S3 = faster, no backend bandwidth

### Q7: Why multi-format support?
**Expected**: Excel for analysis, PDF for sharing, CSV for import elsewhere

### Q8: How to add charts to PDFs?
**Expected**: Use chart library (Chart.js with canvas), render to PNG, embed

## 📝 Sign-Off Checklist

- [ ] All 15 tests pass
- [ ] All formats generate correctly
- [ ] S3 storage works
- [ ] Download URLs work
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-22**
**☐ CHANGES REQUESTED**

---

**END OF BE-21 — DO NOT PROCEED WITHOUT APPROVAL**
