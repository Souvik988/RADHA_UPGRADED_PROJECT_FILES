import { sql } from 'drizzle-orm';
import { index, pgTable, text, timestamp, uniqueIndex, uuid } from 'drizzle-orm/pg-core';

import { users } from './users';

/**
 * BE-56 — Community Barcode Learning Service.
 *
 * Two tables, both intentionally tenant-less because the feature is
 * a global, India-specific product crowd-source on top of Open Food
 * Facts (Req 46). Approved submissions land in `Product_Catalog` as
 * `tenant_id = NULL` rows, visible to every consumer.
 *
 *   - `barcode_learning_submissions` — moderation queue.
 *     `status` walks `pending → approved | rejected | flagged`.
 *     `flagged` is the special re-moderation state pushed back into
 *     the queue when the flag-tracker accumulates 3 unique reports
 *     against the EAN of a previously approved submission.
 *
 *   - `barcode_learning_flags`       — consumer-facing "this entry
 *     looks wrong" reports. The `UNIQUE(product_ean, flagger_user_id)`
 *     constraint prevents a single user from spamming the threshold.
 *     `created_at` is kept so the threshold can be windowed in
 *     future iterations without a schema change.
 */
export const barcodeLearningSubmissions = pgTable(
  'barcode_learning_submissions',
  {
    id: uuid('id')
      .primaryKey()
      .default(sql`gen_random_uuid()`),
    submitterUserId: uuid('submitter_user_id')
      .notNull()
      .references(() => users.id),
    ean: text('ean').notNull(),
    brand: text('brand'),
    name: text('name'),
    category: text('category'),
    s3ObjectKeys: text('s3_object_keys').array(),
    /**
     * Status walks `pending → approved | rejected | flagged`. The
     * `flagged` state is set by the flag-tracker when an approved
     * submission accumulates 3 unique flags so the moderator queue
     * picks it up again.
     */
    status: text('status').notNull().default('pending'),
    submittedAt: timestamp('submitted_at', { withTimezone: true })
      .notNull()
      .default(sql`now()`),
    moderatedAt: timestamp('moderated_at', { withTimezone: true }),
    moderatedBy: uuid('moderated_by').references(() => users.id),
    moderationNotes: text('moderation_notes'),
  },
  (t) => ({
    statusIdx: index('idx_barcode_submissions_status').on(t.status, t.submittedAt),
    eanIdx: index('idx_barcode_submissions_ean').on(t.ean),
  }),
);

export type BarcodeLearningSubmissionRow = typeof barcodeLearningSubmissions.$inferSelect;
export type NewBarcodeLearningSubmission = typeof barcodeLearningSubmissions.$inferInsert;

export const barcodeLearningFlags = pgTable(
  'barcode_learning_flags',
  {
    id: uuid('id')
      .primaryKey()
      .default(sql`gen_random_uuid()`),
    productEan: text('product_ean').notNull(),
    flaggerUserId: uuid('flagger_user_id')
      .notNull()
      .references(() => users.id),
    reason: text('reason'),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .default(sql`now()`),
  },
  (t) => ({
    eanIdx: index('idx_barcode_flags_ean').on(t.productEan),
    uniqueEanFlagger: uniqueIndex('barcode_flags_ean_flagger_unique').on(
      t.productEan,
      t.flaggerUserId,
    ),
  }),
);

export type BarcodeLearningFlagRow = typeof barcodeLearningFlags.$inferSelect;
export type NewBarcodeLearningFlag = typeof barcodeLearningFlags.$inferInsert;

/**
 * Allowed values for `barcode_learning_submissions.status`.
 * Mirrors the SQL `CHECK` constraint declared in
 * `0027_be56_barcode_learning.sql`.
 */
export const BARCODE_LEARNING_STATUSES = ['pending', 'approved', 'rejected', 'flagged'] as const;

export type BarcodeLearningStatus = (typeof BARCODE_LEARNING_STATUSES)[number];
