# File: API_CONTRACTS.md

# RADHA API Contracts

## Standard Response Envelope
```json
{"success": true, "data": {}, "meta": {"requestId": "req_x"}}
```

## Standard Error Envelope
```json
{"success": false, "error": {"code": "VALIDATION_ERROR", "message": "Invalid request"}, "meta": {"requestId": "req_x"}}
```

## Endpoint Matrix
|Method|Endpoint|Auth|Role|Request|Response|Database Tables|Frontend Consumer|Backend Handler|Phase|
|---|---|---|---|---|---|---|---|---|---|
|POST|/api/v1/auth/otp/request|none|public|`{mobile}`|`{requestId, expiresIn}`|otp_attempts|AuthScreen|AuthController.requestOtp|BE-05|
|POST|/api/v1/auth/otp/verify|none|public|`{mobile, otp, requestId}`|`{accessToken, refreshToken, user}`|users,user_sessions,otp_attempts|OtpVerifyScreen|AuthController.verifyOtp|BE-05|
|POST|/api/v1/auth/admin/login|none|admin|`{email,password}`|`{accessToken, user}`|users,user_sessions|AdminLogin|AuthController.adminLogin|BE-05|
|GET|/api/v1/auth/me|bearer|all|`-`|`{user,roles,storeAccess}`|users,stores|AppBootstrap|AuthController.me|BE-05|
|GET|/api/v1/products/lookup/{ean}|bearer|staff+|`-`|`{product,source,found}`|products,product_nutrition,product_health_assessments|ScannerScreen|ProductsController.lookup|BE-07|
|POST|/api/v1/products|bearer|manager/admin|`ProductCreateDto`|`{product}`|products,product_sources|ProductCreateForm|ProductsController.create|BE-07|
|POST|/api/v1/ean-lists/import|bearer|manager/admin|`multipart xlsx/csv`|`{listId,validRows,invalidRows}`|ean_lists,ean_list_items,ean_import_errors|AdminEANImport|EanListsController.import|BE-09|
|POST|/api/v1/ean-lists/{id}/validate|bearer|staff+|`{ean,storeId}`|`{exists,status,matchedItem}`|ean_list_items|BulkScanScreen|EanListsController.validate|BE-09|
|POST|/api/v1/scan-sessions|bearer|staff+|`{type,storeId,taskId?}`|`{session}`|scan_sessions|ScannerScreen|ScanController.createSession|BE-10|
|POST|/api/v1/scan-sessions/{id}/items|bearer|staff+|`ScanItemCreateDto`|`{scanItem,expiryStatus,eanStatus}`|scan_items,expiry_records,products|ScannerScreen|ScanController.addItem|BE-10|
|POST|/api/v1/expiry-records|bearer|staff+|`ExpiryRecordDto`|`{expiryRecord,status}`|expiry_records|ExpiryEntryScreen|ExpiryController.create|BE-11|
|GET|/api/v1/expiry-records/near-expiry|bearer|manager+|`query storeId,days`|`{items[]}`|expiry_records,products|Dashboard|ExpiryController.nearExpiry|BE-11|
|POST|/api/v1/tasks|bearer|manager/admin|`TaskCreateDto`|`{task}`|tasks,task_assignments|TaskCreateScreen|TasksController.create|BE-12|
|GET|/api/v1/tasks/my|bearer|staff+|`query status`|`{tasks[]}`|tasks,task_assignments|TaskListScreen|TasksController.myTasks|BE-12|
|POST|/api/v1/reports/generate|bearer|manager/admin/auditor|`ReportRequestDto`|`{reportId,status}`|reports,report_files,scan_items|ReportsScreen|ReportsController.generate|BE-13|
|GET|/api/v1/reports/{id}/download|bearer|manager/admin/auditor|`format=xlsx/pdf`|`signed url`|reports,report_files|ReportsScreen|ReportsController.download|BE-13|
|POST|/api/v1/media/presign|bearer|staff+|`{assetType,mime,size}`|`{mediaId,uploadUrl,key}`|media_assets|Photo/OCRUpload|MediaController.presign|BE-14|
|POST|/api/v1/ai/ocr/expiry|bearer|staff+|`{mediaId}`|`{suggestedDates,confidence}`|media_assets,ai_extractions|ExpiryEntryScreen|AiController.ocrExpiry|BE-15|
|POST|/api/v1/ai/report-summary|bearer|manager/admin|`{reportId}`|`{summary}`|reports,ai_extractions|ReportDetail|AiController.reportSummary|BE-15|
|GET|/api/v1/dashboard/summary|bearer|manager/admin|`query storeId,dateRange`|`{totals,charts}`|daily_store_metrics,scan_items,tasks|Dashboard|DashboardController.summary|BE-16|


## Rate Limits
| Endpoint Group | Limit |
|---|---|
| OTP request | 3 per phone/hour, 10 per IP/hour |
| Product lookup | 120/min/user |
| Scan item create | 300/min/user |
| EAN import | 10/day/manager |
| Report generate | 20/day/store |
| Media presign | 100/day/user |
| AI OCR/report summary | 50/day/store initially |
---

## 2026-05-15 Upgrade Patch: Inventory, GRN, Subscription, and Owner APIs

### Added Endpoint Matrix
| Method | Endpoint | Auth | Role | Request | Response | Database Tables | Frontend Consumer | Backend Handler | Phase |
|---|---|---|---|---|---|---|---|---|---|
| GET | /api/v1/suppliers | bearer | manager/admin | `query storeId` | `{suppliers[]}` | suppliers | SupplierListScreen | SuppliersController.list | BE-17 |
| POST | /api/v1/suppliers | bearer | manager/admin | `SupplierCreateDto` | `{supplier}` | suppliers | SupplierCreateSheet | SuppliersController.create | BE-17 |
| POST | /api/v1/grn | bearer | manager/admin | `GrnCreateDto` | `{grn}` | grn_headers | GrnEntryScreen | GrnController.create | BE-18 |
| POST | /api/v1/grn/{id}/items | bearer | manager/admin | `GrnItemCreateDto[]` | `{items[]}` | grn_items | GrnItemEntryScreen | GrnController.addItems | BE-18 |
| POST | /api/v1/grn/{id}/post | bearer | manager/admin | `{confirm:true}` | `{grn,stockMovements[]}` | grn_headers,grn_items,inventory_items,inventory_batches,stock_movements | GrnReviewScreen | GrnController.post | BE-18 |
| GET | /api/v1/grn | bearer | manager/admin | `query storeId,status,cursor` | `{grns[],nextCursor}` | grn_headers | GrnListScreen | GrnController.list | BE-18 |
| POST | /api/v1/inventory/stock-in | bearer | manager/admin | `StockInDto` | `{movement,inventoryItem}` | stock_movements,inventory_items,inventory_batches | StockInScreen | InventoryController.stockIn | BE-19 |
| POST | /api/v1/inventory/stock-out | bearer | manager/admin | `StockOutDto` | `{movement,inventoryItem}` | stock_movements,inventory_items,inventory_batches | StockOutScreen | InventoryController.stockOut | BE-19 |
| GET | /api/v1/inventory/counts | bearer | staff+ | `query storeId,categoryId,cursor` | `{items[],summary,nextCursor}` | inventory_items,products | InventoryDashboardScreen | InventoryController.counts | BE-19 |
| GET | /api/v1/inventory/low-stock | bearer | manager/admin | `query storeId,status` | `{alerts[]}` | low_stock_alerts,inventory_items,products | LowStockScreen | InventoryController.lowStock | BE-19 |
| POST | /api/v1/inventory/low-stock-rules | bearer | manager/admin | `LowStockRuleDto` | `{rule}` | low_stock_rules | LowStockRulesScreen | InventoryController.upsertRule | BE-19 |
| GET | /api/v1/subscriptions/status | bearer | tenant_admin | `-` | `{trial,plan,entitlements,limits}` | tenant_subscriptions,subscription_plans,plan_entitlements | SubscriptionScreen | SubscriptionsController.status | BE-20 |
| POST | /api/v1/subscriptions/events | service/bearer | system/owner | `SubscriptionEventDto` | `{accepted:true}` | subscription_events,tenant_subscriptions | BillingWebhook | SubscriptionsController.event | BE-20 |
| POST | /api/v1/analytics/website-event | public | public | `WebsiteEventDto` | `{accepted:true}` | website_events | MarketingWebsite | AnalyticsController.websiteEvent | BE-21 |
| POST | /api/v1/leads | public | public | `LeadCreateDto` | `{leadId}` | marketing_leads,website_events | MarketingWebsite | LeadsController.create | BE-21 |
| POST | /api/v1/analytics/app-event | bearer | all | `AppUsageEventDto` | `{accepted:true}` | app_usage_events | MobileApp | AnalyticsController.appEvent | BE-21 |
| GET | /api/v1/owner/dashboard/summary | bearer | owner | `query range` | `{kpis,series,planBreakdown}` | owner_daily_metrics,tenant_subscriptions,app_usage_events,marketing_leads | OwnerDashboard | OwnerDashboardController.summary | BE-22 |
| GET | /api/v1/owner/users | bearer | owner | `query plan,status,cursor` | `{tenants[],nextCursor}` | tenants,users,tenant_subscriptions | OwnerUsersPage | OwnerDashboardController.users | BE-22 |
| GET | /api/v1/owner/subscriptions | bearer | owner | `query status,plan,cursor` | `{subscriptions[],nextCursor}` | tenant_subscriptions,subscription_events | OwnerSubscriptionsPage | OwnerDashboardController.subscriptions | BE-22 |
| GET | /api/v1/owner/leads | bearer | owner | `query status,cursor` | `{leads[],nextCursor}` | marketing_leads | OwnerLeadsPage | OwnerDashboardController.leads | BE-22 |

### BE-28 v2 — Razorpay Payments
| Method | Endpoint | Auth | Role | Request | Response | Database Tables | Frontend Consumer | Backend Handler | Phase |
|---|---|---|---|---|---|---|---|---|---|
| POST | /api/v1/payments/checkout | bearer | all (authenticated) | `{planId,billingCycle}` | `{razorpayOrderId,keyId,amountPaise,currency,prefill,notes}` | razorpay_orders,subscription_plans,users | SubscriptionUpgradeScreen | PaymentsController.checkout | BE-28 v2 |
| POST | /api/v1/payments/verify | bearer | all (authenticated) | `{razorpayOrderId,razorpayPaymentId,razorpaySignature}` | `{ok,razorpayOrderId,status,subscription}` | razorpay_orders,tenant_subscriptions,subscription_events | SubscriptionUpgradeScreen | PaymentsController.verify | BE-28 v2 |
| POST | /api/v1/payments/refund | bearer | admin/owner | `{razorpayPaymentId,amountPaise?,reason}` | `{ok,refundId,status,amountPaise}` | razorpay_orders,audit_logs | OwnerSubscriptionsPage | PaymentsController.refund | BE-28 v2 |
| POST | /api/v1/payments/webhooks/razorpay | none (HMAC) | razorpay | `RazorpayWebhookEnvelope (signed)` | `{ok,duplicate,event,inboxId}` | payment_webhooks_inbox,razorpay_orders,tenant_subscriptions | RazorpayDashboard | PaymentsController.razorpayWebhook | BE-28 v2 |

### Saved Products (FE-16) — Consumer REST surface
| Method | Endpoint | Auth | Role | Request | Response | Database Tables | Frontend Consumer | Backend Handler | Phase |
|---|---|---|---|---|---|---|---|---|---|
| GET | /api/v1/saved-products | bearer | consumer/all (authenticated) | `query cursor,limit` | `{items[],nextCursor}` | saved_products | SavedProductsScreen | SavedProductsController.list | BE-38 |
| POST | /api/v1/saved-products | bearer | consumer/all (authenticated) | `{productName,productId?,barcode?,expiresAt?,notes?}` | `SavedProductDto` | saved_products | SavedProductsScreen | SavedProductsController.create | BE-38 |
| DELETE | /api/v1/saved-products/:id | bearer | consumer/all (authenticated) | `path id` | `204 No Content` | saved_products | SavedProductsScreen | SavedProductsController.remove | BE-38 |

### Entitlement Enforcement
All paid/limited features must call a shared `EntitlementGuard` before allowing exports, AI report summaries, staff-user additions, advanced reports, and plan-limited inventory usage.

### API Non-Goals
Do not add GST invoice, POS checkout, accounting ledger, printer, or sales payment endpoints in V1.

