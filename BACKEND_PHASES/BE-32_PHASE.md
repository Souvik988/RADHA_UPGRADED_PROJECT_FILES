# Phase BE-32: Performance Optimization & Caching

## Phase Metadata

- **Phase ID**: BE-32
- **Phase Name**: Performance Optimization & Caching
- **Section**: Backend Execution — Hardening Layer
- **Depends On**: BE-01 to BE-31
- **Blocks**: BE-33
- **Estimated Duration**: 3 days
- **Complexity**: High

## Goal

Make RADHA blazing fast at scale: comprehensive Redis caching strategy, database query optimization, connection pool tuning, response compression, slow query monitoring, CDN configuration, background job optimization, prepared statement reuse, materialized views for heavy aggregations, and observability for ongoing optimization.

## Why This Phase Matters

Performance = retention. If RADHA is slow:
- Mobile app feels broken
- Reports timeout
- Users abandon
- Reviews suffer
- Operating costs spike

Without optimization:
- Cannot scale to 10K+ users
- AWS costs balloon
- Database becomes bottleneck
- API timeouts increase

## Prerequisites

- [ ] BE-01 to BE-31 completed
- [ ] All features functional
- [ ] Redis available
- [ ] Monitoring tools ready

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/common/cache/cache.module.ts` | Module |
| `server/src/common/cache/cache.service.ts` | Cache abstraction |
| `server/src/common/cache/cache-key.builder.ts` | Key builder |
| `server/src/common/cache/decorators/cacheable.decorator.ts` | Method cache |
| `server/src/common/cache/strategies/lru-cache.strategy.ts` | In-memory |
| `server/src/common/cache/strategies/redis-cache.strategy.ts` | Distributed |
| `server/src/db/optimizations/connection-pool.config.ts` | Pool tuning |
| `server/src/db/optimizations/prepared-statements.ts` | Reusable queries |
| `server/src/db/optimizations/slow-query-monitor.ts` | Monitoring |
| `server/src/db/migrations/XXX_materialized_views.sql` | Heavy aggregations |
| `server/src/observability/metrics/prometheus-metrics.service.ts` | Metrics |
| `server/src/observability/metrics/custom-metrics.ts` | App metrics |
| `server/src/common/middleware/compression.middleware.ts` | Response compression |
| `server/src/common/middleware/etag.middleware.ts` | HTTP caching |
| `server/src/jobs/cron/refresh-materialized-views.cron.ts` | View refresh |
| `server/src/jobs/cron/cleanup-cache.cron.ts` | Cache cleanup |
| `server/src/integrations/aws/cloudfront/cache-policies.ts` | CDN config |
| All `__tests__/` files |

## Service Interfaces

```typescript
export interface ICacheService {
  // Basic operations
  get<T>(key: string): Promise<T | null>;
  set<T>(key: string, value: T, ttlSeconds?: number): Promise<void>;
  delete(key: string): Promise<void>;
  
  // Patterns
  getOrSet<T>(key: string, factory: () => Promise<T>, ttlSeconds?: number): Promise<T>;
  invalidatePattern(pattern: string): Promise<number>;
  
  // Bulk
  mget<T>(keys: string[]): Promise<(T | null)[]>;
  mset<T>(entries: Array<{ key: string; value: T; ttl?: number }>): Promise<void>;
  
  // Stats
  getStats(): Promise<CacheStats>;
  
  // Health
  isHealthy(): Promise<boolean>;
}

export interface CacheStats {
  hits: number;
  misses: number;
  hitRate: number;
  size: number;
  memoryUsageMb: number;
  evictions: number;
}

export interface CacheConfig {
  ttl: number;
  maxKeys?: number;
  invalidateOn?: string[];
  layered?: boolean; // L1 (memory) + L2 (Redis)
}
```

## Implementation Code

### 1. Cache Service (Multi-Layer)

```typescript
// server/src/common/cache/cache.service.ts
import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import Redis from 'ioredis';
import { LRUCache } from 'lru-cache';
import { ConfigService } from '../../config/config.service';
import { ICacheService, CacheStats } from './cache.types';

@Injectable()
export class CacheService implements ICacheService, OnModuleInit {
  private readonly logger = new Logger(CacheService.name);
  
  private redis!: Redis;
  
  // L1: In-memory cache (fastest, per-instance)
  private memoryCache!: LRUCache<string, any>;
  
  // Stats
  private hits = 0;
  private misses = 0;
  private evictions = 0;

  constructor(private readonly config: ConfigService) {}

  onModuleInit() {
    // Initialize Redis (L2)
    this.redis = new Redis({
      host: this.config.redis.host,
      port: this.config.redis.port,
      password: this.config.redis.password,
      keyPrefix: this.config.redis.keyPrefix + 'cache:',
      enableReadyCheck: true,
      retryStrategy: (times) => {
        return Math.min(times * 50, 2000);
      },
    });

    // Initialize LRU (L1)
    this.memoryCache = new LRUCache({
      max: 10000,                    // Max 10K items
      ttl: 60000,                    // 1 min default
      updateAgeOnGet: false,
      allowStale: false,
      dispose: () => {
        this.evictions++;
      },
    });

    this.logger.log('Multi-layer cache initialized');
  }

  async get<T>(key: string): Promise<T | null> {
    // Try L1 first
    const fromMemory = this.memoryCache.get(key) as T | undefined;
    if (fromMemory !== undefined) {
      this.hits++;
      return fromMemory;
    }
    
    // Try L2 (Redis)
    try {
      const fromRedis = await this.redis.get(key);
      if (fromRedis) {
        const parsed = JSON.parse(fromRedis) as T;
        // Populate L1 for next time
        this.memoryCache.set(key, parsed);
        this.hits++;
        return parsed;
      }
    } catch (error) {
      this.logger.error('Redis get failed', { key, error });
    }
    
    this.misses++;
    return null;
  }

  async set<T>(key: string, value: T, ttlSeconds: number = 300): Promise<void> {
    // Set in both layers
    this.memoryCache.set(key, value, { ttl: Math.min(ttlSeconds * 1000, 60000) });
    
    try {
      await this.redis.setex(key, ttlSeconds, JSON.stringify(value));
    } catch (error) {
      this.logger.error('Redis set failed', { key, error });
    }
  }

  async delete(key: string): Promise<void> {
    this.memoryCache.delete(key);
    
    try {
      await this.redis.del(key);
    } catch (error) {
      this.logger.error('Redis delete failed', { key, error });
    }
  }

  async getOrSet<T>(
    key: string,
    factory: () => Promise<T>,
    ttlSeconds: number = 300,
  ): Promise<T> {
    const cached = await this.get<T>(key);
    if (cached !== null) return cached;
    
    const value = await factory();
    await this.set(key, value, ttlSeconds);
    return value;
  }

  async invalidatePattern(pattern: string): Promise<number> {
    let deleted = 0;
    
    // Invalidate from L1
    for (const key of this.memoryCache.keys()) {
      if (this.matchesPattern(key, pattern)) {
        this.memoryCache.delete(key);
        deleted++;
      }
    }
    
    // Invalidate from L2 (use SCAN for production)
    try {
      const stream = this.redis.scanStream({
        match: pattern,
        count: 100,
      });
      
      const keys: string[] = [];
      for await (const batch of stream) {
        keys.push(...batch);
      }
      
      if (keys.length > 0) {
        await this.redis.del(...keys);
        deleted += keys.length;
      }
    } catch (error) {
      this.logger.error('Redis pattern invalidation failed', { pattern, error });
    }
    
    return deleted;
  }

  async mget<T>(keys: string[]): Promise<(T | null)[]> {
    if (keys.length === 0) return [];
    
    // Check L1 first
    const results: (T | null)[] = [];
    const missingIndices: number[] = [];
    const missingKeys: string[] = [];
    
    for (let i = 0; i < keys.length; i++) {
      const fromMemory = this.memoryCache.get(keys[i]) as T | undefined;
      if (fromMemory !== undefined) {
        results.push(fromMemory);
        this.hits++;
      } else {
        results.push(null);
        missingIndices.push(i);
        missingKeys.push(keys[i]);
      }
    }
    
    // Get missing from L2
    if (missingKeys.length > 0) {
      try {
        const fromRedis = await this.redis.mget(...missingKeys);
        for (let j = 0; j < fromRedis.length; j++) {
          if (fromRedis[j]) {
            const parsed = JSON.parse(fromRedis[j]!) as T;
            results[missingIndices[j]] = parsed;
            this.memoryCache.set(missingKeys[j], parsed);
            this.hits++;
          } else {
            this.misses++;
          }
        }
      } catch (error) {
        this.logger.error('Redis mget failed', { error });
      }
    }
    
    return results;
  }

  async mset<T>(entries: Array<{ key: string; value: T; ttl?: number }>): Promise<void> {
    const pipeline = this.redis.pipeline();
    
    for (const entry of entries) {
      this.memoryCache.set(entry.key, entry.value);
      pipeline.setex(entry.key, entry.ttl || 300, JSON.stringify(entry.value));
    }
    
    try {
      await pipeline.exec();
    } catch (error) {
      this.logger.error('Redis mset failed', { error });
    }
  }

  async getStats(): Promise<CacheStats> {
    const total = this.hits + this.misses;
    const memoryInfo = await this.redis.info('memory').catch(() => '');
    const memMatch = memoryInfo.match(/used_memory:(\d+)/);
    const memoryBytes = memMatch ? parseInt(memMatch[1]) : 0;
    
    return {
      hits: this.hits,
      misses: this.misses,
      hitRate: total > 0 ? this.hits / total : 0,
      size: this.memoryCache.size,
      memoryUsageMb: Math.round((memoryBytes / 1024 / 1024) * 100) / 100,
      evictions: this.evictions,
    };
  }

  async isHealthy(): Promise<boolean> {
    try {
      const result = await this.redis.ping();
      return result === 'PONG';
    } catch {
      return false;
    }
  }

  private matchesPattern(key: string, pattern: string): boolean {
    const regex = new RegExp('^' + pattern.replace(/\*/g, '.*') + '$');
    return regex.test(key);
  }
}
```

### 2. Cacheable Decorator

```typescript
// server/src/common/cache/decorators/cacheable.decorator.ts
import { Inject } from '@nestjs/common';
import { CacheService } from '../cache.service';

interface CacheableOptions {
  ttl?: number;
  keyGenerator?: (args: any[]) => string;
  invalidateOn?: string[];
}

export function Cacheable(prefix: string, options: CacheableOptions = {}) {
  const ttl = options.ttl || 300; // 5 min default
  
  return function (target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;
    
    descriptor.value = async function (...args: any[]) {
      // Get cache service from instance (must be injected)
      const cacheService = (this as any).cacheService as CacheService;
      if (!cacheService) {
        // Cache service not available, just execute
        return originalMethod.apply(this, args);
      }
      
      // Build cache key
      const key = options.keyGenerator
        ? options.keyGenerator(args)
        : `${prefix}:${propertyKey}:${JSON.stringify(args)}`;
      
      return cacheService.getOrSet(
        key,
        () => originalMethod.apply(this, args),
        ttl,
      );
    };
    
    return descriptor;
  };
}

// Usage example:
// @Cacheable('products', { ttl: 600 })
// async findById(id: string) { ... }
```

### 3. Materialized Views Migration

```sql
-- server/src/db/migrations/XXX_materialized_views.sql

-- Tenant statistics (refreshed daily)
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_tenant_stats AS
SELECT 
  t.id as tenant_id,
  t.name,
  ts.plan_code,
  ts.status,
  
  -- Counts
  (SELECT COUNT(*) FROM stores WHERE tenant_id = t.id AND deleted_at IS NULL) as store_count,
  (SELECT COUNT(*) FROM users WHERE tenant_id = t.id AND deleted_at IS NULL) as user_count,
  (SELECT COUNT(*) FROM products WHERE tenant_id = t.id AND deleted_at IS NULL) as product_count,
  
  -- Last 30 days
  (SELECT COUNT(*) FROM scan_items WHERE tenant_id = t.id AND scanned_at >= NOW() - INTERVAL '30 days') as scans_30d,
  (SELECT COUNT(*) FROM reports WHERE tenant_id = t.id AND created_at >= NOW() - INTERVAL '30 days') as reports_30d,
  
  -- Activity
  (SELECT MAX(scanned_at) FROM scan_items WHERE tenant_id = t.id) as last_scan_at,
  (SELECT MAX(last_login_at) FROM users WHERE tenant_id = t.id) as last_login_at,
  
  -- Costs
  (SELECT COALESCE(SUM(cost), 0) FROM ai_usage_log WHERE tenant_id = t.id AND year_month = TO_CHAR(NOW(), 'YYYY-MM')) as ai_cost_this_month
  
FROM tenants t
LEFT JOIN tenant_subscriptions ts ON ts.tenant_id = t.id
WHERE t.deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_tenant_stats_id ON mv_tenant_stats(tenant_id);
CREATE INDEX IF NOT EXISTS idx_mv_tenant_stats_plan ON mv_tenant_stats(plan_code);

-- Refresh function
CREATE OR REPLACE FUNCTION refresh_tenant_stats() RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_tenant_stats;
END;
$$ LANGUAGE plpgsql;

-- Daily product activity (for trending)
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_daily_product_activity AS
SELECT 
  DATE(scanned_at) as date,
  product_id,
  tenant_id,
  store_id,
  COUNT(*) as scan_count,
  COUNT(DISTINCT user_id) as unique_users
FROM scan_items
WHERE scanned_at >= NOW() - INTERVAL '90 days'
GROUP BY DATE(scanned_at), product_id, tenant_id, store_id;

CREATE INDEX IF NOT EXISTS idx_mv_daily_product_date ON mv_daily_product_activity(date);
CREATE INDEX IF NOT EXISTS idx_mv_daily_product_tenant ON mv_daily_product_activity(tenant_id);
```

### 4. Connection Pool Tuning

```typescript
// server/src/db/optimizations/connection-pool.config.ts

export interface PoolConfig {
  max: number;                 // Maximum connections
  idle_timeout: number;        // Seconds before idle conn closed
  connect_timeout: number;     // Seconds to wait for new conn
  max_lifetime: number;        // Max conn lifetime
  prepare: boolean;            // Use prepared statements
  
  // Production tuning
  acquire_timeout?: number;
  reap_interval?: number;
}

export function getPoolConfig(env: 'dev' | 'staging' | 'prod'): PoolConfig {
  const baseConfig = {
    prepare: true,
    connect_timeout: 5,
  };
  
  switch (env) {
    case 'dev':
      return {
        ...baseConfig,
        max: 10,
        idle_timeout: 30,
        max_lifetime: 1800,
      };
    
    case 'staging':
      return {
        ...baseConfig,
        max: 20,
        idle_timeout: 60,
        max_lifetime: 3600,
      };
    
    case 'prod':
      return {
        ...baseConfig,
        max: 50,                  // Per app instance
        idle_timeout: 30,         // Aggressive idle close
        max_lifetime: 1800,       // 30 min recycle
        acquire_timeout: 10,
        reap_interval: 60,
      };
  }
}

// Total connections = max * num_app_instances
// PostgreSQL default max_connections = 100
// With 5 app instances * 50 max = 250 connections
// Need PostgreSQL: max_connections = 300 (with buffer)
```

### 5. Slow Query Monitor

```typescript
// server/src/db/optimizations/slow-query-monitor.ts
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { DbService } from '../db.service';
import { sql } from 'drizzle-orm';
import { LoggerService } from '../../logging/logger.service';

@Injectable()
export class SlowQueryMonitor {
  private readonly logger = new Logger(SlowQueryMonitor.name);
  
  // Threshold: queries slower than this trigger alerts
  private readonly SLOW_THRESHOLD_MS = 100;
  private readonly CRITICAL_THRESHOLD_MS = 1000;

  constructor(
    private readonly db: DbService,
    private readonly appLogger: LoggerService,
  ) {}

  // Run every hour
  @Cron(CronExpression.EVERY_HOUR)
  async checkSlowQueries(): Promise<void> {
    try {
      // Query pg_stat_statements (must be enabled)
      const result = await this.db.getDb().execute(sql`
        SELECT 
          query,
          calls,
          total_exec_time,
          mean_exec_time,
          max_exec_time,
          rows
        FROM pg_stat_statements
        WHERE mean_exec_time > ${this.SLOW_THRESHOLD_MS}
        ORDER BY mean_exec_time DESC
        LIMIT 20
      `);
      
      const slow = result.rows as any[];
      
      if (slow.length === 0) return;
      
      const critical = slow.filter((r) => Number(r.mean_exec_time) > this.CRITICAL_THRESHOLD_MS);
      
      if (critical.length > 0) {
        this.appLogger.error('Critical slow queries detected', {
          count: critical.length,
          queries: critical.slice(0, 5).map((q) => ({
            query: String(q.query).slice(0, 200),
            meanMs: Number(q.mean_exec_time),
            calls: Number(q.calls),
          })),
        });
      }
      
      if (slow.length > 0) {
        this.appLogger.warn('Slow queries detected', {
          totalCount: slow.length,
          worstQueries: slow.slice(0, 3).map((q) => ({
            query: String(q.query).slice(0, 200),
            meanMs: Number(q.mean_exec_time),
            calls: Number(q.calls),
          })),
        });
      }
    } catch (error) {
      // pg_stat_statements may not be available in dev
      this.logger.warn('Slow query check failed', error);
    }
  }
}
```

### 6. Prometheus Metrics

```typescript
// server/src/observability/metrics/prometheus-metrics.service.ts
import { Injectable, OnModuleInit } from '@nestjs/common';
import { Registry, Counter, Histogram, Gauge, collectDefaultMetrics } from 'prom-client';

@Injectable()
export class PrometheusMetricsService implements OnModuleInit {
  private registry!: Registry;
  
  // Custom metrics
  public httpRequestDuration!: Histogram;
  public httpRequestsTotal!: Counter;
  public dbQueryDuration!: Histogram;
  public cacheHits!: Counter;
  public cacheMisses!: Counter;
  public activeUsers!: Gauge;
  public scansPerMinute!: Counter;
  public aiCalls!: Counter;
  public errorRate!: Counter;

  onModuleInit() {
    this.registry = new Registry();
    
    // Default Node.js metrics
    collectDefaultMetrics({ register: this.registry });
    
    // HTTP request metrics
    this.httpRequestDuration = new Histogram({
      name: 'http_request_duration_seconds',
      help: 'HTTP request duration in seconds',
      labelNames: ['method', 'route', 'status'],
      buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5],
      registers: [this.registry],
    });
    
    this.httpRequestsTotal = new Counter({
      name: 'http_requests_total',
      help: 'Total HTTP requests',
      labelNames: ['method', 'route', 'status'],
      registers: [this.registry],
    });
    
    // Database
    this.dbQueryDuration = new Histogram({
      name: 'db_query_duration_seconds',
      help: 'Database query duration',
      labelNames: ['operation', 'table'],
      buckets: [0.001, 0.01, 0.05, 0.1, 0.5, 1],
      registers: [this.registry],
    });
    
    // Cache
    this.cacheHits = new Counter({
      name: 'cache_hits_total',
      help: 'Total cache hits',
      labelNames: ['cache_layer'],
      registers: [this.registry],
    });
    
    this.cacheMisses = new Counter({
      name: 'cache_misses_total',
      help: 'Total cache misses',
      labelNames: ['cache_layer'],
      registers: [this.registry],
    });
    
    // Business metrics
    this.activeUsers = new Gauge({
      name: 'active_users',
      help: 'Currently active users',
      registers: [this.registry],
    });
    
    this.scansPerMinute = new Counter({
      name: 'scans_total',
      help: 'Total scan items recorded',
      labelNames: ['tenant_id', 'status'],
      registers: [this.registry],
    });
    
    this.aiCalls = new Counter({
      name: 'ai_calls_total',
      help: 'Total AI calls',
      labelNames: ['operation', 'provider', 'success'],
      registers: [this.registry],
    });
    
    this.errorRate = new Counter({
      name: 'errors_total',
      help: 'Total errors',
      labelNames: ['code', 'severity'],
      registers: [this.registry],
    });
  }

  async getMetrics(): Promise<string> {
    return this.registry.metrics();
  }

  recordHttpRequest(method: string, route: string, status: number, duration: number) {
    this.httpRequestDuration.labels(method, route, String(status)).observe(duration / 1000);
    this.httpRequestsTotal.labels(method, route, String(status)).inc();
  }

  recordDbQuery(operation: string, table: string, duration: number) {
    this.dbQueryDuration.labels(operation, table).observe(duration / 1000);
  }

  recordCacheHit(layer: 'l1' | 'l2') {
    this.cacheHits.labels(layer).inc();
  }

  recordCacheMiss(layer: 'l1' | 'l2') {
    this.cacheMisses.labels(layer).inc();
  }

  recordScan(tenantId: string, status: string) {
    this.scansPerMinute.labels(tenantId, status).inc();
  }

  recordAiCall(operation: string, provider: string, success: boolean) {
    this.aiCalls.labels(operation, provider, String(success)).inc();
  }

  recordError(code: string, severity: 'low' | 'medium' | 'high' | 'critical') {
    this.errorRate.labels(code, severity).inc();
  }
}
```

### 7. ETag Middleware

```typescript
// server/src/common/middleware/etag.middleware.ts
import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import * as crypto from 'crypto';

@Injectable()
export class ETagMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction): void {
    const originalSend = res.send.bind(res);
    
    res.send = function (body: any) {
      // Only for GET requests with successful responses
      if (req.method === 'GET' && res.statusCode === 200 && body) {
        const content = typeof body === 'string' ? body : JSON.stringify(body);
        const etag = `"${crypto.createHash('md5').update(content).digest('hex')}"`;
        
        res.setHeader('ETag', etag);
        
        // Check if client has matching etag
        const clientEtag = req.headers['if-none-match'];
        if (clientEtag === etag) {
          res.statusCode = 304;
          return originalSend.call(this, '');
        }
      }
      
      return originalSend.call(this, body);
    };
    
    next();
  }
}
```

### 8. Refresh Materialized Views Cron

```typescript
// server/src/jobs/cron/refresh-materialized-views.cron.ts
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { DbService } from '../../db/db.service';
import { sql } from 'drizzle-orm';

@Injectable()
export class RefreshMaterializedViewsCron {
  private readonly logger = new Logger(RefreshMaterializedViewsCron.name);

  constructor(private readonly db: DbService) {}

  // Refresh tenant stats hourly
  @Cron(CronExpression.EVERY_HOUR)
  async refreshTenantStats(): Promise<void> {
    const start = Date.now();
    try {
      await this.db.getDb().execute(sql`SELECT refresh_tenant_stats()`);
      this.logger.log(`Tenant stats refreshed in ${Date.now() - start}ms`);
    } catch (error) {
      this.logger.error('Failed to refresh tenant stats', error);
    }
  }

  // Refresh product activity daily at 2 AM
  @Cron('0 2 * * *')
  async refreshDailyProductActivity(): Promise<void> {
    try {
      await this.db.getDb().execute(sql`
        REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_product_activity
      `);
      this.logger.log('Daily product activity refreshed');
    } catch (error) {
      this.logger.error('Failed to refresh product activity', error);
    }
  }
}
```

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| GET | `/api/v1/metrics` | Internal | Prometheus metrics endpoint |
| GET | `/api/v1/cache/stats` | Admin | Cache performance |
| POST | `/api/v1/cache/invalidate` | Admin | Manual invalidation |
| GET | `/api/v1/health/db` | Public | DB health |
| GET | `/api/v1/health/cache` | Public | Cache health |
| GET | `/api/v1/health/full` | Internal | Comprehensive health |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-33 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Cache Hit/Miss ✅
**Pass Criteria**: ✅ L1 < 1ms, L2 < 5ms, hit rate > 60%

### Test 2: Cache Invalidation ✅
Pattern-based invalidation:
**Pass Criteria**: ✅ Wildcards work

### Test 3: Materialized View Refresh ✅
**Pass Criteria**: ✅ < 5s refresh time

### Test 4: Slow Query Detection ✅
Force slow query (pg_sleep):
**Expected**: Logged with details
**Pass Criteria**: ✅ Monitoring works

### Test 5: Prometheus Metrics ✅
```bash
curl /metrics
```
**Pass Criteria**: ✅ Standard + custom metrics

### Test 6: Connection Pool Limits ✅
**Pass Criteria**: ✅ Respects max, no exhaustion

### Test 7: ETag Caching ✅
GET with If-None-Match:
**Expected**: 304 if unchanged
**Pass Criteria**: ✅ Bandwidth saved

### Test 8: Compression ✅
Response > 1KB compressed:
**Pass Criteria**: ✅ Content-Encoding: gzip

### Test 9: Performance Improvements ✅
Before/after benchmarks:
- Dashboard load: 2s → 200ms (10x with cache)
- Product lookup: 50ms → 5ms (cached)

**Pass Criteria**: ✅ Significant improvements

### Test 10: Cache Failure Resilience ✅
Stop Redis:
**Expected**: App still works (slower)
**Pass Criteria**: ✅ Graceful degradation

### Test 11: Memory Usage ✅
**Pass Criteria**: ✅ L1 cache stays under limits

### Test 12: Concurrent Cache Access ✅
**Pass Criteria**: ✅ No corruption, consistent

### Test 13: Materialized View Concurrent Refresh ✅
**Pass Criteria**: ✅ No table locks

### Test 14: Load Test (1000 concurrent) ✅
**Pass Criteria**: ✅ < 1% error, < 500ms p99

### Test 15: Cache Stats Accuracy ✅
**Pass Criteria**: ✅ Hit rate calculation correct

## 🎯 Q&A Session

### Q1: Why two-layer cache?
**Expected**: L1 (memory) sub-ms, L2 (Redis) shared, best of both worlds

### Q2: Why materialized views?
**Expected**: Pre-computed expensive aggregations, refresh hourly, query in ms

### Q3: Why prepared statements?
**Expected**: PostgreSQL caches plan, ~30% faster repeated queries

### Q4: Why ETag for GET?
**Expected**: Saves bandwidth, faster clients, server-driven

### Q5: How tune connection pool?
**Expected**: Monitor active connections, scale based on app instances

### Q6: How handle cache stampede?
**Expected**: Lock during regeneration, stale-while-revalidate, jittered TTL

### Q7: When use materialized vs Redis cache?
**Expected**: Materialized for complex aggregations, Redis for hot reads

### Q8: How scale to 100K users?
**Expected**: More app instances, read replicas, partitioning, CDN aggressive caching

## 📝 Sign-Off Checklist

- [ ] All 15 tests pass
- [ ] Performance benchmarks improved
- [ ] Cache hit rate > 60%
- [ ] Slow query monitoring active
- [ ] Metrics endpoint working
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-33**
**☐ CHANGES REQUESTED**

---

**END OF BE-32 — DO NOT PROCEED WITHOUT APPROVAL**


---

# 🔄 ADDENDUM v2 — Requirements Update May 2026

> **Extends Phase BE-32 with the tiered Cache_Layer specified by Req 43.**

## Driver Requirement

- **Req 43** — Cache_Layer uses Redis. Per-resource TTLs:
  - Product details: 24-hour TTL
  - Recall_Alert lookups: 1-hour TTL
  - Common search queries: 5-minute TTL (Req 39)
  - Cache keys are tenant-scoped where applicable.
  - Mobile_App: scan history persisted forever-local in `Local_Database`.
  - Cache invalidation on product update or community-learning approval within 1 second.

## Scope of Update

This phase already provides multi-layer caching (L1 + L2). v2 codifies the per-resource TTLs into a single registry and ensures invalidation hooks fire correctly.

## Files to Modify

| File Path | Change |
|---|---|
| `server/src/common/cache/cache-keys.registry.ts` | New — central TTL registry |
| `server/src/common/cache/cache.service.ts` | Use registry for TTLs |
| `server/src/modules/products/listeners/product-updated.listener.ts` | Invalidate `product:{ean}` on update |

```typescript
export const CACHE_TTL_REGISTRY: Readonly<Record<string, number>> = {
  'product:*':           24 * 60 * 60,   // 24 hours
  'recall:*':            60 * 60,        // 1 hour
  'search:*':            5 * 60,         // 5 minutes
  'health-score:*':      60 * 60,        // 1 hour
  'product-explain:*':   Number.POSITIVE_INFINITY, // permanent (Req 45)
};
```

## ADDENDUM v2 Test Procedures (add 3)

| # | Test |
|---|---|
| T-v2.1 | Setting `product:1234` retrieves within TTL=24h, expires after |
| T-v2.2 | Updating a product fires invalidation within 1 second; next read repopulates |
| T-v2.3 | Cache keys are tenant-scoped where applicable (e.g., `tenant:{id}:saved-products:*`) |

## ADDENDUM v2 Sign-off

- [ ] TTL registry centralized
- [ ] Invalidation hooks live
- [ ] Tenant-scoping verified

**Reviewer Approval (v2)**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

**END OF BE-32 ADDENDUM v2**
