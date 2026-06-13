import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:radha_mobile/core/entitlements/entitlement_provider.dart';
import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/subscription_status_dto.dart';
import 'package:radha_mobile/design/widgets/locked_feature.dart';

/// Fake ApiClient returning a scripted subscription status.
class _FakeApi implements ApiClient {
  _FakeApi(this.status);
  final SubscriptionStatusDto status;

  @override
  Future<SubscriptionStatusDto> getSubscriptionStatus() async => status;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SubscriptionStatusDto _status({
  required bool isActive,
  required String code,
  String status = 'active',
  Map<String, bool> features = const {},
  Map<String, dynamic> limits = const {},
  int? trialDaysRemaining,
}) => SubscriptionStatusDto(
  isActive: isActive,
  status: status,
  plan: SubscriptionPlanDto(
    id: '11111111-1111-4111-8111-111111111111',
    code: code,
    name: code,
    price: 0,
    currency: 'INR',
  ),
  features: features,
  limits: limits,
  trialDaysRemaining: trialDaysRemaining,
);

Future<EntitlementState> _resolve(SubscriptionStatusDto status) async {
  final container = ProviderContainer(
    overrides: [apiClientProvider.overrideWithValue(_FakeApi(status))],
  );
  addTearDown(container.dispose);
  return container.read(entitlementProvider.future);
}

void main() {
  group('entitlement mapping from /subscriptions/status', () {
    test(
      'growth (advanced_analytics + stores>1) unlocks tier features',
      () async {
        final state = await _resolve(
          _status(
            isActive: true,
            code: 'growth',
            features: {'advanced_analytics': true},
            limits: {'stores': 5},
          ),
        );
        expect(state.features.contains(Feature.advancedReports), isTrue);
        expect(state.features.contains(Feature.multiStore), isTrue);
        // App-capability features ride on any active plan.
        expect(state.features.contains(Feature.inventory), isTrue);
        expect(state.features.contains(Feature.grn), isTrue);
      },
    );

    test(
      'starter (no advanced_analytics, stores=1) gates tier features',
      () async {
        final state = await _resolve(
          _status(
            isActive: true,
            code: 'starter',
            features: {'advanced_analytics': false},
            limits: {'stores': 1},
          ),
        );
        expect(state.features.contains(Feature.advancedReports), isFalse);
        expect(state.features.contains(Feature.multiStore), isFalse);
        expect(state.features.contains(Feature.inventory), isTrue);
        expect(state.planId, 'starter');
      },
    );

    test('inactive subscription grants nothing', () async {
      final state = await _resolve(
        _status(isActive: false, code: 'starter', status: 'expired'),
      );
      expect(state.features, isEmpty);
      expect(state.isActive, isFalse);
    });

    test('trial maps trialDaysRemaining', () async {
      final state = await _resolve(
        _status(
          isActive: true,
          code: 'trial',
          status: 'trial',
          trialDaysRemaining: 42,
        ),
      );
      expect(state.status, 'trial');
      expect(state.trialDaysRemaining, 42);
    });

    test('unlimited stores unlocks multiStore', () async {
      final state = await _resolve(
        _status(
          isActive: true,
          code: 'pro',
          features: {'advanced_analytics': true},
          limits: {'stores': 'unlimited'},
        ),
      );
      expect(state.features.contains(Feature.multiStore), isTrue);
    });
  });

  group('UsageInfo + requiredPlanFor', () {
    test('UsageInfo.exceeded', () {
      expect(const UsageInfo(current: 10, limit: 10).exceeded, isTrue);
      expect(const UsageInfo(current: 5, limit: 10).exceeded, isFalse);
    });

    test('requiredPlanFor maps to real plan names', () {
      expect(requiredPlanFor(Feature.advancedReports), 'Growth');
      expect(requiredPlanFor(Feature.multiStore), 'Growth');
      expect(requiredPlanFor(Feature.inventory), 'Starter');
      expect(requiredPlanFor(Feature.ingredientExplainer), 'Starter');
    });
  });

  group('LockedFeature widget', () {
    testWidgets('shows overlay when feature is denied', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            entitlementProvider.overrideWith(() => _DeniedController()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LockedFeature(
                feature: Feature.advancedReports,
                child: Text('Advanced Reports Content'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
      expect(find.text('View plans'), findsOneWidget);
      expect(find.text('Advanced Reports Content'), findsOneWidget);
    });

    testWidgets('renders child normally when feature is allowed', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            entitlementProvider.overrideWith(() => _AllowedController()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LockedFeature(
                feature: Feature.inventory,
                child: Text('Inventory Content'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inventory Content'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsNothing);
      expect(find.text('View plans'), findsNothing);
    });
  });
}

EntitlementState _fixed(String code, Set<Feature> features) => EntitlementState(
  planId: code,
  planName: code,
  status: 'active',
  isActive: true,
  billingCycle: BillingCycle.monthly,
  features: features,
);

/// Denies advanced reports (starter-like).
class _DeniedController extends EntitlementController {
  @override
  Future<EntitlementState> build() async =>
      _fixed('starter', {Feature.inventory});
}

/// Allows everything (pro-like).
class _AllowedController extends EntitlementController {
  @override
  Future<EntitlementState> build() async =>
      _fixed('pro', Feature.values.toSet());
}
