import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/network/api_client.dart';
import '../../core/network/dto/task_dto.dart';
import '../../core/router/app_router.dart';
import '../../design/app_assets.dart';
import '../../design/tokens.dart';
import '../../design/widgets/empty_state.dart';
import '../../design/widgets/mor_companion.dart';

/// Paginated tasks state — loaded items + page cursor, per status filter.
class _TasksListState {
  const _TasksListState({
    required this.items,
    required this.cursor,
    required this.hasMore,
    required this.loadingMore,
  });

  final List<TaskResponse> items;
  final String? cursor;
  final bool hasMore;
  final bool loadingMore;

  _TasksListState copyWith({
    List<TaskResponse>? items,
    Object? cursor = _sentinel,
    bool? hasMore,
    bool? loadingMore,
  }) {
    return _TasksListState(
      items: items ?? this.items,
      cursor: identical(cursor, _sentinel) ? this.cursor : cursor as String?,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }

  static const _sentinel = Object();
}

/// Cursor-paginated tasks controller, keyed by status filter (one per tab).
/// Mirrors the inventory list pattern so behaviour stays consistent.
class _TasksListController
    extends AutoDisposeFamilyAsyncNotifier<_TasksListState, String?> {
  static const _pageSize = 30;

  Future<_TasksListState> _fetch(String? status, {String? cursor}) async {
    final client = ref.read(apiClientProvider);
    final page = await client.getTasks(
      status: status,
      cursor: cursor,
      limit: _pageSize,
    );
    return _TasksListState(
      items: page.items,
      cursor: page.cursor,
      hasMore: page.cursor != null && page.items.length >= _pageSize,
      loadingMore: false,
    );
  }

  @override
  Future<_TasksListState> build(String? status) async {
    ref.watch(apiClientProvider);
    return _fetch(status);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.hasMore || current.loadingMore) return;

    state = AsyncValue.data(current.copyWith(loadingMore: true));
    try {
      final next = await _fetch(arg, cursor: current.cursor);
      state = AsyncValue.data(
        _TasksListState(
          items: [...current.items, ...next.items],
          cursor: next.cursor,
          hasMore: next.hasMore,
          loadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(current.copyWith(loadingMore: false));
    }
  }
}

final _tasksListControllerProvider = AsyncNotifierProvider.autoDispose
    .family<_TasksListController, _TasksListState, String?>(
      _TasksListController.new,
    );

/// Tasks list — filter tabs (My Tasks / All / Completed), a priority chip row,
/// polished task cards (priority chip, status dot, assignee + due meta), and a
/// manager-only FAB. Underline tabs + orange accent match the mockup.
class TasksListScreen extends ConsumerStatefulWidget {
  const TasksListScreen({super.key});

  @override
  ConsumerState<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends ConsumerState<TasksListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _index = 0;
  String? _priorityFilter;

  static const _tabs = ['My Tasks', 'All', 'Completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index != _index) {
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
    final currentUser = ref.watch(currentUserProvider);
    final isManager =
        currentUser?.roles.contains('manager') == true ||
        currentUser?.roles.contains('admin') == true;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Tasks',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          _UnderlineTabs(
            labels: _tabs,
            index: _index,
            onChanged: (i) {
              HapticFeedback.selectionClick();
              _tabController.animateTo(i);
            },
          ),
          _PriorityChips(
            selected: _priorityFilter,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _priorityFilter = value);
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TaskList(
                  status: 'pending',
                  priorityFilter: _priorityFilter,
                  userId: currentUser?.userId,
                ),
                _TaskList(status: null, priorityFilter: _priorityFilter),
                _TaskList(status: 'completed', priorityFilter: _priorityFilter),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
              heroTag: 'tasks_fab',
              backgroundColor: RadhaColors.primary,
              foregroundColor: RadhaColors.onPrimary,
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(AppRoute.taskCreate);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New task'),
            )
          : null,
    );
  }
}

/// Underline-style filter tabs with an animated indicator.
class _UnderlineTabs extends StatelessWidget {
  const _UnderlineTabs({
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
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: RadhaSpacing.space16,
                  vertical: RadhaSpacing.space12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
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
                    const SizedBox(height: RadhaSpacing.space8),
                    AnimatedContainer(
                      duration: RadhaMotion.fast,
                      curve: RadhaMotion.easeOut,
                      height: 2.5,
                      width: i == index ? 24 : 0,
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
            ),
        ],
      ),
    );
  }
}

/// Horizontal priority filter chips.
class _PriorityChips extends StatelessWidget {
  const _PriorityChips({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const priorities = ['high', 'medium', 'low'];
    const labels = {'high': 'High', 'medium': 'Medium', 'low': 'Low'};

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RadhaSpacing.space16,
        RadhaSpacing.space12,
        RadhaSpacing.space16,
        RadhaSpacing.space4,
      ),
      child: Row(
        children: priorities.map((p) {
          final isSelected = selected == p;
          final color = _priorityColor(p);
          return Padding(
            padding: const EdgeInsets.only(right: RadhaSpacing.space8),
            child: GestureDetector(
              onTap: () => onChanged(isSelected ? null : p),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: RadhaMotion.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: RadhaSpacing.space12,
                  vertical: RadhaSpacing.space8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
                  border: Border.all(
                    color: isSelected ? color : theme.colorScheme.outline,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: RadhaSpacing.space8),
                    Text(
                      labels[p]!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Task list that consumes the paginated tasks controller and filters locally
/// by priority and optionally by assigned user. Infinite-scrolls across cursor
/// pages so a busy store's full task list is reachable, not just page one.
class _TaskList extends ConsumerStatefulWidget {
  const _TaskList({required this.status, this.priorityFilter, this.userId});

  final String? status;
  final String? priorityFilter;
  final String? userId;

  @override
  ConsumerState<_TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<_TaskList> {
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
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(_tasksListControllerProvider(widget.status).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(_tasksListControllerProvider(widget.status));

    return tasksAsync.when(
      loading: () => const _TaskListSkeleton(),
      error: (err, _) => _TaskError(
        onRetry: () => ref
            .read(_tasksListControllerProvider(widget.status).notifier)
            .refresh(),
      ),
      data: (state) {
        var items = state.items;
        if (widget.priorityFilter != null) {
          items =
              items.where((t) => t.priority == widget.priorityFilter).toList();
        }
        if (widget.userId != null) {
          items = items.where((t) => t.assigneeId == widget.userId).toList();
        }

        if (items.isEmpty) {
          return RefreshIndicator(
            color: RadhaColors.primary,
            onRefresh: () async => ref
                .read(_tasksListControllerProvider(widget.status).notifier)
                .refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.14),
                Center(
                  child: EmptyState(
                    illustration: const MorCompanion(
                      mood: MorMood.greet,
                      size: 104,
                    ),
                    title: 'No tasks here',
                    body: 'Tasks assigned to this view will show up here.',
                  ),
                ),
              ],
            ),
          );
        }

        // Only show the load-more footer when the full (unfiltered) list has
        // more pages — a local priority/assignee filter shouldn't imply more.
        final showFooter = state.loadingMore &&
            widget.priorityFilter == null &&
            widget.userId == null;

        return RefreshIndicator(
          color: RadhaColors.primary,
          onRefresh: () async => ref
              .read(_tasksListControllerProvider(widget.status).notifier)
              .refresh(),
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              RadhaSpacing.space20,
              RadhaSpacing.space12,
              RadhaSpacing.space20,
              RadhaSpacing.space32 + 72,
            ),
            itemCount: items.length + (showFooter ? 1 : 0),
            separatorBuilder: (_, _) =>
                const SizedBox(height: RadhaSpacing.space12),
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return const Padding(
                  padding: EdgeInsets.all(RadhaSpacing.space16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: RadhaColors.primary,
                    ),
                  ),
                );
              }
              return _TaskTile(task: items[index]);
            },
          ),
        );
      },
    );
  }
}

/// Single task card — title + priority chip, meta row, status dot + label.
class _TaskTile extends StatefulWidget {
  const _TaskTile({required this.task});

  final TaskResponse task;

  @override
  State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = widget.task;
    final done = task.status == 'completed';

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/tasks/${task.id}');
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: RadhaSpacing.space8),
                  _PriorityBadge(priority: task.priority),
                ],
              ),
              const SizedBox(height: RadhaSpacing.space12),
              Row(
                children: [
                  _StatusDot(status: task.status),
                  const SizedBox(width: RadhaSpacing.space8),
                  _StatusLabel(status: task.status),
                  const Spacer(),
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: RadhaSpacing.space4),
                    Text(
                      _formatDate(task.dueDate!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              if (task.assigneeName != null) ...[
                const SizedBox(height: RadhaSpacing.space8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: RadhaSpacing.space4),
                    Text(
                      task.assigneeName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (task.requiresEvidence == true) ...[
                      const SizedBox(width: RadhaSpacing.space12),
                      Icon(
                        Icons.photo_camera_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: RadhaSpacing.space4),
                      Text(
                        'Evidence',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
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

/// Colored priority chip (danger = high, warn = medium, success = low).
class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({this.priority});

  final String? priority;

  @override
  Widget build(BuildContext context) {
    if (priority == null) return const SizedBox.shrink();
    final color = _priorityColor(priority!);
    final label = priority![0].toUpperCase() + priority!.substring(1);

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

class _StatusDot extends StatelessWidget {
  const _StatusDot({this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _statusColor(context, status),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final raw = (status ?? 'open').replaceAll('_', ' ');
    final label = raw[0].toUpperCase() + raw.substring(1);
    return Text(
      label,
      style: theme.textTheme.bodySmall?.copyWith(
        color: _statusColor(context, status),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

Color _statusColor(BuildContext context, String? status) {
  switch (status) {
    case 'completed':
      return RadhaColors.success;
    case 'in_progress':
      return RadhaColors.primary;
    case 'cancelled':
      return Theme.of(context).colorScheme.onSurfaceVariant;
    default:
      return RadhaColors.warning;
  }
}

/// Returns the brand-mapped color for a task priority string.
Color _priorityColor(String priority) {
  switch (priority) {
    case 'high':
    case 'urgent':
      return RadhaColors.danger;
    case 'medium':
      return RadhaColors.warning;
    case 'low':
      return RadhaColors.success;
    default:
      return RadhaColors.inkMuted;
  }
}

// ─── Loading / empty / error ─────────────────────────────────────────────────

class _TaskListSkeleton extends StatelessWidget {
  const _TaskListSkeleton();

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
        height: 96,
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

class _TaskError extends StatelessWidget {
  const _TaskError({required this.onRetry});

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
            Text('Failed to load tasks', style: theme.textTheme.bodyMedium),
            const SizedBox(height: RadhaSpacing.space16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
