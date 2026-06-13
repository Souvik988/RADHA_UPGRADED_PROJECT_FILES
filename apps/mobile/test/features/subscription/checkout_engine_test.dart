import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/payment_dto.dart';
import 'package:radha_mobile/features/subscription/payment/checkout_engine.dart';
import 'package:radha_mobile/features/subscription/payment/checkout_models.dart';
import 'package:radha_mobile/features/subscription/payment/razorpay_adapter.dart';

const _planUuid = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d';

const _okCheckout = CheckoutResponse(
  razorpayOrderId: 'order_test_123456',
  keyId: 'rzp_test_key',
  amountPaise: 4900,
  currency: 'INR',
  prefill: CheckoutPrefill(name: 'Asha', contact: '+919999999999'),
);

/// Fake ApiClient — only the two payment methods are real.
class _FakeApi implements ApiClient {
  _FakeApi({this.checkout, this.checkoutError, this.verify, this.verifyError});
  final CheckoutResponse? checkout;
  final Object? checkoutError;
  final VerifyPaymentResponse? verify;
  final Object? verifyError;
  int verifyCalls = 0;

  @override
  Future<CheckoutResponse> createCheckout(CreateCheckoutDto body) async {
    if (checkoutError != null) throw checkoutError!;
    return checkout ?? _okCheckout;
  }

  @override
  Future<VerifyPaymentResponse> verifyPayment(VerifyPaymentDto body) async {
    verifyCalls++;
    if (verifyError != null) throw verifyError!;
    return verify ??
        const VerifyPaymentResponse(
          success: true,
          subscriptionStatus: 'active',
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake adapter — runs a [script] when `open()` is called (handlers are already
/// wired by then), letting a test emit success/error/wallet deterministically.
class _FakeAdapter implements RazorpayAdapter {
  _FakeAdapter(this.script);
  final void Function(_FakeAdapter self) script;
  void Function(RpSuccess)? _onSuccess;
  void Function(RpFailure)? _onError;
  void Function(RpExternalWallet)? _onExternalWallet;
  bool disposed = false;

  @override
  set onSuccess(void Function(RpSuccess) h) => _onSuccess = h;
  @override
  set onError(void Function(RpFailure) h) => _onError = h;
  @override
  set onExternalWallet(void Function(RpExternalWallet) h) =>
      _onExternalWallet = h;

  @override
  void open(Map<String, dynamic> options) => script(this);
  @override
  void dispose() => disposed = true;

  void emitSuccess(RpSuccess s) => _onSuccess?.call(s);
  void emitError(RpFailure f) => _onError?.call(f);
  void emitWallet(RpExternalWallet w) => _onExternalWallet?.call(w);
}

DioException _dio(DioExceptionType type, {int? status}) => DioException(
  requestOptions: RequestOptions(path: '/api/v1/payments/verify'),
  type: type,
  response: status == null
      ? null
      : Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: status,
        ),
);

const _success = RpSuccess(
  orderId: 'order_test_123456',
  paymentId: 'pay_test_1',
  signature: 'sig_test_1',
);

void main() {
  CheckoutEngine engine(
    _FakeApi api, {
    _FakeAdapter? adapter,
    Duration timeout = const Duration(seconds: 5),
  }) => CheckoutEngine(
    api: api,
    adapterFactory: () => adapter ?? _FakeAdapter((_) {}),
    timeout: timeout,
  );

  test('rejects a non-UUID planId before any network call', () async {
    final api = _FakeApi();
    final r = await CheckoutEngine(
      api: api,
      adapterFactory: () => throw StateError('adapter must not be created'),
    ).run(planId: 'starter', billingCycle: 'monthly');
    expect(r, isA<CheckoutFailed>());
    expect((r as CheckoutFailed).reason, 'invalid_plan');
  });

  test('rejects an invalid billing cycle', () async {
    final r = await engine(
      _FakeApi(),
    ).run(planId: _planUuid, billingCycle: 'weekly');
    expect((r as CheckoutFailed).reason, 'invalid_cycle');
  });

  test('createCheckout failure → CheckoutFailed(create_order)', () async {
    final r = await engine(
      _FakeApi(checkoutError: _dio(DioExceptionType.connectionError)),
    ).run(planId: _planUuid, billingCycle: 'monthly');
    expect((r as CheckoutFailed).reason, 'create_order');
  });

  test('invalid checkout response (empty keyId) → CheckoutFailed', () async {
    final api = _FakeApi(
      checkout: const CheckoutResponse(
        razorpayOrderId: 'o1',
        keyId: '',
        amountPaise: 4900,
        currency: 'INR',
        prefill: CheckoutPrefill(),
      ),
    );
    final r = await engine(api).run(planId: _planUuid, billingCycle: 'monthly');
    expect((r as CheckoutFailed).reason, 'invalid_checkout');
  });

  test('non-INR checkout response → CheckoutFailed', () async {
    final api = _FakeApi(
      checkout: const CheckoutResponse(
        razorpayOrderId: 'o1',
        keyId: 'k',
        amountPaise: 4900,
        currency: 'USD',
        prefill: CheckoutPrefill(),
      ),
    );
    final r = await engine(api).run(planId: _planUuid, billingCycle: 'monthly');
    expect((r as CheckoutFailed).reason, 'invalid_checkout');
  });

  test('success → server verifies → CheckoutVerified', () async {
    final api = _FakeApi();
    final adapter = _FakeAdapter((self) => self.emitSuccess(_success));
    final r = await engine(
      api,
      adapter: adapter,
    ).run(planId: _planUuid, billingCycle: 'yearly');
    expect(r, isA<CheckoutVerified>());
    expect((r as CheckoutVerified).subscriptionStatus, 'active');
    expect(adapter.disposed, isTrue);
  });

  test(
    'success → server rejects signature → CheckoutFailed(verification)',
    () async {
      final api = _FakeApi(
        verify: const VerifyPaymentResponse(
          success: false,
          subscriptionStatus: 'inactive',
        ),
      );
      final adapter = _FakeAdapter((self) => self.emitSuccess(_success));
      final r = await engine(
        api,
        adapter: adapter,
      ).run(planId: _planUuid, billingCycle: 'monthly');
      expect((r as CheckoutFailed).reason, 'verification');
    },
  );

  test(
    'success → verify unreachable → CheckoutPending (never failed)',
    () async {
      final api = _FakeApi(verifyError: _dio(DioExceptionType.connectionError));
      final adapter = _FakeAdapter((self) => self.emitSuccess(_success));
      final r = await engine(
        api,
        adapter: adapter,
      ).run(planId: _planUuid, billingCycle: 'monthly');
      expect(r, isA<CheckoutPending>());
      expect((r as CheckoutPending).orderId, 'order_test_123456');
      expect(r.supportRef, '123456');
    },
  );

  test('user dismissal (code 2) → CheckoutCancelled', () async {
    final adapter = _FakeAdapter(
      (self) => self.emitError(const RpFailure(code: kRazorpayCancelledCode)),
    );
    final r = await engine(
      _FakeApi(),
      adapter: adapter,
    ).run(planId: _planUuid, billingCycle: 'monthly');
    expect(r, isA<CheckoutCancelled>());
  });

  test('provider error (other code) → CheckoutFailed(provider)', () async {
    final adapter = _FakeAdapter(
      (self) => self.emitError(const RpFailure(code: 1, message: 'declined')),
    );
    final r = await engine(
      _FakeApi(),
      adapter: adapter,
    ).run(planId: _planUuid, billingCycle: 'monthly');
    expect((r as CheckoutFailed).reason, 'provider');
  });

  test(
    'external wallet is NOT terminal — later success still verifies',
    () async {
      final api = _FakeApi();
      final adapter = _FakeAdapter((self) {
        self.emitWallet(const RpExternalWallet(walletName: 'PhonePe'));
        self.emitSuccess(_success);
      });
      final r = await engine(
        api,
        adapter: adapter,
      ).run(planId: _planUuid, billingCycle: 'monthly');
      expect(r, isA<CheckoutVerified>());
    },
  );

  test('duplicate success callbacks verify only once', () async {
    final api = _FakeApi();
    final adapter = _FakeAdapter((self) {
      self.emitSuccess(_success);
      self.emitSuccess(_success);
    });
    final r = await engine(
      api,
      adapter: adapter,
    ).run(planId: _planUuid, billingCycle: 'monthly');
    expect(r, isA<CheckoutVerified>());
    expect(api.verifyCalls, 1);
  });

  test('no terminal event before timeout → CheckoutFailed(timeout)', () async {
    final adapter = _FakeAdapter((_) {}); // never emits
    final r = await engine(
      _FakeApi(),
      adapter: adapter,
      timeout: const Duration(milliseconds: 40),
    ).run(planId: _planUuid, billingCycle: 'monthly');
    expect((r as CheckoutFailed).reason, 'timeout');
    expect(adapter.disposed, isTrue);
  });

  test('phase listener reaches a terminal phase', () async {
    final phases = <PaymentPhase>[];
    final adapter = _FakeAdapter((self) => self.emitSuccess(_success));
    await engine(
      _FakeApi(),
      adapter: adapter,
    ).run(planId: _planUuid, billingCycle: 'monthly', onPhase: phases.add);
    expect(phases, contains(PaymentPhase.creatingOrder));
    expect(phases.last, PaymentPhase.verified);
  });
}
