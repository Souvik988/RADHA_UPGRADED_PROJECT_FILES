# Phase BE-04: Error Handling & Logging System

## Phase Metadata

- **Phase ID**: BE-04
- **Phase Name**: Error Handling & Logging System
- **Section**: Backend Execution — Foundation Layer
- **Depends On**: BE-01, BE-02, BE-03
- **Blocks**: BE-05, all subsequent phases
- **Estimated Duration**: 2 days

## Goal

Build comprehensive error handling and observability: error code taxonomy, custom exception classes, Sentry integration, audit logging, error analytics, alert thresholds, and log aggregation hooks.

## Why This Phase Matters

Without comprehensive error handling:
- Production bugs go undetected
- Cannot reproduce issues from logs alone
- No visibility into error trends
- Customer support cannot debug
- No alerting on critical failures

## Prerequisites

- [ ] BE-01, BE-02, BE-03 completed
- [ ] Sentry account created (or use mock for dev)
- [ ] Pino logger working

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/common/errors/error-codes.ts` | All error codes enum |
| `server/src/common/errors/business.exception.ts` | Business logic exceptions |
| `server/src/common/errors/validation.exception.ts` | Validation exceptions |
| `server/src/common/errors/not-found.exception.ts` | Resource not found |
| `server/src/common/errors/forbidden.exception.ts` | Access denied |
| `server/src/common/errors/conflict.exception.ts` | State conflicts |
| `server/src/common/errors/external-service.exception.ts` | External API failures |
| `server/src/common/errors/index.ts` | Barrel export |
| `server/src/observability/sentry.service.ts` | Sentry wrapper |
| `server/src/observability/sentry.module.ts` | Sentry module |
| `server/src/observability/error-tracking.service.ts` | Error tracking abstraction |
| `server/src/observability/audit-log.service.ts` | Audit logging |
| `server/src/observability/audit-log.module.ts` | Audit module |
| `server/src/observability/metrics.service.ts` | Metrics emission |

## Service Interfaces

```typescript
// server/src/observability/error-tracking.service.ts

export interface IErrorTrackingService {
  captureException(error: Error, context?: ErrorContext): void;
  captureMessage(message: string, level: ErrorLevel, context?: ErrorContext): void;
  setUser(user: { id: string; email?: string; tenantId?: string }): void;
  clearUser(): void;
  addBreadcrumb(breadcrumb: Breadcrumb): void;
  setTag(key: string, value: string): void;
  setContext(name: string, context: Record<string, unknown>): void;
}

export interface ErrorContext {
  userId?: string;
  tenantId?: string;
  requestId?: string;
  module?: string;
  metadata?: Record<string, unknown>;
}

export type ErrorLevel = 'fatal' | 'error' | 'warning' | 'info' | 'debug';

export interface Breadcrumb {
  message: string;
  category: string;
  level: ErrorLevel;
  data?: Record<string, unknown>;
  timestamp: number;
}

// server/src/observability/audit-log.service.ts

export interface IAuditLogService {
  logAction(entry: AuditEntry): Promise<void>;
  logBatch(entries: AuditEntry[]): Promise<void>;
  query(filters: AuditQueryFilters): Promise<AuditEntry[]>;
}

export interface AuditEntry {
  action: AuditAction;
  resourceType: string;
  resourceId: string;
  userId: string;
  tenantId: string;
  metadata?: Record<string, unknown>;
  ipAddress?: string;
  userAgent?: string;
  timestamp?: Date;
  success: boolean;
  errorCode?: string;
}

export type AuditAction =
  | 'CREATE'
  | 'READ'
  | 'UPDATE'
  | 'DELETE'
  | 'LOGIN'
  | 'LOGOUT'
  | 'EXPORT'
  | 'IMPORT'
  | 'GRANT_ACCESS'
  | 'REVOKE_ACCESS';
```

## Implementation Code

### Error Codes Taxonomy

```typescript
// server/src/common/errors/error-codes.ts

export enum ErrorCode {
  // Generic (1xxx)
  UNKNOWN_ERROR = 'E1000',
  INTERNAL_SERVER_ERROR = 'E1001',
  SERVICE_UNAVAILABLE = 'E1002',
  TIMEOUT = 'E1003',
  RATE_LIMIT_EXCEEDED = 'E1004',

  // Validation (2xxx)
  VALIDATION_ERROR = 'E2000',
  INVALID_INPUT = 'E2001',
  MISSING_REQUIRED_FIELD = 'E2002',
  INVALID_FORMAT = 'E2003',
  VALUE_OUT_OF_RANGE = 'E2004',

  // Authentication (3xxx)
  AUTHENTICATION_REQUIRED = 'E3000',
  INVALID_CREDENTIALS = 'E3001',
  TOKEN_EXPIRED = 'E3002',
  TOKEN_INVALID = 'E3003',
  TOKEN_REVOKED = 'E3004',
  OTP_INVALID = 'E3005',
  OTP_EXPIRED = 'E3006',
  OTP_TOO_MANY_ATTEMPTS = 'E3007',
  ACCOUNT_LOCKED = 'E3008',

  // Authorization (4xxx)
  FORBIDDEN = 'E4000',
  INSUFFICIENT_PERMISSIONS = 'E4001',
  TENANT_ACCESS_DENIED = 'E4002',
  STORE_ACCESS_DENIED = 'E4003',
  ROLE_REQUIRED = 'E4004',
  SUBSCRIPTION_REQUIRED = 'E4005',
  TRIAL_EXPIRED = 'E4006',
  PLAN_LIMIT_EXCEEDED = 'E4007',

  // Resources (5xxx)
  NOT_FOUND = 'E5000',
  USER_NOT_FOUND = 'E5001',
  PRODUCT_NOT_FOUND = 'E5002',
  STORE_NOT_FOUND = 'E5003',
  TENANT_NOT_FOUND = 'E5004',
  TASK_NOT_FOUND = 'E5005',
  REPORT_NOT_FOUND = 'E5006',
  SCAN_SESSION_NOT_FOUND = 'E5007',
  EAN_LIST_NOT_FOUND = 'E5008',

  // Conflicts (6xxx)
  CONFLICT = 'E6000',
  DUPLICATE_RESOURCE = 'E6001',
  EAN_ALREADY_EXISTS = 'E6002',
  USER_ALREADY_EXISTS = 'E6003',
  STALE_DATA = 'E6004',
  CONCURRENT_MODIFICATION = 'E6005',

  // Business Logic (7xxx)
  BUSINESS_RULE_VIOLATION = 'E7000',
  SCAN_SESSION_CLOSED = 'E7001',
  TASK_ALREADY_COMPLETED = 'E7002',
  GRN_ALREADY_POSTED = 'E7003',
  INSUFFICIENT_STOCK = 'E7004',
  EXPIRY_DATE_PAST = 'E7005',
  INVALID_EAN_FORMAT = 'E7006',
  PRODUCT_DISCONTINUED = 'E7007',

  // External Services (8xxx)
  EXTERNAL_SERVICE_ERROR = 'E8000',
  SMS_DELIVERY_FAILED = 'E8001',
  S3_UPLOAD_FAILED = 'E8002',
  S3_DOWNLOAD_FAILED = 'E8003',
  OPEN_FOOD_FACTS_UNAVAILABLE = 'E8004',
  AI_SERVICE_ERROR = 'E8005',
  EMAIL_DELIVERY_FAILED = 'E8006',

  // Database (9xxx)
  DATABASE_ERROR = 'E9000',
  DATABASE_CONNECTION_FAILED = 'E9001',
  DATABASE_QUERY_FAILED = 'E9002',
  DATABASE_TIMEOUT = 'E9003',
  DATABASE_DEADLOCK = 'E9004',
}

export const ERROR_CODE_TO_HTTP_STATUS: Record<ErrorCode, number> = {
  [ErrorCode.UNKNOWN_ERROR]: 500,
  [ErrorCode.INTERNAL_SERVER_ERROR]: 500,
  [ErrorCode.SERVICE_UNAVAILABLE]: 503,
  [ErrorCode.TIMEOUT]: 504,
  [ErrorCode.RATE_LIMIT_EXCEEDED]: 429,
  
  [ErrorCode.VALIDATION_ERROR]: 400,
  [ErrorCode.INVALID_INPUT]: 400,
  [ErrorCode.MISSING_REQUIRED_FIELD]: 400,
  [ErrorCode.INVALID_FORMAT]: 400,
  [ErrorCode.VALUE_OUT_OF_RANGE]: 400,
  
  [ErrorCode.AUTHENTICATION_REQUIRED]: 401,
  [ErrorCode.INVALID_CREDENTIALS]: 401,
  [ErrorCode.TOKEN_EXPIRED]: 401,
  [ErrorCode.TOKEN_INVALID]: 401,
  [ErrorCode.TOKEN_REVOKED]: 401,
  [ErrorCode.OTP_INVALID]: 401,
  [ErrorCode.OTP_EXPIRED]: 401,
  [ErrorCode.OTP_TOO_MANY_ATTEMPTS]: 429,
  [ErrorCode.ACCOUNT_LOCKED]: 403,
  
  [ErrorCode.FORBIDDEN]: 403,
  [ErrorCode.INSUFFICIENT_PERMISSIONS]: 403,
  [ErrorCode.TENANT_ACCESS_DENIED]: 403,
  [ErrorCode.STORE_ACCESS_DENIED]: 403,
  [ErrorCode.ROLE_REQUIRED]: 403,
  [ErrorCode.SUBSCRIPTION_REQUIRED]: 402,
  [ErrorCode.TRIAL_EXPIRED]: 402,
  [ErrorCode.PLAN_LIMIT_EXCEEDED]: 402,
  
  [ErrorCode.NOT_FOUND]: 404,
  [ErrorCode.USER_NOT_FOUND]: 404,
  [ErrorCode.PRODUCT_NOT_FOUND]: 404,
  [ErrorCode.STORE_NOT_FOUND]: 404,
  [ErrorCode.TENANT_NOT_FOUND]: 404,
  [ErrorCode.TASK_NOT_FOUND]: 404,
  [ErrorCode.REPORT_NOT_FOUND]: 404,
  [ErrorCode.SCAN_SESSION_NOT_FOUND]: 404,
  [ErrorCode.EAN_LIST_NOT_FOUND]: 404,
  
  [ErrorCode.CONFLICT]: 409,
  [ErrorCode.DUPLICATE_RESOURCE]: 409,
  [ErrorCode.EAN_ALREADY_EXISTS]: 409,
  [ErrorCode.USER_ALREADY_EXISTS]: 409,
  [ErrorCode.STALE_DATA]: 409,
  [ErrorCode.CONCURRENT_MODIFICATION]: 409,
  
  [ErrorCode.BUSINESS_RULE_VIOLATION]: 422,
  [ErrorCode.SCAN_SESSION_CLOSED]: 422,
  [ErrorCode.TASK_ALREADY_COMPLETED]: 422,
  [ErrorCode.GRN_ALREADY_POSTED]: 422,
  [ErrorCode.INSUFFICIENT_STOCK]: 422,
  [ErrorCode.EXPIRY_DATE_PAST]: 422,
  [ErrorCode.INVALID_EAN_FORMAT]: 422,
  [ErrorCode.PRODUCT_DISCONTINUED]: 422,
  
  [ErrorCode.EXTERNAL_SERVICE_ERROR]: 502,
  [ErrorCode.SMS_DELIVERY_FAILED]: 502,
  [ErrorCode.S3_UPLOAD_FAILED]: 502,
  [ErrorCode.S3_DOWNLOAD_FAILED]: 502,
  [ErrorCode.OPEN_FOOD_FACTS_UNAVAILABLE]: 502,
  [ErrorCode.AI_SERVICE_ERROR]: 502,
  [ErrorCode.EMAIL_DELIVERY_FAILED]: 502,
  
  [ErrorCode.DATABASE_ERROR]: 500,
  [ErrorCode.DATABASE_CONNECTION_FAILED]: 503,
  [ErrorCode.DATABASE_QUERY_FAILED]: 500,
  [ErrorCode.DATABASE_TIMEOUT]: 504,
  [ErrorCode.DATABASE_DEADLOCK]: 503,
};
```

### Custom Exception Classes

```typescript
// server/src/common/errors/business.exception.ts
import { HttpException } from '@nestjs/common';
import { ErrorCode, ERROR_CODE_TO_HTTP_STATUS } from './error-codes';

export interface ExceptionDetails {
  field?: string;
  value?: unknown;
  expected?: unknown;
  metadata?: Record<string, unknown>;
}

export class BusinessException extends HttpException {
  public readonly code: ErrorCode;
  public readonly details?: ExceptionDetails;

  constructor(
    code: ErrorCode,
    message: string,
    details?: ExceptionDetails,
  ) {
    const status = ERROR_CODE_TO_HTTP_STATUS[code] || 500;
    super(
      {
        code,
        message,
        ...(details && { details }),
      },
      status,
    );
    this.code = code;
    this.details = details;
  }
}

// Specific exception classes
export class ValidationException extends BusinessException {
  constructor(message: string, details?: ExceptionDetails) {
    super(ErrorCode.VALIDATION_ERROR, message, details);
  }
}

export class NotFoundException extends BusinessException {
  constructor(resource: string, id?: string) {
    super(
      ErrorCode.NOT_FOUND,
      `${resource} not found${id ? ` (id: ${id})` : ''}`,
      { metadata: { resource, id } },
    );
  }
}

export class ForbiddenException extends BusinessException {
  constructor(reason: string, code: ErrorCode = ErrorCode.FORBIDDEN) {
    super(code, reason);
  }
}

export class ConflictException extends BusinessException {
  constructor(
    message: string,
    code: ErrorCode = ErrorCode.CONFLICT,
    details?: ExceptionDetails,
  ) {
    super(code, message, details);
  }
}

export class ExternalServiceException extends BusinessException {
  constructor(service: string, originalError?: Error) {
    super(
      ErrorCode.EXTERNAL_SERVICE_ERROR,
      `External service ${service} unavailable`,
      {
        metadata: {
          service,
          originalMessage: originalError?.message,
        },
      },
    );
  }
}
```

### Sentry Service

```typescript
// server/src/observability/sentry.service.ts
import { Injectable, OnModuleInit } from '@nestjs/common';
import * as Sentry from '@sentry/node';
import { ConfigService } from '../config/config.service';
import {
  IErrorTrackingService,
  ErrorContext,
  ErrorLevel,
  Breadcrumb,
} from './error-tracking.types';

@Injectable()
export class SentryService implements IErrorTrackingService, OnModuleInit {
  private enabled = false;

  constructor(private readonly config: ConfigService) {}

  onModuleInit(): void {
    const dsn = this.config.get<string>('SENTRY_DSN');
    if (!dsn) {
      console.log('Sentry DSN not configured, error tracking disabled');
      return;
    }

    Sentry.init({
      dsn,
      environment: this.config.nodeEnv,
      release: this.config.get<string>('APP_VERSION'),
      tracesSampleRate: this.config.isProduction ? 0.1 : 1.0,
      beforeSend: (event) => this.scrubEvent(event),
    });

    this.enabled = true;
  }

  captureException(error: Error, context?: ErrorContext): void {
    if (!this.enabled) return;
    
    Sentry.withScope((scope) => {
      if (context?.userId) scope.setUser({ id: context.userId });
      if (context?.tenantId) scope.setTag('tenantId', context.tenantId);
      if (context?.requestId) scope.setTag('requestId', context.requestId);
      if (context?.module) scope.setTag('module', context.module);
      if (context?.metadata) scope.setContext('metadata', context.metadata);
      
      Sentry.captureException(error);
    });
  }

  captureMessage(message: string, level: ErrorLevel, context?: ErrorContext): void {
    if (!this.enabled) return;
    
    Sentry.withScope((scope) => {
      scope.setLevel(level as Sentry.SeverityLevel);
      if (context) {
        if (context.userId) scope.setUser({ id: context.userId });
        if (context.metadata) scope.setContext('metadata', context.metadata);
      }
      Sentry.captureMessage(message);
    });
  }

  setUser(user: { id: string; email?: string; tenantId?: string }): void {
    if (!this.enabled) return;
    Sentry.setUser({
      id: user.id,
      ...(user.email && { email: user.email }),
      ...(user.tenantId && { tenantId: user.tenantId }),
    });
  }

  clearUser(): void {
    if (!this.enabled) return;
    Sentry.setUser(null);
  }

  addBreadcrumb(breadcrumb: Breadcrumb): void {
    if (!this.enabled) return;
    Sentry.addBreadcrumb({
      message: breadcrumb.message,
      category: breadcrumb.category,
      level: breadcrumb.level as Sentry.SeverityLevel,
      data: breadcrumb.data,
      timestamp: breadcrumb.timestamp / 1000,
    });
  }

  setTag(key: string, value: string): void {
    if (!this.enabled) return;
    Sentry.setTag(key, value);
  }

  setContext(name: string, context: Record<string, unknown>): void {
    if (!this.enabled) return;
    Sentry.setContext(name, context);
  }

  private scrubEvent(event: Sentry.Event): Sentry.Event | null {
    if (event.request?.data) {
      const data = event.request.data as Record<string, unknown>;
      ['password', 'otp', 'token', 'secret'].forEach((key) => {
        if (data[key]) data[key] = '[REDACTED]';
      });
    }
    return event;
  }
}
```

### Audit Log Service

```typescript
// server/src/observability/audit-log.service.ts
import { Injectable } from '@nestjs/common';
import { LoggerService } from '../logging/logger.service';
import { RequestContextService } from '../common/context/request-context.service';
import {
  IAuditLogService,
  AuditEntry,
  AuditQueryFilters,
} from './audit-log.types';

@Injectable()
export class AuditLogService implements IAuditLogService {
  constructor(
    private readonly logger: LoggerService,
    private readonly context: RequestContextService,
    // Repository will be injected after BE-05
  ) {}

  async logAction(entry: AuditEntry): Promise<void> {
    const enrichedEntry: AuditEntry = {
      ...entry,
      userId: entry.userId || this.context.getUserId() || 'system',
      tenantId: entry.tenantId || this.context.getTenantId() || 'system',
      ipAddress: entry.ipAddress || this.context.get('ipAddress'),
      userAgent: entry.userAgent || this.context.get('userAgent'),
      timestamp: entry.timestamp || new Date(),
    };

    // Log to structured logs
    this.logger.info('Audit event', {
      audit: true,
      ...enrichedEntry,
    });

    // TODO (BE-05): Persist to audit_logs table
    // await this.auditRepository.create(enrichedEntry);
  }

  async logBatch(entries: AuditEntry[]): Promise<void> {
    await Promise.all(entries.map((e) => this.logAction(e)));
  }

  async query(filters: AuditQueryFilters): Promise<AuditEntry[]> {
    // TODO (BE-05): Implement query against audit_logs table
    return [];
  }
}
```

## DTOs & Validation Schemas

```typescript
// server/src/observability/dto/audit-query.dto.ts
import { z } from 'zod';

export const AuditQueryFiltersSchema = z.object({
  userId: z.string().uuid().optional(),
  tenantId: z.string().uuid().optional(),
  action: z.enum(['CREATE', 'READ', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'EXPORT', 'IMPORT', 'GRANT_ACCESS', 'REVOKE_ACCESS']).optional(),
  resourceType: z.string().optional(),
  resourceId: z.string().optional(),
  startDate: z.coerce.date().optional(),
  endDate: z.coerce.date().optional(),
  success: z.boolean().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
  cursor: z.string().optional(),
});

export type AuditQueryFilters = z.infer<typeof AuditQueryFiltersSchema>;
```

## Database Integration

Will be wired in BE-05 when database is connected. Audit logs will be written to `audit_logs` table.

## API Endpoints

| Method | Endpoint | Auth | Role | Purpose |
|---|---|---|---|---|
| GET | `/api/v1/audit/logs` | Bearer | Admin | Query audit logs |
| GET | `/api/v1/audit/logs/:id` | Bearer | Admin | Get audit entry |

## Tests

```typescript
// server/src/common/errors/__tests__/business.exception.spec.ts
import { BusinessException, NotFoundException, ValidationException } from '../business.exception';
import { ErrorCode } from '../error-codes';

describe('BusinessException', () => {
  it('should create with correct status code', () => {
    const ex = new BusinessException(
      ErrorCode.VALIDATION_ERROR,
      'Invalid input',
    );
    expect(ex.getStatus()).toBe(400);
    expect(ex.code).toBe(ErrorCode.VALIDATION_ERROR);
  });

  it('should include details in response', () => {
    const ex = new BusinessException(
      ErrorCode.VALIDATION_ERROR,
      'Invalid email',
      { field: 'email', value: 'bad-email' },
    );
    const response = ex.getResponse() as Record<string, unknown>;
    expect(response.code).toBe(ErrorCode.VALIDATION_ERROR);
    expect(response.details).toEqual({ field: 'email', value: 'bad-email' });
  });
});

describe('NotFoundException', () => {
  it('should format message with resource and id', () => {
    const ex = new NotFoundException('User', 'user-123');
    expect(ex.message).toBe('User not found (id: user-123)');
    expect(ex.getStatus()).toBe(404);
  });
});
```

## Commands to Run

```bash
cd server
pnpm add @sentry/node @sentry/integrations
pnpm test src/common/errors src/observability
```

## Validation Checklist

- [ ] All error codes defined in enum
- [ ] HTTP status mapping complete
- [ ] Custom exception classes work
- [ ] Sentry integration optional (works without DSN)
- [ ] PII scrubbed in Sentry events
- [ ] Audit log service logs to structured logs
- [ ] Audit log includes context automatically
- [ ] All exception tests pass

## Risk Assessment

| Risk | Mitigation |
|---|---|
| Sentry costs spike | Set sample rate, monitor usage |
| Audit logs too verbose | Filter what to audit, retention policy |
| PII leaks to Sentry | beforeSend scrubber, test thoroughly |

## Performance Benchmarks

- Exception creation: < 1ms
- Sentry capture: async, no blocking
- Audit log write: < 5ms (in-memory queue)

## Completion Criteria

- [ ] All error codes documented
- [ ] All exception classes tested
- [ ] Sentry working in dev (optional in prod for now)
- [ ] Audit logs working
- [ ] BE-04 handoff completed

## Next Phase

**BE-05: Database Connection & Repository Foundation** — Connect PostgreSQL, set up Drizzle ORM, create base repository, implement migrations runner, transaction utilities.


---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-05 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Custom Exception Throwing ✅

Create a test endpoint that throws each exception type:
```typescript
@Get('/test/not-found')
testNotFound() {
  throw new NotFoundException('User', 'user-123');
}

@Get('/test/validation')
testValidation() {
  throw new ValidationException('Invalid email', { field: 'email' });
}

@Get('/test/forbidden')
testForbidden() {
  throw new ForbiddenException('Access denied', ErrorCode.INSUFFICIENT_PERMISSIONS);
}
```

Test each:
```bash
curl http://localhost:3000/api/v1/test/not-found -i
curl http://localhost:3000/api/v1/test/validation -i
curl http://localhost:3000/api/v1/test/forbidden -i
```

**Expected**: Each returns appropriate HTTP status with error envelope including `code` from ErrorCode enum.

**Pass Criteria**: ✅ All exception types work with correct codes/statuses

---

### Test 2: Error Code to HTTP Status Mapping ✅

```bash
pnpm test src/common/errors
```

**Expected**: All 90+ error codes map correctly to HTTP statuses
**Pass Criteria**: ✅ Mapping table tests pass

---

### Test 3: Sentry Integration (Optional) ✅

If `SENTRY_DSN` is set:
```bash
SENTRY_DSN=https://your-key@sentry.io/your-project pnpm start:dev
# Trigger an error
curl http://localhost:3000/api/v1/test/error
```

**Expected**: Error appears in Sentry dashboard with:
- Stack trace
- Request context (requestId, userId)
- No PII in event payload (passwords/tokens redacted)

**Pass Criteria**: ✅ Errors captured, PII scrubbed

---

### Test 4: Sentry Disabled Without DSN ✅

```bash
unset SENTRY_DSN
pnpm start:dev
```

**Expected Console**:
```
Sentry DSN not configured, error tracking disabled
```

**Pass Criteria**: ✅ App works without Sentry, no errors thrown

---

### Test 5: Audit Log Service ✅

```typescript
// In a test controller
await this.auditLog.logAction({
  action: 'CREATE',
  resourceType: 'Product',
  resourceId: 'prod-123',
  userId: 'user-1',
  tenantId: 'tenant-1',
  success: true,
});
```

Check logs:
```bash
pnpm start:dev | grep "Audit event"
```

**Expected Log**:
```json
{
  "level": "info",
  "msg": "Audit event",
  "audit": true,
  "action": "CREATE",
  "resourceType": "Product",
  "resourceId": "prod-123",
  "userId": "user-1",
  "tenantId": "tenant-1",
  "success": true,
  "ipAddress": "127.0.0.1",
  "userAgent": "..."
}
```

**Pass Criteria**: ✅ Audit logs include context auto-enrichment

---

### Test 6: PII Scrubbing in Sentry Events ✅

Trigger an error with sensitive request body:
```bash
curl -X POST http://localhost:3000/api/v1/test/error \
  -H "Content-Type: application/json" \
  -d '{"password":"secret123","mobile":"9876543210"}'
```

**Expected**: Sentry event shows `password: [REDACTED]`, NOT actual password
**Pass Criteria**: ✅ Sentry never receives plain-text secrets

---

### Test 7: Error Code Documentation ✅

```bash
# Verify all error codes are documented
grep -c "= 'E" server/src/common/errors/error-codes.ts
```

**Expected**: 90+ error codes
**Pass Criteria**: ✅ All categories covered (Generic, Validation, Auth, etc.)

---

### Test 8: Custom Exception Tests ✅

```bash
pnpm test src/common/errors
```

**Expected**: 
- BusinessException tests pass
- ValidationException tests pass
- NotFoundException tests pass
- ConflictException tests pass
- ExternalServiceException tests pass
- Coverage > 90%

**Pass Criteria**: ✅ All exception class tests pass

---

## 🎯 Q&A Session

### Q1: Why custom exception classes instead of just `HttpException`?

**Expected Answer**:
- Type-safe error codes (autocomplete in IDE)
- Consistent error structure across codebase
- Mobile app can switch on error codes (i18n, retry logic)
- Documentation: each exception class is self-documenting
- Easier to track in Sentry (group by error class)

---

### Q2: Why an enum for error codes (E1000, E2000) instead of strings?

**Expected Answer**:
- Numbered ranges allow categorization (1xxx=generic, 2xxx=validation, etc.)
- Stable identifiers — never change after release
- Mobile app can match exact codes
- Easy to grep across logs
- Helps debugging: "E5002" immediately tells you it's product-not-found

---

### Q3: Why optional Sentry integration?

**Expected Answer**:
- Local dev doesn't need Sentry (just adds noise)
- Some environments may not have internet access
- Cost control — Sentry has paid plans based on event volume
- Test environments shouldn't pollute production Sentry project
- App must work without external services (resilience)

---

### Q4: What's "beforeSend" in Sentry?

**Expected Answer**:
- Hook that runs BEFORE event is sent to Sentry servers
- Last chance to scrub PII
- Can drop events entirely (return null)
- Used to redact: password, otp, token, secret fields
- Critical for compliance (GDPR, DPDP Act)

---

### Q5: How does audit logging differ from regular logging?

**Expected Answer**:
- **Regular logs**: For debugging (info, warn, error)
- **Audit logs**: For compliance/security (who did what, when)
- Audit logs are queryable (will be persisted to `audit_logs` table in BE-05)
- Audit logs cannot be deleted (immutable)
- Audit logs include before/after state for updates
- Audit logs may have longer retention (7 years for some industries)

---

### Q6: When should you create a new error code vs reuse existing?

**Expected Answer**:
- **Reuse**: When the situation is semantically the same (e.g., any "not found")
- **Create new**: When mobile app needs to handle differently
- **Create new**: When error suggests different user action
- Examples:
  - User vs Product not found → both use `NOT_FOUND` (same UX)
  - Token expired vs revoked → different codes (different UX prompts)

---

### Q7: How do you test error handling without breaking things?

**Expected Answer**:
- Create test endpoints in dev only (`@IfDevelopment()` decorator)
- Use unit tests with mocked dependencies
- Use integration tests that trigger real errors
- Use chaos engineering (BE-31): randomly inject failures
- Monitor error rates in Sentry, alert on spikes

---

### Q8: What's the difference between `error`, `warn`, `info` in logs?

**Expected Answer**:
- **error**: Action required, page on-call (DB down, payments failing)
- **warn**: Investigate later (high latency, retried request)
- **info**: Normal operations (request received, job started)
- **debug**: Local development only (variable values)
- **verbose**: Trace-level (rarely used)

---

## 📝 Sign-Off Checklist

### Code Quality
- [ ] 90+ error codes defined and documented
- [ ] All exception classes implemented
- [ ] HTTP status mapping complete
- [ ] Sentry integration optional
- [ ] PII scrubbing in Sentry beforeSend
- [ ] Audit log service auto-enriches context

### Tests
- [ ] All exception tests pass
- [ ] Sentry mock tests pass
- [ ] Audit log tests pass
- [ ] Coverage > 90% for errors module

### Documentation
- [ ] Error code catalog documented
- [ ] When to use each exception class
- [ ] Sentry setup guide
- [ ] BE-04_HANDOFF.md complete

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-05**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF BE-04 — DO NOT PROCEED WITHOUT APPROVAL**
