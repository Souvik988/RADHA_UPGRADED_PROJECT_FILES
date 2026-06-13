import 'package:json_annotation/json_annotation.dart';

part 'subscription_status_dto.g.dart';

/// DTOs for the canonical plural subscription surface
/// (`/api/v1/subscriptions/*`). Shapes mirror the backend exactly
/// (`server/.../types/subscription.types.ts`):
///   • plan rows carry a real UUID `id` (the checkout planId) + a `code`,
///   • numeric limits are `int`; `'unlimited'` maps to `null`,
///   • decimal prices arrive as JSON strings ("49.00") → parsed to double.
/// The server is the source of truth for features/limits/usage — the app
/// never reconstructs entitlements from a hardcoded table.

/// `number | 'unlimited'` → `int?` (null means unlimited / absent).
int? limitFromJson(Object? v) => v is num ? v.toInt() : null;

double _decToDouble(Object? v) =>
    v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);
double? _decToDoubleN(Object? v) => v == null ? null : _decToDouble(v);

/// One entitlement row on a plan.
@JsonSerializable(createToJson: false)
class PlanFeatureDto {
  const PlanFeatureDto({required this.feature, this.limit, this.description});

  final String feature;

  /// Numeric cap, or null when unlimited.
  @JsonKey(fromJson: limitFromJson)
  final int? limit;

  final String? description;

  factory PlanFeatureDto.fromJson(Map<String, dynamic> json) =>
      _$PlanFeatureDtoFromJson(json);
}

/// A sellable plan from `GET /subscriptions/plans`.
@JsonSerializable(createToJson: false)
class SubscriptionPlanDto {
  const SubscriptionPlanDto({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.price,
    this.yearlyPrice,
    this.currency = 'INR',
    this.trialDays = 0,
    this.isPublic = true,
    this.isActive = true,
    this.sortOrder = 0,
    this.features = const [],
  });

  /// Backend UUID — the value sent as `planId` to `/payments/checkout`.
  final String id;

  /// Stable code: trial / starter / growth / pro.
  final String code;
  final String name;
  final String? description;

  /// Monthly price in rupees (decimal-as-string on the wire).
  @JsonKey(fromJson: _decToDouble)
  final double price;

  /// Optional yearly price; null when the backend derives it at checkout.
  @JsonKey(fromJson: _decToDoubleN)
  final double? yearlyPrice;

  final String currency;
  final int trialDays;
  final bool isPublic;
  final bool isActive;
  final int sortOrder;
  final List<PlanFeatureDto> features;

  factory SubscriptionPlanDto.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanDtoFromJson(json);
}

/// Per-feature usage row inside [UsageStatsDto].
@JsonSerializable(createToJson: false)
class UsageFeatureStatDto {
  const UsageFeatureStatDto({
    this.used = 0,
    this.limit,
    this.percentageUsed = 0,
  });

  final int used;
  @JsonKey(fromJson: limitFromJson)
  final int? limit;
  final num percentageUsed;

  factory UsageFeatureStatDto.fromJson(Map<String, dynamic> json) =>
      _$UsageFeatureStatDtoFromJson(json);
}

/// `GET /subscriptions/usage` (also nested in status).
@JsonSerializable(createToJson: false)
class UsageStatsDto {
  const UsageStatsDto({this.byFeature = const {}});

  final Map<String, UsageFeatureStatDto> byFeature;

  factory UsageStatsDto.fromJson(Map<String, dynamic> json) =>
      _$UsageStatsDtoFromJson(json);
}

/// `GET /subscriptions/status` — the entitlement source of truth.
@JsonSerializable(createToJson: false)
class SubscriptionStatusDto {
  const SubscriptionStatusDto({
    required this.isActive,
    required this.status,
    required this.plan,
    this.trialDaysRemaining,
    this.daysUntilRenewal,
    this.features = const {},
    this.limits = const {},
    this.usage,
  });

  final bool isActive;

  /// trial / active / expired / cancelled / past_due / paused.
  final String status;
  final SubscriptionPlanDto plan;
  final int? trialDaysRemaining;
  final int? daysUntilRenewal;

  /// Server feature flags keyed by backend feature key (e.g. `advanced_analytics`).
  final Map<String, bool> features;

  /// Server limits keyed by backend feature key; values are `int` or the
  /// string `'unlimited'`.
  final Map<String, dynamic> limits;

  final UsageStatsDto? usage;

  bool hasServerFeature(String key) => features[key] == true;

  bool isUnlimited(String key) => limits[key] == 'unlimited';

  /// Numeric limit for [key], or null when unlimited/absent.
  int? limitOf(String key) {
    final v = limits[key];
    return v is num ? v.toInt() : null;
  }

  factory SubscriptionStatusDto.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStatusDtoFromJson(json);
}

/// Body for `POST /subscriptions/upgrade` (non-payment plan change).
@JsonSerializable(createFactory: false)
class UpgradePlanRequestDto {
  const UpgradePlanRequestDto({required this.planCode});
  final String planCode;
  Map<String, dynamic> toJson() => _$UpgradePlanRequestDtoToJson(this);
}

/// Body for `POST /subscriptions/cancel`.
@JsonSerializable(createFactory: false)
class CancelSubscriptionRequestDto {
  const CancelSubscriptionRequestDto({required this.reason});
  final String reason;
  Map<String, dynamic> toJson() => _$CancelSubscriptionRequestDtoToJson(this);
}
