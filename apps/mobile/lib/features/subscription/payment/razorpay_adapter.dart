// Razorpay SDK boundary.
//
// The engine ([CheckoutEngine]) talks only to [RazorpayAdapter] and the
// normalised `Rp*` types in checkout_models.dart — never to `razorpay_flutter`
// directly. That keeps the engine pure Dart (unit-testable with a fake adapter)
// and confines the native plugin to [FlutterRazorpayAdapter].

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'checkout_models.dart';

/// Minimal, mockable surface over a native Razorpay checkout instance.
abstract class RazorpayAdapter {
  set onSuccess(void Function(RpSuccess) handler);
  set onError(void Function(RpFailure) handler);
  set onExternalWallet(void Function(RpExternalWallet) handler);

  /// Open the native sheet with the prepared options.
  void open(Map<String, dynamic> options);

  /// Detach listeners / release the native instance. Safe to call once.
  void dispose();
}

/// Production adapter backed by `razorpay_flutter`. Translates SDK response
/// objects into the engine's normalised value types.
class FlutterRazorpayAdapter implements RazorpayAdapter {
  FlutterRazorpayAdapter() : _razorpay = Razorpay() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleWallet);
  }

  final Razorpay _razorpay;

  void Function(RpSuccess)? _onSuccess;
  void Function(RpFailure)? _onError;
  void Function(RpExternalWallet)? _onExternalWallet;

  @override
  set onSuccess(void Function(RpSuccess) handler) => _onSuccess = handler;

  @override
  set onError(void Function(RpFailure) handler) => _onError = handler;

  @override
  set onExternalWallet(void Function(RpExternalWallet) handler) =>
      _onExternalWallet = handler;

  @override
  void open(Map<String, dynamic> options) => _razorpay.open(options);

  @override
  void dispose() => _razorpay.clear();

  void _handleSuccess(PaymentSuccessResponse r) => _onSuccess?.call(
    RpSuccess(
      orderId: r.orderId,
      paymentId: r.paymentId,
      signature: r.signature,
    ),
  );

  void _handleError(PaymentFailureResponse r) =>
      _onError?.call(RpFailure(code: r.code, message: r.message));

  void _handleWallet(ExternalWalletResponse r) =>
      _onExternalWallet?.call(RpExternalWallet(walletName: r.walletName));
}
