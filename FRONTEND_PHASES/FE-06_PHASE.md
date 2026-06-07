# Phase FE-06: API Client + Typed Services

## Phase Metadata
- **Phase ID**: FE-06
- **Section**: Layer 1 — Foundation
- **Depends On**: FE-01
- **Blocks**: FE-07 (auth state needs API client), FE-08 (sync queue), every screen that calls backend
- **Estimated Duration**: 3-4 days
- **Complexity**: High

## Goal
Stand up the single way the Flutter app talks to the RADHA backend: a typed Dio client wrapped in domain services that consume DTOs generated from `@radha/shared-types`. The client must:
- attach **auth + correlation ID + idempotency key** on every request,
- **refresh JWT** transparently on 401 once and only once,
- **retry** transient failures (5xx, network) with exponential backoff and jitter,
- **respect rate limits** (BE-46 returns structured 429 with `Retry-After`),
- **map errors** to a typed `RadhaError` sealed union the UI can switch on,
- **queue mutations offline** via a hand-off to FE-08's Drift sync queue,
- expose **streaming** support for the AI Ingredient Explainer (BE-40 server-sent events).

By the end of this phase, every later phase calls `ref.read(productsServiceProvider).fetchProductByEan('8901234567890')` and gets a typed result, never a raw `Dio.get`. UI never sees an `Exception` — it sees a `RadhaError.networkUnavailable` or `RadhaError.rateLimited(retryAfter: 12)`.

## Why This Phase Matters
- **One client, one error shape, one auth path** is the difference between an app you can debug and one that drowns in toString'd exceptions.
- **Idempotency keys** mean a flaky scan retry doesn't double-credit the user (BE-44 enforces this server-side; client supplies the key).
- **Correlation IDs** let a support engineer trace a user's bad scan from their phone log to the server log to Sentry to PostHog. BE-48 expects them.
- **Offline queue handoff** is what makes FE-08 possible — without this contract, offline-first is theatre.
- **Server-sent events for AI** is how BE-40's ingredient explainer streams tokens — a UX win we can't add later.

## Prerequisites
- [ ] Backend: BE-06, BE-08, BE-44 (idempotency), BE-46 (rate limits), BE-48 (correlation IDs).
- [ ] Earlier FE: FE-01.
- [ ] Shared types: `@radha/shared-types` package; build outputs `*.d.ts`. Quicktype config to convert TS → Dart freezed in CI.
- [ ] OpenAPI: backend should expose `/api/openapi.json` (BE-02 / BE-32 work).

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/api/client/radha_api_client.dart` | Dio configuration + interceptor stack |
| `apps/mobile/lib/api/client/interceptors/auth_interceptor.dart` | Attaches JWT |
| `apps/mobile/lib/api/client/interceptors/refresh_interceptor.dart` | One-shot refresh on 401 |
| `apps/mobile/lib/api/client/interceptors/correlation_interceptor.dart` | Adds `X-Correlation-Id` |
| `apps/mobile/lib/api/client/interceptors/idempotency_interceptor.dart` | Adds `Idempotency-Key` for POST/PATCH/DELETE |
| `apps/mobile/lib/api/client/interceptors/retry_interceptor.dart` | Backoff + jitter |
| `apps/mobile/lib/api/client/interceptors/rate_limit_interceptor.dart` | Honors `Retry-After` |
| `apps/mobile/lib/api/client/interceptors/log_interceptor.dart` | pretty logger (debug only) |
| `apps/mobile/lib/api/client/interceptors/offline_queue_interceptor.dart` | Hands writes to FE-08 queue when offline |
| `apps/mobile/lib/api/client/interceptors/sentry_interceptor.dart` | Breadcrumb every request |
| `apps/mobile/lib/api/error/radha_error.dart` | Sealed union of all error states |
| `apps/mobile/lib/api/error/error_mapper.dart` | DioException → RadhaError |
| `apps/mobile/lib/api/sse/sse_client.dart` | Server-sent events for streaming endpoints |
| `apps/mobile/lib/api/services/auth_service.dart` | Wraps BE-06 |
| `apps/mobile/lib/api/services/products_service.dart` | Wraps BE-10/12 |
| `apps/mobile/lib/api/services/scans_service.dart` | Wraps BE-16/17 |
| `apps/mobile/lib/api/services/expiry_calendar_service.dart` | Wraps BE-38 |
| `apps/mobile/lib/api/services/recalls_service.dart` | Wraps BE-39 |
| `apps/mobile/lib/api/services/family_service.dart` | Wraps BE-36 |
| `apps/mobile/lib/api/services/allergens_service.dart` | Wraps BE-37 |
| `apps/mobile/lib/api/services/ai_service.dart` | Wraps BE-40 (SSE) |
| `apps/mobile/lib/api/services/alternatives_service.dart` | Wraps BE-41 |
| `apps/mobile/lib/api/services/onboarding_service.dart` | Wraps BE-34 |
| `apps/mobile/lib/api/services/business_activation_service.dart` | Wraps BE-35 |
| `apps/mobile/lib/api/services/grn_service.dart` | Wraps BE-25/26 |
| `apps/mobile/lib/api/services/inventory_service.dart` | Wraps BE-27 |
| `apps/mobile/lib/api/services/tasks_service.dart` | Wraps BE-19 |
| `apps/mobile/lib/api/services/reports_service.dart` | Wraps BE-20/21 |
| `apps/mobile/lib/api/services/dashboard_service.dart` | Wraps BE-30 |
| `apps/mobile/lib/api/services/feature_flags_service.dart` | Wraps BE-47 |
| `apps/mobile/lib/api/dto/*.dart` | freezed DTOs generated from `@radha/shared-types` |
| `apps/mobile/tools/dto_codegen/codegen.ts` | TS → Dart freezed generator (quicktype) |
| `apps/mobile/test/api/client/*.dart` | Interceptor + error tests |
| `apps/mobile/test/api/services/*.dart` | Service unit tests with mocked Dio |

## Client Stack

```dart
// api/client/radha_api_client.dart
class RadhaApiClient {
  final Dio _dio;
  final FlavorConfig _flavor;
  final AuthTokenStore _tokens;
  final OfflineQueueGateway _queue;
  final ConnectivityWatcher _connectivity;

  RadhaApiClient(this._flavor, this._tokens, this._queue, this._connectivity)
    : _dio = Dio(BaseOptions(
        baseUrl: _flavor.apiBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'X-Client-App': 'radha-mobile',
          'X-Client-Version': PackageInfo.appVersion,
          'X-Client-Platform': Platform.operatingSystem,
        },
        responseType: ResponseType.json,
        validateStatus: (s) => s != null && s < 500, // 5xx goes to retry
      )) {
    _dio.interceptors.addAll([
      OfflineQueueInterceptor(_queue, _connectivity),
      CorrelationInterceptor(),
      AuthInterceptor(_tokens),
      IdempotencyInterceptor(),
      RetryInterceptor(maxAttempts: 3),
      RateLimitInterceptor(),
      RefreshInterceptor(_tokens, _onLogout),
      SentryInterceptor(),
      if (kDebugMode) LogInterceptor(),
    ]);
  }
}
```

Order matters. Interceptors fire request-direction in registered order, response-direction in reverse.

### AuthInterceptor

```dart
class AuthInterceptor extends Interceptor {
  final AuthTokenStore tokens;
  AuthInterceptor(this.tokens);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_publicPaths.any(options.path.startsWith)) return handler.next(options);
    final token = await tokens.readAccess();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }
}
```

### RefreshInterceptor (one-shot)

Concurrent 401s coalesce to a single refresh call (mutex). On refresh failure: clear tokens, navigate to OTP, surface `RadhaError.sessionExpired`.

```dart
class RefreshInterceptor extends Interceptor {
  final AuthTokenStore tokens;
  final VoidCallback onLogout;
  Future<String?>? _inflight;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || err.requestOptions.extra['retried'] == true) {
      return handler.next(err);
    }
    final newAccess = await (_inflight ??= _refresh());
    _inflight = null;
    if (newAccess == null) { onLogout(); return handler.next(err); }
    // replay
    err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
    err.requestOptions.extra['retried'] = true;
    final response = await Dio().fetch(err.requestOptions);
    handler.resolve(response);
  }
}
```

### IdempotencyInterceptor

For POST/PATCH/DELETE that don't already have a key:

```dart
@override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
  if (!{'POST','PATCH','DELETE'}.contains(options.method)) return handler.next(options);
  options.headers.putIfAbsent('Idempotency-Key', () => const Uuid().v4());
  handler.next(options);
}
```

### RetryInterceptor

```dart
class RetryInterceptor extends Interceptor {
  final int maxAttempts;       // 3
  final Duration baseDelay;    // 400ms
  final Duration cap;          // 4s
  final Random rng;

  bool _shouldRetry(DioException e) =>
    e.type == DioExceptionType.connectionError ||
    e.type == DioExceptionType.connectionTimeout ||
    (e.response != null && e.response!.statusCode! >= 500);

  Duration _delayFor(int attempt) {
    final exp = baseDelay * pow(2, attempt - 1).toInt();
    final jitter = Duration(milliseconds: rng.nextInt(200));
    return (exp + jitter).clamp(baseDelay, cap);
  }
}
```

Retries are bounded: 3 attempts, ≤ 4 s per retry. Total worst-case: ~7 s.

### RateLimitInterceptor

Reads `Retry-After` from 429. Surfaces as `RadhaError.rateLimited(retryAfter: Duration)` to the UI without retrying — UI decides (e.g. show upgrade CTA).

### CorrelationInterceptor

Adds `X-Correlation-Id: <uuidv4>` and stores it in CLS-equivalent (`Sentry.configureScope.tags`) so the same ID flows into Sentry breadcrumbs and analytics.

### OfflineQueueInterceptor

```dart
@override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
  final isWrite = !{'GET','HEAD'}.contains(options.method);
  if (!isWrite) return handler.next(options);
  if (await connectivity.isOnline()) return handler.next(options);
  // Offline: hand off to FE-08 queue, return synthetic 202 response
  final id = await queue.enqueue(options);
  return handler.resolve(Response(
    requestOptions: options,
    statusCode: 202,
    statusMessage: 'Queued offline',
    data: {'queued': true, 'queue_id': id},
  ));
}
```

The actual queue (Drift table + sync worker) lives in FE-08. This phase only ships the gateway interface; FE-08 implements it.

## Error Mapping

```dart
// api/error/radha_error.dart
@freezed
sealed class RadhaError with _$RadhaError {
  const factory RadhaError.networkUnavailable() = _NetworkUnavailable;
  const factory RadhaError.timeout() = _Timeout;
  const factory RadhaError.serverError({required int status, String? requestId}) = _ServerError;
  const factory RadhaError.unauthorized() = _Unauthorized;
  const factory RadhaError.sessionExpired() = _SessionExpired;
  const factory RadhaError.forbidden({String? reason}) = _Forbidden;
  const factory RadhaError.notFound() = _NotFound;
  const factory RadhaError.rateLimited({required Duration retryAfter, RateLimitTier? tier}) = _RateLimited;
  const factory RadhaError.validation({required Map<String, String> fieldErrors}) = _Validation;
  const factory RadhaError.conflict({String? code}) = _Conflict;
  const factory RadhaError.queuedOffline({required String queueId}) = _QueuedOffline;
  const factory RadhaError.unknown({required Object cause, StackTrace? stack}) = _Unknown;
}

class ErrorMapper {
  static RadhaError fromDio(DioException e) {
    if (e.type == DioExceptionType.connectionError) return const RadhaError.networkUnavailable();
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return const RadhaError.timeout();
    }
    final r = e.response;
    if (r == null) return RadhaError.unknown(cause: e);
    final status = r.statusCode!;
    if (status == 401) return const RadhaError.unauthorized();
    if (status == 403) return RadhaError.forbidden(reason: r.data?['reason']);
    if (status == 404) return const RadhaError.notFound();
    if (status == 409) return RadhaError.conflict(code: r.data?['code']);
    if (status == 422) return RadhaError.validation(fieldErrors: _extractFieldErrors(r.data));
    if (status == 429) return RadhaError.rateLimited(
      retryAfter: Duration(seconds: int.tryParse(r.headers.value('Retry-After') ?? '60') ?? 60),
      tier: RateLimitTier.fromString(r.data?['tier']),
    );
    if (status >= 500) return RadhaError.serverError(status: status, requestId: r.headers.value('X-Request-Id'));
    return RadhaError.unknown(cause: e);
  }
}
```

Service methods return `Future<Either<RadhaError, T>>` (using `dartz` or a simple sealed `Result<T>`). UI never throws.

## Service Pattern

```dart
// api/services/products_service.dart
@riverpod
ProductsService productsService(ProductsServiceRef ref) =>
    ProductsService(ref.watch(radhaApiClientProvider));

class ProductsService {
  final RadhaApiClient client;
  ProductsService(this.client);

  Future<Result<ProductDetail>> fetchByEan(String ean) async {
    try {
      final res = await client.dio.get('/api/v1/products/$ean');
      return Result.ok(ProductDetail.fromJson(res.data));
    } on DioException catch (e) {
      return Result.err(ErrorMapper.fromDio(e));
    }
  }

  Future<Result<ScanOutput>> submitScan(ScanRequest req) async {
    try {
      final res = await client.dio.post('/api/v1/products/scan',
        data: req.toJson(),
        options: Options(headers: {'Idempotency-Key': req.clientId}),
      );
      return Result.ok(ScanOutput.fromJson(res.data));
    } on DioException catch (e) {
      return Result.err(ErrorMapper.fromDio(e));
    }
  }
}
```

## SSE for AI Explainer (BE-40)

```dart
class SseClient {
  Stream<String> tokens(Uri url, {required String authToken}) async* {
    final req = http.Request('GET', url)..headers['Authorization'] = 'Bearer $authToken';
    final stream = (await req.send()).stream.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in stream) {
      if (line.startsWith('data: ')) yield line.substring(6);
    }
  }
}
```

Used by `AiService.explainIngredient(name, lang)` → returns `Stream<String>` consumed by FE-22.

## DTO Generation

CI step:
```
node tools/dto_codegen/codegen.ts \
  --input ../../packages/shared-types/dist/*.d.ts \
  --output apps/mobile/lib/api/dto/
flutter pub run build_runner build --delete-conflicting-outputs
```

Goal: zero hand-written DTOs. A new field in `@radha/shared-types` lands in the Flutter DTO automatically on next CI build. Drift between client and server contracts becomes impossible.

## Visual Behaviour

This phase is non-visual. The demo screen (`api_diagnostics.dart` — dev-only, behind a hidden gesture in tokens gallery) shows:

| State | Visual |
|---|---|
| **Idle** | Buttons: "Test GET /health", "Test POST /scan", "Force 401", "Force 5xx", "Force timeout", "Force 429", "Force offline write". |
| **In flight** | Linear progress at top, button disabled, light haptic on tap. |
| **Success** | Snackbar "200 OK · 124 ms · corr-id: xxxx" + medium haptic. |
| **401 → refresh** | Snackbar "Refreshed" then result; corr-id chain visible in dev log. |
| **5xx retry** | Toast "Retrying… (1/3)" with exponential delay reflected. |
| **Timeout** | Toast "Took too long" + warning haptic. |
| **429** | Toast "Rate limited. Retry after 12 s" + countdown. |
| **Offline write** | Toast "Saved offline · will sync when online" + chip "Queue: 1 item". |
| **Refresh fails** | Modal "Session expired. Sign in again." — taps logout. |
| **Streaming SSE** | Live text appended token-by-token to a panel; cancel button stops stream. |

## Animations
- **Snackbar**: 240 ms `motion.slow` slide-up.
- **Linear progress**: 120 ms `motion.fast` fade-in / fade-out at start/end of request.
- **Streaming SSE token append**: each token fades in over 80 ms (looks like typing).
- **Queue chip**: scale-bump 0.95 → 1.05 → 1.0 over 200 ms when queue size changes.

## Accessibility
- Diagnostics screen is dev-only — no a11y polish required, but interactive controls still labeled.
- All `RadhaError` shapes have a localized `userMessage` getter so UI can show "Couldn't reach RADHA" not the raw exception. Used by FE-37 (empty/error states).
- Streaming SSE: each appended token announced via Semantics chunked at sentence boundaries (avoids spam).

## Testing
- **Unit (interceptors)**:
  - AuthInterceptor: skips public paths; attaches header otherwise.
  - RefreshInterceptor: 401 → calls refresh once even with 5 concurrent 401s (mutex).
  - RefreshInterceptor: refresh fails → fires `onLogout`.
  - IdempotencyInterceptor: POST without key gets one; POST with key keeps it.
  - RetryInterceptor: 5xx → 3 attempts with delays in expected ranges.
  - RetryInterceptor: 4xx (non-429) → no retry.
  - RateLimitInterceptor: 429 surfaces as `RateLimited` with `Retry-After`.
  - CorrelationInterceptor: every request has unique correlation ID; ID propagates to Sentry breadcrumb (mocked).
  - OfflineQueueInterceptor: write while offline → 202 + queue ID.
- **Unit (error mapper)**: 12 cases mapping every Dio error type + status code.
- **Service tests**: each service mocks Dio with `dio_test` — verifies path, headers, body shape, response parsing.
- **Integration**: spin up a fake server (`mockoon` or `dio_mock_adapter`), exercise full stack, validate correlation ID end-to-end.
- **Performance**: 100 sequential GETs to a stub endpoint complete in ≤ 4 s on Pixel 4a — proves no interceptor is doing sync I/O.

## Risk Assessment
| Risk | Likelihood | Mitigation |
|---|---|---|
| Refresh thundering-herd (multiple 401s in flight) | High | Mutex (single in-flight refresh future); test covers it. |
| Idempotency key collision via reuse | Low | UUIDv4 per request; service-supplied key only when intentional. |
| Retry on non-idempotent POST causing duplicates | Medium | Retry only when key present (our interceptor always attaches one); BE-44 dedup absorbs the rest. |
| Dio interceptor order bug | High | Order documented at the top of each file + asserted in unit test on construction. |
| Sentry interceptor leaks PII (request body) | Critical | Body redacted via `SensitiveFields` allow-list (no body for `/auth/*`, `/family/*`). |
| Generated DTOs drift from server | Medium | DTO codegen runs on every CI; mismatch fails CI before merge. |
| SSE keepalive lost on background | Low (Android) | `flutter_background_service` integration deferred to FE-22; meanwhile we restart stream on resume. |

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | A request to `/api/v1/products/8901234567890` includes `Authorization: Bearer …`, `X-Correlation-Id`, `X-Client-Version`. |
| T2 | A POST to `/api/v1/scans` automatically includes `Idempotency-Key: <uuid>`. |
| T3 | 5 concurrent requests that each return 401 trigger exactly one refresh call. |
| T4 | Refresh failure clears tokens and routes to `/auth/otp`. |
| T5 | A 503 response triggers up to 3 retries with delays in {≥400ms, ≥800ms, ≥1600ms} (with jitter). |
| T6 | A 429 with `Retry-After: 12` surfaces as `RadhaError.rateLimited(retryAfter: 12s)` and is **not** retried. |
| T7 | A POST while connectivity is offline returns a synthetic 202 and enqueues to the offline queue gateway. |
| T8 | A 422 with field errors maps to `RadhaError.validation(fieldErrors: {...})`. |
| T9 | DTO codegen runs in CI and produces no diff (committed DTOs are up to date). |
| T10 | `AiService.explainIngredient('aspartame', 'hi')` opens an SSE connection and yields tokens until server closes. |
| T11 | Cancelling SSE stream closes the underlying HTTP connection within 200 ms. |
| T12 | Sentry breadcrumb on every request includes corr-id, method, path, status; body is redacted. |
| T13 | Diagnostics screen "Force 401" then immediate "Force 401" again does not bounce the user (single refresh). |
| T14 | A request with body containing `password` field is logged with body field redacted in dev logs. |
| T15 | 100 sequential GETs against a stub endpoint complete in ≤ 4 s on Pixel 4a (interceptors not blocking). |

### Q&A Questions (8)

1. Why three timeout values (connect/send/receive) and not one? What's the expected p95 of each on Indian 4G?
2. How does the offline queue gateway interface keep FE-08 implementation independent of FE-06?
3. What's the rule for when a retry is safe? Why is non-key POST retry forbidden?
4. How do correlation IDs flow from Flutter → Dio → backend → Sentry → PostHog? Where does the ID originate?
5. Why does refresh use a mutex instead of just letting Dio cancel concurrent retries?
6. How are field-level validation errors (BE 422) mapped to specific UI inputs in FE-11/12/15?
7. What is the deprecation strategy when an endpoint version changes (e.g. `/api/v1` → `/api/v2`)? Header? Path? Both?
8. How does the SSE client recover when the user backgrounds the app for 30 s during an explainer stream?

## Sign-off Gate
- [ ] Developer: 15 tests pass.
- [ ] Developer: DTO codegen passes in CI; committed DTOs match `@radha/shared-types`.
- [ ] Developer: 8 Q&A answered in handoff.
- [ ] Reviewer: Audited interceptor order with test evidence.
- [ ] Reviewer: Verified PII redaction in Sentry breadcrumbs.
- [ ] Reviewer: Confirmed RateLimited not retried (would break BE-46 fairness).

**Developer Signature**: ___________________________

**☐ APPROVED — Proceed to FE-07**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF FE-06 — DO NOT PROCEED WITHOUT APPROVAL**
