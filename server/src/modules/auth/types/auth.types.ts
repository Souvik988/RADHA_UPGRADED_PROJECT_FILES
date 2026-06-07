import type { UserRole } from '@radha/shared-types';

export type SessionRevokeReason = 'logout' | 'logout_all' | 'token_theft' | 'admin' | 'expired';

export interface AccessTokenPayload {
  sub: string;
  tenantId: string | null;
  role: UserRole;
  sessionId: string;
  iat?: number;
  exp?: number;
  iss?: string;
  aud?: string;
}

export interface RefreshTokenPayload {
  sub: string;
  sessionId: string;
  jti: string;
  iat?: number;
  exp?: number;
}

export interface SessionMetadata {
  ipAddress: string;
  userAgent: string;
  deviceId?: string;
  platform?: 'mobile' | 'web' | 'admin';
}

export interface OtpRequestResult {
  requestId: string;
  expiresIn: number;
  attemptsRemaining: number;
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface UserMeResponse {
  id: string;
  mobile: string;
  name: string;
  role: UserRole;
  tenantId: string | null;
  storeIds: string[];
  permissions: string[];
  isVerified: boolean;
  bypassOnboarding: boolean;
  createdAt: Date;
}

export interface AuthResult extends TokenPair {
  user: UserMeResponse;
}
