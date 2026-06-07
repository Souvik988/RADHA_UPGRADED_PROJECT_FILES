# Phase BE-42: Multi-Language i18n

## Phase Metadata
- **Phase ID**: BE-42
- **Depends On**: BE-04 (logging), BE-12 v2 (comprehensive output)
- **Estimated Duration**: 2-3 days

## Goal
Per Req 34, support English, Hindi, Tamil, Telugu, Bengali, Marathi at both UI and backend response layers. Mobile_App ships translation files; Backend honors `Accept-Language` header on scan/explain endpoints; localized fallback to English when missing.

## Files
- `server/src/common/i18n/i18n.module.ts`
- `server/src/common/i18n/i18n.service.ts`
- `server/src/common/i18n/locales/{en,hi,ta,te,bn,mr}.json`
- `server/src/common/i18n/middleware/accept-language.middleware.ts`
- `server/src/database/migrations/v2/2026XXXX_user_preferred_language.sql`

## Schema
```sql
ALTER TABLE users
  ADD COLUMN preferred_language TEXT NOT NULL DEFAULT 'en'
    CHECK (preferred_language IN ('en','hi','ta','te','bn','mr'));

CREATE TABLE product_translations (
  ean TEXT NOT NULL REFERENCES products(ean) ON DELETE CASCADE,
  language TEXT NOT NULL,
  name TEXT, brand TEXT, ingredients_text TEXT, pros TEXT[], cons TEXT[],
  PRIMARY KEY (ean, language)
);
```

## Middleware
```typescript
@Injectable()
export class AcceptLanguageMiddleware implements NestMiddleware {
  use(req: Request, _res: Response, next: NextFunction) {
    const header = req.headers['accept-language'];
    const supported = ['en','hi','ta','te','bn','mr'];
    req.locale = supported.includes(header as string) ? (header as string) : 'en';
    next();
  }
}
```

## API additions
- `PUT /api/v1/users/me/language` — sets preferred_language
- All scan/explain endpoints accept `Accept-Language`

## SOP
**Tests (15)**: each language file is valid JSON; key parity across all 6 files; missing translation falls back to English; user preferred_language overrides Accept-Language when authenticated; emails sent in user's preferred language; FCM body localized; product translations precedence; Devanagari and Tamil fonts render correctly in PDF reports (BE-21); RTL not required (no Arabic/Hebrew); interpolation safe; pluralization correct for Hindi (singular/plural); user can change language without restart; preferred_language saved per user.

**Q&A (8)**: How are translation files updated post-launch (release pipeline vs OTA)? Translation source — human or LLM? Quality assurance for translations? Any compliance issues with regional language naming of allergens? How are right-to-left languages excluded gracefully? How does i18n interact with BE-40 ingredient explanations? Search ranking by language? How do we measure language adoption?

### Sign-off (standard).

---
**END OF BE-42**
