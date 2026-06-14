import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:radha_mobile/core/auth/auth_controller.dart';
import 'package:radha_mobile/core/auth/auth_session.dart';
import 'package:radha_mobile/features/profile/profile_screen.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

const _testSession = AuthSession(
  accessToken: 'access',
  refreshToken: 'refresh',
  userId: 'owner-123',
  tenantId: 'tenant-1',
  roles: ['owner'],
  stores: [
    StoreAccess(storeId: 'store-1', storeName: 'Sharma Store', role: 'owner'),
  ],
  selectedStoreId: 'store-1',
);

class _FakeAuthController extends AuthController {
  @override
  Future<AuthSession?> build() async => _testSession;
}

Widget _buildSubject() {
  return ProviderScope(
    overrides: [authControllerProvider.overrideWith(_FakeAuthController.new)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ProfileScreen(),
    ),
  );
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'RADHA',
      packageName: 'com.radha.mobile',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
    );
  });

  group('ProfileScreen', () {
    testWidgets('renders localized profile actions and account state', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('owner-123'), findsOneWidget);
      expect(find.text('tenant-1'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('Manage stores'), findsOneWidget);
      expect(find.text('Sharma Store'), findsOneWidget);
      expect(find.text('Saved products'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Shopping list'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Shopping list'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Version 1.2.3 (45)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Version 1.2.3 (45)'), findsOneWidget);
    });

    testWidgets('shows localized sign-out confirmation', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      final signOut = find.text('Sign out');
      await tester.scrollUntilVisible(
        signOut,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(signOut);
      await tester.pumpAndSettle();
      await tester.tap(signOut);
      await tester.pumpAndSettle();

      expect(
        find.text('You will need to sign in again with an OTP to use the app.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
