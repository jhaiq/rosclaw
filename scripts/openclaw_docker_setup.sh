#!/usr/bin/env bash
set -euo pipefail

# Local OpenClaw (containerized) + RosClaw integration bootstrap.
#
# What it does:
# - Loads configuration from docker/.env
# - Generates docker/openclaw/.env with OPENCLAW_GATEWAY_TOKEN (if missing)
# - Generates docker/openclaw/openclaw.json from template
# - Optionally runs OpenClaw onboarding wizard in a one-off container
# - Starts agiros + openclaw-gateway with RosClaw plugin enabled
#
# Usage:
#   ./scripts/openclaw_docker_setup.sh
#
# Optional:
#   OPENCLAW_SKIP_ONBOARD=1 ./scripts/openclaw_docker_setup.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_DIR="$REPO_ROOT/docker"
OPENCLAW_DIR="$DOCKER_DIR/openclaw"
ENV_FILE="$DOCKER_DIR/.env"
OPENCLAW_ENV_FILE="$OPENCLAW_DIR/.env"
OPENCLAW_JSON="$OPENCLAW_DIR/openclaw.json"

# Load main configuration
if [[ -f "$ENV_FILE" ]]; then
  echo "[ok] loaded $ENV_FILE"
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
else
  echo "[warn] $ENV_FILE not found, using defaults"
  echo "[info] Copy docker/.env.example to docker/.env and customize"
fi

# Ensure openclaw directory exists
mkdir -p "$OPENCLAW_DIR"

# Generate openclaw.json from environment
echo "[info] generating openclaw.json..."
bash "$OPENCLAW_DIR/generate-openclaw-config.sh" "$OPENCLAW_JSON"

# Generate openclaw/.env if missing
if [[ ! -f "$OPENCLAW_ENV_FILE" ]]; then
  cat > "$OPENCLAW_ENV_FILE" <<EOF
OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN:-}
OPENCLAW_LOG_LEVEL=${OPENCLAW_LOG_LEVEL:-info}
EOF
  echo "[ok] wrote $OPENCLAW_ENV_FILE"
else
  echo "[ok] found $OPENCLAW_ENV_FILE"
fi

cd "$DOCKER_DIR"

if [[ "${OPENCLAW_SKIP_ONBOARD:-0}" != "1" ]]; then
  echo "[info] running OpenClaw onboarding (interactive)..."
  echo "[info] if you don't want this, re-run with OPENCLAW_SKIP_ONBOARD=1"
  docker compose \
    --env-file "$OPENCLAW_ENV_FILE" \
    -f docker-compose.yml \
    -f docker-compose.openclaw.yml \
    run --rm openclaw-cli "openclaw onboard"
fi

echo "[info] starting agiros + openclaw-gateway..."
docker compose \
  --env-file "$OPENCLAW_ENV_FILE" \
  -f docker-compose.yml \
  -f docker-compose.openclaw.yml \
  up -d agiros openclaw-gateway

echo ""
echo "[ok] OpenClaw Control UI: http://127.0.0.1:${OPENCLAW_PORT:-18789}/"
echo "[ok] Token (also in $OPENCLAW_ENV_FILE):"
grep -E '^OPENCLAW_GATEWAY_TOKEN=' "$OPENCLAW_ENV_FILE" || true
