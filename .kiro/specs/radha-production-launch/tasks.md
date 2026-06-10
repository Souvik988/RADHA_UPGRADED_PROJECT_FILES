# Implementation Plan: RADHA Production Launch

## Overview

This plan takes the RADHA platform from "all tests green, feature-complete" to "deployed on AWS, signed for Play Store, and operationally ready." Tasks are organized by launch phase (P0 → P1 → P2) and each references specific requirements. The backend is TypeScript/NestJS; the mobile app is Dart/Flutter. All infrastructure commands target the existing EC2 instance via SSH.

Implementation environment: Windows/PowerShell locally, Ubuntu on EC2 via SSH. Docker builds happen on EC2. Flutter builds happen locally on Windows.

## Tasks

- [ ] 1. Validate and harden the production environment schema
  - [ ] 1.1 Update `server/src/config/env.schema.ts` to enforce production constraints
    - Add Zod refinements: when `NODE_ENV=production`, require `DB_SSL=true`, `JWT_ACCESS_SECRET.length >= 64`, `JWT_REFRESH_SECRET.length >= 64`, `CORS_ORIGINS` must not contain `*`
    - Ensure validation failure logs descriptive errors identifying which variables failed
    - Verify the app refuses to start with a bad config (exit code non-zero)
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [ ]* 1.2 Write property test for environment schema validation
    - **Property 1: Environment validation rejects insecure production configuration**
    - Generate random env objects with: DB_SSL in {false, undefined, 'false'}, JWT secrets of length 0-63, CORS containing '*'
    - Verify all are rejected by the schema with descriptive errors
    - Use fast-check or similar property testing library for TypeScript
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 20.5**

  - [ ] 1.3 Populate `server/.env.production` from the example template
    - Copy `.env.production.example` to `.env.production`
    - Fill all `<PLACEHOLDER>` values with real production credentials
    - Generate JWT secrets: `openssl rand -hex 48` (produces 96 hex chars = 48 bytes)
    - Set `DB_SSL=true`, real RDS endpoint, real ElastiCache endpoint, real 2Factor key, Sentry DSN
    - Set file permissions to 600 on EC2
    - _Requirements: 2.5, 2.6_

- [ ] 2. Fix the TypeScript path alias for production runtime
  - [ ] 2.1 Add `tsc-alias` to the server build pipeline
    - Install `tsc-alias` as a dev dependency: `pnpm add -D tsc-alias` in server/
    - Update `server/package.json` build script: `"build": "nest build && tsc-alias -p tsconfig.build.json"`
    - Remove `-r tsconfig-paths/register` from all docker-compose.prod.yml commands
    - Update Dockerfile CMD to `["node", "dist/main.api.js"]`
    - Update worker/scheduler commands in compose similarly
    - _Requirements: 3.6_

  - [ ] 2.2 Verify the build produces resolvable imports
    - Run `pnpm build` in server/
    - Grep dist/ for any remaining `@/` references that weren't rewritten
    - Run `node dist/main.api.js` locally (with dev env) to confirm boot without module errors
    - _Requirements: 3.6_

- [ ] 3. Checkpoint — Environment and build validation
  - Ensure `pnpm build` completes cleanly in server/
  - Ensure `pnpm test` still passes (2059 tests)
  - Ensure starting the API with `.env.production` values (locally with `DB_SSL=false` override for local) boots without schema errors in dev mode
  - Ask the user if questions arise.

- [ ] 4. AWS infrastructure provisioning (on EC2 via SSH)
  - [ ] 4.1 Provision RDS PostgreSQL instance
    - Create RDS instance: PostgreSQL 16, db.t3.medium, 20GB gp3, storage encryption on, Multi-AZ
    - DB name: `radha`, master user: `radha_app`, enforce TLS via parameter group (`rds.force_ssl=1`)
    - Set automated backups: 7-day retention (upgrade to 30 before public launch)
    - Configure security group: inbound 5432 from EC2 SG only
    - Note the writer endpoint for `.env.production`
    - _Requirements: 1.1, 1.2, 1.6, 17.1, 17.2_

  - [ ] 4.2 Provision ElastiCache Redis cluster
    - Create ElastiCache Redis 7 node: cache.t3.micro, cluster mode off
    - Enable in-transit encryption, set AUTH token
    - Configure security group: inbound 6379 from EC2 SG only
    - Note primary endpoint for `.env.production`
    - _Requirements: 1.3, 1.7_

  - [ ] 4.3 Create S3 bucket and CloudFront distribution
    - Create bucket `radha-prod-media` in ap-south-2, block all public access
    - Enable versioning, set lifecycle rule (IA after 90 days)
    - Add bucket policy denying non-HTTPS (aws:SecureTransport condition)
    - Create CloudFront distribution with OAC to the bucket, TLS 1.2 minimum
    - Set default cache behavior: compress, Cache-Control respect
    - Note the CloudFront domain for `.env.production`
    - _Requirements: 1.4, 1.5, 20.6_

  - [ ] 4.4 Configure EC2 security group and Elastic IP
    - Verify/create security group `radha-ec2-sg`: inbound 22 (admin IP), 80+443 (0.0.0.0/0)
    - Ensure port 3000 is NOT in inbound rules
    - Associate Elastic IP with the EC2 instance
    - Create DNS A record: `api.radha.app` → Elastic IP
    - _Requirements: 1.8_

  - [ ] 4.5 Create IAM instance role for EC2
    - Create IAM role `radha-ec2-role` with trust policy for EC2
    - Attach policy allowing S3 read/write to `radha-prod-media/*`
    - Attach CloudWatch Logs + Metrics put permissions
    - Attach role to the EC2 instance
    - _Requirements: 1.4 (S3 access without static keys)_

- [ ] 5. Docker build and deploy on EC2
  - [ ] 5.1 Transfer project files to EC2
    - SCP the project to EC2 (exclude `node_modules`, `apps/mobile/build`, `.tmp-*`)
    - Place `.env.production` at the correct path with permissions 600
    - _Requirements: 2.5, 3.1_

  - [ ] 5.2 Build and start the Docker compose stack
    - SSH into EC2, install Docker + Compose if not present
    - Run `docker compose -f docker-compose.prod.yml --env-file server/.env.production build`
    - Run `docker compose -f docker-compose.prod.yml --env-file server/.env.production up -d`
    - Verify all 3 containers are running: `docker compose ps`
    - Verify api healthcheck passes: `curl http://127.0.0.1:3000/api/v1/health`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [ ] 5.3 Run database migration and curated seed
    - Take manual RDS snapshot (pre-migration safety)
    - Run: `docker compose exec api pnpm db:migrate`
    - Verify all migrations applied (check `drizzle_migrations` table)
    - Run: `docker compose exec api pnpm db:import:curated`
    - Verify 29 products exist with nutrition data
    - _Requirements: 4.1, 4.2, 4.4_

  - [ ]* 5.4 Write property test for curated import idempotency
    - **Property 2: Curated product import idempotency**
    - Run `pnpm db:import:curated` twice in sequence
    - Verify product count = 29 after each run (no duplicates)
    - **Validates: Requirement 4.2**

- [ ] 6. Configure nginx + Let's Encrypt TLS
  - [ ] 6.1 Install and configure nginx on EC2
    - Install nginx and certbot packages
    - Copy `deploy/nginx/radha-api.conf` to `/etc/nginx/sites-available/`
    - Replace `api.YOURDOMAIN.com` with `api.radha.app` (or actual domain)
    - Symlink to sites-enabled, remove default site
    - Test config: `nginx -t`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.6_

  - [ ] 6.2 Obtain Let's Encrypt certificate
    - Run certbot: `sudo certbot --nginx -d api.radha.app --agree-tos -m ops@radha.app --redirect`
    - Verify HTTPS works: `curl -I https://api.radha.app/api/v1/health`
    - Verify HTTP→HTTPS redirect: `curl -I http://api.radha.app/` → 301
    - Verify HSTS header present in response
    - Verify certbot timer active for auto-renewal
    - _Requirements: 5.1, 5.2, 5.5_

- [ ] 7. Checkpoint — Backend deployment verification
  - `curl https://api.radha.app/api/v1/health` → 200, `{"status":"ok"}`
  - `curl https://api.radha.app/api/v1/health/ready` → 200, db + redis connected
  - Verify security headers present (HSTS, X-Content-Type-Options)
  - Verify port 3000 not reachable from outside: `curl http://<elastic-ip>:3000` → timeout
  - Ensure all tests still pass locally (no regressions from build changes)
  - Ask the user if questions arise.

- [ ] 8. Release signing and production mobile build
  - [ ] 8.1 Generate upload keystore
    - Run keytool to generate `radha-upload.jks` (RSA 2048, 25-year validity, alias `radha-upload`)
    - Create `apps/mobile/android/key.properties` with storeFile, storePassword, keyAlias, keyPassword
    - Add `key.properties` and `*.jks` to `.gitignore`
    - Back up keystore + passwords to secure location
    - _Requirements: 7.1, 7.3, 7.6_

  - [ ] 8.2 Configure release signing in build.gradle.kts
    - Update `apps/mobile/android/app/build.gradle.kts`:
      - Add `signingConfigs.create("release")` reading from `key.properties`
      - Change `buildTypes.release.signingConfig` from debug to release
    - Verify: `flutter build apk --release` completes without signing errors
    - _Requirements: 7.2, 7.4_

  - [ ] 8.3 Build signed release APK and AAB pointing at production API
    - Build APK: `flutter build apk --release --split-per-abi --dart-define=API_BASE_URL=https://api.radha.app/`
    - Build AAB: `flutter build appbundle --release --dart-define=API_BASE_URL=https://api.radha.app/`
    - Verify signature: `jarsigner -verify -verbose build/app/outputs/bundle/release/app-release.aab`
    - Verify APK size < 50MB per ABI
    - _Requirements: 6.1, 7.4, 7.5_

- [ ] 9. On-device smoke test (P0 gate)
  - [ ] 9.1 Install and verify critical path on physical device
    - Install the signed release APK on a physical Android device
    - Test: OTP login → receive real SMS → verify → land on Home
    - Test: Home → Browse Category → Product Detail (real nutrition data from production DB)
    - Test: Scan barcode → product lookup from production API
    - Test: Initiate Razorpay payment (test mode keys for P0)
    - Test: Disable network → create expiry record → enable network → verify sync
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 10. Checkpoint — P0 complete
  - All P0 items verified: infra up, backend deployed, TLS active, signed build on device, critical path works
  - Ask the user if questions arise before proceeding to P1.

- [ ] 11. Performance profiling and optimization (P1)
  - [ ] 11.1 Profile and fix cold start performance
    - Run `flutter run --profile` on physical device with DevTools attached
    - Measure cold start time (tap → interactive Home)
    - If >1.5s: identify bottleneck (splash logic, provider initialization, network calls)
    - Optimize: defer non-critical providers, parallelize splash checks, minimize splash work
    - _Requirements: 9.1, 9.2_

  - [ ] 11.2 Profile and fix scroll performance
    - Attach DevTools, scroll Home and Browse screens
    - Verify 60fps with zero jank frames in the UI thread timeline
    - If jank detected: profile widget rebuilds, optimize with const constructors, RepaintBoundary
    - _Requirements: 9.1_

  - [ ] 11.3 Add image prefetch on Home and Browse screens
    - Call `precacheImage` for the first visible row of product images in `initState` or `build`
    - Verify images appear without pop-in on first render after prefetch
    - _Requirements: 9.3_

- [ ] 12. CDN product image hosting
  - [ ] 12.1 Upload product images to S3 and update database URLs
    - Set `AWS_S3_BUCKET` and `AWS_CLOUDFRONT_DOMAIN` in `.env.production`
    - Run: `docker compose exec api pnpm db:host:images`
    - Verify 29 objects exist in S3 bucket
    - Verify `products.image_url` in DB points to CloudFront URLs
    - Verify images accessible via CloudFront: `curl -I https://<dist>.cloudfront.net/products/<ean>.webp`
    - Verify Cache-Control header: `public, max-age=86400`
    - _Requirements: 10.1, 10.2, 10.4_

  - [ ] 12.2 Implement CDN fallback in mobile app
    - Verify `CachedNetworkImage` in product widgets has `errorWidget` pointing to bundled asset
    - Test by temporarily pointing an image_url to a non-existent path → fallback renders
    - _Requirements: 10.3_

  - [ ]* 12.3 Write property test for CDN fallback resilience
    - **Property 3: CDN image fallback resilience**
    - Mock CachedNetworkImage to return errors for randomly selected products
    - Verify fallback asset renders in all cases without exceptions
    - **Validates: Requirement 10.3**

- [ ] 13. Complete remaining asset illustrations
  - [ ] 13.1 Create offline-state, additive-badge, and allergen-badge illustrations
    - Design and add `assets/illustrations/offline_state.svg` (or PNG)
    - Design and add `assets/illustrations/additive_badge.svg`
    - Design and add `assets/illustrations/allergen_badge.svg`
    - Wire into the corresponding widgets (connectivity banner, product detail badges)
    - Verify assets render correctly in the app
    - _Requirements: 11.1, 11.2, 11.3_

- [ ] 14. Localization pass
  - [ ] 14.1 Translate new catalog/asset strings across 6 ARB locales
    - Identify all new/untranslated keys in `app_en.arb`
    - Add translations to `app_hi.arb`, `app_ta.arb`, `app_te.arb`, `app_bn.arb`, `app_mr.arb`
    - Run `flutter gen-l10n` to regenerate localization delegates
    - Verify no missing key warnings during build
    - _Requirements: 12.1, 12.2_

  - [ ]* 14.2 Write property test for ARB locale key completeness
    - **Property 4: ARB locale key completeness**
    - Parse `app_en.arb`, extract all keys
    - For each of the 5 other locale ARB files, verify every English key exists with non-empty value
    - **Validates: Requirement 12.1**

  - [ ] 14.3 Verify Indic script rendering at textScaleFactor 2.0
    - Run widget tests with `MediaQuery` textScaleFactor set to 2.0
    - Verify no `RenderFlex overflow` or `TextOverflow` exceptions in Devanagari/Tamil/Telugu/Bengali
    - Fix any overflow issues with flexible layouts or text truncation
    - _Requirements: 12.3_

- [ ] 15. Error state and offline QA sweep
  - [ ] 15.1 Verify loading/empty/error/offline states on every data screen
    - For each data-loading screen: simulate no-network (mock connectivity_plus), verify offline banner/state renders
    - For each screen: provide empty API response, verify empty state widget renders
    - For each screen: simulate API error (500), verify error state with retry renders
    - Fix any screens showing raw errors, blank content, or unhandled exceptions
    - _Requirements: 13.1, 13.2, 13.3_

  - [ ]* 15.2 Write property tests for screen state handling
    - **Property 5: Offline state graceful degradation**
    - **Property 6: Empty state presentation**
    - **Property 7: Error state with retry action**
    - For a representative set of data screens, parameterize tests with different failure modes
    - Verify correct state widget renders in each case
    - **Validates: Requirements 13.1, 13.2, 13.3**

- [ ] 16. Observability setup
  - [ ] 16.1 Configure Sentry for production
    - Set `SENTRY_DSN` in `.env.production` with a live Sentry project DSN
    - Verify Sentry SDK initializes: `@sentry/node` captures a test exception
    - Configure release tagging: version from `package.json`
    - Configure PII scrubbing: add mobile/otp/password to `beforeSend` scrub list
    - Verify: trigger a test error, confirm it appears in Sentry dashboard with scrubbed PII
    - _Requirements: 14.1, 14.2_

  - [ ] 16.2 Set up CloudWatch alarms
    - Create alarm: EC2 CPUUtilization > 80% for 5 min → SNS notification
    - Create alarm: RDS FreeStorageSpace < 2GB → SNS notification
    - Create alarm: RDS DatabaseConnections > 80% of max → SNS notification
    - Create SNS topic with ops email subscription, confirm subscription
    - _Requirements: 14.3, 14.4, 18.1, 18.2, 18.3, 18.4_

  - [ ] 16.3 Verify rate limiting on auth/OTP endpoints
    - Confirm rate limit config in `.env.production` (RATE_LIMIT_WINDOW_MS, RATE_LIMIT_MAX)
    - Test: send RATE_LIMIT_MAX+1 requests to `/auth/otp/request` within window
    - Verify the excess request gets HTTP 429
    - _Requirements: 14.6_

  - [ ]* 16.4 Write property test for rate limiting enforcement
    - **Property 8: Rate limiting enforcement**
    - Generate random burst sizes exceeding the limit, verify 429 responses
    - **Validates: Requirement 14.6**

- [ ] 17. Checkpoint — P1 complete
  - Cold start <1.5s verified
  - 60fps scroll verified
  - CDN images loading, fallback working
  - All illustrations present
  - Localization complete across 6 locales
  - All screens handle offline/empty/error gracefully
  - Sentry receiving errors, CloudWatch alarms active
  - Rate limits enforced
  - Ask the user if questions arise before proceeding to P2.

- [ ] 18. Legal compliance pages (P2)
  - [ ] 18.1 Create and host Privacy Policy and Terms of Service
    - Write Privacy Policy covering: data collection, third-party services (Razorpay, 2Factor, Sentry, Gemini), user rights, Indian data protection compliance
    - Write Terms of Service covering: acceptable use, subscription terms, refund policy, liability
    - Host both at publicly accessible URLs (e.g., on the marketing site or a static page)
    - _Requirements: 15.2, 15.3, 15.4_

  - [ ] 18.2 Link legal pages from the mobile app Settings screen
    - Add "Privacy Policy" and "Terms of Service" tap targets in the Settings screen
    - Open URLs in an in-app browser or external browser
    - Verify links are accessible and render correctly
    - _Requirements: 15.1_

- [ ] 19. Razorpay live integration
  - [ ] 19.1 Switch to Razorpay LIVE keys and configure webhook
    - Update `.env.production`: set `RAZORPAY_KEY_ID` to `rzp_live_*` key, set live secret
    - Configure webhook URL in Razorpay dashboard: `https://api.radha.app/api/v1/payments/webhook`
    - Set webhook secret in `.env.production` as `RAZORPAY_WEBHOOK_SECRET`
    - Verify webhook endpoint validates `X-Razorpay-Signature` header
    - _Requirements: 16.1, 16.2_

  - [ ]* 19.2 Write property test for webhook signature verification
    - **Property 9: Razorpay webhook signature verification**
    - Generate random payloads with invalid/missing/tampered signatures
    - Verify all are rejected with 401 and no DB modifications occur
    - **Validates: Requirements 16.2, 16.3**

  - [ ] 19.3 Test live payment end-to-end
    - Initiate a real subscription payment on the app (₹49 plan)
    - Verify Razorpay processes the payment
    - Verify webhook fires and subscription status updates in DB
    - Verify the user's entitlements unlock correctly
    - _Requirements: 16.4_

- [ ] 20. Database backup verification and CloudWatch operational readiness
  - [ ] 20.1 Verify RDS backup configuration
    - Confirm automated backups enabled with configured retention (7-30 days)
    - Confirm PITR shows LatestRestorableTime within 5 minutes of now
    - _Requirements: 17.1, 17.2_

  - [ ] 20.2 Perform restore drill
    - Take manual snapshot
    - Restore to a temporary instance (`radha-drill-<date>`)
    - Connect and compare row counts with production
    - Delete temporary instance after verification
    - Document results
    - _Requirements: 17.3, 17.4_

- [ ] 21. Play Store listing preparation
  - [ ] 21.1 Prepare store listing assets
    - Create/finalize 512×512 app icon PNG
    - Create 1024×500 feature graphic PNG
    - Capture at least 4 phone screenshots showing key flows (OTP, Home, Scan, Product Detail)
    - Write listing copy: title (≤30 chars), short description (≤80 chars), full description (≤4000 chars)
    - _Requirements: 19.1, 19.2, 19.3_

  - [ ] 21.2 Upload signed AAB to Play Console
    - Create the app in Play Console with package name `com.radha.radha_mobile`
    - Upload the signed AAB from task 8.3
    - Fill in content rating questionnaire (category: BUSINESS, suitable for all ages)
    - Link Privacy Policy URL in the store listing
    - Set default language to `en-IN`
    - Submit for review
    - _Requirements: 19.4, 19.5, 19.6_

- [ ] 22. Security hardening verification
  - [ ] 22.1 Verify security posture across all layers
    - Verify nginx: TLS 1.2+ only (test with `openssl s_client -tls1_1` → should fail)
    - Verify Docker: containers run as non-root (`docker exec api whoami` → `node`)
    - Verify EC2: password SSH disabled (`PasswordAuthentication no` in sshd_config)
    - Verify Helmet headers in API responses (X-Frame-Options, etc.)
    - Verify S3 bucket policy denies HTTP (aws:SecureTransport condition)
    - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.6_

- [ ] 23. Final checkpoint — P2 complete, production launch ready
  - All P0 + P1 + P2 items verified
  - Backend deployed and healthy on AWS
  - TLS active, security headers present
  - Signed AAB uploaded to Play Console
  - Legal pages linked and accessible
  - Razorpay live payments working
  - Backups verified with restore drill
  - CloudWatch alarms active
  - Sentry capturing errors
  - Rate limits enforced
  - All app states (offline/empty/error) handled gracefully
  - Performance targets met (60fps, <1.5s cold start)
  - Ask the user if questions arise.

## Task Dependency Graph

```json
{
  "waves": [
    {
      "name": "P0 Wave 1: Foundation",
      "tasks": ["1.1", "1.2", "1.3"]
    },
    {
      "name": "P0 Wave 2: Build Fix",
      "tasks": ["2.1", "2.2"],
      "dependsOn": ["1.1"]
    },
    {
      "name": "P0 Wave 3: Checkpoint",
      "tasks": ["3"],
      "dependsOn": ["1.1", "1.3", "2.1", "2.2"]
    },
    {
      "name": "P0 Wave 4: AWS Infra",
      "tasks": ["4.1", "4.2", "4.3", "4.4", "4.5"],
      "dependsOn": ["3"]
    },
    {
      "name": "P0 Wave 5: Deploy",
      "tasks": ["5.1", "5.2", "5.3", "5.4"],
      "dependsOn": ["4.1", "4.2", "4.3", "4.4", "4.5"]
    },
    {
      "name": "P0 Wave 6: TLS",
      "tasks": ["6.1", "6.2"],
      "dependsOn": ["5.2"]
    },
    {
      "name": "P0 Wave 7: Backend Checkpoint",
      "tasks": ["7"],
      "dependsOn": ["6.1", "6.2"]
    },
    {
      "name": "P0 Wave 8: Release Signing",
      "tasks": ["8.1", "8.2", "8.3"],
      "dependsOn": ["7"]
    },
    {
      "name": "P0 Wave 9: Smoke Test",
      "tasks": ["9.1"],
      "dependsOn": ["8.3"]
    },
    {
      "name": "P0 Wave 10: P0 Checkpoint",
      "tasks": ["10"],
      "dependsOn": ["9.1"]
    },
    {
      "name": "P1 Wave 1: Performance and CDN",
      "tasks": ["11.1", "11.2", "11.3", "12.1", "12.2", "12.3", "13.1"],
      "dependsOn": ["10"]
    },
    {
      "name": "P1 Wave 2: Localization and QA",
      "tasks": ["14.1", "14.2", "14.3", "15.1", "15.2"],
      "dependsOn": ["13.1"]
    },
    {
      "name": "P1 Wave 3: Observability",
      "tasks": ["16.1", "16.2", "16.3", "16.4"],
      "dependsOn": ["10"]
    },
    {
      "name": "P1 Wave 4: P1 Checkpoint",
      "tasks": ["17"],
      "dependsOn": ["11.1", "11.2", "11.3", "12.1", "14.1", "14.3", "15.1", "16.1", "16.2", "16.3"]
    },
    {
      "name": "P2 Wave 1: Legal and Payments",
      "tasks": ["18.1", "18.2", "19.1", "19.2", "19.3"],
      "dependsOn": ["17"]
    },
    {
      "name": "P2 Wave 2: Backups and Store",
      "tasks": ["20.1", "20.2", "21.1", "21.2"],
      "dependsOn": ["17"]
    },
    {
      "name": "P2 Wave 3: Security and Final",
      "tasks": ["22.1", "23"],
      "dependsOn": ["18.1", "19.1", "20.1", "21.2"]
    }
  ]
}
```

## Notes

- Tasks marked with `*` are optional property-based tests that can be skipped for faster launch
- P0 tasks (1-10) are production blockers — nothing ships without them
- P1 tasks (11-17) make the app feel premium — required before beta testers
- P2 tasks (18-23) are required for public Play Store listing
- All SSH operations target: `ssh -i Radha.pem ubuntu@ec2-18-60-109-5.ap-south-2.compute.amazonaws.com`
- Existing documentation: `DEPLOY_AWS.md` is the authoritative runbook for EC2 operations
