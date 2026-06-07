// Subscription management screen.
//
// Current plan + trial progress, a stacked plan-card compare (Standard marked
// "Popular"), and per-plan upgrade CTAs that open the Razorpay sheet. Matches
// the mockup: warm cream surfaces, single orange accent, plus a check-tick
// feature list per card.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/entitlements/entitlement_provider.dart';
import '../../design/app_assets.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets/mor_companion.dart';
import '../../design/widgets/primary_button.dart';
import 'razorpay_checkout_sheet.dart';

// ─── Plan metadata ────────────────────────────────────────────────────────

class _PlanInfo {
  const _PlanInfo({
    required this.id,
    required this.name,
    required this.price,
    required this.tagline,
    required this.highlights,
    required this.features,
  });

  final String id;
  final String name;
  final int price; // 0 = free trial
  final String tagline;
  final List<String> highlights;
  final Set<Feature> features;
}

const List<_PlanInfo> _plans = [
  _PlanInfo(
    id: 'free_trial',
    name: 'Free Trial',
    price: 0,
    tagline: 'Everything, free for 90 days',
    highlights: ['All features unlocked', 'No card required'],
    features: {
      Feature.inventory,
      Feature.grn,
      Feature.advancedReports,
      Feature.bulkScan,
      Feature.allergenProfile,
      Feature.recallAlerts,
      Feature.weeklyDigest,
      Feature.healthyAlternatives,
      Feature.ingredientExplainer,
      Feature.multiStore,
    },
  ),
  _PlanInfo(
    id: 'basic',
    name: 'Basic',
    price: 49,
    tagline: 'Scan, health & expiry',
    highlights: ['Inventory management', 'Unlimited scans'],
    features: {Feature.inventory},
  ),
  _PlanInfo(
    id: 'standard',
    name: 'Standard',
    price: 99,
    tagline: '+ Inventory & tasks',
    highlights: ['Everything in Basic', 'GRN inward', 'Advanced reports', 'Bulk scan'],
    features: {
      Feature.inventory,
      Feature.grn,
      Feature.advancedReports,
      Feature.bulkScan,
    },
  ),
  _PlanInfo(
    id: 'premium',
    name: 'Premium',
    price: 199,
    tagline: '+ GRN, analytics & allergen',
    highlights: ['Everything in Standard', 'Allergen & recall alerts', 'Multi-store', 'Weekly digest'],
    features: {
      Feature.inventory,
      Feature.grn,
      Feature.advancedReports,
      Feature.bulkScan,
      Feature.allergenProfile,
      Feature.recallAlerts,
      Feature.weeklyDigest,
      Feature.healthyAlternatives,
      Feature.ingredientExplainer,
      Feature.multiStore,
    },
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entitlement = ref.watch(entitlementProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Subscription',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: entitlement.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(RadhaSpacing.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MorCompanion(
                  mood: MorMood.concern,
                  size: 96,
                  semanticLabel: 'Could not load',
                ),
                const SizedBox(height: RadhaSpacing.space16),
                Text(
                  'Unable to load subscription info.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (state) => _SubscriptionBody(state: state),
      ),
    );
  }
}

class _SubscriptionBody extends ConsumerStatefulWidget {
  const _SubscriptionBody({required this.state});
  final EntitlementState state;

  @override
  ConsumerState<_SubscriptionBody> createState() => _SubscriptionBodyState();
}

class _SubscriptionBodyState extends ConsumerState<_SubscriptionBody> {
  String? _busyPlanId;

  String get _billingCycleString =>
      widget.state.billingCycle == BillingCycle.yearly ? 'yearly' : 'monthly';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        RadhaSpacing.space20,
        RadhaSpacing.space16,
        RadhaSpacing.space20,
        RadhaSpacing.space48,
      ),
      children: [
        _CurrentPlanCard(state: state),
        const SizedBox(height: RadhaSpacing.space24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Choose a plan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const MorCompanion(mood: MorMood.guard, size: 52),
          ],
        ),
        const SizedBox(height: RadhaSpacing.space12),
        for (final plan in _plans)
          if (plan.id != 'free_trial')
            Padding(
              padding: const EdgeInsets.only(bottom: RadhaSpacing.space12),
              child: _PlanCard(
                plan: plan,
                isCurrent: plan.id == state.planId,
                recommended: plan.id == 'standard',
                busy: _busyPlanId == plan.id,
                disabled: _busyPlanId != null && _busyPlanId != plan.id,
                onUpgrade: () => _handleUpgrade(plan),
              ),
            ),
        const SizedBox(height: RadhaSpacing.space12),
        Center(
          child: Text(
            'Cancel anytime · GST included',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleUpgrade(_PlanInfo plan) async {
    HapticFeedback.lightImpact();
    setState(() => _busyPlanId = plan.id);
    try {
      await openRazorpayCheckout(
        context: context,
        ref: ref,
        planId: plan.id,
        billingCycle: _billingCycleString,
      );
    } finally {
      if (mounted) setState(() => _busyPlanId = null);
    }
  }
}

// ─── Current plan card ────────────────────────────────────────────────────

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.state});
  final EntitlementState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planInfo = _plans.firstWhere(
      (p) => p.id == state.planId,
      orElse: () => _plans.first,
    );
    final trialDays = state.trialDaysRemaining;
    final onTrial = trialDays != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      padding: const EdgeInsets.all(RadhaSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Current plan',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (onTrial)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RadhaSpacing.space12,
                    vertical: RadhaSpacing.space4,
                  ),
                  decoration: BoxDecoration(
                    color: RadhaColors.primaryTint.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
                  ),
                  child: Text(
                    '$trialDays days left',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: RadhaColors.primaryDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: RadhaSpacing.space4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                planInfo.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (planInfo.price > 0)
                Text(
                  '₹${planInfo.price}',
                  style: radhaMonoStyle(
                    fontSize: 22,
                    weight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              if (planInfo.price > 0)
                Text(
                  '/mo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: RadhaSpacing.space4),
          Text(
            state.billingCycle == BillingCycle.yearly
                ? 'Yearly billing'
                : 'Monthly billing',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onTrial) ...[
            const SizedBox(height: RadhaSpacing.space16),
            ClipRRect(
              borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
              child: LinearProgressIndicator(
                // 90-day trial; show elapsed fraction.
                value: ((90 - trialDays) / 90).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: RadhaColors.primary.withValues(alpha: 0.16),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  RadhaColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Plan card ────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.recommended,
    required this.busy,
    required this.disabled,
    required this.onUpgrade,
  });

  final _PlanInfo plan;
  final bool isCurrent;
  final bool recommended;
  final bool busy;
  final bool disabled;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = recommended && !isCurrent;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
        border: Border.all(
          color: highlight || isCurrent
              ? RadhaColors.primary
              : theme.colorScheme.outline,
          width: highlight || isCurrent ? 2 : 1,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: RadhaColors.primary.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : const <BoxShadow>[],
      ),
      padding: const EdgeInsets.all(RadhaSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plan.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: RadhaSpacing.space8),
              if (recommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RadhaSpacing.space8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: RadhaColors.primary,
                    borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
                  ),
                  child: Text(
                    'Popular',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: RadhaColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '₹${plan.price}',
                style: radhaMonoStyle(
                  fontSize: 20,
                  weight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '/mo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: RadhaSpacing.space4),
          Text(
            plan.tagline,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: RadhaSpacing.space12),
          for (final h in plan.highlights)
            Padding(
              padding: const EdgeInsets.only(bottom: RadhaSpacing.space8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: RadhaColors.success,
                  ),
                  const SizedBox(width: RadhaSpacing.space8),
                  Expanded(
                    child: Text(
                      h,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: RadhaSpacing.space8),
          if (isCurrent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: RadhaSpacing.space12,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: RadhaColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
                border: Border.all(color: RadhaColors.primary),
              ),
              child: Text(
                "You're on ${plan.name}",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: RadhaColors.primaryDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else if (highlight)
            PrimaryButton(
              label: 'Upgrade to ${plan.name}',
              expand: true,
              loading: busy,
              onPressed: disabled ? null : onUpgrade,
            )
          else
            OutlinedButton(
              onPressed: disabled || busy ? null : onUpgrade,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, kMinTouchTarget),
              ),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Choose ${plan.name}'),
            ),
        ],
      ),
    );
  }
}
