import { Injectable } from '@nestjs/common';

import { LoggerService } from '@/logging/logger.service';

import { OffCacheService } from './off-cache.service';
import { OffCircuitBreakerService } from './off-circuit-breaker.service';
import {
  OFF_API_VERSION,
  OFF_BASE_URL,
  OFF_REQUEST_TIMEOUT_MS,
  OFF_USER_AGENT,
} from './off.constants';
import type { OffApiResponse, OffProduct, OffStats } from './off.types';

/**
 * RADHA's only entry point into the Open Food Facts API.
 *
 *   - Always checks `OffCacheService` first.
 *   - Respects `OffCircuitBreakerService` — when the circuit is open,
 *     skips the network entirely and returns `null`. The Mobile_App
 *     gracefully falls back to `found: false` rather than seeing a 502.
 *   - Negative-caches OFF "product not found" so repeat misses don't
 *     hammer the upstream service.
 *   - Tracks `OffStats` for the BE-31 admin dashboard (cache hit ratio,
 *     average response time, circuit state).
 */
@Injectable()
export class OpenFoodFactsService {
  private totalRequests = 0;
  private cacheHits = 0;
  private cacheMisses = 0;
  private apiSuccess = 0;
  private apiFailures = 0;
  private readonly responseTimes: number[] = [];

  constructor(
    private readonly cache: OffCacheService,
    private readonly breaker: OffCircuitBreakerService,
    private readonly logger: LoggerService,
  ) {}

  async lookupByEan(ean: string): Promise<OffProduct | null> {
    this.totalRequests += 1;

    const cached = await this.cache.get(ean);
    if (cached) {
      this.cacheHits += 1;
      this.logger.debug('off.cache.hit', { ean, fetchSuccess: cached.fetchSuccess });
      return cached.product;
    }
    this.cacheMisses += 1;

    if (!this.breaker.isAllowed()) {
      this.logger.warn('off.circuit.short_circuit', { ean });
      return null;
    }

    const start = Date.now();
    try {
      const product = await this.fetchByEan(ean);
      this.responseTimes.push(Date.now() - start);
      if (this.responseTimes.length > 100) this.responseTimes.shift();
      this.breaker.recordSuccess();
      this.apiSuccess += 1;

      if (product) {
        await this.cache.setHit(ean, product);
      } else {
        await this.cache.setMiss(ean);
      }
      return product;
    } catch (err) {
      this.breaker.recordFailure();
      this.apiFailures += 1;
      this.logger.error('off.api.failed', {
        ean,
        error: { name: (err as Error).name, message: (err as Error).message },
      });
      return null;
    }
  }

  async isHealthy(): Promise<boolean> {
    try {
      const r = await this.request(
        `${OFF_BASE_URL}/api/${OFF_API_VERSION}/product/3017620422003.json`,
      );
      return r.ok;
    } catch {
      return false;
    }
  }

  getStats(): OffStats {
    const avg =
      this.responseTimes.length > 0
        ? Math.round(this.responseTimes.reduce((a, b) => a + b, 0) / this.responseTimes.length)
        : 0;
    return {
      totalRequests: this.totalRequests,
      cacheHits: this.cacheHits,
      cacheMisses: this.cacheMisses,
      apiSuccess: this.apiSuccess,
      apiFailures: this.apiFailures,
      circuitState: this.breaker.getState(),
      averageResponseMs: avg,
    };
  }

  /** Test seam — overridden in unit tests to avoid live HTTP. */
  protected async request(url: string): Promise<Response> {
    const controller = new AbortController();
    const t = setTimeout(() => controller.abort(), OFF_REQUEST_TIMEOUT_MS);
    try {
      return await fetch(url, {
        method: 'GET',
        headers: { 'User-Agent': OFF_USER_AGENT, Accept: 'application/json' },
        signal: controller.signal,
      });
    } finally {
      clearTimeout(t);
    }
  }

  private async fetchByEan(ean: string): Promise<OffProduct | null> {
    const url = `${OFF_BASE_URL}/api/${OFF_API_VERSION}/product/${ean}.json`;
    const res = await this.request(url);
    if (!res.ok) {
      throw new Error(`OFF API returned ${res.status}`);
    }
    const body = (await res.json()) as OffApiResponse;
    if (body.status !== 1 || !body.product) return null;
    return body.product;
  }
}
