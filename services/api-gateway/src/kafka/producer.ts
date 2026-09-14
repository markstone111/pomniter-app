import { Kafka, Producer, RecordMetadata } from 'kafkajs';

export interface ScreenshotUploadedEvent {
  eventId: string;
  screenshotId: string;
  userId: string;
  filePath: string;
  fileSizeBytes: number;
  width: number;
  height: number;
  capturedAt: string;
  uploadedAt: string;
}

export class EventProducer {
  private producer: Producer | null = null;
  private isConnected = false;
  private readonly kafkaBroker: string;

  constructor(broker = process.env.KAFKA_BOOTSTRAP_SERVERS || 'localhost:9092') {
    this.kafkaBroker = broker;
  }

  async connect(): Promise<void> {
    try {
      const kafka = new Kafka({
        clientId: 'pomniter-api-gateway',
        brokers: [this.kafkaBroker],
        retry: {
          retries: 3,
        },
      });
      this.producer = kafka.producer();
      await this.producer.connect();
      this.isConnected = true;
      console.log(`[Kafka] Connected successfully to ${this.kafkaBroker}`);
    } catch (err) {
      console.warn(`[Kafka] Warning: could not connect to Kafka (${err}). Operating in fallback mode.`);
      this.isConnected = false;
    }
  }

  async publishScreenshotUploaded(event: ScreenshotUploadedEvent): Promise<RecordMetadata[] | null> {
    if (!this.isConnected || !this.producer) {
      console.log(`[Kafka:Fallback] Simulating publish 'screenshot.uploaded' for ${event.screenshotId}`);
      return null;
    }

    return this.producer.send({
      topic: 'screenshot.uploaded',
      messages: [
        {
          key: event.screenshotId,
          value: JSON.stringify(event),
          timestamp: Date.now().toString(),
        },
      ],
    });
  }

  async disconnect(): Promise<void> {
    if (this.producer && this.isConnected) {
      await this.producer.disconnect();
      this.isConnected = false;
    }
  }
}

export const eventProducer = new EventProducer();
