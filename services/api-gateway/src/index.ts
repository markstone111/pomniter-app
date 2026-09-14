import fastify, { FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import multipart from '@fastify/multipart';
import dotenv from 'dotenv';
import { healthRoutes } from './routes/health.js';
import { authRoutes } from './routes/auth.js';
import { screenshotRoutes } from './routes/screenshots.js';
import { searchRoutes } from './routes/search.js';
import { eventProducer } from './kafka/producer.js';

dotenv.config();

export async function buildApp(): Promise<FastifyInstance> {
  const app = fastify({
    logger: process.env.NODE_ENV !== 'test',
  });

  await app.register(cors, {
    origin: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  });

  await app.register(jwt, {
    secret: process.env.JWT_SECRET || 'pomniter_super_secret_jwt_key_2026_dev',
  });

  await app.register(multipart, {
    limits: {
      fileSize: 25 * 1024 * 1024, // 25MB max screenshot upload
    },
  });

  // Register routes
  await app.register(healthRoutes);
  await app.register(authRoutes);
  await app.register(screenshotRoutes);
  await app.register(searchRoutes);

  return app;
}

async function start(): Promise<void> {
  const app = await buildApp();
  const port = parseInt(process.env.PORT || '8000', 10);
  const host = process.env.HOST || '0.0.0.0';

  // Initialize Kafka connection
  await eventProducer.connect();

  try {
    await app.listen({ port, host });
    console.log(`🚀 Pomniter API Gateway listening on http://${host}:${port}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
}

// Only start listening if run directly
if (process.env.NODE_ENV !== 'test') {
  start();
}
