import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design/widgets/connectivity_banner.dart';
import '../../features/sync/sync_status_banner.dart';
import '../offline/sync_service.dart';

/// Five-tab bottom-navigation shell that hosts the primary feature surfaces:
/// Home, Scan, Expiry, Tasks, Profile. Wired up in `app_router.dart` as the
/// builder for a [StatefulShellRoute.indexedStack].
///
/// The 5-tab cap is intentional — UI/UX Pro Max bottom-nav rule disallows
/// more than five top-level destinations. Anything else is reachable via
/// drill-in or the Profile/Settings tab.
class RootShell extends ConsumerWidget {
  const RootShell({required this.navigationShell, super.key});

  /// The shell GoRouter hands us — owns the per-tab navigator stacks and
  /// exposes [StatefulNavigationShell.goBranch] to switch between them.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Side-effect read: ensures the connectivity-driven sync bootstrap is
    // running for the lifetime of the authenticated shell. The provider
    // owns its own subscription, so we don't need to capture anything.
    ref.watch(syncBootstrapProvider);

    return Scaffold(
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(child: navigationShell),
          // Connectivity strip lives at the bottom of the body column, just
          // above the navigation bar. Renders nothing when online so the
          // happy-path layout is unchanged.
          const ConnectivityBanner(),
        ],
      ),
      bottomNavigationBar: _RootBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          // Light selection haptic on tab switch — `selectionClick` is the
          // platform-recommended cue for low-priority discrete events.
          HapticFeedback.selectionClick();
          navigationShell.goBranch(
            index,
            // Re-tapping the active tab pops back to that branch's root.
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _RootBottomNav extends StatelessWidget {
  const _RootBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Expiry',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
