// AI feature DTOs — `/ai/ingredients/*` (BE-40),
// `/healthy-alternatives/*` (BE-41).

// ─── Ingredient Explainer (legacy `/ai/ingredients/explain`) ─────────────
//
// Kept for the inline explainer in product_detail_screen.dart. The
// canonical surface is `IngredientExplanation` below, fed by the public
// `GET /api/v1/ingredients/:slug/explanation` endpoint (BE-40).

class IngredientExplainerRequest {
  const IngredientExplainerRequest({
    required this.ingredients,
    this.productId,
    this.userId,
  });

  final List<String> ingredients;
  final String? productId;
  final String? userId;

  Map<String, dynamic> toJson() => {
    'ingredients': ingredients,
    if (productId != null) 'productId': productId,
    if (userId != null) 'userId': userId,
  };
}

class IngredientExplainerDto {
  const IngredientExplainerDto({required this.summary, required this.entries});

  final String summary;
  final List<IngredientExplainerEntryDto> entries;

  factory IngredientExplainerDto.fromJson(Map<String, dynamic> json) =>
      IngredientExplainerDto(
        summary: json['summary'] as String,
        entries:
            (json['entries'] as List<dynamic>?)
                ?.map(
                  (e) => IngredientExplainerEntryDto.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList(growable: false) ??
            const [],
      );

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'entries': entries.map((e) => e.toJson()).toList(),
  };
}

class IngredientExplainerEntryDto {
  const IngredientExplainerEntryDto({
    required this.ingredient,
    required this.explanation,
    this.severity,
    this.tags,
  });

  final String ingredient;
  final String explanation;
  final String? severity;
  final List<String>? tags;

  factory IngredientExplainerEntryDto.fromJson(Map<String, dynamic> json) =>
      IngredientExplainerEntryDto(
        ingredient: json['ingredient'] as String,
        explanation: json['explanation'] as String,
        severity: json['severity'] as String?,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      );

  Map<String, dynamic> toJson() => {
    'ingredient': ingredient,
    'explanation': explanation,
    if (severity != null) 'severity': severity,
    if (tags != null) 'tags': tags,
  };
}

// ─── BE-40 v2 — `GET /api/v1/ingredients/:slug/explanation` ──────────────
//
// The dedicated full-screen explainer (FE-19) reads from the canonical
// per-slug endpoint. The server returns:
//
//   {
//     ingredientSlug: string,
//     description: string,
//     healthConsiderations: string,   // multi-line, one consideration per
//                                     // newline. Mobile splits into bullets.
//     confidence: 'low' | 'medium' | 'high',
//     language: 'en' | 'hi' | 'ta' | 'te' | 'bn' | 'mr',
//     generatedBy?: string,
//     generatedAt?: string (ISO-8601),
//     cached: boolean
//   }
//
// We project this into a UI-shaped DTO so screens never have to reason
// about server-side field names. The factory is forgiving — it will also
// accept a future server payload that already provides `title`, `summary`,
// or pre-split `bullets` directly, so the mobile is forward-compatible.
class IngredientExplanation {
  const IngredientExplanation({
    required this.slug,
    required this.title,
    required this.summary,
    required this.bullets,
    this.healthFlags,
    this.languageCode,
  });

  /// Canonical kebab-case slug, e.g. `palm-oil`.
  final String slug;

  /// Human-friendly title. Derived from the slug when the server
  /// doesn't supply one explicitly.
  final String title;

  /// Plain-language summary paragraph (1–2 sentences).
  final String summary;

  /// Health considerations as a list of short bullet strings.
  /// Always non-null; may be empty for low-confidence responses.
  final List<String> bullets;

  /// Optional health flags (e.g. `low-confidence`, `allergen-tree-nut`).
  /// Used to render small chips at the top of the explainer card.
  final List<String>? healthFlags;

  /// BCP-47 language tag the explanation was generated in.
  final String? languageCode;

  factory IngredientExplanation.fromJson(Map<String, dynamic> json) {
    final slug = (json['ingredientSlug'] ?? json['slug'] ?? '') as String;

    // Title preference order:
    //   1. Future-shape: server explicitly returns `title`.
    //   2. Derived from the slug — `palm-oil` → `Palm Oil`.
    final title = (json['title'] as String?) ?? _humanizeSlug(slug);

    // Summary preference: explicit `summary`, then `description`.
    final summary =
        (json['summary'] as String?) ?? (json['description'] as String?) ?? '';

    // Bullets preference order:
    //   1. Future-shape: server returns `bullets` as an array.
    //   2. `healthConsiderations` split by line (drop blanks).
    final List<String> bullets;
    final rawBullets = json['bullets'];
    if (rawBullets is List) {
      bullets = rawBullets
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    } else {
      final raw = (json['healthConsiderations'] as String?) ?? '';
      bullets = raw
          .split(RegExp(r'\r?\n'))
          .map((s) => s.replaceFirst(RegExp(r'^[\s•\-*]+'), '').trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }

    // Health flags: explicit array → confidence-derived → null.
    final List<String>? flags;
    final rawFlags = json['healthFlags'];
    if (rawFlags is List) {
      flags = rawFlags
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    } else {
      final confidence = json['confidence'] as String?;
      flags = (confidence == 'low')
          ? const ['low-confidence']
          : null;
    }

    final lang =
        (json['languageCode'] as String?) ?? (json['language'] as String?);

    return IngredientExplanation(
      slug: slug,
      title: title,
      summary: summary,
      bullets: bullets,
      healthFlags: flags,
      languageCode: lang,
    );
  }

  /// `palm-oil` → `Palm Oil`. Falls back to the empty string for an
  /// empty slug so callers can decide what to render.
  static String _humanizeSlug(String slug) {
    if (slug.isEmpty) return '';
    return slug
        .split('-')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' ');
  }
}

// ─── BE-41 — `GET /api/v1/products/:ean/alternatives` ────────────────────
//
// Each item is a healthier candidate in the same category as the source
// EAN, with a partner-rendered affiliate URL. The server returns the
// list directly (no wrapper object) — the mobile UI assembles a
// `HealthyAlternativesResponse` from the source EAN + the returned list.

class HealthyAlternative {
  const HealthyAlternative({
    required this.ean,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.healthScore,
    required this.priceInr,
    this.affiliateLink,
    this.partnerName,
  });

  final String ean;
  final String name;

  /// Brand name. Empty string when the catalogue row has no brand.
  final String brand;

  /// Image URL. Empty string when the catalogue row has no image.
  final String imageUrl;

  /// 0–100 health score, sorted descending by the server.
  final int healthScore;

  /// Display price in INR. `0` when the server doesn't provide one
  /// (the affiliate flow doesn't always quote a price).
  final num priceInr;

  /// Click-out URL with the partner's affiliate id baked in.
  final String? affiliateLink;

  /// Partner name (e.g. `amazon`, `flipkart`).
  final String? partnerName;

  factory HealthyAlternative.fromJson(Map<String, dynamic> json) {
    final score = json['healthScore'];
    final price = json['priceInr'] ?? json['price'];
    return HealthyAlternative(
      ean: (json['ean'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      brand: (json['brand'] as String?) ?? '',
      imageUrl:
          (json['imageUrl'] as String?) ??
          (json['image'] as String?) ??
          '',
      healthScore: score is num ? score.toInt() : 0,
      priceInr: price is num ? price : 0,
      affiliateLink: json['affiliateLink'] as String?,
      partnerName: json['partnerName'] as String?,
    );
  }
}

/// Mobile-side bundle of the source EAN plus the alternatives the server
/// returned. There is no wire-level wrapper today — the API hands us a
/// bare list — but the screen needs both pieces, so we keep them
/// together here. Constructed from the screen, not from JSON.
class HealthyAlternativesResult {
  const HealthyAlternativesResult({
    required this.sourceEan,
    required this.alternatives,
  });

  final String sourceEan;
  final List<HealthyAlternative> alternatives;
}

// ─── Saved Products (FE-16, BE-37) ───────────────────────────────────────
//
// A "saved product" is a product the user has bookmarked from a scan
// result. The list is upserted via `POST /api/v1/sync/saved-products`
// (sync-batch envelope, see `sync_dto.dart`). There is currently NO
// dedicated GET endpoint exposed by the server (see open question in
// the task summary) — the mobile surface degrades to an empty state.
//
// The DTO is defined here so when the GET lands, screens and providers
// already have a typed shape to consume.
class SavedProduct {
  const SavedProduct({
    required this.ean,
    required this.name,
    required this.brand,
    this.imageUrl,
    this.savedAt,
    this.expiryDate,
  });

  /// EAN/barcode. Stable identifier for routing back into scan result.
  final String ean;

  final String name;

  /// Brand name. Empty string when unknown.
  final String brand;

  /// Optional image URL.
  final String? imageUrl;

  /// ISO-8601 timestamp the product was saved at. Optional because
  /// older rows may not carry it.
  final String? savedAt;

  /// Optional ISO-8601 expiry date if the user captured one.
  final String? expiryDate;

  factory SavedProduct.fromJson(Map<String, dynamic> json) {
    return SavedProduct(
      ean: (json['ean'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      brand: (json['brand'] as String?) ?? '',
      imageUrl: json['imageUrl'] as String?,
      savedAt: json['savedAt'] as String?,
      expiryDate: json['expiryDate'] as String?,
    );
  }

  /// Body shape used by the sync-batch upsert. Matches the keys the
  /// backend repository persists. Caller wraps this inside a
  /// `SyncBatchDto` item with its own idempotency key.
  Map<String, dynamic> toJson() => {
    'ean': ean,
    'name': name,
    'brand': brand,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (savedAt != null) 'savedAt': savedAt,
    if (expiryDate != null) 'expiryDate': expiryDate,
  };
}
