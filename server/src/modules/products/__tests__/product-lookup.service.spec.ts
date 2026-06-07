import { ValidationException } from '@/common/errors/business.exception';
import { LoggerService } from '@/logging/logger.service';

import type { ProductRow } from '@/db/schema/products';
import type { DbService } from '@/db/db.service';

import { ProductsRepository } from '../products.repository';
import { ProductNutritionRepository } from '../repositories/product-nutrition.repository';
import { ProductLookupService } from '../services/product-lookup.service';

const buildSvc = (
  options: {
    findVisibleByEan?: jest.Mock;
    findManyByEans?: jest.Mock;
    findByProductId?: jest.Mock;
  } = {},
): { svc: ProductLookupService; products: jest.Mocked<ProductsRepository> } => {
  const products = {
    findVisibleByEan: options.findVisibleByEan ?? jest.fn().mockResolvedValue(null),
    findManyByEans: options.findManyByEans ?? jest.fn().mockResolvedValue([]),
  } as unknown as jest.Mocked<ProductsRepository>;
  const nutrition = {
    findByProductId: options.findByProductId ?? jest.fn().mockResolvedValue(null),
  } as unknown as ProductNutritionRepository;
  const logger = {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    debug: jest.fn(),
  } as unknown as LoggerService;
  return {
    svc: new ProductLookupService(products, nutrition, logger, {} as unknown as DbService),
    products,
  };
};

describe('ProductLookupService.lookupByEan', () => {
  it('throws ValidationException for malformed EAN', async () => {
    const { svc } = buildSvc();
    await expect(svc.lookupByEan('abc', null)).rejects.toBeInstanceOf(ValidationException);
  });

  it('returns found=false when nothing visible to the tenant', async () => {
    const { svc } = buildSvc();
    const result = await svc.lookupByEan('4006381333931', 't-1');
    expect(result.found).toBe(false);
    expect(result.source).toBe('unknown');
  });

  it('returns found=true with database source on hit', async () => {
    const product = {
      id: 'p-1',
      ean: '4006381333931',
      tenantId: 't-1',
      dataSource: 'manual',
    } as ProductRow;
    const { svc, products } = buildSvc({
      findVisibleByEan: jest.fn().mockResolvedValue(product),
    });
    const result = await svc.lookupByEan('4006381333931', 't-1');
    expect(result.found).toBe(true);
    expect(result.source).toBe('database');
    expect(products.findVisibleByEan).toHaveBeenCalledWith('4006381333931', 't-1');
  });

  it('reports source open-food-facts when dataSource matches', async () => {
    const product = {
      id: 'p-2',
      ean: '4006381333931',
      tenantId: null,
      dataSource: 'open_food_facts',
    } as ProductRow;
    const { svc } = buildSvc({
      findVisibleByEan: jest.fn().mockResolvedValue(product),
    });
    const result = await svc.lookupByEan('4006381333931', null);
    expect(result.source).toBe('open-food-facts');
  });
});

describe('ProductLookupService.lookupBatch', () => {
  it('mixes valid hit, valid miss, and invalid input correctly', async () => {
    const product = {
      id: 'p-1',
      ean: '4006381333931',
      tenantId: 't-1',
      dataSource: 'manual',
    } as ProductRow;
    const { svc } = buildSvc({
      findManyByEans: jest.fn().mockResolvedValue([product]),
    });
    const result = await svc.lookupBatch(['4006381333931', '4006381333932', 'abc'], 't-1');
    expect(result.get('4006381333931')?.found).toBe(true);
    expect(result.get('4006381333932')?.found).toBe(false);
    expect(result.get('abc')?.found).toBe(false);
  });
});
