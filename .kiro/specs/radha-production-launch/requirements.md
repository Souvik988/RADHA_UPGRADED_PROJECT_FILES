# Requirements Document

## Introduction

This document specifies the requirements for launching the RADHA platform into production. It covers AWS infrastructure provisioning, Docker deployment, production configuration, release signing, performance optimization, CDN delivery, monitoring, legal compliance, and Play Store listing. Requirements are organized by launch phase: P0 (production blockers), P1 (performance and polish), P2 (store listing and operational maturity).

## Glossary

- **API_Server**: The NestJS REST API process running in the `radha-api` Docker container on EC2
- **Worker**: The NestJS BullMQ worker process running in the `radha-worker` Docker container
- **Scheduler**: The NestJS cron process running in the `radha-scheduler` Docker container
- **Compose_Stack**: The set of three Docker containers (API, Worker, Scheduler) managed by `docker-compose.prod.yml`
- **RDS_Instance**: The AWS RDS PostgreSQL 16 managed database instance in ap-south-2
- **ElastiCache_Cluster**: The AWS ElastiCache Redis 7 node in ap-south-2
- **S3_Bucket**: The `radha-prod-media` S3 bucket storing product images and uploaded media
- **CloudFront_Distribution**: The AWS CloudFront CDN distribution serving assets from S3_Bucket
- **Nginx_Proxy**: The nginx reverse proxy on EC2 that terminates TLS and forwards to API_Server
- **Mobile_App**: The Flutter mobile application built as a signed AAB/APK
- **Upload_Keystore**: The Java keystore file used to sign release builds for Play Store upload
- **Health_Endpoint**: The `/api/v1/health` (shallow) and `/api/v1/health/ready` (deep) HTTP endpoints
- **Env_Schema**: The Zod validation schema at `src/config/env.schema.ts` that validates production configuration
- **Play_Console**: Google Play Console where the AAB is uploaded for distribution

## Requirements

### Requirement 1: AWS Infrastructure Provisioning

**User Story:** As a platform operator, I want managed AWS infrastructure provisioned in ap-south-2, so that the backend has resilient, encrypted data services with minimal operational burden.

#### Acceptance Criteria

1. THE RDS_Instance SHALL run PostgreSQL 16 with storage encryption enabled and TLS connections enforced
2. THE RDS_Instance SHALL have automated backups enabled with a retention period of at least 7 days
3. THE ElastiCache_Cluster SHALL run Redis 7 with in-transit encryption enabled
4. THE S3_Bucket SHALL have block-public-access enabled and serve content exclusively through CloudFront_Distribution
5. THE CloudFront_Distribution SHALL use Origin Access Control (OAC) to access S3_Bucket and enforce TLS 1.2 minimum
6. WHEN a network connection is attempted to RDS_Instance port 5432 from outside the EC2 security group, THEN the connection SHALL be denied
7. WHEN a network connection is attempted to ElastiCache_Cluster port 6379 from outside the EC2 security group, THEN the connection SHALL be denied
8. THE EC2 security group SHALL allow inbound TCP 22 only from the administrator's IP address and TCP 80+443 from all sources

### Requirement 2: Production Environment Configuration

**User Story:** As a platform operator, I want strict validation of production configuration, so that the system cannot start with insecure or incomplete settings.

#### Acceptance Criteria

1. WHEN the API_Server starts with `NODE_ENV=production`, THEN the Env_Schema SHALL enforce that `DB_SSL` is `true`
2. WHEN the API_Server starts with `NODE_ENV=production`, THEN the Env_Schema SHALL enforce that `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET` are each at least 64 characters
3. WHEN the API_Server starts with `NODE_ENV=production`, THEN the Env_Schema SHALL enforce that `CORS_ORIGINS` does not contain the wildcard `*`
4. WHEN the Env_Schema validation fails, THEN the API_Server SHALL exit with a non-zero code and log a descriptive error identifying which variables failed validation
5. THE `.env.production` file SHALL have file permissions `600` on the EC2 host and SHALL NOT be present in the Docker image layers
6. WHEN generating JWT secrets, THE platform operator SHALL use `openssl rand -hex 48` or equivalent to produce cryptographically random values

### Requirement 3: Docker Build and Deployment

**User Story:** As a platform operator, I want to build and deploy the backend via Docker Compose on EC2, so that all three NestJS processes run reliably with automatic restarts.

#### Acceptance Criteria

1. WHEN `docker compose -f docker-compose.prod.yml up -d --build` is executed, THEN the Compose_Stack SHALL build the `radha-server` image and start api, worker, and scheduler containers
2. THE API_Server container SHALL bind only to `127.0.0.1:3000` and SHALL NOT expose port 3000 on the public interface
3. THE Compose_Stack SHALL apply `restart: always` so containers recover from transient failures
4. WHEN the API_Server container's healthcheck fails 5 consecutive times, THEN Docker SHALL mark it as unhealthy
5. THE Docker image SHALL execute application processes as a non-root user (UID ≠ 0)
6. WHEN the `@/` TypeScript path alias fails to resolve at runtime, THEN the documented fix (either `tsconfig-paths/register` with `tsconfig.runtime.json` or `tsc-alias` post-build step) SHALL resolve the issue

### Requirement 4: Database Migration and Seed

**User Story:** As a platform operator, I want to run migrations and seed production data, so that the database schema is current and contains the curated product catalog.

#### Acceptance Criteria

1. WHEN `pnpm db:migrate` is executed inside the api container, THEN all pending migrations SHALL be applied sequentially to the RDS_Instance
2. WHEN `pnpm db:import:curated` is executed inside the api container, THEN 29 branded products with real Open Food Facts nutrition data SHALL be inserted or updated idempotently
3. IF a migration fails, THEN the migration runner SHALL stop execution, log the error, and leave the database in the state before that migration began
4. WHEN running migrations against production, THE platform operator SHALL take a manual RDS snapshot before execution

### Requirement 5: TLS Termination and Reverse Proxy

**User Story:** As a platform operator, I want nginx with Let's Encrypt TLS on the API domain, so that all client traffic is encrypted and HTTP is automatically redirected to HTTPS.

#### Acceptance Criteria

1. WHEN an HTTP request arrives on port 80 for the API domain, THEN the Nginx_Proxy SHALL respond with a 301 redirect to the HTTPS URL
2. THE Nginx_Proxy SHALL include the `Strict-Transport-Security` header with `max-age=63072000; includeSubDomains` on all HTTPS responses
3. THE Nginx_Proxy SHALL include the `X-Content-Type-Options: nosniff` header on all responses
4. THE Nginx_Proxy SHALL proxy all requests to `http://127.0.0.1:3000` with appropriate `X-Forwarded-For`, `X-Forwarded-Proto`, and `Host` headers
5. WHEN the Let's Encrypt certificate approaches expiry, THEN the certbot systemd timer SHALL automatically renew it and reload nginx
6. THE Nginx_Proxy SHALL limit request body size to 15MB via `client_max_body_size`

### Requirement 6: Mobile App Production API Target

**User Story:** As a mobile developer, I want the Flutter app pointed at the production API, so that release builds communicate with the live backend.

#### Acceptance Criteria

1. WHEN building a release APK or AAB, THE build system SHALL accept `--dart-define=API_BASE_URL=https://api.radha.app/` to set the production API endpoint
2. THE Mobile_App SHALL use the `API_BASE_URL` dart-define value as the Dio base URL for all network requests
3. IF `API_BASE_URL` is not provided at build time, THEN the Mobile_App SHALL default to the development URL (`http://localhost:3000/api/v1`)

### Requirement 7: Release Signing

**User Story:** As a mobile developer, I want the app signed with a proper upload keystore, so that the AAB can be uploaded to Play Console and users receive a Google-signed APK.

#### Acceptance Criteria

1. THE Upload_Keystore SHALL be generated using `keytool` with RSA 2048+ key algorithm and validity of at least 25 years
2. THE `android/app/build.gradle.kts` SHALL reference a `key.properties` file for release signing configuration
3. THE `key.properties` file SHALL be listed in `.gitignore` and SHALL NOT be committed to version control
4. WHEN `flutter build appbundle --release` is executed with the signing configuration, THEN the output AAB SHALL be signed with the Upload_Keystore
5. WHEN the signed AAB is verified with `jarsigner -verify`, THEN it SHALL confirm a valid signature (not debug)
6. THE Upload_Keystore file and its passwords SHALL be backed up in a secure location separate from the repository

### Requirement 8: On-Device Smoke Test

**User Story:** As a QA operator, I want to verify the critical user path on a real device with a release build, so that I can confirm end-to-end functionality before public launch.

#### Acceptance Criteria

1. WHEN the signed release build is installed on a physical Android device, THEN the OTP login flow SHALL complete successfully with a real SMS delivered by 2Factor.in
2. WHEN logged in, THEN navigating Home → Browse Category → Product Detail SHALL display real nutrition data from the production database
3. WHEN a barcode is scanned, THEN the product lookup SHALL return data from the production API
4. WHEN a Razorpay payment is initiated (test mode for P0, live for P2), THEN the checkout flow SHALL complete without errors
5. WHEN the device network is disabled and an expiry record is created, THEN the offline queue SHALL persist the write and sync it when connectivity is restored

### Requirement 9: Performance Profiling and Optimization

**User Story:** As a mobile developer, I want the app to achieve 60fps scrolling and <1.5s cold start, so that the user experience matches premium apps like Zepto/Blinkit.

#### Acceptance Criteria

1. WHEN profiled with `flutter run --profile` and DevTools, THEN the Home screen scroll SHALL maintain 60fps with zero jank frames in the UI thread
2. THE Mobile_App cold start (from tap to interactive Home screen) SHALL complete in under 1.5 seconds on a mid-range Android device
3. WHEN the Home or Browse screen loads, THEN `precacheImage` SHALL be called for the first visible row of product images to eliminate pop-in
4. THE API_Server p95 response latency for read endpoints SHALL be under 200ms as measured by Sentry transaction monitoring

### Requirement 10: CDN Product Image Hosting

**User Story:** As a platform operator, I want product images served from CloudFront CDN, so that images load quickly for Indian users and the app has offline fallback.

#### Acceptance Criteria

1. WHEN `pnpm db:host:images` is executed, THEN the 29 curated product images SHALL be uploaded to S3_Bucket and `products.image_url` SHALL be updated to the CloudFront URL
2. THE CloudFront_Distribution SHALL serve product images with `Cache-Control: public, max-age=86400` headers
3. WHEN a product's CDN image URL returns a non-200 response, THEN the Mobile_App SHALL display the bundled fallback asset without visual breakage
4. THE product images SHALL be in WebP format with maximum dimensions of 400×400 for thumbnails and 1200×1200 for detail views

### Requirement 11: Asset Illustrations Completion

**User Story:** As a mobile developer, I want the remaining placeholder illustrations completed, so that all app states have polished visual assets.

#### Acceptance Criteria

1. THE Mobile_App SHALL include a complete offline-state illustration displayed when the device has no network connectivity
2. THE Mobile_App SHALL include an additive-badge illustration for products containing food additives
3. THE Mobile_App SHALL include an allergen-badge illustration for the allergen warning display

### Requirement 12: Localization Pass

**User Story:** As a product manager, I want all new catalog and asset strings translated across 6 locales, so that users in each language see a complete localized experience.

#### Acceptance Criteria

1. THE Mobile_App SHALL provide translations for all user-facing strings in the 6 ARB locales: en, hi, ta, te, bn, mr
2. WHEN the user switches language, THEN all catalog-related strings, asset labels, and new feature strings SHALL render in the selected locale
3. THE localized strings SHALL support Devanagari, Tamil, Telugu, and Bengali scripts without text clipping at `textScaleFactor 2.0`

### Requirement 13: Error State and Offline QA

**User Story:** As a QA operator, I want every screen's loading/empty/error/offline states verified on a flaky network, so that no screen shows a raw error or blank state to users.

#### Acceptance Criteria

1. WHEN the network is throttled or disconnected, THEN every data-loading screen SHALL display a designed offline banner or error state (not a raw exception or blank screen)
2. WHEN a screen has no data to display, THEN it SHALL show a designed empty state with a relevant illustration and action CTA
3. WHEN an API request fails, THEN the screen SHALL display a designed error state with a retry action

### Requirement 14: Observability and Monitoring

**User Story:** As a platform operator, I want Sentry error reporting and CloudWatch alarms active, so that production issues are detected before users report them.

#### Acceptance Criteria

1. THE API_Server SHALL report unhandled exceptions and slow transactions (>2s) to Sentry with release tagging
2. THE Sentry configuration SHALL scrub PII (mobile numbers, OTPs) from error breadcrumbs
3. WHEN EC2 CPU exceeds 80% for 5 minutes, THEN a CloudWatch alarm SHALL trigger notification via SNS
4. WHEN RDS free storage falls below 2GB, THEN a CloudWatch alarm SHALL trigger notification via SNS
5. WHEN the Health_Endpoint fails for 3 consecutive checks, THEN an uptime monitor SHALL send an alert
6. THE API_Server SHALL enforce rate limits on auth/OTP/upload endpoints as configured in `.env.production`

### Requirement 15: Legal Compliance Pages

**User Story:** As a product manager, I want Privacy Policy and Terms of Service pages accessible from the app, so that the Play Store listing requirements are met and users can review legal terms.

#### Acceptance Criteria

1. THE Mobile_App Settings screen SHALL contain links to the Privacy Policy and Terms of Service pages
2. THE Privacy Policy SHALL disclose data collection practices, third-party services (Razorpay, 2Factor, Sentry, Gemini), and user rights under Indian data protection regulations
3. THE Terms of Service SHALL define acceptable use, subscription terms, refund policy, and liability limitations
4. THE legal pages SHALL be hosted at publicly accessible URLs referenced in the Play Store listing

### Requirement 16: Razorpay Live Integration

**User Story:** As a platform operator, I want Razorpay configured with LIVE keys and webhook verification, so that real subscription payments are processed securely.

#### Acceptance Criteria

1. WHEN deploying for public launch (P2), THE `.env.production` SHALL contain Razorpay LIVE keys (`rzp_live_*` prefix)
2. THE API_Server webhook endpoint (`/api/v1/payments/webhook`) SHALL verify the `X-Razorpay-Signature` header using the configured webhook secret before processing any payment event
3. IF the webhook signature verification fails, THEN the API_Server SHALL reject the request with HTTP 401 and log the attempt
4. WHEN a subscription payment succeeds, THEN the API_Server SHALL update the tenant's subscription status and entitlements within the same transaction

### Requirement 17: Database Backup and Recovery

**User Story:** As a platform operator, I want automated backups with tested restore capability, so that data loss risk is minimized and recovery procedures are proven.

#### Acceptance Criteria

1. THE RDS_Instance SHALL have automated backups with a retention period of at least 7 days (30 days recommended before public launch)
2. THE RDS_Instance SHALL have point-in-time recovery (PITR) enabled with 5-minute granularity
3. WHEN a monthly restore drill is performed, THEN the restored instance SHALL contain all data from the source and row counts SHALL match
4. WHEN a manual snapshot is taken before a migration, THEN it SHALL be retained for at least 7 days regardless of the automated backup window

### Requirement 18: CloudWatch Alarms and Alerts

**User Story:** As a platform operator, I want CloudWatch alarms on critical infrastructure metrics, so that I am notified immediately when resources approach capacity limits.

#### Acceptance Criteria

1. WHEN EC2 CPU utilization exceeds 80% for 5 consecutive minutes, THEN a CloudWatch alarm SHALL transition to ALARM state and notify via SNS
2. WHEN RDS free storage drops below 2GB, THEN a CloudWatch alarm SHALL transition to ALARM state and notify via SNS
3. WHEN RDS database connections exceed 80% of `max_connections`, THEN a CloudWatch alarm SHALL notify via SNS
4. THE SNS topic SHALL deliver notifications to the configured operations email address

### Requirement 19: Play Store Listing

**User Story:** As a product manager, I want the app listed on Google Play Store with proper metadata, screenshots, and privacy declarations, so that users can discover and install RADHA.

#### Acceptance Criteria

1. THE Play_Console listing SHALL include app title (≤30 chars), short description (≤80 chars), full description (≤4000 chars), and category set to BUSINESS
2. THE listing SHALL include at least 4 phone screenshots (16:9 or 9:16 ratio) showing key app flows
3. THE listing SHALL include a 512×512 app icon and a 1024×500 feature graphic
4. THE listing SHALL link to the hosted Privacy Policy URL
5. WHEN the signed AAB is uploaded to Play_Console, THEN it SHALL pass all Play Store pre-launch checks without errors
6. THE content rating questionnaire SHALL be completed with responses reflecting the app's actual content (no gambling, no user-generated content moderation issues, suitable for all ages)

### Requirement 20: Security Hardening

**User Story:** As a platform operator, I want security best practices enforced at every layer, so that the production system is resilient to common attack vectors.

#### Acceptance Criteria

1. THE Nginx_Proxy SHALL only allow TLS 1.2 and TLS 1.3 protocols (no SSLv3, TLS 1.0, TLS 1.1)
2. THE Docker containers SHALL run as non-root user and SHALL NOT mount the Docker socket
3. THE EC2 instance SHALL have password-based SSH authentication disabled (key-based only)
4. THE API_Server SHALL set security headers via Helmet middleware (X-Frame-Options, X-XSS-Protection, Content-Security-Policy where applicable)
5. WHEN production secrets are generated, THEN they SHALL be at least 64 characters of cryptographic randomness for JWT secrets and at least 16 characters for database passwords
6. THE S3_Bucket SHALL deny any request that does not use HTTPS (enforced via bucket policy condition `aws:SecureTransport`)
