# RosClaw Project Management
# Central Makefile for all configuration and build tasks

.PHONY: help setup build typecheck gen-config clean go2-start go2-stop

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

setup: ## Setup development environment
	@echo "[info] Setting up RosClaw development environment..."
	@pnpm install
	@cd docker && cp -n .env.example .env 2>/dev/null || true
	@echo "[ok] Setup complete!"

gen-config: ## Generate all configuration files from docker/.env
	@echo "[info] Generating configuration files..."
	@cd docker && bash openclaw/generate-openclaw-config.sh
	@cd extensions/openclaw-plugin && bash generate-plugin-config.sh
	@echo "[ok] All configs regenerated"

gen-docker-config: ## Generate Docker/openclaw.json only
	@cd docker && bash openclaw/generate-openclaw-config.sh

gen-plugin-config: ## Generate plugin config only
	@cd extensions/openclaw-plugin && bash generate-plugin-config.sh

build: ## Build all TypeScript packages
	@pnpm build

typecheck: ## Type check all packages
	@pnpm typecheck

clean: ## Clean build artifacts
	@echo "[info] Cleaning build artifacts..."
	@pnpm clean 2>/dev/null || true
	@find extensions -type d -name "dist" -exec rm -rf {} + 2>/dev/null || true
	@echo "[ok] Clean complete"

# Delegate to docker/Makefile for Docker operations
docker-%:
	@$(MAKE) -C docker $*

# GO2 commands
go2-start: ## Start Unitree GO2 control (simulation or hardware)
	@echo "[info] Starting Unitree GO2 control..."
	@echo "[info] Mode: $${GO2_MODE:-simulation}"
	@echo "[info] Hardware IP: $${GO2_ROBOT_IP:-192.168.123.2}"
	@echo ""
	@echo "[info] Usage:"
	@echo "[info]   Simulation:  make go2-start"
	@echo "[info]   Hardware:    GO2_MODE=hardware make go2-start"
	@echo ""
	@$(MAKE) -C docker go2-start

go2-stop: ## Stop Unitree GO2 control
	@$(MAKE) -C docker go2-stop

go2-hardware: ## Start GO2 control in hardware mode
	@GO2_MODE=hardware $(MAKE) go2-start

# GO2 Gazebo Simulation commands
go2-gz-start: ## Start Unitree GO2 Gazebo simulation
	@echo "[info] Starting GO2 Gazebo simulation..."
	@echo "[info] Usage:"
	@echo "[info]   GPU mode:    make go2-gz-start"
	@echo "[info]   CPU mode:    docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d"
	@echo ""
	@$(MAKE) -C docker go2-gz-start

go2-gz-stop: ## Stop Unitree GO2 Gazebo simulation
	@$(MAKE) -C docker go2-gz-stop

go2-gz-logs: ## Follow logs from GO2 Gazebo simulation
	@$(MAKE) -C docker go2-gz-logs

go2-gz-status: ## Show status of GO2 Gazebo simulation
	@$(MAKE) -C docker go2-gz-status
