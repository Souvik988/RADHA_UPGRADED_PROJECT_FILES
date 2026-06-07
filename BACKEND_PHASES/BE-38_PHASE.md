# Phase BE-38: Expiry Calendar (Consumer)

## Phase Metadata
- **Phase ID**: BE-38
- **Depends On**: BE-09 v2, BE-36 (family sharing), BE-08 v2 (entitlements), BE-18 (existing expiry tracking)
- **Estimated Duration**: 1-2 days

## Goal
Per Req 30, deliver `GET /api/v1/consumer/expiry-calendar?month=YYYY-MM` returning per-day product counts and lists for the requested month, color-coded green/yellow/red. Premium Consumer view includes Family Sharing members; Free Consumer is limited to the user's 5 saved products.

## Schema
Reuse `saved_products` (consumer side). Add a per-saved-product `expires_at` column if not already present.
```sql
ALTER TABLE saved_products
  ADD COLUMN IF NOT EXISTS expires_at DATE,
  ADD COLUMN IF NOT EXISTS marked_consumed_at TIMESTAMPTZ;
CREATE INDEX idx_saved_products_user_expires ON saved_products(user_id, expires_at) WHERE marked_consumed_at IS NULL;
```

## Endpoint
```typescript
@Controller('/api/v1/consumer/expiry-calendar')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('consumer')
export class ExpiryCalendarController {
  @Get('/')
  async byMonth(
    @CurrentUser() user: AuthenticatedUser,
    @Query('month') month: string,        // 'YYYY-MM'
  ): Promise<ExpiryCalendarMonthDto> {
    return this.svc.byMonth(user.id, month);
  }

  @Post('/saved-products/:id/consumed')
  markConsumed(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.svc.markConsumed(user.id, id);
  }

  @Delete('/saved-products/:id')
  remove(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.svc.remove(user.id, id);
  }
}
```

## Service
Selects union of `saved_products` for the user + (if Premium) for all linked family members.

## SOP
**Tests (15)**: months across timezone boundaries, color-coding rules, premium union with family, free quota cap of 5, mark-consumed, remove, RLS denies cross-tenant, performance < 300ms for 200 products, JSON response shape, query param validation, future months allowed, past months allowed (read-only), DST/timezone correctness for IST, expired-already products color, no double-count when family member shares same product.

**Q&A (8)**: How does the calendar handle products with no expiry date? How is "yellow window" configured per category vs global? How does the response support i18n for month labels? Can the calendar be exported to ICS? How does it interact with Recall_Alerts? Performance on heavy users (500+ saved products)? Caching policy? How are "consumed" entries archived?

### Sign-off (standard).

---
**END OF BE-38**
