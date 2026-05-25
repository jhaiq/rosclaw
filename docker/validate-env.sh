#!/usr/bin/env bash
# Validate docker/.env configuration file
# Ensures all required variables are set and have valid values

set -euo pipefail

ENV_FILE="${1:-.env}"
ERRORS=()

echo "[info] validating $ENV_FILE..."

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[error] $ENV_FILE not found"
  echo "[info] Copy .env.example to .env first:"
  echo "  cp .env.example .env"
  exit 1
fi

# Validate using grep to extract values (avoid sourcing issues)
get_env() {
  grep -E "^${1}=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo ""
}

ROSBRIDGE_PORT=$(get_env ROSBRIDGE_PORT)
OPENCLAW_PORT=$(get_env OPENCLAW_PORT)
ROSCLAW_TRANSPORT_MODE=$(get_env ROSCLAW_TRANSPORT_MODE)
ROS_DOMAIN_ID=$(get_env ROS_DOMAIN_ID)
TURTLEBOT3_MODEL=$(get_env TURTLEBOT3_MODEL)
ROSCLAW_ROSBRIDGE_URL=$(get_env ROSCLAW_ROSBRIDGE_URL)
DOCKER_NETWORK_NAME=$(get_env DOCKER_NETWORK_NAME)

# Set defaults if empty
ROSBRIDGE_PORT=${ROSBRIDGE_PORT:-9090}
OPENCLAW_PORT=${OPENCLAW_PORT:-18789}
ROSCLAW_TRANSPORT_MODE=${ROSCLAW_TRANSPORT_MODE:-rosbridge}
ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
TURTLEBOT3_MODEL=${TURTLEBOT3_MODEL:-burger}
ROSCLAW_ROSBRIDGE_URL=${ROSCLAW_ROSBRIDGE_URL:-ws://agiros:9090}
DOCKER_NETWORK_NAME=${DOCKER_NETWORK_NAME:-1panel-network}

# Validate ROSBRIDGE_PORT
if [[ ! "$ROSBRIDGE_PORT" =~ ^[0-9]+$ ]]; then
  ERRORS+=("ROSBRIDGE_PORT must be a number (got: $ROSBRIDGE_PORT)")
fi

# Validate OPENCLAW_PORT
if [[ ! "$OPENCLAW_PORT" =~ ^[0-9]+$ ]]; then
  ERRORS+=("OPENCLAW_PORT must be a number (got: $OPENCLAW_PORT)")
fi

# Validate ROSCLAW_TRANSPORT_MODE
if [[ "$ROSCLAW_TRANSPORT_MODE" != "rosbridge" && \
      "$ROSCLAW_TRANSPORT_MODE" != "local" && \
      "$ROSCLAW_TRANSPORT_MODE" != "webrtc" ]]; then
  ERRORS+=("ROSCLAW_TRANSPORT_MODE must be rosbridge, local, or webrtc (got: $ROSCLAW_TRANSPORT_MODE)")
fi

# Validate ROS_DOMAIN_ID
if [[ ! "$ROS_DOMAIN_ID" =~ ^[0-9]+$ ]]; then
  ERRORS+=("ROS_DOMAIN_ID must be a number (got: $ROS_DOMAIN_ID)")
fi

# Validate TURTLEBOT3_MODEL
if [[ "$TURTLEBOT3_MODEL" != "burger" && \
      "$TURTLEBOT3_MODEL" != "waffle" && \
      "$TURTLEBOT3_MODEL" != "waffle_pi" ]]; then
  ERRORS+=("TURTLEBOT3_MODEL must be burger, waffle, or waffle_pi (got: $TURTLEBOT3_MODEL)")
fi

# Report results
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo "[error] validation failed:"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
  exit 1
fi

echo "[ok] validation passed"
echo "[info] Configuration summary:"
echo "  ROSBRIDGE_PORT: $ROSBRIDGE_PORT"
echo "  OPENCLAW_PORT: $OPENCLAW_PORT"
echo "  ROSCLAW_ROSBRIDGE_URL: $ROSCLAW_ROSBRIDGE_URL"
echo "  DOCKER_NETWORK_NAME: $DOCKER_NETWORK_NAME"
