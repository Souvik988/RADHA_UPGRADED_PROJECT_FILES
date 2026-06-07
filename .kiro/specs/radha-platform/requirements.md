# Requirements Document

## Introduction

RADHA (Retail Assistant for Data, Health & Audits) is a mobile-first SaaS platform serving two distinct user populations from a single app and single login: (1) Indian retail teams (Owners, Managers, Staff, Auditors) who manage product scanning, expiry tracking, EAN verification, audit trails, task management, lightweight inventory, GRN/inward management, and operational reporting; and (2) individual Indian consumers (Consumers) who scan packaged products to evaluate health attributes, manage personal expiry, track allergens for family members, and receive recall alerts. The platform provides a Flutter mobile app, a Next.js marketing website, a Next.js owner dashboard for RADHA platform analytics, and a NestJS backend with PostgreSQL on AWS infrastructure. Role-based UI rendering, onboarding self-selection, comprehensive scan output modes, multi-channel notifications (FCM-first), and a 6-component Operational Health Score round out the platform.

## Glossary

- **RADHA_System**: The complete platform including mobile app, backend API, database, and web interfaces
- **Mobile_App**: Flutter-based Android/iOS application for retail and consumer use
- **Backend_API**: NestJS modular monolith providing REST APIs
- **Database**: PostgreSQL database on AWS RDS
- **Marketing_Website**: Next.js public website for product marketing
- **Owner_Dashboard**: Next.js private web application for the RADHA platform owner (App Owner Dashboard)
- **Client_Dashboard**: In-app dashboard showing store-level operational metrics for business tenants
- **Scanner**: Barcode/EAN scanning functionality using device camera
- **Product_Catalog**: Database of products with EAN codes and attributes
- **Health_Indicator**: Rule-based scoring system for product health (child suitability, sugar/oil/processed content)
- **Expiry_Tracker**: System for tracking product expiry dates with threshold-based alerts
- **EAN_Validator**: System for verifying scanned EANs against approved lists
- **Approved_EAN_List**: Excel/CSV uploaded list of valid EAN codes for a store
- **Scan_Session**: Continuous bulk scanning session with exportable audit trail
- **Task_Manager**: System for assigning and tracking tasks between managers and staff
- **Report_Generator**: System for creating Excel/PDF exports and dashboard summaries
- **AI_OCR_Module**: Free-first AI system using Google ML Kit, Open Food Facts, and optional LLM
- **Inventory_Module**: Lightweight stock tracking (in/out/counts/low-stock alerts)
- **GRN_Module**: Goods Receipt Note system for supplier inward management
- **Subscription_Manager**: System managing free trials and paid plans
- **User**: Any authenticated person using the system
- **Owner**: Retail business owner with full store access
- **Manager**: Store manager who can assign tasks and view reports
- **Staff**: Store employee who executes tasks and scans products
- **Auditor**: Role focused on audit scan sessions
- **Consumer**: Individual end-user (non-business) who uses the Mobile_App for personal product scanning, expiry tracking, allergen checks, and recall alerts; default role for all new signups
- **Premium_Consumer**: Consumer who has subscribed to the Premium Consumer tier (₹49/month) unlocking advanced features
- **RADHA_Owner**: Business owner of the RADHA platform (not a retail client)
- **Store**: Physical retail location managed by a client
- **Tenant**: Multi-tenant isolation boundary (client organization or, for Consumer accounts, the personal tenant scope)
- **EAN**: European Article Number (barcode standard)
- **OCR**: Optical Character Recognition for reading expiry dates and product packaging
- **Image_OCR_Fallback**: Cloud-vision-based product identification triggered when an EAN is not decoded within 2 seconds
- **GRN**: Goods Receipt Note for supplier inward tracking
- **MFG_Date**: Manufacturing date of a product
- **EXP_Date**: Expiry date of a product
- **Batch_Number**: Supplier batch identifier for product traceability
- **S3_Bucket**: AWS Simple Storage Service for file storage
- **CloudFront**: AWS CDN for content delivery
- **MSG91**: SMS service provider for OTP delivery
- **Presigned_URL**: Time-limited AWS S3 upload URL
- **Free_Trial**: Legacy 3-month free subscription period (replaced by Trial_Pro for new signups; preserved for existing tenants)
- **Trial_Pro**: 14-day full Pro-feature trial for business signups, capped at 1 store and 5 users, requires Trial_Verification_Charge before activation
- **Free_Consumer_Tier**: Default ₹0 Consumer tier with 50 scans/day and 5 saved products
- **Premium_Consumer_Tier**: ₹49/month Consumer tier with unlimited scans, unlimited saves, comprehensive scan output, allergen profile, family sharing, expiry calendar, recall alerts, multi-language, and affiliate alternatives
- **Starter_Plan**: ₹49/month business subscription tier (1 store, 5 users, 5,000 scans/month)
- **Growth_Plan**: ₹99/month business subscription tier
- **Pro_Plan**: ₹199/month business subscription tier
- **Trial_Verification_Charge**: ₹2 silent verification charge processed via Razorpay/Cashfree to validate the user's payment method and establish an RBI_eMandate before Trial_Pro activates
- **RBI_eMandate**: Reserve Bank of India compliant recurring payment authorization (UPI Autopay or e-NACH) used for auto-renewal
- **Onboarding_Segment**: One of six self-selection segments chosen by the User on first launch (personal, business_owner, parent, pharmacy, institution, auditor_invited)
- **Onboarding_Screen**: Single screen with a 2x3 grid of six tap-cards used for Onboarding_Segment self-selection
- **Business_Activation**: Process of upgrading a Consumer account to a business tenant with Owner role and a Store
- **Allergen_Profile**: Per-family-member set of allergy and condition tags used to flag matching ingredients during a scan
- **Family_Sharing**: Premium_Consumer feature allowing one subscription to cover up to five linked family member profiles
- **Recall_Alert**: Notification triggered when a saved product matches an entry in a fetched FSSAI/government recall feed
- **Recall_Sweep_Job**: Daily background cron job that fetches recall feeds and matches them against saved products
- **Operational_Health_Score**: Composite score (0–100) for a business tenant calculated from six weighted components and recalculated daily
- **Health_Score_Algorithm_Version**: Semantic version string (e.g., "v1.2") stored with each Operational_Health_Score record so future algorithm changes do not invalidate historical scores
- **Scan_Output_Mode**: Either "basic" or "comprehensive"; controls the depth of information returned by a product scan
- **Comprehensive_Scan_Output**: Full ingredients list, allergens, health PROS, health CONS with risks, age-group child safety bands, consumption guidance, and healthier alternatives
- **Basic_Scan_Output**: Product name, brand, basic Health_Indicator, and expiry status
- **FCM**: Firebase Cloud Messaging, the primary push notification channel
- **In_App_Notification_Center**: In-app inbox listing all notifications delivered to the User
- **AWS_SES**: AWS Simple Email Service used for transactional and digest emails
- **Notification_Preferences**: Per-User per-category opt-in/opt-out settings governing FCM, email, in-app, and SMS notifications
- **Affiliate_Link**: Outbound product link to Amazon, Flipkart, or other partner with embedded affiliate identifier and click tracking
- **Affiliate_Engine**: System that selects healthier alternatives, attaches Affiliate_Links, and records click-through and revenue events
- **Healthy_Alternatives_Engine**: Recommendation logic that selects healthier alternatives for a given scanned product
- **Public_Product_Profile_Page**: SEO-indexed public web page at radha.app/p/{slug} generated by static rendering for every scanned product
- **RADHA_Verified_Badge**: Visual badge issued to Pro_Plan tenants meeting Operational_Health_Score thresholds, usable on WhatsApp Business and Instagram
- **Local_Database**: On-device SQLite store (Drift or Isar) used by the Mobile_App for offline-first operation
- **Sync_Engine**: Mobile_App component that pushes queued local writes to the Backend_API and pulls server changes
- **Idempotency_Key**: Client-generated UUID attached to mutating requests so the Backend_API can deduplicate retries
- **Conflict_Resolution_Policy**: Rules that determine which version wins when local and server records diverge (default: last-write-wins; critical fields use server-wins)
- **Search_Service**: Backend service exposing fuzzy product search by name and brand
- **Rate_Limit_Service**: Backend service that tracks per-user quotas in Redis with daily reset
- **PostgreSQL_RLS**: PostgreSQL Row-Level Security policies that enforce tenant isolation at the database layer
- **Tenant_Scope_Middleware**: Backend middleware that injects tenant_id into every query
- **Referral_Program**: System awarding one free month of Premium_Consumer to both inviter and invitee on a successful signup
- **Referral_Code**: Unique alphanumeric code identifying the inviter
- **Cache_Layer**: Redis-based caching layer with per-resource TTLs
- **PostHog**: Product analytics platform (self-hostable open-source) used for event tracking from Day 1
- **Analytics_Event**: Single tracked event with name, properties, user identifier, and timestamp
- **AI_Ingredient_Explainer**: Feature that returns plain-language explanations of ingredients, generated by an LLM and cached forever in the Database
- **Barcode_Learning_Service**: Crowdsourced enrichment service allowing Users to submit photos and details for products not in Open Food Facts
- **Daily_Insights_Job**: Scheduled job generating personalized weekly scan summaries delivered via FCM
- **Shopping_List_Module**: Feature allowing voice or text intake of shopping items with optional WhatsApp send to a kirana
- **Feature_Flag_Service**: Open-source feature flag service (Unleash or GrowthBook) supporting per-user toggles, A/B testing, and gradual rollout
- **Unleash**: Selected open-source feature flag platform (interchangeable with GrowthBook in implementation)
- **Sentry**: Crash and error reporting platform (free tier 5,000 errors/month)
- **OpenTelemetry**: Tracing and logging instrumentation standard
- **Grafana_Cloud**: Observability backend used for traces and logs (free tier)
- **Backup_Service**: PostgreSQL WAL archiving, automated daily snapshots, and monthly restore tests
- **PITR**: Point-In-Time Recovery for the Database
- **Admin_Impersonation_Tool**: Time-limited audited "view as user" support capability available only to RADHA_Owner support staff
- **Webhook_Service**: Pro_Plan-tier outbound webhook delivery for events such as product.created and inventory.updated
- **Public_Product_Service**: Service that generates and serves Public_Product_Profile_Pages
- **Lottie_Animation**: Vector animation rendered by the Lottie runtime, used on the Onboarding_Screen
- **Configuration_Parser**: Parser for JSON configuration files
- **Configuration_Pretty_Printer**: Serializer that formats Configuration objects back into valid JSON

## Requirements

### Requirement 1: User Authentication, Authorization, and Roles

**User Story:** As any platform user, I want to securely log in using my mobile number and have the app render features appropriate to my role, so that I see only what is relevant to me and my data is protected.

#### Acceptance Criteria

1. WHEN a User enters a valid mobile number, THE Backend_API SHALL send an OTP via MSG91 within 5 seconds
2. WHEN a User enters a correct OTP within 10 minutes of generation, THE Backend_API SHALL create an authenticated session with a JWT token
3. WHEN a User enters an incorrect OTP, THE Backend_API SHALL reject authentication and allow up to 3 retry attempts
4. WHEN an authenticated User attempts an operation, THE Backend_API SHALL verify the User's role permissions before allowing the operation
5. THE Backend_API SHALL support five user roles: Owner, Manager, Staff, Auditor, and Consumer
6. WHEN a new User completes OTP verification for the first time and has no pending invitation, THE Backend_API SHALL assign the Consumer role by default and route the Mobile_App to the Onboarding_Screen
7. WHEN a session token is unused for 30 days, THE Backend_API SHALL invalidate the token and require re-authentication
8. WHERE Owner_Dashboard access is required, THE Backend_API SHALL authenticate using email and password credentials separate from mobile-OTP authentication
9. THE Mobile_App SHALL render UI elements based on the authenticated User's role so that Consumers see consumer features, Staff see staff-scoped operational features, Managers see managerial features, Owners see full business features, and Auditors see audit-only features

### Requirement 2: Barcode and EAN Scanning

**User Story:** As a retail staff member, I want to scan product barcodes quickly and accurately, so that I can identify products and perform operations efficiently.

#### Acceptance Criteria

1. WHEN a User opens the Scanner in the Mobile_App, THE Scanner SHALL activate the device camera and display a scanning viewfinder
2. WHEN a barcode enters the viewfinder, THE Scanner SHALL decode the EAN code within 2 seconds using Google ML Kit
3. WHEN a valid EAN is decoded, THE Mobile_App SHALL send the EAN to the Backend_API for product lookup
4. THE Scanner SHALL support EAN-8, EAN-13, UPC-A, and UPC-E barcode formats
5. WHEN scanning fails due to poor lighting or a damaged barcode, THE Mobile_App SHALL allow manual EAN entry via keyboard
6. WHEN a User scans continuously in a Scan_Session, THE Scanner SHALL maintain camera focus and decode multiple barcodes sequentially without closing

### Requirement 3: Product Catalog and Lookup

**User Story:** As a retail user, I want to retrieve product information by EAN code, so that I can view product details, health indicators, and manage inventory.

#### Acceptance Criteria

1. WHEN the Backend_API receives an EAN lookup request, THE Backend_API SHALL query the Product_Catalog within 500 milliseconds
2. WHEN an EAN exists in the Product_Catalog, THE Backend_API SHALL return product name, brand, category, image URL, and health indicators
3. WHEN an EAN does not exist in the Product_Catalog, THE Backend_API SHALL query Open Food Facts API as a fallback within 3 seconds
4. WHEN Open Food Facts returns product data, THE Backend_API SHALL store the product in the Product_Catalog for future lookups
5. WHERE a product is not found in any source, THE Mobile_App SHALL allow manual product creation with name, brand, category, and image upload
6. THE Backend_API SHALL support product image storage in S3_Bucket with CloudFront CDN URLs
7. WHEN a Manager creates or updates a product, THE Backend_API SHALL validate that the product name is 1–200 characters and category is from a predefined list

### Requirement 4: Product Health Indicators and Scan Output Modes

**User Story:** As a User, I want scan results in either a quick basic mode or a detailed comprehensive mode, so that I can choose the depth of information based on my role and needs.

#### Acceptance Criteria

1. THE Backend_API SHALL expose `GET /api/v1/products/{ean}/scan?mode=basic|comprehensive` and SHALL default `mode` to `basic` when the parameter is omitted
2. WHEN `mode=basic` is requested, THE Backend_API SHALL return Basic_Scan_Output containing product name, brand, Health_Indicator status (green/yellow/red), and expiry status
3. WHEN `mode=comprehensive` is requested, THE Backend_API SHALL return Comprehensive_Scan_Output containing the full ingredients list, allergens, health PROS list, health CONS list with specific risks, age-group child safety bands (infant 0–2, toddler 2–5, child 5–12, adolescent 12–18), consumption guidance, and healthier alternatives with Affiliate_Links
4. WHERE the authenticated User holds a business role (Owner, Manager, Staff, Auditor) or is on the Free_Consumer_Tier, THE Mobile_App SHALL default Scan_Output_Mode to `basic`
5. WHERE the authenticated User holds the Premium_Consumer entitlement, THE Mobile_App SHALL default Scan_Output_Mode to `comprehensive`
6. THE Mobile_App SHALL allow any User to toggle Scan_Output_Mode and SHALL persist the chosen mode per User in the Database
7. THE Health_Indicator SHALL classify child suitability using sugar content greater than 10g per 100g, oil content greater than 15g per 100g, and ultra-processed food classification
8. WHERE nutritional data is unavailable for a product, THE Health_Indicator SHALL display "Data Unavailable" status instead of a numeric or color score
9. THE Health_Indicator SHALL use rule-based scoring without external API calls during the scan response path

### Requirement 5: Expiry Date Tracking and Alerts

**User Story:** As a store manager, I want to track product expiry dates and receive alerts for near-expiry items, so that I can reduce waste and ensure product freshness.

#### Acceptance Criteria

1. WHEN a User adds an expiry date to a product, THE Expiry_Tracker SHALL store MFG_Date and EXP_Date with Batch_Number in the Database
2. THE Expiry_Tracker SHALL calculate days until expiry for each product batch
3. WHEN days until expiry is less than the category-specific threshold, THE Expiry_Tracker SHALL mark the product as yellow (warning) status
4. WHEN days until expiry is less than 7 days or the product is expired, THE Expiry_Tracker SHALL mark the product as red (critical) status
5. WHEN days until expiry is greater than the warning threshold, THE Expiry_Tracker SHALL mark the product as green (safe) status
6. THE Mobile_App SHALL provide OCR assistance using Google ML Kit to extract expiry dates from product packaging images
7. WHEN OCR extracts a date, THE Mobile_App SHALL pre-fill the expiry date field and allow User confirmation or correction
8. THE Client_Dashboard SHALL display the count of products in green, yellow, and red expiry status for the store

### Requirement 6: Approved EAN List Verification

**User Story:** As a store owner, I want to upload an approved EAN list and verify scanned products against it, so that I can ensure only authorized products are stocked.

#### Acceptance Criteria

1. WHERE an Owner uploads an Excel or CSV file, THE Backend_API SHALL parse the file and extract EAN codes within 10 seconds for files up to 10,000 rows
2. WHEN the Backend_API parses the uploaded file, THE Backend_API SHALL validate that each EAN is 8 or 13 digits
3. WHEN validation succeeds, THE Backend_API SHALL store the Approved_EAN_List associated with the Store in the Database
4. WHEN a User scans an EAN during audit, THE EAN_Validator SHALL check whether the EAN exists in the Store's Approved_EAN_List within 200 milliseconds
5. WHEN an EAN is in the Approved_EAN_List, THE Mobile_App SHALL display a green checkmark indicator
6. WHEN an EAN is not in the Approved_EAN_List, THE Mobile_App SHALL display a red cross indicator and log the mismatch
7. THE Backend_API SHALL support replacing the entire Approved_EAN_List with a new upload while preserving historical scan validation results

### Requirement 7: Bulk Audit Scan Sessions

**User Story:** As an auditor, I want to perform continuous bulk scanning sessions and export audit trails, so that I can efficiently audit large inventories and maintain compliance records.

#### Acceptance Criteria

1. WHEN a User starts a Scan_Session, THE Mobile_App SHALL create a new session record with timestamp and User identifier
2. WHILE a Scan_Session is active, THE Mobile_App SHALL allow continuous scanning without closing the Scanner after each scan
3. WHEN a barcode is scanned during a Scan_Session, THE Mobile_App SHALL record EAN, timestamp, product name, EAN validation status, and expiry status
4. THE Mobile_App SHALL display a running count of scanned items, approved EANs, mismatched EANs, and expiry alerts during the session
5. WHEN a User ends a Scan_Session, THE Mobile_App SHALL save the complete session data to the Backend_API
6. WHEN a User requests an audit trail export, THE Report_Generator SHALL create an Excel file containing all scans with timestamps, EAN codes, validation results, and expiry status within 30 seconds
7. THE Backend_API SHALL store Scan_Session data for 12 months for compliance and historical analysis

### Requirement 8: Task Assignment and Management

**User Story:** As a store manager, I want to assign tasks to staff members and track completion, so that I can ensure operational activities are completed on time.

#### Acceptance Criteria

1. WHEN a Manager creates a task, THE Task_Manager SHALL require a task title (1–100 characters), description (0–500 characters), assigned Staff member, and due date
2. WHEN a task is created, THE Backend_API SHALL send a push notification to the assigned Staff member within 10 seconds
3. WHEN a Staff member views assigned tasks, THE Mobile_App SHALL display tasks sorted by due date with status indicators (pending/in-progress/completed)
4. WHEN a Staff member marks a task as completed, THE Task_Manager SHALL record the completion timestamp and notify the assigning Manager
5. WHEN a task is overdue, THE Mobile_App SHALL display a red overdue indicator on the Client_Dashboard
6. THE Task_Manager SHALL support task filtering by status, assigned user, and date range
7. WHERE a Manager deletes a task, THE Backend_API SHALL soft-delete the task record while preserving audit history

### Requirement 9: Report Generation and Export

**User Story:** As a store owner, I want to generate and export reports in Excel and PDF formats, so that I can analyze operations and share data with stakeholders.

#### Acceptance Criteria

1. WHEN a User requests a report, THE Report_Generator SHALL support report types: expiry summary, EAN mismatch log, scan session history, inventory summary, and GRN history
2. WHEN a report is requested for a date range exceeding 10,000 records, THE Report_Generator SHALL process the report asynchronously and notify the User when complete
3. WHEN an Excel report is generated, THE Report_Generator SHALL create an XLSX file with formatted headers, data rows, and summary statistics
4. WHEN a PDF report is generated, THE Report_Generator SHALL create a formatted PDF with company logo, report title, date range, and tabular data
5. THE Report_Generator SHALL store generated report files in S3_Bucket with 90-day retention
6. WHEN a report is ready, THE Backend_API SHALL provide a Presigned_URL valid for 24 hours for secure download
7. THE Client_Dashboard SHALL display summary statistics without requiring full report generation for quick operational insights

### Requirement 10: AI and OCR Assistance

**User Story:** As a retail user, I want AI assistance for product data enrichment and expiry date extraction, so that I can reduce manual data entry and improve accuracy.

#### Acceptance Criteria

1. THE AI_OCR_Module SHALL use Google ML Kit for on-device barcode scanning and text recognition without external API calls
2. WHEN a User captures a product packaging image, THE AI_OCR_Module SHALL extract visible text using Google ML Kit within 3 seconds
3. WHEN extracted text contains date patterns (DD/MM/YYYY, MM/YYYY), THE AI_OCR_Module SHALL identify potential MFG_Date and EXP_Date fields
4. WHERE a product is not found in the local Product_Catalog, THE Backend_API SHALL query Open Food Facts API for product name, brand, category, and nutritional data
5. WHERE Open Food Facts returns no data, THE AI_OCR_Module SHALL optionally use AWS Rekognition for label detection as a paid escalation
6. THE Backend_API SHALL track AI_OCR_Module usage counts per tenant for cost monitoring and subscription enforcement
7. WHERE LLM summarization is enabled for a tenant, THE AI_OCR_Module SHALL generate product health summaries using an abstracted LLM wrapper with a 10-second timeout

### Requirement 11: Lightweight Inventory Management

**User Story:** As a store manager, I want to track stock levels with basic in/out movements and low-stock alerts, so that I can maintain adequate inventory without complex ERP functionality.

#### Acceptance Criteria

1. WHEN a product is received via GRN or manual entry, THE Inventory_Module SHALL increase stock quantity for the product-store-batch combination
2. WHEN a product is removed (expired/damaged/sold/adjustment), THE Inventory_Module SHALL decrease stock quantity and record the reason
3. THE Inventory_Module SHALL maintain current stock quantity per product per store with batch and expiry visibility
4. WHEN stock quantity falls below a configurable low-stock threshold, THE Inventory_Module SHALL create a low-stock alert visible on the Client_Dashboard
5. WHEN a Manager performs a stock count, THE Inventory_Module SHALL allow entering counted quantity and calculate variance from system quantity
6. THE Inventory_Module SHALL record all stock movements with timestamp, user, reason, and quantity change for audit trail
7. THE Client_Dashboard SHALL display category-wise stock summaries and low-stock alert counts

### Requirement 12: GRN and Inward Management

**User Story:** As a store manager, I want to record supplier inward receipts with invoice details and expiry dates, so that I can track incoming stock and update inventory accurately.

#### Acceptance Criteria

1. WHEN a Manager creates a GRN, THE GRN_Module SHALL require supplier name, invoice number, inward date, and at least one product line item
2. WHEN a product line item is added to a GRN, THE GRN_Module SHALL require product EAN, quantity, and optionally Batch_Number and EXP_Date
3. WHEN a GRN is in draft status, THE GRN_Module SHALL allow editing and adding/removing line items
4. WHEN a Manager posts a GRN, THE GRN_Module SHALL validate all required fields and change status to posted
5. WHEN a GRN is posted, THE Inventory_Module SHALL increase stock quantities for all line items and record the GRN reference
6. THE GRN_Module SHALL store supplier information for future GRN creation with autocomplete suggestions
7. THE Mobile_App SHALL allow scanning products during GRN entry to populate line items quickly

### Requirement 13: Subscription Tiers and Trial Flow

**User Story:** As a User, I want clear subscription tiers covering both consumer and business needs and a transparent trial flow with RBI-compliant auto-renewal, so that I can choose the right plan and trust the billing process.

#### Acceptance Criteria

1. THE Subscription_Manager SHALL support four primary tiers: Free_Consumer_Tier (₹0), Premium_Consumer_Tier (₹49/month), Starter_Plan (₹49/month, 1 store, 5 users, 5,000 scans/month), Growth_Plan (₹99/month), and Pro_Plan (₹199/month)
2. WHEN a new User completes signup with the Consumer Onboarding_Segment "personal" or "parent", THE Subscription_Manager SHALL place the User on Free_Consumer_Tier
3. WHEN a User selects a business Onboarding_Segment ("business_owner", "pharmacy", or "institution"), THE Subscription_Manager SHALL present a Trial_Pro offer that unlocks all Pro_Plan features for 14 days while capping the tenant at 1 store and 5 users
4. THE Subscription_Manager SHALL require the User to add a payment method (UPI, debit card, or credit card) before Trial_Pro activates
5. WHEN a User adds a payment method for Trial_Pro, THE Backend_API SHALL initiate a Trial_Verification_Charge of ₹2 via Razorpay or Cashfree to validate the payment method and SHALL establish an RBI_eMandate (UPI Autopay or e-NACH) for auto-renewal
6. WHILE Trial_Pro is being activated, THE Mobile_App SHALL display "₹0 — Free Trial" to the User while the Trial_Verification_Charge is processed silently in the background
7. WHEN day 14 of Trial_Pro elapses without cancellation, THE Subscription_Manager SHALL trigger auto-pay using the established RBI_eMandate to convert the tenant to Starter_Plan or the explicitly chosen paid plan
8. WHEN a User cancels during Trial_Pro, THE Subscription_Manager SHALL stop further charges, leave the Trial_Verification_Charge of ₹2 as-is, and downgrade the account to Free_Consumer_Tier at the end of the 14 days
9. THE Mobile_App SHALL display RBI-compliant e-mandate consent wording at the time the RBI_eMandate is established
10. WHEN a tenant exceeds plan limits, THE Backend_API SHALL prevent additional operations and display an upgrade prompt in the Mobile_App
11. THE Subscription_Manager SHALL track subscription status (trial/active/expired/cancelled), tier, and renewal date in the Database
12. WHERE a User on a Consumer tier has skipped Trial_Pro, THE Mobile_App SHALL display persistent in-app banners and feature-locked prompts encouraging trial signup at most once per day per surface

### Requirement 14: Client In-App Dashboard

**User Story:** As a store owner or manager, I want to view operational metrics in the mobile app, so that I can monitor store performance and take timely actions.

#### Acceptance Criteria

1. WHEN a User opens the Client_Dashboard in the Mobile_App, THE Client_Dashboard SHALL display metrics for the User's store
2. THE Client_Dashboard SHALL show total scans today, this week, and this month
3. THE Client_Dashboard SHALL show counts of products in green, yellow, and red expiry status
4. THE Client_Dashboard SHALL show the count of EAN mismatches from recent scan sessions
5. THE Client_Dashboard SHALL show counts of pending, in-progress, and overdue tasks
6. THE Client_Dashboard SHALL show counts of low-stock alerts and recent GRN entries
7. THE Backend_API SHALL calculate dashboard metrics within 1 second using indexed database queries

### Requirement 15: App Owner Dashboard and Privacy Boundary

**User Story:** As the RADHA platform owner, I want a private SaaS metrics dashboard that respects tenant privacy, so that I can run the business without ever viewing tenant product data, scans, inventory, or task content.

#### Acceptance Criteria

1. WHERE the RADHA_Owner accesses the Owner_Dashboard, THE Owner_Dashboard SHALL require email-and-password authentication separate from mobile-OTP authentication
2. THE Owner_Dashboard SHALL display tenant names, signup dates, subscription tiers, and monthly recurring revenue
3. THE Owner_Dashboard SHALL display aggregate counts of total scans, total inventory items, total tasks, total reports generated, and total GRNs
4. THE Owner_Dashboard SHALL display feature usage metrics, AI_OCR_Module usage, and OCR cost monitoring
5. THE Owner_Dashboard SHALL display PostHog analytics dashboards for product analytics
6. THE Owner_Dashboard SHALL display Marketing_Website visitor count, pricing page views, and contact/WhatsApp click counts
7. THE Owner_Dashboard SHALL display total app registrations, active users (logged in within 30 days), and stores created
8. THE Owner_Dashboard SHALL display counts of trial users, paid users, expired trials, and cancelled subscriptions
9. THE Owner_Dashboard SHALL display subscription plan distribution across Free_Consumer_Tier, Premium_Consumer_Tier, Starter_Plan, Growth_Plan, and Pro_Plan
10. THE Backend_API SHALL expose dedicated Owner_Dashboard endpoints under a separate scope and SHALL exclude any tenant product data, scan content, inventory line items, task content, EAN lists, or family member personal data from those endpoints
11. IF an Owner_Dashboard endpoint is requested for tenant product, scan, inventory, task, EAN list, or family member content, THEN THE Backend_API SHALL return HTTP 403 Forbidden
12. THE Database SHALL store all tenant data encrypted at rest using PostgreSQL TDE so that tenant data can be recovered for the tenant if a mobile device is lost while remaining unreadable to the RADHA_Owner outside an explicit support flow

### Requirement 16: Marketing Website

**User Story:** As a prospective customer, I want to learn about RADHA features and pricing on a public website, so that I can evaluate the product and sign up for a trial.

#### Acceptance Criteria

1. THE Marketing_Website SHALL display product overview, key features, and benefits on the homepage
2. THE Marketing_Website SHALL provide a pricing page showing Free_Consumer_Tier, Premium_Consumer_Tier, Starter_Plan, Growth_Plan, and Pro_Plan with feature comparisons
3. THE Marketing_Website SHALL provide a contact form and WhatsApp click-to-chat for demo requests and inquiries
4. WHEN a visitor submits a contact form, THE Backend_API SHALL store the lead information and send an email notification to RADHA_Owner via AWS_SES within 5 minutes
5. THE Marketing_Website SHALL provide links to download the Mobile_App from Google Play Store and Apple App Store
6. THE Marketing_Website SHALL include privacy policy and terms of service pages with legal compliance content
7. THE Marketing_Website SHALL track page views and button clicks for analytics visible in the Owner_Dashboard

### Requirement 17: Data Security, Encryption, and Multi-Tenancy

**User Story:** As a User, I want my data isolated from other tenants and encrypted at every layer, so that I can trust the platform with sensitive business and personal information.

#### Acceptance Criteria

1. THE Backend_API SHALL implement row-level tenant isolation using tenant_id foreign keys on all data tables
2. WHEN a User makes an API request, THE Tenant_Scope_Middleware SHALL extract tenant_id from the authenticated session and SHALL inject the tenant_id filter into all database queries
3. THE Database SHALL enforce PostgreSQL_RLS policies on every tenant-scoped table so that direct database access cannot read or modify rows belonging to a different tenant
4. THE Database SHALL enable PostgreSQL TDE (Transparent Data Encryption) at the storage level so that the entire database is encrypted at rest
5. THE Backend_API SHALL encrypt sensitive field-level data (mobile numbers, email addresses, payment identifiers) using AES-256 encryption with keys stored in AWS KMS
6. THE Backend_API SHALL transmit all data over HTTPS using TLS 1.2 or higher
7. THE Backend_API SHALL use parameterized queries for all database operations to prevent SQL injection
8. THE Backend_API SHALL implement rate limiting of 100 requests per minute per authenticated User to prevent abuse

### Requirement 18: File Storage and CDN

**User Story:** As a User, I want to upload product images and download reports quickly, so that I can work efficiently without waiting for slow file transfers.

#### Acceptance Criteria

1. WHEN a User uploads a product image, THE Backend_API SHALL generate a Presigned_URL for direct S3_Bucket upload valid for 10 minutes
2. WHEN a User uploads a file using the Presigned_URL, THE Mobile_App SHALL upload directly to S3_Bucket without passing through the Backend_API
3. THE Backend_API SHALL store S3_Bucket object keys in the Database and serve images via CloudFront CDN URLs
4. WHEN a User requests a report download, THE Backend_API SHALL generate a Presigned_URL valid for 24 hours for secure time-limited access
5. THE S3_Bucket SHALL enforce lifecycle policies to delete report files after 90 days and temporary uploads after 7 days
6. THE CloudFront CDN SHALL cache product images with 30-day TTL for fast global delivery
7. THE Backend_API SHALL validate uploaded file types (JPEG, PNG for images; XLSX, CSV for EAN lists) and reject unsupported formats

### Requirement 19: Scalability and Performance

**User Story:** As the RADHA platform grows to 10,000 users, I want the system to maintain fast response times and reliability, so that all users have a consistent experience.

#### Acceptance Criteria

1. THE Database SHALL use B-tree indexes on tenant_id, store_id, user_id, ean_code, and created_at columns for query optimization
2. WHEN paginated queries are required, THE Backend_API SHALL use cursor-based pagination with a limit of 50 records per page
3. THE Backend_API SHALL process long-running operations (report generation, EAN list import) asynchronously using background workers
4. THE Backend_API SHALL implement database connection pooling with a maximum of 20 connections per instance
5. WHEN an API response time exceeds 2 seconds, THE Backend_API SHALL log a slow query warning for performance monitoring
6. THE Backend_API SHALL implement caching for frequently accessed data (product catalog, approved EAN lists) with 5-minute TTL
7. THE Database SHALL use AWS RDS with automated daily backups and 7-day retention for disaster recovery

### Requirement 20: Mobile App Offline Capability (Limited)

**User Story:** As a User, I want to scan products and view cached data when internet is temporarily unavailable, so that I can continue working during connectivity issues.

#### Acceptance Criteria

1. WHEN the Mobile_App loses internet connectivity, THE Mobile_App SHALL display an offline indicator in the UI
2. WHILE offline, THE Scanner SHALL continue to decode barcodes using on-device Google ML Kit
3. WHILE offline, THE Mobile_App SHALL display cached product data for recently viewed products
4. WHEN a User scans a product while offline, THE Mobile_App SHALL queue the scan record for synchronization when connectivity returns
5. WHEN internet connectivity is restored, THE Mobile_App SHALL automatically synchronize queued scan records to the Backend_API within 30 seconds
6. THE Mobile_App SHALL cache the most recent 100 products and the current day's scan session data for offline access
7. WHERE critical operations require server validation (GRN posting, task completion), THE Mobile_App SHALL prevent the operation while offline and display a connectivity-required message

### Requirement 21: Parser and Serializer for Configuration

**User Story:** As a developer, I want to parse and serialize configuration files reliably, so that the system can load settings correctly and maintain configuration integrity.

#### Acceptance Criteria

1. WHEN a valid JSON configuration file is provided, THE Configuration_Parser SHALL parse it into a Configuration object within 100 milliseconds
2. WHEN an invalid JSON configuration file is provided, THE Configuration_Parser SHALL return a descriptive error message indicating the line and column of the syntax error
3. THE Configuration_Pretty_Printer SHALL format Configuration objects back into valid JSON files with 2-space indentation
4. FOR ALL valid Configuration objects, parsing then printing then parsing SHALL produce an equivalent Configuration object (round-trip property)
5. THE Configuration_Parser SHALL validate required fields (database connection, AWS credentials, MSG91 API key) and return validation errors if missing
6. THE Configuration_Parser SHALL support environment variable substitution using ${ENV_VAR} syntax
7. WHEN a Configuration object is serialized, THE Configuration_Pretty_Printer SHALL mask sensitive values (passwords, API keys) in log output

### Requirement 22: SMS OTP Delivery

**User Story:** As a User, I want to receive OTP codes quickly and reliably via SMS, so that I can log in without delays or delivery failures.

#### Acceptance Criteria

1. WHEN the Backend_API sends an OTP request to MSG91, THE Backend_API SHALL include mobile number, OTP code, and template ID
2. WHEN MSG91 accepts the request, THE Backend_API SHALL receive a delivery confirmation within 5 seconds
3. IF MSG91 returns an error response, THEN THE Backend_API SHALL retry the request up to 2 additional times with 2-second delays
4. WHEN all retry attempts fail, THE Backend_API SHALL log the failure and return an error to the Mobile_App
5. THE Backend_API SHALL generate 6-digit numeric OTP codes using cryptographically secure random number generation
6. THE Backend_API SHALL store OTP codes with 10-minute expiration and invalidate them after successful authentication
7. THE Backend_API SHALL rate-limit OTP requests to 3 per mobile number per hour to prevent abuse

### Requirement 23: Error Handling and Logging

**User Story:** As a developer, I want comprehensive error logging and handling, so that I can diagnose issues quickly and maintain system reliability.

#### Acceptance Criteria

1. WHEN an unhandled exception occurs in the Backend_API, THE Backend_API SHALL log the error with stack trace, request context, and timestamp
2. WHEN an error is logged, THE Backend_API SHALL assign a unique error ID and return it to the client for support reference
3. THE Backend_API SHALL categorize errors as client errors (4xx) or server errors (5xx) and return appropriate HTTP status codes
4. WHEN a database query fails, THE Backend_API SHALL log the query, parameters, and error message without exposing sensitive data
5. THE Backend_API SHALL implement structured logging in JSON format including severity, timestamp, service name, and correlation ID
6. THE Backend_API SHALL send critical error alerts (database connection failure, S3 access failure) to RADHA_Owner via email within 5 minutes
7. THE Mobile_App SHALL display user-friendly error messages and provide an option to retry failed operations

### Requirement 24: API Rate Limiting and Throttling

**User Story:** As the RADHA platform operator, I want to prevent API abuse and ensure fair resource usage, so that all users have reliable access to the system.

#### Acceptance Criteria

1. THE Backend_API SHALL implement rate limiting of 100 requests per minute per authenticated user
2. WHEN a user exceeds the rate limit, THE Backend_API SHALL return HTTP 429 status code with a Retry-After header
3. THE Backend_API SHALL implement separate rate limits for expensive operations: 10 report generations per hour and 5 EAN list uploads per day
4. THE Backend_API SHALL track rate limit counters using in-memory cache with a 1-minute sliding window
5. WHERE a tenant is on Free_Consumer_Tier or Trial_Pro, THE Backend_API SHALL enforce stricter rate limits of 50 requests per minute
6. WHEN rate limit violations occur repeatedly, THE Backend_API SHALL log the user and tenant for abuse monitoring
7. THE Backend_API SHALL exempt health-check and status endpoints from rate limiting

### Requirement 25: Database Migration and Schema Management

**User Story:** As a developer, I want to manage database schema changes safely with version control, so that I can deploy updates without data loss or downtime.

#### Acceptance Criteria

1. THE Backend_API SHALL use a migration tool (TypeORM migrations or similar) for all schema changes
2. WHEN a migration is created, THE migration tool SHALL generate a timestamped migration file with up and down methods
3. WHEN a migration is applied, THE migration tool SHALL record the migration version in a schema_migrations table
4. THE Backend_API SHALL prevent application startup if pending migrations exist in production environment
5. WHEN a migration fails, THE migration tool SHALL roll back the transaction and leave the database in the previous consistent state
6. THE migration tool SHALL support data migrations for transforming existing records during schema changes
7. THE Backend_API SHALL require peer review and testing of all migrations before production deployment

### Requirement 26: Onboarding Self-Selection Screen

**User Story:** As a new User completing OTP verification, I want a single onboarding screen that lets me say in one tap who I am, so that the app routes me to the right experience without lengthy questionnaires.

#### Acceptance Criteria

1. WHEN a new User completes OTP verification and has no pending invitation, THE Mobile_App SHALL display the Onboarding_Screen as the next screen
2. THE Onboarding_Screen SHALL render a 2x3 grid of six tap-cards labeled "For me & family" (personal), "My shop / business" (business_owner), "Parent — Health tracking" (parent), "Pharmacy" (pharmacy), "School / Institution" (institution), and "Auditor (invited)" (auditor_invited)
3. THE Onboarding_Screen SHALL play a Lottie_Animation on each card on entrance using a staggered fly-in with ease-out-back curve, sourced from the LottieFiles free library for MVP
4. WHEN a User taps a card, THE Onboarding_Screen SHALL apply a scale-down to 0.95, trigger a light-impact haptic, play the card's Lottie_Animation, and draw a checkmark
5. THE Onboarding_Screen SHALL maintain 60 frames per second during all animations on mid-range Android devices
6. THE Mobile_App SHALL allow a typical User to complete card selection in 10 seconds or less from screen-load to next-screen transition
7. WHEN a User confirms a card selection, THE Mobile_App SHALL POST the chosen Onboarding_Segment to `POST /api/v1/onboarding/segment` with the segment value in the request body
8. WHEN the Backend_API receives a valid Onboarding_Segment, THE Backend_API SHALL persist the segment on the User record and return the post-selection routing target
9. WHEN the Onboarding_Segment is "personal", THE Mobile_App SHALL transition to the Consumer home screen with a Hero animation
10. WHEN the Onboarding_Segment is "parent", THE Mobile_App SHALL transition to the Consumer home screen and prompt the User to set up an Allergen_Profile
11. WHEN the Onboarding_Segment is "business_owner", "pharmacy", or "institution", THE Mobile_App SHALL transition into the Business_Activation flow with the corresponding preset
12. WHEN the Onboarding_Segment is "auditor_invited", THE Mobile_App SHALL prompt the User to enter or scan an invitation token and SHALL validate the token against the Backend_API before granting Auditor role
13. THE Mobile_App SHALL be designed so that LottieFiles assets can be replaced post-launch with custom motion-designer assets without code changes outside the assets directory

### Requirement 27: Business Activation Touchpoints

**User Story:** As a Consumer who runs a shop or business, I want frequent low-friction prompts to upgrade to a business account, so that I can discover the business features without re-signing up.

#### Acceptance Criteria

1. THE Backend_API SHALL expose `POST /api/v1/account/activate-business` that upgrades the authenticated Consumer to the Owner role and creates a tenant with at least one Store
2. WHEN a Consumer User selects the "My shop / business" card on the Onboarding_Screen, THE Mobile_App SHALL invoke `POST /api/v1/account/activate-business` after the User confirms business details
3. WHEN a Consumer User has accumulated 5 or more total scans, THE Mobile_App SHALL display a smart banner reading "Scan a lot? Run a shop?" linking to Business_Activation
4. THE Mobile_App SHALL render a "Upgrade to Business — manage inventory" card on the Consumer home screen for any User on Free_Consumer_Tier
5. WHEN a Consumer User exceeds 50 scans within a 7-day rolling window, THE Mobile_App SHALL display a heavy-scan Business_Activation prompt
6. THE Mobile_App SHALL render a prominent Business_Activation call-to-action on the User's profile screen for any User on Free_Consumer_Tier or Premium_Consumer_Tier
7. WHEN a Consumer User has logged in on each of the last 7 days, THE Backend_API SHALL send an FCM push notification on day 7 inviting the User to upgrade to Business_Activation
8. WHEN a Free_Consumer_Tier User attempts to save a 6th product (limit-trigger), THE Mobile_App SHALL show a Business_Activation prompt as one of the available upgrade options alongside Premium_Consumer_Tier
9. WHEN `POST /api/v1/account/activate-business` succeeds, THE Backend_API SHALL change the User's role from Consumer to Owner and SHALL emit an Analytics_Event named `business_mode_activated`

### Requirement 28: Notification Stack and Channels

**User Story:** As a User, I want notifications delivered through the appropriate channel for each purpose so that I receive timely information without unwanted SMS, and I want full per-category control over what I receive.

#### Acceptance Criteria

1. THE Backend_API SHALL use FCM as the primary push notification channel for engagement, expiry alerts, recall warnings, daily streaks, and marketing messages
2. THE Backend_API SHALL deliver in-app notifications through the In_App_Notification_Center as a secondary channel and SHALL persist notifications for at least 30 days
3. THE Backend_API SHALL use AWS_SES for email notifications (receipts, weekly digests, business reports, password reset)
4. THE Backend_API SHALL use MSG91 SMS only for OTP delivery during signup and login and SHALL NOT use SMS for engagement notifications
5. THE Backend_API SHALL store Notification_Preferences per User per category and per channel (FCM, email, in-app, SMS)
6. WHEN the Backend_API sends a notification, THE Backend_API SHALL check the User's Notification_Preferences for the relevant category and channel and SHALL suppress the notification if the User has opted out
7. WHEN AWS_SES email volume for a billing month approaches 62,000 messages, THE Backend_API SHALL log a budget warning to RADHA_Owner
8. IF an FCM delivery returns a permanent failure (e.g., unregistered token), THEN THE Backend_API SHALL mark the device token invalid and stop sending to that token

### Requirement 29: Operational Health Score

**User Story:** As a business Owner or Manager, I want a single 0-100 Operational_Health_Score for my store, so that I can track operational quality at a glance and benchmark improvements over time.

#### Acceptance Criteria

1. THE Backend_API SHALL compute an Operational_Health_Score in the range 0–100 for every business tenant once per day
2. THE Operational_Health_Score SHALL combine six components with the following weights: Compliance 25%, Expiry Management 20%, Inventory Accuracy 20%, Task Completion 15%, Team Activity 10%, Vendor Quality 10%
3. THE Compliance component SHALL combine EAN approval rate, mismatch rate, and audit completion rate
4. THE Expiry Management component SHALL combine the percentage of items in green expiry status and the expired-loss rate
5. THE Inventory Accuracy component SHALL be derived from variance between counted stock and system stock
6. THE Task Completion component SHALL be the on-time completion rate of tasks in the scoring window
7. THE Team Activity component SHALL be the count of active staff days per week relative to the active staff roster
8. THE Vendor Quality component SHALL combine on-time GRN delivery rate and batch consistency
9. THE Backend_API SHALL store the Health_Score_Algorithm_Version (e.g., "v1.2") with each Operational_Health_Score record so that historical scores remain valid when the algorithm changes
10. THE Client_Dashboard SHALL display the latest Operational_Health_Score, the per-component breakdown, and the trend over the last 30 days
11. WHEN the Operational_Health_Score for a tenant changes by more than 10 points day-over-day, THE Backend_API SHALL send an FCM notification to the Owner subject to Notification_Preferences

### Requirement 30: Expiry Calendar (Consumer)

**User Story:** As a Consumer, I want a calendar view of all my saved products' expiry dates, so that I can plan consumption and reduce waste at home.

#### Acceptance Criteria

1. THE Mobile_App SHALL display an Expiry_Calendar view to authenticated Consumers showing all saved products' expiry dates on a monthly grid
2. THE Expiry_Calendar SHALL color-code dates green when no products expire, yellow when products are within 7–30 days of expiry, and red when products are within 7 days of expiry or already expired
3. WHEN a Consumer taps a date with products, THE Mobile_App SHALL display the list of products expiring on that date with quick actions to mark consumed or remove
4. THE Backend_API SHALL expose `GET /api/v1/consumer/expiry-calendar?month=YYYY-MM` returning per-day product counts and per-day product lists for the requested month
5. WHERE the User holds Premium_Consumer_Tier, THE Expiry_Calendar SHALL include products tracked under Family_Sharing profiles
6. WHERE the User holds Free_Consumer_Tier, THE Expiry_Calendar SHALL be limited to the 5 saved products allowed by the tier

### Requirement 31: Recall Alerts

**User Story:** As a Consumer or business User, I want to be alerted when any of my saved products is recalled by the FSSAI or other government bodies, so that I can stop consuming or selling unsafe items.

#### Acceptance Criteria

1. THE Recall_Sweep_Job SHALL run once per day on a schedule configured in the Database
2. WHEN the Recall_Sweep_Job runs, THE Backend_API SHALL fetch the latest FSSAI recall feed and other configured government recall feeds
3. WHEN a recall entry matches a User's saved product (by EAN, brand+name, or batch identifier), THE Backend_API SHALL create a Recall_Alert record linked to the User and the product
4. WHEN a Recall_Alert is created, THE Backend_API SHALL send an FCM push notification to the User subject to Notification_Preferences
5. THE Mobile_App SHALL display Recall_Alerts in a dedicated section of the In_App_Notification_Center with the recall reason, source, and date
6. WHERE a recall feed fetch fails, THE Backend_API SHALL retry up to 3 times with exponential backoff and SHALL log a failure to Sentry if all retries fail
7. THE Backend_API SHALL cache Recall_Alert lookups with a Cache_Layer TTL of 1 hour

### Requirement 32: Allergen Profile

**User Story:** As a parent or health-conscious Consumer, I want to define allergens and conditions per family member, so that scan output flags any matching ingredients automatically.

#### Acceptance Criteria

1. THE Mobile_App SHALL allow a Consumer to create one Allergen_Profile per family member with the family member's display name, age band, allergy tags, and condition tags
2. THE Backend_API SHALL persist Allergen_Profiles encrypted at rest under the User's tenant scope
3. WHEN a Comprehensive_Scan_Output is requested, THE Backend_API SHALL match the product's ingredients and allergens against the active Allergen_Profile and SHALL include matching allergen flags in the response
4. THE Mobile_App SHALL highlight matched allergens visually with a red banner and the family member's name
5. WHERE the User holds Free_Consumer_Tier, THE Allergen_Profile feature SHALL be limited to 1 family member profile
6. WHERE the User holds Premium_Consumer_Tier, THE Allergen_Profile feature SHALL allow up to 5 family member profiles via Family_Sharing

### Requirement 33: Family Sharing

**User Story:** As a Premium_Consumer, I want one subscription to cover up to five family members, so that we can each have our own scan history and Allergen_Profile under one bill.

#### Acceptance Criteria

1. WHERE the authenticated User holds Premium_Consumer_Tier, THE Backend_API SHALL allow up to 5 linked family member profiles per primary account
2. WHEN the primary User invites a family member by mobile number, THE Backend_API SHALL create a pending family link and SHALL send an FCM or SMS-OTP-flow invitation to the invitee
3. WHEN a family member accepts an invitation, THE Backend_API SHALL link the invitee's Consumer account to the primary account's Premium_Consumer subscription
4. THE Backend_API SHALL share Premium_Consumer entitlements (unlimited scans, comprehensive output, expiry calendar, recall alerts) with linked family members while preserving each member's separate scan history and Allergen_Profile
5. WHEN the primary User removes a family member, THE Backend_API SHALL revoke the family member's Premium_Consumer entitlements within 5 minutes and SHALL leave the family member on Free_Consumer_Tier
6. IF the primary User attempts to add a 6th family member, THEN THE Backend_API SHALL return an error indicating the family-sharing limit has been reached

### Requirement 34: Multi-Language Support

**User Story:** As a User who is more comfortable in an Indian regional language, I want the UI and scan output translated, so that I can use RADHA in my preferred language.

#### Acceptance Criteria

1. THE Mobile_App SHALL provide UI translations for English, Hindi, Tamil, Telugu, Bengali, and Marathi using i18n translation files
2. THE Mobile_App SHALL allow the User to change the language at any time from settings, and the change SHALL apply immediately without requiring a restart
3. THE Backend_API SHALL accept an `Accept-Language` header on scan endpoints and SHALL return localized fields (product name, ingredients explanation, health PROS, health CONS) when localized data exists
4. WHERE localized fields are not available for a product, THE Backend_API SHALL return the English values as a fallback
5. THE Backend_API SHALL persist the User's preferred language on the User record so that notifications and emails are also localized
6. THE Mobile_App SHALL ship initial translation files for all six languages at first release of the multi-language feature

### Requirement 35: Affiliate Links and Healthier Alternatives Engine

**User Story:** As a Consumer scanning a product, I want to see healthier alternatives with links to buy them, so that I can make better choices, and as RADHA, I want to earn affiliate revenue from those links.

#### Acceptance Criteria

1. WHEN a Comprehensive_Scan_Output is generated, THE Healthy_Alternatives_Engine SHALL select up to 3 healthier alternatives from the Product_Catalog using rule-based scoring and SHALL include them in the scan response
2. THE Affiliate_Engine SHALL attach an Affiliate_Link to each healthier alternative, embedding the configured Amazon or Flipkart affiliate identifier
3. WHEN a User taps an Affiliate_Link, THE Mobile_App SHALL open the link in an external browser and SHALL POST a click event to the Backend_API with the source product, alternative product, and partner identifier
4. THE Backend_API SHALL persist affiliate click events and SHALL aggregate click-through and revenue metrics in the Owner_Dashboard
5. WHERE no healthier alternatives meet the scoring threshold, THE Healthy_Alternatives_Engine SHALL return an empty list rather than low-quality recommendations
6. THE Backend_API SHALL ensure the Affiliate_Engine is only invoked for tenants whose subscription includes Comprehensive_Scan_Output access

### Requirement 36: Voice Features Deferral

**User Story:** As a User and as a product team, I want voice features clearly scoped out of v1, so that v1 ships on time without voice scope creep.

#### Acceptance Criteria

1. THE RADHA_System v1 SHALL NOT include voice scan, voice search, or voice shopping list intake features
2. THE Mobile_App v1 SHALL NOT expose any voice-only entry points
3. WHERE the Shopping_List_Module is implemented in v1, THE Shopping_List_Module SHALL accept text input only
4. WHEN voice features are introduced in v2, THE Mobile_App SHALL gate them behind a Feature_Flag_Service flag

### Requirement 37: Offline-First Mobile Architecture

**User Story:** As a User on a flaky mobile connection, I want the app to work offline-first with a reliable sync engine, so that I can scan, save, and review products even when the network is unreliable.

#### Acceptance Criteria

1. THE Mobile_App SHALL maintain a Local_Database using Drift or Isar to persist product reads, scan history, saved products, expiry data, and queued mutations
2. THE Sync_Engine SHALL push queued local mutations to the Backend_API in the order they were created
3. WHEN the Mobile_App issues a mutating request, THE Mobile_App SHALL attach a client-generated Idempotency_Key in the request header
4. WHEN the Backend_API receives a mutating request with an Idempotency_Key it has already processed within the last 24 hours, THE Backend_API SHALL return the original result without re-applying the mutation
5. WHEN a sync conflict is detected between a local record and a server record, THE Sync_Engine SHALL apply the Conflict_Resolution_Policy of last-write-wins by default
6. WHERE a record's field is marked as critical (e.g., subscription tier, payment state, role), THE Conflict_Resolution_Policy SHALL be server-wins regardless of local timestamp
7. WHEN connectivity is restored, THE Sync_Engine SHALL drain the queued mutations within 30 seconds for queues of up to 200 items

### Requirement 38: Image OCR Scan Fallback

**User Story:** As a User scanning a product whose barcode cannot be decoded, I want the app to fall back to a photo of the packaging so I still get a result, so that scanning rarely fails.

#### Acceptance Criteria

1. WHEN the Scanner cannot decode an EAN within 2 seconds of viewfinder activation, THE Mobile_App SHALL prompt the User to take a photo of the packaging
2. WHEN the User submits a packaging photo, THE Mobile_App SHALL upload the image via Presigned_URL and SHALL request product identification from `POST /api/v1/scan/image-fallback`
3. THE Backend_API SHALL identify the product using either Google Cloud Vision API or a self-hosted ML model based on configuration and SHALL return the product or a no-match response within 8 seconds
4. WHEN a product is identified by Image_OCR_Fallback, THE Backend_API SHALL upsert the product into the Product_Catalog and SHALL return the same response shape as a normal scan
5. THE Backend_API SHALL track Image_OCR_Fallback usage counts and estimated cost (e.g., ₹0.001 per image when Google Cloud Vision is used) per tenant for cost monitoring
6. IF the Image_OCR_Fallback returns no match, THEN THE Mobile_App SHALL allow the User to fall back to manual product creation as defined in Requirement 3

### Requirement 39: Search-First Product Discovery

**User Story:** As a User who does not have a barcode handy, I want to search for products by name or brand from anywhere in the app, so that I can find what I need quickly.

#### Acceptance Criteria

1. THE Mobile_App SHALL display a fuzzy search bar on the home screen, scanner screen, and product list screens
2. THE Backend_API SHALL expose `GET /api/v1/products/search?q=...` returning fuzzy matches on product name and brand
3. THE Search_Service SHALL return the top 20 fuzzy matches within 500 milliseconds for queries up to 80 characters
4. THE Search_Service SHALL apply the same tenant scoping rules as other product endpoints
5. WHERE the User holds Free_Consumer_Tier, THE Search_Service SHALL apply the same daily scan/save quotas to search-driven product opens
6. THE Search_Service SHALL cache common queries in the Cache_Layer with a 5-minute TTL

### Requirement 40: Free-Tier Rate Limiting and Quotas

**User Story:** As the RADHA platform operator, I want per-tier daily quotas tracked precisely, so that paid tiers have a clear value proposition and free use stays sustainable.

#### Acceptance Criteria

1. THE Rate_Limit_Service SHALL track per-User daily scan counts and per-User saved-product counts in Redis
2. WHERE the User holds Free_Consumer_Tier, THE Rate_Limit_Service SHALL enforce 50 scans per day and 5 saved products total
3. WHERE the User holds Premium_Consumer_Tier, THE Rate_Limit_Service SHALL allow unlimited scans and unlimited saved products subject only to global rate limits in Requirement 24
4. WHERE the User is on Trial_Pro, THE Rate_Limit_Service SHALL enforce Starter_Plan limits (1 store, 5 users, 5,000 scans/month) while exposing Pro_Plan features
5. THE Rate_Limit_Service SHALL reset daily counters at 00:00 IST
6. WHEN a User exceeds a tier quota, THE Backend_API SHALL return HTTP 429 with a payload identifying which quota was exceeded and the time of next reset
7. THE Mobile_App SHALL display a tier-aware upgrade prompt when a quota is exceeded

### Requirement 41: Multi-Tenant Data Isolation Hardening

**User Story:** As a tenant, I want my data strictly isolated from other tenants at the database, middleware, and test layers, so that no cross-tenant access is ever possible.

#### Acceptance Criteria

1. THE Database SHALL enable PostgreSQL_RLS policies on every tenant-scoped table
2. THE Tenant_Scope_Middleware SHALL inject tenant_id from the authenticated session on every database query
3. IF a query reaches the Database without a resolvable tenant_id, THEN THE Database SHALL reject the query under PostgreSQL_RLS
4. THE Backend_API SHALL include cross-tenant isolation property tests in its automated test suite asserting that any User cannot read or modify rows belonging to another tenant
5. WHEN a Backend_API endpoint is added or modified, THE codebase SHALL require Tenant_Scope_Middleware to be applied unless the endpoint is explicitly listed as tenant-public (e.g., Marketing_Website forms, Public_Product_Profile_Pages)
6. WHEN a query touches Owner_Dashboard data, THE Backend_API SHALL use the Owner_Dashboard scope and SHALL bypass tenant scoping only for the aggregate metrics defined in Requirement 15

### Requirement 42: Referral Program

**User Story:** As a User, I want to invite friends and earn a free month of Premium_Consumer_Tier when they sign up, so that I have an incentive to grow the user base.

#### Acceptance Criteria

1. THE Database SHALL include `referral_code`, `referred_by`, and `referral_rewards` columns on the User table
2. THE Backend_API SHALL generate a unique Referral_Code for every new User
3. WHEN a new User signs up using a valid Referral_Code, THE Backend_API SHALL link the new User to the inviter via `referred_by` and SHALL grant 1 free month of Premium_Consumer_Tier to both the inviter and the invitee
4. THE Backend_API SHALL apply the free month by extending the Premium_Consumer_Tier renewal date or starting one if the User is currently on Free_Consumer_Tier
5. WHERE the inviter is on a business tier, THE referral reward SHALL credit 1 free month of Premium_Consumer_Tier to a linked Family_Sharing slot or to a future tier change rather than discounting the business plan
6. IF an attempted Referral_Code is invalid or self-referring, THEN THE Backend_API SHALL reject the referral and SHALL still allow the signup to complete without rewards

### Requirement 43: Smart Caching Layer

**User Story:** As the RADHA platform operator, I want a tiered cache to reduce database load and speed up scans, so that the platform stays fast and cheap.

#### Acceptance Criteria

1. THE Cache_Layer SHALL use Redis as its backing store
2. THE Cache_Layer SHALL cache product details with a 24-hour TTL
3. THE Mobile_App SHALL persist scan history locally for the lifetime of the install (forever-local) under the Local_Database
4. THE Cache_Layer SHALL cache Recall_Alert lookups with a 1-hour TTL
5. WHEN a cached product is updated by a Manager or by the Barcode_Learning_Service, THE Backend_API SHALL invalidate the corresponding Cache_Layer entry within 1 second
6. THE Cache_Layer SHALL use cache keys scoped by tenant_id where applicable so that cache invalidation does not leak across tenants

### Requirement 44: Analytics Events from Day 1

**User Story:** As a product manager, I want every user action emitted as a structured event to PostHog from launch day, so that we can measure activation, conversion, and feature usage without retrofitting later.

#### Acceptance Criteria

1. THE Mobile_App and Backend_API SHALL emit Analytics_Events to PostHog using the PostHog SDK
2. THE Analytics_Event taxonomy SHALL include at minimum: `app_opened`, `product_scanned`, `trial_started`, `trial_converted`, `business_mode_activated`, `feature_locked_seen`, `subscription_purchased`, `subscription_cancelled`, `recall_alert_received`, `affiliate_link_clicked`
3. THE Analytics_Event payload SHALL include user identifier, tenant identifier, subscription tier, app version, and platform (iOS/Android)
4. WHERE PostHog event volume in a billing month approaches 1,000,000 events, THE Backend_API SHALL log a budget warning to RADHA_Owner
5. THE Backend_API SHALL be designed so that PostHog can be self-hosted by changing only the SDK endpoint configuration
6. WHEN a User has not consented to analytics in Notification_Preferences, THE Mobile_App SHALL emit only the minimum required events for fraud and abuse monitoring and SHALL anonymize the user identifier

### Requirement 45: AI Ingredient Explainer

**User Story:** As a Consumer reading a Comprehensive_Scan_Output, I want to tap any ingredient and see a plain-language explanation of what it is and any health considerations, so that I can understand what I am eating.

#### Acceptance Criteria

1. THE Backend_API SHALL expose `GET /api/v1/ingredients/{ingredient_slug}/explanation` returning a plain-language explanation of the ingredient
2. WHEN an explanation is not yet cached, THE Backend_API SHALL call an LLM (OpenAI or Claude) via an abstracted wrapper to generate the explanation and SHALL persist the result in the Database for permanent reuse
3. THE explanation response SHALL include the ingredient name, plain-language description, common health considerations, and a confidence indicator
4. WHEN the LLM call fails or times out after 10 seconds, THE Backend_API SHALL return a graceful "Explanation unavailable" response and SHALL log the failure to Sentry
5. THE Backend_API SHALL track AI_Ingredient_Explainer usage counts and estimated cost per tenant for cost monitoring
6. THE Backend_API SHALL localize cached explanations using the same multi-language pipeline defined in Requirement 34

### Requirement 46: Barcode Learning (Community Crowdsourcing)

**User Story:** As a User scanning an India-specific product not in Open Food Facts, I want to submit photos and details so the next user benefits, so that the catalog improves quickly for our market.

#### Acceptance Criteria

1. WHEN the Backend_API has no product for an EAN and no Open Food Facts match, THE Mobile_App SHALL allow the User to submit photos and details to the Barcode_Learning_Service
2. THE Backend_API SHALL expose `POST /api/v1/products/learn` accepting EAN, photos via Presigned_URL upload, brand, name, and category
3. WHEN a learning submission is received, THE Backend_API SHALL store it in a moderation queue and SHALL NOT make the data public to other tenants until approved
4. WHERE a learning submission is approved by a moderator, THE Backend_API SHALL upsert the data into the public Product_Catalog and SHALL credit the submitting User with an Analytics_Event
5. THE Backend_API SHALL allow Users to flag incorrect community-submitted data and SHALL re-queue the product for moderation when at least 3 unique flags are received

### Requirement 47: Daily Insights and Shopping List

**User Story:** As a Consumer, I want a weekly digest with my scan summary and personalized alternatives, plus a simple shopping list I can optionally send to a kirana, so that the app feels useful between scans.

#### Acceptance Criteria

1. THE Daily_Insights_Job SHALL run on a weekly schedule and SHALL generate a personalized digest per active Consumer summarizing scans, savings, recall alerts, and recommended alternatives
2. WHEN a Consumer's weekly digest is ready, THE Backend_API SHALL deliver the digest via FCM push notification subject to Notification_Preferences
3. THE Mobile_App SHALL provide a Shopping_List_Module accepting text input items with optional notes and quantities
4. WHERE the User configures a kirana WhatsApp number, THE Shopping_List_Module SHALL allow sending the shopping list as a formatted WhatsApp message via the user's installed WhatsApp client
5. THE Shopping_List_Module SHALL persist lists locally in the Local_Database and SHALL sync to the Backend_API for backup
6. THE Daily_Insights_Job SHALL skip Users who have opted out of marketing notifications in Notification_Preferences

### Requirement 48: Feature Flags

**User Story:** As a developer, I want per-user feature flags with A/B testing and gradual rollout, so that I can ship safely and learn from experiments.

#### Acceptance Criteria

1. THE Feature_Flag_Service SHALL be implemented using Unleash or GrowthBook
2. THE Backend_API and Mobile_App SHALL evaluate feature flags using a stable bucket key derived from User identifier
3. THE Feature_Flag_Service SHALL support boolean flags, multivariate flags for A/B testing, and percentage-based gradual rollouts
4. WHEN a feature flag value changes for a User, THE Mobile_App SHALL apply the new value within 5 minutes
5. THE Backend_API SHALL log feature flag evaluations as Analytics_Events tagged with the flag name and assigned variant
6. WHERE a feature flag is unavailable due to service failure, THE Feature_Flag_Service SHALL return the flag's default value and SHALL log a warning to Sentry

### Requirement 49: Observability

**User Story:** As an on-call engineer, I want crash reports, traces, and logs centralized, so that I can detect and diagnose production issues quickly.

#### Acceptance Criteria

1. THE Mobile_App and Backend_API SHALL integrate Sentry for crash and error reporting
2. THE Backend_API SHALL instrument requests, database queries, and external API calls using OpenTelemetry
3. THE Backend_API SHALL export OpenTelemetry traces and logs to Grafana_Cloud (or a compatible backend) for centralized observability
4. THE Backend_API SHALL include the correlation ID from Requirement 23 in every OpenTelemetry span and log line
5. WHEN Sentry monthly error volume approaches 5,000 events, THE Backend_API SHALL log a budget warning to RADHA_Owner
6. WHEN Backend_API error rate exceeds 1% of requests over a 5-minute window, THE Backend_API SHALL trigger an alert to RADHA_Owner via the configured alerting channel

### Requirement 50: Database Backups and Point-In-Time Recovery

**User Story:** As the RADHA platform operator, I want reliable backups, PITR, and tested restores, so that we can recover from data-loss incidents with confidence.

#### Acceptance Criteria

1. THE Backup_Service SHALL enable PostgreSQL WAL archiving to AWS S3 continuously
2. THE Backup_Service SHALL take an automated daily snapshot of the Database and SHALL store the snapshot in AWS S3
3. THE Backup_Service SHALL retain daily snapshots for at least 30 days
4. THE Backend_API SHALL support PITR back to any point within the WAL retention window
5. THE Backup_Service SHALL execute a monthly automated restore test against a non-production environment and SHALL record the result
6. IF a monthly restore test fails, THEN THE Backup_Service SHALL alert RADHA_Owner within 1 hour

### Requirement 51: Admin Impersonation Tool

**User Story:** As a RADHA support staff member, I want a time-limited audited "view as user" tool, so that I can help users without holding standing access to their data.

#### Acceptance Criteria

1. THE Admin_Impersonation_Tool SHALL be available only from the Owner_Dashboard and only to authenticated RADHA_Owner support staff
2. WHEN a support staff member starts an impersonation session, THE Backend_API SHALL require a written reason and SHALL grant a session limited to 60 minutes
3. WHILE an impersonation session is active, THE Backend_API SHALL tag every request with the impersonating staff identifier and the impersonated User identifier
4. THE Backend_API SHALL persist an audit record for each impersonation session including start time, end time, reason, staff identifier, and User identifier
5. WHEN an impersonation session expires or is ended, THE Backend_API SHALL revoke the impersonation token within 1 minute
6. THE Backend_API SHALL prevent impersonation sessions from initiating destructive actions (e.g., subscription cancellation, account deletion) unless the User has explicitly approved the action via a separate confirmation flow

### Requirement 52: Webhooks for Pro Tier

**User Story:** As a Pro_Plan business with a POS or ERP, I want outbound webhooks for key events, so that I can integrate RADHA with my existing systems.

#### Acceptance Criteria

1. THE Webhook_Service SHALL be available only to tenants on Pro_Plan
2. THE Webhook_Service SHALL support at minimum the events `product.created`, `product.updated`, `inventory.updated`, `grn.posted`, `task.completed`, and `scan_session.ended`
3. THE Webhook_Service SHALL deliver webhook payloads via HTTPS POST with an HMAC-SHA256 signature header keyed by a tenant-specific secret
4. WHEN a webhook delivery fails, THE Webhook_Service SHALL retry up to 5 times with exponential backoff capped at 1 hour
5. WHEN all webhook retries are exhausted, THE Webhook_Service SHALL persist the failed delivery for 7 days and SHALL allow the tenant to manually replay it from the Mobile_App or Owner_Dashboard
6. THE Mobile_App SHALL allow Owners on Pro_Plan to configure up to 5 webhook endpoints per tenant

### Requirement 53: Public Product Profile Pages (SEO)

**User Story:** As a marketing-driven growth lever, I want every scanned product to have a public SEO-indexed page, so that organic search drives new users to RADHA.

#### Acceptance Criteria

1. THE Public_Product_Service SHALL generate a Public_Product_Profile_Page at the URL pattern `https://radha.app/p/{slug}` for every product in the Product_Catalog
2. THE Public_Product_Profile_Page SHALL be statically generated using Next.js static rendering and SHALL be revalidated at most every 24 hours
3. THE Public_Product_Profile_Page SHALL include product name, brand, category, ingredients, basic Health_Indicator, and a call-to-action to download the Mobile_App
4. THE Public_Product_Profile_Page SHALL emit canonical, Open Graph, and JSON-LD product structured data for search engine indexing
5. THE Public_Product_Service SHALL exclude all tenant-specific data (scan counts, who saved it, who scanned it) from the public page
6. WHERE a product is removed from the Product_Catalog or flagged unsafe, THE Public_Product_Service SHALL return HTTP 410 Gone for the corresponding slug

### Requirement 54: RADHA Verified Badge for Retailers

**User Story:** As a Pro_Plan retailer, I want a "RADHA Verified" badge I can use on WhatsApp Business and Instagram, so that I can signal trust to my customers.

#### Acceptance Criteria

1. THE Backend_API SHALL issue a RADHA_Verified_Badge to a Pro_Plan tenant whose Operational_Health_Score has been at or above 75 for at least 30 consecutive days
2. THE Mobile_App SHALL display the RADHA_Verified_Badge status in the Client_Dashboard with the date earned and the current Operational_Health_Score
3. THE Backend_API SHALL provide downloadable badge assets (PNG and SVG) sized for WhatsApp Business profile and Instagram bio
4. WHEN a tenant's Operational_Health_Score falls below 70 for 7 consecutive days, THE Backend_API SHALL revoke the RADHA_Verified_Badge and SHALL notify the Owner via FCM and email
5. THE Backend_API SHALL maintain a public verification endpoint `GET /api/v1/verify/{tenant_slug}` confirming whether a tenant currently holds a valid RADHA_Verified_Badge

### Requirement 55: Staff Invitation Flow

**User Story:** As a business Owner, I want to invite my staff and managers by mobile number and have them onboarded automatically with the right role, so that I don't have to walk each one through setup.

#### Acceptance Criteria

1. WHEN an Owner invites a staff or manager User, THE Backend_API SHALL accept the invitee's mobile number, the assigned role (Staff, Manager, or Auditor), and an optional Store assignment
2. WHEN an invitation is created, THE Backend_API SHALL create a pending invitation record linked to the mobile number and the inviter's tenant
3. WHEN an invitation is created, THE Backend_API SHALL send an SMS via MSG91 containing a download link to the Mobile_App
4. WHEN an invitee installs the Mobile_App and completes OTP login, THE Backend_API SHALL detect the pending invitation linked to that mobile number
5. WHEN a pending invitation is detected, THE Backend_API SHALL auto-create the User account under the inviting tenant with the assigned role and Store, and SHALL bypass the Onboarding_Screen self-selection
6. THE Mobile_App SHALL render only the views permitted by the assigned role for invited Users (Staff, Manager, or Auditor)
7. WHERE an invitation has been pending for more than 30 days, THE Backend_API SHALL mark the invitation expired and SHALL require the Owner to re-issue it
8. WHEN an Owner revokes an invitation, THE Backend_API SHALL delete the pending invitation record and SHALL prevent automatic onboarding from that mobile number
