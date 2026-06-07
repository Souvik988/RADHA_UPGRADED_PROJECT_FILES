# Phase BE-09: Tenant & Store Multi-tenancy

## Phase Metadata

- **Phase ID**: BE-09
- **Phase Name**: Tenant & Store Multi-tenancy
- **Section**: Backend Execution — Security & Identity Layer
- **Depends On**: BE-01 to BE-08
- **Blocks**: All feature phases (BE-10 onwards)
- **Estimated Duration**: 2-3 days
- **Complexity**: High

## Goal

Implement comprehensive multi-tenancy: tenant management, store hierarchy, user-store access mapping, automatic tenant scoping in queries, tenant onboarding flow, and tenant configuration system. Ensure ZERO cross-tenant data leaks.

## Why This Phase Matters

**Multi-tenancy is the core of SaaS.** Without proper isolation:
- One client sees another client's data (catastrophic GDPR violation)
- Compliance failures (DPDP Act, GDPR, SOC 2)
- Loss of customer trust (irreversible)
- Legal liability
- Business model collapse

This phase establishes **bulletproof tenant isolation** at every layer.

## Prerequisites

- [ ] BE-01 to BE-08 completed
- [ ] Authentication working
- [ ] Authorization guards in place
- [ ] Database connection ready
- [ ] Audit logging functional

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/tenants.ts` | Tenants table |
| `server/src/db/schema/stores.ts` | Stores table |
| `server/src/db/schema/user_store_access.ts` | User-store mapping |
| `server/src/db/schema/tenant_settings.ts` | Tenant configuration |
| `server/src/modules/tenants/tenants.module.ts` | Tenants module |
| `server/src/modules/tenants/tenants.controller.ts` | Tenant endpoints |
| `server/src/modules/tenants/tenants.service.ts` | Tenant business logic |
| `server/src/modules/tenants/tenants.repository.ts` | Tenant data access |
| `server/src/modules/tenants/services/tenant-onboarding.service.ts` | Onboarding flow |
| `server/src/modules/tenants/services/tenant-settings.service.ts` | Settings management |
| `server/src/modules/stores/stores.module.ts` | Stores module |
| `server/src/modules/stores/stores.controller.ts` | Store endpoints |
| `server/src/modules/stores/stores.service.ts` | Store business logic |
| `server/src/modules/stores/stores.repository.ts` | Store data access |
| `server/src/modules/stores/services/user-store-access.service.ts` | Access management |
| `server/src/modules/stores/repositories/user-store-access.repository.ts` | Access data |
| `server/src/db/repositories/tenant-scoped.repository.ts` | Auto-scoped base repo |
| `server/src/common/middleware/tenant-context.middleware.ts` | Set tenant in CLS |
| `server/src/modules/tenants/dto/create-tenant.dto.ts` | DTOs |
| `server/src/modules/tenants/dto/onboard-tenant.dto.ts` | DTOs |
| `server/src/modules/stores/dto/create-store.dto.ts` | DTOs |
| `server/src/modules/stores/dto/grant-store-access.dto.ts` | DTOs |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/tenants/tenants.service.ts

export interface ITenantsService {
  // Tenant CRUD (admin only)
  create(dto: CreateTenantDto, createdBy: string): Promise<Tenant>;
  findById(id: string): Promise<Tenant | null>;
  findBySubdomain(subdomain: string): Promise<Tenant | null>;
  update(id: string, dto: UpdateTenantDto, userId: string): Promise<Tenant>;
  suspend(id: string, reason: string, userId: string): Promise<void>;
  reactivate(id: string, userId: string): Promise<void>;
  
  // Onboarding
  onboard(dto: OnboardTenantDto): Promise<TenantOnboardResult>;
  
  // Listing (admin only)
  list(filters: ListTenantsFilter): Promise<PaginatedResult<Tenant>>;
  
  // Settings
  getSettings(tenantId: string): Promise<TenantSettings>;
  updateSettings(tenantId: string, settings: Partial<TenantSettings>, userId: string): Promise<TenantSettings>;
}

// server/src/modules/stores/stores.service.ts

export interface IStoresService {
  // Store CRUD (within tenant)
  create(dto: CreateStoreDto, tenantId: string, userId: string): Promise<Store>;
  findById(id: string, tenantId: string): Promise<Store | null>;
  list(tenantId: string, filters: ListStoresFilter): Promise<PaginatedResult<Store>>;
  update(id: string, dto: UpdateStoreDto, tenantId: string, userId: string): Promise<Store>;
  delete(id: string, tenantId: string, userId: string): Promise<void>;
  
  // Access management
  grantAccess(dto: GrantStoreAccessDto, grantedBy: string): Promise<UserStoreAccess>;
  revokeAccess(userId: string, storeId: string, revokedBy: string): Promise<void>;
  listUserStores(userId: string): Promise<Store[]>;
  listStoreUsers(storeId: string, tenantId: string): Promise<User[]>;
}

// server/src/modules/tenants/services/tenant-onboarding.service.ts

export interface ITenantOnboardingService {
  // Full onboarding flow:
  // 1. Create tenant
  // 2. Create owner user
  // 3. Create first store
  // 4. Send welcome email
  // 5. Create default settings
  // 6. Start free trial
  onboard(dto: OnboardTenantDto): Promise<OnboardingResult>;
  
  validateSubdomain(subdomain: string): Promise<boolean>;
}

export interface OnboardingResult {
  tenant: Tenant;
  owner: User;
  store: Store;
  trialEndsAt: Date;
  authResult: AuthResult;
}
```

## Implementation Code

### 1. Tenants Schema

```typescript
// server/src/db/schema/tenants.ts
import { pgTable, varchar, uuid, boolean, timestamp, jsonb, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns, softDeleteColumn, auditColumns } from './_base';

export const tenantStatusEnum = pgEnum('tenant_status', [
  'active',
  'trial',
  'suspended',
  'cancelled',
  'pending_setup',
]);

export const tenants = pgTable(
  'tenants',
  {
    ...baseColumns,
    ...softDeleteColumn,
    ...auditColumns,
    name: varchar('name', { length: 200 }).notNull(),
    subdomain: varchar('subdomain', { length: 50 }).notNull().unique(),
    status: tenantStatusEnum('status').notNull().default('pending_setup'),
    plan: varchar('plan', { length: 50 }).notNull().default('trial'),
    industry: varchar('industry', { length: 100 }),
    country: varchar('country', { length: 2 }).default('IN'),
    timezone: varchar('timezone', { length: 50 }).default('Asia/Kolkata'),
    contactEmail: varchar('contact_email', { length: 255 }).notNull(),
    contactMobile: varchar('contact_mobile', { length: 20 }),
    metadata: jsonb('metadata').default({}),
    suspendedAt: timestamp('suspended_at', { withTimezone: true }),
    suspendedReason: varchar('suspended_reason', { length: 500 }),
  },
  (table) => ({
    subdomainIdx: index('idx_tenants_subdomain').on(table.subdomain),
    statusIdx: index('idx_tenants_status').on(table.status),
  }),
);

export type Tenant = typeof tenants.$inferSelect;
export type NewTenant = typeof tenants.$inferInsert;
```

### 2. Stores Schema

```typescript
// server/src/db/schema/stores.ts
import { pgTable, varchar, uuid, boolean, timestamp, jsonb, decimal, index } from 'drizzle-orm/pg-core';
import { baseColumns, softDeleteColumn, auditColumns } from './_base';
import { tenants } from './tenants';

export const stores = pgTable(
  'stores',
  {
    ...baseColumns,
    ...softDeleteColumn,
    ...auditColumns,
    tenantId: uuid('tenant_id').notNull().references(() => tenants.id, { onDelete: 'cascade' }),
    name: varchar('name', { length: 200 }).notNull(),
    code: varchar('code', { length: 50 }).notNull(),
    type: varchar('type', { length: 50 }).default('retail'),
    isActive: boolean('is_active').notNull().default(true),
    
    // Address
    addressLine1: varchar('address_line_1', { length: 255 }),
    addressLine2: varchar('address_line_2', { length: 255 }),
    city: varchar('city', { length: 100 }),
    state: varchar('state', { length: 100 }),
    pincode: varchar('pincode', { length: 10 }),
    country: varchar('country', { length: 2 }).default('IN'),
    
    // Geolocation
    latitude: decimal('latitude', { precision: 10, scale: 7 }),
    longitude: decimal('longitude', { precision: 10, scale: 7 }),
    
    // Configuration
    timezone: varchar('timezone', { length: 50 }).default('Asia/Kolkata'),
    currency: varchar('currency', { length: 3 }).default('INR'),
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    tenantIdx: index('idx_stores_tenant').on(table.tenantId),
    tenantCityIdx: index('idx_stores_tenant_city').on(table.tenantId, table.city),
    uniqueTenantCode: index('uniq_stores_tenant_code').on(table.tenantId, table.code),
  }),
);

export type Store = typeof stores.$inferSelect;
export type NewStore = typeof stores.$inferInsert;
```

### 3. User-Store Access

```typescript
// server/src/db/schema/user_store_access.ts
import { pgTable, uuid, varchar, boolean, timestamp, index, unique } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';
import { users } from './users';
import { stores } from './stores';

export const userStoreAccess = pgTable(
  'user_store_access',
  {
    ...baseColumns,
    userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
    storeId: uuid('store_id').notNull().references(() => stores.id, { onDelete: 'cascade' }),
    accessLevel: varchar('access_level', { length: 20 }).notNull().default('read'),
    isActive: boolean('is_active').notNull().default(true),
    grantedBy: uuid('granted_by').references(() => users.id),
    grantedAt: timestamp('granted_at', { withTimezone: true }).defaultNow(),
    revokedAt: timestamp('revoked_at', { withTimezone: true }),
    revokedBy: uuid('revoked_by').references(() => users.id),
  },
  (table) => ({
    userIdx: index('idx_usa_user').on(table.userId),
    storeIdx: index('idx_usa_store').on(table.storeId),
    uniqueUserStore: unique('uniq_user_store').on(table.userId, table.storeId),
  }),
);

export type UserStoreAccess = typeof userStoreAccess.$inferSelect;
export type NewUserStoreAccess = typeof userStoreAccess.$inferInsert;
```

### 4. Tenant-Scoped Repository (Base Class)

```typescript
// server/src/db/repositories/tenant-scoped.repository.ts
import { eq, and } from 'drizzle-orm';
import { BaseRepository } from './base.repository';
import { Transaction } from '../connection';
import { RequestContextService } from '../../common/context/request-context.service';
import { ForbiddenException } from '../../common/errors/business.exception';
import { ErrorCode } from '../../common/errors/error-codes';

/**
 * Base repository that automatically enforces tenant scoping.
 * All queries automatically include tenant_id filter from request context.
 */
export abstract class TenantScopedRepository<TTable, TEntity, TInsert, TUpdate>
  extends BaseRepository<TTable, TEntity, TInsert, TUpdate>
{
  protected abstract tenantIdColumn(): unknown;
  
  constructor(
    db: any,
    table: TTable,
    tableName: string,
    protected readonly contextService: RequestContextService,
  ) {
    super(db, table as any, tableName);
  }

  /**
   * Get tenant ID from CLS context. Throws if not set.
   */
  protected getTenantId(): string {
    const tenantId = this.contextService.getTenantId();
    if (!tenantId) {
      throw new ForbiddenException(
        'Tenant context required',
        ErrorCode.TENANT_ACCESS_DENIED,
      );
    }
    return tenantId;
  }

  /**
   * Override to add tenant filter automatically.
   */
  protected buildConditions(filters: any, options?: any): unknown[] {
    const conditions = super.buildConditions(filters, options);
    
    // Always add tenant_id filter
    const tenantId = this.getTenantId();
    conditions.push(eq(this.tenantIdColumn() as any, tenantId));
    
    return conditions;
  }

  /**
   * Override create to set tenant_id automatically.
   */
  async create(data: TInsert, tx?: Transaction): Promise<TEntity> {
    const tenantId = this.getTenantId();
    const dataWithTenant = { ...data, tenantId } as TInsert;
    return super.create(dataWithTenant, tx);
  }

  /**
   * Validate that a record belongs to current tenant.
   * Throws if cross-tenant access attempted.
   */
  async validateTenantOwnership(id: string): Promise<void> {
    const record = await this.findById(id);
    if (!record) return; // Will throw NotFound elsewhere
    
    const tenantId = this.getTenantId();
    if ((record as any).tenantId !== tenantId) {
      throw new ForbiddenException(
        'Cross-tenant access denied',
        ErrorCode.TENANT_ACCESS_DENIED,
      );
    }
  }
}
```

### 5. Tenant Onboarding Service

```typescript
// server/src/modules/tenants/services/tenant-onboarding.service.ts
import { Injectable } from '@nestjs/common';
import { DbService } from '../../../db/db.service';
import { TenantsRepository } from '../tenants.repository';
import { UsersRepository } from '../../auth/repositories/users.repository';
import { StoresRepository } from '../../stores/stores.repository';
import { UserStoreAccessRepository } from '../../stores/repositories/user-store-access.repository';
import { AuthService } from '../../auth/auth.service';
import { EmailService } from '../../../integrations/email/email.service';
import { AuditLogService } from '../../../observability/audit-log.service';
import { OnboardTenantDto } from '../dto/onboard-tenant.dto';
import {
  ITenantOnboardingService,
  OnboardingResult,
} from '../types/tenant.types';
import {
  ConflictException,
  ValidationException,
} from '../../../common/errors/business.exception';
import { ErrorCode } from '../../../common/errors/error-codes';

@Injectable()
export class TenantOnboardingService implements ITenantOnboardingService {
  constructor(
    private readonly db: DbService,
    private readonly tenantsRepo: TenantsRepository,
    private readonly usersRepo: UsersRepository,
    private readonly storesRepo: StoresRepository,
    private readonly accessRepo: UserStoreAccessRepository,
    private readonly authService: AuthService,
    private readonly emailService: EmailService,
    private readonly auditLog: AuditLogService,
  ) {}

  async onboard(dto: OnboardTenantDto): Promise<OnboardingResult> {
    // 1. Validate subdomain availability
    const valid = await this.validateSubdomain(dto.subdomain);
    if (!valid) {
      throw new ConflictException(
        'Subdomain already taken',
        ErrorCode.DUPLICATE_RESOURCE,
        { metadata: { subdomain: dto.subdomain } },
      );
    }

    // 2. Run everything in a single transaction
    return this.db.transaction(async (tx) => {
      // Create tenant
      const tenant = await this.tenantsRepo.create({
        name: dto.businessName,
        subdomain: dto.subdomain,
        status: 'trial',
        plan: 'trial',
        industry: dto.industry,
        contactEmail: dto.email,
        contactMobile: dto.mobile,
        country: dto.country || 'IN',
      }, tx);

      // Create owner user
      const owner = await this.usersRepo.create({
        tenantId: tenant.id,
        mobile: dto.mobile,
        email: dto.email,
        name: dto.ownerName,
        role: 'owner',
        isVerified: false,
        isActive: true,
      }, tx);

      // Create first store
      const store = await this.storesRepo.create({
        tenantId: tenant.id,
        name: dto.storeName,
        code: 'STORE-001',
        type: 'retail',
        addressLine1: dto.storeAddress,
        city: dto.storeCity,
        state: dto.storeState,
        pincode: dto.storePincode,
      }, tx);

      // Grant owner full access to first store
      await this.accessRepo.create({
        userId: owner.id,
        storeId: store.id,
        accessLevel: 'admin',
        isActive: true,
        grantedBy: owner.id,
      }, tx);

      // Audit log
      await this.auditLog.logAction({
        action: 'CREATE',
        resourceType: 'Tenant',
        resourceId: tenant.id,
        userId: owner.id,
        tenantId: tenant.id,
        success: true,
        metadata: { onboarding: true },
      });

      // Send welcome email (outside transaction)
      const trialEndsAt = new Date();
      trialEndsAt.setMonth(trialEndsAt.getMonth() + 3);

      // Generate auth tokens
      const authResult = await this.authService.generateTokensForUser(owner, {
        ipAddress: 'onboarding',
        userAgent: 'onboarding',
      });

      return {
        tenant,
        owner,
        store,
        trialEndsAt,
        authResult,
      };
    });
  }

  async validateSubdomain(subdomain: string): Promise<boolean> {
    // Reserved subdomains
    const reserved = ['admin', 'api', 'www', 'app', 'support', 'help', 'demo'];
    if (reserved.includes(subdomain.toLowerCase())) return false;

    // Format check
    if (!/^[a-z][a-z0-9-]{2,49}$/.test(subdomain)) return false;

    // Uniqueness check
    const existing = await this.tenantsRepo.findBySubdomain(subdomain);
    return !existing;
  }
}
```

## Database Tables Affected

| Table | Created/Modified | Purpose |
|---|---|---|
| `tenants` | CREATED | Tenant master data |
| `stores` | CREATED | Store master data |
| `user_store_access` | CREATED | User-store mapping |
| `tenant_settings` | CREATED | Per-tenant settings |
| `users` | MODIFIED | tenant_id already exists |

## API Endpoints

| Method | Endpoint | Auth | Role | Purpose |
|---|---|---|---|---|
| POST | `/api/v1/tenants/onboard` | Public | - | Self-service tenant onboarding |
| GET | `/api/v1/tenants/me` | Bearer | All | Current tenant info |
| PATCH | `/api/v1/tenants/me` | Bearer | Owner | Update tenant info |
| GET | `/api/v1/tenants/me/settings` | Bearer | Owner/Manager | Get settings |
| PATCH | `/api/v1/tenants/me/settings` | Bearer | Owner | Update settings |
| GET | `/api/v1/admin/tenants` | Bearer | Admin | List all tenants |
| POST | `/api/v1/admin/tenants/:id/suspend` | Bearer | Admin | Suspend tenant |
| POST | `/api/v1/stores` | Bearer | Owner | Create store |
| GET | `/api/v1/stores` | Bearer | All | List stores |
| GET | `/api/v1/stores/:id` | Bearer | All (with access) | Get store |
| PATCH | `/api/v1/stores/:id` | Bearer | Owner/Manager | Update store |
| DELETE | `/api/v1/stores/:id` | Bearer | Owner | Delete store |
| POST | `/api/v1/stores/:id/access` | Bearer | Owner/Manager | Grant access |
| DELETE | `/api/v1/stores/:id/access/:userId` | Bearer | Owner/Manager | Revoke access |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-10 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Tenant Onboarding ✅

```bash
curl -X POST http://localhost:3000/api/v1/tenants/onboard \
  -H "Content-Type: application/json" \
  -d '{
    "businessName":"Test Mart",
    "subdomain":"testmart",
    "industry":"retail",
    "ownerName":"John Doe",
    "email":"john@testmart.com",
    "mobile":"9876543210",
    "storeName":"Main Store",
    "storeAddress":"123 Main St",
    "storeCity":"Mumbai",
    "storeState":"Maharashtra",
    "storePincode":"400001"
  }'
```

**Expected**: Returns tenant, owner, store, and auth tokens
**Verification**: 
- New row in `tenants`
- New row in `users` with `tenant_id` set
- New row in `stores` with `tenant_id` set
- New row in `user_store_access`

**Pass Criteria**: ✅ Onboarding creates everything atomically

---

### Test 2: Subdomain Validation ✅

```bash
# Reserved subdomain
curl -X POST .../onboard -d '{"subdomain":"admin",...}'
# Expected: 422 with "Reserved subdomain"

# Invalid format
curl -X POST .../onboard -d '{"subdomain":"AB",...}'
# Expected: 400 validation error

# Duplicate
curl -X POST .../onboard -d '{"subdomain":"testmart",...}' # already exists
# Expected: 409 DUPLICATE_RESOURCE
```

**Pass Criteria**: ✅ All validation rules enforced

---

### Test 3: Cross-Tenant Read Block ✅

User from Tenant A tries to read Tenant B's stores:
```bash
# JWT has tenantId=tenant-a
curl http://localhost:3000/api/v1/stores/<tenant-b-store-id> \
  -H "Authorization: Bearer <tenant-a-token>"
```

**Expected**: 403 with `TENANT_ACCESS_DENIED`
**Pass Criteria**: ✅ Cross-tenant read blocked

---

### Test 4: Cross-Tenant Write Block ✅

User from Tenant A tries to update Tenant B's store:
```bash
curl -X PATCH http://localhost:3000/api/v1/stores/<tenant-b-store-id> \
  -H "Authorization: Bearer <tenant-a-token>" \
  -d '{"name":"Hacked"}'
```

**Expected**: 403 with `TENANT_ACCESS_DENIED`
**Verification**: Store unchanged in DB
**Pass Criteria**: ✅ Cross-tenant write blocked

---

### Test 5: Store-Level Access ✅

Manager from Store A tries to access Store B (same tenant):
```bash
# Manager only has access to Store A
curl http://localhost:3000/api/v1/stores/<store-b-id> \
  -H "Authorization: Bearer <manager-token>"
```

**Expected**: 403 with `STORE_ACCESS_DENIED`
**Pass Criteria**: ✅ Store-level access enforced

---

### Test 6: Owner Cross-Store Access ✅

Owner accesses any store in their tenant:
```bash
curl http://localhost:3000/api/v1/stores/<any-store-in-tenant> \
  -H "Authorization: Bearer <owner-token>"
```

**Expected**: 200 success
**Pass Criteria**: ✅ Owner has all-store access

---

### Test 7: Grant Store Access ✅

```bash
curl -X POST http://localhost:3000/api/v1/stores/<store-id>/access \
  -H "Authorization: Bearer <owner-token>" \
  -d '{"userId":"<user-id>","accessLevel":"write"}'
```

**Expected**: 200 with new UserStoreAccess record
**Verification**: User can now access store
**Pass Criteria**: ✅ Access granting works

---

### Test 8: Revoke Store Access ✅

```bash
curl -X DELETE http://localhost:3000/api/v1/stores/<store-id>/access/<user-id> \
  -H "Authorization: Bearer <owner-token>"
```

**Expected**: 204 success
**Verification**: User immediately loses access (subsequent requests fail)
**Pass Criteria**: ✅ Revocation works

---

### Test 9: Tenant Suspension ✅

Admin suspends a tenant:
```bash
curl -X POST http://localhost:3000/api/v1/admin/tenants/<tenant-id>/suspend \
  -H "Authorization: Bearer <admin-token>" \
  -d '{"reason":"Payment failure"}'
```

**Expected**: 200, tenant status=suspended
**Verification**: All users from that tenant cannot login (or get warning)
**Pass Criteria**: ✅ Suspension works

---

### Test 10: TenantScopedRepository ✅

Verify auto-scoping:
```typescript
// User context: tenant-a
const stores = await storesRepo.findMany({});
// Should ONLY return tenant-a stores
expect(stores.every(s => s.tenantId === 'tenant-a')).toBe(true);
```

**Pass Criteria**: ✅ Auto-scoping works

---

### Test 11: Audit Log on Cross-Tenant Attempt ✅

After cross-tenant attempt:
```sql
SELECT * FROM audit_logs 
WHERE action = 'AUTHORIZATION_FAILED' 
  AND error_code = 'TENANT_ACCESS_DENIED';
```

**Expected**: Records present with full context
**Pass Criteria**: ✅ All violations logged

---

### Test 12: Tenant Settings ✅

```bash
# Get settings
curl http://localhost:3000/api/v1/tenants/me/settings \
  -H "Authorization: Bearer <owner-token>"

# Update settings
curl -X PATCH http://localhost:3000/api/v1/tenants/me/settings \
  -H "Authorization: Bearer <owner-token>" \
  -d '{"businessHours":{"open":"09:00","close":"21:00"}}'
```

**Pass Criteria**: ✅ Settings work

---

### Test 13: Database-Level Verification ✅

Verify schema:
```sql
-- All multi-tenant tables have tenant_id NOT NULL
SELECT table_name FROM information_schema.columns
WHERE column_name = 'tenant_id' AND is_nullable = 'NO';

-- All have indexes on tenant_id
SELECT * FROM pg_indexes 
WHERE indexname LIKE '%tenant%';
```

**Pass Criteria**: ✅ All multi-tenant tables properly indexed

---

### Test 14: Performance with Multi-tenancy ✅

Load test with 100 tenants × 1000 records:
```bash
# Run query on heavily loaded DB
EXPLAIN ANALYZE SELECT * FROM stores WHERE tenant_id = 'specific-id';
```

**Expected**: Index scan, < 10ms
**Pass Criteria**: ✅ Indexes used efficiently

---

### Test 15: Concurrent Onboarding ✅

Run 10 concurrent onboarding requests with different subdomains:
**Expected**: All succeed (no deadlocks)
**Pass Criteria**: ✅ Concurrent safety

---

## 🎯 Q&A Session

### Q1: Why row-level multi-tenancy vs database-per-tenant?

**Expected Answer**:
- Row-level: Simpler ops, easier scaling for SMB SaaS
- DB-per-tenant: Stronger isolation, harder to manage 1000s of DBs
- RADHA at 10K tenants: Row-level is correct choice
- PostgreSQL handles it well with proper indexes
- Trade-off: Need rigorous app-level enforcement

---

### Q2: Why TenantScopedRepository abstraction?

**Expected Answer**:
- DRY: Don't repeat tenant filter in every query
- Safety: Cannot forget to filter
- Centralized: Single place to enforce
- Auto-set on insert: tenantId set from context, can't be spoofed
- Performance: Reuses CLS context (no DB lookup)

---

### Q3: How is tenant_id propagated through async code?

**Expected Answer**:
- AsyncLocalStorage (BE-03) preserves context across async boundaries
- JWT auth guard (BE-08) sets tenantId in CLS
- All repositories read from CLS, not from request directly
- Worker queue jobs receive tenantId in job payload
- Cron jobs explicitly set tenantId

---

### Q4: What if a user belongs to multiple tenants?

**Expected Answer**:
- V1: One user = one tenant (simpler)
- Future: Could add `user_tenant_access` table
- Login would require tenant selection
- JWT carries selected tenant
- Switching tenant = re-login

---

### Q5: How does store-level access compose with tenant?

**Expected Answer**:
- First check: User's tenantId == resource's tenantId
- Then check: User has access to specific storeId
- Owner: Bypasses store check (all stores in tenant)
- Admin: Bypasses both checks (cross-tenant)
- Staff/Auditor/Manager: Both checks enforced

---

### Q6: How would you handle tenant deletion?

**Expected Answer**:
- Soft delete with `deletedAt` (recoverable for X days)
- Hard delete after retention period
- Cascade deletes via FK constraints
- Or: Mark all data as deleted via `tenant_id IN (SELECT id FROM tenants WHERE deleted_at IS NOT NULL)`
- Backup before deletion
- Audit log of deletion

---

### Q7: What about shared resources (Open Food Facts cache)?

**Expected Answer**:
- These have `tenant_id IS NULL` (global)
- Read access for all tenants (no privacy concern)
- Write access only by admin (system-wide updates)
- Repository pattern: Some repos extend BaseRepository (not TenantScoped)
- Documented clearly which tables are tenant-scoped vs global

---

### Q8: How to prevent tenant_id manipulation?

**Expected Answer**:
- tenant_id from JWT (signed by server)
- Cannot be modified by client
- Repository auto-injects from CLS (not from request body)
- Validate JWT tenantId matches DB record on read
- Audit logs catch tampering attempts

---

## 📝 Sign-Off Checklist

### Functional
- [ ] Tenant onboarding works atomically
- [ ] Subdomain validation works
- [ ] Stores can be created within tenant
- [ ] User-store access can be granted/revoked
- [ ] Tenant settings work
- [ ] Tenant suspension works

### Security (Critical)
- [ ] Cross-tenant reads BLOCKED
- [ ] Cross-tenant writes BLOCKED
- [ ] Cross-store reads BLOCKED (without access)
- [ ] tenant_id cannot be spoofed
- [ ] Owner role has correct overrides
- [ ] Admin role has correct overrides

### Code Quality
- [ ] TenantScopedRepository abstraction works
- [ ] All multi-tenant tables have tenant_id NOT NULL
- [ ] All have proper indexes
- [ ] Onboarding uses transaction
- [ ] Audit logs comprehensive

### Performance
- [ ] Tenant queries use index
- [ ] No N+1 queries
- [ ] Onboarding < 1 second

### Tests
- [ ] All 15 tests pass
- [ ] Coverage > 90%
- [ ] Cross-tenant tests verify ZERO leaks

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

### CRITICAL Security Verification
- [ ] Manually attempted cross-tenant access (must fail)
- [ ] Verified tenant_id cannot be modified via API
- [ ] Reviewed all multi-tenant tables for tenant_id
- [ ] Confirmed audit logs capture violations
- [ ] Tested with multiple tenants in DB

**☐ APPROVED — Proceed to BE-10**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF BE-09 — DO NOT PROCEED WITHOUT APPROVAL**

**🔒 CRITICAL: This phase determines whether RADHA is a viable SaaS. ZERO tolerance for cross-tenant leaks. Test thoroughly.**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-09 with v2 multi-tenant isolation hardening (Req 41) and Consumer personal-tenant scoping (Req 1, Req 26).**

## Driver Requirements

- **Req 41** — PostgreSQL_RLS policies on every tenant-scoped table; Tenant_Scope_Middleware injecting `tenant_id` on all queries; cross-tenant isolation property tests.
- **Req 1, Req 26** — Each Consumer signup gets a "personal tenant" so all consumer-side data (saved products, allergen profiles, expiry calendar, family members) is isolated under the same multi-tenant model used for businesses.

## Scope of Update

1. Introduce a `tenant_kind` enum on the `tenants` table: `'business' | 'personal'`.
2. Apply PostgreSQL Row-Level Security (RLS) policies on every tenant-scoped table.
3. Build a `TenantScopeMiddleware` that resolves `tenant_id` from JWT and binds it to the database session via `SET LOCAL app.tenant_id`.
4. Add cross-tenant isolation property tests using fast-check or a property-based testing harness.

## Files to Create / Modify

| File Path | Change |
|---|---|
| `server/src/database/migrations/v2/2026XXXX_add_tenant_kind.sql` | Add `tenant_kind` to `tenants` |
| `server/src/database/migrations/v2/2026XXXX_enable_rls.sql` | Enable RLS on tenant-scoped tables |
| `server/src/database/migrations/v2/2026XXXX_rls_policies.sql` | Create RLS policies referencing `current_setting('app.tenant_id')` |
| `server/src/common/middleware/tenant-scope.middleware.ts` | New |
| `server/src/common/middleware/__tests__/tenant-scope.property.spec.ts` | New — property tests |
| `server/src/modules/tenants/services/tenant-bootstrap.service.ts` | New — creates a personal tenant on first Consumer signup |

## RLS Policy Template

```sql
-- Apply to every tenant-scoped table (products, scans, inventory, tasks, ean_lists, saved_products, allergen_profiles, etc.)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY products_tenant_isolation ON products
  USING (tenant_id::text = current_setting('app.tenant_id', true))
  WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

-- Bypass policy ONLY for the dedicated owner-dashboard role used by BE-31 aggregate queries
CREATE POLICY products_owner_dashboard_aggregate ON products
  AS PERMISSIVE
  FOR SELECT
  TO radha_owner_dashboard_role
  USING (true);
```

## TenantScopeMiddleware

```typescript
@Injectable()
export class TenantScopeMiddleware implements NestMiddleware {
  constructor(@InjectDataSource() private readonly dataSource: DataSource) {}

  async use(req: Request, _res: Response, next: NextFunction) {
    const user = req.user as AuthenticatedUser | undefined;
    if (!user) return next();

    // Bind tenant for the duration of this request's DB session
    await this.dataSource.query(`SET LOCAL app.tenant_id = $1`, [user.tenantId]);
    return next();
  }
}
```

## Personal Tenant Bootstrap

```typescript
// server/src/modules/tenants/services/tenant-bootstrap.service.ts
async createPersonalTenantForConsumer(userId: string): Promise<TenantEntity> {
  return this.tenantsRepository.save({
    name: `personal:${userId}`,
    kind: 'personal',
    createdAt: new Date(),
  });
}
```

## ADDENDUM v2 Test Procedures (add 6)

| # | Test |
|---|---|
| T-v2.1 | Direct DB connection with a non-superuser role: any `SELECT` from `products` without `app.tenant_id` set returns 0 rows |
| T-v2.2 | Set `app.tenant_id` to tenant A; assert SELECT returns only tenant A rows |
| T-v2.3 | Property test: For all (tenant_a, tenant_b, payload), creating data in tenant_a then connecting as tenant_b returns 0 rows |
| T-v2.4 | Consumer signup creates a personal tenant with `kind='personal'` |
| T-v2.5 | TenantScopeMiddleware blocks request without `tenant_id` resolution and returns 403 |
| T-v2.6 | App Owner Dashboard role bypasses RLS only for aggregate-allowed endpoints (BE-31 dependency) |

## ADDENDUM v2 Q&A (add 3)

- **Q-v2.1**: What happens if a developer forgets to apply `TenantScopeMiddleware` to a new endpoint?
- **Q-v2.2**: How does the system handle background jobs that run without a request-bound tenant?
- **Q-v2.3**: When App Owner Dashboard aggregate queries run, how is the privacy boundary from Req 15 enforced at the SQL layer?

## ADDENDUM v2 Sign-off

- [ ] RLS enabled and policies tested
- [ ] TenantScopeMiddleware live on every tenant-scoped controller
- [ ] Property tests pass for cross-tenant isolation
- [ ] Personal tenant bootstrap wired into Consumer signup
- [ ] App Owner Dashboard role correctly scoped

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-09 ADDENDUM v2**
