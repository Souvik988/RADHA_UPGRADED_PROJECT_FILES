# Phase BE-03: Global Middleware & Request Context

## Phase Metadata

- **Phase ID**: BE-03
- **Phase Name**: Global Middleware & Request Context
- **Section**: Backend Execution — Foundation Layer
- **Depends On**: BE-01, BE-02
- **Blocks**: BE-04, BE-05, all subsequent phases
- **Estimated Duration**: 2 days
- **Complexity**: Medium

## Goal

Implement production-grade middleware stack: request ID generation, request context (CLS), structured logging, security headers (Helmet), compression, CORS, global validation pipe, global response serializer, and request/response logging with PII redaction.

## Why This Phase Matters

Without proper middleware:
- Cannot trace requests across logs
- Cannot debug production issues effectively
- Security headers missing
- Logs leak sensitive data
- Response format inconsistent
- No correlation between requests and database queries

This phase creates the **observability and security foundation** for all subsequent backend work.

## Prerequisites

- [ ] BE-01 completed: NestJS app starts
- [ ] BE-02 completed: ConfigService available
- [ ] Helmet installed (from BE-01)
- [ ] Compression installed (from BE-01)

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/common/middleware/request-id.middleware.ts` | Generates UUID per request |
| `server/src/common/middleware/request-logger.middleware.ts` | Logs request/response |
| `server/src/common/context/request-context.service.ts` | CLS-based request store |
| `server/src/common/context/request-context.module.ts` | CLS module |
| `server/src/common/filters/global-exception.filter.ts` | Catches all exceptions |
| `server/src/common/filters/http-exception.filter.ts` | Formats HTTP errors |
| `server/src/common/interceptors/response.interceptor.ts` | Standardizes responses |
| `server/src/common/interceptors/timeout.interceptor.ts` | Request timeout |
| `server/src/common/pipes/parse-uuid.pipe.ts` | UUID validation |
| `server/src/common/pipes/zod-validation.pipe.ts` | Zod-based validation |
| `server/src/common/decorators/request-context.decorator.ts` | Inject request context |
| `server/src/common/utils/redact.utils.ts` | PII redaction utilities |
| `server/src/logging/logger.module.ts` | Pino logger module |
| `server/src/logging/logger.service.ts` | Custom logger wrapper |
| `server/src/logging/__tests__/logger.service.spec.ts` | Logger tests |

## Files to Modify

| File Path | Required Change |
|---|---|
| `server/src/app.module.ts` | Import LoggerModule, RequestContextModule |
| `server/src/main.api.ts` | Apply middleware stack in correct order |
| `server/package.json` | Add `nestjs-pino`, `nestjs-cls`, `pino-pretty` |

## Service Interfaces

```typescript
// server/src/common/context/request-context.service.ts

export interface IRequestContext {
  requestId: string;
  startTime: number;
  userAgent?: string;
  ipAddress?: string;
  userId?: string;
  tenantId?: string;
  storeId?: string;
  role?: UserRole;
  correlationId?: string;
}

export interface IRequestContextService {
  set<K extends keyof IRequestContext>(key: K, value: IRequestContext[K]): void;
  get<K extends keyof IRequestContext>(key: K): IRequestContext[K] | undefined;
  getAll(): IRequestContext;
  getRequestId(): string;
  getUserId(): string | undefined;
  getTenantId(): string | undefined;
  getDuration(): number;
}

// server/src/logging/logger.service.ts

export interface ILoggerService {
  error(message: string, context?: LogContext): void;
  warn(message: string, context?: LogContext): void;
  info(message: string, context?: LogContext): void;
  debug(message: string, context?: LogContext): void;
  verbose(message: string, context?: LogContext): void;
  
  // Structured logging
  log(level: LogLevel, message: string, context?: LogContext): void;
  
  // With auto-redaction
  logRequest(req: Request, res: Response, durationMs: number): void;
  logError(error: Error, context?: LogContext): void;
  
  // Child logger with bound context
  child(bindings: Record<string, unknown>): ILoggerService;
}

export interface LogContext {
  requestId?: string;
  userId?: string;
  tenantId?: string;
  module?: string;
  method?: string;
  durationMs?: number;
  statusCode?: number;
  error?: {
    name: string;
    message: string;
    stack?: string;
  };
  [key: string]: unknown;
}

export type LogLevel = 'error' | 'warn' | 'info' | 'debug' | 'verbose';
```

## Implementation Code

### Request ID Middleware

```typescript
// server/src/common/middleware/request-id.middleware.ts
import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class RequestIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction): void {
    const requestId = (req.headers['x-request-id'] as string) || uuidv4();
    req.headers['x-request-id'] = requestId;
    res.setHeader('X-Request-Id', requestId);
    next();
  }
}
```

### Request Context Service (using nestjs-cls)

```typescript
// server/src/common/context/request-context.service.ts
import { Injectable } from '@nestjs/common';
import { ClsService } from 'nestjs-cls';
import { IRequestContext, IRequestContextService } from './request-context.types';

@Injectable()
export class RequestContextService implements IRequestContextService {
  constructor(private readonly cls: ClsService) {}

  set<K extends keyof IRequestContext>(key: K, value: IRequestContext[K]): void {
    this.cls.set(key, value);
  }

  get<K extends keyof IRequestContext>(key: K): IRequestContext[K] | undefined {
    return this.cls.get(key);
  }

  getAll(): IRequestContext {
    return {
      requestId: this.cls.get('requestId') || 'unknown',
      startTime: this.cls.get('startTime') || Date.now(),
      userAgent: this.cls.get('userAgent'),
      ipAddress: this.cls.get('ipAddress'),
      userId: this.cls.get('userId'),
      tenantId: this.cls.get('tenantId'),
      storeId: this.cls.get('storeId'),
      role: this.cls.get('role'),
      correlationId: this.cls.get('correlationId'),
    };
  }

  getRequestId(): string {
    return this.cls.get('requestId') || 'unknown';
  }

  getUserId(): string | undefined {
    return this.cls.get('userId');
  }

  getTenantId(): string | undefined {
    return this.cls.get('tenantId');
  }

  getDuration(): number {
    const startTime = this.cls.get<number>('startTime') || Date.now();
    return Date.now() - startTime;
  }
}
```

### Global Exception Filter

```typescript
// server/src/common/filters/global-exception.filter.ts
import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { RequestContextService } from '../context/request-context.service';
import { redactPII } from '../utils/redact.utils';

interface ErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
  meta: {
    requestId: string;
    timestamp: string;
    path: string;
  };
}

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);

  constructor(private readonly context: RequestContextService) {}

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    const requestId = this.context.getRequestId();

    let status: number;
    let code: string;
    let message: string;
    let details: unknown;

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();
      
      if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
        const respObj = exceptionResponse as Record<string, unknown>;
        code = (respObj.code as string) || this.statusToCode(status);
        message = (respObj.message as string) || exception.message;
        details = respObj.details;
      } else {
        code = this.statusToCode(status);
        message = exceptionResponse as string;
      }
    } else if (exception instanceof Error) {
      status = HttpStatus.INTERNAL_SERVER_ERROR;
      code = 'INTERNAL_SERVER_ERROR';
      message = 'An unexpected error occurred';
      
      // Log full error internally
      this.logger.error({
        message: exception.message,
        stack: exception.stack,
        requestId,
        path: request.url,
        method: request.method,
        body: redactPII(request.body),
      });
    } else {
      status = HttpStatus.INTERNAL_SERVER_ERROR;
      code = 'UNKNOWN_ERROR';
      message = 'An unknown error occurred';
      
      this.logger.error({
        message: 'Unknown exception type',
        exception: String(exception),
        requestId,
      });
    }

    const errorResponse: ErrorResponse = {
      success: false,
      error: {
        code,
        message,
        ...(details !== undefined && { details }),
      },
      meta: {
        requestId,
        timestamp: new Date().toISOString(),
        path: request.url,
      },
    };

    response.status(status).json(errorResponse);
  }

  private statusToCode(status: number): string {
    const codes: Record<number, string> = {
      400: 'BAD_REQUEST',
      401: 'UNAUTHORIZED',
      403: 'FORBIDDEN',
      404: 'NOT_FOUND',
      409: 'CONFLICT',
      422: 'VALIDATION_ERROR',
      429: 'RATE_LIMIT_EXCEEDED',
      500: 'INTERNAL_SERVER_ERROR',
      503: 'SERVICE_UNAVAILABLE',
    };
    return codes[status] || 'UNKNOWN_ERROR';
  }
}
```

### Response Interceptor (Standardize Format)

```typescript
// server/src/common/interceptors/response.interceptor.ts
import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable, map } from 'rxjs';
import { RequestContextService } from '../context/request-context.service';

interface SuccessResponse<T> {
  success: true;
  data: T;
  meta: {
    requestId: string;
    timestamp: string;
    durationMs: number;
  };
}

@Injectable()
export class ResponseInterceptor<T> implements NestInterceptor<T, SuccessResponse<T>> {
  constructor(private readonly context: RequestContextService) {}

  intercept(_: ExecutionContext, next: CallHandler<T>): Observable<SuccessResponse<T>> {
    return next.handle().pipe(
      map((data) => ({
        success: true,
        data,
        meta: {
          requestId: this.context.getRequestId(),
          timestamp: new Date().toISOString(),
          durationMs: this.context.getDuration(),
        },
      })),
    );
  }
}
```

### Zod Validation Pipe

```typescript
// server/src/common/pipes/zod-validation.pipe.ts
import { PipeTransform, BadRequestException } from '@nestjs/common';
import { ZodSchema, ZodError } from 'zod';

export class ZodValidationPipe<T> implements PipeTransform<unknown, T> {
  constructor(private readonly schema: ZodSchema<T>) {}

  transform(value: unknown): T {
    try {
      return this.schema.parse(value);
    } catch (error) {
      if (error instanceof ZodError) {
        const details = error.errors.map((err) => ({
          field: err.path.join('.'),
          message: err.message,
          code: err.code,
        }));

        throw new BadRequestException({
          code: 'VALIDATION_ERROR',
          message: 'Validation failed',
          details,
        });
      }
      throw error;
    }
  }
}
```

### PII Redaction Utility

```typescript
// server/src/common/utils/redact.utils.ts

const PII_FIELDS = [
  'password',
  'otp',
  'token',
  'access_token',
  'refresh_token',
  'authorization',
  'mobile',
  'phone',
  'email',
  'aadhaar',
  'pan',
  'creditCard',
  'ssn',
  'apiKey',
  'secret',
];

const PII_PATTERNS = [
  /\b\d{12}\b/g, // Aadhaar
  /\b[A-Z]{5}\d{4}[A-Z]\b/g, // PAN
  /\b\d{16}\b/g, // Credit card
  /\b[6-9]\d{9}\b/g, // Indian mobile
];

export function redactPII<T>(obj: T): T {
  if (obj === null || obj === undefined) return obj;
  if (typeof obj !== 'object') return obj;

  if (Array.isArray(obj)) {
    return obj.map(redactPII) as unknown as T;
  }

  const result: Record<string, unknown> = {};
  const objRecord = obj as Record<string, unknown>;

  for (const key of Object.keys(objRecord)) {
    const lowerKey = key.toLowerCase();
    const isPII = PII_FIELDS.some((field) => lowerKey.includes(field.toLowerCase()));

    if (isPII) {
      result[key] = '[REDACTED]';
    } else if (typeof objRecord[key] === 'object') {
      result[key] = redactPII(objRecord[key]);
    } else if (typeof objRecord[key] === 'string') {
      let value = objRecord[key] as string;
      for (const pattern of PII_PATTERNS) {
        value = value.replace(pattern, '[REDACTED]');
      }
      result[key] = value;
    } else {
      result[key] = objRecord[key];
    }
  }

  return result as T;
}
```

### Logger Service (Pino-based)

```typescript
// server/src/logging/logger.service.ts
import { Injectable, LoggerService as NestLoggerService } from '@nestjs/common';
import pino, { Logger as PinoLogger } from 'pino';
import { ConfigService } from '../config/config.service';
import { RequestContextService } from '../common/context/request-context.service';
import { redactPII } from '../common/utils/redact.utils';
import { ILoggerService, LogContext, LogLevel } from './logger.types';

@Injectable()
export class LoggerService implements ILoggerService, NestLoggerService {
  private readonly logger: PinoLogger;

  constructor(
    private readonly config: ConfigService,
    private readonly context: RequestContextService,
  ) {
    this.logger = pino({
      level: this.config.get<string>('LOG_LEVEL') || 'info',
      formatters: {
        level: (label) => ({ level: label }),
      },
      timestamp: pino.stdTimeFunctions.isoTime,
      redact: {
        paths: [
          '*.password',
          '*.otp',
          '*.token',
          '*.access_token',
          '*.refresh_token',
          '*.authorization',
          'req.headers.authorization',
        ],
        censor: '[REDACTED]',
      },
      transport: this.config.isDevelopment
        ? {
            target: 'pino-pretty',
            options: {
              colorize: true,
              translateTime: 'HH:MM:ss.l',
              ignore: 'pid,hostname',
            },
          }
        : undefined,
    });
  }

  private buildContext(context?: LogContext): LogContext {
    return {
      ...redactPII(context || {}),
      requestId: this.context.getRequestId(),
      userId: this.context.getUserId(),
      tenantId: this.context.getTenantId(),
    };
  }

  error(message: string, context?: LogContext): void {
    this.logger.error(this.buildContext(context), message);
  }

  warn(message: string, context?: LogContext): void {
    this.logger.warn(this.buildContext(context), message);
  }

  info(message: string, context?: LogContext): void {
    this.logger.info(this.buildContext(context), message);
  }

  debug(message: string, context?: LogContext): void {
    this.logger.debug(this.buildContext(context), message);
  }

  verbose(message: string, context?: LogContext): void {
    this.logger.trace(this.buildContext(context), message);
  }

  log(level: LogLevel, message: string, context?: LogContext): void {
    this[level === 'verbose' ? 'verbose' : level](message, context);
  }

  logError(error: Error, context?: LogContext): void {
    this.error(error.message, {
      ...context,
      error: {
        name: error.name,
        message: error.message,
        stack: error.stack,
      },
    });
  }

  child(bindings: Record<string, unknown>): ILoggerService {
    const childLogger = this.logger.child(bindings);
    const newService = Object.create(this);
    newService.logger = childLogger;
    return newService;
  }
}
```

## DTOs & Validation Schemas

No new DTOs in this phase. The `ZodValidationPipe` is used by all subsequent phases for DTO validation.

## Database Integration

No database operations in this phase.

## API Endpoints

No new endpoints. This phase adds infrastructure for ALL endpoints:
- Request ID header on every response
- Standardized success/error response format
- PII redaction in logs
- Request/response logging
- Validation errors with details

## Tests

```typescript
// server/src/common/utils/__tests__/redact.utils.spec.ts
import { redactPII } from '../redact.utils';

describe('redactPII', () => {
  it('should redact password fields', () => {
    const input = { username: 'john', password: 'secret123' };
    expect(redactPII(input)).toEqual({
      username: 'john',
      password: '[REDACTED]',
    });
  });

  it('should redact mobile numbers in strings', () => {
    const input = { message: 'Call 9876543210 now' };
    expect(redactPII(input)).toEqual({
      message: 'Call [REDACTED] now',
    });
  });

  it('should redact nested PII', () => {
    const input = {
      user: { mobile: '9876543210', name: 'John' },
      auth: { token: 'abc123' },
    };
    expect(redactPII(input)).toEqual({
      user: { mobile: '[REDACTED]', name: 'John' },
      auth: { token: '[REDACTED]' },
    });
  });

  it('should handle arrays', () => {
    const input = [{ password: 'a' }, { password: 'b' }];
    expect(redactPII(input)).toEqual([
      { password: '[REDACTED]' },
      { password: '[REDACTED]' },
    ]);
  });
});
```

## Commands to Run

```bash
cd server
pnpm add nestjs-pino pino pino-pretty nestjs-cls
pnpm test src/common
pnpm start:dev
```

## Validation Checklist

- [ ] Every response has `X-Request-Id` header
- [ ] Every error response has standard envelope
- [ ] Every success response has standard envelope
- [ ] Logs are JSON in production, pretty in dev
- [ ] Passwords/secrets/tokens are redacted in logs
- [ ] Mobile numbers are redacted in logs
- [ ] Request context (CLS) works across async calls
- [ ] Validation errors return 400 with field details
- [ ] Unknown errors return 500 with safe message
- [ ] Helmet headers set on every response
- [ ] CORS works with configured origins
- [ ] Compression works for responses > 1KB
- [ ] Request timeout works (30s default)
- [ ] All middleware tests pass

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|---|---|---|---|
| Middleware order wrong | High | Medium | Document order, add integration tests |
| CLS context lost in async | High | Low | Use `nestjs-cls` (battle-tested) |
| PII leaks in logs | Critical | Medium | Comprehensive redact utility, audit logs |
| Performance overhead | Medium | Low | Pino is fast, benchmark before launch |
| Error filter swallows real errors | High | Low | Always log errors before responding |

## Performance Benchmarks

- **Middleware overhead per request**: < 5ms
- **Logger throughput**: > 10,000 logs/sec
- **Memory per request context**: < 1KB
- **JSON serialization**: < 1ms for typical response

## Security Considerations

- All PII redacted in logs
- Helmet sets security headers (CSP, HSTS, X-Frame-Options)
- CORS strictly enforced via config
- Request body redacted in error logs
- Stack traces hidden in production responses
- Error codes don't leak internal details

## Completion Criteria

- [ ] All middleware files created and tested
- [ ] CLS request context working
- [ ] Pino logger integrated
- [ ] PII redaction comprehensive
- [ ] Global exception filter active
- [ ] Response interceptor active
- [ ] All tests passing (>90% coverage for utils)
- [ ] Documentation updated

## Next Phase

**BE-04: Error Handling & Logging System** — Add error tracking (Sentry), structured error codes, error analytics, alert thresholds, log aggregation.


---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-04 Until This Section is Complete

## 📋 Pre-Test Setup

```bash
cd server
pnpm install
pnpm list nestjs-pino nestjs-cls pino
```

## 🧪 Test Procedures

### Test 1: Request ID Generation ✅

```bash
pnpm start:dev
# In another terminal:
curl -i http://localhost:3000/api/v1/health
```

**Expected**: Response has `X-Request-Id: <uuid>` header
**Pass Criteria**: ✅ Every response has unique X-Request-Id

---

### Test 2: Request ID Propagation ✅

```bash
curl -H "X-Request-Id: my-custom-id-123" http://localhost:3000/api/v1/health -i
```

**Expected**: Response echoes `X-Request-Id: my-custom-id-123`
**Pass Criteria**: ✅ Custom request ID propagates back

---

### Test 3: Standard Success Response ✅

```bash
curl http://localhost:3000/api/v1/health
```

**Expected JSON**:
```json
{
  "success": true,
  "data": { "status": "ok" },
  "meta": {
    "requestId": "<uuid>",
    "timestamp": "2024-...",
    "durationMs": 5
  }
}
```

**Pass Criteria**: ✅ Response wrapped in standard envelope

---

### Test 4: Standard Error Response ✅

Trigger an error:
```bash
curl http://localhost:3000/api/v1/nonexistent -i
```

**Expected JSON**:
```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Cannot GET /api/v1/nonexistent"
  },
  "meta": {
    "requestId": "<uuid>",
    "timestamp": "...",
    "path": "/api/v1/nonexistent"
  }
}
```

**Pass Criteria**: ✅ Error has standard envelope with code

---

### Test 5: PII Redaction in Logs ✅

```bash
# Make request with PII
curl -X POST http://localhost:3000/api/v1/test \
  -H "Content-Type: application/json" \
  -d '{"mobile":"9876543210","password":"secret","email":"test@test.com"}'
```

**Expected Log Output**:
```json
{
  "level": "info",
  "msg": "Incoming request",
  "body": {
    "mobile": "[REDACTED]",
    "password": "[REDACTED]",
    "email": "[REDACTED]"
  }
}
```

**Pass Criteria**: ✅ PII fields redacted in logs

---

### Test 6: Helmet Headers ✅

```bash
curl -I http://localhost:3000/api/v1/health
```

**Expected Headers**:
- `X-DNS-Prefetch-Control`
- `X-Frame-Options: SAMEORIGIN`
- `Strict-Transport-Security` (in production)
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy`

**Pass Criteria**: ✅ Security headers present

---

### Test 7: CORS Configuration ✅

```bash
curl -H "Origin: http://localhost:3000" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS http://localhost:3000/api/v1/health -i
```

**Expected**: 
- `Access-Control-Allow-Origin: http://localhost:3000`
- `Access-Control-Allow-Credentials: true`

**Pass Criteria**: ✅ CORS configured with allowed origins

---

### Test 8: Compression ✅

```bash
curl -H "Accept-Encoding: gzip" -I http://localhost:3000/api/v1/health
```

**Expected**: `Content-Encoding: gzip` (for responses > 1KB)
**Pass Criteria**: ✅ Compression works

---

### Test 9: Validation Pipe ✅

Create a test endpoint that uses Zod validation, then:
```bash
curl -X POST http://localhost:3000/api/v1/test \
  -H "Content-Type: application/json" \
  -d '{"invalid":"data"}'
```

**Expected 400**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "details": [{"field": "...", "message": "..."}]
  }
}
```

**Pass Criteria**: ✅ Validation errors include field details

---

### Test 10: Request Context Across Async ✅

Test that request context flows through async operations:
```bash
pnpm test src/common/context
```

**Expected**: All CLS tests pass — context preserved across `await` calls.
**Pass Criteria**: ✅ Request context works in async functions

---

## 🎯 Q&A Session

### Q1: Why use AsyncLocalStorage (CLS) instead of passing context as parameters?

**Expected Answer**:
- Eliminates parameter pollution (every function would need `context` arg)
- Automatic context flow through async operations
- Zero performance overhead in modern Node.js (>14)
- Standard pattern for request-scoped data
- Used by major frameworks (Express, Fastify, AWS X-Ray)

---

### Q2: What's the difference between Pino and Winston?

**Expected Answer**:
- **Pino**: Faster (10x), JSON-first, smaller, built for high throughput
- **Winston**: More transports/integrations, more flexible, slower
- Pino chosen because production-grade, low overhead, structured by default
- Pretty-print only for dev (via pino-pretty), JSON for prod

---

### Q3: Why redact PII at log time, not at storage time?

**Expected Answer**:
- Defense in depth — multiple layers of protection
- Log aggregation tools (CloudWatch, Datadog) may store unencrypted
- Developers may accidentally log sensitive fields
- Compliance (GDPR, India DPDP Act) requires no PII in logs
- Easier to audit (grep for [REDACTED] vs scanning storage)

---

### Q4: Why use a global exception filter?

**Expected Answer**:
- Single place for error response formatting
- Consistent error envelope across ALL endpoints
- Catches errors from any controller/service/middleware
- Hooks into Sentry/error tracking (BE-04)
- Strips internal details (stack traces) in production

---

### Q5: How does the response interceptor handle non-object responses?

**Expected Answer**:
- Wraps any response (string, number, object, array) in `data` field
- Doesn't wrap if response is already shaped (e.g., file downloads)
- Adds `success: true` for all successful responses
- Adds metadata (requestId, timestamp, durationMs)
- Skipped via `@SkipResponseInterceptor()` decorator if needed

---

### Q6: What's the order of middleware execution?

**Expected Answer** (CRITICAL - test this):
1. `helmet` (security headers)
2. `compression` (response compression)
3. `cors` (CORS preflight)
4. `RequestIdMiddleware` (generate ID)
5. `ClsMiddleware` (initialize context)
6. `RequestLoggerMiddleware` (log request)
7. **Route handler executes**
8. `ResponseInterceptor` (wrap response)
9. `RequestLoggerMiddleware.afterResponse` (log response)
10. `GlobalExceptionFilter` (if error thrown)

---

### Q7: Why 30-second request timeout?

**Expected Answer**:
- Prevents hung requests from holding connections
- Frontend can retry after timeout
- Long operations should be async (jobs)
- Database queries also have 30s timeout (BE-05)
- Configurable per route if needed

---

### Q8: How would you debug a slow endpoint using these tools?

**Expected Answer**:
1. Find requestId from frontend response
2. Search logs by requestId: `grep "requestId.*abc123"`
3. Look at `durationMs` in response logs
4. Check for slow query warnings (BE-05)
5. Check Sentry for breadcrumbs (BE-04)
6. Use `request.user.id` to find user-specific issues

---

## 📝 Sign-Off Checklist

### Functional
- [ ] Request ID on every response
- [ ] Standard success envelope works
- [ ] Standard error envelope works
- [ ] PII redacted in all logs
- [ ] Helmet headers present
- [ ] CORS configured correctly
- [ ] Compression enabled
- [ ] Validation pipe works with Zod
- [ ] Request context flows across async

### Code Quality
- [ ] All middleware unit tested
- [ ] Coverage > 85% for `src/common/`
- [ ] No raw `console.log` (use logger)
- [ ] No PII in test fixtures

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-04**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF BE-03 — DO NOT PROCEED WITHOUT APPROVAL**
