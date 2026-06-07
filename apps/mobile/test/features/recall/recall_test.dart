import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/misc_dto.dart';
import 'package:radha_mobile/design/tokens.dart';
import 'package:radha_mobile/features/recall/recall_alerts_screen.dart';

class MockApiClient extends Mock implements ApiClient {}

/// Wraps the screen in a tiny GoRouter so taps that call `context.push` get
/// resolved against a real Navigator stack instead of crashing.
Widget _buildApp({required ApiClient api}) {
  final router = GoRouter(
    initialLocation: '/recall-alerts',
    routes: [
      GoRoute(
        path: '/recall-alerts',
        builder: (_, _) => const RecallAlertsScreen(),
      ),
      GoRoute(
        path: '/scan/result/:ean',
        builder: (_, state) => Scaffold(
          appBar: AppBar(title: Text('Detail ${state.pathParameters['ean']}')),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(api)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockApiClient api;

  setUp(() {
    api = MockApiClient();
  });

  group('RecallAlertsScreen', () {
    testWidgets('renders recall items returned by the backend', (tester) async {
      when(() => api.getRecalls()).thenAnswer(
        (_) async => [
          const RecallResponse(
            id: 'r-1',
            productId: 'p-1',
            reason: 'Salmonella detected in batch.',
            severity: 'critical',
            productName: 'Crunchy Cookies',
            productEan: '8901234567890',
            recalledAt: '2024-04-01',
          ),
          const RecallResponse(
            id: 'r-2',
            productId: 'p-2',
            reason: 'Mislabelled allergens.',
            severity: 'medium',
            productName: 'Spicy Mix',
            productEan: '8909876543210',
            recalledAt: '2024-03-15',
          ),
        ],
      );

      await tester.pumpWidget(_buildApp(api: api));
      await tester.pumpAndSettle();

      expect(find.text('Crunchy Cookies'), findsOneWidget);
      expect(find.text('Spicy Mix'), findsOneWidget);
      expect(find.text('Salmonella detected in batch.'), findsOneWidget);
    });

    testWidgets('severity badge color matches severity', (tester) async {
      when(() => api.getRecalls()).thenAnswer(
        (_) async => [
          const RecallResponse(
            id: 'r-1',
            productId: 'p-1',
            reason: 'Critical recall.',
            severity: 'critical',
            productName: 'Critical Product',
            productEan: '8900000000001',
            recalledAt: '2024-04-01',
          ),
          const RecallResponse(
            id: 'r-2',
            productId: 'p-2',
            reason: 'Medium recall.',
            severity: 'medium',
            productName: 'Medium Product',
            productEan: '8900000000002',
            recalledAt: '2024-04-02',
          ),
        ],
      );

      await tester.pumpWidget(_buildApp(api: api));
      await tester.pumpAndSettle();

      final critical = tester.widget<Text>(find.text('CRITICAL'));
      expect(critical.style?.color, RadhaColors.danger);

      final medium = tester.widget<Text>(find.text('MEDIUM'));
      expect(medium.style?.color, RadhaColors.warning);
    });

    testWidgets('tapping a recall navigates to product detail', (tester) async {
      when(() => api.getRecalls()).thenAnswer(
        (_) async => [
          const RecallResponse(
            id: 'r-1',
            productId: 'p-1',
            reason: 'Allergen mislabel.',
            severity: 'high',
            productName: 'Tappable Product',
            productEan: '8901111111111',
            recalledAt: '2024-04-01',
          ),
        ],
      );

      await tester.pumpWidget(_buildApp(api: api));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tappable Product'));
      await tester.pumpAndSettle();

      // The fake detail route surfaces an AppBar with the EAN — confirm
      // we landed on it.
      expect(find.text('Detail 8901111111111'), findsOneWidget);
    });

    testWidgets('shows empty state when there are no recalls', (tester) async {
      when(() => api.getRecalls()).thenAnswer((_) async => const []);

      await tester.pumpWidget(_buildApp(api: api));
      await tester.pumpAndSettle();

      expect(find.text('No active recalls'), findsOneWidget);
    });
  });
}
