# Phase BE-06: OTP Authentication & SMS Integration

## Phase Metadata

- **Phase ID**: BE-06
- **Phase Name**: OTP Authentication & SMS Integration
- **Section**: Backend Execution — Security & Identity Layer
- **Depends On**: BE-01, BE-02, BE-03, BE-04, BE-05, DB-03 (users, otp_attempts, sessions tables)
- **Blocks**: BE-07, BE-08, BE-09, ALL feature phases requiring auth
- **Estimated Duration**: 3 days
- **Complexity**: High
- **Priority**: CRITICAL

## Goal

Implement production-grade OTP-based authentication: MSG91 SMS integration, secure OTP generation/storage, rate limiting, abuse protection, JWT issuance, refresh token rotation, session management, and account lockout policies.

## Why This Phase Matters

This is the **front door** of the application. Without proper OTP authentication:
- Anyone can impersonate users
- SMS bombing attacks succeed (cost money + block legitimate users)
- Brute force attacks succeed
- Sessions are insecure
- Token theft is unrecoverable
- No audit trail of authentication events

Production OTP auth must handle:
- ⏱️ Rate limiting (per mobile, per IP, per device)
- 🔒 Cryptographic OTP storage (hashed, never plain)
- 🚨 Brute force protection (account lockout)
- 💸 SMS cost protection (delivery failures, retries)
- 🔄 Token refresh without re-OTP
- 📜 Comprehensive audit trail

## Prerequisites

- [ ] BE-01 to BE-05 completed
- [ ] DB tables exist: `users`, `user_sessions`, `otp_attempts` (DB-03)
- [ ] MSG91 account created (or mock provider for dev)
- [ ] `MSG91_API_KEY`, `MSG91_TEMPLATE_ID` configured
- [ ] Redis running for rate limiting

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/users.ts` | Users table schema |
| `server/src/db/schema/user_sessions.ts` | Sessions table schema |
| `server/src/db/schema/otp_attempts.ts` | OTP attempts table schema |
| `server/src/modules/auth/auth.module.ts` | Auth module |
| `server/src/modules/auth/auth.controller.ts` | Auth endpoints |
| `server/src/modules/auth/auth.service.ts` | Auth business logic |
| `server/src/modules/auth/services/otp.service.ts` | OTP generation/validation |
| `server/src/modules/auth/services/jwt.service.ts` | JWT issuance/validation |
| `server/src/modules/auth/services/session.service.ts` | Session management |
| `server/src/modules/auth/services/rate-limiter.service.ts` | Auth-specific rate limits |
| `server/src/modules/auth/repositories/users.repository.ts` | Users data access |
| `server/src/modules/auth/repositories/sessions.repository.ts` | Sessions data access |
| `server/src/modules/auth/repositories/otp-attempts.repository.ts` | OTP attempts data access |
| `server/src/modules/auth/dto/request-otp.dto.ts` | Request OTP DTO + Zod |
| `server/src/modules/auth/dto/verify-otp.dto.ts` | Verify OTP DTO + Zod |
| `server/src/modules/auth/dto/refresh-token.dto.ts` | Refresh token DTO + Zod |
| `server/src/modules/auth/dto/me.response.dto.ts` | /me response DTO |
| `server/src/modules/auth/types/auth.types.ts` | Auth type definitions |
| `server/src/modules/auth/utils/otp.utils.ts` | OTP generation/hashing |
| `server/src/modules/auth/utils/mobile.utils.ts` | Mobile number normalization |
| `server/src/integrations/sms/sms.module.ts` | SMS module |
| `server/src/integrations/sms/sms.service.ts` | SMS service abstraction |
| `server/src/integrations/sms/providers/msg91.provider.ts` | MSG91 implementation |
| `server/src/integrations/sms/providers/mock.provider.ts` | Mock provider for dev |
| `server/src/integrations/sms/types/sms.types.ts` | SMS types |
| All `__tests__/` files for above |

## Files to Modify

| File Path | Required Change |
|---|---|
| `server/src/app.module.ts` | Import AuthModule, SmsModule |
| `server/src/db/schema/index.ts` | Export users, sessions, otp_attempts |
| `API_CONTRACTS.md` | Document auth endpoints |
| `BACKEND_ARCHITECTURE.md` | Document auth flow |

## Service Interfaces

```typescript
// server/src/modules/auth/types/auth.types.ts

export interface IAuthService {
  // OTP Flow
  requestOtp(dto: RequestOtpDto, ipAddress: string): Promise<OtpRequestResult>;
  verifyOtp(dto: VerifyOtpDto, ipAddress: string, userAgent: string): Promise<AuthResult>;
  
  // Session Management
  refreshTokens(dto: RefreshTokenDto): Promise<TokenPair>;
  logout(sessionId: string): Promise<void>;
  logoutAll(userId: string): Promise<void>;
  
  // Current User
  getCurrentUser(userId: string): Promise<UserMeResponse>;
}

export interface IOtpService {
  generate(): { otp: string; hash: string };
  verify(plainOtp: string, hashedOtp: string): Promise<boolean>;
  isExpired(createdAt: Date, expirySeconds: number): boolean;
}

export interface IJwtService {
  issueAccessToken(payload: AccessTokenPayload): Promise<string>;
  issueRefreshToken(payload: RefreshTokenPayload): Promise<string>;
  verifyAccessToken(token: string): Promise<AccessTokenPayload>;
  verifyRefreshToken(token: string): Promise<RefreshTokenPayload>;
  decodeToken(token: string): unknown;
}

export interface ISessionService {
  create(userId: string, refreshTokenHash: string, metadata: SessionMetadata): Promise<UserSession>;
  findById(sessionId: string): Promise<UserSession | null>;
  findByRefreshTokenHash(hash: string): Promise<UserSession | null>;
  rotateRefreshToken(sessionId: string, newHash: string): Promise<void>;
  revoke(sessionId: string, reason: SessionRevokeReason): Promise<void>;
  revokeAllForUser(userId: string, reason: SessionRevokeReason): Promise<number>;
  cleanup(olderThanDays: number): Promise<number>;
}

export interface ISmsService {
  sendOtp(mobile: string, otp: string): Promise<SmsResult>;
  sendNotification(mobile: string, message: string, templateId?: string): Promise<SmsResult>;
}

export interface OtpRequestResult {
  requestId: string;
  expiresIn: number;
  attemptsRemaining: number;
}

export interface AuthResult {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: UserMeResponse;
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface AccessTokenPayload {
  sub: string; // user id
  tenantId: string;
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
  jti: string; // JWT ID for revocation
  iat?: number;
  exp?: number;
}

export interface SessionMetadata {
  ipAddress: string;
  userAgent: string;
  deviceId?: string;
  platform?: 'mobile' | 'web' | 'admin';
}

export interface SmsResult {
  success: boolean;
  messageId?: string;
  provider: string;
  cost?: number;
  error?: string;
}

export type UserRole = 'owner' | 'manager' | 'staff' | 'auditor' | 'admin';
export type SessionRevokeReason = 'logout' | 'logout_all' | 'token_theft' | 'admin' | 'expired';

export interface UserMeResponse {
  id: string;
  mobile: string;
  name: string;
  role: UserRole;
  tenantId: string;
  storeIds: string[];
  permissions: string[];
  isVerified: boolean;
  createdAt: Date;
}
```

## Implementation Code

### 1. Database Schemas

```typescript
// server/src/db/schema/users.ts
import { pgTable, varchar, uuid, boolean, timestamp, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns, softDeleteColumn, auditColumns, tenantScopeColumn } from './_base';

export const userRoleEnum = pgEnum('user_role', ['owner', 'manager', 'staff', 'auditor', 'admin']);

export const users = pgTable(
  'users',
  {
    ...baseColumns,
    ...softDeleteColumn,
    ...auditColumns,
    tenantId: uuid('tenant_id').notNull(),
    mobile: varchar('mobile', { length: 20 }).notNull(),
    email: varchar('email', { length: 255 }),
    name: varchar('name', { length: 100 }).notNull(),
    role: userRoleEnum('role').notNull().default('staff'),
    isVerified: boolean('is_verified').notNull().default(false),
    isActive: boolean('is_active').notNull().default(true),
    lastLoginAt: timestamp('last_login_at', { withTimezone: true }),
    failedLoginAttempts: varchar('failed_login_attempts', { length: 10 }).default('0'),
    lockedUntil: timestamp('locked_until', { withTimezone: true }),
  },
  (table) => ({
    mobileIdx: index('idx_users_mobile').on(table.mobile),
    tenantRoleIdx: index('idx_users_tenant_role').on(table.tenantId, table.role),
    uniqueMobileTenant: index('uniq_users_mobile_tenant').on(table.mobile, table.tenantId),
  }),
);

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
```

```typescript
// server/src/db/schema/user_sessions.ts
import { pgTable, varchar, uuid, timestamp, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';
import { users } from './users';

export const userSessions = pgTable(
  'user_sessions',
  {
    ...baseColumns,
    userId: uuid('user_id').notNull().references(() => users.id),
    refreshTokenHash: varchar('refresh_token_hash', { length: 255 }).notNull(),
    ipAddress: varchar('ip_address', { length: 45 }),
    userAgent: varchar('user_agent', { length: 500 }),
    deviceId: varchar('device_id', { length: 255 }),
    platform: varchar('platform', { length: 20 }),
    isActive: varchar('is_active', { length: 5 }).notNull().default('true'),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    lastUsedAt: timestamp('last_used_at', { withTimezone: true }),
    revokedAt: timestamp('revoked_at', { withTimezone: true }),
    revokedReason: varchar('revoked_reason', { length: 50 }),
  },
  (table) => ({
    userActiveIdx: index('idx_sessions_user_active').on(table.userId, table.isActive),
    refreshHashIdx: index('idx_sessions_refresh_hash').on(table.refreshTokenHash),
    expiresIdx: index('idx_sessions_expires').on(table.expiresAt),
  }),
);

export type UserSession = typeof userSessions.$inferSelect;
export type NewUserSession = typeof userSessions.$inferInsert;
```

```typescript
// server/src/db/schema/otp_attempts.ts
import { pgTable, varchar, uuid, timestamp, integer, boolean, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const otpAttempts = pgTable(
  'otp_attempts',
  {
    ...baseColumns,
    requestId: uuid('request_id').notNull().unique(),
    mobile: varchar('mobile', { length: 20 }).notNull(),
    otpHash: varchar('otp_hash', { length: 255 }).notNull(),
    attemptCount: integer('attempt_count').notNull().default(0),
    maxAttempts: integer('max_attempts').notNull().default(3),
    isVerified: boolean('is_verified').notNull().default(false),
    isExpired: boolean('is_expired').notNull().default(false),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    verifiedAt: timestamp('verified_at', { withTimezone: true }),
    ipAddress: varchar('ip_address', { length: 45 }),
  },
  (table) => ({
    mobileCreatedIdx: index('idx_otp_mobile_created').on(table.mobile, table.createdAt),
    requestIdIdx: index('idx_otp_request_id').on(table.requestId),
    expiresIdx: index('idx_otp_expires').on(table.expiresAt),
  }),
);

export type OtpAttempt = typeof otpAttempts.$inferSelect;
export type NewOtpAttempt = typeof otpAttempts.$inferInsert;
```

### 2. DTOs with Zod Validation

```typescript
// server/src/modules/auth/dto/request-otp.dto.ts
import { z } from 'zod';

export const RequestOtpSchema = z.object({
  mobile: z.string()
    .regex(/^[6-9]\d{9}$/, 'Invalid Indian mobile number'),
  deviceId: z.string().min(1).max(255).optional(),
  platform: z.enum(['mobile', 'web', 'admin']).default('mobile'),
});

export type RequestOtpDto = z.infer<typeof RequestOtpSchema>;
```

```typescript
// server/src/modules/auth/dto/verify-otp.dto.ts
import { z } from 'zod';

export const VerifyOtpSchema = z.object({
  mobile: z.string().regex(/^[6-9]\d{9}$/, 'Invalid mobile number'),
  otp: z.string()
    .length(6, 'OTP must be 6 digits')
    .regex(/^\d{6}$/, 'OTP must be numeric'),
  requestId: z.string().uuid('Invalid request ID'),
  deviceId: z.string().min(1).max(255).optional(),
});

export type VerifyOtpDto = z.infer<typeof VerifyOtpSchema>;
```

```typescript
// server/src/modules/auth/dto/refresh-token.dto.ts
import { z } from 'zod';

export const RefreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token required'),
});

export type RefreshTokenDto = z.infer<typeof RefreshTokenSchema>;
```

### 3. OTP Utilities

```typescript
// server/src/modules/auth/utils/otp.utils.ts
import { randomInt } from 'crypto';
import * as bcrypt from 'bcrypt';

const BCRYPT_ROUNDS = 10;

export function generateOtp(length: number = 6): string {
  if (length < 4 || length > 8) {
    throw new Error('OTP length must be between 4 and 8');
  }
  
  const min = Math.pow(10, length - 1);
  const max = Math.pow(10, length) - 1;
  return String(randomInt(min, max + 1));
}

export async function hashOtp(otp: string): Promise<string> {
  return bcrypt.hash(otp, BCRYPT_ROUNDS);
}

export async function verifyOtp(plainOtp: string, hashedOtp: string): Promise<boolean> {
  try {
    return await bcrypt.compare(plainOtp, hashedOtp);
  } catch {
    return false;
  }
}

export function normalizeMobile(mobile: string): string {
  // Remove +91, spaces, hyphens
  const digits = mobile.replace(/\D/g, '');
  if (digits.length === 12 && digits.startsWith('91')) {
    return digits.substring(2);
  }
  if (digits.length === 10) {
    return digits;
  }
  throw new Error('Invalid mobile number format');
}
```

### 4. SMS Service (with MSG91)

```typescript
// server/src/integrations/sms/sms.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '../../config/config.service';
import { ISmsService, SmsResult } from './types/sms.types';
import { Msg91Provider } from './providers/msg91.provider';
import { MockSmsProvider } from './providers/mock.provider';
import { ExternalServiceException } from '../../common/errors/business.exception';

@Injectable()
export class SmsService implements ISmsService {
  private readonly logger = new Logger(SmsService.name);
  private provider: ISmsService;

  constructor(
    private readonly config: ConfigService,
    private readonly msg91: Msg91Provider,
    private readonly mock: MockSmsProvider,
  ) {
    const providerName = this.config.sms.provider;
    this.provider = providerName === 'mock' ? this.mock : this.msg91;
    this.logger.log(`SMS provider initialized: ${providerName}`);
  }

  async sendOtp(mobile: string, otp: string): Promise<SmsResult> {
    const maxRetries = 2;
    let lastError: Error | null = null;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        const result = await this.provider.sendOtp(mobile, otp);
        if (result.success) {
          this.logger.log(`OTP sent successfully to mobile (attempt ${attempt + 1})`);
          return result;
        }
        lastError = new Error(result.error);
      } catch (error) {
        lastError = error as Error;
        this.logger.warn(`SMS send attempt ${attempt + 1} failed`, {
          error: lastError.message,
        });
      }

      if (attempt < maxRetries) {
        await this.sleep(2000 * (attempt + 1)); // 2s, 4s backoff
      }
    }

    this.logger.error('All SMS send attempts failed', { error: lastError?.message });
    throw new ExternalServiceException('SMS', lastError || undefined);
  }

  async sendNotification(mobile: string, message: string, templateId?: string): Promise<SmsResult> {
    return this.provider.sendNotification(mobile, message, templateId);
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
```

### 5. MSG91 Provider

```typescript
// server/src/integrations/sms/providers/msg91.provider.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '../../../config/config.service';
import { ISmsService, SmsResult } from '../types/sms.types';

@Injectable()
export class Msg91Provider implements ISmsService {
  private readonly logger = new Logger(Msg91Provider.name);
  private readonly apiUrl = 'https://control.msg91.com/api/v5/otp';

  constructor(private readonly config: ConfigService) {}

  async sendOtp(mobile: string, otp: string): Promise<SmsResult> {
    const { apiKey, senderId, templateId } = this.config.sms;
    const fullMobile = `91${mobile.replace(/\D/g, '').slice(-10)}`;

    try {
      const response = await fetch(this.apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'authkey': apiKey,
        },
        body: JSON.stringify({
          template_id: templateId,
          mobile: fullMobile,
          otp: otp,
          sender: senderId,
        }),
      });

      const data = await response.json() as { type: string; message?: string; request_id?: string };

      if (data.type === 'success') {
        return {
          success: true,
          messageId: data.request_id,
          provider: 'msg91',
        };
      }

      return {
        success: false,
        provider: 'msg91',
        error: data.message || 'Unknown MSG91 error',
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Network error';
      this.logger.error('MSG91 API call failed', { error: message });
      return {
        success: false,
        provider: 'msg91',
        error: message,
      };
    }
  }

  async sendNotification(mobile: string, message: string): Promise<SmsResult> {
    // Use MSG91 sendsms endpoint for non-OTP messages
    // Implementation similar to sendOtp but different endpoint
    throw new Error('Not implemented yet — extend in BE-24');
  }
}
```

### 6. Mock SMS Provider

```typescript
// server/src/integrations/sms/providers/mock.provider.ts
import { Injectable, Logger } from '@nestjs/common';
import { ISmsService, SmsResult } from '../types/sms.types';

@Injectable()
export class MockSmsProvider implements ISmsService {
  private readonly logger = new Logger(MockSmsProvider.name);
  private readonly sentMessages: Array<{ mobile: string; message: string; timestamp: Date }> = [];

  async sendOtp(mobile: string, otp: string): Promise<SmsResult> {
    this.logger.warn(`📱 [MOCK SMS] OTP for ${mobile}: ${otp}`);
    
    this.sentMessages.push({
      mobile,
      message: `OTP: ${otp}`,
      timestamp: new Date(),
    });

    return {
      success: true,
      messageId: `mock-${Date.now()}`,
      provider: 'mock',
    };
  }

  async sendNotification(mobile: string, message: string): Promise<SmsResult> {
    this.logger.warn(`📱 [MOCK SMS] To ${mobile}: ${message}`);
    return {
      success: true,
      messageId: `mock-${Date.now()}`,
      provider: 'mock',
    };
  }

  // For testing only — get sent messages
  getSentMessages(): typeof this.sentMessages {
    return [...this.sentMessages];
  }

  clearSentMessages(): void {
    this.sentMessages.length = 0;
  }
}
```

### 7. Auth Service (Main Logic)

```typescript
// server/src/modules/auth/auth.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '../../config/config.service';
import { DbService } from '../../db/db.service';
import { LoggerService } from '../../logging/logger.service';
import { AuditLogService } from '../../observability/audit-log.service';
import { SmsService } from '../../integrations/sms/sms.service';
import { OtpService } from './services/otp.service';
import { JwtService } from './services/jwt.service';
import { SessionService } from './services/session.service';
import { RateLimiterService } from './services/rate-limiter.service';
import { UsersRepository } from './repositories/users.repository';
import { OtpAttemptsRepository } from './repositories/otp-attempts.repository';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import {
  IAuthService,
  OtpRequestResult,
  AuthResult,
  TokenPair,
  UserMeResponse,
} from './types/auth.types';
import { generateOtp, hashOtp, normalizeMobile } from './utils/otp.utils';
import {
  BusinessException,
  NotFoundException,
} from '../../common/errors/business.exception';
import { ErrorCode } from '../../common/errors/error-codes';
import { v4 as uuidv4 } from 'uuid';
import * as crypto from 'crypto';

@Injectable()
export class AuthService implements IAuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly db: DbService,
    private readonly appLogger: LoggerService,
    private readonly auditLog: AuditLogService,
    private readonly smsService: SmsService,
    private readonly otpService: OtpService,
    private readonly jwtService: JwtService,
    private readonly sessionService: SessionService,
    private readonly rateLimiter: RateLimiterService,
    private readonly usersRepo: UsersRepository,
    private readonly otpAttemptsRepo: OtpAttemptsRepository,
  ) {}

  async requestOtp(dto: RequestOtpDto, ipAddress: string): Promise<OtpRequestResult> {
    const mobile = normalizeMobile(dto.mobile);

    // Rate limit: per mobile (3/hour), per IP (10/hour)
    await this.rateLimiter.checkOtpRequest(mobile, ipAddress);

    // Generate OTP
    const otpLength = this.config.sms.otpLength;
    const otp = generateOtp(otpLength);
    const otpHash = await hashOtp(otp);
    const requestId = uuidv4();
    const expiresAt = new Date(Date.now() + this.config.sms.otpExpirySeconds * 1000);

    // Store OTP attempt
    await this.otpAttemptsRepo.create({
      requestId,
      mobile,
      otpHash,
      attemptCount: 0,
      maxAttempts: 3,
      isVerified: false,
      isExpired: false,
      expiresAt,
      ipAddress,
    });

    // Send via SMS
    try {
      await this.smsService.sendOtp(mobile, otp);
    } catch (error) {
      // Mark attempt as failed but don't expose to client
      this.appLogger.error('OTP delivery failed', {
        mobile: '[REDACTED]',
        requestId,
        error: error instanceof Error ? error.message : 'Unknown',
      });
      throw new BusinessException(
        ErrorCode.SMS_DELIVERY_FAILED,
        'Unable to send OTP. Please try again.',
      );
    }

    // Audit log
    await this.auditLog.logAction({
      action: 'CREATE',
      resourceType: 'OtpAttempt',
      resourceId: requestId,
      userId: 'anonymous',
      tenantId: 'system',
      ipAddress,
      success: true,
      metadata: { mobile: '[REDACTED]' },
    });

    return {
      requestId,
      expiresIn: this.config.sms.otpExpirySeconds,
      attemptsRemaining: 3,
    };
  }

  async verifyOtp(dto: VerifyOtpDto, ipAddress: string, userAgent: string): Promise<AuthResult> {
    const mobile = normalizeMobile(dto.mobile);

    // Find OTP attempt
    const attempt = await this.otpAttemptsRepo.findByRequestId(dto.requestId);
    if (!attempt) {
      throw new BusinessException(ErrorCode.OTP_INVALID, 'Invalid OTP request');
    }

    // Check expiration
    if (attempt.expiresAt < new Date() || attempt.isExpired) {
      await this.otpAttemptsRepo.markExpired(attempt.id);
      throw new BusinessException(ErrorCode.OTP_EXPIRED, 'OTP has expired');
    }

    // Check already verified
    if (attempt.isVerified) {
      throw new BusinessException(ErrorCode.OTP_INVALID, 'OTP already used');
    }

    // Check max attempts
    if (attempt.attemptCount >= attempt.maxAttempts) {
      throw new BusinessException(
        ErrorCode.OTP_TOO_MANY_ATTEMPTS,
        'Too many invalid attempts. Please request a new OTP.',
      );
    }

    // Check mobile matches
    if (attempt.mobile !== mobile) {
      throw new BusinessException(ErrorCode.OTP_INVALID, 'Invalid OTP request');
    }

    // Verify OTP
    const isValid = await this.otpService.verify(dto.otp, attempt.otpHash);
    
    if (!isValid) {
      await this.otpAttemptsRepo.incrementAttempt(attempt.id);
      const remaining = attempt.maxAttempts - (attempt.attemptCount + 1);
      throw new BusinessException(
        ErrorCode.OTP_INVALID,
        `Invalid OTP. ${remaining} attempts remaining.`,
      );
    }

    // Mark as verified
    await this.otpAttemptsRepo.markVerified(attempt.id);

    // Find or create user
    let user = await this.usersRepo.findByMobile(mobile);
    if (!user) {
      // First-time user — create with default tenant/role
      // In production, this would require tenant invitation
      user = await this.createNewUser(mobile);
    }

    // Check if user is active and not locked
    if (!user.isActive) {
      throw new BusinessException(ErrorCode.ACCOUNT_LOCKED, 'Account is deactivated');
    }
    if (user.lockedUntil && user.lockedUntil > new Date()) {
      throw new BusinessException(ErrorCode.ACCOUNT_LOCKED, 'Account is temporarily locked');
    }

    // Update last login
    await this.usersRepo.update(user.id, {
      lastLoginAt: new Date(),
      isVerified: true,
      failedLoginAttempts: '0',
    });

    // Issue tokens
    const sessionId = uuidv4();
    const accessToken = await this.jwtService.issueAccessToken({
      sub: user.id,
      tenantId: user.tenantId,
      role: user.role,
      sessionId,
    });
    const refreshToken = await this.jwtService.issueRefreshToken({
      sub: user.id,
      sessionId,
      jti: uuidv4(),
    });

    // Create session
    const refreshTokenHash = this.hashToken(refreshToken);
    await this.sessionService.create(user.id, refreshTokenHash, {
      ipAddress,
      userAgent,
      deviceId: dto.deviceId,
      platform: 'mobile',
    });

    // Audit
    await this.auditLog.logAction({
      action: 'LOGIN',
      resourceType: 'User',
      resourceId: user.id,
      userId: user.id,
      tenantId: user.tenantId,
      ipAddress,
      userAgent,
      success: true,
    });

    return {
      accessToken,
      refreshToken,
      expiresIn: this.config.jwt.accessTokenExpirySeconds,
      user: await this.getCurrentUser(user.id),
    };
  }

  async refreshTokens(dto: RefreshTokenDto): Promise<TokenPair> {
    let payload;
    try {
      payload = await this.jwtService.verifyRefreshToken(dto.refreshToken);
    } catch (error) {
      throw new BusinessException(ErrorCode.TOKEN_INVALID, 'Invalid refresh token');
    }

    const session = await this.sessionService.findById(payload.sessionId);
    if (!session) {
      throw new BusinessException(ErrorCode.TOKEN_REVOKED, 'Session not found');
    }

    // Verify refresh token hash matches (token rotation security)
    const tokenHash = this.hashToken(dto.refreshToken);
    if (session.refreshTokenHash !== tokenHash) {
      // Possible token theft — revoke all sessions for this user
      this.appLogger.warn('Refresh token mismatch — possible token theft', {
        userId: payload.sub,
        sessionId: payload.sessionId,
      });
      await this.sessionService.revokeAllForUser(payload.sub, 'token_theft');
      throw new BusinessException(ErrorCode.TOKEN_REVOKED, 'Token has been revoked');
    }

    // Check expiration
    if (session.expiresAt < new Date()) {
      throw new BusinessException(ErrorCode.TOKEN_EXPIRED, 'Refresh token expired');
    }

    // Issue new tokens
    const user = await this.usersRepo.findById(payload.sub);
    if (!user) {
      throw new NotFoundException('User', payload.sub);
    }

    const newAccessToken = await this.jwtService.issueAccessToken({
      sub: user.id,
      tenantId: user.tenantId,
      role: user.role,
      sessionId: session.id,
    });
    const newRefreshToken = await this.jwtService.issueRefreshToken({
      sub: user.id,
      sessionId: session.id,
      jti: uuidv4(),
    });

    // Rotate refresh token (old one no longer valid)
    const newHash = this.hashToken(newRefreshToken);
    await this.sessionService.rotateRefreshToken(session.id, newHash);

    return {
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiresIn: this.config.jwt.accessTokenExpirySeconds,
    };
  }

  async logout(sessionId: string): Promise<void> {
    await this.sessionService.revoke(sessionId, 'logout');
  }

  async logoutAll(userId: string): Promise<void> {
    await this.sessionService.revokeAllForUser(userId, 'logout_all');
  }

  async getCurrentUser(userId: string): Promise<UserMeResponse> {
    const user = await this.usersRepo.findById(userId);
    if (!user) {
      throw new NotFoundException('User', userId);
    }

    return {
      id: user.id,
      mobile: user.mobile,
      name: user.name,
      role: user.role,
      tenantId: user.tenantId,
      storeIds: [], // Will be populated in BE-09
      permissions: [], // Will be populated in BE-08
      isVerified: user.isVerified,
      createdAt: user.createdAt,
    };
  }

  private async createNewUser(mobile: string): Promise<User> {
    // For initial registration, create with placeholder tenant
    // In production, tenant would be set during invitation flow
    return this.usersRepo.create({
      mobile,
      name: `User-${mobile.slice(-4)}`,
      role: 'staff',
      tenantId: this.config.get('DEFAULT_TENANT_ID') || uuidv4(),
      isVerified: true,
      isActive: true,
    });
  }

  private hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }
}
```

### 8. Auth Controller

```typescript
// server/src/modules/auth/auth.controller.ts
import {
  Controller,
  Post,
  Get,
  Body,
  UsePipes,
  Headers,
  Ip,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { ZodValidationPipe } from '../../common/pipes/zod-validation.pipe';
import { RequestOtpSchema, RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpSchema, VerifyOtpDto } from './dto/verify-otp.dto';
import { RefreshTokenSchema, RefreshTokenDto } from './dto/refresh-token.dto';
import { CurrentUser } from './decorators/current-user.decorator';
import { Public } from './decorators/public.decorator';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('otp/request')
  @HttpCode(HttpStatus.OK)
  @UsePipes(new ZodValidationPipe(RequestOtpSchema))
  async requestOtp(
    @Body() dto: RequestOtpDto,
    @Ip() ipAddress: string,
  ) {
    return this.authService.requestOtp(dto, ipAddress);
  }

  @Public()
  @Post('otp/verify')
  @HttpCode(HttpStatus.OK)
  @UsePipes(new ZodValidationPipe(VerifyOtpSchema))
  async verifyOtp(
    @Body() dto: VerifyOtpDto,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.authService.verifyOtp(dto, ipAddress, userAgent || 'unknown');
  }

  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @UsePipes(new ZodValidationPipe(RefreshTokenSchema))
  async refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refreshTokens(dto);
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@CurrentUser('sessionId') sessionId: string) {
    await this.authService.logout(sessionId);
  }

  @Post('logout-all')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logoutAll(@CurrentUser('userId') userId: string) {
    await this.authService.logoutAll(userId);
  }

  @Get('me')
  async me(@CurrentUser('userId') userId: string) {
    return this.authService.getCurrentUser(userId);
  }
}
```

## Database Tables Affected

| Table | Operation | Purpose |
|---|---|---|
| `users` | CREATE | New user registration |
| `users` | UPDATE | Update last_login_at, failed_attempts |
| `user_sessions` | CREATE | New session on OTP verify |
| `user_sessions` | UPDATE | Refresh token rotation, revoke |
| `otp_attempts` | CREATE | Each OTP request |
| `otp_attempts` | UPDATE | Increment attempts, mark verified/expired |
| `audit_logs` | CREATE | Login/logout events |

## API Endpoints

| Method | Endpoint | Auth | Rate Limit | Purpose |
|---|---|---|---|---|
| POST | `/api/v1/auth/otp/request` | Public | 3/hr/mobile, 10/hr/IP | Request OTP |
| POST | `/api/v1/auth/otp/verify` | Public | 5/hr/mobile | Verify OTP, get tokens |
| POST | `/api/v1/auth/refresh` | Public | 30/hr/IP | Refresh access token |
| POST | `/api/v1/auth/logout` | Bearer | 100/hr | End current session |
| POST | `/api/v1/auth/logout-all` | Bearer | 5/hr | End all sessions |
| GET | `/api/v1/auth/me` | Bearer | 60/min | Current user info |

## Security Considerations

### OTP Security
- ✅ OTPs hashed with bcrypt before storage (cost: 10)
- ✅ Cryptographically secure random generation (`crypto.randomInt`)
- ✅ Single-use (marked verified after success)
- ✅ Time-limited (10 min default)
- ✅ Rate limited (3 per mobile per hour)

### Token Security
- ✅ Access tokens: 30 min lifetime
- ✅ Refresh tokens: 30 day lifetime
- ✅ Refresh token rotation on every refresh
- ✅ Token theft detection (hash mismatch → revoke all sessions)
- ✅ JTI for refresh token revocation
- ✅ Secrets minimum 64 chars in production

### Account Security
- ✅ Account lockout after failed attempts
- ✅ IP-based rate limiting
- ✅ Mobile-based rate limiting
- ✅ Audit log for all auth events
- ✅ PII redacted in logs

## Performance Benchmarks

- **OTP request**: < 200ms (excluding SMS provider time)
- **OTP verify**: < 100ms (bcrypt is the bottleneck)
- **Token refresh**: < 50ms
- **Get current user**: < 30ms (cached after BE-31)

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-07 Until This Section is Complete

## 📋 Pre-Test Setup

```bash
# Use mock SMS provider for testing
SMS_PROVIDER=mock pnpm start:dev

# Have Redis running (for rate limiting)
docker run -d --name radha-redis -p 6379:6379 redis:7-alpine

# Apply migrations
pnpm db:migrate
```

## 🧪 Test Procedures

### Test 1: Request OTP — Happy Path ✅

```bash
curl -X POST http://localhost:3000/api/v1/auth/otp/request \
  -H "Content-Type: application/json" \
  -d '{"mobile":"9876543210"}'
```

**Expected Response (200)**:
```json
{
  "success": true,
  "data": {
    "requestId": "<uuid>",
    "expiresIn": 600,
    "attemptsRemaining": 3
  }
}
```

**Server Logs (mock SMS)**:
```
📱 [MOCK SMS] OTP for 9876543210: 123456
```

**Pass Criteria**: ✅ Returns requestId, mock OTP visible in logs

---

### Test 2: Invalid Mobile Format ✅

```bash
curl -X POST http://localhost:3000/api/v1/auth/otp/request \
  -H "Content-Type: application/json" \
  -d '{"mobile":"1234567890"}'
```

**Expected (400)**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "details": [{"field": "mobile", "message": "Invalid Indian mobile number"}]
  }
}
```

**Pass Criteria**: ✅ Validation rejects non-Indian mobile

---

### Test 3: Rate Limiting (3/hour per mobile) ✅

```bash
# Run 4 times quickly
for i in {1..4}; do
  curl -X POST http://localhost:3000/api/v1/auth/otp/request \
    -H "Content-Type: application/json" \
    -d '{"mobile":"9876543210"}'
  echo
done
```

**Expected**:
- Requests 1-3: Success
- Request 4: `429 Too Many Requests` with code `RATE_LIMIT_EXCEEDED`

**Pass Criteria**: ✅ 4th request blocked

---

### Test 4: Verify OTP — Happy Path ✅

Get OTP from server logs (mock provider), then:
```bash
curl -X POST http://localhost:3000/api/v1/auth/otp/verify \
  -H "Content-Type: application/json" \
  -d '{
    "mobile":"9876543210",
    "otp":"123456",
    "requestId":"<uuid-from-step-1>"
  }'
```

**Expected (200)**:
```json
{
  "success": true,
  "data": {
    "accessToken": "<jwt>",
    "refreshToken": "<jwt>",
    "expiresIn": 1800,
    "user": {
      "id": "<uuid>",
      "mobile": "9876543210",
      "role": "staff",
      ...
    }
  }
}
```

**Pass Criteria**: ✅ Returns tokens and user info

---

### Test 5: Verify OTP — Wrong OTP ✅

```bash
curl -X POST http://localhost:3000/api/v1/auth/otp/verify \
  -H "Content-Type: application/json" \
  -d '{
    "mobile":"9876543210",
    "otp":"000000",
    "requestId":"<valid-request-id>"
  }'
```

**Expected (401)**:
```json
{
  "error": {
    "code": "OTP_INVALID",
    "message": "Invalid OTP. 2 attempts remaining."
  }
}
```

**Pass Criteria**: ✅ Decrements attempts counter

---

### Test 6: Verify OTP — Max Attempts Reached ✅

After 3 wrong attempts, try again:
**Expected (429)**: `OTP_TOO_MANY_ATTEMPTS`
**Pass Criteria**: ✅ Locked out after 3 wrong attempts

---

### Test 7: Verify OTP — Expired ✅

Wait 10+ minutes, then try to verify:
**Expected (401)**: `OTP_EXPIRED`
**Pass Criteria**: ✅ OTP rejected after expiration

---

### Test 8: Refresh Token — Happy Path ✅

```bash
curl -X POST http://localhost:3000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken":"<refresh-token-from-login>"}'
```

**Expected (200)**: New access + refresh tokens
**Pass Criteria**: ✅ Token rotation works

---

### Test 9: Refresh Token — Token Theft Detection ✅

Use the SAME old refresh token twice:
1. First refresh: succeeds
2. Second refresh with old token: should fail AND revoke all sessions

**Expected (401)**: `TOKEN_REVOKED`
**Verification**: Try `/me` with old access token → should fail
**Pass Criteria**: ✅ Token theft detection works

---

### Test 10: Get Current User ✅

```bash
curl http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer <access-token>"
```

**Expected (200)**: User profile
**Pass Criteria**: ✅ Returns authenticated user

---

### Test 11: Logout ✅

```bash
curl -X POST http://localhost:3000/api/v1/auth/logout \
  -H "Authorization: Bearer <access-token>"
```

**Expected (204)**: No content
**Verification**: Subsequent requests with that token fail
**Pass Criteria**: ✅ Session revoked

---

### Test 12: OTP Hash Storage ✅

```sql
SELECT mobile, otp_hash, length(otp_hash) FROM otp_attempts LIMIT 1;
```

**Expected**: 
- `otp_hash` is bcrypt hash (60 chars)
- NOT plain 6-digit number

**Pass Criteria**: ✅ OTPs never stored in plain text

---

### Test 13: SMS Retry on Failure ✅

Mock MSG91 to fail 2 times, succeed on 3rd:
```typescript
// Override Msg91Provider to fail twice
```

**Expected**: 
- First 2 attempts log errors
- 3rd attempt succeeds
- Total time ~6 seconds (2s + 4s backoff)

**Pass Criteria**: ✅ Retry logic works

---

### Test 14: SMS Final Failure ✅

Mock MSG91 to always fail:
**Expected**: After 3 attempts, throws `EXTERNAL_SERVICE_ERROR`
**Pass Criteria**: ✅ Failure after exhausted retries

---

### Test 15: Concurrent OTP Requests ✅

Run 10 concurrent OTP requests for different mobiles:
**Expected**: All succeed (no race conditions)
**Pass Criteria**: ✅ No deadlocks or duplicate request IDs

---

## 🎯 Q&A Session

### Q1: Why bcrypt for OTP hashing instead of SHA-256?

**Expected Answer**:
- bcrypt is slow by design (cost factor 10 = ~100ms per hash)
- Slow hashing prevents brute force on stolen DB
- SHA-256 is too fast (millions/sec on GPU)
- 6-digit OTP space is small (10^6 = 1M combinations) — fast hash would be cracked instantly
- bcrypt's 100ms hash makes brute force impractical

---

### Q2: Why hash refresh tokens in the database?

**Expected Answer**:
- DB compromise shouldn't grant attacker access to user accounts
- Hash is one-way — attacker can't reverse to get token
- Token comparison via hashing (constant-time)
- Only the user's device has the original token
- Same security model as password storage

---

### Q3: Why refresh token rotation?

**Expected Answer**:
- Reduces window for stolen refresh tokens
- Forces frequent re-validation
- Enables token theft detection (both client and attacker try to use)
- Industry best practice (OAuth 2.0 spec recommendation)
- Trade-off: Slight complexity increase, big security gain

---

### Q4: How does token theft detection work?

**Expected Answer**:
1. User has valid refresh token → uses it → server issues new pair
2. Attacker has stolen refresh token → uses old one → DB hash doesn't match
3. Server detects mismatch → revokes ALL sessions for user
4. Both legitimate user AND attacker forced to re-authenticate
5. User notices unexpected logout → can change recovery details

---

### Q5: Why separate rate limits for mobile vs IP?

**Expected Answer**:
- **Per mobile** (3/hr): Prevents SMS bombing of specific user
- **Per IP** (10/hr): Prevents distributed attacks from one source
- Both needed: Attacker could rotate IPs OR target many mobiles
- Mobile rate limit protects user (no SMS spam)
- IP rate limit protects platform (cost control)

---

### Q6: Why mock SMS provider for development?

**Expected Answer**:
- MSG91 charges per SMS (~₹0.20) — testing is expensive
- No internet required for local dev
- Tests run without external dependencies
- OTP visible in logs for QA testing
- Same interface as production provider (swappable via config)

---

### Q7: What happens when MSG91 is down?

**Expected Answer**:
1. SmsService retries 3 times with exponential backoff (2s, 4s)
2. If all retries fail, throws `ExternalServiceException`
3. User sees: "Unable to send OTP. Please try again."
4. Error logged with full context for debugging
5. No PII leaked in logs
6. User can try again (rate limit allowing)

---

### Q8: Why JWT instead of session-only auth?

**Expected Answer**:
- **Stateless**: API doesn't query DB for every request
- **Scalable**: Multiple servers don't need shared session store
- **Mobile-friendly**: Tokens work great in headers
- **Microservice-ready**: Tokens travel between services
- **Trade-off**: Cannot revoke individual access tokens (mitigated by short lifetime + refresh tokens with revocation)

---

### Q9: What's the JWT payload?

**Expected Answer**:
- `sub` (subject): User ID
- `tenantId`: Multi-tenancy isolation
- `role`: Authorization checks
- `sessionId`: Links to session record (for revocation)
- `iat`, `exp`: Standard JWT timestamps
- NO sensitive data (passwords, secrets, full user profile)

---

### Q10: How would an attacker try to abuse this system?

**Expected Answers**:
1. **SMS Bombing**: Mitigated by mobile rate limit
2. **Brute force OTP**: Mitigated by 3-attempt limit
3. **Token theft**: Mitigated by rotation + theft detection
4. **Account takeover**: Mitigated by lockout policy
5. **Replay attacks**: Mitigated by single-use OTPs
6. **Timing attacks**: Mitigated by bcrypt's constant-time comparison
7. **CSRF**: Tokens in headers, not cookies (immune)
8. **XSS to steal token**: Frontend should use httpOnly storage

---

## 📝 Sign-Off Checklist

### Functional
- [ ] OTP request works (mock + real provider)
- [ ] OTP verify works
- [ ] Invalid OTP rejected
- [ ] Expired OTP rejected
- [ ] Max attempts enforced
- [ ] Rate limiting works (mobile + IP)
- [ ] Token refresh works
- [ ] Token rotation works
- [ ] Token theft detection works
- [ ] Logout works
- [ ] Logout-all works
- [ ] /me returns user

### Security
- [ ] OTPs hashed with bcrypt
- [ ] Refresh tokens hashed in DB
- [ ] Secrets >= 64 chars in production schema
- [ ] PII redacted in all logs
- [ ] Audit logs for all auth events
- [ ] Account lockout enforced
- [ ] Account active check enforced

### Code Quality
- [ ] All Zod schemas validate correctly
- [ ] Service interfaces implemented
- [ ] Repository pattern used
- [ ] Transactions used for multi-table writes
- [ ] No raw SQL outside repositories

### Tests
- [ ] All 15 functional tests pass
- [ ] Unit tests for services pass
- [ ] Integration tests pass
- [ ] Coverage > 85% for auth module
- [ ] Mock SMS provider works for tests

### Documentation
- [ ] API_CONTRACTS.md updated with all endpoints
- [ ] BACKEND_ARCHITECTURE.md updated with auth flow
- [ ] BE-06_HANDOFF.md complete
- [ ] All Q&A questions answered

**Developer Signature**: ___________________________
**Date**: ___________________________

## 👤 Reviewer Approval

### Critical Security Checks
- [ ] No secrets in source code
- [ ] No PII in logs (verified by reviewer reading sample logs)
- [ ] Rate limits cannot be bypassed
- [ ] Token rotation cannot be circumvented
- [ ] OTP brute force is impractical (verified by attempted attack)

### Production Readiness
- [ ] Account lockout after N failed attempts
- [ ] Mobile + IP dual rate limiting
- [ ] Audit log captures all auth events
- [ ] Errors don't leak system internals
- [ ] SMS retry doesn't double-charge

**☐ APPROVED — Proceed to BE-07**
**☐ CHANGES REQUESTED**

**Changes Required**:
1. _________________________________
2. _________________________________

**Reviewer Signature**: ___________________________
**Date**: ___________________________

---

## 🆘 Troubleshooting

### Issue: Mock OTP not visible in logs
**Solution**: Ensure `SMS_PROVIDER=mock` and log level is `debug`. OTP logged at `warn` level.

### Issue: Rate limit not working
**Solution**: Verify Redis is running. Check `RATE_LIMIT_*` env vars.

### Issue: bcrypt is slow in tests
**Solution**: Mock bcrypt in unit tests. Use real bcrypt only in integration tests.

### Issue: JWT verification fails
**Solution**: Check `JWT_ACCESS_SECRET` matches between issue and verify. Different secrets break tokens.

### Issue: Refresh token rotation breaking mobile app
**Solution**: Mobile app must store new refresh token after EVERY refresh. Old token becomes invalid.

---

**END OF BE-06 — DO NOT PROCEED WITHOUT APPROVAL**

**🎯 Critical: Authentication is the gateway to ALL features. If BE-06 has security issues, every subsequent feature is compromised. Take time on this phase.**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-06 with the staff-invitation auto-onboarding path (Req 55).**

## Driver Requirement

- **Req 55** — When an Owner has invited a mobile number, that mobile's first OTP login auto-creates the user under the inviter's tenant with the assigned role (Staff/Manager/Auditor), bypassing the Onboarding_Screen.

## Scope of Update

OTP authentication is unchanged. v2 adds a **post-OTP-success hook** that:

1. Looks up `pending_invitations` by mobile number.
2. If a non-expired invitation exists, creates the user under the inviter's tenant with the invited role and store assignment.
3. Marks the invitation `accepted_at = NOW()`.
4. Sets a flag on the JWT/session payload that the Mobile_App reads to skip the onboarding screen.
5. If no invitation exists, the v1 default-Consumer flow runs (assign Consumer role + route to Onboarding_Screen).

## Files to Create / Modify

| File Path | Change |
|---|---|
| `server/src/modules/auth/services/post-otp-hook.service.ts` | New |
| `server/src/modules/invitations/services/invitations.service.ts` | New (consumed here, owned by BE-09 v2 / BE-35) |
| `server/src/database/migrations/v2/2026XXXX_pending_invitations.sql` | New table |

## Schema

```sql
CREATE TABLE pending_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inviter_user_id UUID NOT NULL REFERENCES users(id),
  inviter_tenant_id UUID NOT NULL REFERENCES tenants(id),
  invitee_mobile TEXT NOT NULL,
  assigned_role TEXT NOT NULL CHECK (assigned_role IN ('staff','manager','auditor')),
  store_id UUID REFERENCES stores(id),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','expired','revoked')),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 days'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  accepted_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ
);

CREATE INDEX idx_pending_invitations_mobile_pending
  ON pending_invitations(invitee_mobile)
  WHERE status='pending';
```

## Post-OTP Hook

```typescript
@Injectable()
export class PostOtpHookService {
  async run(mobile: string): Promise<{ user: UserEntity; bypassOnboarding: boolean }> {
    const invitation = await this.invitations.findActivePending(mobile);
    if (invitation) {
      const user = await this.users.createUnderTenant({
        tenantId: invitation.inviter_tenant_id,
        mobile,
        role: invitation.assigned_role,
        storeIds: invitation.store_id ? [invitation.store_id] : [],
      });
      await this.invitations.markAccepted(invitation.id, user.id);
      return { user, bypassOnboarding: true };
    }
    // Default Consumer path (v2 — Req 1, Req 26)
    const tenant = await this.tenantBootstrap.createPersonalTenantForConsumer(mobile);
    const user = await this.users.createUnderTenant({
      tenantId: tenant.id,
      mobile,
      role: 'consumer',
      storeIds: [],
    });
    return { user, bypassOnboarding: false };
  }
}
```

## ADDENDUM v2 Test Procedures (add 4)

| # | Test |
|---|---|
| T-v2.1 | OTP login with no invitation → user role=`consumer`, `bypassOnboarding=false` |
| T-v2.2 | OTP login WITH active invitation → user role matches invitation, `bypassOnboarding=true` |
| T-v2.3 | OTP login with expired invitation → falls back to consumer path, invitation marked expired |
| T-v2.4 | OTP login with revoked invitation → falls back to consumer path |

## ADDENDUM v2 Q&A (add 2)

- **Q-v2.1**: How does the system handle a user who already has a Consumer account, then later receives a Staff invitation on the same mobile?
- **Q-v2.2**: How is the JWT structured to communicate `bypassOnboarding` to the Mobile_App?

## ADDENDUM v2 Sign-off

- [ ] Pending invitations table live
- [ ] Post-OTP hook tested with all four scenarios
- [ ] Mobile_App receives correct `bypassOnboarding` signal

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-06 ADDENDUM v2**
