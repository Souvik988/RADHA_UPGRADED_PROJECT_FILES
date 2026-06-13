import { Injectable, Logger } from '@nestjs/common';

import { ExternalServiceException } from '@/common/errors/business.exception';
import { ErrorCode } from '@/common/errors/error-codes';
import { ConfigService } from '@/config/config.service';

import { AI_LLM_DEFAULT_TIMEOUT_MS, AI_OPERATION_UNIT_COST } from '../ai.constants';
import type { AiProvider, ILlmProvider, LlmOptions, LlmResult } from '../types/ai.types';

/**
 * Google Gemini LLM provider (Generative Language API, v1beta).
 *
 * Backs the same `ILlmProvider` contract as `OpenAiLlmProvider` so the
 * ingredient explainer (Req 45) and report-summary generation
 * (`FEATURE_LLM_SUMMARIES`) can run on Gemini. Uses the REST endpoint
 * via the global `fetch` (no SDK dependency) — mirrors the MSG91 /
 * Open Food Facts integration style.
 *
 * Configuration (read from `process.env` directly, matching the
 * `OpenAiLlmProvider` decision not to expand the shared typed env
 * schema for optional AI keys):
 *   - `GEMINI_API_KEY` — required to activate the provider.
 *   - `GEMINI_MODEL`   — optional, defaults to `gemini-2.5-flash`.
 *
 * A hard wall-clock timeout is enforced via `AbortController` so a
 * hung upstream can never exceed `options.timeoutMs` (default 10 s per
 * Req 45 / T-v2.3).
 */
@Injectable()
export class GeminiLlmProvider implements ILlmProvider {
  readonly name: AiProvider = 'gemini';
  private readonly logger = new Logger(GeminiLlmProvider.name);
  private static readonly BASE_URL =
    'https://generativelanguage.googleapis.com/v1beta/models';

  constructor(private readonly config: ConfigService) {}

  isConfigured(): boolean {
    if (this.config.isTest) return false;
    return Boolean(process.env.GEMINI_API_KEY);
  }

  async complete(prompt: string, options: LlmOptions = {}): Promise<LlmResult> {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new ExternalServiceException(
        'Gemini',
        new Error('GEMINI_API_KEY not configured'),
        ErrorCode.AI_SERVICE_ERROR,
      );
    }

    const start = Date.now();
    const timeoutMs = options.timeoutMs ?? AI_LLM_DEFAULT_TIMEOUT_MS;
    const model = process.env.GEMINI_MODEL ?? 'gemini-2.5-flash';
    const maxTokens = options.maxTokens ?? 512;
    const temperature = options.temperature ?? 0.3;

    const url = `${GeminiLlmProvider.BASE_URL}/${encodeURIComponent(model)}:generateContent?key=${apiKey}`;
    const requestBody = {
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        temperature,
        maxOutputTokens: maxTokens,
      },
    };

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(requestBody),
        signal: controller.signal,
      });

      if (!res.ok) {
        const detail = await res.text().catch(() => '');
        throw new Error(`Gemini API returned ${res.status}: ${detail.slice(0, 300)}`);
      }

      const body = (await res.json()) as GeminiGenerateResponse;
      const candidate = body.candidates?.[0];
      const text =
        candidate?.content?.parts
          ?.map((p) => p.text ?? '')
          .join('')
          .trim() ?? '';
      const tokensUsed = body.usageMetadata?.totalTokenCount ?? 0;
      const cost = AI_OPERATION_UNIT_COST['report-summary'];

      return {
        text,
        tokensUsed,
        cost,
        provider: 'gemini',
        durationMs: Date.now() - start,
        truncated: candidate?.finishReason === 'MAX_TOKENS',
      };
    } catch (err) {
      const reason =
        (err as Error).name === 'AbortError'
          ? new Error(`Gemini request timed out after ${timeoutMs}ms`)
          : (err as Error);
      this.logger.error(`gemini.complete.failed: ${reason.message}`);
      throw new ExternalServiceException('Gemini', reason, ErrorCode.AI_SERVICE_ERROR);
    } finally {
      clearTimeout(timer);
    }
  }
}

/** Minimal shape of the Gemini `generateContent` response we consume. */
interface GeminiGenerateResponse {
  candidates?: Array<{
    content?: { parts?: Array<{ text?: string }> };
    finishReason?: string;
  }>;
  usageMetadata?: {
    promptTokenCount?: number;
    candidatesTokenCount?: number;
    totalTokenCount?: number;
  };
}
