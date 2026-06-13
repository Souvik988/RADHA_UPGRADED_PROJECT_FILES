// Checkout state machine — the payment "engine".
//
// Pure Dart (no Flutter widgets) so it is fully unit-testable with a fake
// ApiClient + fake RazorpayAdapter. Fixes the defects of the old bare-bool flow:
//   • validates the checkout response before opening the sheet,
//   • external-wallet selection is NOT terminal,
//   • a single terminal event wins (duplicate callbacks ignored),
//   • cancellation is distinct from provider failure,
//   • provider-success-but-server-unconfirmed → pending (never "failed"),
//   • a bounded timeout,
//   • a structured CheckoutResult (not a bool).

import 'dart:async';

import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/payment_dto.dart';

import 'checkout_models.dart';
import 'razorpay_adapter.dart';

typedef PhaseListener = void Function(PaymentPhase phase);

class CheckoutEngine {
  CheckoutEngine({
    required ApiClient api,
    required RazorpayAdapter Function() adapterFactory,
    Duration timeout = const Duration(minutes: 5),
  }) : _api = api,
       _adapterFactory = adapterFactory,
       _timeout = timeout;

  final ApiClient _api;
  final RazorpayAdapter Function() _adapterFactory;
  final Duration _timeout;

  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Run one checkout attempt. [planId] MUST be the backend plan UUID (a plan
  /// *code* like "starter" is rejected up-front, before any network call).
  Future<CheckoutResult> run({
    required String planId,
    required String billingCycle,
    PhaseListener? onPhase,
  }) async {
    void phase(PaymentPhase p) => onPhase?.call(p);

    // ── Input guards (catch the code-as-UUID regression locally) ────────────
    if (!_uuid.hasMatch(planId)) {
      phase(PaymentPhase.paymentFailed);
      return const CheckoutFailed(
        reason: 'invalid_plan',
        message: 'This plan can’t be purchased right now. Please reopen plans.',
      );
    }
    if (billingCycle != 'monthly' && billingCycle != 'yearly') {
      phase(PaymentPhase.paymentFailed);
      return const CheckoutFailed(
        reason: 'invalid_cycle',
        message: 'Please choose a monthly or yearly cycle.',
      );
    }

    // ── 1. Create the Razorpay order on the server ──────────────────────────
    phase(PaymentPhase.creatingOrder);
    final CheckoutResponse checkout;
    try {
      checkout = await _api.createCheckout(
        CreateCheckoutDto(planId: planId, billingCycle: billingCycle),
      );
    } catch (_) {
      phase(PaymentPhase.paymentFailed);
      return const CheckoutFailed(
        reason: 'create_order',
        message: 'Could not start checkout. Please try again.',
      );
    }

    // ── 2. Validate before opening the native sheet ─────────────────────────
    final invalid = _validateCheckout(checkout);
    if (invalid != null) {
      phase(PaymentPhase.paymentFailed);
      return invalid;
    }

    // ── 3. Open the sheet; await exactly one terminal event ─────────────────
    final adapter = _adapterFactory();
    final completer = Completer<CheckoutResult>();
    var settled = false;
    // Latched on the first *terminal* callback (success/error) so a duplicate
    // never triggers a second verify. External wallet does not latch it.
    var terminalStarted = false;
    Timer? timeoutTimer;

    void settle(CheckoutResult r) {
      if (settled) return;
      settled = true;
      timeoutTimer?.cancel();
      if (!completer.isCompleted) completer.complete(r);
    }

    // External wallet is informational — keep waiting for success/error.
    adapter.onExternalWallet = (_) => phase(PaymentPhase.awaitingTerminalEvent);

    adapter.onError = (f) {
      if (terminalStarted) return;
      terminalStarted = true;
      if (f.isCancellation) {
        settle(const CheckoutCancelled());
      } else {
        settle(
          CheckoutFailed(reason: 'provider', code: f.code, message: f.message),
        );
      }
    };

    adapter.onSuccess = (s) async {
      if (terminalStarted) return;
      terminalStarted = true;
      if (!s.isComplete) {
        settle(
          const CheckoutFailed(
            reason: 'incomplete_response',
            message: 'The payment response was incomplete.',
          ),
        );
        return;
      }
      phase(PaymentPhase.verifying);
      try {
        final v = await _api.verifyPayment(
          VerifyPaymentDto(
            razorpayOrderId: s.orderId!,
            razorpayPaymentId: s.paymentId!,
            razorpaySignature: s.signature!,
          ),
        );
        if (v.success) {
          settle(CheckoutVerified(subscriptionStatus: v.subscriptionStatus));
        } else {
          // Server reached, signature rejected → a genuine verification failure.
          settle(
            const CheckoutFailed(
              reason: 'verification',
              message: 'We couldn’t verify this payment.',
            ),
          );
        }
      } catch (_) {
        // Provider success but the server couldn’t confirm — the money may have
        // moved. Never call this a failure.
        settle(CheckoutPending(orderId: s.orderId, paymentId: s.paymentId));
      }
    };

    timeoutTimer = Timer(_timeout, () {
      phase(PaymentPhase.timedOut);
      settle(
        const CheckoutFailed(
          reason: 'timeout',
          message: 'Checkout took too long. Please try again.',
        ),
      );
    });

    try {
      phase(PaymentPhase.openingCheckout);
      adapter.open(_options(checkout, billingCycle));
      phase(PaymentPhase.awaitingTerminalEvent);
    } catch (_) {
      settle(
        const CheckoutFailed(
          reason: 'open',
          message: 'Could not open the payment sheet.',
        ),
      );
    }

    try {
      final result = await completer.future;
      phase(_terminalPhase(result));
      return result;
    } finally {
      adapter.dispose();
    }
  }

  CheckoutResult? _validateCheckout(CheckoutResponse c) {
    if (c.keyId.trim().isEmpty) {
      return const CheckoutFailed(
        reason: 'invalid_checkout',
        message: 'Payment is temporarily unavailable. Please try again.',
      );
    }
    if (c.razorpayOrderId.trim().isEmpty) {
      return const CheckoutFailed(
        reason: 'invalid_checkout',
        message: 'Payment is temporarily unavailable. Please try again.',
      );
    }
    if (c.amountPaise <= 0) {
      return const CheckoutFailed(
        reason: 'invalid_checkout',
        message: 'This plan’s price is unavailable right now.',
      );
    }
    if (c.currency.toUpperCase() != 'INR') {
      return const CheckoutFailed(
        reason: 'invalid_checkout',
        message: 'Unsupported payment currency.',
      );
    }
    return null;
  }

  Map<String, dynamic> _options(CheckoutResponse c, String billingCycle) {
    final prefill = <String, dynamic>{
      if (c.prefill.name != null) 'name': c.prefill.name,
      if (c.prefill.email != null) 'email': c.prefill.email,
      if (c.prefill.contact != null) 'contact': c.prefill.contact,
    };
    return <String, dynamic>{
      'key': c.keyId,
      'order_id': c.razorpayOrderId,
      'amount': c.amountPaise,
      'currency': c.currency,
      'name': 'RADHA',
      'description': 'RADHA subscription ($billingCycle)',
      if (prefill.isNotEmpty) 'prefill': prefill,
    };
  }

  PaymentPhase _terminalPhase(CheckoutResult r) => switch (r) {
    CheckoutVerified() => PaymentPhase.verified,
    CheckoutCancelled() => PaymentPhase.cancelled,
    CheckoutPending() => PaymentPhase.pendingConfirmation,
    CheckoutFailed(reason: 'verification') => PaymentPhase.verificationFailed,
    CheckoutFailed(reason: 'timeout') => PaymentPhase.timedOut,
    CheckoutFailed() => PaymentPhase.paymentFailed,
  };
}
