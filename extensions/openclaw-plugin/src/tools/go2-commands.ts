/**
 * Unitree GO2 specific commands for OpenClaw
 * Gazebo Simulation compatible commands
 */

import { Type } from "@sinclair/typebox";
import type { OpenClawPluginApi } from "../plugin-api.js";
import { getTransport } from "../service.js";

/**
 * Register the go2_stand tool with the AI agent.
 * Makes the GO2 robot stand up from sitting position.
 * Uses the official RobotBehaviorCommand service for proper behavior control.
 */
export function registerGo2StandTool(api: OpenClawPluginApi): void {
  api.registerTool({
    name: "go2_stand",
    label: "GO2 Stand",
    description:
      "Make the Unitree GO2 robot stand up from sitting position using the official behavior command service. " +
      "This triggers the proper standing animation and controller mode change.",
    parameters: Type.Object({}),

    async execute(_toolCallId, _params) {
      const transport = getTransport();
      // Call the official RobotBehaviorCommand service
      await transport.callService({
        service: "/robot1/robot_behavior_command",
        type: "quadropted_msgs/srv/RobotBehaviorCommand",
        args: { command: "up" },
      });

      const result = { success: true, message: "GO2 standing up (official behavior command)" };
      return {
        content: [{ type: "text", text: JSON.stringify(result) }],
        details: result,
      };
    },
  });
}

/**
 * Register the go2_sit tool with the AI agent.
 * Makes the GO2 robot sit down using the official behavior command.
 */
export function registerGo2SitTool(api: OpenClawPluginApi): void {
  api.registerTool({
    name: "go2_sit",
    label: "GO2 Sit",
    description:
      "Make the Unitree GO2 robot sit down using the official behavior command service. " +
      "This triggers the proper sitting animation and controller mode change.",
    parameters: Type.Object({}),

    async execute(_toolCallId, _params) {
      const transport = getTransport();
      // Call the official RobotBehaviorCommand service
      await transport.callService({
        service: "/robot1/robot_behavior_command",
        type: "quadropted_msgs/srv/RobotBehaviorCommand",
        args: { command: "sit" },
      });

      const result = { success: true, message: "GO2 sitting down (official behavior command)" };
      return {
        content: [{ type: "text", text: JSON.stringify(result) }],
        details: result,
      };
    },
  });
}

/**
 * Register the go2_walk tool with the AI agent.
 * Makes the GO2 robot start walking using the official behavior command.
 */
export function registerGo2WalkTool(api: OpenClawPluginApi): void {
  api.registerTool({
    name: "go2_walk",
    label: "GO2 Walk",
    description:
      "Make the Unitree GO2 robot start walking mode using the official behavior command service. " +
      "After calling this, use go2_move to specify movement direction and speed.",
    parameters: Type.Object({}),

    async execute(_toolCallId, _params) {
      const transport = getTransport();
      // Call the official RobotBehaviorCommand service
      await transport.callService({
        service: "/robot1/robot_behavior_command",
        type: "quadropted_msgs/srv/RobotBehaviorCommand",
        args: { command: "walk" },
      });

      const result = { success: true, message: "GO2 walking mode activated (official behavior command)" };
      return {
        content: [{ type: "text", text: JSON.stringify(result) }],
        details: result,
      };
    },
  });
}

/**
 * Register the go2_stop tool with the AI agent.
 * Emergency stop - immediately halt all GO2 movement.
 */
export function registerGo2StopTool(api: OpenClawPluginApi): void {
  api.registerTool({
    name: "go2_stop",
    label: "GO2 Stop",
    description:
      "Emergency stop - immediately halt all GO2 movement. " +
      "Use this command in emergency situations or when you need the robot to stop immediately.",
    parameters: Type.Object({}),

    async execute(_toolCallId, _params) {
      const transport = getTransport();
      // Publish zero velocity to simulation
      await transport.publish({
        topic: "/robot1/cmd_vel",
        type: "geometry_msgs/msg/Twist",
        msg: {
          linear: { x: 0, y: 0, z: 0 },
          angular: { x: 0, y: 0, z: 0 },
        },
      });

      const result = { success: true, message: "GO2 emergency stop activated" };
      return {
        content: [{ type: "text", text: JSON.stringify(result) }],
        details: result,
      };
    },
  });
}

/**
 * Register the go2_move tool with the AI agent.
 * Move the GO2 robot with specified velocity.
 */
export function registerGo2MoveTool(api: OpenClawPluginApi): void {
  api.registerTool({
    name: "go2_move",
    label: "GO2 Move",
    description:
      "Move the GO2 robot with specified velocity. " +
      "Specify linear_x for forward/backward motion (m/s), linear_y for left/right motion (m/s), " +
      "angular_z for rotation (rad/s). Optionally specify duration in seconds.",
    parameters: Type.Object({
      linear_x: Type.Number({
        description: "Forward/backward velocity (m/s), positive=forward",
        default: 0,
      }),
      linear_y: Type.Number({
        description: "Left/right velocity (m/s), positive=left",
        default: 0,
      }),
      angular_z: Type.Number({
        description: "Rotation velocity (rad/s), positive=counterclockwise",
        default: 0,
      }),
      duration: Type.Number({
        description: "How long to move (seconds)",
        default: 1,
      }),
    }),

    async execute(_toolCallId, params) {
      const transport = getTransport();
      const {
        linear_x = 0,
        linear_y = 0,
        angular_z = 0,
        duration = 1,
      } = params as {
        linear_x?: number;
        linear_y?: number;
        angular_z?: number;
        duration?: number;
      };

      // Publish velocity command to simulation
      await transport.publish({
        topic: "/robot1/cmd_vel",
        type: "geometry_msgs/msg/Twist",
        msg: {
          linear: { x: linear_x, y: linear_y, z: 0 },
          angular: { x: 0, y: 0, z: angular_z },
        },
      });

      // If duration specified, schedule stop
      if (duration > 0) {
        setTimeout(async () => {
          await transport.publish({
            topic: "/robot1/cmd_vel",
            type: "geometry_msgs/msg/Twist",
            msg: {
              linear: { x: 0, y: 0, z: 0 },
              angular: { x: 0, y: 0, z: 0 },
            },
          });
        }, duration * 1000);
      }

      const result = {
        success: true,
        message: `GO2 moving: linear=(${linear_x},${linear_y})m/s, angular=${angular_z}rad/s for ${duration}s`,
      };
      return {
        content: [{ type: "text", text: JSON.stringify(result) }],
        details: result,
      };
    },
  });
}
