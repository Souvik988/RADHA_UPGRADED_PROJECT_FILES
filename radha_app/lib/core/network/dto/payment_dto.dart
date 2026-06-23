import 'package:json_annotation/json_annotation.dart';

part 'payment_dto.g.dart';

// ─── Checkout — request ───────────────────────────────────────────────────

/// Body for `POST /api/v1/payments/checkout`.
///
/// Server resolves the price from `planId` + `billingCycle`, creates a
/// Razorpay order, and returns the metadata the client needs to launch
/// the native checkout sheet.
@JsonSerializable(createFactory: false)
class CreateCheckoutDto {
  const CreateCheckoutDto({
    required this.planId,
    required this.billingCycle,
  });

  final String planId;
  final String billingCycle;

  Map<String, dynamic> toJson() => _$CreateCheckoutDtoToJson(this);
}

// ─── Checkout — response ──────────────────────────────────────────────────

/// Prefill values sent into the Razorpay sheet so the user doesn't have
/// to retype identity. Each field is optional — the server omits unknowns.
@JsonSerializable(createToJson: false)
class CheckoutPrefill {
  const CheckoutPrefill({this.name, this.email, this.contact});

  final String? name;
  final String? email;
  final String? contact;

  factory CheckoutPrefill.fromJson(Map<String, dynamic> json) =>
      _$CheckoutPrefillFromJson(json);
}

/// Response payload for `POST /api/v1/payments/checkout`.
///
/// `amountPaise` is in the smallest currency unit (₹1 = 100 paise) — Razorpay
/// expects it that way and the client passes it through unchanged.
@JsonSerializable(createToJson: false)
class CheckoutResponse {
  const CheckoutResponse({
    required this.razorpayOrderId,
    required this.keyId,
    required this.amountPaise,
    required this.currency,
    required this.prefill,
  });

  final String razorpayOrderId;
  final String keyId;
  final int amountPaise;
  final String currency;
  final CheckoutPrefill prefill;

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckoutResponseFromJson(json);
}

// ─── Verify — request ─────────────────────────────────────────────────────

/// Body for `POST /api/v1/payments/verify`.
///
/// All three fields come from the `PaymentSuccessResponse` returned by
/// `Razorpay.EVENT_PAYMENT_SUCCESS`. The server re-computes the HMAC and
/// activates the subscription on a match.
@JsonSerializable(createFactory: false)
class VerifyPaymentDto {
  const VerifyPaymentDto({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  Map<String, dynamic> toJson() => _$VerifyPaymentDtoToJson(this);
}

// ─── Verify — response ────────────────────────────────────────────────────

/// Response payload for `POST /api/v1/payments/verify`.
@JsonSerializable(createToJson: false)
class VerifyPaymentResponse {
  const VerifyPaymentResponse({
    required this.success,
    required this.subscriptionStatus,
  });

  final bool success;
  final String subscriptionStatus;

  factory VerifyPaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$VerifyPaymentResponseFromJson(json);
}
