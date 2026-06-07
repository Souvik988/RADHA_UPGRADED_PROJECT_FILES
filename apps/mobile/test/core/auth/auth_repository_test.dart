// Stubbed unit tests for AuthRepository. Mocks the ApiClient + SessionStorage
// dependencies with mocktail so the tests stay hermetic — no real Dio, no
// real keystore.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:radha_mobile/core/auth/auth_repository.dart';
import 'package:radha_mobile/core/auth/auth_session.dart';
import 'package:radha_mobile/core/auth/session_storage.dart';
import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/api_exception.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockSessionStorage extends Mock implements SessionStorage {}

void main() {
  setUpAll(() {
    registerFallbackValue(const OtpRequestRequestDto(mobile: ''));
    registerFallbackValue(
      const VerifyOtpRequestDto(mobile: '', otp: '', requestId: ''),
    );
    registerFallbackValue(const AdminLoginRequestDto(email: '', password: ''));
    registerFallbackValue(const RefreshTokenRequestDto(refreshToken: ''));
    registerFallbackValue(
      const AuthSession(
        accessToken: '',
        refreshToken: '',
        userId: '',
        tenantId: '',
        roles: [],
        stores: [],
      ),
    );
  });

  late _MockApiClient api;
  late _MockSessionStorage storage;
  late AuthRepository repo;

  setUp(() {
    api = _MockApiClient();
    storage = _MockSessionStorage();
    repo = AuthRepository(apiClient: api, sessionStorage: storage);
  });

  group('requestOtp', () {
    test('returns the server-issued requestId and cooldown', () async {
      when(() => api.requestOtp(any())).thenAnswer(
        (_) async => const OtpRequestResponse(
          requestId: 'req-123',
          expiresIn: 300,
          rateLimitRemaining: 4,
        ),
      );

      final result = await repo.requestOtp('+919999912345');

      expect(result.requestId, 'req-123');
      expect(result.expiresIn, 300);
      expect(result.rateLimitRemaining, 4);
      verify(
        () => api.requestOtp(
          any(
            that: isA<OtpRequestRequestDto>().having(
              (d) => d.mobile,
              'mobile',
              '+919999912345',
            ),
          ),
        ),
      ).called(1);
    });
  });

  group('verifyOtp', () {
    test(
      'calls the API, fetches /me, and persists the resulting session',
      () async {
        when(() => api.verifyOtp(any())).thenAnswer(
          (_) async => const LoginResponse(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
            user: UserSummary(id: 'u-1', tenantId: 't-1'),
          ),
        );
        when(() => api.me()).thenAnswer(
          (_) async => const MeResponse(
            user: UserSummary(id: 'u-1', tenantId: 't-1'),
            roles: ['staff'],
            storeAccess: [
              StoreAccessDto(
                storeId: 's-1',
                storeName: 'Andheri Outlet',
                role: 'staff',
              ),
            ],
          ),
        );
        when(
          () => storage.updateTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ),
        ).thenAnswer((_) async {});
        when(() => storage.writeSession(any())).thenAnswer((_) async {});

        final session = await repo.verifyOtp(
          mobile: '+919999912345',
          otp: '123456',
          requestId: 'req-123',
        );

        expect(session.accessToken, 'access-1');
        expect(session.refreshToken, 'refresh-1');
        expect(session.userId, 'u-1');
        expect(session.tenantId, 't-1');
        expect(session.roles, ['staff']);
        expect(session.stores, hasLength(1));
        // Single-store users get auto-selected.
        expect(session.selectedStoreId, 's-1');

        verify(() => storage.writeSession(any())).called(1);
      },
    );
  });

  group('refresh', () {
    test('rotates tokens via /auth/refresh and persists new pair', () async {
      const existing = AuthSession(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
        userId: 'u-1',
        tenantId: 't-1',
        roles: ['staff'],
        stores: [],
      );
      when(() => storage.readSession()).thenAnswer((_) async => existing);
      when(() => api.refreshToken(any())).thenAnswer(
        (_) async => const LoginResponse(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
          user: UserSummary(id: 'u-1', tenantId: 't-1'),
        ),
      );
      when(
        () => storage.updateTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});

      final rotated = await repo.refresh();

      expect(rotated.accessToken, 'new-access');
      expect(rotated.refreshToken, 'new-refresh');
      expect(rotated.userId, 'u-1');
      verify(
        () => storage.updateTokens(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
        ),
      ).called(1);
    });

    test('throws UnauthorizedException when no session is on disk', () async {
      when(() => storage.readSession()).thenAnswer((_) async => null);

      expect(repo.refresh(), throwsA(isA<UnauthorizedException>()));
    });
  });

  group('logout', () {
    test('clears storage even when the server call fails', () async {
      when(() => api.logout()).thenThrow(
        const UnauthorizedException(message: 'session already revoked'),
      );
      when(() => storage.clear()).thenAnswer((_) async {});

      await repo.logout();

      verify(() => api.logout()).called(1);
      verify(() => storage.clear()).called(1);
    });

    test('clears storage on the happy path', () async {
      when(() => api.logout()).thenAnswer((_) async {});
      when(() => storage.clear()).thenAnswer((_) async {});

      await repo.logout();

      verify(() => storage.clear()).called(1);
    });
  });

  group('isLoggedIn', () {
    test('returns true when an access token is present', () async {
      when(() => storage.readAccessToken()).thenAnswer((_) async => 'access-1');
      expect(await repo.isLoggedIn(), isTrue);
    });

    test('returns false when no access token exists', () async {
      when(() => storage.readAccessToken()).thenAnswer((_) async => null);
      expect(await repo.isLoggedIn(), isFalse);
    });
  });

  group('selectStore', () {
    test('persists the selection and returns the updated session', () async {
      const existing = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        userId: 'u-1',
        tenantId: 't-1',
        roles: ['staff'],
        stores: [
          StoreAccess(storeId: 's-1', storeName: 'A', role: 'staff'),
          StoreAccess(storeId: 's-2', storeName: 'B', role: 'staff'),
        ],
      );
      when(() => storage.readSession()).thenAnswer((_) async => existing);
      when(() => storage.selectStore(any())).thenAnswer((_) async {});

      final updated = await repo.selectStore('s-2');

      expect(updated.selectedStoreId, 's-2');
      verify(() => storage.selectStore('s-2')).called(1);
    });
  });
}
