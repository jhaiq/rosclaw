#!/usr/bin/env bash
# Generate openclaw.plugin.json from environment variables
# This ensures plugin default configuration is in sync with docker/.env
#
# Usage:
#   source ../../docker/.env  # or set env vars externally
#   ./generate-plugin-config.sh [output_file]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTENV_FILE="$SCRIPT_DIR/../../docker/.env"
OUTPUT_FILE="${1:-$SCRIPT_DIR/openclaw.plugin.json}"

# Load .env if exists
if [[ -f "$DOTENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$DOTENV_FILE"
  set +a
  echo "[info] loaded $DOTENV_FILE"
fi

# Use environment variables or defaults
ROSBRIDGE_URL="${ROSCLAW_ROSBRIDGE_URL:-ws://localhost:9090}"
TRANSPORT_MODE="${ROSCLAW_TRANSPORT_MODE:-rosbridge}"
ROBOT_NAME="${ROSCLAW_ROBOT_NAME:-Robot}"

# Remove quotes from robot name if present
ROBOT_NAME=$(echo "$ROBOT_NAME" | tr -d '"')

cat > "$OUTPUT_FILE" <<EOF
{
  "id": "rosclaw",
  "name": "RosClaw",
  "version": "0.0.1",
  "description": "Control ROS2 robots through natural language via messaging apps",
  "configSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "transport": {
        "type": "object",
        "properties": {
          "mode": {
            "type": "string",
            "enum": ["rosbridge", "local", "webrtc"],
            "description": "Transport mode: rosbridge (Mode B), local (Mode A), or webrtc (Mode C)",
            "default": "${TRANSPORT_MODE}"
          }
        }
      },
      "rosbridge": {
        "type": "object",
        "properties": {
          "url": {
            "type": "string",
            "description": "Rosbridge WebSocket URL",
            "default": "${ROSBRIDGE_URL}"
          },
          "reconnect": {
            "type": "boolean",
            "description": "Auto-reconnect on disconnect",
            "default": true
          },
          "reconnectInterval": {
            "type": "number",
            "description": "Reconnect interval in milliseconds",
            "default": 3000
          }
        },
        "required": ["url"]
      },
      "local": {
        "type": "object",
        "properties": {
          "domainId": {
            "type": "number",
            "description": "ROS2 domain ID for local DDS communication",
            "default": 0
          }
        }
      },
      "webrtc": {
        "type": "object",
        "properties": {
          "signalingUrl": {
            "type": "string",
            "description": "WebSocket URL of the signaling server (e.g., wss://signal-host)"
          },
          "apiUrl": {
            "type": "string",
            "description": "REST API URL of the signaling server (e.g., https://signal-host)"
          },
          "robotId": {
            "type": "string",
            "description": "Target robot's ID on the signaling server"
          },
          "robotKey": {
            "type": "string",
            "description": "Robot key secret (validated by robot, not server)"
          },
          "iceServers": {
            "type": "array",
            "description": "STUN/TURN server configuration",
            "items": {
              "type": "object",
              "properties": {
                "urls": {
                  "description": "STUN/TURN server URL(s)"
                },
                "username": {
                  "type": "string"
                },
                "credential": {
                  "type": "string"
                }
              }
            },
            "default": [{ "urls": "stun:stun.l.google.com:19302" }]
          }
        }
      },
      "robot": {
        "type": "object",
        "properties": {
          "name": {
            "type": "string",
            "description": "Robot display name",
            "default": "${ROBOT_NAME}"
          },
          "namespace": {
            "type": "string",
            "description": "ROS2 namespace for the robot",
            "default": ""
          }
        }
      },
      "safety": {
        "type": "object",
        "properties": {
          "maxLinearVelocity": {
            "type": "number",
            "description": "Maximum linear velocity (m/s)",
            "default": 1.0
          },
          "maxAngularVelocity": {
            "type": "number",
            "description": "Maximum angular velocity (rad/s)",
            "default": 1.5
          },
          "workspaceLimits": {
            "type": "object",
            "description": "Workspace boundary limits (meters)",
            "properties": {
              "xMin": { "type": "number", "default": -10 },
              "xMax": { "type": "number", "default": 10 },
              "yMin": { "type": "number", "default": -10 },
              "yMax": { "type": "number", "default": 10 }
            }
          }
        }
      }
    }
  },
  "uiHints": {
    "transport.mode": {
      "label": "Transport Mode",
      "description": "How the plugin connects to ROS2: rosbridge (WebSocket), local (DDS), or webrtc (P2P)"
    },
    "rosbridge.url": {
      "label": "Rosbridge URL",
      "placeholder": "${ROSBRIDGE_URL}"
    },
    "robot.name": {
      "label": "Robot Name",
      "placeholder": "${ROBOT_NAME}"
    },
    "safety.maxLinearVelocity": {
      "label": "Max Linear Velocity (m/s)",
      "advanced": true
    },
    "safety.maxAngularVelocity": {
      "label": "Max Angular Velocity (rad/s)",
      "advanced": true
    },
    "safety.workspaceLimits": {
      "label": "Workspace Boundary Limits",
      "advanced": true
    }
  }
}
EOF

echo "[ok] generated $OUTPUT_FILE"
echo "[info] Defaults: ROSBRIDGE_URL=$ROSBRIDGE_URL, ROBOT_NAME=$ROBOT_NAME"
