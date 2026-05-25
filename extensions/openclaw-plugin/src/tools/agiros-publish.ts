import { Type } from "@sinclair/typebox";
import type { OpenClawPluginApi } from "../plugin-api.js";
import { getTransport } from "../service.js";

/**
 * Register the agiros_publish tool with the AI agent.
 * Allows publishing messages to any AGIROS topic.
 */
export function registerPublishTool(api: OpenClawPluginApi): void {
  api.registerTool({
    name: "agiros_publish",
    label: "AGIROS Publish",
    description:
      "Publish a message to a AGIROS topic. Use this to send commands to the robot " +
      "(e.g., velocity commands to /cmd_vel, navigation goals, etc.).",
    parameters: Type.Object({
      topic: Type.String({ description: "The AGIROS topic name (e.g., '/cmd_vel')" }),
      type: Type.String({ description: "The AGIROS message type (e.g., 'geometry_msgs/msg/Twist')" }),
      message: Type.Record(Type.String(), Type.Unknown(), {
        description: "The message payload matching the AGIROS message type schema",
      }),
    }),

    async execute(_toolCallId, params) {
      const topic = params["topic"] as string;
      const type = params["type"] as string;
      const message = params["message"] as Record<string, unknown>;

      const transport = getTransport();
      transport.publish({ topic, type, msg: message });

      const result = { success: true, topic, type };
      return {
        content: [{ type: "text", text: JSON.stringify(result) }],
        details: result,
      };
    },
  });
}
