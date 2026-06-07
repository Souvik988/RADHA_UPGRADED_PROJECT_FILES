import 'package:json_annotation/json_annotation.dart';

part 'subscription_dto.g.dart';

@JsonSerializable(createToJson: false)
class SubscriptionResponse {
  const SubscriptionResponse({
    required this.id,
    required this.plan,
    required this.status,
    this.expiresAt,
  });

  final String id;
  final String plan;
  final String status;
  final String? expiresAt;

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionResponseFromJson(json);
}

@JsonSerializable(createFactory: false)
class CreateSubscriptionDto {
  const CreateSubscriptionDto({required this.plan});
  final String plan;

  Map<String, dynamic> toJson() => _$CreateSubscriptionDtoToJson(this);
}
