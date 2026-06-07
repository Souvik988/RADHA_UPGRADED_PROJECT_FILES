import { Module, Provider } from '@nestjs/common';

import { AuthModule } from '@/modules/auth/auth.module';
import { ExpiryModule } from '@/modules/expiry/expiry.module';
import { ProductsModule } from '@/modules/products/products.module';
import { ObservabilityModule } from '@/observability/observability.module';

import { GrnController } from './grn.controller';
import { GrnService } from './grn.service';
import { GrnEventsRepository } from './repositories/grn-events.repository';
import { GrnHeadersRepository } from './repositories/grn-headers.repository';
import { GrnItemsRepository } from './repositories/grn-items.repository';
import { GrnPostingService } from './services/grn-posting.service';
import { GrnReversalService } from './services/grn-reversal.service';
import { GrnValidationService } from './services/grn-validation.service';
import { InventoryStubService } from './services/inventory-stub.service';
import {
  SupplierLookupStubService,
  SupplierPerformanceStubService,
} from './services/supplier-stub.service';
import {
  INVENTORY_SERVICE_TOKEN,
  SUPPLIER_LOOKUP_TOKEN,
  SUPPLIER_PERFORMANCE_TOKEN,
} from './types/grn.types';
import { GrnNumberGenerator } from './utils/grn-number-generator.utils';

/**
 * BE-26 — GRN module.
 *
 * Imports:
 *   - AuthModule          → BE-08 guard stack + decorators.
 *   - ProductsModule      → ProductsRepository (catalog read / auto-create).
 *   - ExpiryModule        → ExpiryService (BE-18 batch registration).
 *   - ObservabilityModule → AuditLogService.
 *
 * Cross-phase contracts (each defaults to an in-process stub so the
 * module boots and tests run without BE-25 / BE-27):
 *   - `INVENTORY_SERVICE_TOKEN`     → BE-27 owns the real impl.
 *   - `SUPPLIER_LOOKUP_TOKEN`       → BE-25 owns the real impl.
 *   - `SUPPLIER_PERFORMANCE_TOKEN`  → BE-25 owns the real impl.
 *
 * When BE-25 / BE-27 ship, the orchestrator overrides these
 * providers to point at the real services. The BE-26 handoff
 * documents the override.
 *
 * Exports:
 *   - GrnService       — used by BE-31 dashboard reads.
 *   - GrnPostingService / GrnReversalService — used by App Owner
 *                       Dashboard direct controls.
 *   - The three repositories — used by BE-30 OHS analytics.
 */

const inventoryProvider: Provider = {
  provide: INVENTORY_SERVICE_TOKEN,
  useExisting: InventoryStubService,
};

const supplierLookupProvider: Provider = {
  provide: SUPPLIER_LOOKUP_TOKEN,
  useExisting: SupplierLookupStubService,
};

const supplierPerfProvider: Provider = {
  provide: SUPPLIER_PERFORMANCE_TOKEN,
  useExisting: SupplierPerformanceStubService,
};

@Module({
  imports: [AuthModule, ProductsModule, ExpiryModule, ObservabilityModule],
  controllers: [GrnController],
  providers: [
    GrnHeadersRepository,
    GrnItemsRepository,
    GrnEventsRepository,

    GrnNumberGenerator,
    GrnValidationService,
    GrnPostingService,
    GrnReversalService,

    InventoryStubService,
    SupplierLookupStubService,
    SupplierPerformanceStubService,

    inventoryProvider,
    supplierLookupProvider,
    supplierPerfProvider,

    GrnService,
  ],
  exports: [
    GrnService,
    GrnPostingService,
    GrnReversalService,
    GrnHeadersRepository,
    GrnItemsRepository,
    GrnEventsRepository,
  ],
})
export class GrnModule {}
