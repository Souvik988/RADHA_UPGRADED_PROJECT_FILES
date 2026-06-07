// TEMPORARY DEMO STUB — original preserved in razorpay_checkout_sheet.dart.demo-bak
//
// razorpay_flutter pulls in two com.razorpay native modules (standard-core +
// core) that declare the same `com.razorpay` namespace, which AGP's manifest
// merger rejects. For an on-device demo this file is temporarily stubbed and
// the pubspec dependency is commented out. The public entrypoint signature +
// DTO round-trip are preserved so subscription_screen.dart compiles unchanged.
// RESTORE THE .demo-bak BEFORE SHIPPING.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/dto/payment_dto.dart';

Future<bool> openRazorpayCheckout({
  required BuildContext context,
  required WidgetRef ref,
  required String planId,
  required String billingCycle,
}) async {
  final api = ref.read(apiClientProvider);
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await api.createCheckout(
      CreateCheckoutDto(planId: planId, billingCycle: billingCycle),
    );
  } catch (_) {
    // Ignore in demo build.
  }
  messenger?.showSnackBar(
    const SnackBar(content: Text('Payment sheet unavailable in demo build')),
  );
  return false;
}
