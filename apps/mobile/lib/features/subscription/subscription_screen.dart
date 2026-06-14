// Subscription management screen.
//
// Plans come from the backend (`GET /subscriptions/plans`) with their real UUID
// `id` — checkout sends that UUID (never a plan code) plus the explicitly chosen
// billing cycle. The purchase runs through the tested [CheckoutEngine] and the
// screen reacts to a structured [CheckoutResult] (verified / cancelled / pending
// / failed), refreshing entitlements only after server verification.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

import '../../core/entitlements/entitlement_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/dto/subscription_status_dto.dart';
import '../../design/app_assets.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets/brand_illustration.dart';
import '../../design/widgets/error_state.dart';
import '../../design/widgets/mor_companion.dart';
import '../../design/widgets/primary_button.dart';
import '../../design/widgets/skeleton_loader.dart';
import 'payment/checkout_engine.dart';
import 'payment/checkout_models.dart';
import 'payment/razorpay_adapter.dart';

// ─── Providers ──────────────────────────────────────────────────────────────

/// Public, purchasable plans from the backend (source of truth for price + the
/// UUID used at checkout). Sorted by the server `sortOrder`.
final subscriptionPlansProvider =
    FutureProvider.autoDispose<List<SubscriptionPlanDto>>((ref) async {
      final plans = await ref.watch(apiClientProvider).getSubscriptionPlans();
      final list = [...plans]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });

/// The payment engine, overridable in tests with a fake adapter/api.
final checkoutEngineProvider = Provider<CheckoutEngine>(
  (ref) => CheckoutEngine(
    api: ref.watch(apiClientProvider),
    adapterFactory: FlutterRazorpayAdapter.new,
  ),
);

// ─── Screen ───────────────────────────────────────────────────────────────

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final entitlement = ref.watch(entitlementProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          l10n.subTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: entitlement.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: RadhaColors.primary),
        ),
        error: (_, _) => Center(
          child: ErrorState(
            title: l10n.subLoadError,
            body: l10n.subErrorBody,
            onRetry: () => ref.invalidate(entitlementProvider),
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
  BillingCycle _cycle = BillingCycle.monthly;
  String? _busyPlanCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final state = widget.state;
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        RadhaSpacing.space20,
        RadhaSpacing.space16,
        RadhaSpacing.space20,
        RadhaSpacing.space48,
      ),
      children: [
        Center(
          child: BrandIllustration(
            RadhaAssets.paywallHero,
            size: 196,
            fallback: const MorCompanion(mood: MorMood.guard, size: 120),
          ),
        ),
        const SizedBox(height: RadhaSpacing.space8),
        Text(
          l10n.subUnlockHeadline,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: RadhaSpacing.space24),
        _CurrentPlanCard(state: state),
        const SizedBox(height: RadhaSpacing.space24),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.subChoosePlan,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _BillingToggle(
              cycle: _cycle,
              onChanged: (c) {
                HapticFeedback.selectionClick();
                setState(() => _cycle = c);
              },
            ),
          ],
        ),
        const SizedBox(height: RadhaSpacing.space12),
        plansAsync.when(
          loading: () => const _PlansSkeleton(),
          error: (_, _) => ErrorState(
            title: l10n.subPlansLoadError,
            body: l10n.subErrorBody,
            onRetry: () => ref.invalidate(subscriptionPlansProvider),
          ),
          data: (plans) {
            if (plans.isEmpty) {
              return Text(
                l10n.subPlansUnavailable,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }
            return Column(
              children: [
                for (final plan in plans)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: RadhaSpacing.space12,
                    ),
                    child: _PlanCard(
                      plan: plan,
                      cycle: _cycle,
                      isCurrent: plan.code == state.planId,
                      recommended: plan.code == 'growth',
                      busy: _busyPlanCode == plan.code,
                      disabled:
                          _busyPlanCode != null && _busyPlanCode != plan.code,
                      onUpgrade: () => _handleUpgrade(plan),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: RadhaSpacing.space12),
        Center(
          child: Text(
            l10n.subSecurePayment,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleUpgrade(SubscriptionPlanDto plan) async {
    if (_busyPlanCode != null) return;
    HapticFeedback.lightImpact();
    setState(() => _busyPlanCode = plan.code);
    final engine = ref.read(checkoutEngineProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    void snack(String msg) =>
        messenger.showSnackBar(SnackBar(content: Text(msg)));

    try {
      final result = await engine.run(
        planId: plan.id,
        billingCycle: _cycle.name,
      );
      if (!mounted) return;
      switch (result) {
        case CheckoutVerified():
          await ref.read(entitlementProvider.notifier).refresh();
          if (!mounted) return;
          HapticFeedback.mediumImpact();
          snack(l10n.subWelcome(plan.name));
        case CheckoutCancelled():
          snack(l10n.subCheckoutCancelled);
        case CheckoutPending(:final supportRef):
          snack(l10n.subPaymentPending(supportRef));
        case CheckoutFailed(:final message):
          snack(message ?? l10n.subPaymentFailed);
      }
    } finally {
      if (mounted) setState(() => _busyPlanCode = null);
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
    final l10n = AppLocalizations.of(context);
    final trialDays = state.trialDaysRemaining;
    final onTrial = state.status == 'trial' && trialDays != null;

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
                l10n.subCurrentPlan,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              _StatusChipForState(state: state),
            ],
          ),
          const SizedBox(height: RadhaSpacing.space4),
          Text(
            state.planName.isEmpty ? state.planId : state.planName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (state.daysUntilRenewal != null && !onTrial) ...[
            const SizedBox(height: RadhaSpacing.space4),
            Text(
              l10n.subRenewsInDays(state.daysUntilRenewal!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (onTrial) ...[
            const SizedBox(height: RadhaSpacing.space16),
            ClipRRect(
              borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
              child: LinearProgressIndicator(
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

class _StatusChipForState extends StatelessWidget {
  const _StatusChipForState({required this.state});
  final EntitlementState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final (String label, Color color) = switch (state.status) {
      'trial' => (
        state.trialDaysRemaining != null
            ? l10n.subStatusDaysLeft(state.trialDaysRemaining!)
            : l10n.subStatusTrial,
        RadhaColors.primaryDeep,
      ),
      'active' => (l10n.subStatusActive, RadhaColors.success),
      'past_due' => (l10n.subStatusPastDue, RadhaColors.warning),
      'paused' => (l10n.subStatusPaused, RadhaColors.warning),
      'cancelled' => (l10n.subStatusCancelled, RadhaColors.danger),
      'expired' => (l10n.expired, RadhaColors.danger),
      _ => (state.status, theme.colorScheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RadhaSpacing.space12,
        vertical: RadhaSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Billing cycle toggle ──────────────────────────────────────────────────

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({required this.cycle, required this.onChanged});
  final BillingCycle cycle;
  final ValueChanged<BillingCycle> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    Widget seg(String label, BillingCycle value) {
      final selected = cycle == value;
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RadhaSpacing.space12,
              vertical: RadhaSpacing.space8,
            ),
            decoration: BoxDecoration(
              color: selected ? RadhaColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? RadhaColors.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(l10n.subBillingMonthly, BillingCycle.monthly),
          seg(l10n.subBillingYearly, BillingCycle.yearly),
        ],
      ),
    );
  }
}

// ─── Plan card ────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.cycle,
    required this.isCurrent,
    required this.recommended,
    required this.busy,
    required this.disabled,
    required this.onUpgrade,
  });

  final SubscriptionPlanDto plan;
  final BillingCycle cycle;
  final bool isCurrent;
  final bool recommended;
  final bool busy;
  final bool disabled;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final highlight = recommended && !isCurrent;
    final highlights = plan.features
        .where((f) => (f.description ?? '').isNotEmpty)
        .take(4)
        .toList();

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
              if (recommended) const _PopularBadge(),
              const Spacer(),
              _PlanPrice(plan: plan, cycle: cycle),
            ],
          ),
          if ((plan.description ?? '').isNotEmpty) ...[
            const SizedBox(height: RadhaSpacing.space4),
            Text(
              plan.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: RadhaSpacing.space12),
          for (final f in highlights)
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
                      f.description!,
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
            _CurrentPill(name: plan.name)
          else if (highlight)
            PrimaryButton(
              label: l10n.subUpgradeTo(plan.name),
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
                  : Text(l10n.subChoosePlanNamed(plan.name)),
            ),
        ],
      ),
    );
  }
}

class _PlanPrice extends StatelessWidget {
  const _PlanPrice({required this.plan, required this.cycle});
  final SubscriptionPlanDto plan;
  final BillingCycle cycle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final yearly = cycle == BillingCycle.yearly;
    // Show the real monthly price always; for yearly, show the backend yearly
    // price when present, else state honestly that it's billed yearly at the
    // verified amount (no fabricated number).
    final amount = yearly ? plan.yearlyPrice : plan.price;
    final suffix = yearly ? l10n.subPerYear : l10n.subPerMonth;

    if (yearly && plan.yearlyPrice == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₹${_fmt(plan.price)}',
            style: radhaMonoStyle(
              fontSize: 20,
              weight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            l10n.subBilledYearly,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '₹${_fmt(amount ?? plan.price)}',
          style: radhaMonoStyle(
            fontSize: 20,
            weight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          suffix,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

class _PopularBadge extends StatelessWidget {
  const _PopularBadge();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RadhaSpacing.space8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: RadhaColors.primary,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
      ),
      child: Text(
        l10n.subPopular,
        style: theme.textTheme.labelSmall?.copyWith(
          color: RadhaColors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CurrentPill extends StatelessWidget {
  const _CurrentPill({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: RadhaSpacing.space12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: RadhaColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
        border: Border.all(color: RadhaColors.primary),
      ),
      child: Text(
        l10n.subYoureOnPlan(name),
        style: theme.textTheme.labelLarge?.copyWith(
          color: RadhaColors.primaryDeep,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlansSkeleton extends StatelessWidget {
  const _PlansSkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: RadhaSpacing.space12),
            child: SkeletonLoader(height: 150, radius: RadhaRadii.radiusLg),
          ),
      ],
    );
  }
}
