// OHS Dashboard screen (FE-26).
//
// Mounted at `/ohs`. Owners and managers see this — gated by
// `Feature.advancedReports` at the route layer through `LockedFeature`.
//
// Backend wiring
// ──────────────
//   * `GET /api/v1/dashboard/summary?storeId=<uuid>` (BE-20).
//
// The OHS score, breakdowns, week-over-week delta, and 7-bar trend are
// _derived_ from the wire DTO via [OhsSnapshot.fromDashboard]. When the
// backend grows a canonical OHS field we'll consume it directly without
// changing this screen.
//
// Visual contract (anti-slop)
// ──────────────────────────
//   * Single orange accent for healthy ranges (80+); rose for the
//     red zone (0-39); amber for the middle (40-59).
//   * Plus Jakarta Sans display weight for the headline; JetBrains
//     Mono 64sp for the score numeric.
//   * Asymmetric 2-column bento grid for the breakdown — same shape
//     as the digest screen.
//   * 7-bar mini chart drawn with `Container` heights — no charting
//     package is pulled in for V1.
//   * Animations on transform/opacity only — `RadhaMotion.medium`.
//   * 44pt+ touch targets on every interactive surface.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:radha_mobile/core/auth/auth_controller.dart';
import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/api_exception.dart';
import 'package:radha_mobile/core/network/dto/reports_dto.dart';
import 'package:radha_mobile/core/network/error_codes.dart';
import 'package:radha_mobile/core/router/app_router.dart';
import 'package:radha_mobile/design/app_assets.dart';
import 'package:radha_mobile/design/theme.dart';
import 'package:radha_mobile/design/tokens.dart';
import 'package:radha_mobile/design/widgets/mor_companion.dart';
import 'package:radha_mobile/design/widgets/primary_button.dart';
import 'package:radha_mobile/design/widgets/secondary_button.dart';
import 'package:radha_mobile/design/widgets/skeleton_loader.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

/// Async provider for the live OHS snapshot. Resolves the active store
/// from the auth session and asks the dashboard endpoint for the last
/// 14 days so we have enough trend points to compute a week-over-week
/// delta. The 14-day window is a v1 default — once the backend exposes
/// a `daysAhead=...` ergonomic we'll swap to whatever it recommends.
final ohsSnapshotProvider = FutureProvider.autoDispose<OhsSnapshot>((ref) async {
  final api = ref.watch(apiClientProvider);
  final user = ref.watch(currentUserProvider);
  final storeId = user?.selectedStoreId;
  if (storeId == null) {
    // Caller should be parked at /select-store; surface a friendly error
    // so the screen renders the empty state rather than throwing into
    // the user's face.
    throw const ApiException(
      statusCode: 400,
      code: 'NO_STORE_SELECTED',
      message: 'Pick a store before opening the dashboard.',
    );
  }
  final response = await api.getDashboardSummary(storeId, daysAhead: 14);
  return OhsSnapshot.fromDashboard(response);
});

/// OHS Dashboard surface mounted at `/ohs`.
class OhsDashboardScreen extends ConsumerWidget {
  const OhsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final asyncSnapshot = ref.watch(ohsSnapshotProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ohsTitle, style: theme.textTheme.titleMedium),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ohsSnapshotProvider);
            await ref.read(ohsSnapshotProvider.future);
          },
          child: asyncSnapshot.when(
            loading: () => const _OhsSkeleton(),
            error: (err, _) => _OhsError(
              title: l10n.ohsErrorTitle,
              message: _errorMessage(err, l10n),
              retryLabel: l10n.tryAgain,
              onRetry: () => ref.invalidate(ohsSnapshotProvider),
            ),
            data: (snapshot) {
              if (snapshot.isEmpty) {
                return _OhsEmpty(
                  title: l10n.ohsEmptyTitle,
                  body: l10n.ohsEmptyBody,
                  ctaLabel: l10n.scan,
                  onCta: () => context.go(AppRoute.scan),
                );
              }
              return _OhsContent(snapshot: snapshot);
            },
          ),
        ),
      ),
    );
  }
}

// ─── Score banding ─────────────────────────────────────────────────────

/// Maps an OHS score (0..100) onto the brand semantic palette.
///
/// 80-100 → orange accent (`primary`)
/// 60-79  → muted accent (`primary` at lower opacity in surface context)
/// 40-59  → amber (`warning`)
/// 0-39   → rose  (`danger`)
@visibleForTesting
Color ohsColorForScore(int score) {
  if (score >= 80) return RadhaColors.primary;
  if (score >= 60) return RadhaColors.primary.withValues(alpha: 0.7);
  if (score >= 40) return RadhaColors.warning;
  return RadhaColors.danger;
}

// ─── Content ───────────────────────────────────────────────────────────

class _OhsContent extends StatelessWidget {
  const _OhsContent({required this.snapshot});

  final OhsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        RadhaSpacing.space24,
        RadhaSpacing.space16,
        RadhaSpacing.space24,
        RadhaSpacing.space32,
      ),
      children: [
        _Hero(snapshot: snapshot),
        const SizedBox(height: RadhaSpacing.space24),
        _BreakdownBento(snapshot: snapshot),
        const SizedBox(height: RadhaSpacing.space32),
        _SectionHeader(label: l10n.ohsActionItemsHeader),
        const SizedBox(height: RadhaSpacing.space12),
        _ActionItems(snapshot: snapshot),
        if (snapshot.trend.isNotEmpty) ...[
          const SizedBox(height: RadhaSpacing.space32),
          _SectionHeader(label: l10n.ohsTrendHeader),
          const SizedBox(height: RadhaSpacing.space12),
          _TrendBars(bars: snapshot.trend),
        ],
        const SizedBox(height: RadhaSpacing.space32),
        SizedBox(
          height: kMinTouchTarget,
          child: PrimaryButton(
            label: l10n.ohsViewDetailedReports,
            icon: Icons.assessment_outlined,
            expand: true,
            onPressed: () => context.push(AppRoute.reports),
          ),
        ),
      ],
    );
  }
}

// ─── Hero ──────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.snapshot});

  final OhsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final scoreColor = ohsColorForScore(snapshot.ohsScore);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ohsTitle,
          style: theme.textTheme.headlineLarge?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: RadhaSpacing.space16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(RadhaRadii.radiusXl),
            border: Border.all(color: scheme.outline),
          ),
          padding: const EdgeInsets.all(RadhaSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.ohsScoreCaption.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: RadhaSpacing.space8),
              Text(
                l10n.ohsScore(snapshot.ohsScore),
                style: radhaMonoStyle(
                  fontSize: 64,
                  weight: FontWeight.w700,
                  color: scoreColor,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: RadhaSpacing.space8),
              _DeltaPill(delta: snapshot.weekOverWeekDelta),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.delta});

  final int? delta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (delta == null) {
      return Text(
        l10n.ohsDeltaUnavailable,
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    }
    final value = delta!;
    final label = value > 0
        ? l10n.ohsDeltaUp(value)
        : value < 0
            ? l10n.ohsDeltaDown(-value)
            : l10n.ohsDeltaSame;
    final icon = value > 0
        ? Icons.trending_up_rounded
        : value < 0
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;
    final color = value > 0
        ? RadhaColors.primary
        : value < 0
            ? RadhaColors.danger
            : scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: RadhaSpacing.space4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Breakdown bento (asymmetric 2-column) ─────────────────────────────

class _BreakdownBento extends StatelessWidget {
  const _BreakdownBento({required this.snapshot});

  final OhsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compliance = _byCategory(snapshot.breakdown, 'compliance');
    final inventory = _byCategory(snapshot.breakdown, 'inventoryHygiene');
    final audit = _byCategory(snapshot.breakdown, 'auditCompletion');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tall card on the left — compliance is the dimension that
          // most deserves an at-a-glance read.
          Expanded(
            flex: 5,
            child: _BreakdownCard(
              icon: Icons.verified_outlined,
              label: l10n.ohsCompliance,
              score: compliance,
              tall: true,
            ),
          ),
          const SizedBox(width: RadhaSpacing.space12),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _BreakdownCard(
                    icon: Icons.inventory_2_outlined,
                    label: l10n.ohsInventoryHygiene,
                    score: inventory,
                  ),
                ),
                const SizedBox(height: RadhaSpacing.space12),
                Expanded(
                  child: _BreakdownCard(
                    icon: Icons.fact_check_outlined,
                    label: l10n.ohsAuditCompletion,
                    score: audit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static int _byCategory(List<OhsBreakdown> items, String category) {
    for (final b in items) {
      if (b.category == category) return b.score;
    }
    return 0;
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.icon,
    required this.label,
    required this.score,
    this.tall = false,
  });

  final IconData icon;
  final String label;
  final int score;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = ohsColorForScore(score);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.all(RadhaSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: RadhaSpacing.space12),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: RadhaSpacing.space4),
          Text(
            score.toString(),
            style: radhaMonoStyle(
              fontSize: tall ? 36 : 24,
              weight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: RadhaSpacing.space12),
          // Bar fill — clamped so a zero score is still painted as a
          // hairline indicator rather than disappearing.
          TweenAnimationBuilder<double>(
            duration: RadhaMotion.medium,
            curve: RadhaMotion.easeOut,
            tween: Tween<double>(begin: 0, end: (score.clamp(0, 100)) / 100),
            builder: (context, t, _) => ClipRRect(
              borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
              child: Container(
                height: 6,
                color: scheme.outline.withValues(alpha: 0.4),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: t.isNaN ? 0 : t.clamp(0.04, 1.0),
                  child: Container(color: color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action items ──────────────────────────────────────────────────────

class _ActionItems extends StatelessWidget {
  const _ActionItems({required this.snapshot});

  final OhsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <_ActionItemSpec>[
      if (snapshot.expiryAlertsActive > 0)
        _ActionItemSpec(
          icon: Icons.event_busy_outlined,
          label: l10n.ohsActionExpiry(snapshot.expiryAlertsActive),
          route: AppRoute.expiry,
          tone: _ActionTone.danger,
        ),
      if (snapshot.lowStockCount > 0)
        _ActionItemSpec(
          icon: Icons.inventory_outlined,
          label: l10n.ohsActionLowStock(snapshot.lowStockCount),
          route: AppRoute.inventoryLowStockAlerts,
          tone: _ActionTone.warning,
        ),
      _ActionItemSpec(
        icon: Icons.task_alt_outlined,
        label: l10n.ohsActionTasks,
        route: AppRoute.tasks,
        tone: _ActionTone.accent,
      ),
    ];
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(RadhaSpacing.space16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Text(
          l10n.ohsActionNoneBody,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _ActionItemRow(spec: items[i]),
          if (i != items.length - 1)
            const SizedBox(height: RadhaSpacing.space8),
        ],
      ],
    );
  }
}

enum _ActionTone { accent, warning, danger }

class _ActionItemSpec {
  const _ActionItemSpec({
    required this.icon,
    required this.label,
    required this.route,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String route;
  final _ActionTone tone;
}

class _ActionItemRow extends StatelessWidget {
  const _ActionItemRow({required this.spec});

  final _ActionItemSpec spec;

  Color _toneColor() {
    switch (spec.tone) {
      case _ActionTone.danger:
        return RadhaColors.danger;
      case _ActionTone.warning:
        return RadhaColors.warning;
      case _ActionTone.accent:
        return RadhaColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = _toneColor();

    return Material(
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
        side: BorderSide(color: scheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
        onTap: () => context.push(spec.route),
        child: Padding(
          padding: const EdgeInsets.all(RadhaSpacing.space16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
                ),
                child: Icon(spec.icon, size: 18, color: tone),
              ),
              const SizedBox(width: RadhaSpacing.space12),
              Expanded(
                child: Text(
                  spec.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: RadhaSpacing.space8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 7-bar mini trend ──────────────────────────────────────────────────

class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.bars});

  final List<OhsTrendBar> bars;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(RadhaSpacing.space16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
        border: Border.all(color: scheme.outline),
      ),
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: bars
              .map(
                (bar) => Expanded(
                  child: _TrendBar(bar: bar),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({required this.bar});

  final OhsTrendBar bar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = ohsColorForScore(bar.score);
    final dayLabel = _formatDay(bar.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: TweenAnimationBuilder<double>(
                duration: RadhaMotion.medium,
                curve: RadhaMotion.easeOut,
                tween: Tween<double>(
                  begin: 0,
                  end: bar.score.clamp(0, 100) / 100,
                ),
                builder: (context, t, _) => FractionallySizedBox(
                  heightFactor: t.isNaN ? 0.04 : t.clamp(0.04, 1.0),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(RadhaRadii.radiusSm),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: RadhaSpacing.space8),
          Text(
            dayLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDay(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return DateFormat('E').format(parsed);
  }
}

// ─── Section header ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─── Loading / empty / error ───────────────────────────────────────────

class _OhsSkeleton extends StatelessWidget {
  const _OhsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        RadhaSpacing.space24,
        RadhaSpacing.space16,
        RadhaSpacing.space24,
        RadhaSpacing.space32,
      ),
      children: const [
        SkeletonLoader(width: 240, height: 32),
        SizedBox(height: RadhaSpacing.space16),
        SkeletonLoader(height: 140, radius: RadhaRadii.radiusXl),
        SizedBox(height: RadhaSpacing.space24),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: SkeletonLoader(height: 168, radius: RadhaRadii.radiusLg),
            ),
            SizedBox(width: RadhaSpacing.space12),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  SkeletonLoader(height: 78, radius: RadhaRadii.radiusLg),
                  SizedBox(height: RadhaSpacing.space12),
                  SkeletonLoader(height: 78, radius: RadhaRadii.radiusLg),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: RadhaSpacing.space32),
        SkeletonLoader(width: 160, height: 16),
        SizedBox(height: RadhaSpacing.space12),
        SkeletonLoader(height: 64, radius: RadhaRadii.radiusLg),
        SizedBox(height: RadhaSpacing.space8),
        SkeletonLoader(height: 64, radius: RadhaRadii.radiusLg),
        SizedBox(height: RadhaSpacing.space32),
        SkeletonLoader(height: 140, radius: RadhaRadii.radiusLg),
      ],
    );
  }
}

class _OhsEmpty extends StatelessWidget {
  const _OhsEmpty({
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
  });

  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(RadhaSpacing.space24),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MorCompanion(mood: MorMood.greet, size: 104),
              const SizedBox(height: RadhaSpacing.space24),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: RadhaSpacing.space8),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: RadhaSpacing.space24),
              SizedBox(
                height: kMinTouchTarget,
                child: PrimaryButton(
                  label: ctaLabel,
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: onCta,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OhsError extends StatelessWidget {
  const _OhsError({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(RadhaSpacing.space24),
      children: [
        const MorCompanion(
          mood: MorMood.concern,
          size: 96,
          semanticLabel: 'Could not load',
        ),
        const SizedBox(height: RadhaSpacing.space16),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: RadhaSpacing.space8),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: RadhaSpacing.space24),
        SizedBox(
          height: kMinTouchTarget,
          child: SecondaryButton(
            label: retryLabel,
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ),
      ],
    );
  }
}

String _errorMessage(Object error, AppLocalizations l10n) {
  if (error is ApiException) {
    return userMessageForCode(
      error.code,
      l10n: l10n,
      retryAfterSeconds: error is RateLimitException ? error.retryAfter : null,
      fallback: error.message,
    );
  }
  return l10n.errorGeneric;
}
