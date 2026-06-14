import { Module } from '@nestjs/common';

import { AuthModule } from '@/modules/auth/auth.module';
import { SubscriptionsModule } from '@/modules/subscriptions/subscriptions.module';

import { TenantsController } from './tenants.controller';
import { TenantsRepository } from './repositories/tenants.repository';
import { TenantBootstrapService } from './services/tenant-bootstrap.service';
import { TenantOnboardingService } from './services/tenant-onboarding.service';

@Module({
  // SubscriptionsModule → BE-28 trial start on self-service onboarding (D9).
  imports: [AuthModule, SubscriptionsModule],
  controllers: [TenantsController],
  providers: [TenantsRepository, TenantOnboardingService, TenantBootstrapService],
  exports: [TenantsRepository, TenantOnboardingService, TenantBootstrapService],
})
export class TenantsModule {}
