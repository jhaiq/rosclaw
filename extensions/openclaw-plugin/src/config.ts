import { z } from "zod";

// Default values can be overridden by environment variables:
// - ROSCLAW_DEFAULT_ROSBRIDGE_URL (default: ws://localhost:9090)
// - ROSCLAW_DEFAULT_TRANSPORT_MODE (default: rosbridge)
// - ROSCLAW_DEFAULT_ROBOT_NAME (default: Robot)

const DEFAULT_ROSBRIDGE_URL = process.env.ROSCLAW_DEFAULT_ROSBRIDGE_URL || "ws://localhost:9090";
const DEFAULT_TRANSPORT_MODE = (process.env.ROSCLAW_DEFAULT_TRANSPORT_MODE || "rosbridge") as "rosbridge" | "local" | "webrtc";
const DEFAULT_ROBOT_NAME = process.env.ROSCLAW_DEFAULT_ROBOT_NAME || "Robot";

const IceServerSchema = z.object({
  urls: z.union([z.string(), z.array(z.string())]),
  username: z.string().optional(),
  credential: z.string().optional(),
});

export const RosClawConfigSchema = z.object({
  transport: z
    .object({
      mode: z.enum(["rosbridge", "local", "webrtc"]).default(DEFAULT_TRANSPORT_MODE),
    })
    .default({}),

  rosbridge: z
    .object({
      url: z.string().default(DEFAULT_ROSBRIDGE_URL),
      reconnect: z.boolean().default(true),
      reconnectInterval: z.number().default(3000),
    })
    .default({}),

  local: z
    .object({
      domainId: z.number().default(0),
    })
    .default({}),

  webrtc: z
    .object({
      signalingUrl: z.string().default(""),
      apiUrl: z.string().default(""),
      robotId: z.string().default(""),
      robotKey: z.string().default(""),
      iceServers: z
        .array(IceServerSchema)
        .default([{ urls: "stun:stun.l.google.com:19302" }]),
    })
    .default({}),

  robot: z
    .object({
      name: z.string().default(DEFAULT_ROBOT_NAME),
      namespace: z.string().default(""),
    })
    .default({}),

  safety: z
    .object({
      maxLinearVelocity: z.number().default(1.0),
      maxAngularVelocity: z.number().default(1.5),
      workspaceLimits: z
        .object({
          xMin: z.number().default(-10),
          xMax: z.number().default(10),
          yMin: z.number().default(-10),
          yMax: z.number().default(10),
        })
        .default({}),
    })
    .default({}),
});

export type RosClawConfig = z.infer<typeof RosClawConfigSchema>;

/**
 * Parse and validate raw plugin config against the RosClaw schema.
 * Returns a fully-defaulted, typed config object.
 */
export function parseConfig(raw: Record<string, unknown>): RosClawConfig {
  return RosClawConfigSchema.parse(raw);
}
