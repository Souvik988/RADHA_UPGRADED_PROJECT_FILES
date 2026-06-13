import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Why a product-detail nutrition lookup failed. Drives an explicit, contained
/// error state instead of the previous silent empty widget — the screen always
/// keeps the product identity it already has and only this section reacts.
enum ProductLookupFailure {
  /// 404 — the backend has no record for this EAN yet.
  notFound,

  /// 401/403 — the session lapsed; defer to the auth refresh flow rather than
  /// mislabelling it "nutrition unavailable".
  unauthorized,

  /// No connection / timeout — show cached identity + offline messaging.
  offline,

  /// 5xx, decode, or anything else — a contained, retryable server error.
  serverFailure,
}

/// Classify a caught lookup error. HTTP status wins; connection-class errors
/// are offline; everything else is a server failure. Never string-matches.
ProductLookupFailure classifyProductLookupFailure(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 404) return ProductLookupFailure.notFound;
    if (status == 401 || status == 403) {
      return ProductLookupFailure.unauthorized;
    }
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ProductLookupFailure.offline;
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ProductLookupFailure.serverFailure;
    }
  }
  return ProductLookupFailure.serverFailure;
}

/// PII-free product-detail telemetry. Events: lookup_started, lookup_success,
/// lookup_not_found, lookup_offline_fallback, lookup_server_failure,
/// nutrition_missing, retry_clicked, scan_label_clicked. Never logs tokens or
/// profile data — only the event name and a coarse detail.
void logProductLookupEvent(String event, {String? detail}) {
  developer.log(
    detail == null ? event : '$event ($detail)',
    name: 'radha.product',
    level: 800, // INFO
  );
}

/// Map a failure to its telemetry event name.
String productLookupEventFor(ProductLookupFailure failure) => switch (failure) {
  ProductLookupFailure.notFound => 'lookup_not_found',
  ProductLookupFailure.unauthorized => 'lookup_server_failure',
  ProductLookupFailure.offline => 'lookup_offline_fallback',
  ProductLookupFailure.serverFailure => 'lookup_server_failure',
};
