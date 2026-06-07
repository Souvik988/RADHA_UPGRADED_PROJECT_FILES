/**
 * Saved-products contracts (FE-16 / BE-XX).
 *
 * Mirrors the canonical shape returned by the backend REST surface:
 *
 *   GET    /api/v1/saved-products?cursor=&limit=     200
 *   POST   /api/v1/saved-products                    201
 *   DELETE /api/v1/saved-products/:id                204
 *
 * This file is type-only by policy — the server owns its own
 * `class-validator` DTOs (with constraints like length and ISO-date
 * formats). Frontends consume these as a typed mirror; do NOT add
 * runtime validators or framework imports here.
 */

/**
 * A single saved product as returned by the server.
 *
 * Date fields are emitted as ISO-8601 strings. `expiresAt` is an
 * ISO date (`YYYY-MM-DD`) — no time component. The other timestamps
 * are full ISO datetimes. The frontend keeps them as strings; any
 * formatting happens at the render layer.
 */
export interface SavedProductDto {
  id: string;
  userId: string;
  productName: string;
  productId: string | null;
  barcode: string | null;
  /** ISO date `YYYY-MM-DD` — null when the user did not capture an expiry. */
  expiresAt: string | null;
  /** ISO datetime — set when the user marks the product as consumed. */
  markedConsumedAt: string | null;
  notes: string | null;
  /** ISO datetime. */
  createdAt: string;
  /** ISO datetime. */
  updatedAt: string;
}

/**
 * Body for `POST /api/v1/saved-products`.
 *
 * The server validates `productName` (1..200 chars), `barcode`
 * (8..14 digits), `expiresAt` (`YYYY-MM-DD`), and `notes` (≤500 chars).
 * Those constraints stay server-side; this type just describes the
 * shape so frontends can build the body without guesswork.
 */
export interface CreateSavedProductInput {
  productName: string;
  productId?: string;
  barcode?: string;
  expiresAt?: string;
  notes?: string;
}

/**
 * Response envelope for `GET /api/v1/saved-products`.
 *
 * Cursor pagination — `nextCursor` is `null` on the last page.
 */
export interface ListSavedProductsResponse {
  items: SavedProductDto[];
  nextCursor: string | null;
}
