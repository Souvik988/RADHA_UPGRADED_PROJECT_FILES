import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/network/api_client.dart';
import '../../core/network/dto/expiry_dto.dart';
import '../../core/router/app_router.dart';
import '../../design/app_assets.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets/empty_state.dart';
import '../../design/widgets/mor_companion.dart';
import '../../l10n/generated/app_localizations.dart';

/// Status filter tabs for the expiry list.
enum _ExpiryTab { nearExpiry, expired, safe }

extension on _ExpiryTab {
  String get status => switch (this) {
    _ExpiryTab.nearExpiry => 'near_expiry',
    _ExpiryTab.expired => 'expired',
    _ExpiryTab.safe => 'safe',
  };

  String get apiStatus => switch (this) {
    _ExpiryTab.nearExpiry => 'yellow,red',
    _ExpiryTab.expired => 'expired',
    _ExpiryTab.safe => 'green',
  };
}

@immutable
class _ExpiryQueryArgs {
  const _ExpiryQueryArgs({
    required this.storeId,
    required this.uiStatus,
    required this.apiStatus,
  });

  final String storeId;
  final String uiStatus;
  final String apiStatus;

  @override
  bool operator ==(Object other) =>
      other is _ExpiryQueryArgs &&
      other.storeId == storeId &&
      other.uiStatus == uiStatus &&
      other.apiStatus == apiStatus;

  @override
  int get hashCode => Object.hash(storeId, uiStatus, apiStatus);
}

/// First-page provider per status. Pagination beyond page one is handled in
/// local state inside [_ExpiryTabContent]; this provider owns the initial
/// fetch + pull-to-refresh invalidation.
final _expiryFirstPageProvider = FutureProvider.autoDispose
    .family<PaginatedExpiries, _ExpiryQueryArgs>((ref, args) async {
      final client = ref.watch(apiClientProvider);
      return client.getExpiries(
        status: args.apiStatus,
        storeId: args.storeId,
        limit: 20,
      );
    });

/// Expiry list screen — a segmented Near-expiry / Expired / Safe view, each
/// cursor-paginated and sorted by expiry date. Pull-to-refresh + infinite
/// scroll, status-coloured day-count pills, and a FAB to add a record.
class ExpiryListScreen extends ConsumerStatefulWidget {
  const ExpiryListScreen({super.key});

  @override
  ConsumerState<ExpiryListScreen> createState() => _ExpiryListScreenState();
}

class _ExpiryListScreenState extends ConsumerState<ExpiryListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _index = 0;

  static const _tabs = [
    _ExpiryTab.nearExpiry,
    _ExpiryTab.expired,
    _ExpiryTab.safe,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _index) {
        setState(() => _index = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final session = auth.valueOrNull;
    final selectedStoreId = session?.selectedStoreId;
    final hasSelectableStores = session?.stores.isNotEmpty ?? false;

    final body = auth.isLoading
        ? const _ExpiryListSkeleton()
        : selectedStoreId == null
        ? _ExpiryNeedsStore(canSelectStore: hasSelectableStores)
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  RadhaSpacing.space20,
                  RadhaSpacing.space8,
                  RadhaSpacing.space20,
                  RadhaSpacing.space12,
                ),
                child: _SegmentedTabs(
                  labels: _tabs.map((t) => _tabLabel(l10n, t)).toList(),
                  index: _index,
                  onChanged: (i) {
                    HapticFeedback.selectionClick();
                    _tabController.animateTo(i);
                  },
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs
                      .map(
                        (t) => _ExpiryTabContent(
                          query: _ExpiryQueryArgs(
                            storeId: selectedStoreId,
                            uiStatus: t.status,
                            apiStatus: t.apiStatus,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          l10n.expiryTracker,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (selectedStoreId != null)
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: l10n.expiryCalendarTooltip,
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push(AppRoute.expiryCalendar);
              },
            ),
        ],
      ),
      body: body,
      floatingActionButton: selectedStoreId == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'expiry_fab',
              backgroundColor: RadhaColors.primary,
              foregroundColor: RadhaColors.onPrimary,
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(AppRoute.expiryNew);
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.add),
            ),
    );
  }

  String _tabLabel(AppLocalizations l10n, _ExpiryTab tab) => switch (tab) {
    _ExpiryTab.nearExpiry => l10n.expiryTabNear,
    _ExpiryTab.expired => l10n.expired,
    _ExpiryTab.safe => l10n.expiryTabSafe,
  };
}

class _ExpiryNeedsStore extends StatelessWidget {
  const _ExpiryNeedsStore({required this.canSelectStore});

  final bool canSelectStore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RadhaSpacing.space16),
        child: EmptyState(
          illustration: const MorCompanion(mood: MorMood.concern, size: 104),
          title: l10n.selectStoreEmptyTitle,
          body: l10n.selectStoreEmptyBody,
          actionLabel: canSelectStore
              ? l10n.selectStoreTitle
              : l10n.selectStoreContactManager,
          actionIcon: canSelectStore
              ? Icons.storefront_outlined
              : Icons.support_agent_outlined,
          onAction: () {
            HapticFeedback.selectionClick();
            if (canSelectStore) {
              context.push(AppRoute.selectStore);
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.selectStoreContactManagerSnackbar)),
            );
          },
        ),
      ),
    );
  }
}

/// Pill-style segmented control matching the mockup. Animated thumb.
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: RadhaMotion.fast,
                  curve: RadhaMotion.easeOut,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index
                        ? theme.colorScheme.surfaceContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(RadhaRadii.radiusSm),
                    border: i == index
                        ? Border.all(color: theme.colorScheme.outline)
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: i == index
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: i == index
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Content of a single tab — first page from the provider, further pages from
/// local state. Self-contained so each status keeps its own scroll + cursor.
class _ExpiryTabContent extends ConsumerStatefulWidget {
  const _ExpiryTabContent({required this.query});

  final _ExpiryQueryArgs query;

  @override
  ConsumerState<_ExpiryTabContent> createState() => _ExpiryTabContentState();
}

class _ExpiryTabContentState extends ConsumerState<_ExpiryTabContent>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final List<ExpiryResponse> _more = [];
  String? _cursor;
  bool _initialised = false;
  bool _loadingMore = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _ExpiryTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _more.clear();
      _cursor = null;
      _initialised = false;
      _loadingMore = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || _cursor == null) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final client = ref.read(apiClientProvider);
      final page = await client.getExpiries(
        cursor: _cursor,
        limit: 20,
        status: widget.query.apiStatus,
        storeId: widget.query.storeId,
      );
      if (!mounted) return;
      setState(() {
        _more.addAll(page.items);
        _cursor = page.cursor;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _more.clear();
      _cursor = null;
      _initialised = false;
    });
    ref.invalidate(_expiryFirstPageProvider(widget.query));
    await ref.read(_expiryFirstPageProvider(widget.query).future);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final asyncValue = ref.watch(_expiryFirstPageProvider(widget.query));
    final uiStatus = widget.query.uiStatus;

    return asyncValue.when(
      loading: () => const _ExpiryListSkeleton(),
      error: (err, _) => _ExpiryError(onRetry: _refresh),
      data: (page) {
        // Capture the first page + its cursor once per (re)load.
        if (!_initialised) {
          _initialised = true;
          _cursor = page.cursor;
        }
        final items = <ExpiryResponse>[...page.items, ..._more];

        if (items.isEmpty) {
          return RefreshIndicator(
            color: RadhaColors.primary,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.14),
                Center(
                  child: EmptyState(
                    illustration: MorCompanion(
                      mood: _emptyMood(uiStatus),
                      size: 104,
                    ),
                    title: _emptyTitle(l10n, uiStatus),
                    body: _emptyMessage(l10n, uiStatus),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: RadhaColors.primary,
          onRefresh: _refresh,
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              RadhaSpacing.space20,
              RadhaSpacing.space4,
              RadhaSpacing.space20,
              RadhaSpacing.space32 + 72, // room for the FAB
            ),
            itemCount: items.length + (_loadingMore ? 1 : 0),
            separatorBuilder: (_, _) =>
                const SizedBox(height: RadhaSpacing.space8),
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: RadhaSpacing.space16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return _ExpiryListTile(item: items[index]);
            },
          ),
        );
      },
    );
  }

  MorMood _emptyMood(String status) => switch (status) {
    'expired' => MorMood.celebrate,
    'near_expiry' => MorMood.guard,
    _ => MorMood.greet,
  };

  String _emptyTitle(AppLocalizations l10n, String status) => switch (status) {
    'expired' => l10n.expiryEmptyExpiredTitle,
    'near_expiry' => l10n.expiryEmptyNearTitle,
    _ => l10n.expiryEmptyDefaultTitle,
  };

  String _emptyMessage(AppLocalizations l10n, String status) =>
      l10n.expiryEmptyBody;
}

/// A single expiry record tile — thumbnail, name/batch, and a day-count
/// status pill on the right.
class _ExpiryListTile extends StatelessWidget {
  const _ExpiryListTile({required this.item});

  final ExpiryResponse item;

  /// Days from today until the expiry date. Negative ⇒ already expired.
  int? get _daysLeft {
    final d = DateTime.tryParse(item.expiryDate);
    if (d == null) return null;
    final today = DateTime.now();
    final dateOnly = DateTime(d.year, d.month, d.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    return dateOnly.difference(todayOnly).inDays;
  }

  String _shortProduct(AppLocalizations l10n) {
    // The list endpoint returns productId only; show a stable short token
    // rather than a raw uuid until the product-name join lands server-side.
    final id = item.productId;
    final token = id.length <= 8 ? id : id.substring(0, 8);
    return l10n.expiryProductShort(token);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final days = _daysLeft;
    final (pillColor, pillBg, pillText) = _pill(theme, days, item.status, l10n);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      padding: const EdgeInsets.all(RadhaSpacing.space16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(RadhaRadii.radiusSm),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.inventory_2_outlined,
              size: 22,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: RadhaSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shortProduct(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: RadhaSpacing.space2),
                Text(
                  [
                    if (item.batchNumber != null)
                      l10n.expiryBatch(item.batchNumber!),
                    if (item.quantity != null)
                      l10n.expiryQty('${item.quantity}'),
                    l10n.expiryExp(item.expiryDate),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: RadhaSpacing.space8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RadhaSpacing.space12,
              vertical: RadhaSpacing.space4,
            ),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
            ),
            child: Text(
              pillText,
              style: radhaMonoStyle(
                fontSize: 12,
                weight: FontWeight.w700,
                color: pillColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, String) _pill(
    ThemeData theme,
    int? days,
    String? status,
    AppLocalizations l10n,
  ) {
    // Prefer the precise day count; fall back to the server status label.
    if (days != null) {
      if (days < 0) {
        return (
          RadhaColors.danger,
          RadhaColors.danger.withValues(alpha: 0.12),
          l10n.expired,
        );
      }
      if (days == 0) {
        return (
          RadhaColors.danger,
          RadhaColors.danger.withValues(alpha: 0.12),
          l10n.expiryPillToday,
        );
      }
      if (days == 1) {
        return (
          RadhaColors.warning,
          RadhaColors.primaryTint.withValues(alpha: 0.5),
          l10n.expiryPillTomorrow,
        );
      }
      if (days <= 30) {
        return (
          RadhaColors.warning,
          RadhaColors.primaryTint.withValues(alpha: 0.5),
          l10n.expiryPillDays(days),
        );
      }
      return (
        theme.colorScheme.onSurfaceVariant,
        theme.colorScheme.surfaceContainerLow,
        l10n.expiryPillDays(days),
      );
    }
    final c = switch (status) {
      'expired' => RadhaColors.danger,
      'red' => RadhaColors.danger,
      'yellow' => RadhaColors.warning,
      'near_expiry' => RadhaColors.warning,
      'green' => RadhaColors.success,
      'safe' => RadhaColors.success,
      _ => theme.colorScheme.onSurfaceVariant,
    };
    final label = switch (status) {
      'expired' => l10n.expired,
      'red' => l10n.expiryPillSoon,
      'yellow' => l10n.expiryPillSoon,
      'near_expiry' => l10n.expiryPillSoon,
      'green' => l10n.expiryTabSafe,
      'safe' => l10n.expiryTabSafe,
      _ => '—',
    };
    return (c, c.withValues(alpha: 0.12), label);
  }
}

/// Shimmerless skeleton list shown while the first page loads.
class _ExpiryListSkeleton extends StatelessWidget {
  const _ExpiryListSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        RadhaSpacing.space20,
        RadhaSpacing.space4,
        RadhaSpacing.space20,
        RadhaSpacing.space32,
      ),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: RadhaSpacing.space8),
      itemBuilder: (_, _) => Container(
        height: 80,
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

class _ExpiryError extends StatelessWidget {
  const _ExpiryError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RadhaSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MorCompanion(
              mood: MorMood.concern,
              size: 96,
              semanticLabel: l10n.expiryCouldNotLoadSemantic,
            ),
            const SizedBox(height: RadhaSpacing.space16),
            Text(l10n.expiryLoadError, style: theme.textTheme.bodyMedium),
            const SizedBox(height: RadhaSpacing.space16),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
          ],
        ),
      ),
    );
  }
}
