/**
 * Open Food Facts (OFF) integration constants.
 *
 * OFF is a free, community-maintained product database. We hit the
 * v2 product endpoint, identify ourselves with a descriptive
 * `User-Agent`, and cache aggressively.
 */

export const OFF_BASE_URL = 'https://world.openfoodfacts.org' as const;
export const OFF_API_VERSION = 'v2' as const;
export const OFF_USER_AGENT = 'RADHA-Backend/1.0 (https://radha.app; contact@radha.app)' as const;

/** Default cache lifetime — 30 days. OFF data changes slowly. */
export const OFF_CACHE_TTL_SECONDS = 30 * 24 * 60 * 60;

/** Wall-clock timeout per HTTP request. */
export const OFF_REQUEST_TIMEOUT_MS = 5_000;

/** Number of consecutive failures before the circuit breaker trips. */
export const OFF_CB_FAILURE_THRESHOLD = 5;

/** Successes needed in `half-open` state before transitioning to `closed`. */
export const OFF_CB_SUCCESS_THRESHOLD = 2;

/** Time the circuit stays `open` before allowing a probe request. */
export const OFF_CB_OPEN_DURATION_MS = 60_000;
