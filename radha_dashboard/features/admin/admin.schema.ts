/**
 * features/admin/admin.schema.ts
 * Zod schemas for the Admin Console feature (Phase 16).
 * Covers: impersonation, feature flags, webhooks.
 */
import { z } from 'zod';

/* ── Impersonation ───────────────────────────────────────────────────────── */
export const StartImpersonationSchema = z.object({
  targetUserId: z.string().min(1, 'Target user ID is required'),
  reason: z.string().min(10, 'Please provide a reason (min 10 characters)'),
});
export type StartImpersonationPayload = z.infer<typeof StartImpersonationSchema>;

export const ImpersonationSessionSchema = z.object({
  impersonationToken: z.string(),
  expiresAt: z.string(),
  targetUserId: z.string().optional(),
  targetName: z.string().optional(),
});
export type ImpersonationSession = z.infer<typeof ImpersonationSessionSchema>;

export const ImpersonationAuditRecordSchema = z.object({
  id: z.string().uuid(),
  actorId: z.string(),
  actorName: z.string().optional(),
  targetId: z.string(),
  targetName: z.string().optional(),
  reason: z.string(),
  startedAt: z.string(),
  endedAt: z.string().nullable().optional(),
  durationMs: z.number().nullable().optional(),
});
export type ImpersonationAuditRecord = z.infer<typeof ImpersonationAuditRecordSchema>;

export const ImpersonationAuditListSchema = z.object({
  items: z.array(ImpersonationAuditRecordSchema),
  nextCursor: z.string().nullable().optional(),
});

/* ── Feature flags ───────────────────────────────────────────────────────── */
export const FeatureFlagSchema = z.object({
  key: z.string(),
  enabled: z.boolean(),
  description: z.string().optional(),
  tenantOverrides: z.record(z.boolean()).optional(),
});
export type FeatureFlag = z.infer<typeof FeatureFlagSchema>;

export const FeatureFlagListSchema = z.object({
  flags: z.array(FeatureFlagSchema),
});

/* ── Webhooks ────────────────────────────────────────────────────────────── */
export const WebhookEventOptions = [
  'expiry.created',
  'expiry.alert',
  'task.created',
  'task.completed',
  'grn.received',
  'stock.low',
  'subscription.updated',
  'health_score.calculated',
  'scan.completed',
] as const;
export type WebhookEvent = (typeof WebhookEventOptions)[number];

export const WebhookSchema = z.object({
  id: z.string().uuid(),
  tenantId: z.string(),
  url: z.string().url(),
  events: z.array(z.string()),
  isActive: z.boolean(),
  secret: z.string().optional(),
  createdAt: z.string(),
});
export type Webhook = z.infer<typeof WebhookSchema>;

export const WebhookListSchema = z.object({
  items: z.array(WebhookSchema),
  total: z.number().optional(),
  nextCursor: z.string().nullable().optional(),
});

export const CreateWebhookSchema = z.object({
  tenantId: z.string().min(1, 'Tenant ID is required'),
  url: z.string().url('Must be a valid URL (https://…)'),
  events: z.array(z.string()).min(1, 'Select at least one event'),
});
export type CreateWebhookPayload = z.infer<typeof CreateWebhookSchema>;

export const UpdateWebhookSchema = z.object({
  url: z.string().url().optional(),
  events: z.array(z.string()).optional(),
  isActive: z.boolean().optional(),
});
export type UpdateWebhookPayload = z.infer<typeof UpdateWebhookSchema>;

/* ── Webhook deliveries ──────────────────────────────────────────────────── */
export const WebhookDeliverySchema = z.object({
  id: z.string().uuid(),
  event: z.string(),
  status: z.number(),
  attempt: z.number(),
  deliveredAt: z.string().optional(),
});
export type WebhookDelivery = z.infer<typeof WebhookDeliverySchema>;

export const WebhookDeliveryListSchema = z.object({
  items: z.array(WebhookDeliverySchema),
  nextCursor: z.string().nullable().optional(),
});
