import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design/widgets/connectivity_banner.dart';
import '../../design/widgets/radha_bottom_navigation.dart';
import '../../features/sync/sync_status_banner.dart';
import '../../l10n/generated/app_localizations.dart';
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
      bottomNavigationBar: RadhaBottomNavigation(
        currentIndex: navigationShell.currentIndex,
        destinations: _destinations(context),
        onDestinationSelected: (index) {
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

  /// The five fixed branches: Home, Scan, Expiry, Tasks, Profile. Order matches
  /// the `StatefulShellBranch` order in `app_router.dart` and must not change.
  /// Labels are localized; Scan is the emphasized primary action.
  ///
  /// No `badgeCount` is supplied — counts are wired only when a real provider
  /// exists, so the bar never shows a fabricated number.
  List<RadhaNavDestination> _destinations(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      RadhaNavDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: l10n.home,
      ),
      RadhaNavDestination(
        icon: Icons.qr_code_scanner_rounded,
        selectedIcon: Icons.qr_code_scanner_rounded,
        label: l10n.scan,
        emphasized: true,
      ),
      RadhaNavDestination(
        icon: Icons.event_outlined,
        selectedIcon: Icons.event_rounded,
        label: l10n.expiry,
      ),
      RadhaNavDestination(
        icon: Icons.checklist_outlined,
        selectedIcon: Icons.checklist_rounded,
        label: l10n.tasks,
      ),
      RadhaNavDestination(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: l10n.profile,
      ),
    ];
  }
}
