import 'dart:async';

import 'package:dio/dio.dart';
import 'package:radha_mobile/core/network/token_provider.dart';

/// Injects `Authorization: Bearer <token>` into every request and handles
/// transparent 401 refresh + retry (once).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStore tokenStore,
    required Dio refreshDio,
    required String refreshPath,
  }) : _tokenStore = tokenStore,
       _refreshDio = refreshDio,
       _refreshPath = refreshPath;

  final TokenStore _tokenStore;

  /// A separate Dio instance (no interceptors) used exclusively for the
  /// refresh call to avoid infinite loops.
  final Dio _refreshDio;
  final String _refreshPath;

  static const _retryHeader = 'x-retry';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStore.readAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    if (response == null || response.statusCode != 401) {
      return handler.next(err);
    }

    final options = err.requestOptions;

    // Don't retry if it's the auth path itself or already retried.
    if (options.path.contains('/auth/') ||
        options.headers[_retryHeader] == 'true') {
      return handler.next(err);
    }

    // Attempt refresh.
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null) {
      return handler.next(err);
    }

    try {
      final refreshResponse = await _refreshDio.post<Map<String, dynamic>>(
        _refreshPath,
        data: {'refreshToken': refreshToken},
      );

      final data = refreshResponse.data!;
      final newAccess = data['accessToken'] as String;
      final newRefresh = data['refreshToken'] as String;

      await _tokenStore.persistTokens(access: newAccess, refresh: newRefresh);

      // Retry original request with new token.
      options.headers['Authorization'] = 'Bearer $newAccess';
      options.headers[_retryHeader] = 'true';

      final retryResponse = await _refreshDio.fetch(options);
      return handler.resolve(retryResponse);
    } on DioException {
      // Refresh failed — propagate original 401.
      return handler.next(err);
    }
  }
}
