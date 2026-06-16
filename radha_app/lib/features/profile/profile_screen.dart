// Real `/profile` screen.
//
// Lives in the bottom-nav `profile` branch. Surfaces the signed-in user's
// identity, gives them entry points to the existing routes that are
// "settings-shaped" (stores, allergens, shopping list, subscription,
// language, referrals), and provides Sign Out + an About card with the
// app version pulled from `package_info_plus`.
//
// Design rules:
//   * One orange accent (#EA580C) — used only for the role chip and the trailing
//     chevron of the active sign-out section.
//   * Quick action rows are 56pt high (≥ kMinTouchTarget).
//   * No emoji-as-icon. Material `Icons.*_outlined` only.
//   * No gradient backgrounds, no centered heroes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/router/app_router.dart';
import '../../design/app_assets.dart';
import '../../design/tokens.dart';
import '../../design/widgets/mor_companion.dart';
import '../../l10n/generated/app_localizations.dart';

/// Cached `PackageInfo`. The bootstrap controller already loads this on cold
/// start, so reading it again here is essentially a no-op on real devices.
final _packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// Profile tab content. Sits inside the `RootShell`, which is why we don't
/// own an `AppBar` of our own — the shell renders the nav bar at the bottom
/// and the screen body is what scrolls.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final session = ref.watch(authControllerProvider).valueOrNull;
    final packageInfoAsync = ref.watch(_packageInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.profile,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoute.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          // No-op refresh — invalidating the auth controller forces a
          // re-hydration from secure storage. We don't network-fetch here
          // because /auth/me is owned by the bootstrap controller.
          onRefresh: () async {
            ref.invalidate(authControllerProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              vertical: RadhaSpacing.space16,
            ),
            children: [
              const SizedBox(height: RadhaSpacing.space8),
              _IdentityCard(user: user, tenantId: session?.tenantId),
              const SizedBox(height: RadhaSpacing.space24),
              _SectionLabel(label: l10n.profileAccount),
              _ActionRow(
                icon: Icons.storefront_outlined,
                label: l10n.profileManageStores,
                subtitle: user?.selectedStoreName,
                onTap: () => context.push(AppRoute.selectStore),
              ),
              _ActionRow(
                icon: Icons.bookmark_outline_rounded,
                label: l10n.profileSavedProducts,
                onTap: () => context.push(AppRoute.savedProducts),
              ),
              _ActionRow(
                icon: Icons.card_membership_outlined,
                label: l10n.profileSubscription,
                onTap: () => context.push(AppRoute.subscription),
              ),
              _ActionRow(
                icon: Icons.share_outlined,
                label: l10n.referrals,
                onTap: () => context.push(AppRoute.referrals),
              ),
              const SizedBox(height: RadhaSpacing.space24),
              _SectionLabel(label: l10n.profilePreferences),
              _ActionRow(
                icon: Icons.no_food_outlined,
                label: l10n.profileAllergenProfile,
                onTap: () => context.push(AppRoute.allergens),
              ),
              _ActionRow(
                icon: Icons.shopping_basket_outlined,
                label: l10n.profileShoppingList,
                onTap: () => context.push(AppRoute.shoppingList),
              ),
              _ActionRow(
                icon: Icons.language_outlined,
                label: l10n.language,
                onTap: () => context.push(AppRoute.settingsLanguage),
              ),
              const SizedBox(height: RadhaSpacing.space24),
              _SectionLabel(label: l10n.settingsAbout),
              _AboutCard(packageInfoAsync: packageInfoAsync),
              const SizedBox(height: RadhaSpacing.space24),
              const _SignOutRow(),
              const SizedBox(height: RadhaSpacing.space32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Identity header ──────────────────────────────────────────────────────

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user, required this.tenantId});

  final CurrentUser? user;
  final String? tenantId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final displayName = _displayName(user);
    final primaryRole = (user?.roles.isNotEmpty == true)
        ? user!.roles.first
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RadhaSpacing.space16),
      child: Material(
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
          side: BorderSide(color: scheme.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(RadhaSpacing.space24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(seed: displayName),
              const SizedBox(width: RadhaSpacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tenantId != null) ...[
                      const SizedBox(height: RadhaSpacing.space4),
                      Text(
                        tenantId!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (primaryRole != null) ...[
                      const SizedBox(height: RadhaSpacing.space12),
                      _RoleChip(role: primaryRole),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: RadhaSpacing.space8),
              const MorCompanion(mood: MorMood.guard, size: 64),
            ],
          ),
        ),
      ),
    );
  }

  /// Picks the best string we have for the user. The auth session today
  /// only carries `userId`, but if the API later includes a `name` field
  /// in `CurrentUser` it will surface here automatically.
  static String _displayName(CurrentUser? user) {
    if (user == null) return 'Guest';
    if (user.userId.isEmpty) return 'You';
    return user.userId;
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initial = seed.isEmpty ? '·' : seed.characters.first.toUpperCase();

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
      ),
      child: Text(
        initial,
        style: theme.textTheme.titleMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = role.isEmpty
        ? 'Member'
        : role[0].toUpperCase() + role.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RadhaSpacing.space12,
        vertical: RadhaSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─── Sectioning ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RadhaSpacing.space24,
        RadhaSpacing.space8,
        RadhaSpacing.space24,
        RadhaSpacing.space8,
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Action row ──────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = scheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(
          horizontal: RadhaSpacing.space24,
          vertical: RadhaSpacing.space12,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: RadhaSpacing.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(color: color),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── About card (version) ────────────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.packageInfoAsync});

  final AsyncValue<PackageInfo> packageInfoAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RadhaSpacing.space16),
      child: Material(
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
          side: BorderSide(color: scheme.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RadhaSpacing.space24,
            vertical: RadhaSpacing.space16,
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: RadhaSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RADHA',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    packageInfoAsync.when(
                      loading: () => Text(
                        'Loading version…',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      error: (_, _) => Text(
                        'Version unavailable',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      data: (info) => Text(
                        'Version ${info.version} (${info.buildNumber})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sign out ────────────────────────────────────────────────────────────

class _SignOutRow extends ConsumerStatefulWidget {
  const _SignOutRow();

  @override
  ConsumerState<_SignOutRow> createState() => _SignOutRowState();
}

class _SignOutRowState extends ConsumerState<_SignOutRow> {
  bool _busy = false;

  Future<void> _confirmAndSignOut() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(l10n.signOut),
          content: Text(l10n.signOutConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.signOut),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).logout();
      // The router's redirect handler routes us to /auth/otp on the next
      // refresh tick. Push it explicitly anyway so navigation feels
      // immediate even if the listener is microtask-delayed.
      if (!mounted) return;
      context.go(AppRoute.authOtp);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: _busy ? null : _confirmAndSignOut,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(
          horizontal: RadhaSpacing.space24,
          vertical: RadhaSpacing.space12,
        ),
        child: Row(
          children: [
            Icon(Icons.logout_rounded, size: 22, color: scheme.error),
            const SizedBox(width: RadhaSpacing.space16),
            Expanded(
              child: Text(
                'Sign out',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.error,
                ),
              ),
            ),
            if (_busy)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
