import { Type } from "@sinclair/typebox";
import type { OpenClawPluginApi } from "../plugin-api.js";
import { getTransport } from "../service.js";

/**
 * Register agiros_param_get and agiros_param_set tools with the AI agent.
 */
export function registerParamTools(api: OpenClawPluginApi): void {
  api.registerTool({
    name: "agiros_param_get",
    label: "AGIROS  Get Parameter",
    description:
      "Get the value of a AGIROS parameter from a node. " +
      "Use this to check robot configuration values.",
    parameters: Type.Object({
      node: Type.String({ description: "The fully qualified node name (e.g., '/turtlebot3/controller')" }),
      parameter: Type.String({ description: "The parameter name (e.g., 'max_velocity')" }),
    }),

    async execute(_toolCallId, params) {
      const node = params["node"] as string;
      const parameter = params["parameter"] as string;

      const transport = getTransport();
      const response = await transport.callService({
        service: `${node}/get_parameters`,
        type: "rcl_interfaces/srv/GetParameters",
        args: { names: [parameter] },
      });

      const result = {
        success: response.result,
        node,
        parameter,
        value: response.values,
      };
      return {
        content: [{ type: "text", text: JSON.stringify(result) }],
        details: result,
      };
    },
  });

  api.registerTool({
    name: "agiros_param_set",
    label: "AGIROS  Set Parameter",
    description:
      "Set the value of a AGIROS parameter on a node. " +
      "Use this to change robot configuration at runtime.",
    parameters: Type.Object({
      node: Type.String({ description: "The fully qualified node name" }),
      parameter: Type.String({ description: "The parameter name" }),
      value: Type.Unknown({ description: "The new parameter value" }),
    }),

    async execute(_toolCallId, params) {
      const node = params["node"] as string;
      const parameter = params["parameter"] as string;
      const value = params["value"];

      const transport = getTransport();
      const response = await transport.callService({
        service: `${node}/set_parameters`,
        type: "rcl_interfaces/srv/SetParameters",
        args: {
          parameters: [
            { name: parameter, value },
          ],
        },
      });

      const result = {
        success: response.result,
        node,
        parameter,
      };
      return {
        content: [{ type: "text", text: JSON.stringify(result) }],
        details: result,
      };
    },
  });
}
