import type { INestApplication } from '@nestjs/common';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';

import { API_DEFAULT_VERSION } from '../src/common/constants';
import { AppModule } from '../src/app.module';

describe('AppModule (e2e — BE-03 envelope)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication({ logger: false });
    app.setGlobalPrefix('api');
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: API_DEFAULT_VERSION });
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }),
    );

    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /api/v1/health returns standard success envelope', async () => {
    const res = await request(app.getHttpServer()).get('/api/v1/health').expect(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('ok');
    expect(res.body.meta.requestId).toBeDefined();
    expect(res.headers['x-request-id']).toBeDefined();
  });

  it('GET /api/v1/health echoes a client-supplied request id', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/v1/health')
      .set('x-request-id', 'client-supplied-123')
      .expect(200);
    expect(res.headers['x-request-id']).toBe('client-supplied-123');
    expect(res.body.meta.requestId).toBe('client-supplied-123');
  });

  it('GET /api/v1/nonexistent returns standard error envelope', async () => {
    const res = await request(app.getHttpServer()).get('/api/v1/nonexistent').expect(404);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('NOT_FOUND');
    expect(res.body.meta.path).toBe('/api/v1/nonexistent');
  });
});
