# Requirements Document

## Introduction

RADHA (Retail Assistant for Data, Health & Audits) is a production-grade retail audit and operations SaaS platform for Indian retail teams. The platform provides barcode scanning, product health analysis, expiry tracking, EAN verification, lightweight inventory management, GRN inward processing, task management, subscription-based access control, owner analytics, and AI/OCR assistance across mobile (Flutter), marketing website (Next.js), private owner dashboard (Next.js), and a NestJS backend with API, worker, and scheduler processes.

These requirements are derived from the approved design document at `.kiro/specs/radha-platform-design/design.md`. They cover the functional behaviour of every backend module, every product surface, and every cross-cutting concern (multi-tenant isolation, authentication, authorization, audit logging, performance, security). They are written in EARS form for use as a contract between the design and the upcoming task plan.

**Scope reminder**: RADHA is NOT a GST billing, POS, accounting, or full ERP system. Requirements that touch GST, sales ledgers, or full accounting are explicitly out of scope.

**Scale target**: 10,000 tenants/users initially with database optimization as a critical priority.

## Glossary

- **RADHA_System**: The whole RADHA platform including mobile app, marketing site, owner dashboard, backend API, worker, and scheduler.
- **Backend_API**: The NestJS REST API process serving mobile and web clients.
- **Worker**: The NestJS background worker process for imports, OCR, reports, AI summaries, and notifications.
- **Scheduler**: The NestJS scheduled job process for reminders, metric rollups, trial-expiry checks, and cleanup.
- **Mobile_App**: The Flutter mobile application for retail clients (Android and iOS).
- **Marketing_Site**: The public Next.js marketing website.
- **Owner_Dashboard**: The private Next.js dashboard for the RADHA business owner.
- **Tenant**: A retail business customer that owns one or more stores and users.
- **Store**: A physical retail location belonging to a tenant.
- **User**: A person with login credentials. Roles are `super_admin`, `tenant_admin`, `manager`, `staff`, `auditor`.
- **Owner_User**: The internal RADHA business owner who logs in to the Owner_Dashboard.
- **Auth_Service**: The backend module responsible for OTP login, admin login, JWT issuance, refresh-token rotation, and session revocation.
- **Authorization_Service**: The backend module responsible for role-based and tenant/store-scoped access checks.
- **Products_Service**: The backend module responsible for product lookup, Open Food Facts fallback, caching, and CRUD.
- **Health_Score_Service**: The backend module that computes rule-based health assessments.
- **Ean_Lists_Service**: The backend module responsible for parsing, validating, and storing approved EAN lists.
- **Scan_Sessions_Service**: The backend module responsible for scan session lifecycle and per-scan pass/fail evaluation.
- **Expiry_Service**: The backend module responsible for expiry records and expiry-status calculation.
- **Tasks_Service**: The backend module for task CRUD, assignment, transitions, evidence, and audit events.
- **Inventory_Service**: The backend module for stock in/out, batches, low-stock thresholds, and alerts.
- **GRN_Service**: The backend module for Goods Receipt Notes including create, items, review, and atomic posting.
- **Subscription_Service**: The backend module that owns subscription state, plans, trials, entitlements, and usage limits.
- **Reports_Service**: The backend module for asynchronous report generation, Excel/PDF export, S3 storage, and downloads.
- **Owner_Analytics_Service**: The backend module that captures website events, leads, app usage, and aggregates owner-facing metrics.
- **AI_Service**: The backend module that wraps AI/OCR providers (rule engine, ML Kit on-device, Gemini, optional AWS Rekognition).
- **AI_Provider**: An implementation of the AiProvider abstraction (Gemini, RuleEngine, GemmaLocal, etc.).
- **Audit_Logger**: The mechanism that records audit_log rows for every business state change.
- **Entitlement_Guard**: The decorator/guard that blocks operations when the tenant lacks an entitlement or has exceeded a limit.
- **Approved_EAN_List**: The currently active `ean_lists` row for a store, with its `ean_list_items`.
- **Approved_EAN**: An EAN that exists in the active `Approved_EAN_List` for the relevant store.
- **EAN**: A barcode in EAN-8, EAN-13, or UPC-A format.
- **GRN**: Goods Receipt Note, capturing supplier inward stock with batches and expiry.
- **Health_Assessment**: A `product_health_assessments` row with `overall_score`, `health_label`, flags, reasons, and `rule_version`.
- **Expiry_Status**: One of `safe`, `near_expiry`, `expired`.
- **Plan**: One of `free_trial`, `basic` (₹49/mo), `standard` (₹99/mo), `premium` (₹199/mo).
- **Trial**: The 3-month free trial granted on tenant registration.
- **Cursor_Pagination**: List pagination using `(created_at, id)` cursors instead of OFFSET.
- **PII**: Personally identifiable information such as mobile numbers, email addresses, OTPs, and tokens.

## Requirements

### Requirement 1: OTP Authentication for Retail Users

**User Story:** As a retail user (owner, manager, staff, or auditor), I want to log in to the Mobile_App using my mobile number and an OTP, so that I can access my store's data without remembering a password.

#### Acceptance Criteria

1. WHEN the Mobile_App submits an OTP request for a 10-digit Indian mobile number, THE Auth_Service SHALL generate a 6-digit OTP, store its bcrypt hash in `otp_attempts`, deliver the OTP via MSG91, and return a `requestId` and `expiresIn`.
2. THE Auth_Service SHALL store OTPs only as bcrypt hashes and SHALL NOT persist plain-text OTPs.
3. IF a mobile number has 3 or more `otp_attempts` rows created within the last 60 minutes, THEN THE Auth_Service SHALL reject further OTP requests with HTTP 429 and a `retry-after` header indicating seconds until the next allowed attempt.
4. IF an IP address has 10 or more OTP requests within the last 60 minutes, THEN THE Auth_Service SHALL reject further requests from that IP with HTTP 429.
5. WHEN the Mobile_App submits a `(mobile, otp, requestId)` triple, THE Auth_Service SHALL verify the OTP against the stored hash for that `requestId`, and on success SHALL mark the OTP verified, issue a JWT access token and refresh token, create a `user_sessions` row with the hashed refresh token, and return the user profile, roles, and store access list.
6. IF the submitted OTP does not match the stored hash, THEN THE Auth_Service SHALL increment the `attempts` counter and SHALL reject the request with HTTP 401.
7. IF the stored OTP has already been verified, has expired, or has reached 3 failed attempts, THEN THE Auth_Service SHALL reject verification and invalidate the `requestId`.
8. THE Auth_Service SHALL issue access tokens that expire in 15 minutes and refresh tokens that expire in 7 days.

### Requirement 2: Admin Password Authentication

**User Story:** As a super admin or RADHA business owner, I want to log in with email and password, so that I can access admin and owner dashboards.

#### Acceptance Criteria

1. WHEN an admin user submits email and password, THE Auth_Service SHALL look up the user by email, verify the password against the bcrypt-hashed `password_hash`, and on success SHALL return a JWT access token, refresh token, profile, and role list.
2. THE Auth_Service SHALL hash admin passwords with bcrypt at cost factor 12.
3. IF the email is unknown or the password does not match, THEN THE Auth_Service SHALL return HTTP 401 with a generic error message that does not disclose which field was wrong.

### Requirement 3: Refresh Token Rotation and Session Revocation

**User Story:** As a logged-in user, I want my session to refresh transparently and be revocable on logout or compromise, so that my account remains secure.

#### Acceptance Criteria

1. WHEN the Mobile_App or Owner_Dashboard submits a valid, non-expired, non-revoked refresh token, THE Auth_Service SHALL revoke the submitted refresh token in `user_sessions`, issue a new access token and a new refresh token, and persist the new refresh-token hash.
2. IF the submitted refresh token is missing, expired, revoked, or does not match any `user_sessions` row, THEN THE Auth_Service SHALL return HTTP 401 and SHALL NOT issue new tokens.
3. WHEN a user requests session revocation for a given `sessionId`, THE Auth_Service SHALL set `revoked_at` on that `user_sessions` row.
4. WHILE a `user_sessions` row has `revoked_at IS NOT NULL` or `expires_at < now()`, THE Auth_Service SHALL reject any refresh attempt that uses its token.

### Requirement 4: Role-Based Authorization

**User Story:** As a tenant admin, I want roles to control who can do what, so that staff cannot perform manager-only actions.

#### Acceptance Criteria

1. THE Authorization_Service SHALL recognize exactly the roles `super_admin`, `tenant_admin`, `manager`, `staff`, and `auditor`.
2. WHEN any controller endpoint requires a permission, THE Authorization_Service SHALL deny the request with HTTP 403 unless the calling user holds a role that grants that permission.
3. THE Authorization_Service SHALL deny operations marked `manage_users`, `import_ean_lists`, `post_grn`, `view_analytics`, or `manage_inventory` to users whose effective role at the target store is `staff` or `auditor`.
4. THE Authorization_Service SHALL allow `super_admin` users to perform any operation across any tenant.

### Requirement 5: Tenant and Store Scoping

**User Story:** As a tenant, I want my data to be isolated from other tenants, so that no other business can see or modify my records.

#### Acceptance Criteria

1. THE Backend_API SHALL include `tenant_id` (directly or via `store_id`) in every query against multi-tenant tables.
2. IF a request asks for a resource whose `tenant_id` differs from the calling user's `tenant_id`, THEN THE Authorization_Service SHALL reject the request with HTTP 403 and record an unauthorized-access entry in `audit_logs`.
3. IF a request asks for a `store_id` for which the calling user has no `user_store_access` row (and is not `super_admin`), THEN THE Authorization_Service SHALL reject the request with HTTP 403.
4. WHEN a list endpoint returns rows from a multi-tenant table, THE Backend_API SHALL ensure every returned row has a `tenant_id` matching the calling user's `tenant_id`.

### Requirement 6: Product Lookup by EAN with Open Food Facts Fallback

**User Story:** As staff, I want to scan a barcode and immediately see product details, so that I can decide what to do with the product on the shelf.

#### Acceptance Criteria

1. WHEN the Mobile_App requests `GET /products/lookup/{ean}` for a `store_id`, THE Products_Service SHALL first look for an active product matching `ean` scoped to the user's tenant, then a global product (`tenant_id IS NULL`), and return the first match with `source = 'internal'`.
2. IF no internal product is found for an `ean`, THEN THE Products_Service SHALL query the Open Food Facts API for that `ean`, and on a successful response SHALL persist a new `products` row with `source = 'open_food_facts'`, persist `product_nutrition` if available, and return the cached product.
3. IF Open Food Facts returns no result or fails, THEN THE Products_Service SHALL return a `ProductLookupResult` with `found = false` and `product = null`.
4. WHEN a product is returned by lookup, THE Products_Service SHALL include the latest `Health_Assessment` and `product_nutrition` in the response when those rows exist.
5. THE Products_Service SHALL validate that the input `ean` is a syntactically valid EAN-8, EAN-13, or UPC-A barcode before attempting any lookup, and SHALL reject invalid input with HTTP 400.

### Requirement 7: Manual Product Creation and Update

**User Story:** As a tenant admin or manager, I want to create or update products that are not in any external catalog, so that store-specific items are still scannable.

#### Acceptance Criteria

1. WHEN a manager or tenant admin submits a `ProductCreateDto` with a unique tenant-scoped `ean`, THE Products_Service SHALL insert a `products` row with `source = 'manual'`, `tenant_id` set to the caller's tenant, and SHALL write an audit_log entry with action `product_created`.
2. IF a `ProductCreateDto` references an `ean` that already exists for the same tenant (or globally with no tenant), THEN THE Products_Service SHALL reject the request with HTTP 409.
3. WHEN a manager or tenant admin updates a product, THE Products_Service SHALL update only fields permitted by `ProductUpdateDto`, recompute the `Health_Assessment` if nutrition fields changed, and write an audit_log entry with action `product_updated` containing both `oldValue` and `newValue`.

### Requirement 8: Rule-Based Health Scoring

**User Story:** As a parent shopping for groceries, I want to see whether a product is healthy and child-suitable, so that I can make informed choices.

#### Acceptance Criteria

1. WHEN the Health_Score_Service is asked to compute a `Health_Assessment` for a `productId` with associated `product_nutrition`, THE Health_Score_Service SHALL apply the configured rule version deterministically and produce a single `product_health_assessments` row with `overall_score` in `[0, 100]`.
2. THE Health_Score_Service SHALL set `health_label = 'healthy'` WHEN `overall_score >= 70`, `health_label = 'moderate'` WHEN `overall_score` is in `[40, 70)`, and `health_label = 'unhealthy'` WHEN `overall_score < 40`.
3. WHERE the product nutrition exceeds the configured `sugarThresholdPer100g`, THE Health_Score_Service SHALL set `high_sugar = true`, deduct points from `overall_score`, and append a reason to `reasons`.
4. WHERE the product nutrition exceeds the configured `sodiumThresholdPer100g`, THE Health_Score_Service SHALL set `high_salt = true`, deduct points, and append a reason.
5. WHERE the product nutrition exceeds the configured `saturatedFatThresholdPer100g`, THE Health_Score_Service SHALL set `high_fat = true`, deduct points, and append a reason.
6. WHERE the ingredients contain any string in the configured `processedIndicators` list, THE Health_Score_Service SHALL set `processed = true`, deduct points, and append a reason.
7. WHERE the ingredients contain any string in the configured `childUnsafeIngredients` list, THE Health_Score_Service SHALL set `child_suitable = false` and append a reason naming the offending ingredient.
8. THE Health_Score_Service SHALL produce identical `Health_Assessment` outputs for identical inputs and rule version (deterministic scoring).
9. THE Health_Score_Service SHALL stamp every `Health_Assessment` with the `rule_version` used to compute it.

### Requirement 9: EAN List Excel/CSV Import

**User Story:** As a manager, I want to upload an approved EAN list in Excel or CSV, so that staff can verify which products belong on the shelf.

#### Acceptance Criteria

1. WHEN a manager uploads an Excel or CSV file for a `store_id` with permission `import_ean_lists`, THE Ean_Lists_Service SHALL parse rows, validate each row for non-empty EAN, valid EAN-8/EAN-13/UPC-A format, and absence of duplicates within the file, and SHALL produce an `EanImportResult` with row-level errors.
2. WHEN an import has at least one valid row, THE Ean_Lists_Service SHALL deactivate the previous active `ean_lists` row for the store, insert a new `ean_lists` row with the next `version`, insert all valid `ean_list_items`, and insert one `ean_import_errors` row per invalid row, all within a single database transaction.
3. IF every row in the file is invalid, THEN THE Ean_Lists_Service SHALL set `EanImportResult.status = 'failed'`, SHALL NOT deactivate the existing active list, and SHALL persist `ean_import_errors` rows under a non-active list reference.
4. WHEN at least one row is valid and at least one row is invalid, THE Ean_Lists_Service SHALL set `EanImportResult.status = 'partial'` and include all errors with their original row numbers.
5. THE Ean_Lists_Service SHALL ensure that `ean_list_items` is unique on `(list_id, ean)`.
6. WHEN the import succeeds, THE Audit_Logger SHALL record an audit_log entry with action `ean_list_imported`, including counts of valid and invalid rows.

### Requirement 10: Approved-EAN Lookup and Validation

**User Story:** As staff conducting an audit, I want every scanned EAN to be marked as approved or not approved, so that I can find unauthorized products on the shelf.

#### Acceptance Criteria

1. WHEN the Backend_API is asked to validate an `ean` for a `store_id`, THE Ean_Lists_Service SHALL look it up in the currently active `ean_lists` for that store and return `status = 'approved'` if a matching `ean_list_items` row exists, otherwise `status = 'not_approved'`.
2. THE Ean_Lists_Service SHALL provide an `ean` lookup that completes in less than 50 ms at the p95 service-level latency target documented in the design.
3. THE Ean_Lists_Service SHALL maintain a database index that supports fast `(list_id, ean)` membership checks.

### Requirement 11: Scan Session Lifecycle

**User Story:** As staff, I want to start a scan session, scan items, and finalize a summary, so that I can complete bulk audits.

#### Acceptance Criteria

1. WHEN a user creates a scan session for a store with type `bulk_scan`, `expiry_audit`, or `ean_verification`, THE Scan_Sessions_Service SHALL insert a `scan_sessions` row with `status = 'in_progress'`, `started_by` set to the caller, and `started_at = now()`.
2. WHILE a scan session is `in_progress`, THE Scan_Sessions_Service SHALL accept additions of `scan_items` rows and SHALL reject additions to sessions whose `status` is `completed` or `cancelled` with HTTP 409.
3. WHEN a scan session is completed, THE Scan_Sessions_Service SHALL set `status = 'completed'`, set `completed_at = now()`, and return a `SessionSummary` containing `totalScans`, `uniqueProducts`, `eanPassCount`, `eanFailCount`, `duplicateCount`, and `duration`.
4. THE Scan_Sessions_Service SHALL ensure `scan_sessions.total_scans` always equals the count of `scan_items` rows referencing that session.

### Requirement 12: Scan Item Recording with Pass/Fail and Duplicate Detection

**User Story:** As staff, I want each scan to be evaluated immediately, so that I can react to non-approved items.

#### Acceptance Criteria

1. WHEN a `scan_items` row is added to an active session, THE Scan_Sessions_Service SHALL store the `ean`, the `product_id` if known, `scanned_at`, optional `location`, optional `notes`, and the `scanned_by` user.
2. WHEN a `scan_items` row is added in a session of type `ean_verification`, THE Scan_Sessions_Service SHALL set `ean_status = 'pass'` if the EAN is in the active Approved_EAN_List for the session's store, `ean_status = 'fail'` if it is not, and `ean_status = 'unknown'` if no active list exists.
3. WHEN a `scan_items` row's `ean` already appears in the same session, THE Scan_Sessions_Service SHALL set `is_duplicate = true` on the new row and SHALL still record the row.
4. WHEN a scan item is added without a `product_id`, THE Scan_Sessions_Service SHALL invoke the Products_Service to look up the EAN and link the resulting `product_id` if a product is found.

### Requirement 13: Expiry Record Creation and Status

**User Story:** As staff, I want to record expiry dates on stock and immediately know whether the item is safe, near expiry, or expired, so that I can act on near-expiry stock.

#### Acceptance Criteria

1. WHEN a user submits a `CreateExpiryRecordDto` with a future or past `expiryDate`, THE Expiry_Service SHALL insert an `expiry_records` row, compute `Expiry_Status` and `days_until_expiry`, and persist them on the row.
2. WHILE `expiryDate < today`, THE Expiry_Service SHALL set `status = 'expired'`.
3. WHILE `expiryDate >= today` and `daysBetween(today, expiryDate) <= near_expiry_days` for the product's category (default 30 days when no category threshold exists), THE Expiry_Service SHALL set `status = 'near_expiry'`.
4. WHILE `daysBetween(today, expiryDate) > near_expiry_days` for the product's category, THE Expiry_Service SHALL set `status = 'safe'`.
5. IF `manufacturingDate` is provided and is later than `expiryDate`, THEN THE Expiry_Service SHALL reject the request with HTTP 400 and an explanatory error.
6. WHEN an `expiry_records` row originates from OCR, THE Expiry_Service SHALL persist `ocr_confidence` and require `confirmed_by_user = true` before treating the entry as user-confirmed for downstream alerts.

### Requirement 14: Near-Expiry and Expired Listing

**User Story:** As a manager, I want to see all stock that is near-expiry or expired in my store, so that I can plan removals and discounts.

#### Acceptance Criteria

1. WHEN a manager requests near-expiry items for a `store_id` with a `daysThreshold`, THE Expiry_Service SHALL return all `expiry_records` for that store whose `expiry_date` is in `[today, today + daysThreshold]` ordered by `expiry_date` ascending.
2. WHEN a manager requests expired items for a `store_id`, THE Expiry_Service SHALL return all `expiry_records` for that store with `status = 'expired'` ordered by `expiry_date` ascending.
3. THE Expiry_Service SHALL paginate near-expiry and expired listings using Cursor_Pagination with a maximum page size of 100.

### Requirement 15: Category-Specific Expiry Thresholds

**User Story:** As a tenant admin, I want to configure expiry thresholds per category, so that pharmacy items get a longer warning window than fresh foods.

#### Acceptance Criteria

1. WHEN a tenant admin updates `expiry_thresholds` for a `category` with `near_expiry_days` and `critical_days`, THE Expiry_Service SHALL upsert the row and write an audit_log entry with action `expiry_threshold_updated`.
2. THE Expiry_Service SHALL use `(near_expiry_days = 30, critical_days = 7)` as the default threshold for any category that does not have an `expiry_thresholds` row.

### Requirement 16: Task Lifecycle and Assignment

**User Story:** As a manager, I want to create tasks for staff and audit their completion, so that I can run organized store operations.

#### Acceptance Criteria

1. WHEN a manager creates a task with a `title`, `type`, `storeId`, optional `assignedTo`, optional `dueDate`, `priority`, and `requiresEvidence`, THE Tasks_Service SHALL insert a `tasks` row with `status = 'pending'` and `created_by` set to the caller.
2. WHEN a task is assigned to a user, THE Tasks_Service SHALL update `assigned_to`, write a `task_events` row with `event_type = 'assigned'`, and ensure the assignee has `user_store_access` to the task's store.
3. THE Tasks_Service SHALL only allow status transitions `pending → in_progress → completed`, `pending → cancelled`, and `in_progress → cancelled`, and SHALL reject any other transition with HTTP 409.
4. WHEN a task with `requires_evidence = true` is completed without `evidenceUrls` or a linked `scanSessionId`, THE Tasks_Service SHALL reject the completion with HTTP 400.
5. WHEN a task's `due_date < now()` and `status` is `pending` or `in_progress`, THE Scheduler SHALL mark the task as `overdue` in the next overdue sweep.
6. WHEN any task field changes, THE Tasks_Service SHALL append a `task_events` row capturing `event_type`, `old_value`, `new_value`, and `created_by`.

### Requirement 17: Stock In and Stock Out Movements

**User Story:** As a manager, I want to record stock-in and stock-out events with reasons, so that I have an auditable lightweight inventory ledger.

#### Acceptance Criteria

1. WHEN a manager submits a `StockInDto` for a `(productId, storeId)` with `quantity > 0` and a `reason` from the configured `StockInReason` enum, THE Inventory_Service SHALL upsert the `inventory_items` row, increase `current_stock` by `quantity`, set `last_movement_at = now()`, insert a `stock_movements` row with `movement_type = 'stock_in'`, and write an audit_log entry.
2. WHEN a manager submits a `StockOutDto`, THE Inventory_Service SHALL decrease `current_stock` by `quantity`, insert a `stock_movements` row with `movement_type = 'stock_out'`, and write an audit_log entry.
3. IF a `StockOutDto` would cause `current_stock` to become negative, THEN THE Inventory_Service SHALL reject the request with HTTP 400 and SHALL NOT insert any movement.
4. THE Inventory_Service SHALL ensure `inventory_items.current_stock` always equals `Σ(stock_movements where movement_type='stock_in') − Σ(stock_movements where movement_type='stock_out')` for that `inventory_item_id`.
5. WHERE a `StockInDto` includes both `batchNumber` and `expiryDate`, THE Inventory_Service SHALL upsert an `inventory_batches` row keyed by `(inventory_item_id, batch_number)` and adjust its `quantity` by the movement amount.

### Requirement 18: Low-Stock Rules and Alerts

**User Story:** As a manager, I want low-stock alerts whenever stock for a product or category drops below my threshold, so that I never run out unexpectedly.

#### Acceptance Criteria

1. WHEN a manager upserts a `low_stock_rules` row for a `(store_id, product_id)` or `(store_id, category)`, THE Inventory_Service SHALL persist the threshold and write an audit_log entry with action `low_stock_rule_updated`.
2. WHEN any inventory movement changes `inventory_items.current_stock` so that `current_stock <= threshold` and no active `low_stock_alerts` row exists for that item, THE Inventory_Service SHALL insert a new `low_stock_alerts` row with `status = 'active'`.
3. WHEN any inventory movement changes `inventory_items.current_stock` so that `current_stock > threshold` and an active `low_stock_alerts` row exists, THE Inventory_Service SHALL update that row's `status = 'resolved'` and `resolved_at = now()`.
4. THE Inventory_Service SHALL guarantee that for any `(inventory_item)` either exactly one active `low_stock_alerts` row exists when `current_stock <= threshold`, or no active alert exists when `current_stock > threshold`.

### Requirement 19: GRN Header and Item Entry

**User Story:** As a manager, I want to record a Goods Receipt Note with supplier, invoice, and per-item batches, so that incoming stock is captured before posting.

#### Acceptance Criteria

1. WHEN a manager creates a GRN with `storeId`, `supplierId`, `invoiceNumber`, and `invoiceDate`, THE GRN_Service SHALL insert a `grn_headers` row with `status = 'draft'`, `total_items = 0`, `total_quantity = 0`, and `created_by` set to the caller.
2. WHEN a manager adds GRN items with `productId`, `quantity > 0`, optional `batchNumber`, optional `manufacturingDate`, optional `expiryDate`, and optional `unitPrice`, THE GRN_Service SHALL insert one `grn_items` row per entry and update the `grn_headers.total_items` and `total_quantity` aggregates.
3. IF a GRN item has `manufacturingDate` later than `expiryDate`, THEN THE GRN_Service SHALL reject the item with HTTP 400.
4. WHEN a manager moves a `draft` GRN to `pending_review`, THE GRN_Service SHALL allow the transition only if the GRN has at least one item and SHALL append an audit_log entry.

### Requirement 20: Atomic GRN Posting to Inventory

**User Story:** As a manager, I want posting a GRN to atomically update inventory, batches, and resolve low-stock alerts, so that the system never leaves stock in a half-updated state.

#### Acceptance Criteria

1. WHEN a user with `post_grn` permission posts a GRN whose `status = 'pending_review'`, THE GRN_Service SHALL begin a database transaction, set `grn_headers.status = 'posted'`, set `posted_by` and `posted_at`, insert a `stock_movements` row per `grn_items`, upsert `inventory_items`, upsert `inventory_batches` for items with `expiry_date`, resolve applicable `low_stock_alerts`, write an audit_log entry, and commit the transaction.
2. IF any step in posting a GRN fails, THEN THE GRN_Service SHALL roll back the entire transaction and SHALL leave the GRN's `status` unchanged.
3. THE GRN_Service SHALL ensure that for every `grn_headers` row with `status = 'posted'` exactly one `stock_movements` row exists per `grn_items` row with `reference_type = 'grn'` and `reference_id = grn.id`.
4. WHEN a GRN is posted, THE GRN_Service SHALL return a `GrnPostResult` containing the updated GRN, the list of stock movements, the list of updated inventory items, and the count of low-stock alerts resolved.
5. THE GRN_Service SHALL reject posting attempts on GRNs whose `status` is not `pending_review` with HTTP 409.

### Requirement 21: Subscription Plans, Trial, and Lifecycle

**User Story:** As a tenant admin, I want a 3-month free trial and clearly priced plans, so that I can evaluate RADHA before paying.

#### Acceptance Criteria

1. WHEN a tenant is created via registration, THE Subscription_Service SHALL insert a `tenant_subscriptions` row with `status = 'trial'`, `current_period_start = now()`, `trial_ends_at = now() + 3 months`, and `current_period_end = trial_ends_at`, and SHALL insert a `subscription_events` row with `event_type = 'trial_started'`.
2. THE Subscription_Service SHALL recognize plans `free_trial`, `basic` (₹49/month), `standard` (₹99/month), and `premium` (₹199/month).
3. WHILE the Scheduler runs the trial-expiry sweep, IF a `tenant_subscriptions` row has `status = 'trial'` and `trial_ends_at < now()`, THEN THE Subscription_Service SHALL set `status = 'expired'` and insert a `subscription_events` row with `event_type = 'trial_expired'`.
4. WHEN a tenant upgrades, downgrades, or cancels its plan, THE Subscription_Service SHALL update `tenant_subscriptions` accordingly and insert a `subscription_events` row with the corresponding `event_type` (`upgraded`, `downgraded`, or `cancelled`).

### Requirement 22: Plan Entitlements and Feature Limits

**User Story:** As the system, I want to enforce per-plan feature flags and usage limits, so that paid features are not accessible on lower plans.

#### Acceptance Criteria

1. THE Subscription_Service SHALL load entitlements for the active plan from `plan_entitlements` and SHALL treat `limit_value = NULL` as unlimited and `limit_value = -1` as unlimited.
2. WHEN any operation is gated by Entitlement_Guard for a `feature`, THE Subscription_Service SHALL return `allowed = false` if the tenant has no `tenant_subscriptions` row with `status` in `('trial', 'active')`, the active subscription is a trial whose `trial_ends_at < now()`, the corresponding `plan_entitlements.enabled = false`, or the current period usage already meets or exceeds `plan_entitlements.limit_value`.
3. THE Subscription_Service SHALL count current-period usage from `current_period_start` of the active subscription, using `app_usage_events` for `scan_products`, `reports` for `generate_reports` and `advanced_reports`, and `ai_provider_usage_logs` for `ai_report_summary`.
4. WHEN Entitlement_Guard returns `allowed = false`, THE Backend_API SHALL respond with HTTP 402 (or HTTP 403 where 402 is not appropriate per design) and an `EntitlementCheckResult` containing `reason`, `currentUsage`, and `limit` where applicable, and SHALL NOT execute the gated operation.
5. WHERE the plan is `basic`, THE Subscription_Service SHALL block features `advanced_reports`, `inventory_management`, `grn_inward`, `multi_store`, and `ai_report_summary`.
6. WHERE the plan is `standard`, THE Subscription_Service SHALL allow `advanced_reports`, `inventory_management`, and `grn_inward` while keeping `unlimited_users` and unlimited stores disabled.
7. WHERE the plan is `premium`, THE Subscription_Service SHALL treat `maxUsers`, `maxStores`, `maxScansPerMonth`, and `maxReportsPerMonth` as unlimited and SHALL cap `maxAiCallsPerMonth` at 500.

### Requirement 23: Asynchronous Report Generation and Export

**User Story:** As a manager, I want to generate Excel or PDF reports without blocking my UI, so that I can keep working while reports are being prepared.

#### Acceptance Criteria

1. WHEN a user with `generate_reports` permission submits a `GenerateReportDto`, THE Reports_Service SHALL insert a `reports` row with `status = 'pending'`, enqueue a Worker job, and immediately return the `Report` object to the caller.
2. WHILE the Worker generates a report, THE Reports_Service SHALL update `reports.status` from `pending` to `generating`, then on success to `ready` with `file_url` populated and `expires_at` set, and on error to `failed` with an error message.
3. WHEN a user requests a download URL for a report whose `status = 'ready'` and whose `expires_at >= now()`, THE Reports_Service SHALL return a presigned S3 URL with a TTL of at most 15 minutes.
4. IF a user requests a download for a report whose `expires_at < now()`, THEN THE Reports_Service SHALL set `status = 'expired'`, clear `file_url`, and return HTTP 410.
5. THE Reports_Service SHALL support exporting to formats `xlsx` and `pdf` and SHALL reject any other format with HTTP 400.
6. WHEN a report includes `includeAiSummary = true`, THE Reports_Service SHALL invoke AI_Service to generate a summary, persist it to `reports.ai_summary`, and count one `ai_report_summary` usage event.

### Requirement 24: Report History and Scheduling

**User Story:** As a manager, I want to see and re-download past reports and schedule recurring reports, so that I have a record of operations.

#### Acceptance Criteria

1. WHEN a manager requests report history for a `store_id`, THE Reports_Service SHALL return reports for that store using Cursor_Pagination ordered by `generated_at` descending, with at most 100 items per page.
2. WHEN a manager schedules a report, THE Reports_Service SHALL persist a `scheduled_reports` configuration and the Scheduler SHALL enqueue a generation job at the configured cadence.

### Requirement 25: Owner Dashboard Summary and Analytics

**User Story:** As the RADHA business owner, I want a single dashboard showing visitors, leads, registrations, MRR, and feature usage, so that I can run the business.

#### Acceptance Criteria

1. WHEN an Owner_User requests `GET /owner/dashboard/summary` with a `dateRange`, THE Owner_Analytics_Service SHALL return `OwnerDashboardSummary` with `websiteVisitors`, `totalLeads`, `appRegistrations`, `activeUsers`, `trialUsers`, `paidUsers`, `monthlyRecurringRevenue`, `planBreakdown`, `topFeatureUsage`, and `recentActivity` for that range.
2. THE Owner_Analytics_Service SHALL compute `monthlyRecurringRevenue` as the sum of monthly prices over `tenant_subscriptions` rows whose `status = 'active'` and whose plan price is greater than 0.
3. THE Owner_Analytics_Service SHALL only allow access to `/owner/*` endpoints for users whose role is `super_admin`.

### Requirement 26: Website Event Tracking

**User Story:** As the business owner, I want to know which marketing pages drive conversions, so that I can invest marketing budget wisely.

#### Acceptance Criteria

1. WHEN the Marketing_Site emits a `WebsiteEventDto` for `event_type` of `page_view`, `pricing_view`, `contact_click`, `whatsapp_click`, or `app_download_click`, THE Owner_Analytics_Service SHALL insert a `website_events` row capturing `page_url`, `referrer`, `utm_source`, `utm_medium`, `utm_campaign`, `ip_address`, `user_agent`, `session_id`, and `created_at`.
2. WHEN an Owner_User requests `GET /owner/website-analytics`, THE Owner_Analytics_Service SHALL return aggregated `WebsiteAnalytics` for the date range including `pageViews`, `uniqueVisitors`, `pricingPageViews`, `contactClicks`, `whatsappClicks`, `appDownloadClicks`, `topSources`, and `conversionRate`.

### Requirement 27: Lead Capture and Management

**User Story:** As the business owner, I want every contact-form submission and inbound enquiry to become a lead I can follow up, so that I never lose prospects.

#### Acceptance Criteria

1. WHEN the Marketing_Site submits a contact form with `name` and at least one of `mobile` or `email`, THE Owner_Analytics_Service SHALL insert a `marketing_leads` row with `status = 'new'`, `source` reflecting the channel, and any provided `company` and `message`.
2. WHEN an Owner_User updates a lead's `status` to `contacted`, `qualified`, `converted`, or `lost`, THE Owner_Analytics_Service SHALL persist the change and timestamp in `updated_at`.
3. WHEN a lead is converted to a tenant, THE Owner_Analytics_Service SHALL set `marketing_leads.converted_tenant_id` to the new tenant's `id` and `status = 'converted'`.

### Requirement 28: App Usage Event Tracking

**User Story:** As the business owner, I want to see which features tenants use most, so that I can prioritize the roadmap.

#### Acceptance Criteria

1. WHEN any of `scan`, `expiry_entry`, `report_generated`, `grn_posted`, `task_completed`, or `ai_call` occurs in the Mobile_App or Backend_API, THE Owner_Analytics_Service SHALL insert an `app_usage_events` row with `tenant_id`, `user_id`, `event_type`, `feature`, and `metadata`.
2. WHEN the Scheduler runs the daily-metrics rollup, THE Owner_Analytics_Service SHALL upsert one `owner_daily_metrics` row per `metric_date` containing aggregated visitor, lead, registration, active-user, scan, report, AI-call, and revenue counts.

### Requirement 29: AI/OCR Provider Abstraction and Free-First Strategy

**User Story:** As the business owner, I want to use free or on-device AI by default and only fall back to paid providers when necessary, so that AI cost stays under control.

#### Acceptance Criteria

1. THE AI_Service SHALL expose a single `AiProvider` interface with operations `extractText`, `structureData`, `generateSummary`, and `estimateCost`, and SHALL provide implementations for at least `RuleEngineProvider`, `GeminiProvider`, and a stubbed `GemmaLocalProvider`.
2. WHEN the Mobile_App needs OCR for an expiry label or nutrition label, THE Mobile_App SHALL first attempt on-device OCR via Google ML Kit and SHALL only call the Backend_API for server-side AI when ML Kit confidence is below the configured threshold.
3. WHEN the AI_Service performs any provider call, THE AI_Service SHALL persist an `ai_provider_usage_logs` row capturing `provider`, `model`, `feature`, `tenant_id`, `user_id`, `tokens_in`, `tokens_out`, and `estimated_cost_usd`.
4. IF a paid AI provider returns an error or rate limit, THEN THE AI_Service SHALL log the failure, return a graceful empty/fallback result, and SHALL NOT block the calling business operation.

### Requirement 30: Expiry and Nutrition Extraction

**User Story:** As staff, I want the app to suggest MFG/EXP dates and nutrition values from a photo, so that I do not type them manually.

#### Acceptance Criteria

1. WHEN the AI_Service is asked to extract expiry dates from an image URL, THE AI_Service SHALL produce an `ExpiryExtractionResult` with optional `manufacturingDate`, optional `expiryDate`, optional `batchNumber`, a `confidence` value in `[0, 1]`, the `rawText`, and `requiresConfirmation = true` whenever `confidence < 0.85`.
2. WHEN the AI_Service is asked to extract a nutrition label from an image URL, THE AI_Service SHALL produce a `NutritionExtractionResult` with partial `ProductNutrition`, optional `ingredients`, optional `allergens`, a `confidence` value, and `requiresReview = true` when `confidence < 0.85`.
3. THE Expiry_Service SHALL only treat an OCR-suggested expiry as authoritative when the user has confirmed it (`confirmed_by_user = true`).

### Requirement 31: Media Upload via Presigned S3 URLs

**User Story:** As the system, I want clients to upload large media directly to S3, so that the Backend_API does not proxy file bytes.

#### Acceptance Criteria

1. WHEN a client requests a presigned upload URL with `assetType` and a permitted `mimeType`, THE Backend_API SHALL insert a `media_assets` row with `status = 'pending'`, return an S3 PUT URL with a TTL of 5 minutes, and return a stable `mediaId`.
2. THE Backend_API SHALL only allow `mimeType` values `image/jpeg`, `image/png`, `application/vnd.ms-excel`, `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`, or `text/csv`, and SHALL reject all others with HTTP 400.
3. WHEN a media asset is uploaded, THE Worker SHALL scan it (Rekognition for images or signature checks for files), update `media_assets.status` to `approved` or `rejected`, and persist `moderation_result`.
4. IF an upload exceeds 10 MB, THEN THE Backend_API SHALL reject it with HTTP 400.

### Requirement 32: Audit Logging for Business State Changes

**User Story:** As a tenant admin or auditor, I want a complete audit log of writes, so that I can investigate any change.

#### Acceptance Criteria

1. WHEN any service writes to `products`, `ean_lists`, `scan_sessions`, `expiry_records`, `tasks`, `inventory_items`, `low_stock_rules`, `grn_headers`, `tenant_subscriptions`, `plan_entitlements`, or `reports`, THE Audit_Logger SHALL insert one `audit_logs` row with `actor_id`, `actor_type`, `action`, `resource_type`, `resource_id`, `old_value`, `new_value`, `ip_address`, `user_agent`, `request_id`, and `created_at`.
2. THE Audit_Logger SHALL persist audit logs in the same transaction as the business write so that both succeed or both fail.

### Requirement 33: Cursor Pagination for All List Endpoints

**User Story:** As the system, I want every list to use cursor pagination, so that performance does not degrade as data grows.

#### Acceptance Criteria

1. WHEN any list endpoint returns more than one row, THE Backend_API SHALL accept a `cursor` and a `limit`, return at most `limit` items (capped at 100), and return a `nextCursor` when more rows are available.
2. THE Backend_API SHALL encode cursors as base64-encoded `(created_at, id)` pairs and SHALL reject malformed cursors with HTTP 400.
3. THE Backend_API SHALL NOT use SQL `OFFSET` for any list endpoint.

### Requirement 34: Per-Endpoint Rate Limiting

**User Story:** As the system, I want abuse-prone endpoints to be rate-limited, so that one user cannot degrade the service for others.

#### Acceptance Criteria

1. THE Backend_API SHALL rate-limit `POST /api/v1/auth/otp/request` to 3 requests per mobile per hour and 10 per IP per hour.
2. THE Backend_API SHALL rate-limit `GET /api/v1/products/lookup/:ean` to 120 requests per user per minute.
3. THE Backend_API SHALL rate-limit `POST /api/v1/scan-sessions/:id/items` to 300 requests per user per minute.
4. THE Backend_API SHALL rate-limit `POST /api/v1/reports/generate` to 20 requests per user per day.
5. WHEN a rate limit is exceeded, THE Backend_API SHALL return HTTP 429 with a `Retry-After` header.

### Requirement 35: Database Optimization for 10,000 Users

**User Story:** As the system, I want to maintain low query latency at 10,000 users, so that the product feels fast under realistic load.

#### Acceptance Criteria

1. THE Backend_API SHALL maintain composite or partial indexes for the hot queries listed in the design document, including `idx_users_tenant_role`, `idx_scan_sessions_store_created`, `idx_expiry_store_status_date`, `idx_tasks_store_status_due`, and `idx_inventory_low_stock`.
2. THE Backend_API SHALL achieve API response times of p95 below 500 ms and p99 below 1000 ms for the endpoints documented in the performance targets.
3. THE Backend_API SHALL never produce N+1 queries when expanding scan items into products; it SHALL batch product lookups by id.

### Requirement 36: Caching with Redis

**User Story:** As the system, I want frequently accessed data to be cached, so that database load stays manageable.

#### Acceptance Criteria

1. WHERE Redis is available, THE Backend_API SHALL cache active subscription status with a TTL of 5 minutes keyed by `tenant_id`.
2. WHERE Redis is available, THE Backend_API SHALL cache product lookups by `ean` with a TTL of 1 hour.
3. WHEN a tenant's subscription or a cached product changes, THE Backend_API SHALL invalidate the corresponding cache key in the same transaction context as the write.

### Requirement 37: PII Redaction in Logs

**User Story:** As a user, I want my mobile, email, and tokens to never appear in logs in plain text, so that my data stays safe.

#### Acceptance Criteria

1. WHEN any service logs a payload containing `mobile`, `email`, `password`, `otp`, or `token` fields, THE Backend_API logger SHALL replace those values with the literal string `[REDACTED]` before emitting the log line.

### Requirement 38: Mobile App Offline-First Scan Capture

**User Story:** As staff, I want to keep scanning when the network is poor and have entries sync later, so that I do not lose work.

#### Acceptance Criteria

1. WHILE the device is offline, THE Mobile_App SHALL persist scan items, expiry entries, and task evidence to local storage with `syncStatus = 'pending'`.
2. WHEN connectivity is restored, THE Mobile_App SHALL post pending entries to the Backend_API in the order they were captured and SHALL mark each as `synced` only on a successful 2xx response.
3. IF a pending entry fails repeatedly, THEN THE Mobile_App SHALL retry with exponential backoff and SHALL surface the failure to the user after the configured retry budget is exhausted.

### Requirement 39: Mobile App Token and Storage Security

**User Story:** As staff, I want my session token to be stored securely on the device, so that another app cannot steal it.

#### Acceptance Criteria

1. THE Mobile_App SHALL persist refresh tokens only in `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences on Android).
2. WHEN the user logs out, THE Mobile_App SHALL clear refresh tokens from secure storage and SHALL call the session-revocation endpoint.

### Requirement 40: Marketing Website Pages

**User Story:** As a public visitor, I want to learn about RADHA and sign up for a demo, so that I can decide whether to start a trial.

#### Acceptance Criteria

1. THE Marketing_Site SHALL serve at least the routes `/`, `/features`, `/pricing`, `/contact`, `/privacy`, and `/terms`.
2. THE Marketing_Site SHALL include the configured Play Store and App Store links on the landing page.
3. THE Marketing_Site SHALL emit a `page_view` `WebsiteEventDto` for every page render and a typed event for each `pricing_view`, `contact_click`, `whatsapp_click`, and `app_download_click`.
4. WHEN a visitor submits the contact form with valid `name` and at least one of `mobile` or `email`, THE Marketing_Site SHALL post the lead to the Backend_API and SHALL show a confirmation state.

### Requirement 41: Owner Dashboard Access Restriction

**User Story:** As the RADHA business owner, I want the owner dashboard to be inaccessible to anyone but me, so that internal business metrics stay private.

#### Acceptance Criteria

1. THE Owner_Dashboard SHALL require login with a `super_admin` account before rendering any data.
2. IF a request to `/owner/*` originates from a session without `super_admin` role, THEN THE Backend_API SHALL respond with HTTP 403 and SHALL NOT return any analytics payload.

### Requirement 42: API Security Headers and CORS

**User Story:** As the system, I want safe defaults for HTTP security headers and CORS, so that browser attacks are mitigated.

#### Acceptance Criteria

1. THE Backend_API SHALL emit `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, and the Content-Security-Policy described in the design on every response.
2. THE Backend_API SHALL only allow CORS origins from the configured allow-list (production: `https://radha.app`, `https://owner.radha.app`; development: `http://localhost:3000`).

### Requirement 43: Input Validation and SQL Injection Protection

**User Story:** As the system, I want every request body validated and every query parameterized, so that malformed or hostile input cannot corrupt or extract data.

#### Acceptance Criteria

1. WHEN any request reaches a controller, THE Backend_API SHALL validate the body against a `class-validator` DTO and SHALL reject invalid bodies with HTTP 400 and a structured error list.
2. THE Backend_API SHALL only execute SQL via parameterized queries or query-builder APIs and SHALL NOT concatenate user input into SQL strings.

### Requirement 44: File Upload Validation

**User Story:** As the system, I want uploaded files to be validated by size, MIME type, and signature, so that malicious or oversized files cannot be ingested.

#### Acceptance Criteria

1. WHEN a file is uploaded through the Backend_API, THE Backend_API SHALL reject files larger than 10 MB with HTTP 400.
2. WHEN a file is uploaded through the Backend_API, THE Backend_API SHALL verify the file signature (magic bytes) matches the declared MIME type and SHALL reject mismatches with HTTP 400.

### Requirement 45: Worker and Scheduler Process Boundaries

**User Story:** As the system, I want long-running and scheduled work to run outside the API process, so that user-facing latency stays low.

#### Acceptance Criteria

1. THE Worker SHALL handle report generation, OCR, AI summaries, EAN imports, and notification dispatch via a Bull-backed queue.
2. THE Scheduler SHALL run trial-expiry sweeps, owner daily-metric rollups, overdue-task sweeps, and report-expiration cleanup on configured cron schedules.
3. THE Backend_API SHALL NOT execute report generation, OCR extraction, or full bulk imports synchronously inside an HTTP request.

### Requirement 46: Plan-Based User and Store Limits

**User Story:** As the system, I want plan limits on users and stores enforced, so that pricing is honored.

#### Acceptance Criteria

1. WHEN a `tenant_admin` invites a user that would exceed the plan's `maxUsers` (where `maxUsers >= 0`), THE Subscription_Service SHALL block the invitation via Entitlement_Guard and return an upgrade-required response.
2. WHEN a `tenant_admin` creates a store that would exceed the plan's `maxStores` (where `maxStores >= 0`), THE Subscription_Service SHALL block the creation via Entitlement_Guard and return an upgrade-required response.

### Requirement 47: Internal Service Health and Observability

**User Story:** As an operator, I want health endpoints and logs/metrics for monitoring, so that I can detect outages quickly.

#### Acceptance Criteria

1. THE Backend_API SHALL expose a liveness endpoint that returns 200 when the process is running.
2. THE Backend_API SHALL expose a readiness endpoint that returns 200 only when the database, Redis, and S3 dependencies respond within their configured timeouts and 503 otherwise.
3. THE Backend_API SHALL emit structured logs (Winston JSON) for every request including `request_id`, `user_id`, `tenant_id`, `route`, `status`, and `duration_ms`.

### Requirement 48: Error Response Contract

**User Story:** As a client developer, I want consistent error responses, so that I can build reliable UX around failures.

#### Acceptance Criteria

1. WHEN the Backend_API returns a 4xx or 5xx response, THE Backend_API SHALL return a JSON body with fields `error_code` (string), `message` (string), and optional `details` (object).
2. IF a validation error occurs, THEN THE Backend_API SHALL return HTTP 400 with `error_code = 'validation_error'` and a `details` array describing the offending fields.
3. IF an entitlement check fails, THEN THE Backend_API SHALL return `error_code = 'entitlement_denied'` and include `currentUsage`, `limit`, and `reason` in `details`.

### Requirement 49: Out-of-Scope Boundaries

**User Story:** As a product owner, I want the platform to refuse out-of-scope behaviour, so that we keep RADHA focused on operations and audit.

#### Acceptance Criteria

1. THE RADHA_System SHALL NOT expose endpoints, schemas, or UI for GST billing, sales invoicing, customer ledgers, accounts payable, accounts receivable, or POS checkout.
2. THE Inventory_Service SHALL track only stock counts, batches, and movements with the configured `StockInReason` and `StockOutReason` enums and SHALL NOT compute revenue, margin, or tax.

### Requirement 50: Subscription Status Endpoint

**User Story:** As a tenant admin, I want a single endpoint that tells me my plan, trial state, and limits, so that the Mobile_App can render upgrade prompts accurately.

#### Acceptance Criteria

1. WHEN any authenticated tenant user calls `GET /api/v1/subscriptions/status`, THE Subscription_Service SHALL return a `SubscriptionStatus` containing `plan`, `status`, `trialEndsAt`, `currentPeriodStart`, `currentPeriodEnd`, `entitlements`, and `limits` for the caller's tenant.
2. THE Subscription_Service SHALL include in the response the current-period `currentUsage` for any feature that has a non-unlimited limit.
