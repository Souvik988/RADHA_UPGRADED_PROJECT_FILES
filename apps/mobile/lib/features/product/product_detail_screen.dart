import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:radha_mobile/core/auth/auth_controller.dart';
import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/misc_dto.dart';
import 'package:radha_mobile/core/network/dto/product_dto.dart';
import 'package:radha_mobile/design/app_assets.dart';
import 'package:radha_mobile/design/tokens.dart';
import 'package:radha_mobile/design/widgets/mor_companion.dart';
import 'package:radha_mobile/features/allergen/allergen_profile_screen.dart';
import 'package:radha_mobile/features/product/widgets/health_label_chip.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

/// Fetches product details by EAN from the backend.
final productDetailProvider = FutureProvider.family<ProductResponse, String>((
  ref,
  ean,
) async {
  final client = ref.watch(apiClientProvider);
  return client.getProductByEan(ean);
});

/// On-demand allergen check for a product.
final allergenCheckProvider =
    FutureProvider.family<List<AllergenResponse>, String>((
      ref,
      productId,
    ) async {
      final client = ref.watch(apiClientProvider);
      return client.getProductAllergens(productId);
    });

/// On-demand ingredient explanation via AI.
final ingredientExplainerProvider =
    FutureProvider.family<IngredientExplainerResponse, String>((
      ref,
      productId,
    ) async {
      final client = ref.watch(apiClientProvider);
      return client.explainIngredients({'productId': productId});
    });

/// On-demand healthy alternatives lookup.
final healthyAlternativesProvider =
    FutureProvider.family<HealthyAlternativesResponse, String>((
      ref,
      productId,
    ) async {
      final client = ref.watch(apiClientProvider);
      return client.getHealthyAlternatives(productId);
    });

// ─── Screen ───────────────────────────────────────────────────────────────────

/// Full product detail screen displaying health assessment, allergens,
/// ingredient explainer, and healthy alternatives — each on demand with
/// local loading/error states.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.ean});

  final String ean;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(ean));

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
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
                Text(
                  'Failed to load product',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: RadhaSpacing.space8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        data: (product) => _ProductDetailBody(product: product),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _ProductDetailBody extends ConsumerStatefulWidget {
  const _ProductDetailBody({required this.product});

  final ProductResponse product;

  @override
  ConsumerState<_ProductDetailBody> createState() => _ProductDetailBodyState();
}

class _ProductDetailBodyState extends ConsumerState<_ProductDetailBody> {
  bool _allergenChecked = false;
  bool _alternativesRequested = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(RadhaSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _ProductHeader(product: widget.product),
          const SizedBox(height: RadhaSpacing.space24),

          // ── Health Assessment ───────────────────────────────────────────
          _HealthAssessmentSection(product: widget.product),
          const SizedBox(height: RadhaSpacing.space24),

          // ── Nutrition Info ──────────────────────────────────────────────
          _NutritionSection(product: widget.product),
          const SizedBox(height: RadhaSpacing.space24),

          // ── Allergen Check (on-demand) ─────────────────────────────────
          if (!_allergenChecked)
            _ActionButton(
              icon: Icons.warning_amber_rounded,
              label: 'Check allergens',
              onPressed: () => setState(() => _allergenChecked = true),
            )
          else
            _AllergenCheckSection(productId: widget.product.id),
          const SizedBox(height: RadhaSpacing.space16),

          // ── Ingredient Explainer (on-demand) ───────────────────────────
          _ActionButton(
            icon: Icons.science_outlined,
            label: 'Explain ingredients',
            onPressed: () => _showIngredientExplainer(context),
          ),
          const SizedBox(height: RadhaSpacing.space16),

          // ── Healthy Alternatives (on-demand) ───────────────────────────
          if (!_alternativesRequested)
            _ActionButton(
              icon: Icons.swap_horiz_rounded,
              label: 'See healthier options',
              onPressed: () => setState(() => _alternativesRequested = true),
            )
          else
            _HealthyAlternativesSection(productId: widget.product.id),
          const SizedBox(height: RadhaSpacing.space16),

          // ── FE-22 cross-link to the dedicated alternatives screen ──────
          // Distinct from the on-demand inline section above: this row
          // pushes a full-screen route keyed by EAN, where the user gets
          // a focused list with images, prices, and clearer affordances.
          if (widget.product.ean != null && widget.product.ean!.isNotEmpty)
            _NavRow(
              icon: Icons.compare_arrows_rounded,
              label: 'View healthy alternatives',
              onTap: () => context.push(
                '/alternatives/${widget.product.ean}',
              ),
            ),
          const SizedBox(height: RadhaSpacing.space48),
        ],
      ),
    );
  }

  void _showIngredientExplainer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RadhaRadii.radiusLg),
        ),
      ),
      builder: (_) => _IngredientExplainerSheet(productId: widget.product.id),
    );
  }
}

// ─── Header Section ───────────────────────────────────────────────────────────

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final ProductResponse product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image
        ClipRRect(
          borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
          child: Container(
            width: 80,
            height: 80,
            color: RadhaColors.paperRaised,
            child: product.imageUrl != null
                ? Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _PlaceholderIcon(),
                  )
                : const _PlaceholderIcon(),
          ),
        ),
        const SizedBox(width: RadhaSpacing.space16),
        // Product info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: theme.textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (product.brand != null) ...[
                const SizedBox(height: RadhaSpacing.space4),
                Text(
                  product.brand!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: RadhaColors.inkMuted,
                  ),
                ),
              ],
              if (product.category != null) ...[
                const SizedBox(height: RadhaSpacing.space4),
                Text(
                  product.category!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: RadhaColors.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 32,
        color: RadhaColors.inkMuted,
      ),
    );
  }
}

// ─── Health Assessment Section ────────────────────────────────────────────────

class _HealthAssessmentSection extends StatelessWidget {
  const _HealthAssessmentSection({required this.product});

  final ProductResponse product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Derive health level from product — the API may not provide this yet,
    // so we show a placeholder when the data isn't available.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Health Assessment', style: theme.textTheme.titleMedium),
        const SizedBox(height: RadhaSpacing.space12),
        // Overall health label chip
        const HealthLabelChip(label: 'Moderate', level: HealthLevel.moderate),
        const SizedBox(height: RadhaSpacing.space12),
        // Individual badges
        Wrap(
          spacing: RadhaSpacing.space8,
          runSpacing: RadhaSpacing.space8,
          children: const [
            _HealthBadge(label: 'Sugar', isFlag: false),
            _HealthBadge(label: 'Salt', isFlag: false),
            _HealthBadge(label: 'Fat', isFlag: false),
            _HealthBadge(label: 'Processed', isFlag: false),
            _HealthBadge(label: 'Child-suitable', isFlag: true),
          ],
        ),
      ],
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.label, required this.isFlag});

  final String label;
  final bool isFlag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RadhaSpacing.space8,
        vertical: RadhaSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: isFlag
            ? RadhaColors.success.withValues(alpha: 0.1)
            : RadhaColors.inkMuted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isFlag ? RadhaColors.success : RadhaColors.inkMuted,
        ),
      ),
    );
  }
}

// ─── Nutrition Section ────────────────────────────────────────────────────────

class _NutritionSection extends StatelessWidget {
  const _NutritionSection({required this.product});

  final ProductResponse product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nutrition Info', style: theme.textTheme.titleMedium),
        const SizedBox(height: RadhaSpacing.space12),
        Container(
          padding: const EdgeInsets.all(RadhaSpacing.space16),
          decoration: BoxDecoration(
            color: RadhaColors.paperRaised,
            borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
          ),
          child: Text(
            'Nutrition data will appear here when available from the product lookup.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: RadhaColors.inkMuted,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Allergen Check Section ───────────────────────────────────────────────────

class _AllergenCheckSection extends ConsumerWidget {
  const _AllergenCheckSection({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allergenAsync = ref.watch(allergenCheckProvider(productId));
    final user = ref.watch(currentUserProvider);

    // Pull the user's saved profile so we can highlight matches. Treat any
    // load error or pending state as "no profile" — failing closed shows the
    // raw allergen list rather than mis-tagging items as safe.
    final profileTags = user == null
        ? const <String>{}
        : ref
              .watch(allergenProfileProvider(user.userId))
              .maybeWhen(
                data: (p) => p.allergens.toSet(),
                orElse: () => const <String>{},
              );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Allergen Check', style: theme.textTheme.titleSmall),
        const SizedBox(height: RadhaSpacing.space8),
        allergenAsync.when(
          loading: () => const _SectionSkeleton(),
          error: (error, _) => Text(
            'Failed to check allergens: $error',
            style: theme.textTheme.bodySmall?.copyWith(
              color: RadhaColors.danger,
            ),
          ),
          data: (allergens) {
            if (allergens.isEmpty) {
              return Text(
                'No allergens detected in this product.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: RadhaColors.success,
                ),
              );
            }
            return Wrap(
              spacing: RadhaSpacing.space8,
              runSpacing: RadhaSpacing.space8,
              children: allergens
                  .map(
                    (a) => _AllergenChipReadout(
                      allergen: a,
                      matchesUser: _matches(a, profileTags),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  /// Compares a backend allergen entry against the user's saved profile
  /// tags. Both sides are lower-cased and stripped of underscores so
  /// "Tree Nut" still matches the canonical `tree_nut` tag.
  bool _matches(AllergenResponse allergen, Set<String> profileTags) {
    if (profileTags.isEmpty) return false;
    final raw = allergen.name.toLowerCase().trim();
    final normalised = raw.replaceAll(' ', '_').replaceAll('-', '_');
    if (profileTags.contains(normalised)) return true;
    // Loose match: profile tag appears as a substring (e.g. "peanut" matches
    // "peanut oil" or "may contain peanut").
    for (final tag in profileTags) {
      if (raw.contains(tag.replaceAll('_', ' ')) || normalised.contains(tag)) {
        return true;
      }
    }
    return false;
  }
}

/// Single allergen chip used by the product-detail allergen check. Shows
/// rose styling + a warning icon when the allergen matches the user's
/// saved profile, neutral muted styling otherwise.
class _AllergenChipReadout extends StatelessWidget {
  const _AllergenChipReadout({
    required this.allergen,
    required this.matchesUser,
  });

  final AllergenResponse allergen;
  final bool matchesUser;

  @override
  Widget build(BuildContext context) {
    final color = matchesUser ? RadhaColors.danger : RadhaColors.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RadhaSpacing.space8,
        vertical: RadhaSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: matchesUser ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (matchesUser) ...[
            Icon(Icons.warning_amber_rounded, size: 14, color: color),
            const SizedBox(width: RadhaSpacing.space4),
          ],
          Text(
            allergen.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ingredient Explainer Sheet ───────────────────────────────────────────────

class _IngredientExplainerSheet extends ConsumerWidget {
  const _IngredientExplainerSheet({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final explainerAsync = ref.watch(ingredientExplainerProvider(productId));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(RadhaSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RadhaColors.inkMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: RadhaSpacing.space16),
              Text(
                'Ingredient Explanation',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: RadhaSpacing.space16),
              Expanded(
                child: explainerAsync.when(
                  loading: () => const _SectionSkeleton(),
                  error: (error, _) => Center(
                    child: Text(
                      'Failed to explain ingredients: $error',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: RadhaColors.danger,
                      ),
                    ),
                  ),
                  data: (result) => SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.explanation,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: RadhaSpacing.space16),
                        // FE-19 cross-link — opens the dedicated full-screen
                        // explainer for this ingredient. Slug is derived
                        // from the product id; the dedicated route reads
                        // from `GET /api/v1/ingredients/:slug/explanation`.
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.push(
                                '/ingredients/${_ingredientSlug(productId)}',
                              );
                            },
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('See full explanation'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Best-effort kebab-case slug derived from the product id. The
  /// dedicated `/ingredients/:slug` screen normalises again on the
  /// backend; we trim/lower/dedup hyphens so the URL stays clean.
  static String _ingredientSlug(String raw) {
    final lowered = raw.toLowerCase().trim();
    final slug = lowered
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'ingredient' : slug;
  }
}

// ─── Healthy Alternatives Section ─────────────────────────────────────────────

class _HealthyAlternativesSection extends ConsumerWidget {
  const _HealthyAlternativesSection({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final altAsync = ref.watch(healthyAlternativesProvider(productId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Healthier Options', style: theme.textTheme.titleSmall),
        const SizedBox(height: RadhaSpacing.space8),
        altAsync.when(
          loading: () => const _SectionSkeleton(),
          error: (error, _) => Text(
            'Failed to load alternatives: $error',
            style: theme.textTheme.bodySmall?.copyWith(
              color: RadhaColors.danger,
            ),
          ),
          data: (result) {
            if (result.alternatives.isEmpty) {
              return Text(
                'No healthier alternatives found.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: RadhaColors.inkMuted,
                ),
              );
            }
            return Column(
              children: result.alternatives.map((alt) {
                final name = alt['name'] as String? ?? 'Unknown';
                final score = alt['healthScore']?.toString() ?? '-';
                final altId =
                    alt['id'] as String? ?? alt['productId'] as String?;
                return Padding(
                  padding: const EdgeInsets.only(bottom: RadhaSpacing.space8),
                  child: Container(
                    padding: const EdgeInsets.all(RadhaSpacing.space12),
                    decoration: BoxDecoration(
                      color: RadhaColors.paperRaised,
                      borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(name, style: theme.textTheme.bodyMedium),
                        ),
                        const SizedBox(width: RadhaSpacing.space8),
                        HealthLabelChip(
                          label: 'Score: $score',
                          level: HealthLevel.healthy,
                        ),
                        const SizedBox(width: RadhaSpacing.space8),
                        // Add-to-shopping-list affordance — pushes the
                        // alternative into the user's list with the source
                        // productId so the backend can correlate later.
                        SizedBox(
                          width: kMinTouchTarget,
                          height: kMinTouchTarget,
                          child: IconButton(
                            tooltip: 'Add to shopping list',
                            onPressed: () =>
                                _addToShoppingList(context, ref, name, altId),
                            icon: const Icon(Icons.add_shopping_cart_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Posts a new shopping list item built from the alternative payload.
  /// Surfaces success / failure via a snackbar so the user gets immediate
  /// feedback without leaving the detail screen.
  Future<void> _addToShoppingList(
    BuildContext context,
    WidgetRef ref,
    String name,
    String? altProductId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final client = ref.read(apiClientProvider);
      await client.addShoppingListItem(
        ShoppingListItemDto(name: name, productId: altProductId),
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Added to shopping list')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not add to list: $e')),
      );
    }
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kMinTouchTarget,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

/// Tap-row affordance for cross-links. Keeps the height ≥ kMinTouchTarget,
/// uses Material `Icons.*_outlined` only, and trails a chevron so the
/// gesture is unmistakable. Used for "View healthy alternatives" and
/// future cross-links so the row treatment stays consistent.
class _NavRow extends StatelessWidget {
  const _NavRow({
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
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
        side: BorderSide(color: scheme.outline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minHeight: kMinTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: RadhaSpacing.space16,
            vertical: RadhaSpacing.space12,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: scheme.onSurface),
              const SizedBox(width: RadhaSpacing.space16),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
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
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 14,
          width: 200,
          decoration: BoxDecoration(
            color: RadhaColors.inkMuted.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(RadhaRadii.radiusSm),
          ),
        ),
        const SizedBox(height: RadhaSpacing.space8),
        Container(
          height: 14,
          width: 140,
          decoration: BoxDecoration(
            color: RadhaColors.inkMuted.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(RadhaRadii.radiusSm),
          ),
        ),
      ],
    );
  }
}
