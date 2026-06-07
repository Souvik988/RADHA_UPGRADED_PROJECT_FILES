# Voice Features (v2) — Roadmap & Namespace Reservation

**Status:** Deferred to v2. Not shipping in v1.
**Tracking phase:** BE-57 (deferral marker) → future BE-XX (v2 implementation).
**Feature flag:** `voice_features_v2` (default: `off`).

## Why this doc exists

Per **Req 36**, voice features are formally excluded from RADHA v1 to
keep the v1 scope tight, contain cost (Whisper / Google Speech), and
defer the privacy review that voice data captures require.

This document reserves the `/api/v1/voice/*` namespace and codifies
the contract between the v1 placeholder and the eventual v2
implementation.

## Current behaviour (v1)

The `VoiceModule` (`server/src/modules/voice/`) mounts a single
catch-all controller, `VoicePlaceholderController`, on `/voice/*`.
Every HTTP method on every sub-path:

1. Requires a valid JWT (same `JwtAuthGuard` as the rest of the
   authenticated surface).
2. Throws `ServiceUnavailableException` (HTTP **503**) with the
   following payload:

   ```json
   {
     "statusCode": 503,
     "code": "FEATURE_NOT_AVAILABLE",
     "message": "Voice features available in v2 — currently disabled.",
     "feature": "voice_features_v2"
   }
   ```

Clients (mobile, admin, marketing) MUST branch on the `code` and
`feature` fields rather than the human-readable `message`.

## Feature flag gating (v2)

When v2 lands, the gating contract is:

| `voice_features_v2` value | Behaviour                                                                          |
| ------------------------- | ---------------------------------------------------------------------------------- |
| `off` (default)           | `503 FEATURE_NOT_AVAILABLE` — identical to today's placeholder.                    |
| `on` (per-tenant rollout) | Real voice controllers serve the request; placeholder is bypassed for that tenant. |

The flag is consumed via the existing **BE-47 Feature Flags** module
(`server/src/modules/feature-flags`). v2 implementation MUST:

- Read the flag inside a guard or interceptor at the controller
  level so the placeholder remains the fallback for tenants without
  the flag.
- Emit a `feature_locked_seen` PostHog event whenever the placeholder
  responds with 503 (so we can size demand before paying for ASR).
- Honour the per-tenant + per-environment kill switch.

## v2 scope (planned, NOT v1)

Indicative — to be detailed in the v2 phase doc:

- Speech-to-text intake for product/expiry capture.
- Voice-driven task creation for managers.
- Multi-language support (Hindi, Tamil, Telugu, Marathi, Bengali, …).
- Provider abstraction in `server/src/integrations/voice/` so we can
  swap Whisper ↔ Google Speech ↔ on-device without controller churn.

## Q&A reserved for v2 phase

The BE-57 phase doc reserves the following questions for the v2
implementation phase:

1. How do we identify users likely to want voice when v2 ships?
2. What is the multi-language voice plan (Hindi, Tamil, etc.)?
3. What is the cost projection for voice (Whisper vs. Google Speech)?
4. What are the privacy implications of capturing voice data, and
   how do we surface consent + retention controls?

## Cleanup checklist (when v2 lands)

- [ ] Replace `VoicePlaceholderController` with real controllers
      under `server/src/modules/voice/controllers/`.
- [ ] Wire the `voice_features_v2` flag into a `VoiceFeatureGuard`.
- [ ] Add v2 phase doc, handoff doc, and verification doc under
      `BACKEND_PHASES/`.
- [ ] Update `API_CONTRACTS.md` with the real `/voice/*` endpoints.
- [ ] Update `CONNECTION_MAP.md` to wire the chosen ASR provider.
- [ ] Remove `FEATURE_NOT_AVAILABLE` 503 from documented client
      handling once 100% of tenants have the flag enabled.
- [ ] Retire the `voice_features_v2` flag after full rollout.

## Do NOT

- Do not rename the `/voice` route — clients are already coded
  against it.
- Do not introduce voice handling outside the `voice` module — the
  namespace is reserved on purpose.
- Do not bypass `voice_features_v2` for "internal testing"; use the
  per-tenant flag override instead.
