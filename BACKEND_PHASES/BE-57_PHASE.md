# Phase BE-57: Voice Features Deferral Marker

## Phase Metadata
- **Phase ID**: BE-57
- **Depends On**: BE-47 (Feature Flags)
- **Estimated Duration**: 0.5 days
- **Complexity**: Trivial

## Goal
Per Req 36, formally exclude voice features from v1 and gate any future implementation behind a Feature Flag.

## Implementation
1. Add a feature flag `voice_features_v2` to the Unleash/GrowthBook config, default `off`.
2. Add a `/api/v1/voice/*` route group that returns `503 Service Unavailable` with a clear "voice features not available in v1" message when the flag is off.
3. Reserve the namespace so v2 implementation has a clean integration point.

## Files
- `server/src/modules/voice/voice.module.ts` (placeholder)
- `server/src/modules/voice/controllers/voice-placeholder.controller.ts`
- `docs/roadmap/voice-features-v2.md`

## Endpoint
```typescript
@Controller('/api/v1/voice')
export class VoicePlaceholderController {
  @All('*')
  @UseGuards(JwtAuthGuard)
  notAvailable() {
    throw new ServiceUnavailableException('Voice features available in v2 — currently disabled.');
  }
}
```

## SOP
**Tests (15)**: any voice path returns 503; flag toggling allows access (when v2 lands); error body includes `feature_locked_seen` event; PostHog records the event; documentation reviewed; flag cleanup checklist present; namespace reserved.

(Reduced 15 → 7 because phase is trivial; remaining 8 slots reserved for v2 implementation phase.)

**Q&A (4 — reduced)**: How do we identify users likely to want voice when v2 ships? Multi-language voice plan (Hindi, Tamil, etc.)? Cost projection for voice (Whisper / Google Speech)? Privacy implications of voice data?

### Sign-off (standard).

---
**END OF BE-57 — End of v2 backend execution roadmap. Frontend phases come next in their own stream.**
