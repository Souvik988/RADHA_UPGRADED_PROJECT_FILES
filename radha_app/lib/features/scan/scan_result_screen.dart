import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/network/api_client.dart';
import '../../core/network/dto/ean_dto.dart';
import '../../core/network/dto/product_dto.dart';
import '../../core/router/app_router.dart';
import '../../design/app_assets.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets/mor_celebration.dart';
import '../../design/widgets/mor_companion.dart';
import '../../design/widgets/primary_button.dart';
import '../../l10n/generated/app_localizations.dart';

/// FutureProvider that fetches a product by EAN. Auto-disposed so cache
/// doesn't grow unbounded across many scan results.
final _productByEanProvider = FutureProvider.autoDispose
    .family<ProductResponse, String>((ref, ean) async {
      final client = ref.read(apiClientProvider);
      return client.getProductByEan(ean);
    });

/// Composite key for the approved-EAN check — an EAN scoped to a store.
@immutable
class _EanCheckArgs {
  const _EanCheckArgs({required this.ean, required this.storeId});

  final String ean;
  final String storeId;

  @override
  bool operator ==(Object other) =>
      other is _EanCheckArgs && other.ean == ean && other.storeId == storeId;

  @override
  int get hashCode => Object.hash(ean, storeId);
}

/// Validates an EAN against the store's approved list. Auto-disposed and
/// keyed by (ean, storeId) so each scan result resolves independently.
final _approvedEanProvider = FutureProvider.autoDispose
    .family<EanValidationResult, _EanCheckArgs>((ref, args) async {
      final client = ref.read(apiClientProvider);
      return client.validateEan(
        ValidateEanDto(ean: args.ean, storeId: args.storeId),
      );
    });

/// Full-screen product result after scanning a barcode — the health card.
///
/// Layout mirrors the mockup: product header, approved-EAN pill, an animated
/// circular health-score gauge with nutrition badges, an allergen note, and a
/// pinned bottom action bar (Add to expiry primary + Stock / Save outline).
///
/// Health data note: the V1 `GET /products/lookup/{ean}` returns catalog
/// fields only (no per-product health score). The gauge + badges render in a
/// clearly-labelled "assessment pending" state rather than fabricating values;
/// the widgets accept real data unchanged once the health endpoint is wired.
class ScanResultScreen extends ConsumerWidget {
  const ScanResultScreen({super.key, required this.ean});

  final String ean;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(_productByEanProvider(ean));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          AppLocalizations.of(context).scanResultTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: AppLocalizations.of(context).commonShare,
            onPressed: () => Share.share(
              AppLocalizations.of(context).scanResultShareMessage(ean),
            ),
          ),
        ],
      ),
      body: productAsync.when(
        loading: () => const _SkeletonBody(),
        error: (error, _) => _ErrorBody(ean: ean, error: error),
        data: (product) => _ProductBody(product: product, ean: ean),
      ),
    );
  }
}

// ─── Body ────────────────────────────────────────────────────────────────────

/// Renders the product result and fires a one-shot "scan-success" celebration
/// (Mor celebrate + marigold petal burst) the first time the store's approved
/// EAN check resolves to a match. The beat is brand-affirming feedback — the
/// daily dopamine of a clean audit scan (Character Bible §6/§8). It never
/// blocks interaction and auto-dismisses; in reduced-motion it is suppressed
/// (the approval pill + text already convey the state).
class _ProductBody extends ConsumerStatefulWidget {
  const _ProductBody({required this.product, required this.ean});

  final ProductResponse product;
  final String ean;

  @override
  ConsumerState<_ProductBody> createState() => _ProductBodyState();
}

class _ProductBodyState extends ConsumerState<_ProductBody> {
  bool _celebrated = false;
  bool _showBurst = false;

  @override
  Widget build(BuildContext context) {
    final storeId = ref.watch(currentUserProvider)?.selectedStoreId;

    // Only an in-audit scan (store selected) has an approved list to match
    // against, so only then can a "matched" success beat fire.
    if (storeId != null) {
      ref.listen<AsyncValue<EanValidationResult>>(
        _approvedEanProvider(_EanCheckArgs(ean: widget.ean, storeId: storeId)),
        (prev, next) {
          final matched = next.asData?.value.matched ?? false;
          if (matched && !_celebrated && mounted) {
            _celebrated = true;
            HapticFeedback.mediumImpact();
            setState(() => _showBurst = true);
          }
        },
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  RadhaSpacing.space20,
                  RadhaSpacing.space8,
                  RadhaSpacing.space20,
                  RadhaSpacing.space24,
                ),
                children: [
                  _ProductHeader(product: widget.product, ean: widget.ean),
                  const SizedBox(height: RadhaSpacing.space16),
                  _ApprovedEanPill(ean: widget.ean),
                  const SizedBox(height: RadhaSpacing.space24),
                  const _HealthSection(),
                  const SizedBox(height: RadhaSpacing.space16),
                  _ExplainIngredientsButton(productId: widget.product.id),
                  const SizedBox(height: RadhaSpacing.space16),
                  const _AllergenNote(),
                ],
              ),
            ),
            _ActionBar(ean: widget.ean),
          ],
        ),
        if (_showBurst)
          // Non-interactive overlay so taps still reach the content beneath.
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: const Alignment(0, -0.45),
                child: MorCelebration(
                  size: 132,
                  onComplete: () {
                    if (mounted) setState(() => _showBurst = false);
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Product header ──────────────────────────────────────────────────────────

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product, required this.ean});

  final ProductResponse product;
  final String ean;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductThumb(imageUrl: product.imageUrl),
        const SizedBox(width: RadhaSpacing.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              if (product.brand != null || product.category != null) ...[
                const SizedBox(height: RadhaSpacing.space4),
                Row(
                  children: [
                    if (product.brand != null)
                      Flexible(
                        child: Text(
                          product.brand!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (product.brand != null && product.category != null)
                      Text(
                        ' · ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (product.category != null)
                      Flexible(
                        child: Text(
                          product.category!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: RadhaSpacing.space8),
              Text(
                'EAN: $ean',
                style: radhaMonoStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Icon(
      Icons.inventory_2_outlined,
      size: 32,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: imageUrl == null
          ? placeholder
          : CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              width: 72,
              height: 72,
              errorWidget: (_, _, _) => placeholder,
              placeholder: (_, _) => placeholder,
            ),
    );
  }
}

// ─── Approved EAN pill ───────────────────────────────────────────────────────

/// Resolves and renders the approved-list verification state for [ean].
///
/// Outside an audit (no selected store) consumers have no approved list, so we
/// keep the neutral "not in an audit" copy. With a store selected we call
/// `POST /ean-lists/validate` and render a green (approved), red (not in list /
/// invalid), or warning (no active list) pill — falling back to a neutral
/// "couldn't check" pill on error.
class _ApprovedEanPill extends ConsumerWidget {
  const _ApprovedEanPill({required this.ean});

  final String ean;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeId = ref.watch(currentUserProvider)?.selectedStoreId;

    final l10n = AppLocalizations.of(context);

    // No store ⇒ consumer context, nothing to verify against.
    if (storeId == null) {
      return _PillFrame(
        icon: Icons.verified_outlined,
        label: l10n.scanApprovalNotInAudit,
        tone: _PillTone.neutral,
      );
    }

    final result = ref.watch(
      _approvedEanProvider(_EanCheckArgs(ean: ean, storeId: storeId)),
    );

    return result.when(
      loading: () => _PillFrame(
        icon: null,
        label: l10n.scanApprovalChecking,
        tone: _PillTone.neutral,
        showSpinner: true,
      ),
      error: (_, _) => _PillFrame(
        icon: Icons.help_outline_rounded,
        label: l10n.scanApprovalCheckFailed,
        tone: _PillTone.neutral,
      ),
      data: (validation) {
        if (validation.matched) {
          return _PillFrame(
            icon: Icons.check_circle_rounded,
            label: l10n.scanApprovalApproved,
            tone: _PillTone.success,
          );
        }
        switch (validation.reason) {
          case 'no_active_list':
            return _PillFrame(
              icon: Icons.info_outline_rounded,
              label: l10n.scanApprovalNoList,
              tone: _PillTone.warning,
            );
          case 'invalid_format':
            return _PillFrame(
              icon: Icons.cancel_rounded,
              label: l10n.scanApprovalInvalidBarcode,
              tone: _PillTone.danger,
            );
          default:
            return _PillFrame(
              icon: Icons.cancel_rounded,
              label: l10n.scanApprovalNotInList,
              tone: _PillTone.danger,
            );
        }
      },
    );
  }
}

enum _PillTone { neutral, success, warning, danger }

/// Shared pill chrome for the approval status. Honors the design radii and
/// keeps a `Semantics` label so the status is announced to screen readers.
class _PillFrame extends StatelessWidget {
  const _PillFrame({
    required this.icon,
    required this.label,
    required this.tone,
    this.showSpinner = false,
  });

  final IconData? icon;
  final String label;
  final _PillTone tone;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color accent = switch (tone) {
      _PillTone.success => RadhaColors.success,
      _PillTone.warning => RadhaColors.warning,
      _PillTone.danger => RadhaColors.danger,
      _PillTone.neutral => theme.colorScheme.onSurfaceVariant,
    };
    final bool tinted = tone != _PillTone.neutral;
    final Color background = tinted
        ? accent.withValues(alpha: 0.08)
        : theme.colorScheme.surfaceContainer;
    final Color border = tinted
        ? accent.withValues(alpha: 0.35)
        : theme.colorScheme.outline;
    final Color foreground = tinted ? accent : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      label: AppLocalizations.of(context).scanApprovalStatus(label),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RadhaSpacing.space12,
            vertical: RadhaSpacing.space8,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSpinner)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 16, color: foreground),
              const SizedBox(width: RadhaSpacing.space8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Health section ──────────────────────────────────────────────────────────

class _HealthSection extends StatelessWidget {
  const _HealthSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(RadhaSpacing.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.scanResultHealthHeading,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Assessment-pending chip — honest about V1 data availability.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RadhaSpacing.space12,
                  vertical: RadhaSpacing.space4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
                ),
                child: Text(
                  l10n.scanResultAssessmentPending,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RadhaSpacing.space16),
          Row(
            children: [
              const _ScoreGauge(score: null),
              const SizedBox(width: RadhaSpacing.space20),
              Expanded(
                child: Text(
                  l10n.scanResultNutritionPending,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RadhaSpacing.space16),
          Wrap(
            spacing: RadhaSpacing.space8,
            runSpacing: RadhaSpacing.space8,
            children: [
              _HealthChip(
                label: AppLocalizations.of(context).healthSugar,
                icon: Icons.water_drop_outlined,
                level: _HealthLevel.unknown,
              ),
              _HealthChip(
                label: AppLocalizations.of(context).healthSalt,
                icon: Icons.grain,
                level: _HealthLevel.unknown,
              ),
              _HealthChip(
                label: AppLocalizations.of(context).healthFat,
                icon: Icons.opacity,
                level: _HealthLevel.unknown,
              ),
              _HealthChip(
                label: AppLocalizations.of(context).healthProcessed,
                icon: Icons.factory_outlined,
                level: _HealthLevel.unknown,
              ),
              _HealthChip(
                label: AppLocalizations.of(context).healthChildSuitable,
                icon: Icons.child_friendly,
                level: _HealthLevel.unknown,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Animated circular health-score gauge. Sweeps the arc from 0 to [score]
/// (0..100) on entry; renders a neutral dashed ring + "–" when [score] is
/// null (assessment pending). Honors reduce-motion.
class _ScoreGauge extends StatefulWidget {
  const _ScoreGauge({required this.score});

  /// 0..100, or null when no assessment is available.
  final int? score;

  @override
  State<_ScoreGauge> createState() => _ScoreGaugeState();
}

class _ScoreGaugeState extends State<_ScoreGauge>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  late Animation<double> _anim;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.score == null || _ctrl != null) return;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ctrl = ctrl;
    _anim = Tween<double>(begin: 0, end: widget.score! / 100).animate(
      CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic),
    );
    if (reduceMotion) {
      ctrl.value = 1.0;
    } else {
      ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 72.0;
    if (widget.score == null) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _GaugePainter(
            progress: 0,
            track: theme.colorScheme.outline,
            fill: RadhaColors.primary,
          ),
          child: Center(
            child: Text(
              '–',
              style: radhaMonoStyle(
                fontSize: 22,
                weight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final shown = (_anim.value * 100).round();
          return CustomPaint(
            painter: _GaugePainter(
              progress: _anim.value,
              track: theme.colorScheme.outline,
              fill: RadhaColors.primary,
            ),
            child: Center(
              child: Text(
                '$shown',
                style: radhaMonoStyle(
                  fontSize: 22,
                  weight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Full track ring.
    canvas.drawCircle(center, radius, trackPaint);
    // Progress arc from top, clockwise.
    const start = -math.pi / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      2 * math.pi * progress,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress || old.fill != fill || old.track != track;
}

enum _HealthLevel { good, moderate, bad, unknown }

class _HealthChip extends StatelessWidget {
  const _HealthChip({
    required this.label,
    required this.icon,
    required this.level,
  });

  final String label;
  final IconData icon;
  final _HealthLevel level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color = switch (level) {
      _HealthLevel.good => RadhaColors.success,
      _HealthLevel.moderate => RadhaColors.warning,
      _HealthLevel.bad => RadhaColors.danger,
      _HealthLevel.unknown => theme.colorScheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RadhaSpacing.space12,
        vertical: RadhaSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: RadhaSpacing.space8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Explain ingredients (AI) ────────────────────────────────────────────────

class _ExplainIngredientsButton extends StatelessWidget {
  const _ExplainIngredientsButton({required this.productId});

  final String productId;

  /// Kebab-case slug derived from the product id for the `/ingredients/:slug`
  /// route. The backend normalises again server-side.
  String get _slug {
    final s = productId
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return s.isEmpty ? 'ingredient' : s;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/ingredients/$_slug');
        },
        borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(RadhaSpacing.space16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: RadhaColors.primary,
              ),
              const SizedBox(width: RadhaSpacing.space12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).scanResultExplainIngredients,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Allergen note ───────────────────────────────────────────────────────────

class _AllergenNote extends StatelessWidget {
  const _AllergenNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(RadhaSpacing.space16),
      decoration: BoxDecoration(
        color: RadhaColors.primaryTint.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: RadhaColors.warning,
          ),
          const SizedBox(width: RadhaSpacing.space12),
          Expanded(
            child: Text(
              AppLocalizations.of(context).scanResultAllergenPrompt,
              style: theme.textTheme.bodySmall?.copyWith(
                color: RadhaColors.ink,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom action bar ───────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.ean});

  final String ean;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        RadhaSpacing.space20,
        RadhaSpacing.space12,
        RadhaSpacing.space20,
        RadhaSpacing.space12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: AppLocalizations.of(context).scanResultAddToExpiry,
              icon: Icons.event_available_outlined,
              expand: true,
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(AppRoute.expiryNew);
              },
            ),
          ),
          const SizedBox(width: RadhaSpacing.space12),
          _OutlineIconButton(
            icon: Icons.add_box_outlined,
            tooltip: AppLocalizations.of(context).scanResultAddToStock,
            onTap: () => context.push(AppRoute.inventoryStockMovement),
          ),
          const SizedBox(width: RadhaSpacing.space12),
          _OutlineIconButton(
            icon: Icons.bookmark_add_outlined,
            tooltip: AppLocalizations.of(context).scanResultSaveToList,
            onTap: () => context.push(AppRoute.shoppingList),
          ),
        ],
      ),
    );
  }
}

class _OutlineIconButton extends StatelessWidget {
  const _OutlineIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
          child: Container(
            width: kMinTouchTarget + 4,
            height: kMinTouchTarget + 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Icon(icon, color: theme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton ────────────────────────────────────────────────────────────────

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget box(double h, double w) => Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusSm),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(RadhaSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              box(72, 72),
              const SizedBox(width: RadhaSpacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(20, double.infinity),
                    const SizedBox(height: RadhaSpacing.space8),
                    box(14, 140),
                    const SizedBox(height: RadhaSpacing.space8),
                    box(12, 100),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: RadhaSpacing.space24),
          box(120, double.infinity),
          const SizedBox(height: RadhaSpacing.space16),
          box(56, double.infinity),
        ],
      ),
    );
  }
}

// ─── Error ───────────────────────────────────────────────────────────────────

enum _ScanErrorKind { notFound, unauthorized, offline, timeout, serverError }

_ScanErrorKind _classifyError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) return _ScanErrorKind.unauthorized;
    if (status == 404) return _ScanErrorKind.notFound;
    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException) {
      return _ScanErrorKind.offline;
    }
    if (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionTimeout) {
      return _ScanErrorKind.timeout;
    }
    return _ScanErrorKind.serverError;
  }
  return _ScanErrorKind.serverError;
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.ean, required this.error});

  final String ean;
  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final kind = _classifyError(error);

    final (title, body, showLabelScanCta) = switch (kind) {
      _ScanErrorKind.notFound => (
        l10n.productNotFound,
        l10n.scanResultNotFoundBody(ean),
        true,
      ),
      _ScanErrorKind.unauthorized => (
        'Not authorised',
        'Your session may have expired. Please sign out and sign back in.',
        false,
      ),
      _ScanErrorKind.offline => (
        'You\'re offline',
        'Check your internet connection and try scanning again.',
        false,
      ),
      _ScanErrorKind.timeout => (
        'Request timed out',
        'The server took too long to respond. Try again in a moment.',
        false,
      ),
      _ScanErrorKind.serverError => (
        'Something went wrong',
        'We couldn\'t fetch this product right now. Try again.',
        false,
      ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RadhaSpacing.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MorCompanion(
              mood: kind == _ScanErrorKind.offline
                  ? MorMood.concern
                  : MorMood.concern,
              size: 108,
              semanticLabel: l10n.scanResultNoProduct,
            ),
            const SizedBox(height: RadhaSpacing.space16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: RadhaSpacing.space8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RadhaSpacing.space24),
            if (showLabelScanCta)
              PrimaryButton(
                label: l10n.scanResultScanLabel,
                icon: Icons.document_scanner_outlined,
                expand: true,
                onPressed: () => context.pushReplacement(AppRoute.labelScan),
              ),
            if (showLabelScanCta) const SizedBox(height: RadhaSpacing.space12),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(l10n.scanAgain),
            ),
          ],
        ),
      ),
    );
  }
}
