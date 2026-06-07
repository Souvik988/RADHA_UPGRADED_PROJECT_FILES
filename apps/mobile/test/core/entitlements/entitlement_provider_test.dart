import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:radha_mobile/core/entitlements/entitlement_provider.dart';
import 'package:radha_mobile/design/widgets/locked_feature.dart';

void main() {
  group('EntitlementState', () {
    test('canAccess returns true for included features', () {
      final controller = EntitlementController();
      final container = ProviderContainer(
        overrides: [entitlementProvider.overrideWith(() => controller)],
      );
      addTearDown(container.dispose);

      // Simulate a standard plan state
      container.read(entitlementProvider.notifier);
      final state = EntitlementState(
        planId: 'standard',
        billingCycle: BillingCycle.monthly,
        features: {
          Feature.advancedReports,
          Feature.inventory,
          Feature.grn,
          Feature.bulkScan,
        },
      );

      expect(state.features.contains(Feature.inventory), isTrue);
      expect(state.features.contains(Feature.grn), isTrue);
      expect(state.features.contains(Feature.advancedReports), isTrue);
      expect(state.features.contains(Feature.bulkScan), isTrue);
    });

    test('canAccess returns false for excluded features', () {
      final state = EntitlementState(
        planId: 'basic',
        billingCycle: BillingCycle.monthly,
        features: {Feature.inventory},
      );

      expect(state.features.contains(Feature.inventory), isTrue);
      expect(state.features.contains(Feature.grn), isFalse);
      expect(state.features.contains(Feature.advancedReports), isFalse);
      expect(state.features.contains(Feature.allergenProfile), isFalse);
      expect(state.features.contains(Feature.recallAlerts), isFalse);
      expect(state.features.contains(Feature.weeklyDigest), isFalse);
    });

    test('UsageInfo.exceeded is true when current >= limit', () {
      const usage = UsageInfo(current: 10, limit: 10);
      expect(usage.exceeded, isTrue);

      const usage2 = UsageInfo(current: 5, limit: 10);
      expect(usage2.exceeded, isFalse);
    });

    test('requiredPlanFor returns correct plan name', () {
      expect(requiredPlanFor(Feature.inventory), 'Basic');
      expect(requiredPlanFor(Feature.grn), 'Standard');
      expect(requiredPlanFor(Feature.allergenProfile), 'Premium');
      expect(requiredPlanFor(Feature.weeklyDigest), 'Premium');
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

      // The lock icon and upgrade text should be visible
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
      expect(find.text('View plans'), findsOneWidget);
      // The child content is still rendered (just dimmed)
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

      // Child renders normally, no lock overlay
      expect(find.text('Inventory Content'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsNothing);
      expect(find.text('View plans'), findsNothing);
    });
  });
}

/// Controller that simulates a basic plan (denies advanced reports).
class _DeniedController extends EntitlementController {
  @override
  Future<EntitlementState> build() async {
    return const EntitlementState(
      planId: 'basic',
      billingCycle: BillingCycle.monthly,
      features: {Feature.inventory},
    );
  }
}

/// Controller that simulates a premium plan (allows everything).
class _AllowedController extends EntitlementController {
  @override
  Future<EntitlementState> build() async {
    return const EntitlementState(
      planId: 'premium',
      billingCycle: BillingCycle.monthly,
      features: {
        Feature.advancedReports,
        Feature.inventory,
        Feature.grn,
        Feature.allergenProfile,
        Feature.recallAlerts,
        Feature.weeklyDigest,
        Feature.healthyAlternatives,
        Feature.ingredientExplainer,
        Feature.bulkScan,
        Feature.multiStore,
      },
    );
  }
}
