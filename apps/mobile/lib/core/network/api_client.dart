/// Retrofit-based API client for the RADHA backend.
///
/// Auth DTOs are re-exported here so existing imports remain stable.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';

import 'package:radha_mobile/core/network/dio_provider.dart';
import 'package:radha_mobile/core/network/dto/ai_dto.dart';
import 'package:radha_mobile/core/network/dto/allergen_profile_dto.dart';
import 'package:radha_mobile/core/network/dto/auth_dto.dart';
import 'package:radha_mobile/core/network/dto/catalog_dto.dart';
import 'package:radha_mobile/core/network/dto/ean_dto.dart';
import 'package:radha_mobile/core/network/dto/expiry_dto.dart';
import 'package:radha_mobile/core/network/dto/grn_dto.dart';
import 'package:radha_mobile/core/network/dto/inventory_dto.dart';
import 'package:radha_mobile/core/network/dto/misc_dto.dart';
import 'package:radha_mobile/core/network/dto/onboarding_dto.dart';
import 'package:radha_mobile/core/network/dto/payment_dto.dart';
import 'package:radha_mobile/core/network/dto/product_dto.dart';
import 'package:radha_mobile/core/network/dto/product_lookup_dto.dart';
import 'package:radha_mobile/core/network/dto/reports_dto.dart';
import 'package:radha_mobile/core/network/dto/saved_product_dto.dart';
import 'package:radha_mobile/core/network/dto/scan_dto.dart';
import 'package:radha_mobile/core/network/dto/subscription_status_dto.dart';
import 'package:radha_mobile/core/network/dto/task_dto.dart';

// Re-export auth DTOs so existing imports from this file keep working.
export 'package:radha_mobile/core/network/dto/auth_dto.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  // ─── Auth ───────────────────────────────────────────────────────────────
  @POST('/api/v1/auth/otp/request')
  Future<OtpRequestResponse> requestOtp(@Body() OtpRequestRequestDto body);

  @POST('/api/v1/auth/otp/verify')
  Future<LoginResponse> verifyOtp(@Body() VerifyOtpRequestDto body);

  @POST('/api/v1/auth/admin/login')
  Future<LoginResponse> adminLogin(@Body() AdminLoginRequestDto body);

  @POST('/api/v1/auth/refresh')
  Future<LoginResponse> refreshToken(@Body() RefreshTokenRequestDto body);

  @POST('/api/v1/auth/logout')
  Future<void> logout();

  @GET('/api/v1/auth/me')
  Future<MeResponse> me();

  // ─── Products ───────────────────────────────────────────────────────────
  @GET('/api/v1/products')
  Future<PaginatedProducts> getProducts({
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });

  @GET('/api/v1/products/{id}')
  Future<ProductResponse> getProduct(@Path('id') String id);

  @POST('/api/v1/products')
  Future<ProductResponse> createProduct(@Body() CreateProductDto body);

  /// Rich lookup with real nutrition (drives the catalog product detail).
  @GET('/api/v1/products/lookup/{ean}')
  Future<ProductLookupResult> getProductLookup(
    @Path('ean') String ean, {
    @Query('includeNutrition') bool includeNutrition = true,
  });

  // ─── Consumer catalog (browse-without-scan) ──────────────────────────────
  @GET('/api/v1/catalog/categories')
  Future<List<CatalogCategory>> getCatalogCategories();

  @GET('/api/v1/catalog/products')
  Future<CatalogBrowsePage> getCatalogProducts({
    @Query('category') String? category,
    @Query('q') String? q,
    @Query('sort') String? sort,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });

  // ─── Scan sessions ────────────────────────────────────────────────────────
  @POST('/api/v1/scan-sessions')
  Future<ScanSessionResponse> createScanSession(
    @Body() CreateScanSessionDto body,
  );

  @GET('/api/v1/scan-sessions/active')
  Future<ScanSessionResponse> getActiveScanSession(
    @Query('storeId') String storeId,
  );

  @GET('/api/v1/scan-sessions/{id}/summary')
  Future<ScanSessionSummary> getScanSessionSummary(@Path('id') String id);

  @POST('/api/v1/scan-sessions/{id}/items')
  Future<ScanItemResultResponse> recordScanItem(
    @Path('id') String id,
    @Body() RecordScanItemDto body,
  );

  @POST('/api/v1/scan-sessions/{id}/end')
  Future<ScanSessionResponse> endScanSession(
    @Path('id') String id,
    @Body() EndScanSessionDto body,
  );

  // ─── EAN approved lists ─────────────────────────────────────────────────
  @POST('/api/v1/ean-lists/validate')
  Future<EanValidationResult> validateEan(@Body() ValidateEanDto body);

  @POST('/api/v1/ean-lists/validate/batch')
  Future<Map<String, EanValidationResult>> validateEanBatch(
    @Body() ValidateEanBatchDto body,
  );

  @GET('/api/v1/ean-lists')
  Future<List<EanListSummary>> getEanLists({
    @Query('storeId') String? storeId,
    @Query('status') String? status,
    @Query('limit') int? limit,
  });

  @POST('/api/v1/ean-lists')
  Future<EanListSummary> createEanList(@Body() CreateEanListDto body);

  @POST('/api/v1/ean-lists/{id}/import')
  Future<EanImportInitResponse> importEanListInline(
    @Path('id') String id,
    @Body() ImportEanInlineDto body,
  );

  @GET('/api/v1/ean-lists/imports/{batchId}')
  Future<EanImportStatusResponse> getEanImportStatus(
    @Path('batchId') String batchId,
  );

  // ─── Expiry ─────────────────────────────────────────────────────────────
  @POST('/api/v1/expiry-records')
  Future<ExpiryResponse> createExpiry(@Body() CreateExpiryDto body);

  @GET('/api/v1/expiry-records')
  Future<List<ExpiryResponse>> getExpiryRecords({
    @Query('limit') int? limit,
    @Query('status') String? status,
    @Query('storeId') String? storeId,
  });

  @GET('/api/v1/expiry-records/{id}')
  Future<ExpiryResponse> getExpiry(@Path('id') String id);

  @DELETE('/api/v1/expiry-records/{id}')
  Future<void> deleteExpiry(@Path('id') String id);

  // ─── Tasks ──────────────────────────────────────────────────────────────
  @POST('/api/v1/tasks')
  Future<TaskResponse> createTask(@Body() CreateTaskDto body);

  @GET('/api/v1/tasks')
  Future<PaginatedTasks> getTasks({
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
    @Query('status') String? status,
  });

  @GET('/api/v1/tasks/{id}')
  Future<TaskResponse> getTask(@Path('id') String id);

  @PATCH('/api/v1/tasks/{id}')
  Future<TaskResponse> updateTask(
    @Path('id') String id,
    @Body() UpdateTaskDto body,
  );

  @DELETE('/api/v1/tasks/{id}')
  Future<void> deleteTask(@Path('id') String id);

  // ─── Inventory ──────────────────────────────────────────────────────────
  @GET('/api/v1/inventory')
  Future<PaginatedInventory> getInventory({
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });

  @POST('/api/v1/inventory/adjust')
  Future<InventoryItemResponse> adjustStock(@Body() StockAdjustmentDto body);

  @GET('/api/v1/inventory/{id}')
  Future<InventoryItemResponse> getInventoryItem(@Path('id') String id);

  // ─── GRN ────────────────────────────────────────────────────────────────
  @POST('/api/v1/grn')
  Future<GrnResponse> createGrn(@Body() CreateGrnDto body);

  @GET('/api/v1/grn')
  Future<PaginatedGrns> getGrns({
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });

  @GET('/api/v1/grn/{id}')
  Future<GrnResponse> getGrn(@Path('id') String id);

  // ─── Subscription (canonical plural surface — BE-28) ────────────────────
  // Backend: @Controller('subscriptions'). The server is the source of truth
  // for plans (with UUID id), status, features, limits and usage.
  @GET('/api/v1/subscriptions/plans')
  Future<List<SubscriptionPlanDto>> getSubscriptionPlans();

  @GET('/api/v1/subscriptions/status')
  Future<SubscriptionStatusDto> getSubscriptionStatus();

  @GET('/api/v1/subscriptions/usage')
  Future<UsageStatsDto> getSubscriptionUsage();

  @POST('/api/v1/subscriptions/upgrade')
  Future<void> upgradeSubscriptionPlan(@Body() UpgradePlanRequestDto body);

  @POST('/api/v1/subscriptions/cancel')
  Future<void> cancelSubscription(@Body() CancelSubscriptionRequestDto body);

  @POST('/api/v1/subscriptions/reactivate')
  Future<void> reactivateSubscription();

  // ─── Payments (Razorpay) ───────────────────────────────────────────────
  @POST('/api/v1/payments/checkout')
  Future<CheckoutResponse> createCheckout(@Body() CreateCheckoutDto body);

  @POST('/api/v1/payments/verify')
  Future<VerifyPaymentResponse> verifyPayment(@Body() VerifyPaymentDto body);

  // ─── Onboarding (BE-34) ────────────────────────────────────────────────
  // Backend exposes a single endpoint: POST /onboarding/segment that records
  // the user's self-selected segment and returns a routing decision. The
  // earlier `/onboarding/status` and `/onboarding/complete` routes never
  // existed on the server — they've been removed from this client.
  @POST('/api/v1/onboarding/segment')
  Future<OnboardingRoutingResponse> selectOnboardingSegment(
    @Body() SelectSegmentRequestDto body,
  );

  // ─── Allergens ─────────────────────────────────────────────────────────
  @GET('/api/v1/allergens/profile/{userId}')
  Future<AllergenProfileResponse> getAllergenProfile(
    @Path('userId') String userId,
  );

  @PUT('/api/v1/allergens/profile/{userId}')
  Future<AllergenProfileResponse> updateAllergenProfile(
    @Path('userId') String userId,
    @Body() UpdateAllergenProfileDto body,
  );

  // ─── Recall ────────────────────────────────────────────────────────────
  @GET('/api/v1/recalls')
  Future<List<RecallResponse>> getRecalls();

  @GET('/api/v1/recalls/product/{productId}')
  Future<List<RecallResponse>> getProductRecalls(
    @Path('productId') String productId,
  );

  // ─── Ingredient Explainer ──────────────────────────────────────────────
  /// BE-40 — `GET /api/v1/ingredients/:slug/explanation?locale=...`.
  ///
  /// Per-slug explanation surface used by the dedicated full-screen
  /// explainer (FE-19). Inline Product Detail no longer posts raw ingredient
  /// lists; it routes users to the label-scan flow when a pack label is needed.
  @GET('/api/v1/ingredients/{slug}/explanation')
  Future<IngredientExplanation> getIngredientExplanation(
    @Path('slug') String slug, {
    @Query('locale') String? locale,
  });

  // ─── Healthy Alternatives ──────────────────────────────────────────────
  /// BE-41 — `GET /api/v1/products/:ean/alternatives`.
  ///
  /// Returns up to three healthier candidates for a source EAN. The
  /// canonical path the server actually exposes (and the one FE-22 reads
  /// from). Returns a bare list — the screen wraps it in a
  /// `HealthyAlternativesResult` once it knows the source EAN.
  @GET('/api/v1/products/{ean}/alternatives')
  Future<List<HealthyAlternative>> getHealthierAlternatives(
    @Path('ean') String ean,
  );

  // ─── Saved Products (FE-16) ────────────────────────────────────────────
  /// `GET /api/v1/saved-products?cursor=&limit=` — cursor-paginated list of
  /// the signed-in user's saved products. Returns the canonical envelope
  /// `{ items, nextCursor }` so the client can lazy-load further pages.
  @GET('/api/v1/saved-products')
  Future<ListSavedProductsResponse> getSavedProducts({
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });

  /// `POST /api/v1/saved-products` — bookmark a new product. Returns the
  /// freshly created row with server-assigned `id`/timestamps.
  @POST('/api/v1/saved-products')
  Future<SavedProductDto> createSavedProduct(
    @Body() CreateSavedProductDto body,
  );

  /// `DELETE /api/v1/saved-products/:id` — remove a saved product.
  /// Returns 204 No Content; the typed return is `void`.
  @DELETE('/api/v1/saved-products/{id}')
  Future<void> deleteSavedProduct(@Path('id') String id);

  /// BE-37 — `POST /api/v1/sync/saved-products`.
  ///
  /// Idempotent batch upsert. The mobile sync queue is the canonical
  /// pattern; the saved-products screen re-uses it for "save" and
  /// "unsave" mutations. There is currently no GET counterpart — see
  /// the FE-16 open-question summary.
  @POST('/api/v1/sync/saved-products')
  Future<void> syncSavedProducts(@Body() Map<String, dynamic> body);

  // ─── Referrals ─────────────────────────────────────────────────────────
  @POST('/api/v1/referrals')
  Future<ReferralResponse> createReferral(@Body() CreateReferralDto body);

  @GET('/api/v1/referrals')
  Future<List<ReferralResponse>> getReferrals();

  @GET('/api/v1/referrals/me')
  Future<ReferralStatsResponse> getReferralStats();

  @POST('/api/v1/referrals/redeem')
  Future<void> redeemReferral(@Body() RedeemReferralDto body);

  // ─── User preferences ─────────────────────────────────────────────────
  @PUT('/api/v1/user/language')
  Future<void> updateUserLanguage(@Body() UpdateLanguageDto body);

  // ─── Sync ──────────────────────────────────────────────────────────────
  @POST('/api/v1/sync/push')
  Future<void> syncPush(@Body() SyncPushDto body);

  @GET('/api/v1/sync/pull')
  Future<SyncPullResponse> syncPull({@Query('since') String? since});

  // ─── OCR Fallback ──────────────────────────────────────────────────────
  @POST('/api/v1/ocr/fallback')
  Future<OcrFallbackResponse> ocrFallback(@Body() Map<String, dynamic> body);

  // ─── Shopping List ─────────────────────────────────────────────────────
  @GET('/api/v1/shopping-list')
  Future<ShoppingListResponse> getShoppingList();

  @POST('/api/v1/shopping-list/items')
  Future<ShoppingListItemResponse> addShoppingListItem(
    @Body() ShoppingListItemDto body,
  );

  @PATCH('/api/v1/shopping-list/items/{id}')
  Future<ShoppingListItemResponse> updateShoppingListItem(
    @Path('id') String id,
    @Body() UpdateShoppingListItemDto body,
  );

  @DELETE('/api/v1/shopping-list/items/{id}')
  Future<void> deleteShoppingListItem(@Path('id') String id);

  // ─── Public Product ────────────────────────────────────────────────────
  // ─── Weekly Digest ─────────────────────────────────────────────────────
  @GET('/api/v1/weekly-digest')
  Future<WeeklyDigestResponse> getWeeklyDigest();

  // ─── Reports / Exports (FE-30) ─────────────────────────────────────────
  // BE-20 / BE-21 surface. Static `/reports/scheduled` and
  // `/reports/aggregate` paths sit before `/reports/:id` server-side
  // so Nest's resolver doesn't collide them; the Retrofit method order
  // below is irrelevant to that — what matters is the request path.

  /// `GET /api/v1/reports` — recent reports for the tenant. The server
  /// returns a bare JSON array today; an envelope wrapper can be added
  /// later by replacing this method's return type without changing
  /// callers (they typically project to a `List<ReportSummary>` anyway).
  @GET('/api/v1/reports')
  Future<List<ReportSummary>> getReports({
    @Query('status') String? status,
    @Query('type') String? type,
    @Query('limit') int? limit,
  });

  /// `POST /api/v1/reports/generate` — kick off an async report job.
  @POST('/api/v1/reports/generate')
  Future<GenerateReportResponseDto> generateReport(
    @Body() GenerateReportRequestDto body,
  );

  /// `POST /api/v1/reports/:id/export` — re-export an existing report
  /// in one or more formats. Returns presigned download URLs implicitly
  /// via [ExportFile.fileName] + the per-format download endpoint below.
  @POST('/api/v1/reports/{id}/export')
  Future<ExportResponseDto> exportReport(
    @Path('id') String reportId,
    @Body() ExportRequestDto body,
  );

  /// `GET /api/v1/reports/:id/download/:format` — presigned download URL
  /// for a specific format. Mobile leans on this to hand a URL to the
  /// platform browser (`url_launcher`).
  @GET('/api/v1/reports/{id}/download/{format}')
  Future<ReportDownloadUrlResponse> getReportDownloadUrl(
    @Path('id') String reportId,
    @Path('format') String format,
  );

  /// `GET /api/v1/reports/scheduled` — list of recurring report
  /// schedules visible to the tenant.
  @GET('/api/v1/reports/scheduled')
  Future<List<ScheduledReport>> getScheduledReports();

  /// `POST /api/v1/reports/schedule` — create a new recurring schedule.
  /// The server validates the nested `parameters` against the same
  /// schema as the generate endpoint.
  @POST('/api/v1/reports/schedule')
  Future<ScheduledReport> createScheduledReport(
    @Body() CreateScheduleRequestDto body,
  );

  /// `POST /api/v1/reports/scheduled/:id/pause` — temporarily stop firing.
  @POST('/api/v1/reports/scheduled/{id}/pause')
  Future<ScheduledReport> pauseScheduledReport(@Path('id') String id);

  /// `POST /api/v1/reports/scheduled/:id/resume` — resume after a pause.
  @POST('/api/v1/reports/scheduled/{id}/resume')
  Future<ScheduledReport> resumeScheduledReport(@Path('id') String id);

  /// `DELETE /api/v1/reports/scheduled/:id` — cancel a schedule.
  @DELETE('/api/v1/reports/scheduled/{id}')
  Future<void> deleteScheduledReport(@Path('id') String id);

  // ─── Dashboard / OHS (FE-26) ───────────────────────────────────────────
  /// `GET /api/v1/dashboard/summary` — live operational rollup for the
  /// caller's currently-active store. The mobile app derives the OHS
  /// headline + breakdowns from this DTO via [OhsSnapshot.fromDashboard].
  @GET('/api/v1/dashboard/summary')
  Future<DashboardSummaryResponse> getDashboardSummary(
    @Query('storeId') String storeId, {
    @Query('daysAhead') int? daysAhead,
  });
}

/// Provides the generated Retrofit [ApiClient] backed by the configured Dio.
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});

extension ExpiryApiClientCompat on ApiClient {
  Future<PaginatedExpiries> getExpiries({
    String? cursor,
    int? limit,
    String? status,
    String? storeId,
  }) async {
    final items = await getExpiryRecords(
      limit: limit,
      status: status,
      storeId: storeId,
    );
    return PaginatedExpiries(items: items, total: items.length);
  }
}
