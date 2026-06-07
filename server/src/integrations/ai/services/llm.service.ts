import { Inject, Injectable } from '@nestjs/common';

import { LoggerService } from '@/logging/logger.service';

import {
  AI_EXPLANATION_RULE_VERSION,
  AI_EXPLANATION_TEXT_MAX,
  AI_LLM_DEFAULT_TIMEOUT_MS,
} from '../ai.constants';
import { AiCircuitBreakerService } from './ai-circuit-breaker.service';
import { AiExplanationCacheRepository } from '../repositories/ai-explanation-cache.repository';
import { MockAiProvider } from '../providers/mock-ai.provider';
import {
  ILlmProvider,
  IngredientExplanationResult,
  LLM_PROVIDER_TOKEN,
  LlmOptions,
  LlmResult,
} from '../types/ai.types';
import { truncateForStorage } from '../utils/ocr-text-parser.utils';

interface SummaryInput {
  reportType?: string;
  storeId?: string;
  summary?: Record<string, unknown>;
  data?: unknown;
}

/**
 * BE-22 — LLM façade.
 *
 *   - Routes generic completions through the active `ILlmProvider`,
 *     guarded by the per-provider circuit breaker.
 *   - Owns the report-summary template fallback so callers can
 *     degrade gracefully when the LLM is disabled or down.
 *   - Owns the ingredient-explainer cache (Req 45 — permanent
 *     caching). On cache hit we skip the LLM entirely; on miss we
 *     call, persist the parsed JSON, and return.
 */
@Injectable()
export class LlmService {
  constructor(
    @Inject(LLM_PROVIDER_TOKEN) private readonly provider: ILlmProvider,
    private readonly mock: MockAiProvider,
    private readonly breaker: AiCircuitBreakerService,
    private readonly cacheRepo: AiExplanationCacheRepository,
    private readonly logger: LoggerService,
  ) {}

  /**
   * Try the active provider, fall back to the mock if the breaker is
   * open or the call fails. Honours `options.timeoutMs` (default 10 s
   * per Req 45 / T-v2.3).
   */
  async complete(prompt: string, options: LlmOptions = {}): Promise<LlmResult> {
    const opts: LlmOptions = {
      ...options,
      timeoutMs: options.timeoutMs ?? AI_LLM_DEFAULT_TIMEOUT_MS,
    };

    if (!this.provider.isConfigured() || !this.breaker.isAllowed(this.provider.name)) {
      return this.mock.complete(prompt, opts);
    }

    try {
      const result = await this.provider.complete(prompt, opts);
      this.breaker.recordSuccess(this.provider.name);
      return result;
    } catch (err) {
      this.breaker.recordFailure(this.provider.name);
      this.logger.warn('ai.llm.fallback_to_mock', {
        provider: this.provider.name,
        error: { name: (err as Error).name, message: (err as Error).message },
      });
      // Return a graceful failure shape rather than throwing — Req 45
      // explicitly demands "graceful failure" on timeout.
      const mockResult = await this.mock.complete(prompt, opts);
      return {
        ...mockResult,
        truncated: true,
      };
    }
  }

  /** Build a deterministic plain-text summary when the LLM is unavailable. */
  buildTemplateSummary(input: SummaryInput): string {
    const summary = (input.summary ?? {}) as Record<string, number | undefined>;
    const parts: string[] = [];
    if (typeof summary.totalScans === 'number') {
      parts.push(`Total scans: ${summary.totalScans}`);
    }
    if (typeof summary.matchedScans === 'number' && typeof summary.totalScans === 'number') {
      const rate =
        summary.totalScans > 0 ? Math.round((summary.matchedScans / summary.totalScans) * 100) : 0;
      parts.push(`Match rate: ${rate}%`);
    }
    if (typeof summary.expiredItems === 'number') {
      parts.push(`Expired items: ${summary.expiredItems}`);
    }
    if (typeof summary.nearExpiryItems === 'number') {
      parts.push(`Near-expiry items: ${summary.nearExpiryItems}`);
    }
    if (parts.length === 0) {
      return 'No data available for summary.';
    }
    return `${input.reportType ?? 'Report'} summary: ${parts.join('. ')}.`;
  }

  /** Generate a report summary, preferring the LLM if configured. */
  async generateSummary(input: SummaryInput, options: LlmOptions = {}): Promise<LlmResult> {
    if (!this.provider.isConfigured()) {
      const text = this.buildTemplateSummary(input);
      return {
        text,
        tokensUsed: 0,
        cost: 0,
        provider: 'mock',
        durationMs: 1,
      };
    }
    const prompt = this.buildSummaryPrompt(input);
    return this.complete(prompt, options);
  }

  /**
   * Generate (or fetch from cache) an ingredient explanation.
   *
   * Implements the Req 45 contract: deterministic, locale-aware,
   * permanently cached. The first call burns budget; every subsequent
   * call for the same `(slug, locale, ruleVersion)` is free.
   */
  async explainIngredient(
    slug: string,
    options: LlmOptions = {},
  ): Promise<IngredientExplanationResult> {
    const locale = options.locale ?? 'en';
    const ruleVersion = AI_EXPLANATION_RULE_VERSION;
    const cacheKey = slug.trim().toLowerCase();

    const cached = await this.cacheRepo.findCached(
      'ingredient-explanation',
      cacheKey,
      locale,
      ruleVersion,
    );
    if (cached) {
      // Best-effort hit counter; failure must not break the response.
      this.cacheRepo.incrementHit(cached.id).catch(() => undefined);
      const payload = cached.response as unknown as IngredientExplanationResult;
      return {
        ...payload,
        slug: cacheKey,
        locale,
        cached: true,
        provider: cached.provider,
        cost: 0,
        durationMs: 0,
      };
    }

    const prompt = this.buildIngredientPrompt(cacheKey, locale);
    const llm = await this.complete(prompt, {
      ...options,
      timeoutMs: options.timeoutMs ?? AI_LLM_DEFAULT_TIMEOUT_MS,
    });

    const parsed = this.parseIngredientResponse(cacheKey, locale, llm.text);
    const payload: IngredientExplanationResult = {
      ...parsed,
      cached: false,
      provider: llm.provider,
      cost: llm.cost,
      durationMs: llm.durationMs,
    };

    // Persist for permanent reuse — failure to persist must not break
    // the response.
    try {
      await this.cacheRepo.upsertCached({
        operation: 'ingredient-explanation',
        cacheKey,
        locale,
        ruleVersion,
        response: payload as unknown as Record<string, unknown>,
        responseText: truncateForStorage(llm.text, AI_EXPLANATION_TEXT_MAX),
        provider: llm.provider,
        cost: String(llm.cost),
        tokensUsed: llm.tokensUsed,
      });
    } catch (err) {
      this.logger.warn('ai.explanation.cache_persist_failed', {
        slug: cacheKey,
        error: { name: (err as Error).name, message: (err as Error).message },
      });
    }

    return payload;
  }

  private buildSummaryPrompt(input: SummaryInput): string {
    const summary = JSON.stringify(input.summary ?? {});
    return [
      'You are an analyst writing a one-paragraph executive summary for a retail audit report.',
      'Be concrete: cite percentages, totals, and the most actionable finding.',
      'Avoid hyperbole. Avoid more than three sentences.',
      `Report type: ${input.reportType ?? 'general'}`,
      `Summary numbers (JSON): ${summary}`,
    ].join('\n');
  }

  private buildIngredientPrompt(slug: string, locale: string): string {
    return [
      `You are a dietary information assistant. Explain the ingredient "${slug}" in plain, non-alarmist language.`,
      `Respond in ${locale === 'en' ? 'English' : locale}.`,
      'Return strict JSON with these keys: title, summary, whatItIs, healthImpact, commonUses (array of strings), childSafetyNote (string or null).',
      'Keep "summary" under 200 characters. Keep all other fields under 500 characters.',
      'Do not include any text outside the JSON object.',
    ].join('\n');
  }

  private parseIngredientResponse(
    slug: string,
    locale: string,
    raw: string,
  ): Omit<IngredientExplanationResult, 'cached' | 'provider' | 'cost' | 'durationMs'> {
    const fallback = {
      slug,
      locale,
      title: this.titleCase(slug),
      summary: 'Information unavailable for this ingredient.',
      whatItIs: 'Not enough data to describe this ingredient yet.',
      healthImpact: 'Health impact information is not yet available.',
      commonUses: [] as string[],
    };
    try {
      // Strip markdown code fences if the LLM ignored the JSON-only directive.
      const cleaned = raw
        .trim()
        .replace(/^```(?:json)?/i, '')
        .replace(/```$/i, '')
        .trim();
      const parsed = JSON.parse(cleaned) as {
        title?: string;
        summary?: string;
        whatItIs?: string;
        healthImpact?: string;
        commonUses?: string[];
        childSafetyNote?: string | null;
      };
      return {
        slug,
        locale,
        title: this.shortString(parsed.title) ?? fallback.title,
        summary: this.shortString(parsed.summary) ?? fallback.summary,
        whatItIs: this.shortString(parsed.whatItIs) ?? fallback.whatItIs,
        healthImpact: this.shortString(parsed.healthImpact) ?? fallback.healthImpact,
        commonUses: Array.isArray(parsed.commonUses)
          ? parsed.commonUses.filter((s): s is string => typeof s === 'string').slice(0, 10)
          : [],
        childSafetyNote: this.shortString(parsed.childSafetyNote ?? undefined),
      };
    } catch {
      return fallback;
    }
  }

  private shortString(s: string | null | undefined): string | undefined {
    if (typeof s !== 'string') return undefined;
    const t = s.trim();
    if (!t) return undefined;
    return t.slice(0, 1000);
  }

  private titleCase(slug: string): string {
    return slug.replace(/[-_]+/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
  }
}
