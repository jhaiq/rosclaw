import type {
  ConnectionStatus,
  ConnectionHandler,
  Subscription,
  PublishOptions,
  SubscribeOptions,
  ServiceCallOptions,
  ServiceCallResult,
  ActionGoalOptions,
  ActionResult,
  TopicInfo,
  ServiceInfo,
  ActionInfo,
  MessageHandler,
} from "./types.js";

/**
 * Unified transport interface for AGIROS communication.
 *
 * All deployment modes (local DDS, rosbridge WebSocket, WebRTC data channel)
 * implement this interface so that plugin tools work identically regardless
 * of the underlying transport.
 */
export interface RosTransport {
  // --- Connection lifecycle ---

  /** Establish the transport connection. */
  connect(): Promise<void>;

  /** Gracefully close the transport connection. */
  disconnect(): Promise<void>;

  /** Get current connection status. */
  getStatus(): ConnectionStatus;

  /** Register a connection status change handler. Returns a cleanup function. */
  onConnection(handler: ConnectionHandler): () => void;

  // --- Topics ---

  /** Publish a message to a AGIROS topic. */
  publish(options: PublishOptions): void;

  /** Subscribe to a AGIROS topic. Returns a Subscription handle. */
  subscribe(options: SubscribeOptions, handler: MessageHandler): Subscription;

  // --- Services ---

  /** Call a AGIROS service and return the result. */
  callService(options: ServiceCallOptions): Promise<ServiceCallResult>;

  // --- Actions ---

  /** Send a goal to a AGIROS action server. */
  sendActionGoal(options: ActionGoalOptions): Promise<ActionResult>;

  /** Cancel an in-progress action goal. */
  cancelActionGoal(action: string): Promise<void>;

  // --- Introspection ---

  /** List all available AGIROS topics. */
  listTopics(): Promise<TopicInfo[]>;

  /** List all available AGIROS services. */
  listServices(): Promise<ServiceInfo[]>;

  /** List all available AGIROS action servers. */
  listActions(): Promise<ActionInfo[]>;
}
