# RADHA AI Modules Architecture

## Purpose

This file is the execution-ready source of truth for all AI, OCR, barcode, product intelligence, health scoring, audit intelligence, and low-cost automation modules in RADHA.

RADHA must remain useful even without expensive AI calls. The default strategy is:

1. Use on-device/free modules first.
2. Use rules where AI is unnecessary.
3. Use open-source/local models where realistic.
4. Use paid cloud AI only as fallback or for high-value summaries.
5. Wrap every AI provider behind backend interfaces so models can be replaced later.

## AI Strategy Summary

| Layer | Primary Choice | Cost Profile | Used For |
|---|---|---:|---|
| On-device barcode | Google ML Kit Barcode Scanning / `mobile_scanner` | Free | EAN/UPC scanning |
| On-device OCR | Google ML Kit Text Recognition | Free | MFG/EXP date scan, label OCR |
| Rules engine | Backend TypeScript rules | Free | Health score, expiry status, EAN validation |
| Public product API | Open Food Facts | Free/open data | Product name, nutrition, ingredients, image when available |
| On-device LLM optional | Gemma 4 E2B/E4B via LiteRT/LiteRT-LM | Free model, device compute | Offline assistant, label explanation, low-risk summarization |
| Server LLM optional | Gemini API free tier first | Free tier / cheap paid tier | Report summaries, nutrition label structuring, manager assistant |
| Image moderation fallback | AWS Rekognition | Paid, free tier may apply for new AWS accounts | Unsafe product/user images, product image checks |
| Speech/OCR advanced later | AWS Transcribe / Textract | Paid | Voice notes, complex document OCR later |

## Recommendation on Gemma 4

Gemma 4 can be used, but not as the first dependency for the MVP.

Use Gemma 4 only for optional/offline AI features after the barcode, OCR, expiry, EAN, and report core is stable.

### Why Gemma 4 is useful

- Runs locally on supported devices.
- Can reduce server AI cost.
- Can support offline or low-connectivity retail workflows.
- Useful for assistant-style explanations and lightweight reasoning.

### Why Gemma 4 should not be the MVP core

- It increases app size and device compatibility complexity.
- Older or low-end Android devices may perform poorly.
- Flutter integration through native bridges/LiteRT may take extra engineering time.
- Health scoring and expiry tracking do not need an LLM.
- Barcode and OCR already have better purpose-built mobile tools.

### Final Gemma 4 usage decision

| Use Case | Use Gemma 4? | Reason |
|---|---:|---|
| Barcode scanning | No | ML Kit is faster and purpose-built |
| Expiry OCR | No | ML Kit Text Recognition is better |
| Health score calculation | No | Rule engine is cheaper and more transparent |
| Product label explanation | Later | Useful for offline explanation |
| Manager assistant | Later | Server Gemini is easier first |
| Audit report summary | Optional later | Use server LLM first for consistency |
| On-device privacy mode | Yes later | Good premium/offline feature |

## AI Modules Execution Matrix

| Module | Business Purpose | MVP Implementation | Free/Cheap Tool | Backend Wrapper | Frontend Usage | Tables | Phase | Upgrade Path |
|---|---|---|---|---|---|---|---:|---|
| Barcode Scanner AI | Scan EAN/UPC quickly | On-device scanner | ML Kit / `mobile_scanner` | `barcode.service.ts` | Flutter scanner screen | products, scans | FE-5 / BE-11 | Add GS1 verification |
| Expiry OCR Assist | Suggest MFG/EXP dates | OCR + date parser + user confirm | ML Kit Text Recognition | `ocr.service.ts` | Expiry entry screen | expiry_records, ai_extractions | FE-6 / BE-12 | Add confidence ranking |
| Product Data Enrichment | Fill missing product details | Open Food Facts lookup + manual fallback | Open Food Facts API | `product-enrichment.service.ts` | Product detail screen | products | BE-11 | Add GS1/retailer feeds |
| Health Score Engine | Healthy/non-healthy indicator | Rule-based scoring | TypeScript rules | `health-score.service.ts` | Product health card | products, health_score_rules | DB-7 / BE-13 | Add nutrition label LLM parser |
| Child Suitability | Flag products for children | Rules: sugar/salt/additives/category | TypeScript rules | `child-suitability.service.ts` | Health indicator screen | products | BE-13 | Add school canteen mode |
| EAN Validation | Verify approved display list | Exact match against uploaded EAN list | SQL + rules | `ean-validation.service.ts` | Scan result screen | ean_lists, ean_list_items, scans | BE-12 | Add mismatch reasons |
| AI Nutrition Label Reader | Extract nutrition and ingredients from photo | Phase 2 OCR + LLM structuring | ML Kit + Gemini free tier | `nutrition-extraction.service.ts` | Product edit/create screen | ai_extractions, products | BE-15 | Add human review queue |
| AI Report Summarizer | Create readable audit summary | LLM only when report generated | Gemini free tier | `ai-report.service.ts` | Report detail screen | reports | BE-15 | Add natural-language analytics |
| AI Anomaly Detector | Find suspicious audit patterns | Rule-based first | SQL queries + rules | `audit-anomaly.service.ts` | Dashboard alert cards | scans, tasks, expiry_records | BE-14 | Add ML model later |
| AI Task Recommendation | Recommend follow-up tasks | Rule-based first | SQL + rules | `task-recommendation.service.ts` | Manager dashboard | tasks, scans | BE-14 | Add LLM explanations |
| AI Product Image Check | Identify product/label from photo | Later only | ML Kit Image Labeling | `product-image-ai.service.ts` | Product capture screen | media_assets, products | Later | Custom model via ML Kit |
| AI Shelf Audit | Compare shelf/display photo | Later only | Custom CV model | `shelf-audit.service.ts` | Shelf audit screen | shelf_audits | Later | Planogram compliance |
| Manager Chat Assistant | Ask questions about audits | Later | Gemini API / Gemma 4 offline | `manager-assistant.service.ts` | Admin/chat screen | reports, scans, tasks | Later | Analytics copilot |

## Google Modules RADHA Should Use

### 1. Google ML Kit Barcode Scanning

Use for mobile barcode/EAN scanning. It runs on device and does not need network access.

Flutter package options:

- `mobile_scanner`
- `google_mlkit_barcode_scanning`

RADHA usage:

- Product lookup scan
- Expiry scan start
- EAN audit scan
- Bulk scan mode

### 2. Google ML Kit Text Recognition

Use for on-device OCR. It is best for MFG/EXP date suggestions and label text extraction.

RADHA usage:

- Manufacturing date OCR
- Expiry date OCR
- Batch number OCR
- Nutrition label OCR
- Ingredient text OCR

Important: OCR must suggest values, not auto-finalize them. User confirmation is required.

### 3. Google ML Kit Image Labeling

Use later for product-image recognition or shelf-photo assistance.

RADHA usage later:

- Detect whether image contains packaged product
- Detect shelf/category patterns
- Assist product image classification

### 4. Gemma 4 + LiteRT / LiteRT-LM

Use later for on-device/offline assistant features.

RADHA usage later:

- Offline explanation of health score
- Offline audit notes summary
- Offline manager assistant for cached data
- Privacy-first product label explanation

Do not use it for initial barcode, expiry, or EAN validation.

### 5. Gemini API Free Tier

Use as the cheapest cloud LLM option for controlled server-side tasks.

RADHA usage:

- Report summary generation
- Product label extraction from OCR text
- Manager-friendly audit explanation
- Corrective action note generation

Keep all Gemini calls behind `ai-provider.interface.ts` so Gemini can be replaced later by Gemma, OpenAI, or another model.

## Free-First AI Implementation Rules

### Rule 1: Do not use an LLM when rules are enough

Use rules for:

- expiry status
- near-expiry threshold
- EAN match
- health score v1
- high sugar/high salt indicator
- child suitability v1
- duplicate scan detection

### Rule 2: Use on-device OCR before server OCR

Use ML Kit Text Recognition first. Only send images to server if:

- user asks for enrichment
- OCR confidence is low
- admin review is needed
- product database needs improvement

### Rule 3: Use LLM only after OCR

Never send raw images to an LLM in MVP. First extract text, then ask LLM to structure text.

### Rule 4: Add confidence and human confirmation

Every AI output should have:

- confidence score
- source field
- user/admin confirmation state
- audit log entry

### Rule 5: Provider abstraction is mandatory

Files:

```text
server/src/modules/ai/ai.module.ts
server/src/modules/ai/interfaces/ai-provider.interface.ts
server/src/modules/ai/providers/gemini.provider.ts
server/src/modules/ai/providers/gemma-local.provider.ts
server/src/modules/ai/providers/rule-engine.provider.ts
server/src/modules/ai/services/ai-report.service.ts
server/src/modules/ai/services/nutrition-extraction.service.ts
server/src/modules/ai/services/audit-anomaly.service.ts
```

## AI Backend File Plan

| File | Purpose | Created Phase | Filled Phase |
|---|---|---:|---:|
| `server/src/modules/ai/ai.module.ts` | Main AI module wiring | BE-3 | BE-15 |
| `server/src/modules/ai/interfaces/ai-provider.interface.ts` | Common provider contract | BE-3 | BE-15 |
| `server/src/modules/ai/providers/rule-engine.provider.ts` | Free deterministic AI substitute | BE-13 | BE-15 |
| `server/src/modules/ai/providers/gemini.provider.ts` | Gemini API wrapper | BE-15 | BE-15 |
| `server/src/modules/ai/providers/gemma-local.provider.ts` | Future local/on-device bridge placeholder | BE-15 | Later |
| `server/src/modules/ai/services/ai-report.service.ts` | Audit summary generation | BE-15 | BE-15 |
| `server/src/modules/ai/services/nutrition-extraction.service.ts` | OCR text to structured nutrition fields | BE-15 | BE-15 |
| `server/src/modules/ai/services/audit-anomaly.service.ts` | Detect abnormal scan/audit patterns | BE-14 | BE-14 |
| `server/src/modules/ocr/ocr.service.ts` | OCR extraction orchestration | BE-12 | BE-12 |
| `server/src/modules/health-score/health-score.service.ts` | Transparent health scoring | BE-13 | BE-13 |

## AI Database Tables

### `ai_extractions`

Stores OCR and AI extraction output.

Common writes:

- expiry image OCR
- nutrition label OCR
- ingredient extraction

Common reads:

- admin review queue
- product enrichment review
- audit trace

Indexes:

- `(source_type, status, created_at desc)`
- `(product_id, created_at desc)`
- `(created_by_user_id, created_at desc)`

### `health_score_rules`

Stores configurable scoring thresholds.

Examples:

- high sugar threshold
- high sodium threshold
- near-expiry category threshold
- child suitability thresholds

Indexes:

- `(category, active)`
- `(rule_type, active)`

### `ai_provider_usage_logs`

Tracks cost and usage.

Fields:

- provider
- model
- feature
- tokens_in
- tokens_out
- estimated_cost
- user_id
- created_at

Indexes:

- `(provider, created_at desc)`
- `(feature, created_at desc)`

## AI API Contracts

### POST `/api/v1/ai/expiry-ocr`

Purpose: parse expiry/MFG date from OCR text or image reference.

Request:

```json
{
  "mediaAssetId": "uuid",
  "rawOcrText": "MFG 05/2026 EXP 11/2026"
}
```

Response:

```json
{
  "manufacturingDate": "2026-05-01",
  "expiryDate": "2026-11-30",
  "batchNumber": null,
  "confidence": 0.82,
  "requiresConfirmation": true
}
```

### POST `/api/v1/ai/nutrition-extract`

Purpose: convert OCR nutrition text into structured product nutrition.

### POST `/api/v1/ai/report-summary`

Purpose: generate manager-friendly audit report summary.

### GET `/api/v1/ai/usage`

Purpose: admin-only AI usage/cost monitoring.

## AI Privacy Rules

- Do not send customer/store private data to free-tier LLM unless necessary.
- Prefer OCR/rules locally or server-side.
- Keep raw product images in S3 with restricted access.
- Log every AI extraction.
- Mark all AI-generated fields as `ai_suggested` until user/admin confirms.
- Do not use LLM output as final compliance decision without human confirmation.

## Build Order

1. Build barcode scanner using ML Kit/mobile scanner.
2. Build product lookup with internal DB + Open Food Facts.
3. Build expiry tracking with manual entry.
4. Add ML Kit OCR date suggestion.
5. Add rule-based health score.
6. Add EAN Excel verification.
7. Add AI report summarizer using Gemini free tier.
8. Add nutrition label OCR + structured extraction.
9. Add Gemma 4 only as optional offline assistant after MVP.
10. Add shelf/image AI later.

## Final Recommendation

For RADHA MVP, the best AI stack is:

- ML Kit Barcode Scanning for scanning.
- ML Kit Text Recognition for expiry/nutrition OCR.
- Open Food Facts API for product data.
- Rule-based health scoring and child suitability.
- Gemini API free tier for report summaries and label structuring.
- Gemma 4 later for offline assistant features.
- AWS Rekognition only as paid fallback for image moderation.

Do not use Gemma 4 as the first MVP engine. Use it as a future advantage.
---

## 2026-05-15 Upgrade Patch: Inventory and Owner Analytics AI Additions

### Added Rule-First AI/Automation Modules
| Module | Business Purpose | MVP Implementation | Free/Cheap Tool | Backend Wrapper | Frontend Usage | Tables | Phase | Upgrade Path |
|---|---|---|---|---|---|---|---:|---|
| Inventory Reorder Suggestion | Suggest products that need restocking | Rule-based min stock + movement velocity | SQL + rules | inventory-insight.service.ts | Manager inventory dashboard | inventory_items,stock_movements,low_stock_alerts | BE-19 | Later ML reorder forecasting |
| Expiry Risk Summary | Summarize expiry exposure by category | Rule-based batch expiry windows | SQL + rules | expiry-risk.service.ts | Client dashboard/report | inventory_batches,expiry_records | BE-19 | LLM narrative summary |
| GRN Quality Warning | Warn if supplier sent short-shelf-life stock | Rule-based supplier/category thresholds | SQL + rules | grn-risk.service.ts | GRN review screen | grn_items,suppliers,inventory_batches | BE-18 | Vendor accountability score |
| Owner Conversion Insight | Explain trial-to-paid funnel | SQL rollup + simple templates | SQL + rules | owner-insight.service.ts | Owner dashboard | owner_daily_metrics,tenant_subscriptions,website_events | BE-22 | LLM business summary |

### AI Boundary
Do not use paid LLMs for basic stock counts, low-stock alerts, GRN posting, or subscription status. These are deterministic business rules.

