import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/app_assets.dart';
import '../../design/tokens.dart';
import '../../design/widgets/mor_companion.dart';
import 'app_router.dart';

/// Branded 404 surface for GoRouter's `errorBuilder`.
///
/// Replaces the default bare Material scaffold: Mor (concern mood) + warm copy
/// + a single clear way back home, all on brand tokens. A dead-end route never
/// drops the user onto an off-brand grey error page.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.location});

  /// The unmatched location, shown only as muted fine print for debugging.
  final String? location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(RadhaSpacing.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MorCompanion(
                  mood: MorMood.concern,
                  size: 120,
                  semanticLabel: 'Page not found',
                ),
                const SizedBox(height: RadhaSpacing.space24),
                Text(
                  'This page wandered off',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: RadhaSpacing.space8),
                Text(
                  "We couldn't find what you were looking for. Let's get you "
                  'back home.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: RadhaSpacing.space24),
                FilledButton(
                  onPressed: () => context.go(AppRoute.home),
                  child: const Text('Back to home'),
                ),
                if (location != null && location!.isNotEmpty) ...[
                  const SizedBox(height: RadhaSpacing.space24),
                  Text(
                    location!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
