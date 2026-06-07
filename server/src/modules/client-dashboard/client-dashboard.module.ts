import { Module, Provider } from '@nestjs/common';

import { AuthModule } from '@/modules/auth/auth.module';
import { StoresModule } from '@/modules/stores/stores.module';

import { ClientDashboardController } from './client-dashboard.controller';
import { HealthScoresRepository } from './repositories/health-scores.repository';
import { AlertsSummaryService } from './services/alerts-summary.service';
import { ComplianceCalculator } from './services/components/compliance.calculator';
import { ExpiryManagementCalculator } from './services/components/expiry-management.calculator';
import { InventoryAccuracyCalculator } from './services/components/inventory-accuracy.calculator';
import { TaskCompletionCalculator } from './services/components/task-completion.calculator';
import { TeamActivityCalculator } from './services/components/team-activity.calculator';
import { VendorQualityCalculator } from './services/components/vendor-quality.calculator';
import { ClientDashboardService } from './services/dashboard.service';
import { DashboardCacheService } from './services/dashboard-cache.service';
import { KpiService } from './services/kpi.service';
import { OperationalHealthScoreService } from './services/operational-health-score.service';
import { QuickActionService } from './services/quick-action.service';
import { StubInventoryAccuracyMetricsQuery } from './services/stub-inventory-accuracy-metrics.query';
import { StubSubscriptionsService } from './services/stub-subscriptions.service';
import { TeamPerformanceService } from './services/team-performance.service';
import { TrendsService } from './services/trends.service';
import { DASHBOARD_CACHE_INVALIDATOR_TOKEN } from './types/dashboard.types';
import {
  INVENTORY_ACCURACY_METRICS_QUERY,
  SUBSCRIPTIONS_SERVICE_TOKEN,
} from './types/integration.tokens';

/**
 * BE-30 — Client Dashboard module.
 *
 * Imports:
 *   - AuthModule    → BE-08 guard stack + decorators (the controller
 *                     uses JwtAuthGuard, RolesGuard, PermissionsGuard,
 *                     TenantScopeGuard).
 *   - StoresModule  → StoresRepository (tenant + store membership
 *                     check) + StoreScopeGuard.
 *
 * Cross-phase contracts (defaulted to in-process stubs so the
 * module boots and tests run without BE-27 / BE-28):
 *   - `INVENTORY_ACCURACY_METRICS_QUERY` → BE-27 owns the real impl.
 *   - `SUBSCRIPTIONS_SERVICE_TOKEN`      → BE-28 owns the real impl.
 *
 * The orchestrator overrides these providers when BE-27 / BE-28
 * land. The dashboard module is unaffected by the override; the
 * INTEGRATION CHECKLIST (BE-30 HANDOFF) lists the override points.
 *
 * Cache invalidator export:
 *   - `DASHBOARD_CACHE_INVALIDATOR_TOKEN` is bound to the
 *     `DashboardCacheService` so other modules (scans / expiry /
 *     tasks repositories) can call `invalidateStore(...)` without
 *     reaching back into this module's source. The orchestrator
 *     wires this into the relevant post-write hooks.
 */

const inventoryStubProvider: Provider = {
  provide: INVENTORY_ACCURACY_METRICS_QUERY,
  useExisting: StubInventoryAccuracyMetricsQuery,
};

const subscriptionsStubProvider: Provider = {
  provide: SUBSCRIPTIONS_SERVICE_TOKEN,
  useExisting: StubSubscriptionsService,
};

const cacheInvalidatorProvider: Provider = {
  provide: DASHBOARD_CACHE_INVALIDATOR_TOKEN,
  useExisting: DashboardCacheService,
};

@Module({
  imports: [AuthModule, StoresModule],
  controllers: [ClientDashboardController],
  providers: [
    /* Sub-services */
    KpiService,
    AlertsSummaryService,
    QuickActionService,
    TrendsService,
    TeamPerformanceService,
    DashboardCacheService,

    /* OHS calculators + service + repo */
    ComplianceCalculator,
    ExpiryManagementCalculator,
    InventoryAccuracyCalculator,
    TaskCompletionCalculator,
    TeamActivityCalculator,
    VendorQualityCalculator,
    OperationalHealthScoreService,
    HealthScoresRepository,

    /* Cross-phase stubs + token bindings */
    StubInventoryAccuracyMetricsQuery,
    StubSubscriptionsService,
    inventoryStubProvider,
    subscriptionsStubProvider,

    /* Cache invalidator binding for downstream modules */
    cacheInvalidatorProvider,

    /* Public façade */
    ClientDashboardService,
  ],
  exports: [
    ClientDashboardService,
    OperationalHealthScoreService,
    HealthScoresRepository,
    DashboardCacheService,
    /* Re-export the invalidator token so downstream modules can
       inject it without depending on the dashboard's source. */
    cacheInvalidatorProvider,
  ],
})
export class ClientDashboardModule {}
