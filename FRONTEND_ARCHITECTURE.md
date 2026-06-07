# File: FRONTEND_ARCHITECTURE.md

# RADHA Frontend Architecture

## Frontend Surfaces
1. Flutter mobile app for Staff, Manager, Auditor, Admin-lite.
2. Next.js admin web panel.
3. Next.js marketing website.

## Mobile Route Map
| Route | Screen | Role | Phase |
|---|---|---|---|
| /login | Mobile OTP login | all | FE-04 |
| /dashboard | Role dashboard | all | FE-05 |
| /scanner | Barcode scanner | staff/auditor | FE-06 |
| /product/:ean | Product detail | staff+ | FE-07 |
| /audit/bulk | Bulk EAN audit | staff/auditor | FE-08 |
| /tasks | My tasks | staff/manager | FE-09 |
| /reports | Reports | manager/admin/auditor | FE-10 |

## Component Map
| Component Group | Examples |
|---|---|
| core/ui | RadhaButton, StatusChip, HealthBadge, ExpiryBadge |
| scanner | BarcodeScannerView, ManualEANEntry, ScanResultSheet |
| product | ProductCard, ProductHealthPanel, NutritionSummary |
| expiry | ExpiryDateForm, OCRSuggestionCard |
| audit | BulkScanList, EANValidationResult |
| tasks | TaskCard, TaskForm |
| reports | KPIGrid, ExportButton |
| admin | ImportWizard, UserRoleEditor, StoreSelector |

## State Management
- Flutter: Riverpod recommended.
- Admin web: TanStack Query.
- No UI screen calls API directly.

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


## Frontend Testing Plan
- Unit: validators, status label mappers.
- Widget: auth, scanner result, expiry form, task card.
- Integration: login -> scan -> expiry -> report.
---

## 2026-05-15 Upgrade Patch: Corrected Frontend Surfaces and Routes

### Corrected Frontend Surfaces
| Surface | Path | User | Notes |
|---|---|---|---|
| Mobile app | `apps/mobile` | Retail client users | Contains client dashboard inside the app. |
| Marketing website | `apps/marketing-web` | Public visitors | Landing pages, pricing, contact, download links, privacy/terms. |
| Owner dashboard | `apps/owner-dashboard` | RADHA owner only | Private SaaS analytics and subscription dashboard. |

Do **not** place admin/website code inside `apps/mobile/lib/features/admin_web_panel_and_marketing_website/`.

### Added Mobile Routes
| Route | Screen | Role | Phase |
|---|---|---|---|
| /inventory | Inventory dashboard | staff+ | FE-13 |
| /inventory/product/:id | Inventory product detail | staff+ | FE-13 |
| /inventory/stock-in | Stock in form | manager/admin | FE-13 |
| /inventory/stock-out | Stock out form | manager/admin | FE-13 |
| /inventory/low-stock | Low-stock alerts | manager/admin | FE-13 |
| /grn | GRN list | manager/admin | FE-14 |
| /grn/new | GRN inward entry | manager/admin | FE-14 |
| /grn/:id/review | GRN review and post | manager/admin | FE-14 |
| /suppliers | Supplier list | manager/admin | FE-14 |
| /subscription | Trial/plan status | tenant admin | FE-15 |

### Client In-App Dashboard Cards
The `/dashboard` screen should include:
- Total scans today/week/month.
- Expiry safe/near-expiry/expired counts.
- EAN matched/unmatched counts.
- Pending/completed/overdue tasks.
- Current stock count.
- Low-stock count.
- Recent GRN inward count.
- Export/report shortcut.

### Owner Dashboard Routes
| Route | Page | Purpose |
|---|---|---|
| /owner/dashboard | Owner KPI dashboard | Visitors, signups, trials, paid users, revenue, activity. |
| /owner/website | Website analytics | Page views, clicks, source campaigns, app download clicks. |
| /owner/leads | Lead management | Contact/demo leads and follow-up status. |
| /owner/users | App user base | Tenants, stores, users, active/inactive users. |
| /owner/subscriptions | Subscription tracking | Trial, paid, expired, cancelled, plan split. |
| /owner/usage | Feature usage | Scans, expiry records, EAN validations, GRNs, inventory events, exports, AI calls. |

### Marketing Website Pages
| Route | Purpose |
|---|---|
| / | Product positioning and app download CTA. |
| /features | Scanner, expiry, EAN validation, tasks, GRN, lightweight inventory. |
| /pricing | 3-month free trial and ₹49/₹99/₹199 plans. |
| /contact | Demo/contact form and WhatsApp click tracking. |
| /privacy | Privacy policy for Play Store and customers. |
| /terms | Terms and subscription terms. |

### New Component Groups
| Component Group | Examples |
|---|---|
| inventory | InventoryKpiCard, StockInForm, StockOutForm, LowStockAlertCard, InventoryCountList |
| grn | GrnHeaderForm, SupplierSelector, GrnItemTable, GrnReviewPanel, PostGrnButton |
| subscription | TrialCountdownCard, PlanCard, EntitlementLimitBanner |
| owner-dashboard | OwnerKpiGrid, VisitorChart, PlanBreakdownCard, LeadTable, UserActivityTable |
| marketing | PricingCards, FeatureSection, LeadCaptureForm, AppDownloadButton |

