export type Brand<T, B extends string> = T & {
    readonly __brand: B;
};
export type UserId = Brand<string, 'UserId'>;
export type TenantId = Brand<string, 'TenantId'>;
export type StoreId = Brand<string, 'StoreId'>;
export type ProductId = Brand<string, 'ProductId'>;
export type UserRole = 'owner' | 'manager' | 'staff' | 'auditor' | 'consumer' | 'admin';
export type SubscriptionTier = 'free_consumer' | 'premium_consumer' | 'trial_pro' | 'starter' | 'growth' | 'pro';
export type ScanOutputMode = 'basic' | 'comprehensive';
export type OnboardingSegment = 'personal' | 'business_owner' | 'parent' | 'pharmacy' | 'institution' | 'auditor_invited';
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
