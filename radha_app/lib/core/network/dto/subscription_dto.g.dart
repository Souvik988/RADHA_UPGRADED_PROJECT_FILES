// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionResponse _$SubscriptionResponseFromJson(
  Map<String, dynamic> json,
) => SubscriptionResponse(
  id: json['id'] as String,
  plan: json['plan'] as String,
  status: json['status'] as String,
  expiresAt: json['expiresAt'] as String?,
);

Map<String, dynamic> _$CreateSubscriptionDtoToJson(
  CreateSubscriptionDto instance,
) => <String, dynamic>{'plan': instance.plan};
