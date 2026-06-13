// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_status_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanFeatureDto _$PlanFeatureDtoFromJson(Map<String, dynamic> json) =>
    PlanFeatureDto(
      feature: json['feature'] as String,
      limit: limitFromJson(json['limit']),
      description: json['description'] as String?,
    );

SubscriptionPlanDto _$SubscriptionPlanDtoFromJson(Map<String, dynamic> json) =>
    SubscriptionPlanDto(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: _decToDouble(json['price']),
      yearlyPrice: _decToDoubleN(json['yearlyPrice']),
      currency: json['currency'] as String? ?? 'INR',
      trialDays: (json['trialDays'] as num?)?.toInt() ?? 0,
      isPublic: json['isPublic'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      features:
          (json['features'] as List<dynamic>?)
              ?.map((e) => PlanFeatureDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

UsageFeatureStatDto _$UsageFeatureStatDtoFromJson(Map<String, dynamic> json) =>
    UsageFeatureStatDto(
      used: (json['used'] as num?)?.toInt() ?? 0,
      limit: limitFromJson(json['limit']),
      percentageUsed: json['percentageUsed'] as num? ?? 0,
    );

UsageStatsDto _$UsageStatsDtoFromJson(Map<String, dynamic> json) =>
    UsageStatsDto(
      byFeature:
          (json['byFeature'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              UsageFeatureStatDto.fromJson(e as Map<String, dynamic>),
            ),
          ) ??
          const {},
    );

SubscriptionStatusDto _$SubscriptionStatusDtoFromJson(
  Map<String, dynamic> json,
) => SubscriptionStatusDto(
  isActive: json['isActive'] as bool,
  status: json['status'] as String,
  plan: SubscriptionPlanDto.fromJson(json['plan'] as Map<String, dynamic>),
  trialDaysRemaining: (json['trialDaysRemaining'] as num?)?.toInt(),
  daysUntilRenewal: (json['daysUntilRenewal'] as num?)?.toInt(),
  features:
      (json['features'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ) ??
      const {},
  limits: json['limits'] as Map<String, dynamic>? ?? const {},
  usage: json['usage'] == null
      ? null
      : UsageStatsDto.fromJson(json['usage'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UpgradePlanRequestDtoToJson(
  UpgradePlanRequestDto instance,
) => <String, dynamic>{'planCode': instance.planCode};

Map<String, dynamic> _$CancelSubscriptionRequestDtoToJson(
  CancelSubscriptionRequestDto instance,
) => <String, dynamic>{'reason': instance.reason};
