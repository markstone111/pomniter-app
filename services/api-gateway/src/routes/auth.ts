import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';

interface UserRecord {
  id: string;
  email: string;
  passwordHash: string;
  displayName: string;
  createdAt: string;
}

// In-memory user store for dev/testing when Postgres is not connected
const inMemoryUsers = new Map<string, UserRecord>();

export async function authRoutes(app: FastifyInstance): Promise<void> {
  // Register
  app.post(
    '/api/v1/auth/register',
    async (
      request: FastifyRequest<{
        Body: { email?: string; password?: string; displayName?: string };
      }>,
      reply: FastifyReply
    ) => {
      const { email, password, displayName } = request.body || {};

      if (!email || !password) {
        return reply.status(400).send({
          error: 'Bad Request',
          message: 'Email and password are required',
        });
      }

      if (inMemoryUsers.has(email.toLowerCase())) {
        return reply.status(409).send({
          error: 'Conflict',
          message: 'A user with this email already exists',
        });
      }

      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(password, salt);
      const user: UserRecord = {
        id: uuidv4(),
        email: email.toLowerCase(),
        passwordHash,
        displayName: displayName || email.split('@')[0],
        createdAt: new Date().toISOString(),
      };

      inMemoryUsers.set(user.email, user);

      const token = app.jwt.sign({
        sub: user.id,
        email: user.email,
        displayName: user.displayName,
      });

      return reply.status(201).send({
        token,
        user: {
          id: user.id,
          email: user.email,
          displayName: user.displayName,
          createdAt: user.createdAt,
        },
      });
    }
  );

  // Login
  app.post(
    '/api/v1/auth/login',
    async (
      request: FastifyRequest<{
        Body: { email?: string; password?: string };
      }>,
      reply: FastifyReply
    ) => {
      const { email, password } = request.body || {};

      if (!email || !password) {
        return reply.status(400).send({
          error: 'Bad Request',
          message: 'Email and password are required',
        });
      }

      const user = inMemoryUsers.get(email.toLowerCase());
      if (!user) {
        return reply.status(401).send({
          error: 'Unauthorized',
          message: 'Invalid email or password',
        });
      }

      const isMatch = await bcrypt.compare(password, user.passwordHash);
      if (!isMatch) {
        return reply.status(401).send({
          error: 'Unauthorized',
          message: 'Invalid email or password',
        });
      }

      const token = app.jwt.sign({
        sub: user.id,
        email: user.email,
        displayName: user.displayName,
      });

      return reply.send({
        token,
        user: {
          id: user.id,
          email: user.email,
          displayName: user.displayName,
        },
      });
    }
  );

  // Current User (/me)
  app.get(
    '/api/v1/auth/me',
    {
      preHandler: async (request: FastifyRequest, reply: FastifyReply) => {
        try {
          await request.jwtVerify();
        } catch (err) {
          reply.status(401).send({ error: 'Unauthorized', message: 'Invalid or missing token' });
        }
      },
    },
    async (request: FastifyRequest) => {
      return {
        user: request.user,
      };
    }
  );
}
