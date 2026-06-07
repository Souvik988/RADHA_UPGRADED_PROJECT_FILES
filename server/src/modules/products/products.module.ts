import { Module, forwardRef } from '@nestjs/common';

import { AuthModule } from '@/modules/auth/auth.module';
import { HealthScoringModule } from '@/modules/health-scoring/health-scoring.module';

import { ScanController } from './controllers/scan.controller';
import { SearchController } from './controllers/search.controller';
import { ProductsController } from './products.controller';
import { ProductsRepository } from './products.repository';
import { ProductsService } from './products.service';
import { ProductNutritionRepository } from './repositories/product-nutrition.repository';
import { SearchRepository } from './repositories/search.repository';
import { ProductLookupService } from './services/product-lookup.service';
import { ProductSearchService } from './services/product-search.service';
import { ScanModePreferenceService } from './services/scan-mode-preference.service';
import { SearchAnalyticsService } from './services/search-analytics.service';

@Module({
  imports: [AuthModule, forwardRef(() => HealthScoringModule)],
  controllers: [ProductsController, ScanController, SearchController],
  providers: [
    ProductsRepository,
    ProductNutritionRepository,
    SearchRepository,
    ProductsService,
    ProductLookupService,
    ProductSearchService,
    SearchAnalyticsService,
    ScanModePreferenceService,
  ],
  exports: [
    ProductsRepository,
    ProductNutritionRepository,
    SearchRepository,
    ProductsService,
    ProductLookupService,
    ProductSearchService,
    SearchAnalyticsService,
    ScanModePreferenceService,
  ],
})
export class ProductsModule {}
