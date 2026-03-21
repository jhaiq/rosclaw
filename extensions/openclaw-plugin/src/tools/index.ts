import type { OpenClawPluginApi } from "../plugin-api.js";
import { registerPublishTool } from "./ros2-publish.js";
import { registerSubscribeTool } from "./ros2-subscribe.js";
import { registerServiceTool } from "./ros2-service.js";
import { registerActionTool } from "./ros2-action.js";
import { registerParamTools } from "./ros2-param.js";
import { registerIntrospectTool } from "./ros2-introspect.js";
import { registerCameraTool } from "./ros2-camera.js";
import {
  registerGo2StandTool,
  registerGo2SitTool,
  registerGo2StopTool,
  registerGo2MoveTool,
} from "./go2-commands.js";

/**
 * Register all ROS2 tools with the OpenClaw AI agent.
 */
export function registerTools(api: OpenClawPluginApi): void {
  registerPublishTool(api);
  registerSubscribeTool(api);
  registerServiceTool(api);
  registerActionTool(api);
  registerParamTools(api);
  registerIntrospectTool(api);
  registerCameraTool(api);

  // Register GO2 specific tools if robot is GO2
  const config = api.pluginConfig as Record<string, unknown> | undefined;
  const robot = config?.robot as Record<string, unknown> | undefined;
  const robotType = (robot?.type as string) ?? "turtlebot";
  const robotName = (robot?.name as string) ?? "";
  if (robotType === "go2" || robotName.toLowerCase().includes("go2")) {
    registerGo2StandTool(api);
    registerGo2SitTool(api);
    registerGo2StopTool(api);
    registerGo2MoveTool(api);
    api.logger.info("GO2-specific tools registered");
  }
}
