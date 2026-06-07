# Phase BE-08: Authorization Guards & Role System

## Phase Metadata

- **Phase ID**: BE-08
- **Phase Name**: Authorization Guards & Role System
- **Section**: Backend Execution — Security & Identity Layer
- **Depends On**: BE-01 to BE-07
- **Blocks**: All feature phases (BE-09 onwards)
- **Estimated Duration**: 2 days
- **Complexity**: High

## Goal

Implement comprehensive authorization layer: JWT verification guards, role-based access control (RBAC), permission system, tenant scoping enforcement, store-level access control, rate limiting per role, and decorators for clean controller code.

## Why This Phase Matters

Without proper authorization:
- Authenticated users can access ANY data
- Cross-tenant data leaks (catastrophic for SaaS)
- Staff can perform manager actions
- No audit trail of authorization failures
- API susceptible to privilege escalation

This is the **second line of defense** after authentication.

## Prerequisites

- [ ] BE-01 to BE-07 completed
- [ ] JWT working (BE-06)
- [ ] User roles defined (BE-06)
- [ ] Tenant model in place (BE-06)
- [ ] Redis running (for rate limiting)

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/modules/auth/guards/jwt-auth.guard.ts` | Verify JWT, attach user |
| `server/src/modules/auth/guards/roles.guard.ts` | Check user roles |
| `server/src/modules/auth/guards/permissions.guard.ts` | Fine-grained permissions |
| `server/src/modules/auth/guards/tenant-scope.guard.ts` | Enforce tenant isolation |
| `server/src/modules/auth/guards/store-scope.guard.ts` | Enforce store-level access |
| `server/src/modules/auth/guards/optional-jwt.guard.ts` | Optional auth (public+private) |
| `server/src/modules/auth/decorators/auth.decorators.ts` | All auth decorators |
| `server/src/modules/auth/decorators/roles.decorator.ts` | @Roles() |
| `server/src/modules/auth/decorators/permissions.decorator.ts` | @RequirePermissions() |
| `server/src/modules/auth/decorators/public.decorator.ts` | @Public() |
| `server/src/modules/auth/decorators/current-user.decorator.ts` | @CurrentUser() |
| `server/src/modules/auth/decorators/current-tenant.decorator.ts` | @CurrentTenant() |
| `server/src/modules/auth/decorators/current-store.decorator.ts` | @CurrentStore() |
| `server/src/modules/auth/services/permissions.service.ts` | Permission resolution |
| `server/src/modules/auth/services/access-control.service.ts` | High-level access checks |
| `server/src/modules/auth/strategies/jwt.strategy.ts` | Passport JWT strategy |
| `server/src/modules/auth/types/permission.types.ts` | Permission definitions |
| `server/src/modules/auth/constants/permissions.ts` | All permission constants |
| `server/src/modules/auth/constants/role-permissions.map.ts` | Role-to-permission mapping |
| `server/src/common/throttler/throttler.module.ts` | Rate limiting module |
| `server/src/common/throttler/role-based.throttler.ts` | Role-based rate limits |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/auth/services/permissions.service.ts

export interface IPermissionsService {
  getRolePermissions(role: UserRole): Set<Permission>;
  hasPermission(user: AuthenticatedUser, permission: Permission): boolean;
  hasAnyPermission(user: AuthenticatedUser, permissions: Permission[]): boolean;
  hasAllPermissions(user: AuthenticatedUser, permissions: Permission[]): boolean;
  canAccessTenant(user: AuthenticatedUser, tenantId: string): boolean;
  canAccessStore(user: AuthenticatedUser, storeId: string): boolean;
}

// server/src/modules/auth/services/access-control.service.ts

export interface IAccessControlService {
  // Resource-level checks
  canRead(user: AuthenticatedUser, resource: string, resourceId?: string): Promise<boolean>;
  canWrite(user: AuthenticatedUser, resource: string, resourceId?: string): Promise<boolean>;
  canDelete(user: AuthenticatedUser, resource: string, resourceId?: string): Promise<boolean>;
  
  // Action-level checks
  canPerformAction(user: AuthenticatedUser, action: AccessAction): Promise<AccessResult>;
  
  // Throws if denied
  enforce(user: AuthenticatedUser, action: AccessAction): Promise<void>;
}

export interface AccessAction {
  action: string;
  resource: string;
  resourceId?: string;
  metadata?: Record<string, unknown>;
}

export interface AccessResult {
  allowed: boolean;
  reason?: string;
  requiresMfa?: boolean;
}

export interface AuthenticatedUser {
  id: string;
  tenantId: string;
  role: UserRole;
  permissions: Permission[];
  storeIds: string[];
  sessionId: string;
}

export type Permission = 
  // User management
  | 'users:read'
  | 'users:write'
  | 'users:delete'
  | 'users:invite'
  // Product
  | 'products:read'
  | 'products:write'
  | 'products:delete'
  | 'products:bulk-import'
  // Scans
  | 'scans:read'
  | 'scans:write'
  | 'scans:delete'
  | 'scans:export'
  // Tasks
  | 'tasks:read'
  | 'tasks:write'
  | 'tasks:assign'
  | 'tasks:delete'
  // Reports
  | 'reports:read'
  | 'reports:generate'
  | 'reports:export'
  // Inventory
  | 'inventory:read'
  | 'inventory:write'
  | 'inventory:adjust'
  // GRN
  | 'grn:read'
  | 'grn:write'
  | 'grn:post'
  | 'grn:cancel'
  // Subscriptions
  | 'subscriptions:read'
  | 'subscriptions:manage'
  // Owner-only
  | 'owner:dashboard'
  | 'owner:analytics'
  | 'owner:billing'
  // Admin-only
  | 'admin:tenants:read'
  | 'admin:tenants:write'
  | 'admin:platform:settings';
```

## Implementation Code

### 1. JWT Auth Guard

```typescript
// server/src/modules/auth/guards/jwt-auth.guard.ts
import {
  Injectable,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Reflector } from '@nestjs/core';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { RequestContextService } from '../../../common/context/request-context.service';
import { ErrorCode } from '../../../common/errors/error-codes';
import { BusinessException } from '../../../common/errors/business.exception';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(
    private readonly reflector: Reflector,
    private readonly contextService: RequestContextService,
  ) {
    super();
  }

  canActivate(context: ExecutionContext) {
    const isPublic = this.reflector.getAllAndOverride<boolean>(
      IS_PUBLIC_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (isPublic) {
      return true;
    }

    return super.canActivate(context);
  }

  handleRequest<TUser = AuthenticatedUser>(
    err: Error | null,
    user: TUser | null,
    info: Error | undefined,
  ): TUser {
    if (err || !user) {
      if (info?.name === 'TokenExpiredError') {
        throw new BusinessException(ErrorCode.TOKEN_EXPIRED, 'Access token expired');
      }
      if (info?.name === 'JsonWebTokenError') {
        throw new BusinessException(ErrorCode.TOKEN_INVALID, 'Invalid access token');
      }
      throw new BusinessException(
        ErrorCode.AUTHENTICATION_REQUIRED,
        'Authentication required',
      );
    }

    // Set user in request context (CLS)
    this.contextService.set('userId', (user as AuthenticatedUser).id);
    this.contextService.set('tenantId', (user as AuthenticatedUser).tenantId);
    this.contextService.set('role', (user as AuthenticatedUser).role);

    return user;
  }
}
```

### 2. Roles Guard

```typescript
// server/src/modules/auth/guards/roles.guard.ts
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { UserRole } from '../types/auth.types';
import { ErrorCode } from '../../../common/errors/error-codes';
import { BusinessException } from '../../../common/errors/business.exception';
import { AuthenticatedUser } from '../types/permission.types';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user: AuthenticatedUser = request.user;

    if (!user) {
      throw new BusinessException(
        ErrorCode.AUTHENTICATION_REQUIRED,
        'Authentication required',
      );
    }

    const hasRole = requiredRoles.includes(user.role);
    if (!hasRole) {
      throw new BusinessException(
        ErrorCode.ROLE_REQUIRED,
        `One of these roles required: ${requiredRoles.join(', ')}`,
      );
    }

    return true;
  }
}
```

### 3. Permissions Service

```typescript
// server/src/modules/auth/services/permissions.service.ts
import { Injectable } from '@nestjs/common';
import {
  IPermissionsService,
  Permission,
  AuthenticatedUser,
} from '../types/permission.types';
import { UserRole } from '../types/auth.types';
import { ROLE_PERMISSIONS } from '../constants/role-permissions.map';

@Injectable()
export class PermissionsService implements IPermissionsService {
  getRolePermissions(role: UserRole): Set<Permission> {
    return new Set(ROLE_PERMISSIONS[role] || []);
  }

  hasPermission(user: AuthenticatedUser, permission: Permission): boolean {
    if (user.permissions.includes(permission)) return true;
    
    const rolePerms = this.getRolePermissions(user.role);
    return rolePerms.has(permission);
  }

  hasAnyPermission(user: AuthenticatedUser, permissions: Permission[]): boolean {
    return permissions.some((p) => this.hasPermission(user, p));
  }

  hasAllPermissions(user: AuthenticatedUser, permissions: Permission[]): boolean {
    return permissions.every((p) => this.hasPermission(user, p));
  }

  canAccessTenant(user: AuthenticatedUser, tenantId: string): boolean {
    // Admins can access any tenant
    if (user.role === 'admin') return true;
    return user.tenantId === tenantId;
  }

  canAccessStore(user: AuthenticatedUser, storeId: string): boolean {
    if (user.role === 'admin') return true;
    if (user.role === 'owner') return true; // Owner has all stores
    return user.storeIds.includes(storeId);
  }
}
```

### 4. Role-Permission Mapping

```typescript
// server/src/modules/auth/constants/role-permissions.map.ts
import { UserRole } from '../types/auth.types';
import { Permission } from '../types/permission.types';

export const ROLE_PERMISSIONS: Record<UserRole, Permission[]> = {
  admin: [
    // Admin has all permissions
    'users:read', 'users:write', 'users:delete', 'users:invite',
    'products:read', 'products:write', 'products:delete', 'products:bulk-import',
    'scans:read', 'scans:write', 'scans:delete', 'scans:export',
    'tasks:read', 'tasks:write', 'tasks:assign', 'tasks:delete',
    'reports:read', 'reports:generate', 'reports:export',
    'inventory:read', 'inventory:write', 'inventory:adjust',
    'grn:read', 'grn:write', 'grn:post', 'grn:cancel',
    'subscriptions:read', 'subscriptions:manage',
    'owner:dashboard', 'owner:analytics', 'owner:billing',
    'admin:tenants:read', 'admin:tenants:write', 'admin:platform:settings',
  ],
  owner: [
    'users:read', 'users:write', 'users:invite',
    'products:read', 'products:write', 'products:delete', 'products:bulk-import',
    'scans:read', 'scans:write', 'scans:export',
    'tasks:read', 'tasks:write', 'tasks:assign', 'tasks:delete',
    'reports:read', 'reports:generate', 'reports:export',
    'inventory:read', 'inventory:write', 'inventory:adjust',
    'grn:read', 'grn:write', 'grn:post', 'grn:cancel',
    'subscriptions:read', 'subscriptions:manage',
  ],
  manager: [
    'users:read',
    'products:read', 'products:write',
    'scans:read', 'scans:write', 'scans:export',
    'tasks:read', 'tasks:write', 'tasks:assign',
    'reports:read', 'reports:generate', 'reports:export',
    'inventory:read', 'inventory:write',
    'grn:read', 'grn:write', 'grn:post',
  ],
  staff: [
    'products:read',
    'scans:read', 'scans:write',
    'tasks:read', 'tasks:write',
    'inventory:read',
    'grn:read', 'grn:write',
  ],
  auditor: [
    'products:read',
    'scans:read', 'scans:export',
    'tasks:read',
    'reports:read', 'reports:generate', 'reports:export',
    'inventory:read',
    'grn:read',
  ],
};
```

### 5. Decorators

```typescript
// server/src/modules/auth/decorators/auth.decorators.ts
import { SetMetadata } from '@nestjs/common';
import { UserRole } from '../types/auth.types';
import { Permission } from '../types/permission.types';

export const IS_PUBLIC_KEY = 'isPublic';
export const ROLES_KEY = 'roles';
export const PERMISSIONS_KEY = 'permissions';
export const REQUIRE_TENANT_KEY = 'requireTenant';

// @Public() — Skip auth
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);

// @Roles('owner', 'manager') — Require role
export const Roles = (...roles: UserRole[]) => SetMetadata(ROLES_KEY, roles);

// @RequirePermissions('products:write') — Require permission
export const RequirePermissions = (...permissions: Permission[]) =>
  SetMetadata(PERMISSIONS_KEY, permissions);

// @RequireTenant() — Validate tenant scope from request
export const RequireTenant = () => SetMetadata(REQUIRE_TENANT_KEY, true);

// @CurrentUser() — Inject current user
import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { AuthenticatedUser } from '../types/permission.types';

export const CurrentUser = createParamDecorator(
  (field: keyof AuthenticatedUser | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user as AuthenticatedUser;
    return field ? user?.[field] : user;
  },
);

// @CurrentTenant() — Inject tenant ID
export const CurrentTenant = createParamDecorator(
  (_, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return (request.user as AuthenticatedUser)?.tenantId;
  },
);

// @CurrentStore() — Inject store ID from header/param
export const CurrentStore = createParamDecorator(
  (_, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return request.headers['x-store-id'] || request.params.storeId;
  },
);
```

## Database Tables Affected

No new tables. Uses existing:
- `users` — for role lookup
- `user_store_access` — for store scoping (future)
- `audit_logs` — for authorization failures

## API Endpoints

This phase doesn't add endpoints but **secures all existing and future endpoints**.

Example secured endpoint:
```typescript
@Controller('products')
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
export class ProductsController {
  @Post()
  @Roles('owner', 'manager')
  @RequirePermissions('products:write')
  async create(
    @Body() dto: CreateProductDto,
    @CurrentUser() user: AuthenticatedUser,
    @CurrentTenant() tenantId: string,
  ) {
    return this.service.create(dto, tenantId, user.id);
  }
}
```

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-09 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Public Endpoint (No Auth) ✅

```bash
curl http://localhost:3000/api/v1/health
```

**Expected**: 200 OK (no token needed)
**Pass Criteria**: ✅ Public endpoints accessible

---

### Test 2: Protected Endpoint Without Token ✅

```bash
curl http://localhost:3000/api/v1/auth/me
```

**Expected**: 401 with `AUTHENTICATION_REQUIRED`
**Pass Criteria**: ✅ Protected endpoints require auth

---

### Test 3: Expired Token ✅

Use an expired JWT:
```bash
curl http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer <expired-token>"
```

**Expected**: 401 with `TOKEN_EXPIRED`
**Pass Criteria**: ✅ Expired tokens rejected

---

### Test 4: Role-Based Access ✅

Create test endpoint requiring 'manager' role:
```typescript
@Get('test/manager-only')
@Roles('manager', 'owner', 'admin')
testManagerOnly() { return { ok: true }; }
```

**Test with staff token**:
```bash
curl http://localhost:3000/api/v1/test/manager-only \
  -H "Authorization: Bearer <staff-token>"
```

**Expected**: 403 with `ROLE_REQUIRED`
**Pass Criteria**: ✅ Role check blocks unauthorized

---

### Test 5: Permission-Based Access ✅

```typescript
@Post('test/products')
@RequirePermissions('products:write')
testCreateProduct() { return { ok: true }; }
```

Test with auditor (no products:write permission):
**Expected**: 403 with `INSUFFICIENT_PERMISSIONS`
**Pass Criteria**: ✅ Permission check works

---

### Test 6: Tenant Scoping ✅

User from Tenant A tries to access Tenant B data:
```bash
# tenantId in URL: tenant-b
# JWT tenantId: tenant-a
curl http://localhost:3000/api/v1/tenants/tenant-b/data \
  -H "Authorization: Bearer <tenant-a-token>"
```

**Expected**: 403 with `TENANT_ACCESS_DENIED`
**Pass Criteria**: ✅ Cross-tenant access blocked

---

### Test 7: Store Scoping ✅

Staff member tries to access store they don't belong to:
**Expected**: 403 with `STORE_ACCESS_DENIED`
**Pass Criteria**: ✅ Store-level access enforced

---

### Test 8: Owner Override ✅

Owner accesses any store in their tenant:
**Expected**: 200 (success)
**Pass Criteria**: ✅ Owner has access to all tenant stores

---

### Test 9: Admin Override ✅

Admin accesses any tenant:
**Expected**: 200 (success)
**Pass Criteria**: ✅ Admins bypass tenant checks

---

### Test 10: Decorator Composition ✅

```typescript
@Get('test/multi')
@Roles('owner', 'manager')
@RequirePermissions('products:read', 'inventory:read')
testMulti() { return { ok: true }; }
```

Test with role check passing but missing permission:
**Expected**: 403 (must satisfy ALL guards)
**Pass Criteria**: ✅ Multiple guards work together

---

### Test 11: Rate Limiting ✅

Make 200 requests quickly:
**Expected**: After 100 requests/minute, returns 429 `RATE_LIMIT_EXCEEDED`
**Pass Criteria**: ✅ Rate limit enforced

---

### Test 12: Different Limits per Role ✅

- Free trial user: 50 req/min
- Paid user: 100 req/min
- Admin: 1000 req/min

**Pass Criteria**: ✅ Tiered rate limits work

---

### Test 13: Audit Log on Auth Failure ✅

After failed authorization attempt, check audit logs:
```sql
SELECT * FROM audit_logs WHERE action = 'AUTHORIZATION_FAILED';
```

**Expected**: Records logged with user_id, attempted resource, reason
**Pass Criteria**: ✅ Failures auditable

---

### Test 14: Decorators Inject Correctly ✅

```typescript
@Get('test/inject')
testInject(
  @CurrentUser() user: AuthenticatedUser,
  @CurrentUser('id') userId: string,
  @CurrentTenant() tenantId: string,
) {
  return { user, userId, tenantId };
}
```

**Expected**: All decorators return correct values
**Pass Criteria**: ✅ Decorators work

---

### Test 15: Guard Bypass with @Public() ✅

```typescript
@Get('test/public')
@Public()
testPublic() { return { ok: true }; }
```

**Expected**: Accessible without token
**Pass Criteria**: ✅ Public decorator works

---

## 🎯 Q&A Session

### Q1: Why both Roles AND Permissions?

**Expected Answer**:
- **Roles**: Coarse-grained, easy to reason about (manager, staff)
- **Permissions**: Fine-grained, flexible (products:write)
- Roles → Permissions mapping centralized
- Permissions allow custom assignments (special user with extra perms)
- Both layers = defense in depth

---

### Q2: Why tenant scoping at guard level?

**Expected Answer**:
- Single point of enforcement
- Cannot forget in individual controllers
- Catches mistakes early
- Audit trail centralized
- Database-level RLS optional (post-launch)

---

### Q3: Why does admin role bypass tenant checks?

**Expected Answer**:
- RADHA platform admins need cross-tenant access for support
- Limited to small group (RADHA staff only)
- All admin actions audited
- Trade-off: Less isolation but necessary for SaaS operations

---

### Q4: How do you prevent privilege escalation?

**Expected Answer**:
- JWT signed by server (not client-modifiable)
- Role/permissions from DB, not from token
- Refresh fetches latest role from DB
- Token revocation on role change
- Audit logs for role changes

---

### Q5: Why fail-closed (deny by default)?

**Expected Answer**:
- Security principle: When in doubt, deny
- Forgetting `@Roles` doesn't make endpoint public
- Public endpoints must explicitly use `@Public()`
- Reduces accidental exposure
- Industry best practice

---

### Q6: How would you implement custom permissions?

**Expected Answer**:
- User-specific permission overrides (additional)
- Stored in `user_permissions` table
- Permissions service merges role + custom
- Audit log when permissions modified
- UI to manage in admin panel

---

### Q7: Why role-based rate limits?

**Expected Answer**:
- Prevents free-tier abuse
- Allows paid users higher limits
- Admins need flexibility for support
- Trial users limited to prevent freeloading
- Per-tenant rate limits also possible (future)

---

### Q8: How does tenant scoping work with shared resources?

**Expected Answer**:
- Some resources are global (Open Food Facts cache)
- These have NULL tenantId
- Authorization service knows which resources are tenant-scoped
- Read-only global resources are public to all tenants
- Modifications still tenant-scoped

---

## 📝 Sign-Off Checklist

### Functional
- [ ] Public endpoints work without auth
- [ ] Protected endpoints require valid JWT
- [ ] Role checks enforce role membership
- [ ] Permission checks enforce permissions
- [ ] Tenant scoping prevents cross-tenant access
- [ ] Store scoping prevents unauthorized store access
- [ ] Admin role overrides tenant checks
- [ ] Owner role overrides store checks
- [ ] Decorators compose correctly
- [ ] Rate limiting works per role

### Security
- [ ] Cannot bypass guards
- [ ] Cannot modify JWT to escalate
- [ ] All denials logged
- [ ] Audit trail comprehensive
- [ ] Fail-closed (deny by default)
- [ ] No information leakage in error messages

### Tests
- [ ] All 15 tests pass
- [ ] Coverage > 90%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

### Critical Security Checks
- [ ] Tested cross-tenant access (must fail)
- [ ] Tested privilege escalation attempts (must fail)
- [ ] Verified all endpoints have explicit auth declaration
- [ ] No `@Public()` on sensitive endpoints
- [ ] Role-permission mapping reviewed

**☐ APPROVED — Proceed to BE-09**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF BE-08 — DO NOT PROCEED WITHOUT APPROVAL**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **This addendum extends Phase BE-08 with the v2 requirement updates. The original phase content above remains the contract for v1 implementation. This addendum applies on top of v1 and MUST be implemented before BE-08 is signed off in v2 mode.**

## Driver Requirements

- **Req 1 (Updated)** — Add `Consumer` as the 5th user role.
- **Req 26** — Onboarding self-selection determines initial role for new sign-ups (Consumer by default).
- **Req 55** — Pending invitations bypass onboarding and assign Staff/Manager/Auditor on first OTP login.

## Scope of Update

The Authorization layer must now treat `Consumer` as a first-class role with its own permission set, and capability resolution must depend on the User's `subscriptionTier` (Free Consumer vs Premium Consumer) in addition to the role.

## Files to Modify

| File Path | Change |
|---|---|
| `server/src/modules/auth/types/permission.types.ts` | Add `consumer:*` permission strings; add `subscriptionTier` to `AuthenticatedUser` |
| `server/src/modules/auth/constants/permissions.ts` | Add Consumer-specific permissions (see below) |
| `server/src/modules/auth/constants/role-permissions.map.ts` | Map Consumer role → Consumer permissions |
| `server/src/modules/auth/services/permissions.service.ts` | New method `getEntitlements(user) → ConsumerEntitlements` |
| `server/src/modules/auth/decorators/roles.decorator.ts` | Accept `'consumer'` as a valid role argument |
| `server/src/modules/auth/services/access-control.service.ts` | Branch on `subscriptionTier` for Premium-gated resources |
| `server/src/modules/auth/__tests__/consumer-role.spec.ts` | New file |

## New Type Additions

```typescript
// server/src/modules/auth/types/permission.types.ts (additions)

export type UserRole = 'owner' | 'manager' | 'staff' | 'auditor' | 'consumer';

export type SubscriptionTier =
  | 'free_consumer'
  | 'premium_consumer'
  | 'starter'
  | 'growth'
  | 'pro'
  | 'trial_pro';

export interface AuthenticatedUser {
  id: string;
  tenantId: string;          // Personal-scope tenant for Consumers
  role: UserRole;
  permissions: Permission[];
  storeIds: string[];        // Empty for Consumers
  sessionId: string;
  subscriptionTier: SubscriptionTier;     // NEW in v2
  onboardingSegment?: string;             // NEW in v2
  familyPrimaryUserId?: string;           // NEW in v2 — set if user is a linked family member
}

export type Permission =
  // ... existing v1 permissions ...
  // NEW Consumer-specific permissions:
  | 'consumer:scan'
  | 'consumer:save_product'
  | 'consumer:expiry_calendar:read'
  | 'consumer:allergen_profile:read'
  | 'consumer:allergen_profile:write'
  | 'consumer:family_sharing:invite'
  | 'consumer:family_sharing:remove'
  | 'consumer:recall_alerts:read'
  | 'consumer:scan_mode_toggle'
  | 'consumer:shopping_list:read'
  | 'consumer:shopping_list:write'
  | 'business:activate'      // Used by Req 27 Business Activation flow
  | 'onboarding:select_segment';

export interface ConsumerEntitlements {
  scansPerDay: number;          // 50 free / Infinity premium
  savedProductsLimit: number;   // 5 free / Infinity premium
  comprehensiveScanAccess: boolean;
  allergenProfileMaxFamilyMembers: number; // 1 free / 5 premium
  familySharing: boolean;
  expiryCalendar: boolean;
  recallAlerts: boolean;
  multiLanguage: boolean;
  affiliateAlternatives: boolean;
}
```

## New Role-Permissions Map (additions)

```typescript
// server/src/modules/auth/constants/role-permissions.map.ts (additions)

export const CONSUMER_PERMISSIONS: ReadonlySet<Permission> = new Set([
  'consumer:scan',
  'consumer:save_product',
  'consumer:expiry_calendar:read',
  'consumer:allergen_profile:read',
  'consumer:allergen_profile:write',
  'consumer:recall_alerts:read',
  'consumer:scan_mode_toggle',
  'consumer:shopping_list:read',
  'consumer:shopping_list:write',
  'business:activate',
  'onboarding:select_segment',
]);

export const ROLE_PERMISSIONS_MAP: Record<UserRole, ReadonlySet<Permission>> = {
  owner: OWNER_PERMISSIONS,
  manager: MANAGER_PERMISSIONS,
  staff: STAFF_PERMISSIONS,
  auditor: AUDITOR_PERMISSIONS,
  consumer: CONSUMER_PERMISSIONS, // NEW
};
```

## Entitlements Resolver

```typescript
// server/src/modules/auth/services/permissions.service.ts (additions)

private static readonly ENTITLEMENT_TABLE: Record<SubscriptionTier, ConsumerEntitlements> = {
  free_consumer: {
    scansPerDay: 50,
    savedProductsLimit: 5,
    comprehensiveScanAccess: false,
    allergenProfileMaxFamilyMembers: 1,
    familySharing: false,
    expiryCalendar: true,           // limited to 5 saved products by quota
    recallAlerts: true,
    multiLanguage: true,
    affiliateAlternatives: false,
  },
  premium_consumer: {
    scansPerDay: Number.POSITIVE_INFINITY,
    savedProductsLimit: Number.POSITIVE_INFINITY,
    comprehensiveScanAccess: true,
    allergenProfileMaxFamilyMembers: 5,
    familySharing: true,
    expiryCalendar: true,
    recallAlerts: true,
    multiLanguage: true,
    affiliateAlternatives: true,
  },
  trial_pro: { /* business trial entitlements (capped at Starter limits but Pro features) */
    scansPerDay: Number.POSITIVE_INFINITY, savedProductsLimit: Number.POSITIVE_INFINITY,
    comprehensiveScanAccess: true, allergenProfileMaxFamilyMembers: 5, familySharing: true,
    expiryCalendar: true, recallAlerts: true, multiLanguage: true, affiliateAlternatives: true,
  },
  starter: { /* business — none of the consumer extras gated */
    scansPerDay: Number.POSITIVE_INFINITY, savedProductsLimit: Number.POSITIVE_INFINITY,
    comprehensiveScanAccess: false, allergenProfileMaxFamilyMembers: 0, familySharing: false,
    expiryCalendar: false, recallAlerts: false, multiLanguage: true, affiliateAlternatives: false,
  },
  growth: { /* same as starter, higher API quotas */
    scansPerDay: Number.POSITIVE_INFINITY, savedProductsLimit: Number.POSITIVE_INFINITY,
    comprehensiveScanAccess: false, allergenProfileMaxFamilyMembers: 0, familySharing: false,
    expiryCalendar: false, recallAlerts: false, multiLanguage: true, affiliateAlternatives: false,
  },
  pro: { /* same baseline; pro-only features gated separately by webhook/badge phases */
    scansPerDay: Number.POSITIVE_INFINITY, savedProductsLimit: Number.POSITIVE_INFINITY,
    comprehensiveScanAccess: false, allergenProfileMaxFamilyMembers: 0, familySharing: false,
    expiryCalendar: false, recallAlerts: false, multiLanguage: true, affiliateAlternatives: false,
  },
};

getEntitlements(user: AuthenticatedUser): ConsumerEntitlements {
  return PermissionsService.ENTITLEMENT_TABLE[user.subscriptionTier];
}
```

## ADDENDUM v2 Test Procedures (add to SOP — 5 additional)

| # | Test |
|---|---|
| T-v2.1 | Authenticate as a fresh sign-up; assert role is `consumer` and `subscriptionTier` is `free_consumer` |
| T-v2.2 | Assert Consumer cannot access any `owner:*`, `manager:*`, or `staff:*` permission |
| T-v2.3 | Promote user to `premium_consumer` tier; assert `getEntitlements` returns unlimited scans and `comprehensiveScanAccess === true` |
| T-v2.4 | Authenticate via pending-invitation OTP; assert role assigned matches invitation (Staff/Manager/Auditor) and onboarding segment is bypassed |
| T-v2.5 | Attempt to call `consumer:scan_mode_toggle` while authenticated as `staff`; assert 403 (consumer-only permission) |

## ADDENDUM v2 Q&A (add to SOP — 3 additional)

- **Q-v2.1**: How does the system distinguish a Consumer's "personal tenant" from a real business tenant in tenant-scoped queries?
- **Q-v2.2**: When a Consumer upgrades to Premium Consumer, where is the entitlement change persisted and how is it reflected in subsequent JWT payloads?
- **Q-v2.3**: If a user holds an invitation as Staff but their phone has previously created a Consumer account, what is the correct merge behavior and where is it implemented?

## ADDENDUM v2 Sign-off

- [ ] Consumer role added and tested (T-v2.1, T-v2.2)
- [ ] Subscription tier branching tested (T-v2.3)
- [ ] Invitation auto-onboarding tested (T-v2.4)
- [ ] No cross-role permission leakage (T-v2.5)
- [ ] All 8 v1 Q&A + 3 v2 Q&A answered

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-08 ADDENDUM v2 — Continue to BE-09 only after both v1 and v2 sign-offs**
