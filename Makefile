# RosClaw Project Management
# Central Makefile for all configuration and build tasks

.PHONY: help setup build typecheck gen-config clean

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
