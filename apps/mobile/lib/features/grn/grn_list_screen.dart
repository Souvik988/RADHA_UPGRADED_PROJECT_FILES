import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/network/dto/grn_dto.dart';
import '../../core/router/app_router.dart';
import '../../design/app_assets.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets/empty_state.dart';
import '../../design/widgets/mor_companion.dart';

/// Provider that fetches GRNs from the backend.
final _grnsProvider = FutureProvider.autoDispose<PaginatedGrns>((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getGrns();
});

/// GRN list — status filter tabs (Draft / Pending review / Posted), polished
/// supplier cards with status pills, invoice meta, and a mono rupee total.
class GrnListScreen extends ConsumerStatefulWidget {
  const GrnListScreen({super.key});

  @override
  ConsumerState<GrnListScreen> createState() => _GrnListScreenState();
}

class _GrnListScreenState extends ConsumerState<GrnListScreen> {
  String? _statusFilter;

  static const _filters = <(String?, String)>[
    (null, 'All'),
    ('draft', 'Draft'),
    ('pending_review', 'Pending Review'),
    ('posted', 'Posted'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grnsAsync = ref.watch(_grnsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Goods received',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          _StatusTabs(
            filters: _filters,
            selected: _statusFilter,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _statusFilter = value);
            },
          ),
          Expanded(
            child: grnsAsync.when(
              loading: () => const _GrnSkeleton(),
              error: (err, _) => _GrnError(
                onRetry: () => ref.invalidate(_grnsProvider),
              ),
              data: (paginated) {
                var items = [...paginated.items];
                if (_statusFilter != null) {
                  items = items
                      .where((g) => g.status == _statusFilter)
                      .toList();
                }
                items.sort((a, b) {
                  final aDate = a.invoiceDate ?? a.createdAt ?? '';
                  final bDate = b.invoiceDate ?? b.createdAt ?? '';
                  return bDate.compareTo(aDate);
                });

                if (items.isEmpty) {
                  return RefreshIndicator(
                    color: RadhaColors.primary,
                    onRefresh: () async => ref.invalidate(_grnsProvider),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.14,
                        ),
                        Center(
                          child: EmptyState(
                            illustration: const MorCompanion(
                              mood: MorMood.greet,
                              size: 104,
                            ),
                            title: 'No GRNs here',
                            body: 'Create a goods-received note to log a '
                                'supplier delivery.',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: RadhaColors.primary,
                  onRefresh: () async => ref.invalidate(_grnsProvider),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      RadhaSpacing.space20,
                      RadhaSpacing.space12,
                      RadhaSpacing.space20,
                      RadhaSpacing.space32 + 72,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: RadhaSpacing.space12),
                    itemBuilder: (context, index) =>
                        _GrnTile(grn: items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'grn_fab',
        backgroundColor: RadhaColors.primary,
        foregroundColor: RadhaColors.onPrimary,
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push(AppRoute.grnCreate);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New GRN'),
      ),
    );
  }
}

/// Underline status tabs.
class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.filters,
    required this.selected,
    required this.onChanged,
  });

  final List<(String?, String)> filters;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: RadhaSpacing.space12),
        child: Row(
          children: filters.map((f) {
            final active = selected == f.$1;
            return GestureDetector(
              onTap: () => onChanged(f.$1),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: RadhaSpacing.space12,
                  vertical: RadhaSpacing.space12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f.$2,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: active
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: active
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: RadhaSpacing.space8),
                    AnimatedContainer(
                      duration: RadhaMotion.fast,
                      curve: RadhaMotion.easeOut,
                      height: 2.5,
                      width: active ? 20 : 0,
                      decoration: BoxDecoration(
                        color: RadhaColors.primary,
                        borderRadius: BorderRadius.circular(
                          RadhaRadii.radiusFull,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Single GRN card.
class _GrnTile extends StatefulWidget {
  const _GrnTile({required this.grn});

  final GrnResponse grn;

  @override
  State<_GrnTile> createState() => _GrnTileState();
}

class _GrnTileState extends State<_GrnTile> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grn = widget.grn;

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/grn/${grn.id}/items');
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: RadhaMotion.fast,
        curve: RadhaMotion.spring,
        child: Container(
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
                  Expanded(
                    child: Text(
                      grn.supplierName ?? 'Supplier',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: RadhaSpacing.space8),
                  _StatusPill(status: grn.status),
                ],
              ),
              const SizedBox(height: RadhaSpacing.space8),
              Text(
                [
                  if (grn.invoiceNumber != null) grn.invoiceNumber,
                  if (grn.invoiceDate != null) _formatDate(grn.invoiceDate!),
                ].whereType<String>().join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: RadhaSpacing.space12),
              Row(
                children: [
                  Text(
                    '${grn.totalItems ?? 0} items',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\u20B9 ${_formatValue(grn.totalValue)}',
                    style: radhaMonoStyle(
                      fontSize: 15,
                      weight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: RadhaSpacing.space8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatValue(double? v) {
    if (v == null) return '0';
    // Indian grouping is nice-to-have; keep a clean integer with thousands.
    final whole = v.round();
    final s = whole.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return iso;
    }
  }
}

/// Status pill.
class _StatusPill extends StatelessWidget {
  const _StatusPill({this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();
    final color = _statusColor(status!);
    final label = _statusLabel(status!);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RadhaSpacing.space8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'draft':
      return RadhaColors.inkMuted;
    case 'pending_review':
      return RadhaColors.warning;
    case 'posted':
      return RadhaColors.success;
    default:
      return RadhaColors.inkMuted;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'draft':
      return 'Draft';
    case 'pending_review':
      return 'Pending';
    case 'posted':
      return 'Posted';
    default:
      return status;
  }
}

// ─── Loading / empty / error ─────────────────────────────────────────────────

class _GrnSkeleton extends StatelessWidget {
  const _GrnSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        RadhaSpacing.space20,
        RadhaSpacing.space12,
        RadhaSpacing.space20,
        RadhaSpacing.space32,
      ),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: RadhaSpacing.space12),
      itemBuilder: (_, _) => Container(
        height: 104,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
          border: Border.all(color: theme.colorScheme.outline),
        ),
      ),
    );
  }
}

// _EmptyIllustration removed — empty states now use MorCompanion.

class _GrnError extends StatelessWidget {
  const _GrnError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
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
            Text('Failed to load GRNs', style: theme.textTheme.bodyMedium),
            const SizedBox(height: RadhaSpacing.space16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
