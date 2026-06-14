import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:radha_mobile/core/auth/auth_controller.dart';
import 'package:radha_mobile/core/auth/auth_session.dart';
import 'package:radha_mobile/features/select_store/select_store_screen.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

const _sessionWithStores = AuthSession(
  accessToken: 'access',
  refreshToken: 'refresh',
  userId: 'user-1',
  tenantId: 'tenant-1',
  roles: ['manager'],
  stores: [
    StoreAccess(storeId: 's-1', storeName: 'Andheri Store', role: 'manager'),
    StoreAccess(storeId: 's-2', storeName: 'Bandra Store', role: 'staff'),
  ],
);

const _sessionWithoutStores = AuthSession(
  accessToken: 'access',
  refreshToken: 'refresh',
  userId: 'user-1',
  tenantId: 'tenant-1',
  roles: ['staff'],
  stores: <StoreAccess>[],
);

class _StoresAuthController extends AuthController {
  @override
  Future<AuthSession?> build() async => _sessionWithStores;
}

class _NoStoresAuthController extends AuthController {
  @override
  Future<AuthSession?> build() async => _sessionWithoutStores;
}

Widget _buildSubject(AuthController Function() controller) {
  return ProviderScope(
    overrides: [authControllerProvider.overrideWith(controller)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SelectStoreScreen(),
    ),
  );
}

void main() {
  group('SelectStoreScreen', () {
    testWidgets('renders localized store selection copy and roles', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(_StoresAuthController.new));
      await tester.pumpAndSettle();

      expect(find.text('Select store'), findsOneWidget);
      expect(find.text('Choose a store'), findsOneWidget);
      expect(
        find.textContaining("Pick where you're working today"),
        findsOneWidget,
      );
      expect(find.text('Andheri Store'), findsOneWidget);
      expect(find.text('Bandra Store'), findsOneWidget);
      expect(find.text('Manager'), findsOneWidget);
      expect(find.text('Staff'), findsOneWidget);
    });

    testWidgets('renders localized no-store empty state', (tester) async {
      await tester.pumpWidget(_buildSubject(_NoStoresAuthController.new));
      await tester.pumpAndSettle();

      expect(find.text('No stores yet'), findsOneWidget);
      expect(
        find.textContaining('not associated with any store'),
        findsOneWidget,
      );

      await tester.tap(find.text('Contact your manager'));
      await tester.pumpAndSettle();

      expect(
        find.text('Reach out to your manager to be added to a store.'),
        findsOneWidget,
      );
    });
  });
}
