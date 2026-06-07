/**
 * @radha/shared-types
 *
 * Shared TypeScript types used across:
 *  - server (NestJS backend)
 *  - mobile (Flutter via codegen — only the schema-relevant subset)
 *  - dashboard (Next.js owner dashboard)
 *  - marketing (Next.js marketing website)
 *
 * Keep this package framework-free. No NestJS, no React, no AWS imports here.
 * Add domain primitives only.
 */

/* ============================================================================
 * Branded primitives
 * ========================================================================== */

export type Brand<T, B extends string> = T & { readonly __brand: B };

export type UserId = Brand<string, 'UserId'>;
export type TenantId = Brand<string, 'TenantId'>;
export type StoreId = Brand<string, 'StoreId'>;
export type ProductId = Brand<string, 'ProductId'>;

/* ============================================================================
 * Domain enums (mirrored from spec)
 * ========================================================================== */

export type UserRole = 'owner' | 'manager' | 'staff' | 'auditor' | 'consumer' | 'admin';

export type SubscriptionTier =
  | 'free_consumer'
  | 'premium_consumer'
  | 'trial_pro'
  | 'starter'
  | 'growth'
  | 'pro';

export type ScanOutputMode = 'basic' | 'comprehensive';

export type OnboardingSegment =
  | 'personal'
  | 'business_owner'
  | 'parent'
  | 'pharmacy'
  | 'institution'
  | 'auditor_invited';

/* ============================================================================
 * Common API envelope shapes
 * ========================================================================== */

export interface ApiErrorBody {
  errorId: string;
  code: string;
  message: string;
  details?: Record<string, unknown>;
}

export interface PaginatedResponse<T> {
  items: T[];
  nextCursor?: string;
  total?: number;
}

/* ============================================================================
 * Health check contract (used by BE-01)
 * ========================================================================== */

export interface HealthStatusResponse {
  status: 'ok' | 'degraded' | 'down';
  timestamp: string;
  service: string;
  version: string;
}

export interface ReadinessResponse {
  status: 'ready' | 'not_ready';
  timestamp: string;
  checks: Record<string, 'ok' | 'failing' | 'unknown'>;
}

/* ============================================================================
 * Saved products (FE-16)
 * ========================================================================== */

export type {
  SavedProductDto,
  CreateSavedProductInput,
  ListSavedProductsResponse,
} from './saved-products';
