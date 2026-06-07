# Phase BE-45: Image OCR Scan Fallback

## Phase Metadata
- **Phase ID**: BE-45
- **Depends On**: BE-13 v2 (presigned URLs), BE-22 v2 (Vision provider), BE-11 v2 (OFF upsert), BE-32 v2 (cache)
- **Estimated Duration**: 2 days

## Goal
Per Req 38, when the Mobile_App can't decode a barcode within 2 seconds, user takes a photo of the packaging. Backend identifies the product via Cloud Vision (or self-hosted ML), upserts into Product_Catalog, and returns the same response shape as a normal scan.

## Files
- `server/src/modules/scan/controllers/image-fallback.controller.ts`
- `server/src/modules/scan/services/image-fallback.service.ts`
- `server/src/modules/scan/dto/image-fallback.dto.ts`

## API
```typescript
@Controller('/api/v1/scan')
export class ImageFallbackController {
  @Post('/image-fallback')
  @UseGuards(JwtAuthGuard)
  async fallback(
    @Body() dto: ImageFallbackDto,    // { s3_object_key, locale }
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<BasicScanOutputDto | ComprehensiveScanOutputDto | { matched: false }> {
    const result = await this.svc.identify(dto.s3ObjectKey, user.id);
    if (!result.matched) return { matched: false };
    await this.off.fetchOrUpsert(result.ean);
    return result.scanOutput;
  }
}
```

## Service flow
1. Read S3 object via presigned GET
2. Send to Google Cloud Vision (₹0.001/image) or self-hosted model
3. Parse name + brand from OCR
4. Search Product_Catalog → if match, return scan output
5. Else query OFF by name+brand → if match, upsert and return
6. Else return `{ matched: false }`
7. Track cost per tenant in BE-22 cost tracker

## SOP
**Tests (15)**: typical packaging photo identifies within 8 sec; low-light fails gracefully; cost tracked correctly; cache hit on previously seen image; self-host switch works; OFF upsert idempotent; non-food image returns no match; multi-language OCR; size limit enforced (5MB max); fall back to manual creation if no match; sentry captures failures; lifecycle rule cleans up images after 7 days; concurrent calls dedupe; PostHog event emitted; tenant scope on outputs.

**Q&A (8)**: How is the image preprocessed (resize, contrast)? Self-hosted ML option spec? Cost ceiling per tenant? How are user-uploaded images audited for inappropriate content? How does this interact with BE-56 community barcode learning (different prefix, different acceptance)? What if Vision returns multiple candidates? How does latency variance affect Mobile_App UX (loading state)? Backup plan if Cloud Vision is down?

### Sign-off (standard).

---
**END OF BE-45**
