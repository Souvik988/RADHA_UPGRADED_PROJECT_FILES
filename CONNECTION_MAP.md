# File: CONNECTION_MAP.md

# RADHA Complete System Wiring Map

|Feature|Frontend Files|API Contract|Backend Route|Controller|Service|Repository|Database Tables|Tests|Phase|
|---|---|---|---|---|---|---|---|---|---|
|auth|AuthScreen|/api/v1/auth/otp/request|/api/v1/auth/otp/request|AuthController|requestOtp|Repository matching module|otp_attempts|E2E + integration|BE-05|
|auth|OtpVerifyScreen|/api/v1/auth/otp/verify|/api/v1/auth/otp/verify|AuthController|verifyOtp|Repository matching module|users,user_sessions,otp_attempts|E2E + integration|BE-05|
|auth|AdminLogin|/api/v1/auth/admin/login|/api/v1/auth/admin/login|AuthController|adminLogin|Repository matching module|users,user_sessions|E2E + integration|BE-05|
|auth|AppBootstrap|/api/v1/auth/me|/api/v1/auth/me|AuthController|me|Repository matching module|users,stores|E2E + integration|BE-05|
|products|ScannerScreen|/api/v1/products/lookup/{ean}|/api/v1/products/lookup/{ean}|ProductsController|lookup|Repository matching module|products,product_nutrition,product_health_assessments|E2E + integration|BE-07|
|products|ProductCreateForm|/api/v1/products|/api/v1/products|ProductsController|create|Repository matching module|products,product_sources|E2E + integration|BE-07|
|ean-lists|AdminEANImport|/api/v1/ean-lists/import|/api/v1/ean-lists/import|EanListsController|import|Repository matching module|ean_lists,ean_list_items,ean_import_errors|E2E + integration|BE-09|
|ean-lists|BulkScanScreen|/api/v1/ean-lists/{id}/validate|/api/v1/ean-lists/{id}/validate|EanListsController|validate|Repository matching module|ean_list_items|E2E + integration|BE-09|
|scan-sessions|ScannerScreen|/api/v1/scan-sessions|/api/v1/scan-sessions|ScanController|createSession|Repository matching module|scan_sessions|E2E + integration|BE-10|
|scan-sessions|ScannerScreen|/api/v1/scan-sessions/{id}/items|/api/v1/scan-sessions/{id}/items|ScanController|addItem|Repository matching module|scan_items,expiry_records,products|E2E + integration|BE-10|
|expiry-records|ExpiryEntryScreen|/api/v1/expiry-records|/api/v1/expiry-records|ExpiryController|create|Repository matching module|expiry_records|E2E + integration|BE-11|
|expiry-records|Dashboard|/api/v1/expiry-records/near-expiry|/api/v1/expiry-records/near-expiry|ExpiryController|nearExpiry|Repository matching module|expiry_records,products|E2E + integration|BE-11|
|tasks|TaskCreateScreen|/api/v1/tasks|/api/v1/tasks|TasksController|create|Repository matching module|tasks,task_assignments|E2E + integration|BE-12|
|tasks|TaskListScreen|/api/v1/tasks/my|/api/v1/tasks/my|TasksController|myTasks|Repository matching module|tasks,task_assignments|E2E + integration|BE-12|
|reports|ReportsScreen|/api/v1/reports/generate|/api/v1/reports/generate|ReportsController|generate|Repository matching module|reports,report_files,scan_items|E2E + integration|BE-13|
|reports|ReportsScreen|/api/v1/reports/{id}/download|/api/v1/reports/{id}/download|ReportsController|download|Repository matching module|reports,report_files|E2E + integration|BE-13|
|media|Photo/OCRUpload|/api/v1/media/presign|/api/v1/media/presign|MediaController|presign|Repository matching module|media_assets|E2E + integration|BE-14|
|ai|ExpiryEntryScreen|/api/v1/ai/ocr/expiry|/api/v1/ai/ocr/expiry|AiController|ocrExpiry|Repository matching module|media_assets,ai_extractions|E2E + integration|BE-15|
|ai|ReportDetail|/api/v1/ai/report-summary|/api/v1/ai/report-summary|AiController|reportSummary|Repository matching module|reports,ai_extractions|E2E + integration|BE-15|
|dashboard|Dashboard|/api/v1/dashboard/summary|/api/v1/dashboard/summary|DashboardController|summary|Repository matching module|daily_store_metrics,scan_items,tasks|E2E + integration|BE-16|


## Wiring Rules
- Frontend only calls API service files.
- Backend controllers call services only.
- Services call repositories and integrations.
- SMS/AI/AWS providers are hidden behind wrappers.
---

## 2026-05-15 Upgrade Patch: Added Wiring for Inventory, GRN, Subscription, and Owner Dashboard

| Feature | Frontend Files | API Contract | Backend Route | Controller | Service | Repository | Database Tables | Tests | Phase |
|---|---|---|---|---|---|---|---|---|---|
| suppliers | SupplierListScreen | /api/v1/suppliers | /api/v1/suppliers | SuppliersController | SuppliersService | SuppliersRepository | suppliers | E2E + integration | BE-17 |
| grn | GrnEntryScreen | /api/v1/grn | /api/v1/grn | GrnController | GrnService | GrnRepository | grn_headers,grn_items | E2E + integration | BE-18 |
| grn-posting | GrnReviewScreen | /api/v1/grn/{id}/post | /api/v1/grn/{id}/post | GrnController | postGrn | GrnRepository,InventoryRepository | grn_headers,grn_items,inventory_items,inventory_batches,stock_movements | Transaction test | BE-18 |
| inventory-counts | InventoryDashboardScreen | /api/v1/inventory/counts | /api/v1/inventory/counts | InventoryController | counts | InventoryRepository | inventory_items,products | E2E + integration | BE-19 |
| stock-in | StockInScreen | /api/v1/inventory/stock-in | /api/v1/inventory/stock-in | InventoryController | stockIn | InventoryRepository | inventory_items,inventory_batches,stock_movements | Transaction test | BE-19 |
| stock-out | StockOutScreen | /api/v1/inventory/stock-out | /api/v1/inventory/stock-out | InventoryController | stockOut | InventoryRepository | inventory_items,inventory_batches,stock_movements | Negative-stock test | BE-19 |
| low-stock | LowStockScreen | /api/v1/inventory/low-stock | /api/v1/inventory/low-stock | InventoryController | lowStockAlerts | InventoryRepository | low_stock_rules,low_stock_alerts | Alert lifecycle test | BE-19 |
| subscription-status | SubscriptionScreen | /api/v1/subscriptions/status | /api/v1/subscriptions/status | SubscriptionsController | status | SubscriptionsRepository | tenant_subscriptions,subscription_plans,plan_entitlements | Entitlement test | BE-20 |
| website-event | MarketingWebsite | /api/v1/analytics/website-event | /api/v1/analytics/website-event | AnalyticsController | trackWebsiteEvent | AnalyticsRepository | website_events | Event ingestion test | BE-21 |
| lead-capture | LeadCaptureForm | /api/v1/leads | /api/v1/leads | LeadsController | createLead | LeadsRepository | marketing_leads | Duplicate lead test | BE-21 |
| app-event | MobileAppEventClient | /api/v1/analytics/app-event | /api/v1/analytics/app-event | AnalyticsController | trackAppEvent | AnalyticsRepository | app_usage_events | Event ingestion test | BE-21 |
| owner-summary | OwnerDashboard | /api/v1/owner/dashboard/summary | /api/v1/owner/dashboard/summary | OwnerDashboardController | summary | OwnerDashboardRepository | owner_daily_metrics,tenant_subscriptions,marketing_leads,app_usage_events | Owner auth test | BE-22 |
| owner-users | OwnerUsersPage | /api/v1/owner/users | /api/v1/owner/users | OwnerDashboardController | users | OwnerDashboardRepository | tenants,stores,users,tenant_subscriptions | Owner auth test | BE-22 |
| owner-subscriptions | OwnerSubscriptionsPage | /api/v1/owner/subscriptions | /api/v1/owner/subscriptions | OwnerDashboardController | subscriptions | OwnerDashboardRepository | tenant_subscriptions,subscription_events | Owner auth test | BE-22 |

