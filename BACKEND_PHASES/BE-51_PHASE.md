# Phase BE-51: Public Product Profile Pages (SEO)

## Phase Metadata
- **Phase ID**: BE-51
- **Depends On**: BE-10 v2, BE-12 v2, BE-09 v2
- **Estimated Duration**: 2 days

## Goal
Per Req 53, generate `https://radha.app/p/{slug}` for every product in Product_Catalog. Statically rendered via Next.js, revalidated every 24h. Includes name, brand, ingredients, basic Health_Indicator, App download CTA. JSON-LD + canonical + Open Graph for SEO. NO tenant data exposed.

## Files
- `web/marketing/app/p/[slug]/page.tsx` — Next.js static page
- `server/src/modules/public-product/public-product.module.ts`
- `server/src/modules/public-product/services/public-product.service.ts`
- `server/src/modules/public-product/services/slug.service.ts`

## API
- `GET /api/v1/public/products/{slug}` (used by Next.js getStaticProps)
- `GET /api/v1/public/products/sitemap.xml`

## Schema
```sql
ALTER TABLE products ADD COLUMN public_slug TEXT UNIQUE;
ALTER TABLE products ADD COLUMN public_status TEXT NOT NULL DEFAULT 'active'
  CHECK (public_status IN ('active','withdrawn','unsafe'));
```

## Service
- Slug generated as `{kebab(name)}-{ean.slice(-4)}` for uniqueness
- 410 Gone returned for `withdrawn`/`unsafe`
- Tenant data excluded by hard column allow-list

## SOP
**Tests (15)**: page renders within 1s; sitemap generated; canonical tag present; OG tags present; JSON-LD product schema valid; 410 Gone for unsafe; revalidate window 24h; no tenant data leaks (column allow-list test); image lazy-load; mobile-responsive; download CTA dynamic per device; multilanguage hreflang; slug stability across re-renders; sitemap pagination for >50K products; structured data passes Google's rich-results test.

**Q&A (8)**: How does slug change if product name changes? SEO penalties for thin content? robots.txt and sitemap submission strategy? Caching layer in front of Next.js (CloudFront)? Search Console verification? Translations and hreflang strategy? How does this interact with BE-56 community-submitted products (moderation gate before public)? GDPR-style "right to be forgotten" for products user submitted?

### Sign-off (standard).

---
**END OF BE-51**
