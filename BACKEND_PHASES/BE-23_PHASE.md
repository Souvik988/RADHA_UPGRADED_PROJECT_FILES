# Phase BE-23: Media Processing & CDN

## Phase Metadata

- **Phase ID**: BE-23
- **Phase Name**: Media Processing & CDN
- **Section**: Backend Execution — Advanced Features Layer
- **Depends On**: BE-01 to BE-22
- **Blocks**: BE-24 (notifications need images)
- **Estimated Duration**: 2 days
- **Complexity**: Medium

## Goal

Process media uploads asynchronously: generate image variants (thumbnail, medium, full), optimize file sizes, format conversion (WebP), CloudFront CDN cache invalidation, EXIF stripping (privacy), and lifecycle policies.

## Why This Phase Matters

Without proper image processing:
- Mobile apps download huge originals (slow, costly)
- No thumbnails = poor list performance
- EXIF data leaks GPS/device info
- CDN serves stale content after updates
- Storage costs balloon

## Prerequisites

- [ ] BE-13 (S3 + CloudFront)
- [ ] BE-22 (AI infrastructure)
- [ ] Bull queue running

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/modules/media/services/image-processor.service.ts` | Sharp-based processor |
| `server/src/modules/media/services/cdn-invalidator.service.ts` | CloudFront invalidation |
| `server/src/modules/media/services/exif-stripper.service.ts` | Privacy |
| `server/src/modules/media/processors/image-processing.processor.ts` | Bull worker |
| `server/src/modules/media/services/image-variants.service.ts` | Variant config |
| `server/src/integrations/aws/cloudfront/cloudfront-client.service.ts` | AWS SDK |
| `server/src/modules/media/utils/image-optimization.utils.ts` | Optimization helpers |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/media/services/image-processor.service.ts

export interface IImageProcessorService {
  processImage(mediaId: string): Promise<ProcessedImageResult>;
  generateVariants(buffer: Buffer): Promise<ImageVariants>;
  optimize(buffer: Buffer, options: OptimizeOptions): Promise<OptimizedImage>;
  stripExif(buffer: Buffer): Promise<Buffer>;
  convertFormat(buffer: Buffer, targetFormat: 'webp' | 'jpeg' | 'png'): Promise<Buffer>;
  getMetadata(buffer: Buffer): Promise<ImageMetadata>;
}

export interface ICdnInvalidatorService {
  invalidate(paths: string[]): Promise<InvalidationResult>;
  invalidateByMediaId(mediaId: string): Promise<InvalidationResult>;
  invalidateAll(): Promise<InvalidationResult>; // Use sparingly
}

export interface ProcessedImageResult {
  mediaId: string;
  variants: {
    thumbnail: VariantInfo;  // 150x150
    small: VariantInfo;       // 400x400
    medium: VariantInfo;      // 800x800
    large: VariantInfo;       // 1600x1600
    original: VariantInfo;
  };
  totalSizeBytes: number;
  optimizationRatio: number;
  durationMs: number;
}

export interface VariantInfo {
  s3Key: string;
  cdnUrl: string;
  width: number;
  height: number;
  sizeBytes: number;
  format: string;
}

export interface ImageVariants {
  thumbnail: Buffer;
  small: Buffer;
  medium: Buffer;
  large: Buffer;
}

export interface OptimizeOptions {
  quality?: number;     // 1-100
  format?: 'webp' | 'jpeg' | 'png';
  maxWidth?: number;
  maxHeight?: number;
  stripExif?: boolean;
  progressive?: boolean;
}

export interface OptimizedImage {
  buffer: Buffer;
  format: string;
  width: number;
  height: number;
  sizeBytes: number;
}

export interface ImageMetadata {
  width: number;
  height: number;
  format: string;
  sizeBytes: number;
  hasExif: boolean;
  exifGps?: { lat: number; lng: number };
  channels: number;
  density?: number;
}

export interface InvalidationResult {
  invalidationId: string;
  paths: string[];
  status: 'in-progress' | 'completed';
}
```

## Implementation Code

### 1. Image Processor Service

```typescript
// server/src/modules/media/services/image-processor.service.ts
import { Injectable, Logger } from '@nestjs/common';
import sharp from 'sharp';
import { S3Service } from '../../../integrations/aws/s3/s3.service';
import { MediaRepository } from '../media.repository';
import {
  IImageProcessorService,
  ProcessedImageResult,
  ImageVariants,
  OptimizeOptions,
  OptimizedImage,
  ImageMetadata,
  VariantInfo,
} from '../types/media.types';
import { CloudFrontService } from '../../../integrations/aws/cloudfront/cloudfront.service';

@Injectable()
export class ImageProcessorService implements IImageProcessorService {
  private readonly logger = new Logger(ImageProcessorService.name);
  
  // Variant configurations
  private readonly VARIANTS = {
    thumbnail: { width: 150, height: 150, quality: 80 },
    small:     { width: 400, height: 400, quality: 80 },
    medium:    { width: 800, height: 800, quality: 85 },
    large:     { width: 1600, height: 1600, quality: 90 },
  };

  constructor(
    private readonly s3: S3Service,
    private readonly cdn: CloudFrontService,
    private readonly mediaRepo: MediaRepository,
  ) {}

  async processImage(mediaId: string): Promise<ProcessedImageResult> {
    const startTime = Date.now();
    
    const media = await this.mediaRepo.findById(mediaId);
    if (!media) throw new Error(`Media not found: ${mediaId}`);
    
    // Update status
    await this.mediaRepo.update(mediaId, { status: 'processing' });
    
    try {
      // Download original
      const original = await this.s3.downloadObject(media.s3Key);
      
      // Get metadata
      const metadata = await this.getMetadata(original);
      
      // Strip EXIF (privacy + size)
      const stripped = await this.stripExif(original);
      
      // Generate variants
      const variants = await this.generateVariants(stripped);
      
      // Upload variants to S3
      const variantInfos: Record<string, VariantInfo> = {};
      let totalSize = 0;
      
      for (const [name, buffer] of Object.entries(variants)) {
        const variantKey = this.buildVariantKey(media.s3Key, name);
        await this.s3.uploadObject(variantKey, buffer, 'image/webp');
        
        const variantMeta = await sharp(buffer).metadata();
        variantInfos[name] = {
          s3Key: variantKey,
          cdnUrl: this.cdn.getCdnUrl(variantKey),
          width: variantMeta.width || 0,
          height: variantMeta.height || 0,
          sizeBytes: buffer.length,
          format: 'webp',
        };
        totalSize += buffer.length;
      }
      
      // Original info
      variantInfos.original = {
        s3Key: media.s3Key,
        cdnUrl: this.cdn.getCdnUrl(media.s3Key),
        width: metadata.width,
        height: metadata.height,
        sizeBytes: media.contentLength,
        format: metadata.format,
      };
      
      // Update media record with variants
      await this.mediaRepo.update(mediaId, {
        status: 'ready',
        width: metadata.width,
        height: metadata.height,
        variants: variantInfos as any,
        processedAt: new Date(),
      });
      
      const optimizationRatio = media.contentLength > 0
        ? totalSize / media.contentLength
        : 1;
      
      return {
        mediaId,
        variants: variantInfos as any,
        totalSizeBytes: totalSize + media.contentLength,
        optimizationRatio,
        durationMs: Date.now() - startTime,
      };
    } catch (error) {
      await this.mediaRepo.update(mediaId, { status: 'failed' });
      throw error;
    }
  }

  async generateVariants(buffer: Buffer): Promise<ImageVariants> {
    const variants: any = {};
    
    for (const [name, config] of Object.entries(this.VARIANTS)) {
      variants[name] = await sharp(buffer)
        .resize({
          width: config.width,
          height: config.height,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .webp({ quality: config.quality, effort: 4 })
        .toBuffer();
    }
    
    return variants as ImageVariants;
  }

  async optimize(buffer: Buffer, options: OptimizeOptions = {}): Promise<OptimizedImage> {
    let pipeline = sharp(buffer);
    
    // Resize if needed
    if (options.maxWidth || options.maxHeight) {
      pipeline = pipeline.resize({
        width: options.maxWidth,
        height: options.maxHeight,
        fit: 'inside',
        withoutEnlargement: true,
      });
    }
    
    // Strip EXIF
    if (options.stripExif !== false) {
      pipeline = pipeline.rotate(); // Auto-rotate based on EXIF then strip
      pipeline = pipeline.withMetadata({});
    }
    
    // Format conversion
    const format = options.format || 'webp';
    const quality = options.quality || 85;
    
    if (format === 'webp') {
      pipeline = pipeline.webp({ quality, effort: 4 });
    } else if (format === 'jpeg') {
      pipeline = pipeline.jpeg({ quality, progressive: options.progressive });
    } else if (format === 'png') {
      pipeline = pipeline.png({ quality, compressionLevel: 9 });
    }
    
    const output = await pipeline.toBuffer();
    const meta = await sharp(output).metadata();
    
    return {
      buffer: output,
      format,
      width: meta.width || 0,
      height: meta.height || 0,
      sizeBytes: output.length,
    };
  }

  async stripExif(buffer: Buffer): Promise<Buffer> {
    return sharp(buffer)
      .rotate() // Auto-orient based on EXIF
      .withMetadata({}) // Strip all metadata
      .toBuffer();
  }

  async convertFormat(buffer: Buffer, targetFormat: 'webp' | 'jpeg' | 'png'): Promise<Buffer> {
    const pipeline = sharp(buffer);
    
    if (targetFormat === 'webp') return pipeline.webp({ quality: 85 }).toBuffer();
    if (targetFormat === 'jpeg') return pipeline.jpeg({ quality: 85 }).toBuffer();
    return pipeline.png({ compressionLevel: 9 }).toBuffer();
  }

  async getMetadata(buffer: Buffer): Promise<ImageMetadata> {
    const meta = await sharp(buffer).metadata();
    
    let exifGps;
    if (meta.exif) {
      try {
        // Parse EXIF for GPS (simplified - use exifr for production)
        exifGps = undefined;
      } catch {
        // Ignore
      }
    }
    
    return {
      width: meta.width || 0,
      height: meta.height || 0,
      format: meta.format || 'unknown',
      sizeBytes: buffer.length,
      hasExif: !!meta.exif,
      exifGps,
      channels: meta.channels || 0,
      density: meta.density,
    };
  }

  private buildVariantKey(originalKey: string, variantName: string): string {
    // Original: tenant-x/product/uuid.jpg
    // Variant:  tenant-x/product/uuid_thumbnail.webp
    const lastDot = originalKey.lastIndexOf('.');
    const base = originalKey.slice(0, lastDot);
    return `${base}_${variantName}.webp`;
  }
}
```

### 2. CloudFront Invalidator

```typescript
// server/src/modules/media/services/cdn-invalidator.service.ts
import { Injectable, Logger } from '@nestjs/common';
import {
  CloudFrontClient,
  CreateInvalidationCommand,
} from '@aws-sdk/client-cloudfront';
import { v4 as uuidv4 } from 'uuid';
import { ConfigService } from '../../../config/config.service';
import { MediaRepository } from '../media.repository';
import { ICdnInvalidatorService, InvalidationResult } from '../types/media.types';

@Injectable()
export class CdnInvalidatorService implements ICdnInvalidatorService {
  private readonly logger = new Logger(CdnInvalidatorService.name);
  private readonly client: CloudFrontClient;
  private readonly distributionId: string;

  constructor(
    private readonly config: ConfigService,
    private readonly mediaRepo: MediaRepository,
  ) {
    this.client = new CloudFrontClient({
      region: this.config.aws.region,
      credentials: {
        accessKeyId: this.config.aws.accessKeyId,
        secretAccessKey: this.config.aws.secretAccessKey,
      },
    });
    this.distributionId = this.config.get<string>('AWS_CLOUDFRONT_DISTRIBUTION_ID') || '';
  }

  async invalidate(paths: string[]): Promise<InvalidationResult> {
    if (!this.distributionId) {
      this.logger.warn('CloudFront distribution ID not configured, skipping invalidation');
      return {
        invalidationId: 'skipped',
        paths,
        status: 'completed',
      };
    }
    
    // Ensure paths start with /
    const formattedPaths = paths.map((p) => p.startsWith('/') ? p : `/${p}`);
    
    const command = new CreateInvalidationCommand({
      DistributionId: this.distributionId,
      InvalidationBatch: {
        CallerReference: uuidv4(),
        Paths: {
          Quantity: formattedPaths.length,
          Items: formattedPaths,
        },
      },
    });
    
    try {
      const response = await this.client.send(command);
      this.logger.log(`CDN invalidation created: ${response.Invalidation?.Id}`);
      
      return {
        invalidationId: response.Invalidation?.Id || 'unknown',
        paths: formattedPaths,
        status: 'in-progress',
      };
    } catch (error) {
      this.logger.error('CDN invalidation failed', error);
      throw error;
    }
  }

  async invalidateByMediaId(mediaId: string): Promise<InvalidationResult> {
    const media = await this.mediaRepo.findById(mediaId);
    if (!media) throw new Error('Media not found');
    
    // Invalidate all variants
    const paths = [media.s3Key];
    if (media.variants) {
      const variants = media.variants as any;
      for (const v of Object.values(variants)) {
        if (v && (v as any).s3Key) {
          paths.push((v as any).s3Key);
        }
      }
    }
    
    return this.invalidate(paths);
  }

  async invalidateAll(): Promise<InvalidationResult> {
    return this.invalidate(['/*']);
  }
}
```

### 3. Bull Queue Processor

```typescript
// server/src/modules/media/processors/image-processing.processor.ts
import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';
import { Logger } from '@nestjs/common';
import { ImageProcessorService } from '../services/image-processor.service';

@Processor('image-processing')
export class ImageProcessingProcessor {
  private readonly logger = new Logger(ImageProcessingProcessor.name);

  constructor(private readonly processor: ImageProcessorService) {}

  @Process('process-image')
  async handleProcess(job: Job<{ mediaId: string }>): Promise<void> {
    this.logger.log(`Processing image: ${job.data.mediaId}`);
    
    try {
      const result = await this.processor.processImage(job.data.mediaId);
      this.logger.log(
        `Processed ${result.mediaId}: ${result.totalSizeBytes} bytes, ratio ${result.optimizationRatio.toFixed(2)}`,
      );
    } catch (error) {
      this.logger.error(`Failed to process ${job.data.mediaId}`, error);
      throw error;
    }
  }
}
```

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| POST | `/api/v1/media/:id/reprocess` | Bearer | Force reprocess |
| POST | `/api/v1/media/:id/invalidate` | Admin | CDN invalidation |
| GET | `/api/v1/media/:id/variants` | Bearer | List variants |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-24 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Generate All Variants ✅
Upload 2MB JPEG, process:
**Expected**: 4 variants (thumb, small, medium, large) all WebP
**Pass Criteria**: ✅ Variants generated

### Test 2: Optimization Ratio ✅
Original 2MB → variants total ~500KB:
**Pass Criteria**: ✅ ~75% size reduction

### Test 3: EXIF Stripping ✅
Image with GPS metadata:
**Expected**: Variants have no GPS data
**Pass Criteria**: ✅ Privacy preserved

### Test 4: Format Conversion ✅
PNG input → WebP output:
**Pass Criteria**: ✅ Format converted

### Test 5: Aspect Ratio Preserved ✅
Tall portrait image (200x1000):
**Expected**: Variants maintain aspect (e.g., thumbnail 30x150)
**Pass Criteria**: ✅ No distortion

### Test 6: Auto-orientation ✅
Image with rotated EXIF:
**Expected**: Output displays correctly
**Pass Criteria**: ✅ Orientation fixed

### Test 7: Async Processing ✅
Upload media, immediately query:
**Expected**: status='processing', variants=null
After ~5s: status='ready', variants populated
**Pass Criteria**: ✅ Async works

### Test 8: CDN Invalidation ✅
After update:
**Expected**: CloudFront invalidation triggered
**Pass Criteria**: ✅ Cache invalidated

### Test 9: Variant URLs ✅
**Expected**: All variant URLs return 200 from CDN
**Pass Criteria**: ✅ CDN serves variants

### Test 10: Large Image Handling ✅
20MB image:
**Expected**: Processes successfully (or rejects if > limit)
**Pass Criteria**: ✅ Doesn't OOM

### Test 11: Concurrent Processing ✅
50 images in queue:
**Expected**: All process eventually
**Pass Criteria**: ✅ Queue handles load

### Test 12: Failed Processing Retry ✅
Force a failure:
**Expected**: Bull retries 3 times
**Pass Criteria**: ✅ Retry logic

### Test 13: Reprocess Endpoint ✅
Force reprocess of existing media:
**Pass Criteria**: ✅ Variants regenerated

### Test 14: Tenant Isolation ✅
Process only own tenant's media
**Pass Criteria**: ✅ Isolated

### Test 15: Performance ✅
Single image: < 2 seconds for all variants
**Pass Criteria**: ✅ Fast processing

## 🎯 Q&A Session

### Q1: Why Sharp library?
**Expected**: Fastest Node.js image library, libvips-based, low memory, all formats

### Q2: Why WebP for variants?
**Expected**: 25-35% smaller than JPEG, all browsers support, faster loading

### Q3: Why strip EXIF?
**Expected**: Privacy (GPS, device), smaller files, security

### Q4: Why 4 variants?
**Expected**: Thumbnail for lists, small for cards, medium for detail, large for fullscreen

### Q5: Why async processing?
**Expected**: Upload returns instantly, processing in background, no timeout

### Q6: Why CDN invalidation?
**Expected**: Updated images don't show old version, important for product updates

### Q7: Why preserve original?
**Expected**: Re-processing if needed, audit, can regenerate variants

### Q8: How to handle failed processing?
**Expected**: Status='failed', retry up to 3x, log for investigation, alert ops

## 📝 Sign-Off Checklist

- [ ] All 15 tests pass
- [ ] Variants generated correctly
- [ ] EXIF stripped
- [ ] CDN invalidation works
- [ ] Async processing works
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-24**
**☐ CHANGES REQUESTED**

---

**END OF BE-23 — DO NOT PROCEED WITHOUT APPROVAL**
