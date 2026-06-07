# Phase BE-48: Observability (Sentry + OpenTelemetry)

## Phase Metadata
- **Phase ID**: BE-48
- **Depends On**: BE-04 (logging)
- **Estimated Duration**: 2-3 days

## Goal
Per Req 49, integrate Sentry (free tier 5K errors/month) for crash/error reporting, instrument Backend with OpenTelemetry for traces, and export to Grafana_Cloud (free tier).

## Files
- `server/src/common/observability/observability.module.ts`
- `server/src/common/observability/sentry.provider.ts`
- `server/src/common/observability/otel.provider.ts`
- `server/src/common/observability/services/budget-watcher.service.ts`

## Init
```typescript
// main.ts
import * as Sentry from '@sentry/node';
import { NodeSDK } from '@opentelemetry/sdk-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';

Sentry.init({ dsn: process.env.SENTRY_DSN, tracesSampleRate: 0.1, environment: process.env.NODE_ENV });

const otel = new NodeSDK({
  traceExporter: new OTLPTraceExporter({ url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT }),
  serviceName: 'radha-backend',
});
otel.start();
```

## Correlation
Every request gets a `correlation_id` header (generated if absent). Pino logger and OTel spans both include it (Req 23 alignment).

## SOP
**Tests (15)**: errors land in Sentry; correlation ID in span and log; OTel exports to Grafana endpoint; Sentry budget watcher fires at 85% of 5K; error-rate alarm at 1% over 5 minutes; sampling rate 10% in prod, 100% in staging; PII scrubbed from Sentry events; performance overhead < 3%; clock skew tolerance; sentry source maps for Mobile; alert routing to ops channel; Sentry environment tags correct; OTel resource attributes; trace ID exposed in error responses for support.

**Q&A (8)**: How is the OTel exporter configured for self-host vs Grafana Cloud? Sentry sample rate trade-offs? How are Mobile crashes attributed to specific build? PII scrubbing rules? Long-running job tracing? How does OTel cost compare to alternatives? Distributed tracing across BE-50 webhooks? Disaster recovery if Sentry is down?

### Sign-off (standard).

---
**END OF BE-48**
