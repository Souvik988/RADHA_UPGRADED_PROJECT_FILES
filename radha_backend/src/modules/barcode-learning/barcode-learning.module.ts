import { Module } from '@nestjs/common';

import { AuthModule } from '@/modules/auth/auth.module';
import { ObservabilityModule } from '@/observability/observability.module';

import { AdminSubmissionController } from './controllers/admin-submission.controller';
import { ConsumerSubmissionController } from './controllers/consumer-submission.controller';
import {
  PRODUCTS_CATALOG_PORT,
  StubProductsCatalogAdapter,
} from './ports/products-catalog.port';
import { FlagRepository } from './repositories/flag.repository';
import { SubmissionRepository } from './repositories/submission.repository';
import { BarcodeLearningService } from './services/barcode-learning.service';
import { FlagTrackerService } from './services/flag-tracker.service';

/**
 * BE-56 — Community Barcode Learning module.
 *
 * Wires the consumer-facing submission/flag endpoints, the admin
 * moderation queue, and the supporting service + repository layer.
 *
 * The `PRODUCTS_CATALOG_PORT` is bound to the `StubProductsCatalogAdapter`
 * by default — BE-11 v2 will rebind it with the real catalog adapter.
 *
 * Per the BE-56 brief this module is NOT registered in
 * `app.module.ts` here; the integrator wires it up in the BE-56
 * handoff step.
 */
@Module({
  imports: [AuthModule, ObservabilityModule],
  controllers: [ConsumerSubmissionController, AdminSubmissionController],
  providers: [
    SubmissionRepository,
    FlagRepository,
    FlagTrackerService,
    BarcodeLearningService,
    StubProductsCatalogAdapter,
    {
      provide: PRODUCTS_CATALOG_PORT,
      useExisting: StubProductsCatalogAdapter,
    },
  ],
  exports: [BarcodeLearningService],
})
export class BarcodeLearningModule {}
