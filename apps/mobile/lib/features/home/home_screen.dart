import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:radha_mobile/core/auth/auth_controller.dart';
import 'package:radha_mobile/core/router/app_router.dart';
import 'package:radha_mobile/design/app_assets.dart';
import 'package:radha_mobile/design/theme.dart';
import 'package:radha_mobile/design/tokens.dart';
import 'package:radha_mobile/design/widgets/mor_companion.dart';
import 'package:radha_mobile/design/widgets/skeleton_loader.dart';

import 'providers/home_summary_providers.dart';

/// Home dashboard — the anchor screen (VISUAL_SCREENS/08_home.md).
///
/// A breathable, content-heavy bento told as a story: a warm storefront
/// greeting band (the human beat), three KPI tiles (mono numbers, functional
/// tints), the **Hero Story Banner** where Mor hands the owner today's mission,
/// a quick-actions row, and a recent-tasks list (the next action).
///
/// Wiring is preserved 1:1 from the prior build — same providers, same routes,
/// same `_Stagger` / `_PressableCard` primitives. Only the visual layer grew.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(nearExpiryCountProvider);
    ref.invalidate(openTasksCountProvider);
    ref.invalidate(lowStockCountProvider);
    await Future.wait<void>([
      ref.read(nearExpiryCountProvider.future).catchError((_) => 0),
      ref.read(openTasksCountProvider.future).catchError((_) => 0),
      ref.read(lowStockCountProvider.future).catchError((_) => 0),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: RadhaColors.primary,
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            RadhaSpacing.space20,
            RadhaSpacing.space16,
            RadhaSpacing.space20,
            RadhaSpacing.space32,
          ),
          children: [
            _Stagger(index: 0, child: _HeroGreeting(user: user)),
            const SizedBox(height: RadhaSpacing.space20),
            _Stagger(index: 1, child: const _KpiRow()),
            const SizedBox(height: RadhaSpacing.space20),
            _Stagger(index: 2, child: const _StoryBanner()),
            const SizedBox(height: RadhaSpacing.space24),
            _Stagger(index: 3, child: const _QuickActionsSection()),
            const SizedBox(height: RadhaSpacing.space24),
            _Stagger(index: 4, child: const _RecentTasksSection()),
          ],
        ),
      ),
    );
  }
}

// ─── Staggered entrance wrapper ──────────────────────────────────────────────

/// Fades + rises its child in, staggered by `index`. One-shot. Uses an
/// Interval-based curve on a single controller started in `initState` (no
/// `Future.delayed`) so widget tests that pump a single frame don't trip over
/// a dangling Timer. Respects `disableAnimations`.
class _Stagger extends StatefulWidget {
  const _Stagger({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<_Stagger> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _fade;
  late final Animation<Offset> _rise;

  @override
  void initState() {
    super.initState();
    final start = (widget.index * 0.1).clamp(0.0, 0.6);
    final curve = CurvedAnimation(
      parent: _c,
      curve: Interval(start, 1, curve: Curves.easeOut),
    );
    _fade = curve;
    _rise = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return widget.child;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _rise, child: widget.child),
    );
  }
}

// ─── Hero greeting band ──────────────────────────────────────────────────────

/// The authored "human beat": a warm storefront band with a personalised
/// greeting, the store-picker chip, and the avatar. The storefront
/// illustration sits in the top-right (its left third is intentionally clear),
/// behind a soft warm wash.
class _HeroGreeting extends StatelessWidget {
  const _HeroGreeting({required this.user});

  final CurrentUser? user;

  String get _timeGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Personalised greeting derived from the user id. We keep the raw first
    // segment (no forced capitalisation) so the greeting always contains the
    // user identifier verbatim.
    final rawName = user?.userId.split('-').first ?? 'there';
    final name = rawName.isEmpty ? 'there' : rawName;
    final storeName = user?.selectedStoreName;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RadhaRadii.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            RadhaColors.primaryTint.withValues(alpha: 0.38),
            theme.colorScheme.surface,
          ],
        ),
      ),
      padding: const EdgeInsets.all(RadhaSpacing.space16),
      child: Stack(
        children: [
          // Storefront motif, top-right, subtle and behind the content.
          Positioned(
            right: -10,
            top: -10,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.85,
                child: Image.asset(
                  RadhaAssets.illoHomeStorefront,
                  height: 104,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  // Decode small (the source is ~1.6 MB) to stay jank-free.
                  cacheHeight: 312,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _timeGreeting,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: RadhaSpacing.space2),
                    Text(
                      name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (storeName != null) ...[
                      const SizedBox(height: RadhaSpacing.space12),
                      _StorePickerChip(storeName: storeName),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: RadhaSpacing.space12),
              _AvatarTile(name: name),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorePickerChip extends StatelessWidget {
  const _StorePickerChip({required this.storeName});

  final String storeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(AppRoute.selectStore);
        },
        borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RadhaSpacing.space12,
            vertical: RadhaSpacing.space8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: RadhaSpacing.space8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: RadhaSpacing.space4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'R';
    return Semantics(
      button: true,
      label: 'Profile',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(AppRoute.profile);
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.outline),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── KPI row ─────────────────────────────────────────────────────────────────

class _KpiRow extends ConsumerWidget {
  const _KpiRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearExpiry = ref.watch(nearExpiryCountProvider);
    final openTasks = ref.watch(openTasksCountProvider);
    final lowStock = ref.watch(lowStockCountProvider);

    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            value: openTasks,
            label: 'Open tasks',
            icon: Icons.checklist_rounded,
            tint: RadhaColors.primary,
            onTap: () => context.push(AppRoute.tasks),
          ),
        ),
        const SizedBox(width: RadhaSpacing.space12),
        Expanded(
          child: _KpiTile(
            value: nearExpiry,
            label: 'Near expiry',
            icon: Icons.schedule_rounded,
            tint: RadhaColors.warning,
            onTap: () => context.push(AppRoute.expiry),
          ),
        ),
        const SizedBox(width: RadhaSpacing.space12),
        Expanded(
          child: _KpiTile(
            value: lowStock,
            label: 'Low stock',
            icon: Icons.inventory_2_rounded,
            tint: RadhaColors.complement,
            onTap: () => context.push(AppRoute.inventory),
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final AsyncValue<int> value;
  final String label;
  final IconData icon;

  /// Functional tint for the glyph well + number (warn/accent/teal).
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PressableCard(
      onTap: onTap,
      padding: const EdgeInsets.all(RadhaSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(RadhaRadii.radiusSm),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(height: RadhaSpacing.space12),
          value.when(
            data: (count) => Text(
              '$count',
              style: radhaMonoStyle(
                fontSize: 28,
                weight: FontWeight.w700,
                color: tint,
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: RadhaSpacing.space4),
              child: SkeletonLoader(width: 36, height: 24),
            ),
            error: (_, _) => Text(
              '–',
              style: radhaMonoStyle(
                fontSize: 28,
                weight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: RadhaSpacing.space4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Story Banner (Mor's daily mission) ─────────────────────────────────

/// The showpiece (VISUAL_SCREENS/08_home.md Z2). Mor hands the owner today's
/// real, backend-driven mission. **No scan-to-earn / rewards** — the headline
/// is derived from live KPI providers and routes to a real screen.
class _StoryBanner extends ConsumerWidget {
  const _StoryBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nearExpiry = ref.watch(nearExpiryCountProvider).valueOrNull;
    final openTasks = ref.watch(openTasksCountProvider).valueOrNull;
    final lowStock = ref.watch(lowStockCountProvider).valueOrNull;

    final loading =
        nearExpiry == null && openTasks == null && lowStock == null;

    String eyebrow = 'AAJ KA KAAM · TODAY';
    final String headline;
    final String cta;
    final VoidCallback onTap;
    final MorMood mood;

    if ((nearExpiry ?? 0) > 0) {
      headline = '$nearExpiry items near expiry — clear the shelf';
      cta = 'Open expiry';
      onTap = () => context.push(AppRoute.expiry);
      mood = MorMood.guard;
    } else if ((openTasks ?? 0) > 0) {
      headline = openTasks == 1
          ? '1 task needs you today'
          : '$openTasks tasks need you today';
      cta = 'View tasks';
      onTap = () => context.push(AppRoute.tasks);
      mood = MorMood.work;
    } else if ((lowStock ?? 0) > 0) {
      headline = '$lowStock items running low on stock';
      cta = 'Check inventory';
      onTap = () => context.push(AppRoute.inventory);
      mood = MorMood.think;
    } else if (loading) {
      headline = "Here's your store today";
      cta = 'Open tasks';
      onTap = () => context.push(AppRoute.tasks);
      mood = MorMood.greet;
    } else {
      eyebrow = 'ALL CLEAR';
      headline = "Shabaash! Your store's in great shape today";
      cta = 'Run a quick audit';
      onTap = () => context.go(AppRoute.scan);
      mood = MorMood.celebrate;
    }

    return Container(
      decoration: BoxDecoration(
        color: RadhaColors.primary,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusXl),
      ),
      padding: const EdgeInsets.all(RadhaSpacing.space20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: RadhaColors.primaryTint,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: RadhaSpacing.space8),
                Text(
                  headline,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: RadhaColors.onPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: RadhaSpacing.space16),
                _WhiteCtaPill(label: cta, onTap: onTap),
              ],
            ),
          ),
          const SizedBox(width: RadhaSpacing.space12),
          MorCompanion(mood: mood, size: 84),
        ],
      ),
    );
  }
}

class _WhiteCtaPill extends StatelessWidget {
  const _WhiteCtaPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: RadhaColors.onPrimary,
      borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RadhaSpacing.space16,
            vertical: RadhaSpacing.space8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: RadhaColors.primaryDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: RadhaSpacing.space4),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: RadhaColors.primaryDeep,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick actions section ───────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: RadhaSpacing.space12),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan',
                accent: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Scan is a bottom-nav branch — switch tabs rather than push.
                  context.go(AppRoute.scan);
                },
              ),
            ),
            const SizedBox(width: RadhaSpacing.space12),
            Expanded(
              child: _QuickAction(
                icon: Icons.event_available_outlined,
                label: 'Add Expiry',
                onTap: () => context.push(AppRoute.expiryNew),
              ),
            ),
            const SizedBox(width: RadhaSpacing.space12),
            Expanded(
              child: _QuickAction(
                icon: Icons.add_task_outlined,
                label: 'New Task',
                onTap: () => context.push(AppRoute.taskCreate),
              ),
            ),
            const SizedBox(width: RadhaSpacing.space12),
            Expanded(
              child: _QuickAction(
                icon: Icons.inventory_2_outlined,
                label: 'Inventory',
                onTap: () => context.push(AppRoute.inventory),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileColor = accent
        ? RadhaColors.primaryTint.withValues(alpha: 0.9)
        : RadhaColors.primaryTint.withValues(alpha: 0.45);
    return _PressableCard(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      padding: const EdgeInsets.symmetric(
        horizontal: RadhaSpacing.space8,
        vertical: RadhaSpacing.space16,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(RadhaRadii.radiusSm),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: RadhaColors.primaryDeep),
          ),
          const SizedBox(height: RadhaSpacing.space8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent tasks ────────────────────────────────────────────────────────────

class _RecentTasksSection extends StatelessWidget {
  const _RecentTasksSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Lightweight placeholder rows — the live tasks list lives on the Tasks
    // tab. These mirror that surface's visual language so the home preview
    // and the full list read as one system.
    final items = <_RecentTask>[
      const _RecentTask(
        title: 'Check dairy fridge temps',
        meta: 'Due today · 6 PM',
        status: _TaskDotStatus.dueSoon,
      ),
      const _RecentTask(
        title: 'Restock front shelf',
        meta: 'Assigned to you',
        status: _TaskDotStatus.open,
      ),
      const _RecentTask(
        title: 'Audit approved EANs — aisle 3',
        meta: 'Completed · 2h ago',
        status: _TaskDotStatus.done,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent tasks',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoute.tasks),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: RadhaSpacing.space8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: RadhaSpacing.space12),
        for (var i = 0; i < items.length; i++) ...[
          _RecentTaskRow(task: items[i]),
          if (i != items.length - 1)
            const SizedBox(height: RadhaSpacing.space8),
        ],
      ],
    );
  }
}

enum _TaskDotStatus { done, dueSoon, open }

class _RecentTask {
  const _RecentTask({
    required this.title,
    required this.meta,
    required this.status,
  });

  final String title;
  final String meta;
  final _TaskDotStatus status;
}

class _RecentTaskRow extends StatelessWidget {
  const _RecentTaskRow({required this.task});

  final _RecentTask task;

  Color _dotColor() => switch (task.status) {
    _TaskDotStatus.done => RadhaColors.success,
    _TaskDotStatus.dueSoon => RadhaColors.warning,
    _TaskDotStatus.open => RadhaColors.inkMuted,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = task.status == _TaskDotStatus.done;
    return _PressableCard(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push(AppRoute.tasks);
      },
      padding: const EdgeInsets.all(RadhaSpacing.space16),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _dotColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: RadhaSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: RadhaSpacing.space2),
                Text(
                  task.meta,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// ─── Shared pressable card primitive ─────────────────────────────────────────

/// A rounded surface with a spring press-scale (0.97). Used by every tappable
/// card on the dashboard so the tactile feel is consistent. Honors
/// `disableAnimations` via `AnimatedScale`.
class _PressableCard extends StatefulWidget {
  const _PressableCard({
    required this.child,
    required this.onTap,
    required this.padding,
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets padding;

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: RadhaMotion.fast,
        curve: RadhaMotion.spring,
        child: AnimatedContainer(
          duration: RadhaMotion.fast,
          curve: RadhaMotion.easeOut,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
