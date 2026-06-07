# Phase BE-44: Offline-First Sync + Idempotency

## Phase Metadata
- **Phase ID**: BE-44
- **Depends On**: BE-03, BE-09 v2, BE-32 v2
- **Estimated Duration**: 2-3 days

## Goal
Implement Req 37. Backend support for offline-first Mobile_App: idempotency keys on mutating requests, batch sync endpoints, conflict resolution rules, and a clear contract for the on-device Drift/Isar `Local_Database`.

## Schema
```sql
CREATE TABLE idempotency_records (
  key TEXT PRIMARY KEY,
  user_id UUID NOT NULL,
  request_hash TEXT NOT NULL,
  response_status INT NOT NULL,
  response_body JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours')
);
CREATE INDEX idx_idem_expires ON idempotency_records(expires_at);
```

## Idempotency Middleware
```typescript
@Injectable()
export class IdempotencyMiddleware implements NestMiddleware {
  async use(req: Request, res: Response, next: NextFunction) {
    if (!['POST','PUT','PATCH','DELETE'].includes(req.method)) return next();
    const key = req.headers['idempotency-key'] as string;
    if (!key) return next();
    const record = await this.repo.findOneBy({ key });
    if (record) {
      if (record.requestHash !== this.hash(req)) {
        throw new ConflictException('Idempotency-Key reused with different payload');
      }
      res.status(record.responseStatus).json(record.responseBody);
      return;
    }
    res.on('finish', () => {
      // capture response and persist
    });
    next();
  }
}
```

## Bulk Sync Endpoints
- `POST /api/v1/sync/scans` — array of scans with idempotency keys
- `POST /api/v1/sync/saved-products` — array
- `POST /api/v1/sync/allergen-profiles` — array
- `GET /api/v1/sync/changes?since=<cursor>` — server-pull endpoint for changes

## Conflict Resolution
- **Default**: last-write-wins by client timestamp (LamportClock)
- **Critical fields (server-wins always)**: `subscriptions.tier`, `subscriptions.status`, `users.role`, `users.email_verified`

## SOP
**Tests (15)**: same key + same payload returns cached response; same key + different payload → 409; expired keys are rejected as fresh; bulk sync 200 items < 5 sec; offline-queued scan with idempotency key syncs once; conflict resolution last-write-wins; server-wins for critical fields; tenant scope enforced on every sync write; sync changes endpoint cursor-paginated; clock skew tolerated; partial failure: per-item error map; Mobile retries handled; very old offline data (>30 days) flagged; replay attacks blocked; sentry captures sync errors.

**Q&A (8)**: How is Lamport clock implemented? What's the strategy when local DB schema migrates ahead of server? How are Drift/Isar migrations versioned? What happens when an offline-saved Premium feature usage hits a Free tier user post-sync? How is idempotency record cleaned up? Performance under high contention? Sync strategy for the Allergen_Profile table given it's encrypted? How are sync errors surfaced to user?

### Sign-off (standard).

---
**END OF BE-44**
