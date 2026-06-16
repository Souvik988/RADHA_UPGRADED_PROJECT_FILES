import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:radha_mobile/core/auth/auth_controller.dart';
import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/task_dto.dart';

/// Cache a *successful* result for the lifetime of the app session.
///
/// Why: the home summary tiles must feel "already there" on every return to
/// the Home tab — no skeleton flash on re-entry. Calling [KeepAliveLink] only
/// after a value resolves means errors are **not** cached, so a transient
/// backend/network failure is retried on the next read (graceful self-heal),
/// while good data sticks until an explicit pull-to-refresh invalidates it.
void _cacheOnSuccess(Ref ref) => ref.keepAlive();

/// Count of expiry records in the backend's warning/danger states.
final nearExpiryCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final storeId = ref.watch(currentUserProvider)?.selectedStoreId;
  if (storeId == null) return 0;

  final client = ref.watch(apiClientProvider);
  final response = await client.getExpiries(
    status: 'yellow,red',
    storeId: storeId,
    limit: 200,
  );
  _cacheOnSuccess(ref);
  return response.total;
});

/// Count of tasks with status "open".
final openTasksCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.getTasks(status: 'open', limit: 1);
  _cacheOnSuccess(ref);
  return response.total;
});

/// Count of low-stock inventory items.
/// Uses the inventory endpoint with `limit: 1` to get the total count.
/// Note: In a future iteration the backend may expose a `/inventory/low-stock`
/// filter; for now we use the general inventory total as a proxy.
final lowStockCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final client = ref.watch(apiClientProvider);
  // No server-side low-stock filter exists yet, so we fetch a bounded inventory
  // page and count items at/below their configured threshold — the exact rule
  // the Low-stock alerts screen uses (`current_stock <= threshold`). This makes
  // the KPI honest instead of surfacing the total inventory size.
  final response = await client.getInventory(limit: 200);
  final count = response.items
      .where(
        (i) =>
            i.lowStockThreshold != null && i.quantity <= i.lowStockThreshold!,
      )
      .length;
  _cacheOnSuccess(ref);
  return count;
});

// ─── Consumer-mode providers ─────────────────────────────────────────────────

/// Count of the signed-in user's saved products (consumer mode KPI).
///
/// Fetches up to 20 items and reports `.length`. The API uses cursor
/// pagination without a total count, so this is a best-effort display number
/// for the home KPI tile — exact counts live on the saved-products screen.
final savedProductsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.getSavedProducts(limit: 20);
  _cacheOnSuccess(ref);
  return response.items.length;
});

/// Count of active system-wide recall alerts (consumer mode KPI).
///
/// Recalls are a free safety hook — always visible regardless of plan. The
/// endpoint returns the full list; `.length` is used as the badge value.
final recallAlertsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final client = ref.watch(apiClientProvider);
  final recalls = await client.getRecalls();
  _cacheOnSuccess(ref);
  return recalls.length;
});

/// Top-3 most recent open tasks (business mode — replaces hardcoded list).
///
/// Scoped to open status so the home preview always shows actionable items.
/// The full task list lives on the Tasks tab.
final recentTasksProvider = FutureProvider.autoDispose<List<TaskResponse>>((
  ref,
) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.getTasks(status: 'open', limit: 3);
  _cacheOnSuccess(ref);
  return response.items;
});
