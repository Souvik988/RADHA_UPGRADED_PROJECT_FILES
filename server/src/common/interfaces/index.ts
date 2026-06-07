/**
 * Application-wide interfaces.
 *
 * These are server-internal contracts. Cross-platform contracts go in
 * `@radha/shared-types` instead.
 */

export interface IBootstrapMetadata {
  serviceName: string;
  version: string;
  environment: string;
  startedAt: Date;
}
