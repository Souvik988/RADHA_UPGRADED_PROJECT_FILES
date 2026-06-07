# Phase BE-01: NestJS Backend Initialization

## Phase Overview

**Phase ID**: BE-01  
**Phase Name**: NestJS Backend Initialization  
**Section**: Backend Execution  
**Depends On**: PF-01, PF-02, PF-04, PF-05  
**Blocks**: BE-02, BE-03, BE-04  
**Estimated Duration**: 2-3 days  

## Goal

Create production-grade NestJS backend application with three separate entry points (API server, Worker process, Scheduler process), proper module structure, and foundational configuration that supports the entire RADHA platform.

## Why This Phase Matters

This phase establishes the architectural foundation for all backend work. Without proper initialization:
- Backend modules cannot be organized cleanly
- API/Worker/Scheduler processes cannot run independently
- Environment configuration will be inconsistent
- Module boundaries will be unclear
- Testing infrastructure will be fragile

A solid foundation here prevents architectural debt and enables parallel development of backend modules.

## Prerequisites

- [ ] PF-01: Architecture baseline completed
- [ ] PF-02: Repository structure created
- [ ] PF-04: Environment contract defined
- [ ] PF-05: Shared types package available
- [ ] Node.js 18+ installed
- [ ] pnpm 8+ installed

## Files to Create

| File Path | Purpose | Empty Initially? |
|---|---|---|
| `server/package.json` | Backend dependencies and scripts | No |
| `server/tsconfig.json` | TypeScript configuration | No |
| `server/nest-cli.json` | NestJS CLI configuration | No |
| `server/.eslintrc.js` | ESLint rules | No |
| `server/.prettierrc` | Prettier formatting | No |
| `server/src/main.api.ts` | API process entry point | No |
| `server/src/main.worker.ts` | Worker process entry point | No |
| `server/src/main.scheduler.ts` | Scheduler process entry point | No |
| `server/src/app.module.ts` | Root application module | No |
| `server/src/config/app.config.ts` | Application configuration | No |
| `server/src/common/constants/index.ts` | Shared constants | No |
| `server/src/common/enums/index.ts` | Shared enums | No |
| `server/src/common/interfaces/index.ts` | Shared interfaces | No |
| `server/test/jest-e2e.json` | E2E test configuration | No |
| `server/test/app.e2e-spec.ts` | Sample E2E test | No |

## Files to Modify

| File Path | Required Change |
|---|---|
| `packages/shared-types/package.json` | Add as workspace dependency |
| `BACKEND_ARCHITECTURE.md` | Document module structure |
| `API_CONTRACTS.md` | Add health check endpoint |
| `CONNECTION_MAP.md` | Add backend bootstrap wiring |

## Detailed Implementation

### 1. Package.json Configuration

```json
{
  "name": "@radha/server",
  "version": "1.0.0",
  "description": "RADHA Backend API Server",
  "scripts": {
    "prebuild": "rimraf dist",
    "build": "nest build",
    "format": "prettier --write \"src/**/*.ts\" \"test/**/*.ts\"",
    "start": "nest start",
    "start:dev": "nest start --watch",
    "start:debug": "nest start --debug --watch",
    "start:prod": "node dist/main.api",
    "start:worker": "node dist/main.worker",
    "start:scheduler": "node dist/main.scheduler",
    "lint": "eslint \"{src,apps,libs,test}/**/*.ts\" --fix",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:cov": "jest --coverage",
    "test:debug": "node --inspect-brk -r tsconfig-paths/register -r ts-node/register node_modules/.bin/jest --runInBand",
    "test:e2e": "jest --config ./test/jest-e2e.json",
    "db:generate": "drizzle-kit generate:pg",
    "db:migrate": "tsx src/db/migrate.ts",
    "db:studio": "drizzle-kit studio"
  },
  "dependencies": {
    "@nestjs/common": "^10.3.0",
    "@nestjs/core": "^10.3.0",
    "@nestjs/platform-express": "^10.3.0",
    "@nestjs/config": "^3.1.1",
    "@nestjs/schedule": "^4.0.0",
    "@nestjs/bull": "^10.0.1",
    "bull": "^4.12.0",
    "class-validator": "^0.14.0",
    "class-transformer": "^0.5.1",
    "drizzle-orm": "^0.29.0",
    "postgres": "^3.4.3",
    "zod": "^3.22.4",
    "helmet": "^7.1.0",
    "compression": "^1.7.4",
    "uuid": "^9.0.1",
    "@radha/shared-types": "workspace:*"
  },
  "devDependencies": {
    "@nestjs/cli": "^10.2.1",
    "@nestjs/schematics": "^10.0.3",
    "@nestjs/testing": "^10.3.0",
    "@types/express": "^4.17.21",
    "@types/jest": "^29.5.11",
    "@types/node": "^20.10.6",
    "@types/uuid": "^9.0.7",
    "@typescript-eslint/eslint-plugin": "^6.17.0",
    "@typescript-eslint/parser": "^6.17.0",
    "drizzle-kit": "^0.20.9",
    "eslint": "^8.56.0",
    "eslint-config-prettier": "^9.1.0",
    "eslint-plugin-prettier": "^5.1.2",
    "jest": "^29.7.0",
    "prettier": "^3.1.1",
    "rimraf": "^5.0.5",
    "ts-jest": "^29.1.1",
    "ts-loader": "^9.5.1",
    "ts-node": "^10.9.2",
    "tsconfig-paths": "^4.2.0",
    "tsx": "^4.7.0",
    "typescript": "^5.3.3"
  }
}
```

### 2. TypeScript Configuration

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "allowSyntheticDefaultImports": true,
    "target": "ES2021",
    "sourceMap": true,
    "outDir": "./dist",
    "baseUrl": "./",
    "incremental": true,
    "skipLibCheck": true,
    "strictNullChecks": true,
    "noImplicitAny": true,
    "strictBindCallApply": true,
    "forceConsistentCasingInFileNames": true,
    "noFallthroughCasesInSwitch": true,
    "paths": {
      "@radha/shared-types": ["../packages/shared-types/src"],
      "@/*": ["src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "test"]
}
```

### 3. Main API Entry Point

```typescript
// server/src/main.api.ts
import { NestFactory } from '@nestjs/core';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
import compression from 'compression';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log', 'debug', 'verbose'],
  });

  const configService = app.get(ConfigService);

  // Security middleware
  app.use(helmet());
  app.use(compression());

  // CORS configuration
  app.enableCors({
    origin: configService.get('CORS_ORIGINS')?.split(',') || '*',
    credentials: true,
  });

  // API versioning
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Graceful shutdown
  app.enableShutdownHooks();

  const port = configService.get('PORT') || 3000;
  await app.listen(port);

  console.log(`🚀 RADHA API Server running on: http://localhost:${port}`);
  console.log(`📚 API Version: v1`);
  console.log(`🌍 Environment: ${configService.get('NODE_ENV')}`);
}

bootstrap().catch((error) => {
  console.error('❌ Failed to start API server:', error);
  process.exit(1);
});
```

### 4. Worker Entry Point

```typescript
// server/src/main.worker.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ConfigService } from '@nestjs/config';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn', 'log'],
  });

  const configService = app.get(ConfigService);

  console.log(`🔧 RADHA Worker Process started`);
  console.log(`🌍 Environment: ${configService.get('NODE_ENV')}`);
  console.log(`📋 Worker will process: imports, reports, AI tasks, notifications`);

  // Worker stays alive to process queue jobs
  process.on('SIGTERM', async () => {
    console.log('⚠️  SIGTERM received, shutting down worker gracefully...');
    await app.close();
    process.exit(0);
  });
}

bootstrap().catch((error) => {
  console.error('❌ Failed to start worker process:', error);
  process.exit(1);
});
```

### 5. Scheduler Entry Point

```typescript
// server/src/main.scheduler.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ConfigService } from '@nestjs/config';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn', 'log'],
  });

  const configService = app.get(ConfigService);

  console.log(`⏰ RADHA Scheduler Process started`);
  console.log(`🌍 Environment: ${configService.get('NODE_ENV')}`);
  console.log(`📅 Scheduler will run: metric rollups, cleanup jobs, reminders`);

  // Scheduler stays alive to run cron jobs
  process.on('SIGTERM', async () => {
    console.log('⚠️  SIGTERM received, shutting down scheduler gracefully...');
    await app.close();
    process.exit(0);
  });
}

bootstrap().catch((error) => {
  console.error('❌ Failed to start scheduler process:', error);
  process.exit(1);
});
```

### 6. Root Application Module

```typescript
// server/src/app.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { BullModule } from '@nestjs/bull';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),

    // Scheduler (for cron jobs)
    ScheduleModule.forRoot(),

    // Queue (for background jobs)
    BullModule.forRoot({
      redis: {
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT || '6379'),
        password: process.env.REDIS_PASSWORD,
      },
    }),

    // Feature modules will be added in subsequent phases
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
```

### 7. Application Configuration

```typescript
// server/src/config/app.config.ts
export interface AppConfig {
  nodeEnv: string;
  port: number;
  apiPrefix: string;
  corsOrigins: string[];
  database: {
    host: string;
    port: number;
    name: string;
    user: string;
    password: string;
    ssl: boolean;
    maxConnections: number;
  };
  redis: {
    host: string;
    port: number;
    password?: string;
  };
  aws: {
    region: string;
    accessKeyId: string;
    secretAccessKey: string;
    s3Bucket: string;
  };
  sms: {
    provider: 'msg91';
    apiKey: string;
    senderId: string;
  };
}

export const loadAppConfig = (): AppConfig => ({
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  apiPrefix: process.env.API_PREFIX || 'api',
  corsOrigins: process.env.CORS_ORIGINS?.split(',') || ['*'],
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    name: process.env.DB_NAME || 'radha',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '',
    ssl: process.env.DB_SSL === 'true',
    maxConnections: parseInt(process.env.DB_MAX_CONNECTIONS || '20', 10),
  },
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
    password: process.env.REDIS_PASSWORD,
  },
  aws: {
    region: process.env.AWS_REGION || 'ap-south-1',
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || '',
    s3Bucket: process.env.AWS_S3_BUCKET || '',
  },
  sms: {
    provider: 'msg91',
    apiKey: process.env.MSG91_API_KEY || '',
    senderId: process.env.MSG91_SENDER_ID || 'RADHA',
  },
});
```

## Commands to Run

```bash
# Navigate to server directory
cd server

# Install dependencies
pnpm install

# Generate TypeScript types from shared package
pnpm --filter @radha/shared-types build

# Lint code
pnpm lint

# Run tests
pnpm test

# Build application
pnpm build

# Start API server in development
pnpm start:dev

# Start worker process
pnpm start:worker

# Start scheduler process
pnpm start:scheduler

# Run E2E tests
pnpm test:e2e
```

## Environment Variables Required

```env
# Application
NODE_ENV=development
PORT=3000
API_PREFIX=api
CORS_ORIGINS=http://localhost:3000,http://localhost:3001

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=radha_dev
DB_USER=postgres
DB_PASSWORD=your_password
DB_SSL=false
DB_MAX_CONNECTIONS=20

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# AWS
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_S3_BUCKET=radha-dev-media

# SMS
MSG91_API_KEY=
MSG91_SENDER_ID=RADHA
```

## Database Tables Affected

None directly. This phase establishes the backend foundation but does not interact with the database yet.

## API Contracts Affected

| Endpoint | Method | Purpose | Status |
|---|---|---|---|
| `/api/v1/health` | GET | Health check | Added |
| `/api/v1/health/ready` | GET | Readiness check | Added |

## Tests to Write

### Unit Tests

```typescript
// server/src/app.module.spec.ts
describe('AppModule', () => {
  it('should compile the module', async () => {
    const module = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    expect(module).toBeDefined();
  });
});
```

### E2E Tests

```typescript
// server/test/app.e2e-spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from './../src/app.module';

describe('AppController (e2e)', () => {
  let app: INestApplication;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  it('/api/v1/health (GET)', () => {
    return request(app.getHttpServer())
      .get('/api/v1/health')
      .expect(200)
      .expect({ status: 'ok', timestamp: expect.any(String) });
  });

  afterAll(async () => {
    await app.close();
  });
});
```

## Validation Checklist

- [ ] `pnpm install` completes without errors
- [ ] `pnpm lint` passes with no warnings
- [ ] `pnpm test` passes all unit tests
- [ ] `pnpm build` creates dist folder successfully
- [ ] `pnpm start:dev` starts API server on configured port
- [ ] Health check endpoint returns 200 OK
- [ ] Environment variables load correctly
- [ ] TypeScript compilation has no errors
- [ ] ESLint rules are enforced
- [ ] Prettier formatting is consistent
- [ ] Three entry points (API/Worker/Scheduler) are defined
- [ ] Graceful shutdown works on SIGTERM

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|---|---|---|---|
| Dependency version conflicts | High | Medium | Lock exact versions in package.json |
| Missing environment variables | High | High | Add validation in BE-02 |
| Port already in use | Medium | Medium | Make port configurable, check before start |
| Module circular dependencies | High | Low | Follow strict module boundaries |
| TypeScript path mapping issues | Medium | Medium | Test imports from shared packages |

## Completion Criteria

- [ ] All files listed in "Files to Create" exist and contain valid code
- [ ] `pnpm install` completes successfully
- [ ] `pnpm lint` passes with zero errors
- [ ] `pnpm test` passes with 100% of tests passing
- [ ] `pnpm build` creates production-ready dist folder
- [ ] API server starts and responds to health check
- [ ] Worker process starts without errors
- [ ] Scheduler process starts without errors
- [ ] All environment variables are documented
- [ ] TypeScript compilation produces no errors
- [ ] Module structure follows NestJS best practices
- [ ] Graceful shutdown handlers are implemented
- [ ] E2E test infrastructure is working

## Next Phase

**BE-02: Configuration and Environment Validation** - Add typed configuration, environment variable validation, and boot-time failure on invalid configuration.

---

## Session Handoff Notes

### What Was Completed
- NestJS backend initialized with three entry points
- Package dependencies configured
- TypeScript and build tooling set up
- Basic module structure created
- Health check endpoints defined

### What's Ready for Next Phase
- Application can start successfully
- Module system is ready for feature modules
- Configuration system is ready for validation layer
- Testing infrastructure is in place

### Known Issues
- Environment validation not yet implemented (BE-02)
- Database connection not yet configured (BE-04)
- No authentication yet (BE-05)
- No logging system yet (BE-03)

### Context for Next Developer
You're starting with a clean NestJS foundation. The next phase (BE-02) will add environment validation to ensure all required config is present before the app starts. Focus on creating a typed configuration service that validates on boot.


---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-02 Until This Section is Complete

This section is the **mandatory checkpoint** before moving to the next phase. The developer MUST execute every test, answer every Q&A, and get reviewer approval.

## 📋 Pre-Test Setup

### 1. Environment Verification

```bash
# Verify Node version
node --version
# Expected: v18.17.0 or higher

# Verify pnpm version
pnpm --version
# Expected: 8.10.0 or higher

# Verify project structure
cd server
ls -la
# Expected to see: package.json, tsconfig.json, src/, test/, nest-cli.json
```

### 2. Dependency Check

```bash
cd server
pnpm install
# Expected: All dependencies installed without errors
# Expected: No "ERR!" or "WARN" messages about peer dependencies
```

## 🧪 Test Procedures

### Test 1: Build Verification ✅

```bash
cd server
pnpm build
```

**Expected Output**:
- `dist/` folder created
- No TypeScript compilation errors
- No ESLint errors
- Build completes in < 30 seconds

**Verification**:
```bash
ls -la dist/
# Expected files: main.api.js, main.worker.js, main.scheduler.js, app.module.js
```

**Pass Criteria**: ✅ Build succeeds with zero errors

---

### Test 2: Linting & Formatting ✅

```bash
cd server
pnpm lint
```

**Expected Output**: 
- "All matched files use ESLint" message
- Zero errors
- Zero warnings

```bash
pnpm format
```

**Expected Output**: All files formatted with Prettier

**Pass Criteria**: ✅ Lint passes with 0 errors, 0 warnings

---

### Test 3: Unit Tests ✅

```bash
cd server
pnpm test
```

**Expected Output**:
```
Test Suites: 1 passed, 1 total
Tests:       3 passed, 3 total
Coverage:    > 80%
```

**Pass Criteria**: ✅ All tests pass with >80% coverage

---

### Test 4: API Server Startup ✅

**Terminal 1**:
```bash
cd server
pnpm start:dev
```

**Expected Console Output**:
```
🚀 RADHA API Server running on: http://localhost:3000
📚 API Version: v1
🌍 Environment: development
```

**Pass Criteria**: ✅ Server starts within 5 seconds, no errors

---

### Test 5: Health Check Endpoint ✅

**Terminal 2** (with server running):
```bash
curl -i http://localhost:3000/api/v1/health
```

**Expected Response**:
```http
HTTP/1.1 200 OK
Content-Type: application/json
X-Request-Id: <some-uuid>

{
  "status": "ok",
  "timestamp": "2024-01-XX..."
}
```

**Pass Criteria**: ✅ Returns 200 OK with valid JSON

---

### Test 6: Worker Process Startup ✅

**Terminal 3**:
```bash
cd server
pnpm start:worker
```

**Expected Output**:
```
🔧 RADHA Worker Process started
🌍 Environment: development
📋 Worker will process: imports, reports, AI tasks, notifications
```

**Pass Criteria**: ✅ Worker starts without errors

---

### Test 7: Scheduler Process Startup ✅

**Terminal 4**:
```bash
cd server
pnpm start:scheduler
```

**Expected Output**:
```
⏰ RADHA Scheduler Process started
🌍 Environment: development
📅 Scheduler will run: metric rollups, cleanup jobs, reminders
```

**Pass Criteria**: ✅ Scheduler starts without errors

---

### Test 8: Graceful Shutdown ✅

In each terminal where a process is running:
- Press `Ctrl+C`

**Expected Behavior**:
- Process logs "⚠️  SIGTERM received, shutting down gracefully..."
- Process exits cleanly within 5 seconds
- No "unhandled rejection" or "open handle" errors

**Pass Criteria**: ✅ All processes shut down gracefully

---

### Test 9: E2E Tests ✅

```bash
cd server
pnpm test:e2e
```

**Expected Output**:
```
PASS  test/app.e2e-spec.ts
  AppController (e2e)
    ✓ /api/v1/health (GET)
```

**Pass Criteria**: ✅ All E2E tests pass

---

### Test 10: Port Conflict Handling ✅

**Terminal 1**: Start server (uses port 3000)
**Terminal 2**: Try to start another server with same port

```bash
PORT=3000 pnpm start:dev
```

**Expected Behavior**: Second server fails with clear error: `EADDRINUSE: address already in use :::3000`

**Pass Criteria**: ✅ Error is clear, not a silent failure

---

## 🎯 Q&A Session — Developer Must Answer

The developer must answer these questions to confirm understanding:

### Q1: Architecture Understanding
**Question**: Why does this phase create THREE entry points (API, Worker, Scheduler) instead of one?

**Expected Answer**:
- API process handles HTTP requests synchronously
- Worker process handles long-running background jobs (imports, reports)
- Scheduler runs cron jobs (metric rollups, cleanup)
- Separation allows independent scaling and deployment
- API can restart without losing background jobs

**Developer's Answer**: _________________________________

---

### Q2: Module System
**Question**: How does NestJS know which module to load when the API starts?

**Expected Answer**:
- `main.api.ts` calls `NestFactory.create(AppModule)`
- `AppModule` is the root module
- `AppModule.imports` array lists all feature modules
- DI container resolves dependencies automatically
- All providers/controllers/services must be registered in their respective modules

**Developer's Answer**: _________________________________

---

### Q3: Configuration
**Question**: Where does the application read environment variables from?

**Expected Answer**:
- `ConfigModule.forRoot()` reads from `.env.local` first, then `.env`
- Variables accessed via `process.env.VAR_NAME` (will change in BE-02)
- `.env` is gitignored, `.env.example` is committed
- No validation yet — that comes in BE-02

**Developer's Answer**: _________________________________

---

### Q4: Security
**Question**: What security middleware is configured in this phase, and what does each do?

**Expected Answer**:
- **Helmet**: Sets security headers (X-Frame-Options, CSP, HSTS, etc.)
- **Compression**: Gzip-compresses responses to reduce bandwidth
- **CORS**: Controls which domains can call our API
- **ValidationPipe**: Validates incoming DTOs, strips unknown fields
- **Versioning**: URI-based (`/api/v1/...`) for backward compatibility

**Developer's Answer**: _________________________________

---

### Q5: TypeScript Path Mapping
**Question**: What does `@/*` resolve to in `tsconfig.json` paths, and why is it useful?

**Expected Answer**:
- `@/*` resolves to `server/src/*`
- `@radha/shared-types` resolves to the shared types package
- Useful for cleaner imports: `import { x } from '@/common/utils'` instead of `'../../common/utils'`
- Improves refactoring (file moves don't break imports)

**Developer's Answer**: _________________________________

---

### Q6: Testing
**Question**: What's the difference between unit tests and E2E tests in this phase?

**Expected Answer**:
- **Unit tests**: Test individual classes in isolation with mocked dependencies (`pnpm test`)
- **E2E tests**: Spin up the full app and make real HTTP requests (`pnpm test:e2e`)
- Unit tests run fast (< 5s), E2E tests slower (10-30s)
- Both types required for >80% coverage

**Developer's Answer**: _________________________________

---

### Q7: Production Readiness
**Question**: What is NOT production-ready about the current code, and which phase addresses each issue?

**Expected Answer**:
- ❌ No environment validation → BE-02
- ❌ No structured logging → BE-03
- ❌ No error tracking (Sentry) → BE-04
- ❌ No database connection → BE-05
- ❌ No authentication → BE-06
- ❌ No authorization → BE-08
- ❌ No rate limiting → BE-08
- ❌ Default CORS is `*` → fixed by config validation in BE-02

**Developer's Answer**: _________________________________

---

### Q8: Graceful Shutdown
**Question**: Why is graceful shutdown important, and how is it implemented?

**Expected Answer**:
- Prevents data loss from in-flight requests
- Closes database connections cleanly (when added in BE-05)
- Closes queue subscriptions cleanly (when added in BE-24)
- Implemented via `app.enableShutdownHooks()` and `process.on('SIGTERM')`
- Production deployments (Kubernetes, ECS) send SIGTERM before killing pods

**Developer's Answer**: _________________________________

---

## 📝 Sign-Off Checklist (Developer)

Developer must check ALL boxes before requesting review:

### Code Quality
- [ ] All files in "Files to Create" exist
- [ ] All files compile without TypeScript errors
- [ ] ESLint passes with 0 errors, 0 warnings
- [ ] Prettier formatting applied
- [ ] No `console.log` statements (except in main.*.ts entry points)
- [ ] No `any` types (except where unavoidable, with comment)
- [ ] All public methods have JSDoc comments

### Tests
- [ ] All unit tests pass
- [ ] All E2E tests pass
- [ ] Coverage report shows > 80%
- [ ] No skipped tests (`.skip`, `.only`)
- [ ] No commented-out tests

### Functional Verification
- [ ] API server starts on port 3000
- [ ] Worker process starts
- [ ] Scheduler process starts
- [ ] Health check returns 200 OK
- [ ] All three processes shut down gracefully on Ctrl+C
- [ ] X-Request-Id header is present on responses

### Documentation
- [ ] All Q&A questions answered correctly
- [ ] BE-01_HANDOFF.md fully filled out
- [ ] No "[TO BE FILLED]" placeholders remaining
- [ ] Environment state documented
- [ ] Known issues documented

### Git Hygiene
- [ ] All work committed to feature branch
- [ ] Commit messages descriptive
- [ ] No secrets in commits
- [ ] `.env.local` in `.gitignore`

**Developer Signature**: ___________________________
**Date**: ___________________________

---

## 👤 Reviewer Checklist (Reviewer)

The reviewer (you) checks these items independently:

### Architecture Review
- [ ] Module structure follows NestJS best practices
- [ ] Three-process architecture correctly implemented
- [ ] No business logic in entry point files
- [ ] Configuration is environment-aware

### Security Review
- [ ] No secrets committed to repo
- [ ] CORS configuration acceptable for current phase
- [ ] Helmet configured correctly
- [ ] Validation pipe enabled globally

### Code Review
- [ ] Code is readable and follows conventions
- [ ] No obvious performance issues
- [ ] Error handling is consistent
- [ ] Logging is appropriate (not too verbose, not too sparse)

### Test Review
- [ ] Tests actually test something meaningful
- [ ] Test names clearly describe what they test
- [ ] No flaky tests
- [ ] Coverage report reviewed

### Documentation Review
- [ ] Phase file matches what was built
- [ ] Handoff file is complete and accurate
- [ ] Developer Q&A answers show understanding

### Decision

**☐ APPROVED — Proceed to BE-02**
**☐ CHANGES REQUESTED** (list below)

**Changes Required (if any)**:
1. _________________________________
2. _________________________________
3. _________________________________

**Reviewer Signature**: ___________________________
**Date**: ___________________________

---

## 🚀 Ready for BE-02?

If ALL of the following are true, you can proceed:
- ✅ All 10 tests pass
- ✅ All 8 Q&A questions answered correctly
- ✅ Developer sign-off complete
- ✅ Reviewer approval granted
- ✅ Handoff file fully populated

**If any of the above is missing, FIX IT before moving to BE-02.**

The next phase (BE-02) builds directly on the configuration system started here. If BE-01 is incomplete, BE-02 will fail.

---

## 🆘 Troubleshooting Common Issues

### Issue: `pnpm install` fails with peer dependency errors
**Solution**:
```bash
pnpm install --strict-peer-dependencies=false
```
But document this in handoff as technical debt to resolve in BE-32.

### Issue: TypeScript path aliases not resolving
**Solution**:
1. Ensure `tsconfig.json` has correct `baseUrl` and `paths`
2. Run `pnpm build` to verify
3. Restart your IDE TypeScript server

### Issue: Port 3000 already in use
**Solution**:
```bash
# Find process using port 3000
lsof -i :3000  # Mac/Linux
netstat -ano | findstr :3000  # Windows

# Kill it, or use different port
PORT=3001 pnpm start:dev
```

### Issue: Health check returns 404
**Solution**:
1. Verify `HealthModule` is imported in `AppModule`
2. Check controller path: `@Controller('health')`
3. Check global prefix: should be `api/v1` (versioning)
4. Try: `curl http://localhost:3000/api/v1/health`

### Issue: Tests fail with "Cannot find module '@radha/shared-types'"
**Solution**:
1. Build the shared package: `pnpm --filter @radha/shared-types build`
2. Verify `tsconfig.json` paths point to correct location
3. Restart Jest cache: `pnpm test --clearCache`

---

**END OF BE-01 — DO NOT PROCEED WITHOUT APPROVAL ABOVE**
