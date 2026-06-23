// App-mode resolver.
//
// Derives whether the current user is in consumer mode (personal food-health)
// or business mode (retail-ops command center) from the existing auth session.
// This is a pure computation — no new network calls. The router and home screen
// read this provider to decide which content set to render.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';

/// The two operating modes of the RADHA shell.
///
/// Same login, same 5-tab navigation. Mode decides which content a tab
/// renders and which Hero missions rotate in the Story Banner.
enum AppMode { consumer, business }

/// Roles that indicate the user has a business (tenant) identity.
///
/// A user holding any of these roles AND having a selected store is resolved
/// into business mode. Everything else is consumer mode.
const kBusinessRoles = {
  'staff',
  'manager',
  'auditor',
  'admin',
  'tenant_admin',
  'admin_lite',
};

/// Pure function — same inputs always return the same output.
///
/// [user] comes from `currentUserProvider` (GET /auth/me). A null user
/// (loading, signed-out) defaults to consumer so no screen is blank.
AppMode resolveMode(CurrentUser? user) {
  if (user == null) return AppMode.consumer;
  final hasBizRole = user.roles.any(kBusinessRoles.contains);
  return (hasBizRole && user.selectedStoreId != null)
      ? AppMode.business
      : AppMode.consumer;
}

/// Derived provider — no I/O, re-evaluates whenever auth session changes.
///
/// Reads from `currentUserProvider` (which itself watches
/// `authControllerProvider`), so mode flips automatically when a consumer
/// completes business-activation and the entitlement refresh updates the
/// session.
final appModeProvider = Provider<AppMode>((ref) {
  return resolveMode(ref.watch(currentUserProvider));
});
