# Phase BE-13: Product Image Management & S3

## Phase Metadata

- **Phase ID**: BE-13
- **Phase Name**: Product Image Management & S3
- **Section**: Backend Execution — Core Product Layer
- **Depends On**: BE-01 to BE-12
- **Blocks**: BE-14, BE-23 (all media features)
- **Estimated Duration**: 2 days
- **Complexity**: Medium

## Goal

Implement S3-based image management: presigned URL generation for direct uploads, image validation (type/size), automatic CloudFront CDN URLs, image variants (thumbnail/medium/full), virus/content scanning hooks, lifecycle policies (auto-delete unused), and OFF image migration to our S3.

## Why This Phase Matters

Without proper image management:
- Mobile app uploads go through backend (slow, costly bandwidth)
- No CDN means slow image loading globally
- No size limits = abuse and storage costs
- No virus scanning = security risk
- OFF images break when OFF goes down
- No image variants = mobile downloads full-size

## Prerequisites

- [ ] BE-01 to BE-12 completed
- [ ] AWS account with S3 bucket created
- [ ] CloudFront distribution configured
- [ ] AWS credentials in env vars

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/media_assets.ts` | Media tracking table |
| `server/src/integrations/aws/s3/s3.module.ts` | S3 module |
| `server/src/integrations/aws/s3/s3.service.ts` | S3 wrapper |
| `server/src/integrations/aws/s3/presigned-url.service.ts` | URL generation |
| `server/src/integrations/aws/cloudfront/cloudfront.service.ts` | CDN URLs |
| `server/src/modules/media/media.module.ts` | Media module |
| `server/src/modules/media/media.controller.ts` | Media endpoints |
| `server/src/modules/media/media.service.ts` | Media business logic |
| `server/src/modules/media/media.repository.ts` | Media data access |
| `server/src/modules/media/services/image-variant.service.ts` | Generate variants |
| `server/src/modules/media/services/image-validator.service.ts` | Validate uploads |
| `server/src/modules/media/services/off-image-migration.service.ts` | Migrate OFF images |
| `server/src/modules/media/dto/presign-upload.dto.ts` | DTOs |
| `server/src/modules/media/dto/confirm-upload.dto.ts` | DTOs |
| `server/src/modules/media/utils/file-key.utils.ts` | S3 key generation |
| `server/src/modules/media/types/media.types.ts` | Types |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/integrations/aws/s3/s3.service.ts

export interface IS3Service {
  // Presigned URLs
  generatePresignedUploadUrl(params: PresignUploadParams): Promise<PresignedUploadResult>;
  generatePresignedDownloadUrl(key: string, expirySeconds?: number): Promise<string>;
  
  // Direct operations
  uploadObject(key: string, body: Buffer, contentType: string): Promise<string>;
  downloadObject(key: string): Promise<Buffer>;
  deleteObject(key: string): Promise<void>;
  copyObject(sourceKey: string, destKey: string): Promise<void>;
  
  // Existence
  objectExists(key: string): Promise<boolean>;
  getObjectMetadata(key: string): Promise<ObjectMetadata>;
  
  // Lifecycle
  setLifecyclePolicy(prefix: string, days: number): Promise<void>;
}

export interface PresignUploadParams {
  key: string;
  contentType: string;
  contentLength: number;
  expirySeconds?: number;
  metadata?: Record<string, string>;
}

export interface PresignedUploadResult {
  url: string;
  fields: Record<string, string>;
  expiresIn: number;
  uploadKey: string;
}

// server/src/modules/media/media.service.ts

export interface IMediaService {
  // Upload flow
  initiateUpload(dto: PresignUploadDto, userId: string): Promise<UploadInitResult>;
  confirmUpload(dto: ConfirmUploadDto, userId: string): Promise<MediaAsset>;
  
  // Variants
  generateVariants(mediaId: string): Promise<MediaVariants>;
  
  // CRUD
  findById(id: string): Promise<MediaAsset | null>;
  delete(id: string, userId: string): Promise<void>;
  
  // Special: migrate from URL (e.g., OFF image)
  migrateFromUrl(url: string, productId: string): Promise<MediaAsset>;
  
  // CDN URL generation
  getCdnUrl(key: string, variant?: ImageVariant): string;
}

export interface UploadInitResult {
  mediaId: string;
  uploadUrl: string;
  uploadFields: Record<string, string>;
  expiresIn: number;
  cdnUrl: string; // URL after upload completes
}

export interface MediaVariants {
  thumbnail: string; // 150x150
  medium: string;   // 500x500
  full: string;     // original
}

export type ImageVariant = 'thumbnail' | 'medium' | 'full';

export type MediaStatus = 'pending' | 'uploaded' | 'processing' | 'ready' | 'failed' | 'deleted';

export interface MediaAsset {
  id: string;
  tenantId: string;
  ownerType: 'product' | 'user' | 'tenant' | 'tmp';
  ownerId: string;
  s3Key: string;
  contentType: string;
  contentLength: number;
  status: MediaStatus;
  variants?: MediaVariants;
  uploadedBy: string;
  uploadedAt?: Date;
  metadata?: Record<string, unknown>;
}
```

## Implementation Code

### 1. Media Assets Schema

```typescript
// server/src/db/schema/media_assets.ts
import { pgTable, varchar, uuid, integer, timestamp, jsonb, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns, softDeleteColumn, auditColumns, tenantScopeColumn } from './_base';

export const mediaStatusEnum = pgEnum('media_status', [
  'pending',
  'uploaded',
  'processing',
  'ready',
  'failed',
  'deleted',
]);

export const mediaOwnerTypeEnum = pgEnum('media_owner_type', [
  'product',
  'user',
  'tenant',
  'tmp',
]);

export const mediaAssets = pgTable(
  'media_assets',
  {
    ...baseColumns,
    ...softDeleteColumn,
    ...auditColumns,
    tenantId: uuid('tenant_id').notNull(),
    
    ownerType: mediaOwnerTypeEnum('owner_type').notNull(),
    ownerId: uuid('owner_id'),
    
    s3Key: varchar('s3_key', { length: 500 }).notNull(),
    s3Bucket: varchar('s3_bucket', { length: 100 }).notNull(),
    
    contentType: varchar('content_type', { length: 100 }).notNull(),
    contentLength: integer('content_length').notNull(),
    
    status: mediaStatusEnum('status').notNull().default('pending'),
    
    // Variants (paths to thumbnail, medium, full)
    variants: jsonb('variants').default({}),
    
    // Image-specific
    width: integer('width'),
    height: integer('height'),
    
    // Source tracking
    sourceUrl: varchar('source_url', { length: 500 }),
    
    uploadedAt: timestamp('uploaded_at', { withTimezone: true }),
    processedAt: timestamp('processed_at', { withTimezone: true }),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    ownerIdx: index('idx_media_owner').on(table.ownerType, table.ownerId),
    statusIdx: index('idx_media_status').on(table.status),
    tenantIdx: index('idx_media_tenant').on(table.tenantId),
    s3KeyIdx: index('idx_media_s3key').on(table.s3Key),
  }),
);

export type MediaAsset = typeof mediaAssets.$inferSelect;
export type NewMediaAsset = typeof mediaAssets.$inferInsert;
```

### 2. S3 Service

```typescript
// server/src/integrations/aws/s3/s3.service.ts
import { Injectable, Logger } from '@nestjs/common';
import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
  HeadObjectCommand,
  CopyObjectCommand,
} from '@aws-sdk/client-s3';
import { createPresignedPost } from '@aws-sdk/s3-presigned-post';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { ConfigService } from '../../../config/config.service';
import { IS3Service, PresignUploadParams, PresignedUploadResult } from './s3.types';
import { ExternalServiceException } from '../../../common/errors/business.exception';

@Injectable()
export class S3Service implements IS3Service {
  private readonly logger = new Logger(S3Service.name);
  private readonly client: S3Client;
  private readonly bucket: string;

  constructor(private readonly config: ConfigService) {
    this.client = new S3Client({
      region: this.config.aws.region,
      credentials: {
        accessKeyId: this.config.aws.accessKeyId,
        secretAccessKey: this.config.aws.secretAccessKey,
      },
    });
    this.bucket = this.config.aws.s3.bucket;
  }

  async generatePresignedUploadUrl(
    params: PresignUploadParams,
  ): Promise<PresignedUploadResult> {
    const expirySeconds = params.expirySeconds || 600; // 10 minutes default
    
    try {
      const presigned = await createPresignedPost(this.client, {
        Bucket: this.bucket,
        Key: params.key,
        Conditions: [
          ['content-length-range', 0, params.contentLength],
          ['eq', '$Content-Type', params.contentType],
        ],
        Fields: {
          'Content-Type': params.contentType,
          ...params.metadata,
        },
        Expires: expirySeconds,
      });

      return {
        url: presigned.url,
        fields: presigned.fields,
        expiresIn: expirySeconds,
        uploadKey: params.key,
      };
    } catch (error) {
      this.logger.error('Failed to generate presigned URL', { error });
      throw new ExternalServiceException('S3', error as Error);
    }
  }

  async generatePresignedDownloadUrl(
    key: string,
    expirySeconds: number = 86400,
  ): Promise<string> {
    try {
      const command = new GetObjectCommand({ Bucket: this.bucket, Key: key });
      return await getSignedUrl(this.client, command, { expiresIn: expirySeconds });
    } catch (error) {
      throw new ExternalServiceException('S3', error as Error);
    }
  }

  async uploadObject(key: string, body: Buffer, contentType: string): Promise<string> {
    try {
      await this.client.send(new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: body,
        ContentType: contentType,
      }));
      return key;
    } catch (error) {
      throw new ExternalServiceException('S3', error as Error);
    }
  }

  async downloadObject(key: string): Promise<Buffer> {
    try {
      const response = await this.client.send(new GetObjectCommand({
        Bucket: this.bucket,
        Key: key,
      }));
      
      if (!response.Body) throw new Error('Empty response body');
      
      const chunks: Buffer[] = [];
      const stream = response.Body as NodeJS.ReadableStream;
      
      for await (const chunk of stream) {
        chunks.push(Buffer.from(chunk));
      }
      
      return Buffer.concat(chunks);
    } catch (error) {
      throw new ExternalServiceException('S3', error as Error);
    }
  }

  async deleteObject(key: string): Promise<void> {
    try {
      await this.client.send(new DeleteObjectCommand({
        Bucket: this.bucket,
        Key: key,
      }));
    } catch (error) {
      throw new ExternalServiceException('S3', error as Error);
    }
  }

  async copyObject(sourceKey: string, destKey: string): Promise<void> {
    try {
      await this.client.send(new CopyObjectCommand({
        Bucket: this.bucket,
        Key: destKey,
        CopySource: `${this.bucket}/${sourceKey}`,
      }));
    } catch (error) {
      throw new ExternalServiceException('S3', error as Error);
    }
  }

  async objectExists(key: string): Promise<boolean> {
    try {
      await this.client.send(new HeadObjectCommand({
        Bucket: this.bucket,
        Key: key,
      }));
      return true;
    } catch (error) {
      if ((error as { name: string }).name === 'NotFound') return false;
      throw error;
    }
  }

  async getObjectMetadata(key: string): Promise<{ contentType: string; contentLength: number; lastModified?: Date }> {
    const response = await this.client.send(new HeadObjectCommand({
      Bucket: this.bucket,
      Key: key,
    }));
    
    return {
      contentType: response.ContentType || 'application/octet-stream',
      contentLength: response.ContentLength || 0,
      lastModified: response.LastModified,
    };
  }

  async setLifecyclePolicy(prefix: string, days: number): Promise<void> {
    // Simplified - real implementation uses PutBucketLifecycleConfiguration
    this.logger.log(`Lifecycle: delete ${prefix}/* after ${days} days`);
  }
}
```

### 3. Media Service

```typescript
// server/src/modules/media/media.service.ts
import { Injectable } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { S3Service } from '../../integrations/aws/s3/s3.service';
import { CloudFrontService } from '../../integrations/aws/cloudfront/cloudfront.service';
import { MediaRepository } from './media.repository';
import { ImageValidatorService } from './services/image-validator.service';
import { RequestContextService } from '../../common/context/request-context.service';
import { ConfigService } from '../../config/config.service';
import {
  IMediaService,
  UploadInitResult,
  MediaAsset,
  MediaVariants,
  ImageVariant,
} from './types/media.types';
import {
  ValidationException,
  NotFoundException,
} from '../../common/errors/business.exception';
import { ErrorCode } from '../../common/errors/error-codes';

@Injectable()
export class MediaService implements IMediaService {
  constructor(
    private readonly config: ConfigService,
    private readonly s3: S3Service,
    private readonly cdn: CloudFrontService,
    private readonly mediaRepo: MediaRepository,
    private readonly validator: ImageValidatorService,
    private readonly contextService: RequestContextService,
  ) {}

  async initiateUpload(
    dto: PresignUploadDto,
    userId: string,
  ): Promise<UploadInitResult> {
    // Validate content type
    this.validator.validateContentType(dto.contentType);
    
    // Validate size
    this.validator.validateSize(dto.contentLength);
    
    // Generate unique S3 key
    const tenantId = this.contextService.getTenantId();
    const mediaId = uuidv4();
    const ext = this.getExtension(dto.contentType);
    const s3Key = this.buildS3Key({
      tenantId: tenantId!,
      ownerType: dto.ownerType,
      mediaId,
      ext,
    });
    
    // Create media record (pending status)
    const media = await this.mediaRepo.create({
      id: mediaId,
      ownerType: dto.ownerType,
      ownerId: dto.ownerId,
      s3Key,
      s3Bucket: this.config.aws.s3.bucket,
      contentType: dto.contentType,
      contentLength: dto.contentLength,
      status: 'pending',
      uploadedBy: userId,
    });
    
    // Generate presigned URL
    const presigned = await this.s3.generatePresignedUploadUrl({
      key: s3Key,
      contentType: dto.contentType,
      contentLength: dto.contentLength,
      expirySeconds: 600,
      metadata: {
        'x-amz-meta-media-id': mediaId,
        'x-amz-meta-tenant-id': tenantId!,
      },
    });
    
    return {
      mediaId,
      uploadUrl: presigned.url,
      uploadFields: presigned.fields,
      expiresIn: presigned.expiresIn,
      cdnUrl: this.cdn.getCdnUrl(s3Key),
    };
  }

  async confirmUpload(
    dto: ConfirmUploadDto,
    userId: string,
  ): Promise<MediaAsset> {
    const media = await this.mediaRepo.findById(dto.mediaId);
    if (!media) {
      throw new NotFoundException('Media', dto.mediaId);
    }
    
    // Verify object exists in S3
    const exists = await this.s3.objectExists(media.s3Key);
    if (!exists) {
      await this.mediaRepo.update(media.id, { status: 'failed' });
      throw new ValidationException('Upload not found in S3');
    }
    
    // Get actual metadata
    const metadata = await this.s3.getObjectMetadata(media.s3Key);
    
    // Update status
    await this.mediaRepo.update(media.id, {
      status: 'uploaded',
      uploadedAt: new Date(),
      contentLength: metadata.contentLength,
    });
    
    // Trigger variant generation (async, will be done in BE-23 worker)
    // For now, mark as ready
    await this.mediaRepo.update(media.id, { status: 'ready' });
    
    return await this.mediaRepo.findById(media.id) as MediaAsset;
  }

  async generateVariants(mediaId: string): Promise<MediaVariants> {
    // BE-23 will implement actual image processing
    // For now, return same key for all variants
    const media = await this.mediaRepo.findById(mediaId);
    if (!media) throw new NotFoundException('Media', mediaId);
    
    return {
      thumbnail: this.cdn.getCdnUrl(media.s3Key),
      medium: this.cdn.getCdnUrl(media.s3Key),
      full: this.cdn.getCdnUrl(media.s3Key),
    };
  }

  async findById(id: string): Promise<MediaAsset | null> {
    return this.mediaRepo.findById(id);
  }

  async delete(id: string, userId: string): Promise<void> {
    const media = await this.mediaRepo.findById(id);
    if (!media) throw new NotFoundException('Media', id);
    
    // Soft delete in DB
    await this.mediaRepo.softDelete(id, userId);
    
    // Schedule actual S3 deletion (could be lifecycle policy)
    await this.s3.deleteObject(media.s3Key);
  }

  async migrateFromUrl(url: string, productId: string): Promise<MediaAsset> {
    // Download image from URL
    const response = await fetch(url);
    if (!response.ok) {
      throw new ValidationException(`Failed to fetch image: ${response.status}`);
    }
    
    const buffer = Buffer.from(await response.arrayBuffer());
    const contentType = response.headers.get('content-type') || 'image/jpeg';
    
    this.validator.validateContentType(contentType);
    this.validator.validateSize(buffer.length);
    
    // Upload to our S3
    const tenantId = this.contextService.getTenantId();
    const mediaId = uuidv4();
    const ext = this.getExtension(contentType);
    const s3Key = this.buildS3Key({
      tenantId: tenantId!,
      ownerType: 'product',
      mediaId,
      ext,
    });
    
    await this.s3.uploadObject(s3Key, buffer, contentType);
    
    // Create media record
    return this.mediaRepo.create({
      id: mediaId,
      ownerType: 'product',
      ownerId: productId,
      s3Key,
      s3Bucket: this.config.aws.s3.bucket,
      contentType,
      contentLength: buffer.length,
      status: 'ready',
      sourceUrl: url,
      uploadedAt: new Date(),
      uploadedBy: 'system',
    });
  }

  getCdnUrl(key: string, variant?: ImageVariant): string {
    if (!variant || variant === 'full') {
      return this.cdn.getCdnUrl(key);
    }
    
    // Variant-specific path: products/{id}/thumbnail.jpg
    const variantKey = key.replace(/\.[^.]+$/, `.${variant}$&`);
    return this.cdn.getCdnUrl(variantKey);
  }

  private buildS3Key(params: {
    tenantId: string;
    ownerType: string;
    mediaId: string;
    ext: string;
  }): string {
    return `${params.tenantId}/${params.ownerType}/${params.mediaId}.${params.ext}`;
  }

  private getExtension(contentType: string): string {
    const map: Record<string, string> = {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/webp': 'webp',
      'image/gif': 'gif',
    };
    return map[contentType] || 'bin';
  }
}
```

### 4. Image Validator

```typescript
// server/src/modules/media/services/image-validator.service.ts
import { Injectable } from '@nestjs/common';
import { ValidationException } from '../../../common/errors/business.exception';

@Injectable()
export class ImageValidatorService {
  private readonly ALLOWED_TYPES = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
  ];
  
  private readonly MAX_SIZE_BYTES = 10 * 1024 * 1024; // 10MB
  private readonly MIN_SIZE_BYTES = 100; // 100 bytes (avoid 0-byte files)

  validateContentType(contentType: string): void {
    if (!this.ALLOWED_TYPES.includes(contentType)) {
      throw new ValidationException(
        `Invalid content type: ${contentType}`,
        {
          field: 'contentType',
          value: contentType,
          expected: this.ALLOWED_TYPES.join(', '),
        },
      );
    }
  }

  validateSize(bytes: number): void {
    if (bytes < this.MIN_SIZE_BYTES) {
      throw new ValidationException('File too small');
    }
    if (bytes > this.MAX_SIZE_BYTES) {
      throw new ValidationException(
        `File too large. Max: ${this.MAX_SIZE_BYTES / 1024 / 1024}MB`,
      );
    }
  }

  async validateImageBuffer(buffer: Buffer): Promise<{ width: number; height: number }> {
    // Use sharp library to validate (will be in BE-23)
    // For now, check magic numbers
    if (buffer.length < 12) {
      throw new ValidationException('Invalid image data');
    }
    
    const isJpeg = buffer[0] === 0xFF && buffer[1] === 0xD8;
    const isPng = buffer[0] === 0x89 && buffer[1] === 0x50;
    const isWebp = buffer.toString('utf8', 8, 12) === 'WEBP';
    const isGif = buffer.toString('utf8', 0, 3) === 'GIF';
    
    if (!isJpeg && !isPng && !isWebp && !isGif) {
      throw new ValidationException('Invalid image format');
    }
    
    return { width: 0, height: 0 }; // BE-23 will extract real dimensions
  }
}
```

### 5. CloudFront Service

```typescript
// server/src/integrations/aws/cloudfront/cloudfront.service.ts
import { Injectable } from '@nestjs/common';
import { ConfigService } from '../../../config/config.service';

@Injectable()
export class CloudFrontService {
  constructor(private readonly config: ConfigService) {}

  getCdnUrl(s3Key: string): string {
    const domain = this.config.aws.cloudfront.domain;
    if (!domain) {
      // Fallback to S3 URL if no CDN configured
      return `https://${this.config.aws.s3.bucket}.s3.${this.config.aws.region}.amazonaws.com/${s3Key}`;
    }
    return `https://${domain}/${s3Key}`;
  }

  async invalidateCache(paths: string[]): Promise<void> {
    // BE-32 will implement CloudFront invalidation
  }
}
```

## DTOs

```typescript
// server/src/modules/media/dto/presign-upload.dto.ts
import { z } from 'zod';

export const PresignUploadSchema = z.object({
  ownerType: z.enum(['product', 'user', 'tenant', 'tmp']),
  ownerId: z.string().uuid().optional(),
  contentType: z.enum(['image/jpeg', 'image/png', 'image/webp', 'image/gif']),
  contentLength: z.number().int().min(100).max(10 * 1024 * 1024),
  filename: z.string().max(255).optional(),
});

export type PresignUploadDto = z.infer<typeof PresignUploadSchema>;
```

```typescript
// server/src/modules/media/dto/confirm-upload.dto.ts
import { z } from 'zod';

export const ConfirmUploadSchema = z.object({
  mediaId: z.string().uuid(),
});

export type ConfirmUploadDto = z.infer<typeof ConfirmUploadSchema>;
```

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| POST | `/api/v1/media/presign` | Bearer | Get presigned upload URL |
| POST | `/api/v1/media/:id/confirm` | Bearer | Confirm upload complete |
| GET | `/api/v1/media/:id` | Bearer | Get media details |
| DELETE | `/api/v1/media/:id` | Bearer | Delete media |
| POST | `/api/v1/media/migrate-from-url` | Bearer | Migrate external image |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-14 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Get Presigned Upload URL ✅

```bash
curl -X POST http://localhost:3000/api/v1/media/presign \
  -H "Authorization: Bearer <token>" \
  -d '{
    "ownerType":"product",
    "ownerId":"<product-id>",
    "contentType":"image/jpeg",
    "contentLength":102400
  }'
```

**Expected**:
```json
{
  "data": {
    "mediaId": "<uuid>",
    "uploadUrl": "https://...s3.amazonaws.com/...",
    "uploadFields": {...},
    "expiresIn": 600,
    "cdnUrl": "https://cdn.radha.com/..."
  }
}
```

**Pass Criteria**: ✅ Returns valid presigned URL

---

### Test 2: Direct Upload to S3 ✅

```bash
# Use presigned URL to upload
curl -X POST <uploadUrl> \
  -F "Content-Type=image/jpeg" \
  -F "file=@test-image.jpg"
```

**Expected**: 204 from S3
**Pass Criteria**: ✅ Direct upload works (bypass backend)

---

### Test 3: Confirm Upload ✅

```bash
curl -X POST http://localhost:3000/api/v1/media/<mediaId>/confirm \
  -H "Authorization: Bearer <token>"
```

**Expected**: Media status changes to 'ready'
**Pass Criteria**: ✅ Confirmation works

---

### Test 4: Invalid Content Type ✅

```bash
curl -X POST http://localhost:3000/api/v1/media/presign \
  -d '{"contentType":"application/exe","contentLength":1000}'
```

**Expected**: 400 with VALIDATION_ERROR
**Pass Criteria**: ✅ Only allowed types accepted

---

### Test 5: Size Limit ✅

```bash
curl -X POST http://localhost:3000/api/v1/media/presign \
  -d '{"contentLength":20000000}'
```

**Expected**: 400 — exceeds 10MB
**Pass Criteria**: ✅ Size limit enforced

---

### Test 6: Migrate from URL ✅

```bash
curl -X POST http://localhost:3000/api/v1/media/migrate-from-url \
  -H "Authorization: Bearer <token>" \
  -d '{"url":"https://example.com/image.jpg","productId":"<id>"}'
```

**Expected**: Image downloaded, uploaded to S3, media record created
**Pass Criteria**: ✅ URL migration works

---

### Test 7: CDN URL Generation ✅

```typescript
const url = mediaService.getCdnUrl('tenant-1/product/abc.jpg');
expect(url).toMatch(/cloudfront/);
```

**Pass Criteria**: ✅ Returns CDN URL

---

### Test 8: Tenant Isolation ✅

User from Tenant A tries to access Tenant B media:
**Expected**: 404 (TenantScopedRepository blocks)
**Pass Criteria**: ✅ Cross-tenant access blocked

---

### Test 9: Soft Delete ✅

```bash
curl -X DELETE http://localhost:3000/api/v1/media/<id> \
  -H "Authorization: Bearer <token>"
```

**Expected**: Status='deleted', deletedAt set, S3 object deleted
**Pass Criteria**: ✅ Soft delete + S3 cleanup

---

### Test 10: Pending Upload Cleanup ✅

Upload that never gets confirmed (pending > 1 hour):
**Expected**: BE-24 cron job will clean up
**Pass Criteria**: ✅ No orphaned records

---

### Test 11: S3 Object Existence Check ✅

After upload, check object exists:
```typescript
const exists = await s3Service.objectExists('tenant-1/product/abc.jpg');
expect(exists).toBe(true);
```

**Pass Criteria**: ✅ S3 metadata accurate

---

### Test 12: Magic Number Validation ✅

Upload a file with .jpg extension but PHP content:
**Expected**: Validation rejects (magic numbers don't match)
**Pass Criteria**: ✅ Cannot upload disguised files

---

### Test 13: Presigned URL Expiration ✅

Wait 11 minutes after presigning, then try to upload:
**Expected**: 403 from S3 (URL expired)
**Pass Criteria**: ✅ Expiration enforced

---

### Test 14: Concurrent Upload Safety ✅

Two requests for same product image:
**Expected**: Both succeed, two media records, last one wins
**Pass Criteria**: ✅ No data corruption

---

### Test 15: Performance ✅

```bash
time curl -X POST .../presign ...
# Expected: < 100ms
```

**Pass Criteria**: ✅ Fast presigning

---

## 🎯 Q&A Session

### Q1: Why presigned URLs vs proxy through backend?

**Expected Answer**:
- Bandwidth cost: Backend doesn't relay file bytes
- Speed: Direct upload to S3
- Scalability: Backend doesn't bottleneck
- Cost: AWS bandwidth cheaper than EC2
- Simpler: Less code, fewer failure points

---

### Q2: Why CloudFront CDN?

**Expected Answer**:
- Global edge caching (fast worldwide)
- Lower latency for users
- Reduces S3 GET costs (cache hits)
- HTTPS termination
- DDoS protection
- ~30% cost savings on bandwidth

---

### Q3: Why magic number validation?

**Expected Answer**:
- File extension can be lied about
- Magic numbers in file header are real
- Prevents uploading PHP/script disguised as image
- Required for security (XSS, RCE prevention)
- Standard practice

---

### Q4: How to handle large image uploads?

**Expected Answer**:
- Multipart upload for > 5MB (future)
- Currently: 10MB limit via single PUT
- Mobile resizes before upload
- Server validates on confirm
- Async variant generation (BE-23)

---

### Q5: Why migrate OFF images to our S3?

**Expected Answer**:
- OFF may go down → broken images
- OFF may delete images → broken images
- Better latency (our CDN closer to users)
- Don't hot-link external resources
- Bandwidth costs us either way
- Can apply our own variants

---

### Q6: How does S3 key structure prevent conflicts?

**Expected Answer**:
- `{tenantId}/{ownerType}/{mediaId}.{ext}`
- UUID for mediaId = no collisions
- TenantId prefix = isolation
- ownerType for organization
- Easy lifecycle policies per prefix

---

### Q7: Lifecycle policies for cost?

**Expected Answer**:
- Pending uploads: Delete after 7 days
- Deleted media: Move to Glacier after 30 days
- Old variants: Regenerate on demand
- Hot files: Stay in S3 standard
- Saves ~40-60% on storage

---

### Q8: Security for presigned URLs?

**Expected Answer**:
- Short expiration (10 minutes default)
- Content-type restriction
- Content-length limit
- Tied to specific S3 key
- Cannot be reused for different file
- IP-based restrictions (future)

---

## 📝 Sign-Off Checklist

### Functional
- [ ] Presigned URL generation works
- [ ] Direct upload to S3 works
- [ ] Upload confirmation works
- [ ] CDN URLs returned
- [ ] Migration from URL works
- [ ] Tenant isolation maintained
- [ ] Soft delete + S3 cleanup

### Security
- [ ] Magic number validation
- [ ] Content type whitelist
- [ ] Size limits enforced
- [ ] Presigned URLs expire
- [ ] Cannot upload to wrong tenant

### Performance
- [ ] Presigning < 100ms
- [ ] No backend bandwidth for uploads

### Tests
- [ ] All 15 tests pass
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-14**
**☐ CHANGES REQUESTED**

---

**END OF BE-13 — DO NOT PROCEED WITHOUT APPROVAL**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-13 with the presigned-URL upload path used by Image_OCR_Fallback (Req 38).**

## Driver Requirement

- **Req 38** — Image OCR fallback uploads packaging photos via `Presigned_URL` so identification can run server-side.

## Scope of Update

Existing `S3UploadService` already supports presigned uploads. v2 adds:

1. A dedicated bucket prefix `image-ocr-fallback/{userId}/{uuid}.jpg`.
2. A 7-day lifecycle rule on that prefix to auto-delete unused images (consistent with Req 18 lifecycle policies).
3. A small `imageOcrFallback` flavor on `S3UploadService` so BE-45 calls a clean façade.

## Files to Modify

| File Path | Change |
|---|---|
| `server/src/modules/media/services/s3-upload.service.ts` | Add `presignImageOcrFallback(userId)` |
| `infra/s3-lifecycle/image-ocr-fallback.yaml` | New lifecycle rule (7-day expiration) |

## ADDENDUM v2 Test Procedures (add 2)

| # | Test |
|---|---|
| T-v2.1 | `presignImageOcrFallback` returns a 10-minute presigned URL targeting the correct prefix |
| T-v2.2 | Lifecycle rule deletes objects after 7 days (verified in staging via lifecycle audit) |

## ADDENDUM v2 Q&A (add 2)

- **Q-v2.1**: How does the system clean up images uploaded for fallback that fail before the OFF upsert step (orphaned blobs)?
- **Q-v2.2**: Are user-submitted barcode-learning images (Req 46, BE-56) stored under a different prefix and lifecycle?

## ADDENDUM v2 Sign-off

- [ ] Presigned URL flavor added
- [ ] Lifecycle rule live
- [ ] Orphan cleanup tested

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-13 ADDENDUM v2**
