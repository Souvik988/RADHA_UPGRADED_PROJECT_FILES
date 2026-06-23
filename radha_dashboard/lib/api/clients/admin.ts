/**
 * lib/api/clients/admin.ts — Admin console endpoints (Doc 1 §6.16, §6.18)
 * Impersonation, feature flags (read-only), webhooks.
 */
import 'server-only';
import { z } from 'zod';
import { apiFetch } from '../core/api-fetch';
import { NotImplementedBackendError } from '../core/errors';
import { PaginatedSchema, cursorParams, type CursorParams } from '../core/pagination';

const WebhookSchema = z.object({
  id: z.string(),
  tenantId: z.string(),
  url: z.string(),
  events: z.array(z.string()),
  isActive: z.boolean(),
  secret: z.string().optional(),
  createdAt: z.string(),
});

const FeatureFlagSchema = z.object({
  key: z.string(),
  enabled: z.boolean(),
  description: z.string().optional(),
  tenantOverrides: z.record(z.boolean()).optional(),
});

/* ── Impersonation ────────────────────────────────────────────────────────── */
export async function startImpersonation(tenantId: string, reason: string) {
  return apiFetch('/admin/impersonate', {
    method: 'POST',
    body: { tenantId, reason },
    schema: z.object({ impersonationToken: z.string(), expiresAt: z.string() }),
  });
}

export async function stopImpersonation() {
  return apiFetch('/admin/impersonate/stop', {
    method: 'POST',
    schema: z.object({ ok: z.boolean() }),
  });
}

/* ── Feature flags ────────────────────────────────────────────────────────── */
export async function listFeatureFlags() {
  return apiFetch('/admin/feature-flags', {
    schema: z.object({ flags: z.array(FeatureFlagSchema) }),
  });
}

/* ── Webhooks ─────────────────────────────────────────────────────────────── */
export async function listWebhooks(tenantId: string, params?: CursorParams) {
  return apiFetch('/admin/webhooks', {
    schema: PaginatedSchema(WebhookSchema),
    query: { tenantId, ...cursorParams(params) },
  });
}

export async function createWebhook(data: { tenantId: string; url: string; events: string[] }) {
  return apiFetch('/admin/webhooks', { method: 'POST', body: data, schema: WebhookSchema });
}

export async function updateWebhook(id: string, data: Partial<{ url: string; events: string[]; isActive: boolean }>) {
  return apiFetch(`/admin/webhooks/${id}`, { method: 'PATCH', body: data, schema: WebhookSchema });
}

export async function deleteWebhook(id: string) {
  return apiFetch(`/admin/webhooks/${id}`, { method: 'DELETE', schema: z.object({}), noBody: true });
}

export async function listWebhookDeliveries(webhookId: string, params?: CursorParams) {
  return apiFetch(`/admin/webhooks/${webhookId}/deliveries`, {
    schema: PaginatedSchema(z.object({
      id: z.string(), event: z.string(), status: z.number(),
      attempt: z.number(), deliveredAt: z.string().optional(),
    })),
    query: cursorParams(params),
  });
}

export async function replayWebhookDelivery(webhookId: string, deliveryId: string) {
  return apiFetch(`/admin/webhooks/${webhookId}/deliveries/${deliveryId}/replay`, {
    method: 'POST',
    schema: z.object({ ok: z.boolean() }),
  });
}

/* ── 🆕 PROPOSED — Audit log viewer ──────────────────────────────────────── */
/** @proposed — Backend not yet implemented. */
export async function listAuditLog(_params: { tenantId?: string; limit?: number }): Promise<never> {
  throw new NotImplementedBackendError('GET /admin/audit-log');
}
