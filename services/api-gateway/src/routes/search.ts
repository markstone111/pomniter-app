import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { inMemoryScreenshots } from './screenshots.js';

export async function searchRoutes(app: FastifyInstance): Promise<void> {
  app.get(
    '/api/v1/search',
    async (
      request: FastifyRequest<{
        Querystring: { q?: string; category?: string; limit?: string };
      }>,
      reply: FastifyReply
    ) => {
      const q = (request.query.q || '').trim().toLowerCase();
      const category = request.query.category;
      const limit = parseInt(request.query.limit || '30', 10);

      const searchServiceUrl = process.env.SEARCH_SERVICE_URL || 'http://localhost:8003';

      try {
        // Try forwarding to downstream search-service
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 1000);

        const response = await fetch(`${searchServiceUrl}/api/v1/search`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ query: q, category, limit }),
          signal: controller.signal,
        });
        clearTimeout(timeout);

        if (response.ok) {
          const data = await response.json();
          return reply.send(data);
        }
      } catch {
        // Downstream search service unavailable; proceed to local in-memory fallback
      }

      // Local fallback hybrid text search
      const screenshots = Array.from(inMemoryScreenshots.values());
      const filtered = screenshots.filter((s) => {
        const matchesCategory = !category || s.category.toLowerCase() === category.toLowerCase();
        const matchesText =
          !q ||
          s.extractedText.toLowerCase().includes(q) ||
          s.summary.toLowerCase().includes(q) ||
          s.tags.some((t) => t.toLowerCase().includes(q));
        return matchesCategory && matchesText;
      });

      return {
        query: q,
        total: filtered.length,
        results: filtered.slice(0, limit).map((s) => ({
          screenshot: s,
          score: 0.95,
          matchType: 'keyword_fallback',
        })),
      };
    }
  );
}
