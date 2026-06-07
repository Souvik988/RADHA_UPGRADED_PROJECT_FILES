// Subscription entitlement provider.
//
// Fetches the tenant's subscription status from the backend and exposes
// helpers to check feature access and usage limits. All feature-gating
// in the app reads from this provider — no ad-hoc permission logic.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/dto/subscription_dto.dart';

// ─── Domain types ─────────────────────────────────────────────────────────

/// Features that can be gated by subscription plan.
enum Feature {
  advancedReports,
  inventory,
  grn,
  allergenProfile,
  recallAlerts,
  weeklyDigest,
  healthyAlternatives,
  ingredientExplainer,
  bulkScan,
  multiStore,
}

/// Billing cadence for a subscription.
enum BillingCycle { monthly, yearly }

/// Usage info for metered features (current usage vs limit).
class UsageInfo {
  const UsageInfo({required this.current, required this.limit});
  final int current;
  final int limit;

  bool get exceeded => current >= limit;
  double get ratio => limit > 0 ? current / limit : 0;
}

/// Immutable snapshot of the tenant's entitlement state.
class EntitlementState {
  const EntitlementState({
    required this.planId,
    required this.billingCycle,
    required this.features,
    this.trialDaysRemaining,
    this.usage = const {},
  });

  final String planId;
  final int? trialDaysRemaining;
  final BillingCycle billingCycle;
  final Set<Feature> features;
  final Map<Feature, UsageInfo> usage;
}

// ─── Plan definitions ─────────────────────────────────────────────────────

/// Which features each plan includes. Free trial gets everything for 90 days.
const Map<String, Set<Feature>> _planFeatures = {
  'free_trial': {
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
  'basic': {Feature.inventory},
  'standard': {
    Feature.advancedReports,
    Feature.inventory,
    Feature.grn,
    Feature.bulkScan,
  },
  'premium': {
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
};

/// Returns the minimum plan required to access the given feature.
String requiredPlanFor(Feature feature) {
  if (_planFeatures['basic']!.contains(feature)) return 'Basic';
  if (_planFeatures['standard']!.contains(feature)) return 'Standard';
  return 'Premium';
}

// ─── Provider ─────────────────────────────────────────────────────────────

/// Async notifier that fetches subscription status and exposes entitlement
/// checks to any widget in the tree.
class EntitlementController extends AsyncNotifier<EntitlementState> {
  @override
  Future<EntitlementState> build() async {
    final api = ref.read(apiClientProvider);
    final response = await api.getSubscription();
    return _mapResponse(response);
  }

  /// Whether the current plan grants access to [feature].
  bool canAccess(Feature feature) {
    final state = this.state.valueOrNull;
    if (state == null) return false;
    return state.features.contains(feature);
  }

  /// Returns usage info for a metered [feature], or null if unmetered.
  UsageInfo? usageOf(Feature feature) {
    return state.valueOrNull?.usage[feature];
  }

  /// Force-refreshes entitlement state from the backend.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiClientProvider);
      final response = await api.getSubscription();
      return _mapResponse(response);
    });
  }

  EntitlementState _mapResponse(SubscriptionResponse response) {
    final planId = response.plan.toLowerCase();
    final features = _planFeatures[planId] ?? const {};

    int? trialDays;
    if (planId == 'free_trial' && response.expiresAt != null) {
      final expires = DateTime.tryParse(response.expiresAt!);
      if (expires != null) {
        trialDays = expires.difference(DateTime.now()).inDays;
        if (trialDays < 0) trialDays = 0;
      }
    }

    return EntitlementState(
      planId: planId,
      billingCycle: BillingCycle.monthly,
      features: features,
      trialDaysRemaining: trialDays,
    );
  }
}

/// The global entitlement provider. Watch this from any widget that needs to
/// check feature access.
final entitlementProvider =
    AsyncNotifierProvider<EntitlementController, EntitlementState>(
      EntitlementController.new,
    );
