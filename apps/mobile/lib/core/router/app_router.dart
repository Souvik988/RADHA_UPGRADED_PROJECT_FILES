import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/otp_request_screen.dart';
import '../../features/auth/otp_verify_screen.dart';
import '../../features/ai/ingredient_explainer_screen.dart';
import '../../features/allergen/allergen_profile_screen.dart';
import '../../features/alternatives/healthy_alternatives_screen.dart';
import '../../features/digest/weekly_digest_screen.dart';
import '../../features/expiry/expiry_calendar_screen.dart';
import '../../features/expiry/expiry_create_screen.dart';
import '../../features/expiry/expiry_list_screen.dart';
import '../../features/grn/grn_create_screen.dart';
import '../../features/grn/grn_items_screen.dart';
import '../../features/grn/grn_list_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/inventory/inventory_list_screen.dart';
import '../../features/inventory/low_stock_alerts_screen.dart';
import '../../features/inventory/stock_movement_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/recall/recall_alerts_screen.dart';
import '../../features/referrals/referrals_screen.dart';
import '../../features/saved_products/saved_products_screen.dart';
import '../../features/scan/ean_audit_screen.dart';
import '../../features/scan/scan_result_screen.dart';
import '../../features/scan/scan_screen.dart';
import '../../features/select_store/select_store_screen.dart';
import '../../features/settings/language_picker.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shopping_list/shopping_list_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/subscription/subscription_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/ohs_dashboard/ohs_dashboard_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../core/entitlements/entitlement_provider.dart';
import '../../design/widgets/locked_feature.dart';
import '../../features/tasks/task_create_screen.dart';
import '../../features/tasks/task_detail_screen.dart';
import '../../features/tasks/tasks_list_screen.dart';
import '../auth/auth_controller.dart';
import '../onboarding/onboarding_flag_controller.dart';
import 'go_router_refresh.dart';
import 'root_shell.dart';

/// Symbolic constants for every named route the app understands. Avoids
/// stringly-typed routing in callers and makes refactors safe.
class AppRoute {
  AppRoute._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String authOtp = '/auth/otp';
  static const String authOtpVerify = '/auth/otp/verify';
  static const String selectStore = '/select-store';

  static const String home = '/home';
  static const String scan = '/scan';
  static const String scanResult = '/scan/result/:ean';
  static const String eanAudit = '/scan/audit';
  static const String expiry = '/expiry';
  static const String expiryNew = '/expiry/new';
  static const String tasks = '/tasks';
  static const String taskCreate = '/tasks/create';
  static const String taskDetail = '/tasks/:id';
  static const String inventory = '/inventory';
  static const String inventoryStockMovement = '/inventory/stock-movement';
  static const String inventoryLowStockAlerts = '/inventory/low-stock-alerts';
  static const String grn = '/grn';
  static const String grnCreate = '/grn/create';
  static const String grnDetail = '/grn/:id';
  static const String grnItems = '/grn/:id/items';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String settingsLanguage = '/settings/language';
  static const String support = '/support';
  static const String subscription = '/subscription';
  static const String shoppingList = '/shopping-list';
  static const String recallAlerts = '/recall-alerts';
  static const String allergens = '/allergens';
  static const String referrals = '/referrals';
  static const String expiryCalendar = '/expiry-calendar';

  // Consumer-facing AI screens (FE-19, FE-22, FE-16). All rendered
  // full-screen on top of the bottom-nav shell — see
  // `parentNavigatorKey: _rootNavigatorKey` on the route entries.
  static const String ingredientExplainer = '/ingredients/:slug';
  static const String healthyAlternatives = '/alternatives/:ean';
  static const String savedProducts = '/saved-products';

  // FE-24 — Weekly Digest landing surface. `/digest` shows the most
  // recent week (Sunday push deep-link target). `/digest/:weekIso`
  // is the archive route — pre-wired so the future archive feature
  // can be linked into without a breaking change.
  static const String weeklyDigest = '/digest';
  static const String weeklyDigestArchive = '/digest/:weekIso';

  // FE-30 — Reports & Exports hub. Owner / manager surface gated
  // by the `advancedReports` entitlement.
  static const String reports = '/reports';

  // FE-26 — OHS (Operational Health) dashboard. Same entitlement
  // gate as `/reports` — both surfaces sit on the paid tier.
  static const String ohsDashboard = '/ohs';
}

/// Routes that are reachable without an authenticated session. The redirect
/// guard never bounces away from these.
final Set<String> _publicPathPrefixes = <String>{
  AppRoute.splash,
  AppRoute.onboarding,
  AppRoute.authOtp,
  AppRoute.authOtpVerify,
};

bool _isPublic(String location) {
  if (location == AppRoute.splash ||
      location == AppRoute.onboarding ||
      location == AppRoute.authOtp ||
      location == AppRoute.authOtpVerify) {
    return true;
  }
  // Defensive: handle deep links / sub-paths under /auth.
  return _publicPathPrefixes.any(location.startsWith);
}

bool _isStoreSelector(String location) => location == AppRoute.selectStore;

bool _isOnboarding(String location) => location == AppRoute.onboarding;

bool _isSplash(String location) => location == AppRoute.splash;

/// The single global navigator key. Held by the parent `Navigator` that hosts
/// the root shell, so dialogs / snackbars triggered outside any branch land
/// on the right `Overlay`.
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'rootNavigator',
);

/// Per-branch navigator keys. Each tab keeps its own stack so deep navigation
/// inside one tab doesn't blow away the others.
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'homeNavigator',
);
final GlobalKey<NavigatorState> _scanNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'scanNavigator',
);
final GlobalKey<NavigatorState> _expiryNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'expiryNavigator',
);
final GlobalKey<NavigatorState> _tasksNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'tasksNavigator',
);
final GlobalKey<NavigatorState> _profileNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'profileNavigator');

/// Provides the singleton [GoRouter] for the app. Watched by the
/// `MaterialApp.router` in `main.dart`.
///
/// Listens to [authControllerProvider] and [onboardingFlagControllerProvider]
/// via a `refreshListenable` so the redirect callback re-fires whenever the
/// session or the onboarding flag changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshNotifier(ref, [
    authControllerProvider,
    onboardingFlagControllerProvider,
  ]);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoute.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state),
    routes: <RouteBase>[
      // ─── Public / pre-auth routes ─────────────────────────────────────
      GoRoute(
        path: AppRoute.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoute.authOtp,
        name: 'authOtp',
        builder: (context, state) => const OtpRequestScreen(),
      ),
      GoRoute(
        path: AppRoute.authOtpVerify,
        name: 'authOtpVerify',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return OtpVerifyScreen(
            mobile: extra['mobile'] ?? '',
            requestId: extra['requestId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoute.selectStore,
        name: 'selectStore',
        builder: (context, state) => const SelectStoreScreen(),
      ),

      // ─── Authenticated shell ──────────────────────────────────────────
      // Five-tab bottom-nav shell. Each branch keeps its own navigator so
      // tab-switching preserves per-tab stacks.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RootShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _scanNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.scan,
                name: 'scan',
                builder: (context, state) => const ScanScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _expiryNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.expiry,
                name: 'expiry',
                builder: (context, state) => const ExpiryListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _tasksNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.tasks,
                name: 'tasks',
                builder: (context, state) => const TasksListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ─── Deep-link routes outside the shell ──────────────────────────
      // These present full-screen on top of the shell — bottom nav is
      // intentionally hidden so the user focuses on the drilled-in flow.
      GoRoute(
        path: AppRoute.scanResult,
        name: 'scanResult',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final ean = state.pathParameters['ean'] ?? '';
          return ScanResultScreen(ean: ean);
        },
      ),
      GoRoute(
        path: AppRoute.eanAudit,
        name: 'eanAudit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EanAuditScreen(),
      ),
      GoRoute(
        path: AppRoute.expiryNew,
        name: 'expiryNew',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExpiryCreateScreen(),
      ),
      GoRoute(
        path: AppRoute.taskCreate,
        name: 'taskCreate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TaskCreateScreen(),
      ),
      GoRoute(
        path: AppRoute.taskDetail,
        name: 'taskDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return TaskDetailScreen(taskId: id);
        },
      ),
      GoRoute(
        path: AppRoute.inventory,
        name: 'inventory',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LockedFeature(
          feature: Feature.inventory,
          child: InventoryListScreen(),
        ),
      ),
      GoRoute(
        path: AppRoute.inventoryStockMovement,
        name: 'inventoryStockMovement',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StockMovementScreen(),
      ),
      GoRoute(
        path: AppRoute.inventoryLowStockAlerts,
        name: 'inventoryLowStockAlerts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LowStockAlertsScreen(),
      ),
      GoRoute(
        path: AppRoute.grn,
        name: 'grn',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const LockedFeature(feature: Feature.grn, child: GrnListScreen()),
      ),
      GoRoute(
        path: AppRoute.grnCreate,
        name: 'grnCreate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GrnCreateScreen(),
      ),
      GoRoute(
        path: AppRoute.grnDetail,
        name: 'grnDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return GrnItemsScreen(grnId: id);
        },
      ),
      GoRoute(
        path: AppRoute.grnItems,
        name: 'grnItems',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return GrnItemsScreen(grnId: id);
        },
      ),
      GoRoute(
        path: AppRoute.settings,
        name: 'settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoute.settingsLanguage,
        name: 'settingsLanguage',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LanguagePickerScreen(),
      ),
      GoRoute(
        path: AppRoute.support,
        name: 'support',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: AppRoute.subscription,
        name: 'subscription',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoute.shoppingList,
        name: 'shoppingList',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ShoppingListScreen(),
      ),
      GoRoute(
        path: AppRoute.recallAlerts,
        name: 'recallAlerts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LockedFeature(
          feature: Feature.recallAlerts,
          child: RecallAlertsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoute.allergens,
        name: 'allergens',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LockedFeature(
          feature: Feature.allergenProfile,
          child: AllergenProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppRoute.referrals,
        name: 'referrals',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReferralsScreen(),
      ),
      GoRoute(
        path: AppRoute.expiryCalendar,
        name: 'expiryCalendar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExpiryCalendarScreen(),
      ),

      // ─── FE-19 / FE-22 / FE-16 — Consumer AI screens ─────────────────
      GoRoute(
        path: AppRoute.ingredientExplainer,
        name: 'ingredientExplainer',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return IngredientExplainerScreen(slug: slug);
        },
      ),
      GoRoute(
        path: AppRoute.healthyAlternatives,
        name: 'healthyAlternatives',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final ean = state.pathParameters['ean'] ?? '';
          return HealthyAlternativesScreen(ean: ean);
        },
      ),
      GoRoute(
        path: AppRoute.savedProducts,
        name: 'savedProducts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SavedProductsScreen(),
      ),

      // ─── FE-24 — Weekly Digest landing ────────────────────────────────
      // `/digest` lands users from the Sunday "Your week with RADHA"
      // push notification onto the latest digest. `/digest/:weekIso`
      // is the archive deep-link; the screen accepts the param today
      // and is forward-compatible with the per-week server endpoint
      // once it ships.
      GoRoute(
        path: AppRoute.weeklyDigest,
        name: 'weeklyDigest',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WeeklyDigestScreen(),
      ),
      GoRoute(
        path: AppRoute.weeklyDigestArchive,
        name: 'weeklyDigestArchive',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final weekIso = state.pathParameters['weekIso'];
          return WeeklyDigestScreen(weekIso: weekIso);
        },
      ),

      // ─── FE-30 — Reports & Exports ────────────────────────────────────
      // Paid surface — `LockedFeature` keeps the page behind the
      // `advancedReports` entitlement so non-paying tenants see the
      // upgrade overlay instead of the live tab UI.
      GoRoute(
        path: AppRoute.reports,
        name: 'reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LockedFeature(
          feature: Feature.advancedReports,
          child: ReportsScreen(),
        ),
      ),

      // ─── FE-26 — OHS Dashboard ────────────────────────────────────────
      // Same entitlement gate as `/reports` — both screens are paid.
      GoRoute(
        path: AppRoute.ohsDashboard,
        name: 'ohsDashboard',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LockedFeature(
          feature: Feature.advancedReports,
          child: OhsDashboardScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No route matches "${state.uri}"',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    ),
  );
});

/// Auth-aware redirect callback. Runs on every navigation attempt and
/// returns either a redirect target or `null` to permit the requested
/// route. The rules below mirror the spec for Task 4 step 2.
String? _redirect(Ref ref, GoRouterState state) {
  final location = state.matchedLocation;

  final auth = ref.read(authControllerProvider);
  final onboarding = ref.read(onboardingFlagControllerProvider);

  // 1. Block the rest of the app while we hydrate the session from secure
  //    storage. `/splash` is the only allowed location during this window.
  if (auth.isLoading || onboarding.isLoading) {
    return _isSplash(location) ? null : AppRoute.splash;
  }

  // From here on both controllers have settled (data or error).
  final session = auth.valueOrNull;
  final onboardingComplete = onboarding.valueOrNull ?? false;

  // 2. Push first-time users into onboarding before anything else.
  if (!onboardingComplete && !_isOnboarding(location)) {
    return AppRoute.onboarding;
  }

  // Onboarding is done — get off the splash if we somehow stuck on it.
  if (_isSplash(location)) {
    if (session == null) {
      return AppRoute.authOtp;
    }
    if (session.selectedStoreId == null && session.stores.isNotEmpty) {
      return AppRoute.selectStore;
    }
    return AppRoute.home;
  }

  // 3. No session ⇒ funnel to OTP request, except on already-public routes.
  if (session == null) {
    if (_isPublic(location)) return null;
    return AppRoute.authOtp;
  }

  // Logged-in users have no business on the OTP screens.
  if ((session.selectedStoreId != null || session.stores.isEmpty) &&
      (location == AppRoute.authOtp || location == AppRoute.authOtpVerify)) {
    return AppRoute.home;
  }

  // 4. Logged-in but no store picked ⇒ park on /select-store — but ONLY when
  //    the user actually has stores to choose from. Consumers (and any role
  //    with zero store access) have no store to pick, so they go straight to
  //    /home rather than dead-ending on the empty store selector.
  if (session.selectedStoreId == null &&
      session.stores.isNotEmpty &&
      !_isStoreSelector(location) &&
      !_isPublic(location)) {
    return AppRoute.selectStore;
  }

  // 5. Otherwise let GoRouter resolve the requested location.
  return null;
}
