import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/network/dto/inventory_dto.dart';
import '../../core/router/app_router.dart';
import '../../design/app_assets.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets/mor_companion.dart';

/// State controller that hydrates the inventory list with cursor pagination
/// and exposes a single `AsyncValue<List<InventoryItemResponse>>` to the UI.
///
/// The store keeps the current page cursor + already-loaded items so we can
/// append more rows when the user scrolls without rewriting the whole list.
class _InventoryListState {
  const _InventoryListState({
    required this.items,
    required this.cursor,
    required this.hasMore,
    required this.loadingMore,
  });

  final List<InventoryItemResponse> items;
  final String? cursor;
  final bool hasMore;
  final bool loadingMore;

  _InventoryListState copyWith({
    List<InventoryItemResponse>? items,
    Object? cursor = _sentinel,
    bool? hasMore,
    bool? loadingMore,
  }) {
    return _InventoryListState(
      items: items ?? this.items,
      cursor: identical(cursor, _sentinel) ? this.cursor : cursor as String?,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }

  static const _sentinel = Object();
}

class _InventoryListController
    extends AutoDisposeAsyncNotifier<_InventoryListState> {
  static const _pageSize = 30;

  @override
  Future<_InventoryListState> build() async {
    final client = ref.watch(apiClientProvider);
    final page = await client.getInventory(limit: _pageSize);
    return _InventoryListState(
      items: page.items,
      cursor: page.cursor,
      hasMore: page.cursor != null && page.items.length >= _pageSize,
      loadingMore: false,
    );
  }

  /// Refresh the list from the top, discarding any loaded pages.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(apiClientProvider);
      final page = await client.getInventory(limit: _pageSize);
      return _InventoryListState(
        items: page.items,
        cursor: page.cursor,
        hasMore: page.cursor != null && page.items.length >= _pageSize,
        loadingMore: false,
      );
    });
  }

  /// Append the next page if a cursor is available and we aren't already
  /// fetching one. Errors keep the existing items in place.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.hasMore || current.loadingMore) return;

    state = AsyncValue.data(current.copyWith(loadingMore: true));

    try {
      final client = ref.read(apiClientProvider);
      final page = await client.getInventory(
        cursor: current.cursor,
        limit: _pageSize,
      );
      state = AsyncValue.data(
        _InventoryListState(
          items: [...current.items, ...page.items],
          cursor: page.cursor,
          hasMore: page.cursor != null && page.items.length >= _pageSize,
          loadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(current.copyWith(loadingMore: false));
    }
  }
}

final _inventoryListControllerProvider =
    AsyncNotifierProvider.autoDispose<
      _InventoryListController,
      _InventoryListState
    >(_InventoryListController.new);

/// Inventory list screen showing current stock per product with a low-stock
/// badge, expandable batch breakdown, search-by-product/EAN filter, infinite
/// scroll across cursor pages, and quick links to stock movement + low-stock
/// alerts.
///
/// Consumes the inventory listing endpoint that backs Requirements R17 + R18
/// (current stock, low-stock flag).
class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  bool _showSearch = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(_inventoryListControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inventoryAsync = ref.watch(_inventoryListControllerProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: _showSearch
            ? _SearchField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                onClose: () => setState(() {
                  _showSearch = false;
                  _searchQuery = '';
                  _searchController.clear();
                }),
              )
            : Text(
                'Inventory',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
        actions: [
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search inventory',
              onPressed: () => setState(() => _showSearch = true),
            ),
        ],
      ),
      body: Column(
        children: [
          // Action buttons row — quick links to the connected screens.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: RadhaSpacing.space24,
              vertical: RadhaSpacing.space12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.swap_vert_rounded,
                    label: 'Stock Movement',
                    onTap: () => context.push(AppRoute.inventoryStockMovement),
                  ),
                ),
                const SizedBox(width: RadhaSpacing.space12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.warning_amber_rounded,
                    label: 'Low Stock Alerts',
                    onTap: () => context.push(AppRoute.inventoryLowStockAlerts),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: inventoryAsync.when(
              loading: () => const _InventorySkeleton(),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MorCompanion(
                      mood: MorMood.concern,
                      size: 96,
                      semanticLabel: 'Could not load',
                    ),
                    const SizedBox(height: RadhaSpacing.space12),
                    Text(
                      'Failed to load inventory',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: RadhaSpacing.space8),
                    FilledButton(
                      onPressed: () => ref
                          .read(_inventoryListControllerProvider.notifier)
                          .refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                final items = _filter(state.items, _searchQuery);

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MorCompanion(mood: MorMood.greet, size: 104),
                        const SizedBox(height: RadhaSpacing.space12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No inventory items found'
                              : 'No matches for "$_searchQuery"',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(_inventoryListControllerProvider.notifier)
                      .refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      RadhaSpacing.space24,
                      RadhaSpacing.space12,
                      RadhaSpacing.space24,
                      RadhaSpacing.space24,
                    ),
                    itemCount: items.length + (state.loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: RadhaSpacing.space12),
                    itemBuilder: (context, index) {
                      if (index >= items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(RadhaSpacing.space16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return _InventoryTile(item: items[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Lower-cases the user query and filters by `productId`. The item DTO only
  /// surfaces `productId` (which doubles as the EAN-style identifier in the
  /// list endpoint) so a single field covers both name and EAN searches.
  static List<InventoryItemResponse> _filter(
    List<InventoryItemResponse> items,
    String query,
  ) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return items;
    return items
        .where((i) => i.productId.toLowerCase().contains(trimmed))
        .toList();
  }
}

/// Borderless search field used inside the AppBar title slot.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search by product or EAN...',
        border: InputBorder.none,
        suffixIcon: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

/// Two-line iconic action card used at the top of the screen for quick
/// navigation to the related sub-flows.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
        onTap: onTap,
        child: Container(
          height: kMinTouchTarget + 8,
          padding: const EdgeInsets.symmetric(horizontal: RadhaSpacing.space16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: RadhaColors.primary),
              const SizedBox(width: RadhaSpacing.space8),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single inventory row. Tap to expand the batch / threshold breakdown and
/// reveal the low-stock badge for items below their threshold.
class _InventoryTile extends StatefulWidget {
  const _InventoryTile({required this.item});

  final InventoryItemResponse item;

  @override
  State<_InventoryTile> createState() => _InventoryTileState();
}

class _InventoryTileState extends State<_InventoryTile> {
  bool _expanded = false;

  bool get _isLowStock {
    final threshold = widget.item.lowStockThreshold;
    if (threshold == null) return false;
    return widget.item.quantity < threshold;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final low = _isLowStock;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _expanded = !_expanded);
        },
        child: Padding(
          padding: const EdgeInsets.all(RadhaSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                          'Product ${item.productId}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: RadhaSpacing.space2),
                        Row(
                          children: [
                            Text(
                              low
                                  ? 'Below threshold'
                                  : 'In stock',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: low
                                    ? RadhaColors.warning
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (low) ...[
                              const SizedBox(width: RadhaSpacing.space8),
                              const _LowStockBadge(),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: RadhaSpacing.space12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.quantity}',
                        style: radhaMonoStyle(
                          fontSize: 22,
                          weight: FontWeight.w700,
                          color: low
                              ? RadhaColors.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'units',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: RadhaSpacing.space12),
                Divider(height: 1, color: theme.colorScheme.outline),
                const SizedBox(height: RadhaSpacing.space12),
                _DetailLine(
                  label: 'Total quantity',
                  value: '${item.quantity} units',
                ),
                if (item.lowStockThreshold != null)
                  _DetailLine(
                    label: 'Low-stock threshold',
                    value: '${item.lowStockThreshold} units',
                  ),
                const SizedBox(height: RadhaSpacing.space4),
                Text(
                  'Tap "Stock movement" to view the full batch ledger.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Label/value line used in the expanded inventory detail.
class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: RadhaSpacing.space4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rose pill badge shown when stock is below the configured threshold.
/// Background sits at ~12% alpha of the danger token, label at 600 weight.
class _LowStockBadge extends StatelessWidget {
  const _LowStockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RadhaSpacing.space8,
        vertical: RadhaSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: RadhaColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
      ),
      child: const Text(
        'Low Stock',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: RadhaColors.danger,
        ),
      ),
    );
  }
}

/// Skeleton list shown while the first inventory page loads.
class _InventorySkeleton extends StatelessWidget {
  const _InventorySkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        RadhaSpacing.space24,
        RadhaSpacing.space12,
        RadhaSpacing.space24,
        RadhaSpacing.space24,
      ),
      itemCount: 7,
      separatorBuilder: (_, _) => const SizedBox(height: RadhaSpacing.space12),
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
