// Payment engine value types — framework- and SDK-agnostic so the checkout
// state machine can be unit-tested without the native Razorpay plugin.
//
// SECURITY: nothing here carries a Razorpay key/secret. The Key ID arrives in
// the server checkout response at runtime; the secret never leaves the server.

import 'package:flutter/foundation.dart';

/// Razorpay's `PAYMENT_CANCELLED` error code (user dismissed the sheet).
/// Mirrored as a plain int so the engine stays decoupled from the SDK; the
/// adapter maps the SDK constant onto this.
const int kRazorpayCancelledCode = 2;

/// Lifecycle of a single checkout attempt. Surfaced to the UI so it can show
/// the right busy / pending / terminal affordance.
enum PaymentPhase {
  idle,
  creatingOrder,
  openingCheckout,
  awaitingTerminalEvent,
  verifying,
  verified,
  cancelled,
  paymentFailed,
  verificationFailed,
  pendingConfirmation,
  timedOut,
}

/// Normalised Razorpay success payload (from `EVENT_PAYMENT_SUCCESS`).
@immutable
class RpSuccess {
  const RpSuccess({this.orderId, this.paymentId, this.signature});
  final String? orderId;
  final String? paymentId;
  final String? signature;

  bool get isComplete =>
      (orderId?.isNotEmpty ?? false) &&
      (paymentId?.isNotEmpty ?? false) &&
      (signature?.isNotEmpty ?? false);
}

/// Normalised Razorpay failure payload (from `EVENT_PAYMENT_ERROR`).
@immutable
class RpFailure {
  const RpFailure({this.code, this.message});
  final int? code;
  final String? message;

  /// User-dismissed the sheet — a cancellation, not a provider failure.
  bool get isCancellation => code == kRazorpayCancelledCode;
}

/// Normalised external-wallet selection (from `EVENT_EXTERNAL_WALLET`).
/// **Not terminal** — the SDK still fires success/error afterwards.
@immutable
class RpExternalWallet {
  const RpExternalWallet({this.walletName});
  final String? walletName;
}

/// The single, structured outcome of a checkout attempt. Replaces the old bare
/// `Future<bool>` so callers can react precisely (verified / cancelled / failed
/// / payment-received-but-unconfirmed).
sealed class CheckoutResult {
  const CheckoutResult();
}

/// Server verified the payment and activated the plan.
class CheckoutVerified extends CheckoutResult {
  const CheckoutVerified({required this.subscriptionStatus});
  final String subscriptionStatus;
}

/// User dismissed the sheet before paying. Selected plan/cycle can be retried.
class CheckoutCancelled extends CheckoutResult {
  const CheckoutCancelled();
}

/// A real failure: order creation, an invalid checkout response, a provider
/// error, or a server signature mismatch (`reason == 'verification'`).
class CheckoutFailed extends CheckoutResult {
  const CheckoutFailed({this.reason, this.code, this.message});
  final String? reason;
  final int? code;
  final String? message;
}

/// Razorpay reported success but the server could not be reached/confirmed.
/// **Never** present this as a failure — the money may have moved. The UI
/// offers a refresh/recovery path and a support reference.
class CheckoutPending extends CheckoutResult {
  const CheckoutPending({this.orderId, this.paymentId});
  final String? orderId;
  final String? paymentId;

  /// Short, support-friendly reference (order id suffix) — no PII.
  String get supportRef {
    final id = orderId ?? paymentId ?? '';
    return id.length <= 6 ? id : id.substring(id.length - 6);
  }
}
