import { Injectable } from '@nestjs/common';
import { and, eq, inArray, isNull, or } from 'drizzle-orm';

import { DbService } from '@/db/db.service';
import { BaseRepository } from '@/db/repositories/base.repository';
import { NewProduct, ProductRow, products } from '@/db/schema/products';

@Injectable()
export class ProductsRepository extends BaseRepository<
  typeof products,
  ProductRow,
  NewProduct,
  Partial<NewProduct>
> {
  constructor(db: DbService) {
    super(db.getDb(), products, 'products');
  }

  /**
   * Look up a product by EAN respecting tenant visibility.
   * Tenant-scoped row > global (tenant_id = NULL) > nothing.
   */
  async findVisibleByEan(ean: string, tenantId: string | null): Promise<ProductRow | null> {
    const condition = tenantId
      ? or(eq(products.tenantId, tenantId), isNull(products.tenantId))
      : isNull(products.tenantId);

    const rows = (await this.db
      .select()
      .from(products)
      .where(and(eq(products.ean, ean), condition, isNull(products.deletedAt)))) as ProductRow[];

    if (rows.length === 0) return null;
    if (rows.length === 1) return rows[0];
    return rows.find((r) => r.tenantId !== null) ?? rows[0];
  }

  async findManyByEans(eans: string[], tenantId: string | null): Promise<ProductRow[]> {
    if (eans.length === 0) return [];
    const condition = tenantId
      ? or(eq(products.tenantId, tenantId), isNull(products.tenantId))
      : isNull(products.tenantId);
    return (await this.db
      .select()
      .from(products)
      .where(
        and(inArray(products.ean, eans), condition, isNull(products.deletedAt)),
      )) as ProductRow[];
  }

  async findByIdInTenant(id: string, tenantId: string | null): Promise<ProductRow | null> {
    const condition = tenantId
      ? or(eq(products.tenantId, tenantId), isNull(products.tenantId))
      : isNull(products.tenantId);
    const [row] = await this.db
      .select()
      .from(products)
      .where(and(eq(products.id, id), condition, isNull(products.deletedAt)))
      .limit(1);
    return (row as ProductRow | undefined) ?? null;
  }
}
