import { z } from 'zod';

/**
 * BE-56 — Body of `POST /api/v1/products/learn`.
 *
 * Consumers submit barcode metadata for a product not yet in Open
 * Food Facts. `s3ObjectKeys` references images uploaded via the
 * BE-13 presigned URL flow — we only store the key, not the URL,
 * because the bucket lifecycle keeps objects 7 days then archives
 * them once the moderator has reviewed.
 *
 * Optional brand/name/category lets consumers submit partial
 * information; the moderator can complete the entry on approval.
 */
export const SubmitBarcodeSchema = z
  .object({
    ean: z
      .string()
      .trim()
      .min(8, 'ean must be at least 8 digits')
      .max(14, 'ean must be at most 14 digits')
      .regex(/^\d+$/, 'ean must be numeric'),
    brand: z.string().trim().min(1).max(120).optional(),
    name: z.string().trim().min(1).max(200).optional(),
    category: z.string().trim().min(1).max(120).optional(),
    s3ObjectKeys: z.array(z.string().trim().min(1).max(512)).max(8).optional(),
  })
  .strict();

export type SubmitBarcodeDto = z.infer<typeof SubmitBarcodeSchema>;
