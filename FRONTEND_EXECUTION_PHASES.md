# File: FRONTEND_EXECUTION_PHASES.md

# Frontend Execution Phases

## Phase FE-01: Flutter Mobile App Initialization

### Goal
Create RADHA mobile app shell, package structure, env loader, and basic build targets.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `apps/mobile/lib/features/flutter_mobile_app_initialization/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/core/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `FRONTEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

### Dependencies
Depends on PF-05/PF-06 and corresponding API mocks or backend endpoints.

### Database Tables Affected
Indirect through backend APIs only.

### API Contracts Affected
See API_CONTRACTS.md phase rows.

### Frontend Screens/Components Affected
Mobile/admin UI for Flutter Mobile App Initialization.

### Backend Routes/Controllers/Services Affected
Depends on backend stubs or live endpoints when available.

### Tests to Write
- Widget tests for screens/components.
- Integration tests with mocked API client.

### Validation Checklist
- Flutter analyze passes.
- Loading/empty/error/success states implemented.
- No direct HTTP calls outside service layer.
- Responsive layout checked.

### Risks and Bugs to Watch
- API drift.
- Scanner permission differences.
- Overcrowded mobile UI.

### Completion Criteria
Flutter Mobile App Initialization is usable in mocked mode and ready for backend integration.
## Phase FE-02: Mobile Routing, App Shell, and Role Navigation

### Goal
Build authenticated/unauthenticated routes, role-based navigation, and bottom/tab structure.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `apps/mobile/lib/features/mobile_routing_app_shell_and_role_navigation/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/core/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `FRONTEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

### Dependencies
Depends on PF-05/PF-06 and corresponding API mocks or backend endpoints.

### Database Tables Affected
Indirect through backend APIs only.

### API Contracts Affected
See API_CONTRACTS.md phase rows.

### Frontend Screens/Components Affected
Mobile/admin UI for Mobile Routing, App Shell, and Role Navigation.

### Backend Routes/Controllers/Services Affected
Depends on backend stubs or live endpoints when available.

### Tests to Write
- Widget tests for screens/components.
- Integration tests with mocked API client.

### Validation Checklist
- Flutter analyze passes.
- Loading/empty/error/success states implemented.
- No direct HTTP calls outside service layer.
- Responsive layout checked.

### Risks and Bugs to Watch
- API drift.
- Scanner permission differences.
- Overcrowded mobile UI.

### Completion Criteria
Mobile Routing, App Shell, and Role Navigation is usable in mocked mode and ready for backend integration.
## Phase FE-03: Design System, Theme, and Shared UI Components

### Goal
Create premium RADHA UI foundation: colors, typography, cards, buttons, inputs, chips, status badges.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `apps/mobile/lib/features/design_system_theme_and_shared_ui_components/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/core/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `FRONTEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

### Dependencies
Depends on PF-05/PF-06 and corresponding API mocks or backend endpoints.

### Database Tables Affected
Indirect through backend APIs only.

### API Contracts Affected
See API_CONTRACTS.md phase rows.

### Frontend Screens/Components Affected
Mobile/admin UI for Design System, Theme, and Shared UI Components.

### Backend Routes/Controllers/Services Affected
Depends on backend stubs or live endpoints when available.

### Tests to Write
- Widget tests for screens/components.
- Integration tests with mocked API client.

### Validation Checklist
- Flutter analyze passes.
- Loading/empty/error/success states implemented.
- No direct HTTP calls outside service layer.
- Responsive layout checked.

### Risks and Bugs to Watch
- API drift.
- Scanner permission differences.
- Overcrowded mobile UI.

### Completion Criteria
Design System, Theme, and Shared UI Components is usable in mocked mode and ready for backend integration.
## Phase FE-04: Authentication and Onboarding Screens

### Goal
Build mobile OTP login, admin/staff/manager role routing, and first-login profile setup.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `apps/mobile/lib/features/authentication_and_onboarding_screens/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/core/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `FRONTEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

### Dependencies
Depends on PF-05/PF-06 and corresponding API mocks or backend endpoints.

### Database Tables Affected
Indirect through backend APIs only.

### API Contracts Affected
See API_CONTRACTS.md phase rows.

### Frontend Screens/Components Affected
Mobile/admin UI for Authentication and Onboarding Screens.

### Backend Routes/Controllers/Services Affected
Depends on backend stubs or live endpoints when available.

### Tests to Write
- Widget tests for screens/components.
- Integration tests with mocked API client.

### Validation Checklist
- Flutter analyze passes.
- Loading/empty/error/success states implemented.
- No direct HTTP calls outside service layer.
- Responsive layout checked.

### Risks and Bugs to Watch
- API drift.
- Scanner permission differences.
- Overcrowded mobile UI.

### Completion Criteria
Authentication and Onboarding Screens is usable in mocked mode and ready for backend integration.
## Phase FE-05: Role-Based Dashboards

### Goal
Build Staff, Manager, Admin/Auditor dashboard shells with scan/task/report quick actions.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `apps/mobile/lib/features/role_based_dashboards/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/core/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `FRONTEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

### Dependencies
Depends on PF-05/PF-06 and corresponding API mocks or backend endpoints.

### Database Tables Affected
Indirect through backend APIs only.

### API Contracts Affected
See API_CONTRACTS.md phase rows.

### Frontend Screens/Components Affected
Mobile/admin UI for Role-Based Dashboards.

### Backend Routes/Controllers/Services Affected
Depends on backend stubs or live endpoints when available.

### Tests to Write
- Widget tests for screens/components.
- Integration tests with mocked API client.

### Validation Checklist
- Flutter analyze passes.
- Loading/empty/error/success states implemented.
- No direct HTTP calls outside service layer.
- Responsive layout checked.

### Risks and Bugs to Watch
- API drift.
- Scanner permission differences.
- Overcrowded mobile UI.

### Completion Criteria
Role-Based Dashboards is usable in mocked mode and ready for backend integration.
## Phase FE-06: Barcode/EAN Scanner Screen

### Goal
Build camera scanner, manual EAN entry fallback, scan states, duplicate scan handling, and scanner permissions.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `apps/mobile/lib/features/barcode_ean_scanner_screen/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/core/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `FRONTEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

### Dependencies
Depends on PF-05/PF-06 and corresponding API mocks or backend endpoints.

### Database Tables Affected
Indirect through backend APIs only.

### API Contracts Affected
See API_CONTRACTS.md phase rows.

### Frontend Screens/Components Affected
Mobile/admin UI for Barcode/EAN Scanner Screen.

### Backend Routes/Controllers/Services Affected
Depends on backend stubs or live endpoints when available.

### Tests to Write
- Widget tests for screens/components.
- Integration tests with mocked API client.

### Validation Checklist
- Flutter analyze passes.
- Loading/empty/error/success states implemented.
- No direct HTTP calls outside service layer.
- Responsive layout checked.

### Risks and Bugs to Watch
- API drift.
- Scanner permission differences.
- Overcrowded mobile UI.

### Completion Criteria
Barcode/EAN Scanner Screen is usable in mocked mode and ready for backend integration.
## Phase FE-07: Product Detail, Health Indicator, and Expiry Entry

### Goal
Build product detail screen, health badge UI, child-preference indicator, expiry/manual-OCR entry flow.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `apps/mobile/lib/features/product_detail_health_indicator_and_expiry_entry/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/core/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `FRONTEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

### Dependencies
Depends on PF-05/PF-06 and corresponding API mocks or backend endpoints.

### Database Tables Affected
Indirect through backend APIs only.

### API Contracts Affected
See API_CONTRACTS.md phase rows.

### Frontend Screens/Components Affected
Mobile/admin UI for Product Detail, Health Indicator, and Expiry Entry.

### Backend Routes/Controllers/Services Affected
Depends on backend stubs or live endpoints when available.

### Tests to Write
- Widget tests for screens/components.
- Integration tests with mocked API client.

### Validation Checklist
- Flutter analyze passes.
- Loading/empty/error/success states implemented.
- No direct HTTP calls outside service layer.
- Responsive layout checked.

### Risks and Bugs to Watch
- API drift.
- Scanner permission differences.
- Overcrowded mobile UI.

### Completion Criteria
Product Detail, Health Indicator, and Expiry Entry is usable in mocked mode and ready for backend integration.
## Phase FE-08: EAN Audit and Bulk Scan Workflow

### Goal
Build approved-EAN task mode, bulk scan list, green/red validation, invalid item notes, and session summary.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `apps/mobile/lib/features/ean_audit_and_bulk_scan_workflow/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/core/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `FRONTEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

### Dependencies
Depends on PF-05/PF-06 and corresponding API mocks or backend endpoints.

### Database Tables Affected
Indirect through backend APIs only.

### API Contracts Affected
See API_CONTRACTS.md phase rows.

### Frontend Screens/Components Affected
Mobile/admin UI for EAN Audit and Bulk Scan Workflow.

### Backend Routes/Controllers/Services Affected
Depends on backend stubs or live endpoints when available.

### Tests to Write
- Widget tests for screens/components.
- Integration tests with mocked API client.

### Validation Checklist
- Flutter analyze passes.
- Loading/empty/error/success states implemented.
- No direct HTTP calls outside service layer.
- Responsive layout checked.

### Risks and Bugs to Watch
- API drift.
- Scanner permission differences.
- Overcrowded mobile UI.

### Completion Criteria
EAN Audit and Bulk Scan Workflow is usable in mocked mode and ready for backend integration.
## Phase FE-09: Task Assignment and Completion Screens

### Goal
Build manager task creation/list/detail and staff task execution/completion flows.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `apps/mobile/lib/features/task_assignment_and_completion_screens/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/core/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `FRONTEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

### Dependencies
Depends on PF-05/PF-06 and corresponding API mocks or backend endpoints.

### Database Tables Affected
Indirect through backend APIs only.

### API Contracts Affected
See API_CONTRACTS.md phase rows.

### Frontend Screens/Components Affected
Mobile/admin UI for Task Assignment and Completion Screens.

### Backend Routes/Controllers/Services Affected
Depends on backend stubs or live endpoints when available.

### Tests to Write
- Widget tests for screens/components.
- Integration tests with mocked API client.

### Validation Checklist
- Flutter analyze passes.
- Loading/empty/error/success states implemented.
- No direct HTTP calls outside service layer.
- Responsive layout checked.

### Risks and Bugs to Watch
- API drift.
- Scanner permission differences.
- Overcrowded mobile UI.

### Completion Criteria
Task Assignment and Completion Screens is usable in mocked mode and ready for backend integration.
## Phase FE-10: Reports, Export, and Sharing Screens

### Goal
Build report filters, summary cards, Excel/PDF download links, email/WhatsApp share actions.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `apps/mobile/lib/features/reports_export_and_sharing_screens/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/core/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `FRONTEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

### Dependencies
Depends on PF-05/PF-06 and corresponding API mocks or backend endpoints.

### Database Tables Affected
Indirect through backend APIs only.

### API Contracts Affected
See API_CONTRACTS.md phase rows.

### Frontend Screens/Components Affected
Mobile/admin UI for Reports, Export, and Sharing Screens.

### Backend Routes/Controllers/Services Affected
Depends on backend stubs or live endpoints when available.

### Tests to Write
- Widget tests for screens/components.
- Integration tests with mocked API client.

### Validation Checklist
- Flutter analyze passes.
- Loading/empty/error/success states implemented.
- No direct HTTP calls outside service layer.
- Responsive layout checked.

### Risks and Bugs to Watch
- API drift.
- Scanner permission differences.
- Overcrowded mobile UI.

### Completion Criteria
Reports, Export, and Sharing Screens is usable in mocked mode and ready for backend integration.
## Phase FE-11: Admin Web Panel and Marketing Website

### Goal
Build Next.js admin web dashboard, website landing pages, login, product/admin management screens.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `apps/mobile/lib/features/admin_web_panel_and_marketing_website/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/core/` | Create required folder scaffold | Yes |
| `apps/admin-web/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `FRONTEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

### Dependencies
Depends on PF-05/PF-06 and corresponding API mocks or backend endpoints.

### Database Tables Affected
Indirect through backend APIs only.

### API Contracts Affected
See API_CONTRACTS.md phase rows.

### Frontend Screens/Components Affected
Mobile/admin UI for Admin Web Panel and Marketing Website.

### Backend Routes/Controllers/Services Affected
Depends on backend stubs or live endpoints when available.

### Tests to Write
- Widget tests for screens/components.
- Integration tests with mocked API client.

### Validation Checklist
- Flutter analyze passes.
- Loading/empty/error/success states implemented.
- No direct HTTP calls outside service layer.
- Responsive layout checked.

### Risks and Bugs to Watch
- API drift.
- Scanner permission differences.
- Overcrowded mobile UI.

### Completion Criteria
Admin Web Panel and Marketing Website is usable in mocked mode and ready for backend integration.
## Phase FE-12: Frontend Testing, Accessibility, Offline States, and Store Polish

### Goal
Add tests, responsive checks, accessibility, loading/error/empty states, app icon/splash, release readiness.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `apps/mobile/lib/features/frontend_testing_accessibility_offline_states_and_store_polish/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/core/` | Create required folder scaffold | Yes |
| `apps/mobile/lib/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `FRONTEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

### Dependencies
Depends on PF-05/PF-06 and corresponding API mocks or backend endpoints.

### Database Tables Affected
Indirect through backend APIs only.

### API Contracts Affected
See API_CONTRACTS.md phase rows.

### Frontend Screens/Components Affected
Mobile/admin UI for Frontend Testing, Accessibility, Offline States, and Store Polish.

### Backend Routes/Controllers/Services Affected
Depends on backend stubs or live endpoints when available.

### Tests to Write
- Widget tests for screens/components.
- Integration tests with mocked API client.

### Validation Checklist
- Flutter analyze passes.
- Loading/empty/error/success states implemented.
- No direct HTTP calls outside service layer.
- Responsive layout checked.

### Risks and Bugs to Watch
- API drift.
- Scanner permission differences.
- Overcrowded mobile UI.

### Completion Criteria
Frontend Testing, Accessibility, Offline States, and Store Polish is usable in mocked mode and ready for backend integration.
---

## 2026-05-15 Upgrade Patch: Added Frontend Execution Phases

## Phase FE-13: Mobile Lightweight Inventory Screens
### Goal
Build inventory dashboard, stock in, stock out, category counts, product stock detail, and low-stock alerts inside the RADHA mobile app.
### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| apps/mobile/lib/features/inventory/presentation/inventory_dashboard_screen.dart | Stock counts and low-stock summary | No |
| apps/mobile/lib/features/inventory/presentation/stock_in_screen.dart | Manual stock in | No |
| apps/mobile/lib/features/inventory/presentation/stock_out_screen.dart | Stock out with reason | No |
| apps/mobile/lib/features/inventory/presentation/low_stock_screen.dart | Low-stock alerts | No |
### Tests
- Loading/empty/error/success states.
- Stock form validation.
- Low-stock card display.

## Phase FE-14: Mobile GRN and Supplier Screens
### Goal
Build supplier list/create, GRN inward entry, item entry, expiry/batch capture, review, and post screens.
### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| apps/mobile/lib/features/grn/presentation/grn_list_screen.dart | GRN history | No |
| apps/mobile/lib/features/grn/presentation/grn_entry_screen.dart | Supplier + invoice entry | No |
| apps/mobile/lib/features/grn/presentation/grn_item_entry_screen.dart | Product quantities and expiry/batch | No |
| apps/mobile/lib/features/grn/presentation/grn_review_screen.dart | Review and post GRN | No |
### Tests
- GRN form validation.
- Post confirmation.
- Expiry date required for expiry-tracked product.

## Phase FE-15: Marketing Website and Subscription Pages
### Goal
Build public landing page, features, pricing, contact/demo, download CTA, privacy, and terms.
### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| apps/marketing-web/app/(public)/page.tsx | Landing page | No |
| apps/marketing-web/app/(public)/features/page.tsx | Feature explanation | No |
| apps/marketing-web/app/(public)/pricing/page.tsx | Trial and plans | No |
| apps/marketing-web/app/(public)/contact/page.tsx | Lead capture | No |
### Tests
- Lead form validation.
- Analytics event fired for CTA clicks.

## Phase FE-16: Owner-Only Dashboard
### Goal
Build private RADHA owner dashboard for website analytics, leads, app users, subscriptions, revenue, and usage metrics.
### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| apps/owner-dashboard/app/owner/dashboard/page.tsx | Owner KPI dashboard | No |
| apps/owner-dashboard/app/owner/website/page.tsx | Website analytics | No |
| apps/owner-dashboard/app/owner/leads/page.tsx | Lead management | No |
| apps/owner-dashboard/app/owner/users/page.tsx | App user base | No |
| apps/owner-dashboard/app/owner/subscriptions/page.tsx | Subscription tracking | No |
| apps/owner-dashboard/app/owner/usage/page.tsx | Feature usage tracking | No |
### Tests
- Owner-only route guard.
- KPI cards load empty and success states.
- Tenant users cannot access owner dashboard.

