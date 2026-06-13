# Requirements Document

## Introduction

This feature makes the RADHA web dashboard (`radha_dashboard/`, Next.js App Router) production-ready
for a demo to a Gujarat retail client. It is an improvement effort, not a new-feature effort: no new
product capabilities are added beyond what is needed to make existing screens reliable, fast, secure,
data-complete, and visually polished.

The work spans seven concerns the user raised:

1. **Demo data completeness** — every dashboard feature (overview, analytics, audit, expiry, GRN,
   inventory, tasks, billing, suppliers, reports, notifications, settings, admin) must render fully
   populated, clearly-labelled demo data when demo mode is active, so the dashboard is demoable
   without a live backend.
2. **Real data on scan** — when a QR/EAN barcode is scanned, the dashboard must display the matching
   product's data and the scan time/details, rendering real backend data wherever it is available.
3. **Product images** — products must show real images sourced from a free product-image API
   (Open Food Facts, already integrated by the backend), with a graceful placeholder fallback.
4. **Navigation performance** — moving between dashboard pages must be fast (current 4–5 s per page
   is unacceptable).
5. **Auth/session reliability and security** — spurious redirects to the login page must stop, and the
   session/routing/security system must be hardened.
6. **UI/visual quality** — the dashboard must meet a polished, production-quality visual bar consistent
   with the workspace Visual System Bible (`.kiro/steering/visual-assets.md`) where it applies to the web.
7. **Production readiness** — the combined result must be reliable, fast, secure, and visually polished.

Two cross-cutting constraints from steering govern all of the above:

- **Honest-data discipline.** The dashboard renders only what the backend returns. Demo data is a
  clearly separated, explicitly-toggled mode — never fabricated into a real backend response and never
  presented as live data.
- **Multi-tenancy.** All data access is scoped by `tenant_id` (and `store_id` where applicable); demo
  data and real data alike must respect the active store scope.

## Glossary

- **Dashboard**: The RADHA Next.js web application under `radha_dashboard/`.
- **Feature_Area**: One of the dashboard's functional sections — Overview, Analytics, Audit/EAN, Expiry,
  GRN, Inventory, Tasks, Billing, Suppliers, Reports, Notifications, Settings, Admin.
- **Demo_Mode**: The operating mode, gated by the `DEMO_MODE` environment flag, in which the Dashboard
  serves demo data without requiring the live backend.
- **Demo_Data_Provider**: The centralized module under `radha_dashboard/lib/demo/` that supplies
  scoped demo datasets for every Feature_Area.
- **Demo_Indicator**: A persistent visible UI element that tells the user the Dashboard is showing demo
  (sample) data rather than live data.
- **API_Proxy**: A Next.js route handler under `radha_dashboard/app/api/*` that the client calls; it
  attaches the server-side Bearer token and forwards to the backend or returns Demo_Mode data.
- **Backend**: The NestJS API at `radha_backend/`, reached via `NEXT_PUBLIC_API_BASE_URL`.
- **Scan_Event**: A QR or EAN barcode value submitted to the Dashboard for lookup.
- **Scan_Result_View**: The Dashboard surface that displays product data and scan time/details for a
  Scan_Event.
- **Product_Image_Service**: The Dashboard module that resolves a product image URL (via the Backend's
  Open Food Facts integration) and supplies a placeholder when no image is available.
- **Placeholder_Image**: The branded fallback visual shown when no real product image can be resolved.
- **Navigation_System**: The Dashboard's routing and page-rendering pipeline (App Router segments,
  server/client components, data prefetch).
- **Auth_Gateway**: The combination of `middleware.ts` and the server-side session checks in the
  `(dash)` layout that gate access to authenticated routes.
- **Session_Manager**: The server-only session module (`lib/auth/session.ts`) and the
  `/api/auth/{login,me,refresh,logout}` route handlers that manage the session cookie and tokens.
- **Session_Cookie**: The httpOnly, SameSite cookie holding the session payload (tokens + minimal user
  identity).
- **Store_Scope**: The currently selected `store_id` (or the owner's "all stores" rollup) that scopes
  all displayed data.
- **UI_System**: The shared design tokens, components, and visual rules the Dashboard renders with.
- **Visual_Bible**: The workspace Visual System rules in `.kiro/steering/visual-assets.md`.

## Requirements

### Requirement 1: Demo data coverage across all feature areas

**User Story:** As a sales presenter demoing RADHA without a live backend, I want every dashboard
feature to show fully populated sample data, so that the dashboard looks complete and credible.

#### Acceptance Criteria

1. WHILE Demo_Mode is active, THE Demo_Data_Provider SHALL supply, for each Feature_Area (Overview,
   Analytics, Audit/EAN, Expiry, GRN, Inventory, Tasks, Billing, Suppliers, Reports, Notifications,
   Settings, and Admin), a dataset containing at least one record for every primary data region the page
   renders and at least 5 records for each list or table region.
2. WHILE Demo_Mode is active, WHEN a user opens any Feature_Area page, THE Dashboard SHALL render every
   primary data region on that page (KPI tiles, lists, tables, and charts) populated from the
   Demo_Data_Provider within 2 seconds (2000 ms) of page load, with zero empty-state placeholders shown
   for any region that has available demo data.
3. THE Demo_Data_Provider SHALL define each Feature_Area's demo dataset in a centralized location under
   `radha_dashboard/lib/demo/`, with exactly one dataset definition per Feature_Area.
4. WHILE Demo_Mode is active, THE Demo_Data_Provider SHALL return only demo records whose `tenantId` and
   `storeId` match the active Store_Scope, and SHALL exclude all records whose `tenantId` or `storeId`
   differ from the active Store_Scope.
5. WHEN the active Store_Scope changes WHILE Demo_Mode is active, THE Dashboard SHALL update each
   Feature_Area's displayed demo data to match the newly selected Store_Scope within 2 seconds (2000 ms)
   of the change.
6. WHERE a Feature_Area exposes demo data through an API_Proxy, THE API_Proxy SHALL source that data
   from the Demo_Data_Provider rather than from values defined inline in the route handler.
7. IF a Feature_Area page is opened WHILE Demo_Mode is active and the Demo_Data_Provider has no demo
   dataset defined for that Feature_Area, THEN THE Dashboard SHALL render a designed empty-state for each
   affected region and SHALL log an indication that the Feature_Area's demo dataset is missing, without
   crashing or leaving any region blank.

### Requirement 2: Demo data is clearly labelled and isolated from real data

**User Story:** As a stakeholder reviewing the dashboard, I want demo data to be unmistakably marked as
sample data, so that demo content is never mistaken for live business data.

#### Acceptance Criteria

1. WHILE Demo_Mode is active, THE Dashboard SHALL display a persistent Demo_Indicator on every
   authenticated page that remains continuously visible while the page is scrolled and after navigation
   between authenticated pages, and that contains text identifying the displayed content as sample/demo
   data.
2. WHILE Demo_Mode is inactive, THE Dashboard SHALL NOT display any Demo_Indicator on any authenticated
   page.
3. WHEN Demo_Mode is activated or deactivated, THE Dashboard SHALL add or remove the Demo_Indicator on
   the currently displayed authenticated page within 1 second without requiring a manual page reload.
4. IF Demo_Mode is inactive, THEN THE API_Proxy SHALL NOT return any value originating from the
   Demo_Data_Provider.
5. IF Demo_Mode is inactive AND a resolved response would include any value originating from the
   Demo_Data_Provider, THEN THE API_Proxy SHALL exclude that value from the response and return only
   Backend-originated data.
6. WHILE Demo_Mode is inactive AND the Backend returns no data for a Feature_Area, THE Dashboard SHALL
   render that Feature_Area's designed empty state rather than demo data.
7. THE Demo_Data_Provider SHALL be importable only by server-side API_Proxy code and SHALL NOT be
   bundled into client components.

### Requirement 3: Real data display on scan

**User Story:** As a store auditor, I want a scanned QR/EAN barcode to immediately show the matching
product and the scan time, so that I can verify products against the approved list at the shelf.

#### Acceptance Criteria

1. WHEN a Scan_Event is submitted, THE Dashboard SHALL initiate the matching-product request from the
   Backend through an API_Proxy scoped to the active Store_Scope within 500 milliseconds of the
   Scan_Event.
2. WHEN the Backend returns a product record for a Scan_Event within 5 seconds of request initiation,
   THE Scan_Result_View SHALL display the product's name and EAN.
3. WHEN the Backend returns a product record for a Scan_Event, THE Scan_Result_View SHALL display a
   verification status whose value is exactly one of "matched", "not in list", or "invalid".
4. WHEN the Backend returns a product record for a Scan_Event, THE Scan_Result_View SHALL display the
   scan timestamp expressed in the active Store_Scope local time zone and the exact scanned barcode
   value.
5. IF the Backend returns no matching product for a Scan_Event within the 5 second response window, THEN
   THE Scan_Result_View SHALL display a "not in list" result that retains and shows the exact scanned
   barcode value and the scan timestamp expressed in the active Store_Scope local time zone.
6. WHILE a Scan_Event request is pending and before a response is received, THE Scan_Result_View SHALL
   display a loading state and SHALL NOT display any product record or verification status from a
   previously completed Scan_Event.
7. IF a Scan_Event request fails due to a request timeout exceeding the 5 second response window or a
   transport error, THEN THE Scan_Result_View SHALL display an error indication that communicates the
   failure, SHALL retain and show the exact scanned barcode value, and SHALL present a retry action that
   re-submits the Scan_Event.
8. WHERE a product field is returned by the Backend as an identifier or token rather than a
   human-readable value, THE Scan_Result_View SHALL display the returned value or a designed placeholder
   and SHALL NOT fabricate a substitute value.
9. WHILE Demo_Mode is active, WHEN a Scan_Event is submitted, THE Scan_Result_View SHALL display a demo
   product record and scan timestamp from the Demo_Data_Provider within 1 second of the Scan_Event.

### Requirement 4: Product image resolution with fallback

**User Story:** As a viewer of product lists and scan results, I want products to show real images, so
that the dashboard looks merchandised and recognizable.

#### Acceptance Criteria

1. WHEN the Dashboard renders a product that has a non-empty associated image URL from the Backend, THE
   Product_Image_Service SHALL display that image in the product cell.
2. WHEN the Dashboard renders a product that has no Backend image URL and has a non-empty EAN, THE
   Product_Image_Service SHALL request a product image via the Backend's Open Food Facts integration
   using the product's EAN, with a request timeout of 5 seconds.
3. IF the Open Food Facts image request does not return a usable image within the 5-second timeout, THEN
   THE Product_Image_Service SHALL stop waiting and display the Placeholder_Image while preserving the
   product's other displayed data.
4. IF a product has no Backend image URL and no non-empty EAN, THEN THE Product_Image_Service SHALL
   display the Placeholder_Image without issuing an Open Food Facts request.
5. IF no product image can be resolved for a product after all resolution paths are exhausted, THEN THE
   Product_Image_Service SHALL display the Placeholder_Image.
6. IF a resolved image request fails to load, THEN THE Product_Image_Service SHALL display the
   Placeholder_Image and SHALL provide a non-text visual indication that the image could not be loaded.
7. WHILE a product image is being resolved or loaded, THE Product_Image_Service SHALL display the
   Placeholder_Image or skeleton backer occupying the cell's fixed dimensions.
8. THE Dashboard configuration SHALL permit loading product images from the Open Food Facts image host.
9. WHEN the Product_Image_Service displays a product image or the Placeholder_Image, THE Dashboard SHALL
   render it within the cell's fixed width and height such that the cell's outer dimensions remain
   unchanged before, during, and after the image loads (zero layout shift).

### Requirement 5: Navigation performance

**User Story:** As a daily dashboard user, I want pages to open quickly, so that I am not blocked by
multi-second waits when moving between sections.

#### Acceptance Criteria

1. WHEN a user navigates between two authenticated pages on a warm session (a session in which the
   application shell is already loaded and the user authenticated within the prior 30 minutes), THE
   Navigation_System SHALL render the destination page's header and persistent layout shell within 1
   second for at least 95% of such navigations.
2. WHEN a user navigates to a Feature_Area page with data regions that are not yet loaded, THE
   Navigation_System SHALL display a loading skeleton placeholder for each not-yet-loaded data region
   within 1 second of navigation start rather than a blank page.
3. WHEN a Feature_Area page's primary data has loaded on a warm session, THE Navigation_System SHALL
   render that data within 2.5 seconds of navigation start for at least 95% of such navigations.
4. WHILE a page's data is loading, THE Dashboard SHALL keep the persistent navigation shell (sidebar and
   top bar) responsive to user input, beginning the next requested navigation within 1 second of the
   user's tap.
5. WHEN a user revisits a Feature_Area page whose data was loaded earlier in the current session, THE
   Navigation_System SHALL display the previously loaded data within 500 milliseconds of navigation start
   while revalidating that data in the background.
6. IF a Feature_Area page's primary data fails to load within 10 seconds of navigation start, THEN THE
   Navigation_System SHALL replace the loading skeletons with an error state indicating the data could
   not be loaded and provide a retry action, while preserving the persistent navigation shell.
7. WHEN background revalidation of a revisited Feature_Area page completes with data that differs from
   the displayed data, THE Navigation_System SHALL update the displayed data within 1 second of
   revalidation completion.

### Requirement 6: Authentication and session reliability

**User Story:** As an authenticated user, I want to stay logged in while my session is valid, so that I
am not unexpectedly bounced to the login page during normal use.

#### Acceptance Criteria

1. WHILE a valid Session_Cookie is present, where a valid Session_Cookie is one that has not expired and
   parses successfully, WHEN a user navigates between authenticated pages, THE Auth_Gateway SHALL
   complete the authorization check within 500 milliseconds and allow access without redirecting to the
   login page.
2. IF a request to `/api/auth/me` fails due to a transient Backend or network error, where such an error
   is an HTTP 502, 503, or 504 response, a request timeout, or no network response received, WHILE the
   Session_Cookie is still valid, THEN THE Session_Manager SHALL NOT clear the Session_Cookie and THE
   Dashboard SHALL NOT redirect to the login page.
3. IF a request to `/api/auth/me` fails due to a transient Backend or network error, where such an error
   is an HTTP 502, 503, or 504 response, a request timeout, or no network response received, THEN THE
   Session_Manager SHALL retry the request up to 3 times using exponential backoff starting at 1 second
   and capped at 8 seconds between attempts, and IF all retries are exhausted, THEN THE Session_Manager
   SHALL surface a non-fatal error indication to the user while retaining the Session_Cookie.
4. WHEN an access token is within 60 seconds of expiry, THE Session_Manager SHALL refresh the token
   using the refresh token before the next authenticated Backend request and SHALL complete the refresh
   within 5 seconds.
5. IF a token refresh fails because the refresh token is invalid or expired, THEN THE Session_Manager
   SHALL clear the Session_Cookie, preserving no other client-side session state, and THE Dashboard SHALL
   display a session-ended indication and redirect to the login page within 1 second with the original
   path preserved in the `next` parameter.
6. WHEN 2 or more concurrent authenticated requests each encounter an expired access token, THE
   Session_Manager SHALL perform at most one token refresh and SHALL apply the refreshed token to all
   pending requests.
7. IF the Session_Cookie value cannot be parsed, THEN THE Auth_Gateway SHALL treat the request as
   unauthenticated and redirect to the login page within 1 second with the original path preserved in
   the `next` parameter.

### Requirement 7: Routing and redirect security

**User Story:** As a security reviewer, I want the routing guards to be safe and predictable, so that the
dashboard cannot be used for open redirects or unauthorized access.

#### Acceptance Criteria

1. WHEN the Auth_Gateway redirects an unauthenticated user to the login page, THE Auth_Gateway SHALL set
   the `next` parameter only to a same-origin relative path, where a same-origin relative path begins
   with a single `/`, does not begin with `//` or `/\`, contains no scheme or authority component, and is
   at most 2048 characters long.
2. WHEN a user is redirected after login using the `next` parameter, THE Dashboard SHALL navigate to the
   `next` value only if it is a same-origin relative path as defined in criterion 1.
3. IF the `next` parameter is absent or fails the same-origin relative path validation, THEN THE
   Dashboard SHALL navigate to the default home route and SHALL discard the supplied `next` value.
4. WHILE an authenticated user lacks the role required for an admin route, WHEN the user requests that
   route, THE Auth_Gateway SHALL redirect to the `/403` page and SHALL render no admin route data before
   the redirect.
5. WHEN any `(dash)` route request is received, THE `(dash)` server layout SHALL re-verify the session
   server-side before rendering any Feature_Area data, independent of the `middleware.ts` presence check.
6. IF the server-side session re-verification fails, THEN THE Dashboard SHALL render no Feature_Area data
   and SHALL redirect to the login page with a validated same-origin relative `next` parameter.
7. THE Session_Cookie SHALL be set with the `httpOnly` attribute and a `SameSite` attribute value of
   `Lax` or `Strict`, and SHALL be set with the `Secure` attribute when the Dashboard runs in production.
8. THE Dashboard SHALL NOT expose any access token or refresh token to client JavaScript, `localStorage`,
   the URL, or log output.

### Requirement 8: Multi-tenant and store scoping integrity

**User Story:** As a multi-store operator, I want every screen to show data only for the store I have
selected, so that store data never leaks across the tenant.

#### Acceptance Criteria

1. WHEN the Dashboard requests Feature_Area data, THE API_Proxy SHALL forward both the active
   Store_Scope identifier and the session tenant identifier to the Backend.
2. WHILE no specific store is selected and the session role is owner or admin, THE Dashboard SHALL
   display the multi-store rollup view for the active tenant.
3. WHEN no specific store is selected and the session role is owner or admin, THE API_Proxy SHALL forward
   the tenant-rollup scope together with the session tenant identifier to the Backend.
4. THE Dashboard SHALL display data only for the tenant associated with the current session.
5. WHILE the session role is neither owner nor admin, THE Dashboard SHALL restrict the selectable
   Store_Scope to the stores assigned to the session and SHALL display data only for those assigned
   stores.
6. IF a Backend response contains one or more records whose tenant identifier or store identifier does
   not match the active scope, THEN THE Dashboard SHALL discard the entire response, render none of its
   records, and display an error indication that data could not be shown.
7. WHEN the Store_Scope changes, THE Dashboard SHALL refetch the visible Feature_Area data for the newly
   selected Store_Scope within 2 seconds and SHALL discard any stale in-flight responses associated with
   a previous Store_Scope.
8. WHILE a refetch triggered by a Store_Scope change is in progress, THE Dashboard SHALL display a
   loading state and SHALL NOT display Feature_Area data from the previous Store_Scope.

### Requirement 9: Visual quality and design consistency

**User Story:** As a client evaluating RADHA, I want the dashboard to look polished and on-brand, so that
it feels like a premium, finished product.

#### Acceptance Criteria

1. THE UI_System SHALL render every color, typography, spacing, and radius value in feature components by
   reading the Dashboard's design tokens, with zero hard-coded color, spacing, radius, or duration
   literals present in feature component code.
2. WHEN the Dashboard renders any authenticated page, THE Dashboard SHALL apply the Visual_Bible brand
   foundations to that page: the warm cream canvas `#FFFBF5` (never a pure white `#FFFFFF` canvas), the
   ink color `#1C1917` for primary text (never pure black `#000000`), the Plus Jakarta Sans typeface for
   text, and the JetBrains Mono typeface for all numeric values including KPIs, prices, dates, EANs, IDs,
   and timers.
3. WHERE a Feature_Area page contains a page region, defined as the header band, a spacing-separated
   content zone, or a floating-or-pinned action bar, THE Dashboard SHALL render at most one primary
   call-to-action styled in the brand orange accent `#EA580C` within that region.
4. WHEN a Feature_Area page region has no data to display, THE Dashboard SHALL render a designed empty
   state for that region containing a tonal category icon, a title line, one supporting line of text, and
   exactly one orange call-to-action.
5. WHILE a Feature_Area page region is loading its data, THE Dashboard SHALL render a skeleton
   placeholder for that region whose block layout matches the position and shape of the final rendered
   content.
6. IF a Feature_Area page region fails to load its data, THEN THE Dashboard SHALL render an error state
   for that region containing an error indication, a retry control, and SHALL preserve any data already
   loaded in other regions of the page.
7. WHILE a user has reduced-motion enabled in their operating system, THE Dashboard SHALL suppress
   non-essential motion including fade transitions, parallax drift, numeric count-up, skeleton shimmer,
   and celebration animations, and SHALL apply the corresponding state changes instantly.
8. WHEN the Dashboard renders interactive controls, THE UI_System SHALL provide each control with an
   accessible name and a keyboard focus indicator that uses the orange accent `#EA580C` and remains
   visible against the control's background.

### Requirement 10: Reliable error handling and degraded backend behavior

**User Story:** As a user when the backend is slow or unavailable, I want clear, non-disruptive feedback,
so that I understand the dashboard state without being logged out or shown a broken page.

#### Acceptance Criteria

1. IF an API_Proxy receives a non-success response from the Backend other than 401, THEN THE Dashboard
   SHALL render the affected region's error state with a visible error indication and a retry affordance,
   and SHALL keep all other regions interactive and rendered with their last successfully loaded data.
2. WHEN a Backend request exceeds 30 seconds without a complete response, THE API_Proxy SHALL abort that
   request and return a timeout error to the Dashboard.
3. WHEN the Dashboard receives a timeout error from an API_Proxy, THE Dashboard SHALL render the affected
   region's error state with a visible error indication and a retry affordance.
4. IF the Backend returns a response body that fails schema validation, THEN THE Dashboard SHALL render
   the affected region's error state with a visible error indication, SHALL retain the region's last
   successfully loaded data, and SHALL render no field sourced from the unvalidated response body.
5. WHEN a user activates the retry affordance for a region in an error state, THE Dashboard SHALL
   re-issue only that region's failed request and SHALL swap that region to its loading state until the
   request completes.
6. WHEN the Dashboard renders an error state for a failed request, THE Dashboard SHALL keep the user on
   the current route and SHALL NOT redirect to the login page, unless the failure was an authentication
   failure as defined in Requirement 6.
