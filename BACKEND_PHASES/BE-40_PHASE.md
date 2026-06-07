# Phase BE-40: AI Ingredient Explainer (LLM)

## Phase Metadata
- **Phase ID**: BE-40
- **Depends On**: BE-22 v2 (LLM provider abstraction), BE-32 v2 (cache), BE-42 (i18n)
- **Estimated Duration**: 2 days

## Goal
Implement Req 45. `GET /api/v1/ingredients/{ingredient_slug}/explanation` returns plain-language explanation of an ingredient. Cache forever in DB; LLM only on first request per ingredient.

## Schema
```sql
CREATE TABLE ingredient_explanations (
  ingredient_slug TEXT PRIMARY KEY,
  description TEXT NOT NULL,
  health_considerations TEXT NOT NULL,
  confidence TEXT NOT NULL CHECK (confidence IN ('low','medium','high')),
  language TEXT NOT NULL DEFAULT 'en',
  generated_by TEXT NOT NULL,                 -- 'openai-gpt-4o', 'claude-opus-4.7', etc.
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (ingredient_slug, language)
);
```

## Service
```typescript
async getExplanation(slug: string, locale = 'en'): Promise<IngredientExplanationDto> {
  const cached = await this.repo.findOneBy({ ingredientSlug: slug, language: locale });
  if (cached) return cached;
  try {
    const result = await this.llm.generate({
      system: 'Explain this food ingredient in plain language with health considerations.',
      user: slug,
      language: locale,
      timeoutMs: 10_000,
    });
    return await this.repo.save({ ingredientSlug: slug, language: locale, ...result, generatedBy: this.llm.modelName });
  } catch (e) {
    this.sentry.captureException(e);
    return { ingredientSlug: slug, description: 'Explanation unavailable', healthConsiderations: '', confidence: 'low' };
  }
}
```

## API
`GET /api/v1/ingredients/{slug}/explanation?locale=hi|en|...`

## SOP
**Tests (15)**: cache hit returns < 50ms, cache miss generates and persists, 10s timeout produces graceful fallback, locale parameter respected, fallback to English when locale missing, sentry captures errors, cost tracker increments per call, multi-language same slug stored separately, slug normalization (kebab-case), no LLM call for cached entries, performance with 10k cached ingredients, idempotent (concurrent calls produce single row), property test (any string slug never crashes), tenant-agnostic (cached globally).

**Q&A (8)**: How is the slug derived from raw ingredient text? How are LLM hallucinations mitigated? When the model is updated, how do we mass-regenerate? Cost cap per month? How does this interact with PostHog cost tracking? What is the user-facing UX while the first call generates (loading state)? How do we handle non-English ingredient names? Can users flag explanations as wrong?

### Sign-off (standard).

---
**END OF BE-40**
