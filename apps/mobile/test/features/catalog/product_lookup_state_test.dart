import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radha_mobile/features/catalog/product_lookup_state.dart';

DioException _dio(DioExceptionType type, {int? status}) => DioException(
  requestOptions: RequestOptions(path: '/api/v1/products/lookup/x'),
  type: type,
  response: status == null
      ? null
      : Response(
          requestOptions: RequestOptions(path: '/api/v1/products/lookup/x'),
          statusCode: status,
        ),
);

void main() {
  group('classifyProductLookupFailure', () {
    test('404 → notFound', () {
      expect(
        classifyProductLookupFailure(
          _dio(DioExceptionType.badResponse, status: 404),
        ),
        ProductLookupFailure.notFound,
      );
    });

    test('401 and 403 → unauthorized', () {
      expect(
        classifyProductLookupFailure(
          _dio(DioExceptionType.badResponse, status: 401),
        ),
        ProductLookupFailure.unauthorized,
      );
      expect(
        classifyProductLookupFailure(
          _dio(DioExceptionType.badResponse, status: 403),
        ),
        ProductLookupFailure.unauthorized,
      );
    });

    test('connection-class errors → offline', () {
      for (final t in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      ]) {
        expect(
          classifyProductLookupFailure(_dio(t)),
          ProductLookupFailure.offline,
        );
      }
    });

    test('500 → serverFailure', () {
      expect(
        classifyProductLookupFailure(
          _dio(DioExceptionType.badResponse, status: 500),
        ),
        ProductLookupFailure.serverFailure,
      );
    });

    test('non-Dio error → serverFailure', () {
      expect(
        classifyProductLookupFailure(StateError('boom')),
        ProductLookupFailure.serverFailure,
      );
    });
  });

  test('event mapping is stable and PII-free names', () {
    expect(
      productLookupEventFor(ProductLookupFailure.notFound),
      'lookup_not_found',
    );
    expect(
      productLookupEventFor(ProductLookupFailure.offline),
      'lookup_offline_fallback',
    );
    expect(
      productLookupEventFor(ProductLookupFailure.serverFailure),
      'lookup_server_failure',
    );
    expect(
      productLookupEventFor(ProductLookupFailure.unauthorized),
      'lookup_server_failure',
    );
  });
}
