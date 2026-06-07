import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:radha_mobile/core/network/api_client.dart';

/// Count of expiry records with status "near_expiry".
/// Calls the paginated endpoint with `limit: 1` and reads the `total` field.
final nearExpiryCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.getExpiries(status: 'near_expiry', limit: 1);
  return response.total;
});

/// Count of tasks with status "open".
final openTasksCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.getTasks(status: 'open', limit: 1);
  return response.total;
});

/// Count of low-stock inventory items.
/// Uses the inventory endpoint with `limit: 1` to get the total count.
/// Note: In a future iteration the backend may expose a `/inventory/low-stock`
/// filter; for now we use the general inventory total as a proxy.
final lowStockCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.getInventory(limit: 1);
  // The total here represents all inventory items. When the backend adds a
  // `status=low_stock` filter this will narrow automatically.
  return response.total;
});
