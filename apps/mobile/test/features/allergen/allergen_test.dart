import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:radha_mobile/core/auth/auth_controller.dart';
import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/allergen_profile_dto.dart';
import 'package:radha_mobile/features/allergen/allergen_profile_screen.dart';

class MockApiClient extends Mock implements ApiClient {}

class FakeUpdateAllergenProfileDto extends Fake
    implements UpdateAllergenProfileDto {}

const _testUser = CurrentUser(
  userId: 'user-1',
  tenantId: 'tenant-1',
  roles: ['owner'],
  selectedStoreId: 'store-1',
  selectedStoreName: 'Test store',
);

Widget _buildApp(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) => _testUser),
      ...overrides,
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockApiClient api;

  setUpAll(() {
    registerFallbackValue(FakeUpdateAllergenProfileDto());
  });

  setUp(() {
    api = MockApiClient();
  });

  group('AllergenProfileScreen', () {
    testWidgets('renders all canonical allergen chips', (tester) async {
      when(() => api.getAllergenProfile(any())).thenAnswer(
        (_) async =>
            const AllergenProfileResponse(userId: 'user-1', allergens: []),
      );

      await tester.pumpWidget(
        _buildApp(
          const AllergenProfileScreen(),
          overrides: [apiClientProvider.overrideWithValue(api)],
        ),
      );
      await tester.pumpAndSettle();

      // Every canonical option must surface as a chip on the screen.
      for (final option in kAllergenOptions) {
        expect(
          find.text(option.label),
          findsOneWidget,
          reason: '${option.label} chip should be visible',
        );
      }
    });

    testWidgets('selecting a chip toggles its state', (tester) async {
      when(() => api.getAllergenProfile(any())).thenAnswer(
        (_) async =>
            const AllergenProfileResponse(userId: 'user-1', allergens: []),
      );
      when(() => api.updateAllergenProfile(any(), any())).thenAnswer(
        (_) async =>
            const AllergenProfileResponse(userId: 'user-1', allergens: []),
      );

      await tester.pumpWidget(
        _buildApp(
          const AllergenProfileScreen(),
          overrides: [apiClientProvider.overrideWithValue(api)],
        ),
      );
      await tester.pumpAndSettle();

      // Toggle on.
      await tester.tap(find.text('Peanut'));
      await tester.pump();

      // Toggle off — the chip is tapped a second time.
      await tester.tap(find.text('Peanut'));
      await tester.pump();

      // Save now persists an empty selection — proves the second tap
      // cleared the first one rather than stacking.
      final saveButton = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      final captured = verify(
        () => api.updateAllergenProfile('user-1', captureAny()),
      ).captured;
      expect(captured, hasLength(1));
      final body = captured.single as UpdateAllergenProfileDto;
      expect(body.allergens, isEmpty);
    });

    testWidgets('save button calls updateAllergenProfile', (tester) async {
      when(() => api.getAllergenProfile(any())).thenAnswer(
        (_) async =>
            const AllergenProfileResponse(userId: 'user-1', allergens: []),
      );
      when(() => api.updateAllergenProfile(any(), any())).thenAnswer(
        (_) async => const AllergenProfileResponse(
          userId: 'user-1',
          allergens: ['peanut', 'gluten'],
        ),
      );

      await tester.pumpWidget(
        _buildApp(
          const AllergenProfileScreen(),
          overrides: [apiClientProvider.overrideWithValue(api)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Peanut'));
      await tester.tap(find.text('Gluten'));
      await tester.pump();

      // Save bar lives below the wrap; ensure it's hit-testable.
      final saveButton = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      final captured = verify(
        () => api.updateAllergenProfile('user-1', captureAny()),
      ).captured;
      expect(captured, hasLength(1));
      final body = captured.single as UpdateAllergenProfileDto;
      expect(body.allergens, containsAll(['peanut', 'gluten']));
    });
  });
}
