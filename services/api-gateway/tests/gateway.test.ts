import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../src/index.js';

describe('Pomniter API Gateway Tests', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    process.env.NODE_ENV = 'test';
    app = await buildApp();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /health returns 200 with service metadata', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/health',
    });

    expect(res.statusCode).toBe(200);
    const data = JSON.parse(res.body);
    expect(data.status).toBe('ok');
    expect(data.service).toBe('pomniter-api-gateway');
  });

  it('GET /metrics returns Prometheus metric format', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/metrics',
    });

    expect(res.statusCode).toBe(200);
    expect(res.body).toContain('pomniter_screenshots_uploaded_total');
  });

  it('POST /api/v1/auth/register registers new user and issues JWT', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        email: 'testuser@pomniter.dev',
        password: 'Password123!',
        displayName: 'Test User',
      },
    });

    expect(res.statusCode).toBe(201);
    const data = JSON.parse(res.body);
    expect(data.token).toBeDefined();
    expect(data.user.email).toBe('testuser@pomniter.dev');
  });

  it('POST /api/v1/auth/login logs in user with valid credentials', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: {
        email: 'testuser@pomniter.dev',
        password: 'Password123!',
      },
    });

    expect(res.statusCode).toBe(200);
    const data = JSON.parse(res.body);
    expect(data.token).toBeDefined();
  });

  it('POST /api/v1/screenshots/upload queues a screenshot and emits event', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/screenshots/upload',
    });

    expect(res.statusCode).toBe(202);
    const data = JSON.parse(res.body);
    expect(data.screenshot.id).toBeDefined();
  });

  it('GET /api/v1/search performs fallback keyword search', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/search?q=test',
    });

    expect(res.statusCode).toBe(200);
    const data = JSON.parse(res.body);
    expect(data.query).toBe('test');
    expect(Array.isArray(data.results)).toBe(true);
  });
});
