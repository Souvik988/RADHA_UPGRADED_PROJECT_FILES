// Subscription entitlement provider.
//
// Single source of feature-gating for the app. State is derived from the
// backend `GET /api/v1/subscriptions/status` response — never from a hardcoded
// plan→feature table. The server owns features/limits/usage/plan/trial/renewal;
// this layer only normalises the backend feature keys onto the app's [Feature]
// enum and exposes `canAccess`.

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/dto/subscription_status_dto.dart';

// ─── Domain types ─────────────────────────────────────────────────────────

/// App-level capabilities the UI may gate. These are RADHA UI features; the
/// backend gates only a subset as explicit flags (see [_allows]).
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

/// Immutable snapshot of the tenant's entitlement state, projected from the
/// server status response.
class EntitlementState {
  const EntitlementState({
    required this.planId,
    required this.planName,
    required this.status,
    required this.isActive,
    required this.billingCycle,
    required this.features,
    this.trialDaysRemaining,
    this.daysUntilRenewal,
    this.usage = const {},
  });

  /// Backend plan *code* (trial / starter / growth / pro). Kept named `planId`
  /// for source compatibility with existing callers.
  final String planId;
  final String planName;

  /// Raw server status: trial / active / expired / cancelled / past_due / paused.
  final String status;
  final bool isActive;
  final int? trialDaysRemaining;
  final int? daysUntilRenewal;
  final BillingCycle billingCycle;
  final Set<Feature> features;
  final Map<Feature, UsageInfo> usage;
}

// ─── Backend feature-key normalisation ─────────────────────────────────────

/// Backend feature keys we understand (mirrors `ALL_FEATURES` server-side).
/// Keys outside this set are logged once and ignored — never auto-granted.
const Set<String> _knownServerFeatureKeys = {
  'stores',
  'users',
  'monthly_scans',
  'monthly_reports',
  'ean_lists',
  'ai_ocr',
  'ai_label_analysis',
  'llm_summaries',
  'rekognition',
  'priority_support',
  'custom_branding',
  'api_access',
  'advanced_analytics',
};

bool _loggedUnknownKeys = false;

/// Decide access for an app [Feature] from the server status. Where the backend
/// exposes a matching flag/limit we honour it; the remaining app capabilities
/// are not gated per-flag by the backend, so they ride on any *active* plan
/// (trial included) — the app never invents a paywall the backend doesn't
/// enforce.
bool _allows(SubscriptionStatusDto s, Feature f) {
  if (!s.isActive) return false;
  switch (f) {
    case Feature.advancedReports:
      return s.hasServerFeature('advanced_analytics');
    case Feature.multiStore:
      return s.isUnlimited('stores') || (s.limitOf('stores') ?? 0) > 1;
    case Feature.inventory:
    case Feature.grn:
    case Feature.allergenProfile:
    case Feature.recallAlerts:
    case Feature.weeklyDigest:
    case Feature.healthyAlternatives:
    case Feature.ingredientExplainer:
    case Feature.bulkScan:
      return true;
  }
}

/// The smallest plan that unlocks [feature] — display copy for locked states.
String requiredPlanFor(Feature feature) {
  switch (feature) {
    case Feature.advancedReports:
    case Feature.multiStore:
      return 'Growth';
    case Feature.inventory:
    case Feature.grn:
    case Feature.allergenProfile:
    case Feature.recallAlerts:
    case Feature.weeklyDigest:
    case Feature.healthyAlternatives:
    case Feature.ingredientExplainer:
    case Feature.bulkScan:
      return 'Starter';
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────

class EntitlementController extends AsyncNotifier<EntitlementState> {
  @override
  Future<EntitlementState> build() => _load();

  Future<EntitlementState> _load() async {
    final api = ref.read(apiClientProvider);
    return _map(await api.getSubscriptionStatus());
  }

  /// Whether the current plan grants access to [feature].
  bool canAccess(Feature feature) =>
      state.valueOrNull?.features.contains(feature) ?? false;

  /// Usage info for a metered [feature], or null if unmetered.
  UsageInfo? usageOf(Feature feature) => state.valueOrNull?.usage[feature];

  /// Refresh from the backend, **preserving the last valid state** on failure
  /// (silent background refresh). Used after a verified payment so the new plan
  /// appears without flashing a full-screen loader/error.
  Future<void> refresh() async {
    final api = ref.read(apiClientProvider);
    try {
      state = AsyncData(_map(await api.getSubscriptionStatus()));
    } catch (e, st) {
      if (!state.hasValue) state = AsyncError(e, st);
    }
  }

  EntitlementState _map(SubscriptionStatusDto s) {
    _logUnknownKeysOnce(s);
    final features = <Feature>{
      for (final f in Feature.values)
        if (_allows(s, f)) f,
    };
    return EntitlementState(
      planId: s.plan.code,
      planName: s.plan.name,
      status: s.status,
      isActive: s.isActive,
      billingCycle: BillingCycle.monthly, // /status does not expose the cycle
      features: features,
      trialDaysRemaining: s.status == 'trial' ? s.trialDaysRemaining : null,
      daysUntilRenewal: s.daysUntilRenewal,
    );
  }

  void _logUnknownKeysOnce(SubscriptionStatusDto s) {
    if (_loggedUnknownKeys) return;
    final unknown = <String>{...s.features.keys, ...s.limits.keys}
      ..removeWhere(_knownServerFeatureKeys.contains);
    if (unknown.isNotEmpty) {
      developer.log(
        'ignoring unknown subscription feature keys: ${unknown.join(',')}',
        name: 'radha.entitlements',
        level: 900,
      );
      _loggedUnknownKeys = true;
    }
  }
}

/// The global entitlement provider. Watch this from any widget that needs to
/// check feature access.
final entitlementProvider =
    AsyncNotifierProvider<EntitlementController, EntitlementState>(
      EntitlementController.new,
    );
