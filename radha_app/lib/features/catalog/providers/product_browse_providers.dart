import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:radha_app/core/network/api_client.dart';
import 'package:radha_app/core/network/dto/catalog_dto.dart';
import 'package:radha_app/features/catalog/data/launch_catalog.dart';

/// Browse sort order — backed by the server `?sort=` param (`health` = best
/// rating first, `name` = A→Z) and applied to the bundled launch catalog too.
enum CatalogSort { health, name }

extension CatalogSortX on CatalogSort {
  String get wire => this == CatalogSort.health ? 'health' : 'name';
  String get label => this == CatalogSort.health ? 'Healthiest' : 'A–Z';
}

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Veg status for the "Veg only" filter / dot. Honours an explicit
/// [LaunchProduct.isVeg] override, else derives it: non-food categories are
/// N/A (null), eggs are non-veg, all other packaged food defaults to veg.
bool? vegStatusForLaunch(LaunchProduct p) {
  if (p.isVeg != null) return p.isVeg;
  const nonFood = {'personal-care', 'household'};
  if (nonFood.contains(p.categoryId)) return null;
  const nonVeg = {'farm-eggs'};
  if (nonVeg.contains(p.slug)) return false;
  return true;
}

/// Unified browse card model — a curated launch product, a server catalog row,
/// or both merged by EAN. Carries everything the grid + detail handoff need.
@immutable
class BrowseProduct {
  const BrowseProduct({
    required this.routeKey,
    required this.name,
    this.ean,
    this.brand,
    this.netWeight,
    this.assetImage,
    this.networkImage,
    this.healthScore,
    this.healthGrade,
    this.isVeg,
    this.serverItem,
  });

  /// Navigation key for the detail route — the real EAN when known, else slug.
  final String routeKey;
  final String? ean;
  final String name;
  final String? brand;
  final String? netWeight;

  /// Bundled pack-shot (offline, premium) — preferred when present.
  final String? assetImage;

  /// Server/CDN image — used when there's no bundled asset.
  final String? networkImage;

  final num? healthScore;
  final String? healthGrade;
  final bool? isVeg;

  /// The server row when this product came from `/catalog` — passed to the
  /// detail screen so it can show the real health rating without a refetch.
  final CatalogProductItem? serverItem;

  factory BrowseProduct.fromLaunch(LaunchProduct p) => BrowseProduct(
    routeKey: p.ean ?? p.slug,
    ean: p.ean,
    name: p.name,
    brand: p.brand,
    netWeight: p.netWeight,
    assetImage: p.asset,
    isVeg: vegStatusForLaunch(p),
  );

  factory BrowseProduct.fromServer(CatalogProductItem c) {
    final launch = launchProductByEan(c.ean);
    return BrowseProduct(
      routeKey: c.ean,
      ean: c.ean,
      name: c.name,
      brand: c.brand,
      netWeight: launch?.netWeight,
      assetImage: launch?.asset,
      networkImage: c.imageUrl,
      healthScore: c.healthScore,
      healthGrade: c.healthGrade,
      isVeg: launch == null ? null : vegStatusForLaunch(launch),
      serverItem: c,
    );
  }
}

/// Browse state for one category: the fixed bundled launch list + the server
/// rows accumulated across cursor pages. [products] is the merged, de-duped
/// view the grid renders.
@immutable
class CategoryBrowseState {
  const CategoryBrowseState({
    required this.launch,
    required this.server,
    required this.cursor,
    required this.hasMore,
    required this.loadingMore,
  });

  final List<LaunchProduct> launch;
  final List<CatalogProductItem> server;
  final String? cursor;
  final bool hasMore;
  final bool loadingMore;

  /// Launch products first (curated/offline), with server rows merged in: a
  /// server row that shares an EAN with a launch product replaces it (it adds
  /// the real health rating but keeps the bundled image); server-only rows
  /// append after.
  List<BrowseProduct> get products {
    final serverByEan = {for (final s in server) s.ean: s};
    final out = <BrowseProduct>[];
    final usedEans = <String>{};
    for (final p in launch) {
      final s = p.ean == null ? null : serverByEan[p.ean];
      if (s != null) {
        out.add(BrowseProduct.fromServer(s));
        usedEans.add(s.ean);
      } else {
        out.add(BrowseProduct.fromLaunch(p));
      }
    }
    for (final s in server) {
      if (usedEans.contains(s.ean)) continue;
      out.add(BrowseProduct.fromServer(s));
    }
    return out;
  }

  CategoryBrowseState copyWith({
    List<CatalogProductItem>? server,
    Object? cursor = _sentinel,
    bool? hasMore,
    bool? loadingMore,
  }) => CategoryBrowseState(
    launch: launch,
    server: server ?? this.server,
    cursor: identical(cursor, _sentinel) ? this.cursor : cursor as String?,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );

  static const _sentinel = Object();
}

/// Cursor-paginated, offline-first browse controller for a `(categorySlug,
/// sort)` pair. Always seeds from the bundled launch catalog so the grid is
/// populated instantly/offline; best-effort enriches with server `/catalog`
/// rows (real health-sorted, paginated) when reachable. A changed sort is a new
/// family arg → automatic rebuild.
class CategoryBrowseController
    extends
        AutoDisposeFamilyAsyncNotifier<
          CategoryBrowseState,
          (String, CatalogSort)
        > {
  static const _pageSize = 20;
  String? _categoryUuid;

  @override
  Future<CategoryBrowseState> build((String, CatalogSort) arg) async {
    final (slug, sort) = arg;
    final launch = launchProductsForCategory(slug);

    // Best-effort server enrich. The catalog API filters by category *UUID*,
    // so resolve it from /catalog/categories (slugs differ from the home ids,
    // e.g. `biscuits` ↔ `biscuits-snacks`). Any failure (offline / empty DB)
    // degrades silently to the launch catalog — never an error screen.
    List<CatalogProductItem> server = const [];
    String? cursor;
    var hasMore = false;
    try {
      final cats = await ref.watch(catalogCategoriesProvider.future);
      _categoryUuid = _matchCategoryId(cats, slug);
      if (_categoryUuid != null) {
        final page = await ref
            .read(apiClientProvider)
            .getCatalogProducts(
              category: _categoryUuid,
              sort: sort.wire,
              limit: _pageSize,
            );
        server = page.items;
        cursor = page.nextCursor;
        hasMore = page.nextCursor != null;
      }
    } catch (_) {
      // Offline / catalog not yet seeded — launch catalog stands alone.
    }

    return CategoryBrowseState(
      launch: launch,
      server: server,
      cursor: cursor,
      hasMore: hasMore,
      loadingMore: false,
    );
  }

  /// Append the next server page. No-op when there's nothing more, we're
  /// already loading, or the category couldn't be resolved. Errors keep the
  /// current list intact.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.hasMore || current.loadingMore || _categoryUuid == null) {
      return;
    }

    state = AsyncValue.data(current.copyWith(loadingMore: true));
    try {
      final (_, sort) = arg;
      final client = ref.read(apiClientProvider);
      final page = await client.getCatalogProducts(
        category: _categoryUuid,
        sort: sort.wire,
        cursor: current.cursor,
        limit: _pageSize,
      );
      state = AsyncValue.data(
        current.copyWith(
          server: [...current.server, ...page.items],
          cursor: page.nextCursor,
          hasMore: page.nextCursor != null,
          loadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(
        current.copyWith(loadingMore: false, hasMore: false),
      );
    }
  }

  /// Match a home category id (e.g. `biscuits`) to a server catalog category
  /// (e.g. slug `biscuits-snacks`) by normalised slug/name containment.
  String? _matchCategoryId(List<CatalogCategory> cats, String slug) {
    final needle = _norm(slug);
    for (final c in cats) {
      final s = _norm(c.slug);
      final n = _norm(c.name);
      if (s == needle ||
          n == needle ||
          s.contains(needle) ||
          needle.contains(s) ||
          n.contains(needle)) {
        return c.id;
      }
    }
    return null;
  }
}

/// Global catalog categories, cached across browse screens. Switching between
/// categories shouldn't refetch this small, rarely-changing list — so a
/// successful fetch is `keepAlive`d. A failure (offline / catalog not seeded)
/// returns an empty list and is NOT cached, so it retries on the next open;
/// the bundled launch catalog covers browse in the meantime regardless.
final catalogCategoriesProvider =
    FutureProvider.autoDispose<List<CatalogCategory>>((ref) async {
      try {
        final cats = await ref.watch(apiClientProvider).getCatalogCategories();
        ref.keepAlive();
        return cats;
      } catch (_) {
        return const <CatalogCategory>[];
      }
    });

final categoryBrowseProvider = AsyncNotifierProvider.autoDispose
    .family<
      CategoryBrowseController,
      CategoryBrowseState,
      (String, CatalogSort)
    >(CategoryBrowseController.new);

/// One curated launch product per category (manifest order) — a varied,
/// always-available spread for the home "Featured" rail when the server catalog
/// is empty/offline.
List<BrowseProduct> _launchFeatured() {
  final byCategory = <String, BrowseProduct>{};
  for (final p in kLaunchCatalog) {
    byCategory.putIfAbsent(p.categoryId, () => BrowseProduct.fromLaunch(p));
  }
  return byCategory.values.toList(growable: false);
}

/// Products for the consumer home "Featured" rail.
///
/// Prefers REAL health-sorted rows from `/catalog` (best-rated first) — so once
/// the catalog is seeded the rail surfaces genuinely top-rated products — then
/// pads with curated launch products so the rail is populated offline / day one
/// (deduped by EAN, capped). Health pills render only where a real rating
/// exists; unrated launch products simply show no pill (never a fabricated
/// score). Any failure falls back to the launch spread — never an error UI.
final featuredProductsProvider = FutureProvider.autoDispose<List<BrowseProduct>>(
  (ref) async {
    const max = 12;
    final launchPicks = _launchFeatured();

    List<BrowseProduct> server = const [];
    try {
      final page = await ref
          .watch(apiClientProvider)
          .getCatalogProducts(sort: CatalogSort.health.wire, limit: max);
      server = page.items.map(BrowseProduct.fromServer).toList();
      ref.keepAlive();
    } catch (_) {
      // Offline / catalog not yet seeded — the launch spread carries the rail.
    }

    final out = <BrowseProduct>[...server];
    final seen = {for (final p in server) p.ean};
    for (final p in launchPicks) {
      if (out.length >= max) break;
      if (p.ean != null && seen.contains(p.ean)) continue;
      out.add(p);
    }
    return out.take(max).toList(growable: false);
  },
);

/// Catalog search results for a free-text [query] across the whole catalog.
///
/// Offline-first: matches the bundled launch catalog by name/brand instantly,
/// and merges server `/catalog?q=` rows (real, health-sorted) when reachable —
/// deduped by EAN/name. Returns empty for queries shorter than 2 chars (the
/// screen shows a "type to search" prompt instead). Server failure degrades to
/// the launch matches; never an error UI.
final catalogSearchProvider = FutureProvider.autoDispose
    .family<List<BrowseProduct>, String>((ref, query) async {
      final q = query.trim();
      if (q.length < 2) return const <BrowseProduct>[];
      final ql = q.toLowerCase();

      final launchMatches = kLaunchCatalog
          .where(
            (p) =>
                p.name.toLowerCase().contains(ql) ||
                (p.brand?.toLowerCase().contains(ql) ?? false),
          )
          .map(BrowseProduct.fromLaunch)
          .toList();

      List<BrowseProduct> server = const [];
      try {
        final page = await ref
            .watch(apiClientProvider)
            .getCatalogProducts(q: q, sort: CatalogSort.health.wire, limit: 30);
        server = page.items.map(BrowseProduct.fromServer).toList();
      } catch (_) {
        // Offline / catalog not seeded — launch matches stand alone.
      }

      // Server rows (real) first, then launch matches not already covered.
      final out = <BrowseProduct>[...server];
      final seenEan = {for (final p in server) p.ean};
      final seenName = {for (final p in server) p.name.toLowerCase()};
      for (final p in launchMatches) {
        if (p.ean != null && seenEan.contains(p.ean)) continue;
        if (seenName.contains(p.name.toLowerCase())) continue;
        out.add(p);
      }
      return out;
    });
