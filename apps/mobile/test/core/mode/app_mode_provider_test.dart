import 'package:flutter_test/flutter_test.dart';

import 'package:radha_mobile/core/auth/auth_controller.dart';
import 'package:radha_mobile/core/mode/app_mode_provider.dart';

void main() {
  group('resolveMode', () {
    test('null user → consumer', () {
      expect(resolveMode(null), AppMode.consumer);
    });

    test('consumer-only roles, no store → consumer', () {
      final user = CurrentUser(
        userId: 'u1',
        roles: const ['personal'],
        selectedStoreId: null,
      );
      expect(resolveMode(user), AppMode.consumer);
    });

    test('parent role, no store → consumer', () {
      final user = CurrentUser(
        userId: 'u2',
        roles: const ['parent'],
        selectedStoreId: null,
      );
      expect(resolveMode(user), AppMode.consumer);
    });

    test('business role + selected store → business', () {
      final user = CurrentUser(
        userId: 'u3',
        roles: const ['manager'],
        selectedStoreId: 'store-1',
      );
      expect(resolveMode(user), AppMode.business);
    });

    test('staff role + selected store → business', () {
      final user = CurrentUser(
        userId: 'u4',
        roles: const ['staff'],
        selectedStoreId: 'store-99',
      );
      expect(resolveMode(user), AppMode.business);
    });

    test('tenant_admin role + selected store → business', () {
      final user = CurrentUser(
        userId: 'u5',
        roles: const ['tenant_admin'],
        selectedStoreId: 'store-2',
      );
      expect(resolveMode(user), AppMode.business);
    });

    test('business role but no selected store → consumer', () {
      // User has a business role but hasn't selected a store yet.
      // Resolves consumer until store is selected (routes to store selection).
      final user = CurrentUser(
        userId: 'u6',
        roles: const ['manager'],
        selectedStoreId: null,
      );
      expect(resolveMode(user), AppMode.consumer);
    });

    test('consumer post-activation: business role + store → business', () {
      // After business-activation + entitlement refresh, the resolver flips.
      final user = CurrentUser(
        userId: 'u7',
        roles: const ['personal', 'tenant_admin'],
        selectedStoreId: 'store-new',
      );
      expect(resolveMode(user), AppMode.business);
    });

    test('unknown/future roles alone → consumer', () {
      final user = CurrentUser(
        userId: 'u8',
        roles: const ['future_role'],
        selectedStoreId: 'store-x',
      );
      expect(resolveMode(user), AppMode.consumer);
    });

    test('empty roles list → consumer', () {
      final user = CurrentUser(
        userId: 'u9',
        roles: const [],
        selectedStoreId: 'store-x',
      );
      expect(resolveMode(user), AppMode.consumer);
    });
  });
}
