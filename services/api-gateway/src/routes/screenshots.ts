import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { v4 as uuidv4 } from 'uuid';
import { eventProducer } from '../kafka/producer.js';
import { screenshotUploadCounter } from './health.js';

export interface ScreenshotModel {
  id: string;
  userId: string;
  fileName: string;
  fileSizeBytes: number;
  width: number;
  height: number;
  category: string;
  extractedText: string;
  summary: string;
  tags: string[];
  capturedAt: string;
  indexedAt: string;
}

// In-memory screenshot repository
export const inMemoryScreenshots = new Map<string, ScreenshotModel>();

export async function screenshotRoutes(app: FastifyInstance): Promise<void> {
  // Upload screenshot
  app.post(
    '/api/v1/screenshots/upload',
    async (request: FastifyRequest, reply: FastifyReply) => {
      try {
        let fileName = 'screenshot.png';
        let fileBytesLength = 0;
        let userId = 'anonymous-user';

        if (request.isMultipart()) {
          const data = await request.file();
          if (data) {
            fileName = data.filename;
            const buffer = await data.toBuffer();
            fileBytesLength = buffer.length;
          }
        }

        const screenshotId = `sc-${uuidv4().slice(0, 8)}`;
        const timestamp = new Date().toISOString();

        const screenshot: ScreenshotModel = {
          id: screenshotId,
          userId,
          fileName,
          fileSizeBytes: fileBytesLength > 0 ? fileBytesLength : 102400,
          width: 1080,
          height: 2400,
          category: 'document',
          extractedText: 'Processing OCR...',
          summary: 'Uploaded screenshot queued for event-driven OCR and embedding.',
          tags: ['uploaded'],
          capturedAt: timestamp,
          indexedAt: timestamp,
        };

        inMemoryScreenshots.set(screenshotId, screenshot);

        // Publish to Kafka topic 'screenshot.uploaded'
        await eventProducer.publishScreenshotUploaded({
          eventId: uuidv4(),
          screenshotId: screenshot.id,
          userId: screenshot.userId,
          filePath: `screenshots/${screenshot.id}_${fileName}`,
          fileSizeBytes: screenshot.fileSizeBytes,
          width: screenshot.width,
          height: screenshot.height,
          capturedAt: screenshot.capturedAt,
          uploadedAt: timestamp,
        });

        screenshotUploadCounter.inc({ status: 'success' });

        return reply.status(202).send({
          message: 'Screenshot uploaded and queued for indexing',
          screenshot,
        });
      } catch (err) {
        screenshotUploadCounter.inc({ status: 'error' });
        return reply.status(500).send({
          error: 'Internal Server Error',
          message: `Failed to process upload: ${err}`,
        });
      }
    }
  );

  // List screenshots
  app.get(
    '/api/v1/screenshots',
    async (
      request: FastifyRequest<{
        Querystring: { limit?: string; offset?: string };
      }>
    ) => {
      const limit = parseInt(request.query.limit || '50', 10);
      const all = Array.from(inMemoryScreenshots.values());
      return {
        total: all.length,
        screenshots: all.slice(0, limit),
      };
    }
  );

  // Get single screenshot by ID
  app.get(
    '/api/v1/screenshots/:id',
    async (
      request: FastifyRequest<{
        Params: { id: string };
      }>,
      reply: FastifyReply
    ) => {
      const item = inMemoryScreenshots.get(request.params.id);
      if (!item) {
        return reply.status(404).send({
          error: 'Not Found',
          message: `Screenshot with id '${request.params.id}' not found`,
        });
      }

      return { screenshot: item };
    }
  );
}
