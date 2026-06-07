# Phase BE-02: Configuration System & Environment Validation

## Phase Metadata

- **Phase ID**: BE-02
- **Phase Name**: Configuration System & Environment Validation
- **Section**: Backend Execution — Foundation Layer
- **Depends On**: BE-01
- **Blocks**: BE-03, BE-04, BE-05, all subsequent phases
- **Estimated Duration**: 1-2 days
- **Complexity**: Medium
- **Priority**: Critical (foundation)

## Goal

Replace direct `process.env` access with a fully typed, validated `ConfigService` that fails fast on invalid configuration. Use Zod schemas to validate every environment variable at boot time, with environment-specific rules (dev vs staging vs production).

## Why This Phase Matters

Without proper configuration validation:
- Apps crash mysteriously in production due to missing env vars
- Type errors occur at runtime instead of boot time
- Sensitive defaults leak into production (e.g., CORS `*`)
- No single source of truth for config structure
- Testing is brittle (real env vars leak into tests)
- Onboarding is hard (no docs of required vars)

This phase establishes a **fail-fast configuration system** that:
- Validates ALL env vars at boot using Zod
- Provides typed access via `ConfigService`
- Enforces stricter rules in production
- Documents every variable
- Supports test overrides cleanly
- Masks secrets in logs

## Prerequisites

- [ ] BE-01 completed: NestJS app starts successfully
- [ ] `@nestjs/config` installed
- [ ] `zod` installed
- [ ] `.env.example` exists with all variables
- [ ] Health check endpoint responds 200 OK

## Files to Create

| File Path | Purpose | Empty Initially? |
|---|---|---|
| `server/src/config/env.schema.ts` | Zod schema for environment variables | No |
| `server/src/config/env.validation.ts` | Validation function used by ConfigModule | No |
| `server/src/config/config.service.ts` | Typed configuration service | No |
| `server/src/config/config.module.ts` | Custom config module wrapper | No |
| `server/src/config/config.types.ts` | TypeScript types for config | No |
| `server/src/config/secrets.utils.ts` | Secret masking utilities | No |
| `server/src/config/__tests__/env.validation.spec.ts` | Validation unit tests | No |
| `server/src/config/__tests__/config.service.spec.ts` | ConfigService unit tests | No |
| `server/.env.example` | Template with all variables documented | No |
| `server/.env.development.example` | Development-specific defaults | No |
| `server/.env.production.example` | Production requirements | No |

## Files to Modify

| File Path | Required Change |
|---|---|
| `server/src/app.module.ts` | Replace `ConfigModule.forRoot()` with custom `AppConfigModule` |
| `server/src/main.api.ts` | Use `ConfigService` instead of `process.env` |
| `server/src/main.worker.ts` | Use `ConfigService` instead of `process.env` |
| `server/src/main.scheduler.ts` | Use `ConfigService` instead of `process.env` |
| `server/package.json` | Add `zod` if not already present |
| `BACKEND_ARCHITECTURE.md` | Document configuration strategy |

## Service Interfaces (TypeScript)

### IConfigService Interface

```typescript
// server/src/config/config.service.ts

export interface IConfigService {
  // Application
  get nodeEnv(): NodeEnv;
  get port(): number;
  get apiPrefix(): string;
  get isProduction(): boolean;
  get isDevelopment(): boolean;
  get isTest(): boolean;

  // Database
  get database(): DatabaseConfig;
  
  // Redis
  get redis(): RedisConfig;
  
  // AWS
  get aws(): AwsConfig;
  
  // SMS
  get sms(): SmsConfig;
  
  // Security
  get jwt(): JwtConfig;
  get cors(): CorsConfig;
  get rateLimit(): RateLimitConfig;
  
  // Features
  get features(): FeatureFlags;
  
  // Generic typed getter
  get<T>(key: ConfigKey): T;
  
  // Get with fallback
  getOrDefault<T>(key: ConfigKey, defaultValue: T): T;
  
  // Get masked value (for logging)
  getMasked(key: ConfigKey): string;
  
  // Get all config (with secrets masked)
  getAll(): MaskedConfig;
  
  // Validate config matches expected shape
  validate(): ValidationResult;
}
```

### Configuration Type Definitions

```typescript
// server/src/config/config.types.ts

export enum NodeEnv {
  Development = 'development',
  Test = 'test',
  Staging = 'staging',
  Production = 'production',
}

export interface DatabaseConfig {
  host: string;
  port: number;
  name: string;
  user: string;
  password: string;
  ssl: boolean;
  maxConnections: number;
  idleTimeoutMs: number;
  connectionTimeoutMs: number;
  statementTimeoutMs: number;
  schema: string;
}

export interface RedisConfig {
  host: string;
  port: number;
  password?: string;
  db: number;
  keyPrefix: string;
  tls: boolean;
}

export interface AwsConfig {
  region: string;
  accessKeyId: string;
  secretAccessKey: string;
  s3: {
    bucket: string;
    region: string;
    presignedUrlExpirySeconds: number;
  };
  cloudfront: {
    domain: string;
    keyPairId?: string;
    privateKey?: string;
  };
}

export interface SmsConfig {
  provider: 'msg91' | 'twilio' | 'mock';
  apiKey: string;
  senderId: string;
  templateId: string;
  otpLength: number;
  otpExpirySeconds: number;
  maxAttemptsPerHour: number;
}

export interface JwtConfig {
  accessTokenSecret: string;
  refreshTokenSecret: string;
  accessTokenExpirySeconds: number;
  refreshTokenExpirySeconds: number;
  issuer: string;
  audience: string;
}

export interface CorsConfig {
  origins: string[];
  credentials: boolean;
  methods: string[];
  allowedHeaders: string[];
  exposedHeaders: string[];
  maxAge: number;
}

export interface RateLimitConfig {
  windowMs: number;
  max: number;
  message: string;
  skipSuccessfulRequests: boolean;
  trustProxy: boolean;
}

export interface FeatureFlags {
  enableAiOcr: boolean;
  enableLlmSummaries: boolean;
  enableAwsRekognition: boolean;
  enableOfflineSync: boolean;
  enableSubscriptions: boolean;
  enableOwnerDashboard: boolean;
  enableMarketingWebsite: boolean;
}

export interface MaskedConfig {
  [key: string]: string | number | boolean | MaskedConfig;
}

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
}

export interface ValidationError {
  variable: string;
  message: string;
  received?: string;
  expected: string;
}

export type ConfigKey = 
  | 'NODE_ENV'
  | 'PORT'
  | 'DB_HOST'
  | 'DB_PORT'
  // ... all other keys
  ;
```

## Implementation Code

### 1. Environment Schema (Zod)

```typescript
// server/src/config/env.schema.ts
import { z } from 'zod';

export const NodeEnvSchema = z.enum([
  'development',
  'test',
  'staging',
  'production',
]);

export const EnvSchema = z.object({
  // Application
  NODE_ENV: NodeEnvSchema.default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  API_PREFIX: z.string().min(1).default('api'),
  APP_NAME: z.string().default('RADHA'),
  APP_VERSION: z.string().default('1.0.0'),

  // Database
  DB_HOST: z.string().min(1, 'DB_HOST is required'),
  DB_PORT: z.coerce.number().int().min(1).max(65535).default(5432),
  DB_NAME: z.string().min(1, 'DB_NAME is required'),
  DB_USER: z.string().min(1, 'DB_USER is required'),
  DB_PASSWORD: z.string().min(1, 'DB_PASSWORD is required'),
  DB_SSL: z.coerce.boolean().default(false),
  DB_SCHEMA: z.string().default('public'),
  DB_MAX_CONNECTIONS: z.coerce.number().int().min(1).max(100).default(20),
  DB_IDLE_TIMEOUT_MS: z.coerce.number().int().default(30000),
  DB_CONNECTION_TIMEOUT_MS: z.coerce.number().int().default(5000),
  DB_STATEMENT_TIMEOUT_MS: z.coerce.number().int().default(30000),

  // Redis
  REDIS_HOST: z.string().min(1).default('localhost'),
  REDIS_PORT: z.coerce.number().int().min(1).max(65535).default(6379),
  REDIS_PASSWORD: z.string().optional(),
  REDIS_DB: z.coerce.number().int().min(0).max(15).default(0),
  REDIS_KEY_PREFIX: z.string().default('radha:'),
  REDIS_TLS: z.coerce.boolean().default(false),

  // AWS
  AWS_REGION: z.string().min(1).default('ap-south-1'),
  AWS_ACCESS_KEY_ID: z.string().min(1, 'AWS_ACCESS_KEY_ID is required'),
  AWS_SECRET_ACCESS_KEY: z.string().min(1, 'AWS_SECRET_ACCESS_KEY is required'),
  AWS_S3_BUCKET: z.string().min(1, 'AWS_S3_BUCKET is required'),
  AWS_S3_REGION: z.string().default('ap-south-1'),
  AWS_S3_PRESIGNED_EXPIRY_SECONDS: z.coerce.number().int().default(600),
  AWS_CLOUDFRONT_DOMAIN: z.string().optional(),
  AWS_CLOUDFRONT_KEY_PAIR_ID: z.string().optional(),
  AWS_CLOUDFRONT_PRIVATE_KEY: z.string().optional(),

  // SMS (MSG91)
  SMS_PROVIDER: z.enum(['msg91', 'twilio', 'mock']).default('msg91'),
  MSG91_API_KEY: z.string().min(1, 'MSG91_API_KEY is required'),
  MSG91_SENDER_ID: z.string().length(6, 'MSG91 sender ID must be 6 chars').default('RADHA1'),
  MSG91_TEMPLATE_ID: z.string().min(1, 'MSG91_TEMPLATE_ID is required'),
  OTP_LENGTH: z.coerce.number().int().min(4).max(8).default(6),
  OTP_EXPIRY_SECONDS: z.coerce.number().int().default(600),
  OTP_MAX_ATTEMPTS_PER_HOUR: z.coerce.number().int().default(3),

  // JWT
  JWT_ACCESS_SECRET: z.string().min(32, 'JWT_ACCESS_SECRET must be at least 32 chars'),
  JWT_REFRESH_SECRET: z.string().min(32, 'JWT_REFRESH_SECRET must be at least 32 chars'),
  JWT_ACCESS_EXPIRY_SECONDS: z.coerce.number().int().default(1800), // 30 minutes
  JWT_REFRESH_EXPIRY_SECONDS: z.coerce.number().int().default(2592000), // 30 days
  JWT_ISSUER: z.string().default('radha-platform'),
  JWT_AUDIENCE: z.string().default('radha-clients'),

  // CORS
  CORS_ORIGINS: z.string()
    .default('http://localhost:3000')
    .transform((val) => val.split(',').map(s => s.trim())),
  CORS_CREDENTIALS: z.coerce.boolean().default(true),
  CORS_MAX_AGE: z.coerce.number().int().default(86400),

  // Rate Limiting
  RATE_LIMIT_WINDOW_MS: z.coerce.number().int().default(60000),
  RATE_LIMIT_MAX: z.coerce.number().int().default(100),
  RATE_LIMIT_TRUST_PROXY: z.coerce.boolean().default(false),

  // Feature Flags
  FEATURE_AI_OCR: z.coerce.boolean().default(true),
  FEATURE_LLM_SUMMARIES: z.coerce.boolean().default(false),
  FEATURE_AWS_REKOGNITION: z.coerce.boolean().default(false),
  FEATURE_OFFLINE_SYNC: z.coerce.boolean().default(true),
  FEATURE_SUBSCRIPTIONS: z.coerce.boolean().default(true),
  FEATURE_OWNER_DASHBOARD: z.coerce.boolean().default(true),
  FEATURE_MARKETING_WEBSITE: z.coerce.boolean().default(true),

  // Logging
  LOG_LEVEL: z.enum(['error', 'warn', 'info', 'debug', 'verbose']).default('info'),
  LOG_FORMAT: z.enum(['json', 'pretty']).default('json'),
  LOG_REDACT_KEYS: z.string()
    .default('password,secret,token,key,authorization')
    .transform((val) => val.split(',').map(s => s.trim())),
});

// Production-specific stricter schema
export const ProductionEnvSchema = EnvSchema.extend({
  CORS_ORIGINS: z.string()
    .refine((val) => !val.includes('*'), 'CORS_ORIGINS cannot include "*" in production')
    .transform((val) => val.split(',').map(s => s.trim())),
  DB_SSL: z.coerce.boolean().refine(val => val === true, 'DB_SSL must be true in production'),
  DB_PASSWORD: z.string().min(16, 'DB_PASSWORD must be at least 16 chars in production'),
  JWT_ACCESS_SECRET: z.string().min(64, 'JWT_ACCESS_SECRET must be at least 64 chars in production'),
  JWT_REFRESH_SECRET: z.string().min(64, 'JWT_REFRESH_SECRET must be at least 64 chars in production'),
});

export type Env = z.infer<typeof EnvSchema>;
export type ProductionEnv = z.infer<typeof ProductionEnvSchema>;
```

### 2. Validation Function

```typescript
// server/src/config/env.validation.ts
import { EnvSchema, ProductionEnvSchema, Env } from './env.schema';
import { z } from 'zod';

export function validateEnv(config: Record<string, unknown>): Env {
  const nodeEnv = config.NODE_ENV || 'development';
  
  // Use stricter schema in production
  const schema = nodeEnv === 'production' ? ProductionEnvSchema : EnvSchema;
  
  const result = schema.safeParse(config);
  
  if (!result.success) {
    const errors = result.error.errors.map(err => ({
      variable: err.path.join('.'),
      message: err.message,
      received: config[err.path[0]] as string,
      expected: err.code,
    }));
    
    console.error('❌ Environment validation failed:');
    errors.forEach(err => {
      console.error(`  - ${err.variable}: ${err.message}`);
    });
    
    throw new Error(
      `Environment validation failed with ${errors.length} error(s). ` +
      `See logs above for details.`
    );
  }
  
  return result.data;
}

export function validateOrThrow(config: Record<string, unknown>): Env {
  try {
    return validateEnv(config);
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(`Configuration error: ${error.message}`);
    }
    throw error;
  }
}
```

### 3. ConfigService Implementation

```typescript
// server/src/config/config.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService as NestConfigService } from '@nestjs/config';
import { Env } from './env.schema';
import {
  IConfigService,
  NodeEnv,
  DatabaseConfig,
  RedisConfig,
  AwsConfig,
  SmsConfig,
  JwtConfig,
  CorsConfig,
  RateLimitConfig,
  FeatureFlags,
  MaskedConfig,
  ValidationResult,
  ConfigKey,
} from './config.types';
import { maskSecret, isSecretKey } from './secrets.utils';

@Injectable()
export class ConfigService implements IConfigService {
  private readonly logger = new Logger(ConfigService.name);
  
  constructor(private readonly nestConfig: NestConfigService<Env, true>) {
    this.logger.log(`Configuration loaded for environment: ${this.nodeEnv}`);
  }

  // Application
  get nodeEnv(): NodeEnv {
    return this.nestConfig.get('NODE_ENV', { infer: true }) as NodeEnv;
  }

  get port(): number {
    return this.nestConfig.get('PORT', { infer: true });
  }

  get apiPrefix(): string {
    return this.nestConfig.get('API_PREFIX', { infer: true });
  }

  get isProduction(): boolean {
    return this.nodeEnv === NodeEnv.Production;
  }

  get isDevelopment(): boolean {
    return this.nodeEnv === NodeEnv.Development;
  }

  get isTest(): boolean {
    return this.nodeEnv === NodeEnv.Test;
  }

  // Database
  get database(): DatabaseConfig {
    return {
      host: this.nestConfig.get('DB_HOST', { infer: true }),
      port: this.nestConfig.get('DB_PORT', { infer: true }),
      name: this.nestConfig.get('DB_NAME', { infer: true }),
      user: this.nestConfig.get('DB_USER', { infer: true }),
      password: this.nestConfig.get('DB_PASSWORD', { infer: true }),
      ssl: this.nestConfig.get('DB_SSL', { infer: true }),
      schema: this.nestConfig.get('DB_SCHEMA', { infer: true }),
      maxConnections: this.nestConfig.get('DB_MAX_CONNECTIONS', { infer: true }),
      idleTimeoutMs: this.nestConfig.get('DB_IDLE_TIMEOUT_MS', { infer: true }),
      connectionTimeoutMs: this.nestConfig.get('DB_CONNECTION_TIMEOUT_MS', { infer: true }),
      statementTimeoutMs: this.nestConfig.get('DB_STATEMENT_TIMEOUT_MS', { infer: true }),
    };
  }

  // Redis
  get redis(): RedisConfig {
    return {
      host: this.nestConfig.get('REDIS_HOST', { infer: true }),
      port: this.nestConfig.get('REDIS_PORT', { infer: true }),
      password: this.nestConfig.get('REDIS_PASSWORD', { infer: true }),
      db: this.nestConfig.get('REDIS_DB', { infer: true }),
      keyPrefix: this.nestConfig.get('REDIS_KEY_PREFIX', { infer: true }),
      tls: this.nestConfig.get('REDIS_TLS', { infer: true }),
    };
  }

  // AWS
  get aws(): AwsConfig {
    return {
      region: this.nestConfig.get('AWS_REGION', { infer: true }),
      accessKeyId: this.nestConfig.get('AWS_ACCESS_KEY_ID', { infer: true }),
      secretAccessKey: this.nestConfig.get('AWS_SECRET_ACCESS_KEY', { infer: true }),
      s3: {
        bucket: this.nestConfig.get('AWS_S3_BUCKET', { infer: true }),
        region: this.nestConfig.get('AWS_S3_REGION', { infer: true }),
        presignedUrlExpirySeconds: this.nestConfig.get('AWS_S3_PRESIGNED_EXPIRY_SECONDS', { infer: true }),
      },
      cloudfront: {
        domain: this.nestConfig.get('AWS_CLOUDFRONT_DOMAIN', { infer: true }) || '',
        keyPairId: this.nestConfig.get('AWS_CLOUDFRONT_KEY_PAIR_ID', { infer: true }),
        privateKey: this.nestConfig.get('AWS_CLOUDFRONT_PRIVATE_KEY', { infer: true }),
      },
    };
  }

  // SMS
  get sms(): SmsConfig {
    return {
      provider: this.nestConfig.get('SMS_PROVIDER', { infer: true }),
      apiKey: this.nestConfig.get('MSG91_API_KEY', { infer: true }),
      senderId: this.nestConfig.get('MSG91_SENDER_ID', { infer: true }),
      templateId: this.nestConfig.get('MSG91_TEMPLATE_ID', { infer: true }),
      otpLength: this.nestConfig.get('OTP_LENGTH', { infer: true }),
      otpExpirySeconds: this.nestConfig.get('OTP_EXPIRY_SECONDS', { infer: true }),
      maxAttemptsPerHour: this.nestConfig.get('OTP_MAX_ATTEMPTS_PER_HOUR', { infer: true }),
    };
  }

  // JWT
  get jwt(): JwtConfig {
    return {
      accessTokenSecret: this.nestConfig.get('JWT_ACCESS_SECRET', { infer: true }),
      refreshTokenSecret: this.nestConfig.get('JWT_REFRESH_SECRET', { infer: true }),
      accessTokenExpirySeconds: this.nestConfig.get('JWT_ACCESS_EXPIRY_SECONDS', { infer: true }),
      refreshTokenExpirySeconds: this.nestConfig.get('JWT_REFRESH_EXPIRY_SECONDS', { infer: true }),
      issuer: this.nestConfig.get('JWT_ISSUER', { infer: true }),
      audience: this.nestConfig.get('JWT_AUDIENCE', { infer: true }),
    };
  }

  // CORS
  get cors(): CorsConfig {
    return {
      origins: this.nestConfig.get('CORS_ORIGINS', { infer: true }) as unknown as string[],
      credentials: this.nestConfig.get('CORS_CREDENTIALS', { infer: true }),
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-Id'],
      exposedHeaders: ['X-Request-Id', 'X-Total-Count'],
      maxAge: this.nestConfig.get('CORS_MAX_AGE', { infer: true }),
    };
  }

  // Rate Limit
  get rateLimit(): RateLimitConfig {
    return {
      windowMs: this.nestConfig.get('RATE_LIMIT_WINDOW_MS', { infer: true }),
      max: this.nestConfig.get('RATE_LIMIT_MAX', { infer: true }),
      message: 'Too many requests, please try again later.',
      skipSuccessfulRequests: false,
      trustProxy: this.nestConfig.get('RATE_LIMIT_TRUST_PROXY', { infer: true }),
    };
  }

  // Feature Flags
  get features(): FeatureFlags {
    return {
      enableAiOcr: this.nestConfig.get('FEATURE_AI_OCR', { infer: true }),
      enableLlmSummaries: this.nestConfig.get('FEATURE_LLM_SUMMARIES', { infer: true }),
      enableAwsRekognition: this.nestConfig.get('FEATURE_AWS_REKOGNITION', { infer: true }),
      enableOfflineSync: this.nestConfig.get('FEATURE_OFFLINE_SYNC', { infer: true }),
      enableSubscriptions: this.nestConfig.get('FEATURE_SUBSCRIPTIONS', { infer: true }),
      enableOwnerDashboard: this.nestConfig.get('FEATURE_OWNER_DASHBOARD', { infer: true }),
      enableMarketingWebsite: this.nestConfig.get('FEATURE_MARKETING_WEBSITE', { infer: true }),
    };
  }

  // Generic typed getter
  get<T>(key: ConfigKey): T {
    return this.nestConfig.get(key, { infer: true }) as T;
  }

  getOrDefault<T>(key: ConfigKey, defaultValue: T): T {
    const value = this.nestConfig.get(key, { infer: true });
    return value !== undefined ? (value as T) : defaultValue;
  }

  getMasked(key: ConfigKey): string {
    const value = this.nestConfig.get(key, { infer: true });
    if (value === undefined || value === null) return '<undefined>';
    if (isSecretKey(key)) return maskSecret(String(value));
    return String(value);
  }

  getAll(): MaskedConfig {
    const result: MaskedConfig = {};
    const allConfig = process.env;
    
    for (const key of Object.keys(allConfig)) {
      const value = allConfig[key];
      if (value === undefined) continue;
      result[key] = isSecretKey(key) ? maskSecret(value) : value;
    }
    
    return result;
  }

  validate(): ValidationResult {
    return { valid: true, errors: [] };
  }
}
```

### 4. Secrets Utilities

```typescript
// server/src/config/secrets.utils.ts

const SECRET_KEY_PATTERNS = [
  /password/i,
  /secret/i,
  /token/i,
  /api_key/i,
  /private_key/i,
  /access_key/i,
  /credential/i,
];

export function isSecretKey(key: string): boolean {
  return SECRET_KEY_PATTERNS.some(pattern => pattern.test(key));
}

export function maskSecret(value: string): string {
  if (!value || value.length === 0) return '<empty>';
  if (value.length <= 4) return '****';
  if (value.length <= 8) return value.slice(0, 2) + '****';
  return value.slice(0, 4) + '****' + value.slice(-2);
}

export function maskObject<T extends Record<string, unknown>>(obj: T): T {
  const result = { ...obj };
  for (const key of Object.keys(result)) {
    if (isSecretKey(key) && typeof result[key] === 'string') {
      (result as Record<string, unknown>)[key] = maskSecret(result[key] as string);
    } else if (typeof result[key] === 'object' && result[key] !== null) {
      (result as Record<string, unknown>)[key] = maskObject(result[key] as Record<string, unknown>);
    }
  }
  return result;
}
```

### 5. Custom Config Module

```typescript
// server/src/config/config.module.ts
import { Module, Global } from '@nestjs/common';
import { ConfigModule as NestConfigModule } from '@nestjs/config';
import { ConfigService } from './config.service';
import { validateEnv } from './env.validation';

@Global()
@Module({
  imports: [
    NestConfigModule.forRoot({
      isGlobal: true,
      envFilePath: [
        '.env.local',
        `.env.${process.env.NODE_ENV || 'development'}`,
        '.env',
      ],
      validate: validateEnv,
      cache: true,
      expandVariables: true,
    }),
  ],
  providers: [ConfigService],
  exports: [ConfigService],
})
export class AppConfigModule {}
```

## DTOs & Validation Schemas

This phase IS the validation layer foundation. All Zod schemas are in `env.schema.ts` above.

## Database Integration

**No database operations in this phase.** Database connection comes in BE-05.

## API Endpoints

**No new endpoints in this phase.** ConfigService is internal infrastructure.

However, this phase adds:
- `GET /api/v1/health/config` (development only) — Returns masked config

```typescript
// server/src/health/config-health.controller.ts
@Controller('health/config')
export class ConfigHealthController {
  constructor(private readonly config: ConfigService) {}

  @Get()
  getMaskedConfig() {
    if (this.config.isProduction) {
      throw new ForbiddenException('Config endpoint disabled in production');
    }
    return this.config.getAll();
  }
}
```

## Tests

### Unit Tests

```typescript
// server/src/config/__tests__/env.validation.spec.ts
import { validateEnv } from '../env.validation';

describe('validateEnv', () => {
  const validConfig = {
    NODE_ENV: 'development',
    DB_HOST: 'localhost',
    DB_NAME: 'radha_test',
    DB_USER: 'postgres',
    DB_PASSWORD: 'password123',
    AWS_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
    AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    AWS_S3_BUCKET: 'radha-test',
    MSG91_API_KEY: 'test-key',
    MSG91_TEMPLATE_ID: 'template-1',
    JWT_ACCESS_SECRET: 'a'.repeat(32),
    JWT_REFRESH_SECRET: 'b'.repeat(32),
  };

  it('should validate valid configuration', () => {
    const result = validateEnv(validConfig);
    expect(result.NODE_ENV).toBe('development');
    expect(result.PORT).toBe(3000); // default
  });

  it('should fail when DB_HOST is missing', () => {
    const config = { ...validConfig };
    delete (config as Partial<typeof validConfig>).DB_HOST;
    expect(() => validateEnv(config)).toThrow(/DB_HOST is required/);
  });

  it('should coerce string numbers to numbers', () => {
    const result = validateEnv({ ...validConfig, PORT: '4000' });
    expect(result.PORT).toBe(4000);
    expect(typeof result.PORT).toBe('number');
  });

  it('should fail when port is out of range', () => {
    expect(() => validateEnv({ ...validConfig, PORT: '70000' })).toThrow();
  });

  it('should enforce stricter rules in production', () => {
    expect(() => validateEnv({
      ...validConfig,
      NODE_ENV: 'production',
      DB_SSL: 'false',
    })).toThrow(/DB_SSL must be true in production/);
  });

  it('should reject CORS wildcards in production', () => {
    expect(() => validateEnv({
      ...validConfig,
      NODE_ENV: 'production',
      DB_SSL: 'true',
      DB_PASSWORD: 'a'.repeat(20),
      JWT_ACCESS_SECRET: 'a'.repeat(64),
      JWT_REFRESH_SECRET: 'b'.repeat(64),
      CORS_ORIGINS: 'https://example.com,*',
    })).toThrow(/CORS_ORIGINS cannot include "\*" in production/);
  });

  it('should split CORS_ORIGINS by comma', () => {
    const result = validateEnv({
      ...validConfig,
      CORS_ORIGINS: 'http://a.com,http://b.com',
    });
    expect(result.CORS_ORIGINS).toEqual(['http://a.com', 'http://b.com']);
  });
});
```

### ConfigService Tests

```typescript
// server/src/config/__tests__/config.service.spec.ts
import { Test } from '@nestjs/testing';
import { ConfigService as NestConfigService } from '@nestjs/config';
import { ConfigService } from '../config.service';

describe('ConfigService', () => {
  let service: ConfigService;
  let nestConfig: NestConfigService;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        ConfigService,
        {
          provide: NestConfigService,
          useValue: {
            get: jest.fn((key) => mockEnv[key]),
          },
        },
      ],
    }).compile();

    service = module.get(ConfigService);
    nestConfig = module.get(NestConfigService);
  });

  describe('database config', () => {
    it('should return database configuration', () => {
      const db = service.database;
      expect(db.host).toBe('localhost');
      expect(db.port).toBe(5432);
      expect(db.maxConnections).toBe(20);
    });
  });

  describe('isProduction', () => {
    it('should return true when NODE_ENV is production', () => {
      jest.spyOn(nestConfig, 'get').mockReturnValue('production');
      expect(service.isProduction).toBe(true);
    });
  });

  describe('getMasked', () => {
    it('should mask secret values', () => {
      jest.spyOn(nestConfig, 'get').mockReturnValue('super-secret-key-12345');
      const masked = service.getMasked('JWT_ACCESS_SECRET');
      expect(masked).toMatch(/^sup\*+45$/);
    });
  });
});
```

## Commands to Run

```bash
# Install Zod (if not already)
cd server
pnpm add zod

# Run tests
pnpm test src/config

# Run validation manually
NODE_ENV=development pnpm start:dev

# Test with bad config (should fail fast)
DB_HOST="" pnpm start:dev

# Test with production config
NODE_ENV=production pnpm start:prod
```

## Environment Variables

See `.env.example` and `env.schema.ts` for the complete list. Key categories:

- **Application**: NODE_ENV, PORT, API_PREFIX
- **Database**: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, DB_SSL, etc.
- **Redis**: REDIS_HOST, REDIS_PORT, REDIS_PASSWORD
- **AWS**: AWS_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_S3_BUCKET
- **SMS**: MSG91_API_KEY, MSG91_SENDER_ID, MSG91_TEMPLATE_ID
- **JWT**: JWT_ACCESS_SECRET, JWT_REFRESH_SECRET
- **CORS**: CORS_ORIGINS, CORS_CREDENTIALS
- **Rate Limit**: RATE_LIMIT_WINDOW_MS, RATE_LIMIT_MAX
- **Features**: FEATURE_AI_OCR, FEATURE_LLM_SUMMARIES, etc.

## Validation Checklist

- [ ] `pnpm install` adds `zod` successfully
- [ ] `EnvSchema` validates a valid config without errors
- [ ] `EnvSchema` rejects missing required variables
- [ ] `ProductionEnvSchema` enforces stricter rules
- [ ] `ConfigService` provides typed access to all config
- [ ] `ConfigService.isProduction` works correctly
- [ ] Secret values are masked in `getMasked()` output
- [ ] All env vars documented in `.env.example`
- [ ] Production-specific defaults in `.env.production.example`
- [ ] Development defaults in `.env.development.example`
- [ ] Boot fails fast with clear error on invalid config
- [ ] CORS origins parsed correctly from comma-separated string
- [ ] Numbers coerced from strings
- [ ] Booleans coerced from strings
- [ ] All unit tests pass
- [ ] No `process.env` access remains in `main.api.ts`
- [ ] No `process.env` access remains in `main.worker.ts`
- [ ] Health check `/health/config` works in dev
- [ ] Health check `/health/config` returns 403 in production
- [ ] TypeScript shows correct types when using `ConfigService`

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|---|---|---|---|
| Schema changes break existing code | High | Medium | Add type tests, run full test suite |
| Production secrets logged accidentally | Critical | Low | Always use `getMasked()` for logs |
| Default values mask real bugs | Medium | Medium | Require explicit values in production |
| Test environment leaks real secrets | High | Low | Use `.env.test` with mock values |
| Boot fails in production due to strict rules | High | Medium | Test with production env in staging |
| Schema doesn't match runtime behavior | Medium | Low | Sync schema with consumers regularly |

## Performance Benchmarks

- **Config validation time**: < 50ms at boot
- **ConfigService access time**: < 1µs (cached)
- **Memory overhead**: < 5MB for all config
- **Boot time impact**: < 100ms additional

## Security Considerations

### Threats Addressed

1. **Secret leakage in logs**: All secrets masked via `maskSecret()`
2. **Insecure defaults in production**: ProductionEnvSchema enforces strict rules
3. **CORS misconfiguration**: Wildcards rejected in production
4. **Weak JWT secrets**: Minimum 64 chars in production
5. **Plaintext database passwords**: Minimum 16 chars in production
6. **Disabled SSL in production**: DB_SSL must be true

### Threats Not Yet Addressed

- **Secret rotation**: Manual process (BE-31 will add automation)
- **Secret storage**: .env files (production should use AWS Secrets Manager)
- **Access control on config endpoint**: Only environment-based (BE-08 will add auth)

## Completion Criteria

- [ ] All files in "Files to Create" exist
- [ ] All files in "Files to Modify" updated
- [ ] `pnpm test src/config` passes 100%
- [ ] `pnpm start:dev` starts with valid config
- [ ] App fails fast with invalid config
- [ ] `process.env` not used directly anywhere in `src/`
- [ ] All env vars documented
- [ ] Production env example provided
- [ ] Secrets are masked in all logs
- [ ] Schema versioning documented
- [ ] BE-02 handoff file completed

## Next Phase

**BE-03: Global Middleware & Request Context** — Add request ID middleware, global exception filter, request/response logging, CORS, Helmet, compression, and validation pipes.

---

## Implementation Notes

### When to Use Each Method

- **`config.database.host`**: For typed access to known config sections
- **`config.get<string>('CUSTOM_KEY')`**: For dynamic keys
- **`config.getOrDefault('KEY', 'default')`**: When defaults are acceptable
- **`config.getMasked('SECRET_KEY')`**: For logging
- **`config.isProduction`**: For conditional behavior

### Best Practices

1. **Never log raw config**: Always use `getMasked()` or `maskObject()`
2. **Inject ConfigService**: Don't create new instances
3. **Use typed getters**: Prefer `config.database` over `config.get('DB_HOST')`
4. **Validate at boot**: Don't validate at runtime
5. **Test with mock config**: Don't rely on real env vars in tests


---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-03 Until This Section is Complete

## 📋 Pre-Test Setup

```bash
cd server
pnpm install
# Verify zod is installed
pnpm list zod
# Expected: zod 3.22.4 or higher
```

## 🧪 Test Procedures

### Test 1: Valid Configuration Boot ✅

```bash
# Set up valid .env
cd server
cp .env.example .env.local

# Edit .env.local with test values:
# DB_HOST=localhost
# DB_NAME=radha_dev
# DB_USER=postgres
# DB_PASSWORD=postgres
# AWS_ACCESS_KEY_ID=test-key
# AWS_SECRET_ACCESS_KEY=test-secret
# AWS_S3_BUCKET=test-bucket
# MSG91_API_KEY=test-key
# MSG91_TEMPLATE_ID=test-template
# JWT_ACCESS_SECRET=$(openssl rand -base64 32)
# JWT_REFRESH_SECRET=$(openssl rand -base64 32)

pnpm start:dev
```

**Expected Output**:
```
[ConfigService] Configuration loaded for environment: development
🚀 RADHA API Server running on: http://localhost:3000
```

**Pass Criteria**: ✅ Server starts, no validation errors

---

### Test 2: Missing Required Variable ✅

```bash
# Remove DB_HOST temporarily
DB_HOST="" pnpm start:dev
```

**Expected Output**:
```
❌ Environment validation failed:
  - DB_HOST: DB_HOST is required
Error: Environment validation failed with 1 error(s)
```

**Pass Criteria**: ✅ Server fails to start with clear error message

---

### Test 3: Invalid Type Coercion ✅

```bash
PORT="not-a-number" pnpm start:dev
```

**Expected Output**:
```
❌ Environment validation failed:
  - PORT: Expected number, received nan
```

**Pass Criteria**: ✅ Boot fails with type error

---

### Test 4: Production Schema Enforcement ✅

```bash
# Try to start with production env but weak settings
NODE_ENV=production \
DB_SSL=false \
JWT_ACCESS_SECRET="short" \
pnpm start
```

**Expected Output**:
```
❌ Environment validation failed:
  - DB_SSL: DB_SSL must be true in production
  - JWT_ACCESS_SECRET: JWT_ACCESS_SECRET must be at least 64 chars in production
```

**Pass Criteria**: ✅ Production schema rejects weak settings

---

### Test 5: CORS Wildcard Rejection in Production ✅

```bash
NODE_ENV=production \
DB_SSL=true \
DB_PASSWORD="long-enough-password-12345" \
JWT_ACCESS_SECRET="$(openssl rand -base64 64)" \
JWT_REFRESH_SECRET="$(openssl rand -base64 64)" \
CORS_ORIGINS="https://example.com,*" \
pnpm start
```

**Expected Output**:
```
❌ Environment validation failed:
  - CORS_ORIGINS: CORS_ORIGINS cannot include "*" in production
```

**Pass Criteria**: ✅ Wildcard CORS rejected

---

### Test 6: ConfigService Typed Access ✅

```bash
pnpm test src/config
```

**Expected Output**:
```
PASS  src/config/__tests__/env.validation.spec.ts
PASS  src/config/__tests__/config.service.spec.ts
PASS  src/config/__tests__/secrets.utils.spec.ts

Test Suites: 3 passed
Tests: 30+ passed
Coverage: > 90%
```

**Pass Criteria**: ✅ All config tests pass with >90% coverage

---

### Test 7: Secret Masking ✅

Start server and check logs:
```bash
pnpm start:dev | grep -i "secret\|password\|key"
```

**Expected Behavior**:
- No raw secrets visible in logs
- Masked values shown as `xxxx****xx` pattern
- Or `[REDACTED]` for sensitive fields

**Pass Criteria**: ✅ NO plain-text secrets in logs

---

### Test 8: Config Health Endpoint (Dev Only) ✅

With server running:
```bash
curl http://localhost:3000/api/v1/health/config
```

**Expected Response (Dev)**:
```json
{
  "NODE_ENV": "development",
  "DB_HOST": "localhost",
  "DB_PASSWORD": "post****es",
  "JWT_ACCESS_SECRET": "abc1****xyz"
}
```

**Pass Criteria**: ✅ Returns masked config in dev

---

### Test 9: Config Health Endpoint Blocked in Production ✅

```bash
NODE_ENV=production pnpm start
curl http://localhost:3000/api/v1/health/config
```

**Expected Response**: `403 Forbidden`

**Pass Criteria**: ✅ Endpoint disabled in production

---

### Test 10: process.env Removal Verification ✅

```bash
# Search for direct process.env usage in src/
grep -r "process.env" server/src/ --exclude-dir=node_modules
```

**Expected Output**: ONLY in `config/` files (acceptable). NO `process.env` in any other file.

**Pass Criteria**: ✅ No `process.env` outside config module

---

## 🎯 Q&A Session

### Q1: Why Zod over Joi or class-validator?

**Expected Answer**:
- Better TypeScript inference (auto-generates types from schema)
- Smaller bundle size
- More expressive API
- Schema and types stay in sync (single source of truth)
- `class-validator` requires decorators which complicates plain config objects

**Developer's Answer**: _________________________________

---

### Q2: Why two separate schemas (EnvSchema + ProductionEnvSchema)?

**Expected Answer**:
- Production has stricter security requirements (longer secrets, SSL enforced)
- Cleaner code than conditional `.refine()` based on NODE_ENV
- Better error messages specific to environment
- Allows dev to be permissive (faster local iteration)
- Forces explicit thought about prod requirements

**Developer's Answer**: _________________________________

---

### Q3: How does `coerce` work in Zod?

**Expected Answer**:
- Environment variables are ALWAYS strings
- `z.coerce.number()` converts "3000" → 3000
- `z.coerce.boolean()` converts "true"/"false" → true/false
- Without coercion, validation would fail because env vars are strings
- Coercion happens before validation

**Developer's Answer**: _________________________________

---

### Q4: Why mask secrets but still allow access?

**Expected Answer**:
- Application code needs the actual values to work (DB connection, API calls)
- Logs/error messages should NEVER expose secrets
- `getMasked()` is for safe logging only
- `database.password` returns plain value for actual DB connection
- Two methods serve different purposes

**Developer's Answer**: _________________________________

---

### Q5: What happens if config validation fails at boot?

**Expected Answer**:
- App throws error BEFORE starting HTTP server
- Process exits with code 1
- Error message lists ALL invalid variables
- Production deployments will fail health checks
- Container restarts (Kubernetes/ECS) will detect failure

**Developer's Answer**: _________________________________

---

### Q6: Why `@Global()` on AppConfigModule?

**Expected Answer**:
- ConfigService used in EVERY module
- Without `@Global()`, must import ConfigModule in every feature module
- `@Global()` makes ConfigService available everywhere via DI
- Used for cross-cutting concerns only (config, logging, etc.)
- Don't overuse — most modules should be feature-scoped

**Developer's Answer**: _________________________________

---

### Q7: How would you add a new environment variable?

**Expected Answer**:
1. Add to `EnvSchema` in `env.schema.ts` with appropriate Zod validator
2. Add to `ProductionEnvSchema` if stricter rules needed
3. Add to `.env.example` with documentation
4. Add to `.env.development.example` with default
5. Add typed getter to `ConfigService` if commonly accessed
6. Update tests to cover new variable
7. Document in BACKEND_ARCHITECTURE.md

**Developer's Answer**: _________________________________

---

### Q8: What's the danger of caching config in `ConfigModule.forRoot({ cache: true })`?

**Expected Answer**:
- Config is loaded once at startup, not re-read
- Changes to .env require restart
- Better performance (no repeated env access)
- Safe because config shouldn't change at runtime
- Hot-reload would require explicit invalidation

**Developer's Answer**: _________________________________

---

## 📝 Sign-Off Checklist (Developer)

### Code Quality
- [ ] Zod schemas defined for ALL env vars (50+)
- [ ] Production schema has stricter rules
- [ ] No `process.env` outside config module
- [ ] All config sections have typed getters
- [ ] Secret masking utility tested

### Functional Tests
- [ ] Valid config boots successfully
- [ ] Invalid config fails with clear errors
- [ ] Production schema enforces SSL, secret length, no CORS wildcards
- [ ] All 30+ unit tests pass
- [ ] Coverage > 90% for config module

### Security
- [ ] Secrets never appear in plain text in logs
- [ ] Config endpoint blocked in production (403)
- [ ] `.env.local` in `.gitignore`
- [ ] No real secrets committed

### Documentation
- [ ] All env vars documented in `.env.example`
- [ ] `BACKEND_ARCHITECTURE.md` updated
- [ ] BE-02_HANDOFF.md complete

**Developer Signature**: ___________________________
**Date**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-03**
**☐ CHANGES REQUESTED** (list below)

**Changes Required**:
1. _________________________________
2. _________________________________

**Reviewer Signature**: ___________________________
**Date**: ___________________________

---

## 🆘 Troubleshooting

### Issue: "ConfigService is not defined"
**Solution**: Verify `AppConfigModule` is imported in `AppModule`. Module must use `@Global()`.

### Issue: Type errors when accessing config
**Solution**: Use the typed getters (`config.database`, `config.aws`) instead of `config.get('KEY')`.

### Issue: Zod validation passes but values are strings
**Solution**: Use `z.coerce.number()` and `z.coerce.boolean()` for env vars (always strings).

### Issue: Production boot fails locally
**Solution**: Either set valid production values OR boot with `NODE_ENV=development`.

---

**END OF BE-02 — DO NOT PROCEED WITHOUT APPROVAL**
