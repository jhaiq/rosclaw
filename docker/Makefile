# RosClaw Docker Management
# All configuration is loaded from docker/.env

SHELL := /bin/bash
DOTENV := .env
COMPOSE_FILES := -f docker-compose.yml -f docker-compose.openclaw.yml
COMPOSE := docker compose --env-file $(DOTENV) $(COMPOSE_FILES)

.PHONY: help setup start stop restart clean logs validate gen-config gen-plugin-config gpu-start gpu-stop verify-gpu go2-start go2-stop go2-logs

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

setup: ## Create .env from template and generate all configs
	@echo "[info] Setting up RosClaw Docker environment..."
	@if [[ ! -f $(DOTENV) ]]; then \
		cp .env.example $(DOTENV); \
		echo "[ok] Created $(DOTENV)"; \
	else \
		echo "[info] $(DOTENV) already exists"; \
	fi
	@bash validate-env.sh $(DOTENV)
	@bash openclaw/generate-openclaw-config.sh
	@bash ../extensions/openclaw-plugin/generate-plugin-config.sh
	@echo ""
	@echo "[ok] Setup complete!"
	@echo "[info] To start: make start"
	@echo "[info] Or run: ./scripts/openclaw_docker_setup.sh"

start: ## Start all services
	@echo "[info] Starting services..."
	@$(COMPOSE) up -d ros2 openclaw-gateway
	@echo ""
	@echo "[ok] Services started!"
	@echo "[info] Control UI: http://127.0.0.1:18789/"

stop: ## Stop all services
	@echo "[info] Stopping services..."
	@$(COMPOSE) down
	@echo "[ok] Services stopped"

restart: ## Restart all services
	@echo "[info] Restarting services..."
	@$(COMPOSE) restart
	@echo "[ok] Services restarted"

down: ## Stop and remove containers and networks
	@echo "[info] Removing containers and networks..."
	@$(COMPOSE) down
	@echo "[ok] Cleanup complete"

clean: ## Stop and remove volumes (resets all state)
	@echo "[warn] This will remove all OpenClaw state!"
	@read -p "Continue? [y/N] " confirm && [[ "$$confirm" == "y" || "$$confirm" == "Y" ]] || exit 0
	@$(COMPOSE) down -v
	@echo "[ok] State reset complete"

logs: ## Follow logs from all services
	@$(COMPOSE) logs -f

logs-ros2: ## Follow logs from ros2 service
	@$(COMPOSE) logs -f ros2

logs-openclaw: ## Follow logs from openclaw-gateway
	@$(COMPOSE) logs -f openclaw-gateway

gen-config: ## Regenerate openclaw.json from .env
	@bash openclaw/generate-openclaw-config.sh
	@echo "[ok] Config regenerated"

gen-plugin-config: ## Regenerate openclaw.plugin.json from .env
	@bash ../extensions/openclaw-plugin/generate-plugin-config.sh
	@echo "[ok] Plugin config regenerated"

validate: ## Validate .env configuration
	@bash validate-env.sh $(DOTENV)

ps: ## Show running containers
	@$(COMPOSE) ps

pull: ## Pull latest images
	@$(COMPOSE) pull

build: ## Build images from source
	@$(COMPOSE) build

# 1Panel specific commands
connect-1panel: ## Connect ros2 container to 1panel-network
	@echo "[info] Connecting ros2 to 1panel-network..."
	@docker network connect 1panel-network docker-ros2-1 2>/dev/null || echo "[info] Already connected or container not running"
	@echo "[ok] Done"

status: ## Show status and configuration
	@echo "=== RosClaw Status ==="
	@echo ""
	@echo "Containers:"
	@$(COMPOSE) ps 2>/dev/null || echo "  No containers running"
	@echo ""
	@echo "Configuration:"
	@if [[ -f $(DOTENV) ]]; then \
		echo "  $(DOTENV): loaded"; \
		bash validate-env.sh $(DOTENV) 2>/dev/null || true; \
	else \
		echo "  $(DOTENV): not found"; \
	fi

# GPU commands
gpu-start: ## Start ros2 with GPU acceleration (requires NVIDIA Container Toolkit)
	@echo "[info] Starting ros2 with GPU acceleration..."
	@$(COMPOSE) --profile gpu up -d ros2-gpu
	@echo ""
	@echo "[ok] GPU-accelerated ros2 started!"
	@echo "[info] Verify with: docker exec rosclaw-ros2-gpu nvidia-smi"

gpu-stop: ## Stop GPU-accelerated ros2 container
	@echo "[info] Stopping GPU-accelerated ros2..."
	@$(COMPOSE) --profile gpu stop ros2-gpu
	@echo "[ok] ros2-gpu stopped"

verify-gpu: ## Verify GPU support and configuration
	@bash verify-gpu.sh

# GO2 commands
go2-start: ## Start Unitree GO2 control node (simulation mode by default)
	@echo "[info] Starting Unitree GO2 control node..."
	@$(COMPOSE) --profile go2 up -d go2-node
	@echo ""
	@echo "[ok] GO2 node started!"
	@echo "[info] Mode: $$GO2_MODE (default: simulation)"

go2-stop: ## Stop Unitree GO2 control node
	@echo "[info] Stopping GO2 node..."
	@$(COMPOSE) --profile go2 stop go2-node
	@echo "[ok] GO2 node stopped"

go2-logs: ## Follow logs from GO2 node
	@$(COMPOSE) --profile go2 logs -f go2-node
