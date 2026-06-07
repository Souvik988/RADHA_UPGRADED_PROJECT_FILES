# Phase BE-53: Admin Impersonation Tool

## Phase Metadata
- **Phase ID**: BE-53
- **Depends On**: BE-07 (Admin auth), BE-31 v2 (Owner Dashboard), BE-09 v2 (RLS)
- **Estimated Duration**: 2 days

## Goal
Per Req 51, time-limited audited "view as user" capability for RADHA support staff. 60-minute sessions. Reason required. Destructive actions blocked. Full audit trail.

## Schema
```sql
CREATE TABLE impersonation_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_user_id UUID NOT NULL REFERENCES users(id),
  impersonated_user_id UUID NOT NULL REFERENCES users(id),
  reason TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '60 minutes'),
  ended_at TIMESTAMPTZ,
  ended_reason TEXT
);

CREATE TABLE impersonation_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES impersonation_sessions(id) ON DELETE CASCADE,
  request_path TEXT NOT NULL,
  request_method TEXT NOT NULL,
  response_status INT NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

## Service & Guard
```typescript
@Injectable()
export class ImpersonationGuard implements CanActivate {
  canActivate(ctx: ExecutionContext): boolean {
    const req = ctx.switchToHttp().getRequest();
    const session = req.impersonationSession as ImpersonationSession | undefined;
    if (!session) return true;
    if (this.isDestructive(req)) {
      throw new ForbiddenException('Destructive actions blocked during impersonation');
    }
    return true;
  }

  private isDestructive(req: Request): boolean {
    return req.method === 'DELETE' ||
           req.path.includes('/subscriptions/cancel') ||
           req.path.includes('/account/delete');
  }
}
```

## API
- `POST /api/v1/admin/impersonate` (start)
- `DELETE /api/v1/admin/impersonate` (end)
- `GET /api/v1/admin/impersonations/audit` (list)

## SOP
**Tests (15)**: start requires reason; session 60-min cap; auto-revoke on expiry; every action logged; destructive actions blocked; admin role required; impersonation token tagged in JWT; per-action audit row; concurrent sessions allowed; ending session immediately revokes token; impersonated user notified post-hoc by email; logs survive impersonator role removal; PII handling in audit logs; multi-impersonation accounting per support agent.

**Q&A (8)**: How is the impersonation token distinguished from a normal session? When the impersonated user is online, what UX signal do we show? How does this interact with BE-31's privacy boundary? Right of impersonated user to view audit log? Compliance for cross-border support staff? Two-person approval for sensitive actions? How are destructive actions appealed? How are emergency-break-glass paths separated?

### Sign-off (standard).

---
**END OF BE-53**
