import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/payment_dto.dart';
import 'package:radha_mobile/core/network/dto/subscription_status_dto.dart';
import 'package:radha_mobile/design/theme.dart';
import 'package:radha_mobile/features/subscription/payment/checkout_engine.dart';
import 'package:radha_mobile/features/subscription/payment/checkout_models.dart';
import 'package:radha_mobile/features/subscription/payment/razorpay_adapter.dart';
import 'package:radha_mobile/features/subscription/subscription_screen.dart';

const _starterId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _growthId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

SubscriptionPlanDto _plan(String id, String code, String name, double price) =>
    SubscriptionPlanDto(
      id: id,
      code: code,
      name: name,
      price: price,
      currency: 'INR',
      sortOrder: code == 'starter' ? 1 : 2,
      features: const [
        PlanFeatureDto(feature: 'monthly_scans', description: 'Lots of scans'),
      ],
    );

SubscriptionStatusDto _trialStatus() => SubscriptionStatusDto(
  isActive: true,
  status: 'trial',
  trialDaysRemaining: 30,
  plan: _plan('tttttttt-tttt-4ttt-8ttt-tttttttttttt', 'trial', 'Free Trial', 0),
);

class _FakeApi implements ApiClient {
  String? lastCheckoutPlanId;
  String? lastBillingCycle;
  int verifyCalls = 0;

  @override
  Future<SubscriptionStatusDto> getSubscriptionStatus() async => _trialStatus();

  @override
  Future<List<SubscriptionPlanDto>> getSubscriptionPlans() async => [
    _plan(_starterId, 'starter', 'Starter', 49),
    _plan(_growthId, 'growth', 'Growth', 99),
  ];

  @override
  Future<CheckoutResponse> createCheckout(CreateCheckoutDto body) async {
    lastCheckoutPlanId = body.planId;
    lastBillingCycle = body.billingCycle;
    return const CheckoutResponse(
      razorpayOrderId: 'order_1',
      keyId: 'rzp_test_k',
      amountPaise: 4900,
      currency: 'INR',
      prefill: CheckoutPrefill(),
    );
  }

  @override
  Future<VerifyPaymentResponse> verifyPayment(VerifyPaymentDto body) async {
    verifyCalls++;
    return const VerifyPaymentResponse(
      success: true,
      subscriptionStatus: 'active',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake adapter that reports a successful payment as soon as the sheet opens.
class _SuccessAdapter implements RazorpayAdapter {
  void Function(RpSuccess)? _onSuccess;
  @override
  set onSuccess(void Function(RpSuccess) h) => _onSuccess = h;
  @override
  set onError(void Function(RpFailure) h) {}
  @override
  set onExternalWallet(void Function(RpExternalWallet) h) {}
  @override
  void open(Map<String, dynamic> options) => _onSuccess?.call(
    const RpSuccess(orderId: 'order_1', paymentId: 'pay_1', signature: 'sig_1'),
  );
  @override
  void dispose() {}
}

Widget _app(_FakeApi api) {
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(api),
      checkoutEngineProvider.overrideWithValue(
        CheckoutEngine(api: api, adapterFactory: _SuccessAdapter.new),
      ),
    ],
    child: MaterialApp(
      theme: radhaLightTheme(),
      home: const SubscriptionScreen(),
    ),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders backend plans, current plan, and billing toggle', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_FakeApi()));
    await tester.pumpAndSettle();

    expect(find.text('Starter'), findsOneWidget);
    expect(find.text('Growth'), findsOneWidget);
    expect(find.text('Current plan'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
  });

  testWidgets('checkout sends the plan UUID (not the code) and verifies', (
    tester,
  ) async {
    final api = _FakeApi();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Choose Starter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose Starter'));
    await tester.pumpAndSettle();

    expect(api.lastCheckoutPlanId, _starterId); // UUID, never 'starter'
    expect(api.lastBillingCycle, 'monthly');
    expect(api.verifyCalls, 1);
    expect(find.textContaining("You're on Starter"), findsOneWidget);
  });

  testWidgets('billing toggle drives the checkout cycle', (tester) async {
    final api = _FakeApi();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yearly'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Choose Starter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose Starter'));
    await tester.pumpAndSettle();

    expect(api.lastBillingCycle, 'yearly');
  });
}
