import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Why a product-detail nutrition lookup failed. The screen keeps the product
/// identity it already has, and only the remote nutrition section reacts.
enum ProductLookupFailure {
  /// 404: the backend has no record for this EAN yet.
  notFound,

  /// 401: the session lapsed. Let auth refresh/sign-in handle it.
  unauthorized,

  /// 403: the caller is signed in, but cannot read this product detail.
  forbidden,

  /// No network route to the backend.
  offline,

  /// The backend did not answer in time.
  timeout,

  /// 5xx, decode, cancellation, certificate, or unknown failures.
  serverFailure,
}

/// Classify a caught lookup error without matching arbitrary English text.
ProductLookupFailure classifyProductLookupFailure(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 404) return ProductLookupFailure.notFound;
    if (status == 401) return ProductLookupFailure.unauthorized;
    if (status == 403) return ProductLookupFailure.forbidden;
    if (status == 408 || status == 504) return ProductLookupFailure.timeout;

    switch (error.type) {
      case DioExceptionType.connectionError:
        return ProductLookupFailure.offline;
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ProductLookupFailure.timeout;
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ProductLookupFailure.serverFailure;
    }
  }
  return ProductLookupFailure.serverFailure;
}

/// PII-free product-detail telemetry. Never logs tokens or profile data, only
/// the coarse event name and optional non-sensitive detail.
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
  ProductLookupFailure.unauthorized => 'lookup_unauthorized',
  ProductLookupFailure.forbidden => 'lookup_forbidden',
  ProductLookupFailure.offline => 'lookup_offline_fallback',
  ProductLookupFailure.timeout => 'lookup_timeout',
  ProductLookupFailure.serverFailure => 'lookup_server_failure',
};
