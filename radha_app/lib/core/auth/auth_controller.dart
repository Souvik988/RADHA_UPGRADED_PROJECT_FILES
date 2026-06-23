import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'auth_session.dart';

/// Single source of truth for the user's authentication state. Reads the
/// session from secure storage on first build, then mutates it through the
/// repository as the user logs in / out / switches stores. Widgets watching
/// `authControllerProvider` re-render through the standard
/// `AsyncValue<T>` machinery (data / loading / error).
class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final repo = ref.read(authRepositoryProvider);
    return repo.currentSession();
  }

  /// Issues an OTP. Doesn't change session state — only on `verifyOtp` does
  /// the user become authenticated.
  Future<OtpRequestResult> requestOtp(String mobile) {
    final repo = ref.read(authRepositoryProvider);
    return repo.requestOtp(mobile);
  }

  /// Completes the OTP flow and lifts the controller into a signed-in state.
  Future<void> verifyOtp({
    required String mobile,
    required String otp,
    required String requestId,
  }) async {
    state = const AsyncLoading<AuthSession?>();
    state = await AsyncValue.guard<AuthSession?>(() async {
      final repo = ref.read(authRepositoryProvider);
      return repo.verifyOtp(mobile: mobile, otp: otp, requestId: requestId);
    });
  }

  /// Admin email + password login. Same state transitions as [verifyOtp].
  Future<void> adminLogin({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading<AuthSession?>();
    state = await AsyncValue.guard<AuthSession?>(() async {
      final repo = ref.read(authRepositoryProvider);
      return repo.adminLogin(email: email, password: password);
    });
  }

  /// Wipes the session locally and (best-effort) on the server. The new state
  /// is `AsyncData(null)` regardless of network outcome — see
  /// [AuthRepository.logout].
  Future<void> logout() async {
    state = const AsyncLoading<AuthSession?>();
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncData<AuthSession?>(null);
  }

  /// Persists the user's chosen store and updates the in-memory session.
  /// Throws if the user isn't signed in — the UI guards prevent that.
  Future<void> selectStore(String storeId) async {
    state = const AsyncLoading<AuthSession?>();
    state = await AsyncValue.guard<AuthSession?>(() async {
      final repo = ref.read(authRepositoryProvider);
      return repo.selectStore(storeId);
    });
  }
}

/// Global handle for the auth state machine.
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

/// Slim view of the current user that screens consume. Resolves to `null`
/// while the controller is loading, errored, or signed out — callers should
/// fall back to a guard / redirect rather than rendering on `null`.
class CurrentUser {
  const CurrentUser({
    required this.userId,
    this.tenantId,
    required this.roles,
    this.selectedStoreId,
    this.selectedStoreName,
  });

  final String userId;
  final String? tenantId;
  final List<String> roles;
  final String? selectedStoreId;
  final String? selectedStoreName;
}

/// Derived view of the auth state that ignores loading + error states. Use
/// this when a screen wants the "current user" without owning the
/// `AsyncValue` boilerplate; combine with auth/role guards for redirects.
final currentUserProvider = Provider<CurrentUser?>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;
  if (session == null) return null;
  final selected = session.selectedStoreId == null
      ? null
      : session.stores.where((s) => s.storeId == session.selectedStoreId);
  final selectedStore = (selected == null || selected.isEmpty)
      ? null
      : selected.first;
  return CurrentUser(
    userId: session.userId,
    tenantId: session.tenantId,
    roles: session.roles,
    selectedStoreId: session.selectedStoreId,
    selectedStoreName: selectedStore?.storeName,
  );
});
