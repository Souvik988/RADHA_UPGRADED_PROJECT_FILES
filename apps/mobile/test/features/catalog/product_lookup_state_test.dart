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
    test('404 maps to notFound', () {
      expect(
        classifyProductLookupFailure(
          _dio(DioExceptionType.badResponse, status: 404),
        ),
        ProductLookupFailure.notFound,
      );
    });

    test('401 maps to unauthorized and 403 maps to forbidden', () {
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
        ProductLookupFailure.forbidden,
      );
    });

    test('connection error maps to offline', () {
      expect(
        classifyProductLookupFailure(_dio(DioExceptionType.connectionError)),
        ProductLookupFailure.offline,
      );
    });

    test('timeout-class errors map to timeout', () {
      for (final t in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      ]) {
        expect(
          classifyProductLookupFailure(_dio(t)),
          ProductLookupFailure.timeout,
        );
      }
    });

    test('408 and 504 map to timeout', () {
      for (final status in [408, 504]) {
        expect(
          classifyProductLookupFailure(
            _dio(DioExceptionType.badResponse, status: status),
          ),
          ProductLookupFailure.timeout,
        );
      }
    });

    test('500 maps to serverFailure', () {
      expect(
        classifyProductLookupFailure(
          _dio(DioExceptionType.badResponse, status: 500),
        ),
        ProductLookupFailure.serverFailure,
      );
    });

    test('non-Dio error maps to serverFailure', () {
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
      'lookup_unauthorized',
    );
    expect(
      productLookupEventFor(ProductLookupFailure.forbidden),
      'lookup_forbidden',
    );
    expect(
      productLookupEventFor(ProductLookupFailure.timeout),
      'lookup_timeout',
    );
  });
}
