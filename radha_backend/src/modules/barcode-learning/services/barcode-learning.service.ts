import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import type {
  BarcodeLearningStatus,
  BarcodeLearningSubmissionRow,
} from '@/db/schema/barcode-learning';
import { LoggerService } from '@/logging/logger.service';
import { AuditLogService } from '@/observability/audit-log.service';

import type { ApproveSubmissionDto, RejectSubmissionDto } from '../dto/moderate.dto';
import type { FlagProductDto } from '../dto/flag-product.dto';
import type { SubmitBarcodeDto } from '../dto/submit-barcode.dto';
import {
  PRODUCTS_CATALOG_PORT,
  ProductsCatalogPort,
} from '../ports/products-catalog.port';
import { FlagRepository } from '../repositories/flag.repository';
import { SubmissionRepository } from '../repositories/submission.repository';
import { FlagTrackerService, FlagTrackResult } from './flag-tracker.service';

/**
 * BE-56 — Community Barcode Learning service.
 *
 * Owns:
 *   - Consumer submission (`submit`)
 *     • Enforces `MAX_SUBMISSIONS_PER_DAY` per user (in-memory
 *       fallback; future BE-46 v2 hookup will swap in Redis).
 *     • Always inserts a fresh row — multiple users may submit the
 *       same EAN. The moderator consolidates on approve.
 *
 *   - Moderator queue (`listQueue`)
 *     • Filters by `status` (`pending` by default, `flagged` for
 *       re-moderation cases).
 *
 *   - Approval (`approve`)
 *     • Pushes the (optionally edited) data through the
 *       `ProductsCatalogPort` — the global `Product_Catalog` upsert
 *       happens here, behind the port boundary.
 *     • Sets `status='approved'`, `moderated_at`, `moderated_by`.
 *
 *   - Rejection (`reject`)
 *     • Sets `status='rejected'`, `moderated_at`, `moderation_notes`.
 *     • Does NOT touch the catalog.
 *
 *   - Flag (`flag`)
 *     • Inserts via the unique constraint so duplicate user flags
 *       are silent no-ops.
 *     • Delegates threshold evaluation to `FlagTrackerService` so
 *       the cross-cutting policy lives in one place.
 *
 * Every state-changing path writes an audit log entry. PII fields
 * (brand, name, category) are bounded by the DTO; we log only the
 * EAN + ids.
 */

/** BE-56 spec: 10 submissions / user / day. */
export const MAX_SUBMISSIONS_PER_DAY = 10;

const ONE_DAY_MS = 24 * 60 * 60 * 1000;

export interface SubmissionDto {
  id: string;
  submitterUserId: string;
  ean: string;
  brand: string | null;
  name: string | null;
  category: string | null;
  s3ObjectKeys: string[];
  status: BarcodeLearningStatus;
  submittedAt: string;
  moderatedAt: string | null;
  moderatedBy: string | null;
  moderationNotes: string | null;
}

export interface QueueResultDto {
  data: SubmissionDto[];
  total: number;
  limit: number;
  offset: number;
}

export interface FlagResultDto {
  ean: string;
  uniqueFlagCount: number;
  thresholdCrossed: boolean;
  flippedSubmissionId: string | null;
  duplicate: boolean;
}

export interface ApproveResultDto {
  submission: SubmissionDto;
  productId: string;
  catalogCreated: boolean;
}

@Injectable()
export class BarcodeLearningService {
  constructor(
    private readonly submissions: SubmissionRepository,
    private readonly flags: FlagRepository,
    private readonly flagTracker: FlagTrackerService,
    @Inject(PRODUCTS_CATALOG_PORT)
    private readonly catalog: ProductsCatalogPort,
    private readonly logger: LoggerService,
    private readonly audit: AuditLogService,
  ) {}

  /* ─────────────────── Consumer: submit ─────────────────── */

  /**
   * Insert a pending submission. Enforces the daily rate limit by
   * counting rows in the last 24 hours; the BE-56 spec calls for a
   * 10-per-day cap and notes that a Redis-backed counter is fine to
   * swap in later.
   */
  async submit(userId: string, dto: SubmitBarcodeDto): Promise<SubmissionDto> {
    if (!userId) {
      throw new BadRequestException('userId is required');
    }

    const since = new Date(Date.now() - ONE_DAY_MS);
    const todayCount = await this.submissions.countByUserSince(userId, since);
    if (todayCount >= MAX_SUBMISSIONS_PER_DAY) {
      throw new ConflictException(
        `Daily submission limit reached (max ${MAX_SUBMISSIONS_PER_DAY} per user per day)`,
      );
    }

    const row = await this.submissions.create({
      submitterUserId: userId,
      ean: dto.ean,
      brand: dto.brand ?? null,
      name: dto.name ?? null,
      category: dto.category ?? null,
      s3ObjectKeys: dto.s3ObjectKeys ?? null,
    });

    this.logger.info('barcode_learning.submitted', {
      submissionId: row.id,
      ean: row.ean,
      userId,
    });

    void this.audit.logAction({
      action: 'CREATE',
      resourceType: 'barcode_learning_submission',
      resourceId: row.id,
      tenantId: '',
      userId,
      success: true,
      metadata: { ean: row.ean, hasImages: (dto.s3ObjectKeys?.length ?? 0) > 0 },
    });

    return this.toDto(row);
  }

  /* ─────────────────── Moderator: queue ─────────────────── */

  /**
   * Return submissions awaiting a moderator decision. `pending` is
   * the default; `flagged` re-surfaces previously approved entries
   * that the community has called into question.
   */
  async listQueue(filters: {
    status: BarcodeLearningStatus;
    limit: number;
    offset: number;
  }): Promise<QueueResultDto> {
    const [rows, total] = await Promise.all([
      this.submissions.listByStatus(filters.status, {
        limit: filters.limit,
        offset: filters.offset,
      }),
      this.submissions.countByStatus(filters.status),
    ]);
    return {
      data: rows.map((r) => this.toDto(r)),
      total,
      limit: filters.limit,
      offset: filters.offset,
    };
  }

  /* ─────────────────── Moderator: approve ─────────────────── */

  /**
   * Approve a submission and push its data into `Product_Catalog`
   * via the port. Refuses to re-approve a row that is already
   * approved/rejected (idempotency boundary lives at the controller
   * + service contract — repeated clicks return a clean conflict
   * rather than silently corrupting the timeline).
   */
  async approve(
    submissionId: string,
    moderatorId: string,
    dto: ApproveSubmissionDto,
  ): Promise<ApproveResultDto> {
    const existing = await this.requireSubmission(submissionId);
    if (existing.status === 'approved') {
      throw new ConflictException('Submission is already approved');
    }
    if (existing.status === 'rejected') {
      throw new ConflictException('Submission was rejected — submit a new one to revisit');
    }

    const merged = {
      ean: existing.ean,
      brand: dto.brand ?? existing.brand,
      name: dto.name ?? existing.name,
      category: dto.category ?? existing.category,
      s3ObjectKeys: existing.s3ObjectKeys,
    };

    const catalogResult = await this.catalog.upsertGlobal({
      ean: merged.ean,
      brand: merged.brand,
      name: merged.name,
      category: merged.category,
      s3ObjectKeys: merged.s3ObjectKeys,
      source: 'community',
      submitterUserId: existing.submitterUserId,
      approvedBy: moderatorId,
    });

    const updated = await this.submissions.updateStatus(submissionId, {
      status: 'approved',
      moderatedAt: new Date(),
      moderatedBy: moderatorId,
      moderationNotes: dto.notes ?? null,
    });
    if (!updated) {
      throw new NotFoundException('Submission not found');
    }

    this.logger.info('barcode_learning.approved', {
      submissionId,
      ean: existing.ean,
      moderatorId,
      productId: catalogResult.productId,
      catalogCreated: catalogResult.created,
    });

    void this.audit.logAction({
      action: 'UPDATE',
      resourceType: 'barcode_learning_submission',
      resourceId: submissionId,
      tenantId: '',
      userId: moderatorId,
      success: true,
      metadata: {
        outcome: 'approved',
        ean: existing.ean,
        productId: catalogResult.productId,
        catalogCreated: catalogResult.created,
      },
    });

    return {
      submission: this.toDto(updated),
      productId: catalogResult.productId,
      catalogCreated: catalogResult.created,
    };
  }

  /* ─────────────────── Moderator: reject ─────────────────── */

  /**
   * Reject a submission with a mandatory reason. Does NOT call the
   * catalog — rejected entries never become public.
   */
  async reject(
    submissionId: string,
    moderatorId: string,
    dto: RejectSubmissionDto,
  ): Promise<SubmissionDto> {
    const existing = await this.requireSubmission(submissionId);
    if (existing.status === 'approved') {
      throw new ConflictException('Submission is already approved — cannot reject');
    }
    if (existing.status === 'rejected') {
      throw new ConflictException('Submission is already rejected');
    }

    const updated = await this.submissions.updateStatus(submissionId, {
      status: 'rejected',
      moderatedAt: new Date(),
      moderatedBy: moderatorId,
      moderationNotes: dto.reason,
    });
    if (!updated) {
      throw new NotFoundException('Submission not found');
    }

    this.logger.info('barcode_learning.rejected', {
      submissionId,
      ean: existing.ean,
      moderatorId,
    });

    void this.audit.logAction({
      action: 'UPDATE',
      resourceType: 'barcode_learning_submission',
      resourceId: submissionId,
      tenantId: '',
      userId: moderatorId,
      success: true,
      metadata: { outcome: 'rejected', ean: existing.ean },
    });

    return this.toDto(updated);
  }

  /* ─────────────────── Consumer: flag ─────────────────── */

  /**
   * Record a consumer flag against an EAN. The unique
   * `(product_ean, flagger_user_id)` constraint keeps a single user
   * from inflating the threshold; duplicates are silent no-ops
   * (`duplicate: true` in the response).
   *
   * After every successful insert we evaluate the threshold via
   * `FlagTrackerService`. The flip happens inside the tracker so
   * the policy lives in one place.
   */
  async flag(userId: string, ean: string, dto: FlagProductDto): Promise<FlagResultDto> {
    if (!userId) {
      throw new BadRequestException('userId is required');
    }

    const inserted = await this.flags.create({
      productEan: ean,
      flaggerUserId: userId,
      reason: dto.reason ?? null,
    });
    const duplicate = inserted === null;

    let trackResult: FlagTrackResult;
    if (duplicate) {
      // Same user, same EAN — count is unchanged. Still surface the
      // current count so the client can render a "you already
      // flagged this" affordance.
      const uniqueFlagCount = await this.flags.countUniqueByEan(ean);
      trackResult = {
        ean,
        uniqueFlagCount,
        thresholdCrossed: false,
        flippedSubmissionId: null,
      };
    } else {
      trackResult = await this.flagTracker.evaluate(ean);
    }

    this.logger.info('barcode_learning.flagged', {
      ean,
      userId,
      duplicate,
      uniqueFlagCount: trackResult.uniqueFlagCount,
      thresholdCrossed: trackResult.thresholdCrossed,
    });

    if (!duplicate) {
      void this.audit.logAction({
        action: 'CREATE',
        resourceType: 'barcode_learning_flag',
        resourceId: ean,
        tenantId: '',
        userId,
        success: true,
        metadata: {
          ean,
          uniqueFlagCount: trackResult.uniqueFlagCount,
          thresholdCrossed: trackResult.thresholdCrossed,
        },
      });
    }

    return {
      ean: trackResult.ean,
      uniqueFlagCount: trackResult.uniqueFlagCount,
      thresholdCrossed: trackResult.thresholdCrossed,
      flippedSubmissionId: trackResult.flippedSubmissionId,
      duplicate,
    };
  }

  /* ─────────────────── Internal helpers ─────────────────── */

  private async requireSubmission(id: string): Promise<BarcodeLearningSubmissionRow> {
    const row = await this.submissions.findById(id);
    if (!row) {
      throw new NotFoundException('Submission not found');
    }
    return row;
  }

  private toDto(row: BarcodeLearningSubmissionRow): SubmissionDto {
    return {
      id: row.id,
      submitterUserId: row.submitterUserId,
      ean: row.ean,
      brand: row.brand ?? null,
      name: row.name ?? null,
      category: row.category ?? null,
      s3ObjectKeys: row.s3ObjectKeys ?? [],
      status: row.status as BarcodeLearningStatus,
      submittedAt: row.submittedAt.toISOString(),
      moderatedAt: row.moderatedAt ? row.moderatedAt.toISOString() : null,
      moderatedBy: row.moderatedBy ?? null,
      moderationNotes: row.moderationNotes ?? null,
    };
  }
}
