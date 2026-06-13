import { Body, Controller, HttpCode, Param, Post, UseGuards, Version } from '@nestjs/common';

import { ZodValidationPipe } from '@/common/pipes/zod-validation.pipe';
import { CurrentUser, Roles } from '@/modules/auth/decorators/auth.decorators';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from '@/modules/auth/guards/roles.guard';

import { FlagProductDto, FlagProductSchema } from '../dto/flag-product.dto';
import { SubmitBarcodeDto, SubmitBarcodeSchema } from '../dto/submit-barcode.dto';
import {
  BarcodeLearningService,
  FlagResultDto,
  SubmissionDto,
} from '../services/barcode-learning.service';

/**
 * BE-56 — Consumer-facing endpoints for the Barcode Learning queue.
 *
 *   POST /api/v1/products/learn       — submit a community barcode entry
 *   POST /api/v1/products/:ean/flag   — flag an existing entry as incorrect
 *
 * The HTTP transport is intentionally thin: validation via Zod,
 * delegation to `BarcodeLearningService` for everything else
 * (rate-limit, audit log, threshold tracking).
 */
@Controller('products')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('consumer')
export class ConsumerSubmissionController {
  constructor(private readonly svc: BarcodeLearningService) {}

  @Post('learn')
  @Version('1')
  @HttpCode(201)
  submit(
    @CurrentUser('id') userId: string,
    @Body(new ZodValidationPipe(SubmitBarcodeSchema)) dto: SubmitBarcodeDto,
  ): Promise<SubmissionDto> {
    return this.svc.submit(userId, dto);
  }

  @Post(':ean/flag')
  @Version('1')
  @HttpCode(200)
  flag(
    @CurrentUser('id') userId: string,
    @Param('ean') ean: string,
    @Body(new ZodValidationPipe(FlagProductSchema)) dto: FlagProductDto,
  ): Promise<FlagResultDto> {
    return this.svc.flag(userId, ean, dto);
  }
}
