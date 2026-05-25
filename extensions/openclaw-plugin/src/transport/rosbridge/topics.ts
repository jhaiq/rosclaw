import type { RosbridgeClient } from "./client.js";
import type { MessageHandler } from "./types.js";

/**
 * Helper for publishing messages to a AGIROS topic.
 *
 * Rosbridge requires an "advertise" message before any "publish" on a topic.
 * This class tracks whether the topic has been advertised and sends the
 * advertise exactly once per publisher instance.
 */
export class TopicPublisher {
  private advertised = false;

  constructor(
    private client: RosbridgeClient,
    private topic: string,
    private type: string,
  ) {}

  /** Publish a message to the topic. Advertises on first call. */
  publish(msg: Record<string, unknown>): void {
    if (!this.advertised) {
      this.client.send({
        op: "advertise",
        topic: this.topic,
        type: this.type,
      });
      this.advertised = true;
    }
    this.client.send({
      op: "publish",
      topic: this.topic,
      msg,
    });
  }
}

/**
 * Helper for subscribing to messages from a AGIROS topic.
 */
export class TopicSubscriber {
  private unsubscribeFromClient: (() => void) | null = null;

  constructor(
    private client: RosbridgeClient,
    private topic: string,
    private type?: string,
  ) {}

  /** Subscribe to the topic and receive messages via the handler. */
  subscribe(handler: MessageHandler): void {
    this.unsubscribeFromClient = this.client.onMessage(this.topic, handler);
    this.client.send({
      op: "subscribe",
      id: this.client.nextId("subscribe"),
      topic: this.topic,
      type: this.type,
    });
  }

  /** Unsubscribe from the topic. */
  unsubscribe(): void {
    if (this.unsubscribeFromClient) {
      this.unsubscribeFromClient();
      this.unsubscribeFromClient = null;
    }
    this.client.send({
      op: "unsubscribe",
      id: this.client.nextId("unsubscribe"),
      topic: this.topic,
    });
  }
}
