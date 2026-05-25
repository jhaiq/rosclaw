
# RosClaw

## What This Is

RosClaw is a ROS2 + OpenClaw integration that enables natural language control of robots through messaging apps (WhatsApp, Telegram, Discord, Slack). An AI agent translates user intent into ROS2 commands via the rosbridge WebSocket protocol.

## Architecture

```
User (messaging app) → OpenClaw Gateway → RosClaw Plugin → rosbridge_server → ROS2 robots
```

### Key Components

| Component | Path | Purpose |
|---|---|---|
| `@rosclaw/openclaw-plugin` | `extensions/openclaw-plugin/` | OpenClaw extension: tools, hooks, services, commands |
| `@rosclaw/openclaw-canvas` | `extensions/openclaw-canvas/` | Real-time dashboard (Phase 3 — not yet implemented) |
| `rosclaw_discovery` | `agiros_ws/src/rosclaw_discovery/` | ROS2 node for capability auto-discovery |
| `rosclaw_msgs` | `agiros_ws/src/rosclaw_msgs/` | Custom ROS2 message/service definitions |
| `rosclaw_agent` | `agiros_ws/src/rosclaw_agent/` | ROS2 agent node for WebRTC ↔ DDS bridge (Mode C robot-side) |

### Transport Layer

The transport abstraction lives inside the plugin at `extensions/openclaw-plugin/src/transport/`. It supports three modes:

| Mode | Adapter | Description |
|---|---|---|
| `rosbridge` (default) | `transport/rosbridge/` | WebSocket to rosbridge_server (Mode B) |
| `local` | `transport/local/` | Direct DDS on same machine (Mode A — stub) |
| `webrtc` | `transport/webrtc/` | WebRTC data channel via signaling server (Mode C — stub) |

## Monorepo Structure

- **`extensions/`** — OpenClaw plugin extensions (pnpm workspaces)
- **`agiros_ws/`** — ROS2 colcon workspace
- **`docker/`** — Docker Compose and Dockerfiles
- **`examples/`** — Demo projects
- **`docs/`** — Architecture and design docs

## Key Commands

```sh
pnpm install          # Install all dependencies
pnpm typecheck        # Type-check all packages
```

## Conventions

- **ESM-only**: All packages use `"type": "module"`
- **TypeScript strict mode**: `ES2022` target, `NodeNext` module resolution
- **jiti-loaded**: OpenClaw loads plugin `.ts` source directly at runtime — no build step
- **pnpm workspaces**: Workspace root covers `extensions/*`
- **npm scope**: `@rosclaw/`
- **ROS2 package prefix**: `rosclaw_`
- **Config validation**: Zod schemas in `src/config.ts`, parsed once in `register()`
- **Stub pattern**: Unimplemented code has `// TODO:` markers with proper type signatures

## Tech Stack

- TypeScript (ESM, strict)
- pnpm workspaces
- Zod (config validation)
- ROS2 Jazzy Jalisco
- rosbridge_suite (WebSocket bridge to ROS2)
- OpenClaw plugin API
- Docker / Docker Compose

## Skills

### Robot Adapter Skill

用于快速适配新机器人或仿真环境到 RosClaw 平台。

**文档:**
- **完整流程**: [`docs/skills/robot-adapter.md`](docs/skills/robot-adapter.md)
- **快速参考**: [`docs/skills/robot-adapter-quickref.md`](docs/skills/robot-adapter-quickref.md)
- **技能定义**: [`docs/skills/rosclaw-robot-adapter.skill.md`](docs/skills/rosclaw-robot-adapter.skill.md)
- **Claude Code 使用**: [`docs/skills/claude-code-skill.md`](docs/skills/claude-code-skill.md)

**在 Claude Code 中使用:**

```
@rosclaw-robot-adapter 帮我适配一个新的机器人
```

或

```
使用 rosclaw-robot-adapter skill
```

**在 OpenClaw 中使用:**

```sh
/robot-adapt help
/robot-adapt start -n "MyRobot" -t simulation
/robot-adapt generate -n "MyRobot" -m rosbridge
```

#### 核心步骤

1. **分析话题** - 使用 `agiros topic list/info/hz/echo` 分析机器人接口
2. **设计映射** - 映射到 RosClaw 标准话题 (`/cmd_vel`, `/scan`, `/joint_states` 等)
3. **编写桥接** - 创建 ROS2 桥接节点 (Python)
4. **Docker 封装** - 创建 Dockerfile 和 docker-compose.yml
5. **插件配置** - 更新 `openclaw.plugin.json` 默认值
6. **验证测试** - 话题频率、端到端命令执行

#### 参考实现

- GO2 Gazebo: `docker/docker-compose.go2-gz.yml`
- 桥接节点：`agiros_ws/src/unitree_go2/unitree_go2/go2_gz_bridge.py`
- 机器人命令：`extensions/openclaw-plugin/src/tools/go2-commands.ts`
- OpenClaw 命令：`extensions/openclaw-plugin/src/commands/robot-adapter.ts`

## Recent Updates (Updated: 2026-03-24)

### GO2 Behavior Commands (2026-03-24)

**Major addition**: Official Unitree GO2 behavior command support using ROS2 service interface.

**Problem**: Existing `go2_stand` and `go2_sit` tools used topic publishing (`/robot1/set_pose`) instead of the official behavior control interface.

**Solution**: Refactored to use `transport.callService()` with the official `/robot1/robot_behavior_command` service from ROS2-Gazebo-GO2 project.

**New tools**:
- `go2_stand` - Uses service call with `command: "up"` for STAND controller mode (body height: 0.0m)
- `go2_sit` - Uses service call with `command: "sit"` for REST controller mode (body height: -0.15m)
- `go2_walk` - Uses service call with `command: "walk"` for TROT controller mode (body height: 0.0m)

**Files changed**:
- `extensions/openclaw-plugin/src/tools/go2-commands.ts` - Refactored stand/sit, added walk tool
- `extensions/openclaw-plugin/src/tools/index.ts` - Registered go2_walk tool
- `docs/unitree-go2-integration.md` - Added behavior commands reference table

**Behavior Commands Reference**:
| Command | Service | Controller | Body Height |
|---------|---------|------------|-------------|
| `sit` | `command: "sit"` | REST | -0.15m |
| `up` | `command: "up"` | STAND | 0.0m |
| `walk` | `command: "walk"` | TROT | 0.0m |

**Usage**:
```sh
# Via AGIROS S S CLI
agiros service call /robot1/robot_behavior_command quadropted_msgs/srv/RobotBehaviorCommand "{command: 'sit'}"

# Via OpenClaw natural language
"让机器人坐下"
"站起来"
"开始行走"
```

**Reference**: ROS2-Gazebo-GO2/src/quadropted_controller/scripts/RobotController/RobotController.py

### GO2 Scene Modes (2026-03-23)

**Major addition**: Scene-based operational mode selection via `GO2_SCENE` environment variable.

**New service**: `go2-scene-node` - Docker Compose service that launches scene-specific ROS2 nodes based on environment variable.

**Supported scenes**:
| Scene | Description | Additional Launch File |
|-------|-------------|------------------------|
| `none` (default) | Simulation only | None |
| `cartographer` | Simulation + Cartographer SLAM for mapping | `go2_cartographer.launch.py` |
| `navigation2` | Simulation + Nav2 for autonomous navigation | `go2_navigation2.launch.py` |

**Files changed**:
- `docker/docker-compose.go2-gz.yml` - Added go2-scene-node service with case-based launch logic
- `docker/.env` - Added `GO2_SCENE` variable (default: none)
- `docker/CONFIG.md` - Added scene mode documentation
- `CLAUDE.md` - Added GO2 Scene Modes section

**Usage**:
```sh
# Mapping mode (Cartographer SLAM)
GO2_SCENE=cartographer docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# Navigation mode (Nav2)
GO2_SCENE=navigation2 docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# Simulation only
GO2_SCENE=none docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d
```

**Reference**: ROS2-Gazebo-GO2 README.md section 2.3 (建图和导航)

### GO2 Gazebo Model Loading Fix (2026-03-23)

**Problem**: Gazebo failed to load custom world files (e.g., `rmuc_2025_world.sdf`) with error:
```
Unable to find uri[model://rmuc_2025]
```

**Root cause**: `GZ_SIM_RESOURCE_PATH` was missing the source models directory:
```yaml
# BEFORE (incorrect)
GZ_SIM_RESOURCE_PATH=/opt/go2_gz_sim/models:/opt/go2_gz_sim/src/gazebo_sim/world

# AFTER (correct)
GZ_SIM_RESOURCE_PATH=/opt/go2_gz_sim/models:/opt/go2_gz_sim/src/gazebo_sim/models:/opt/go2_gz_sim/src/gazebo_sim/world
```

The `rmuc_2025` model exists at `/opt/go2_gz_sim/src/gazebo_sim/models/rmuc_2025/`, but this path was not included in the resource path.

**Launch file fix**: Changed default launch file from `launch_sim.launch.py` to `launch.py`:
- `launch.py` supports dynamic `world` and `sensors` parameters
- `launch_sim.launch.py` had hardcoded world path

**Files changed**:
- `docker/docker-compose.go2-gz.yml` - Added `GO2_WORLD`, `GO2_SENSORS` environment variables, fixed `GZ_SIM_RESOURCE_PATH`
- `docker/Dockerfile.go2-gz-sim` - Changed CMD to use `launch.py`
- `docker/.env` - Added `GO2_SIM_LAUNCH=launch.py`

**Usage**:
```sh
# Start with custom world file
GO2_WORLD=rmuc_2025_world.sdf docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# Start with sensors enabled
GO2_SENSORS=true docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# GUI mode (for local debugging)
GO2_GUI=true docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d
```

### Initial GO2 Gazebo Integration

**Major addition**: Complete ROS2-Gazebo-GO2 simulation support with Docker Compose deployment.

**New files**:
- `docker/docker-compose.go2-gz.yml` - Docker Compose with go2-gz profile
- `docker/Dockerfile.go2-gz-sim` - Gazebo simulation container image
- `docker/Dockerfile.go2-gz-sim.local` - Local development variant
- `docker/build-go2-gz-sim-source.sh` - Source build script
- `docker/build-go2-bridge.sh` - Bridge node build script
- `docker/scripts/go2-gz-entrypoint.sh` - Container entrypoint with headless support
- `agiros_ws/src/unitree_go2/unitree_go2/go2_gz_bridge.py` - Topic bridging node
- `agiros_ws/src/unitree_go2/launch/go2_gz_bridge_launch.py` - Launch configuration
- `examples/go2-gz-sim/` - Integration tests and verification scripts

**Key features**:
- Headless Gazebo mode via `ign gazebo -r -s` (server-only, no GUI)
- GPU acceleration support (NVIDIA Container Toolkit)
- Environment variable control: `GO2_WORLD`, `GO2_SENSORS`, `ROS_DOMAIN_ID`
- Three-service architecture: simulation, bridge, rosbridge

**Configuration**:
```yaml
# docker-compose.go2-gz.yml --profile go2-gz
services:
  go2-gz-sim:     # Gazebo simulation (headless)
  go2-bridge-node: # Topic bridging to RosClaw standard
  agiros:           # rosbridge_server (OpenClaw connects here)
```

**Bug fixes**:
- Fixed Gazebo world file discovery: added world directory to `GZ_SIM_RESOURCE_PATH`
- Fixed headless startup: use `ign gazebo -r -s` instead of GUI mode
- Fixed COLCON_CURRENT_PREFIX for multi-workspace builds
- Changed default world to `empty.world` (no external model dependencies)

### GO2 Gazebo Model Loading Fix (2026-03-23)

**Problem**: Gazebo failed to load custom world files (e.g., `rmuc_2025_world.sdf`) with error:
```
Unable to find uri[model://rmuc_2025]
```

**Root cause**: `GZ_SIM_RESOURCE_PATH` was missing the source models directory:
```yaml
# BEFORE (incorrect)
GZ_SIM_RESOURCE_PATH=/opt/go2_gz_sim/models:/opt/go2_gz_sim/src/gazebo_sim/world

# AFTER (correct)
GZ_SIM_RESOURCE_PATH=/opt/go2_gz_sim/models:/opt/go2_gz_sim/src/gazebo_sim/models:/opt/go2_gz_sim/src/gazebo_sim/world
```

The `rmuc_2025` model exists at `/opt/go2_gz_sim/src/gazebo_sim/models/rmuc_2025/`, but this path was not included in the resource path.

**Launch file fix**: Changed default launch file from `launch_sim.launch.py` to `launch.py`:
- `launch.py` supports dynamic `world` and `sensors` parameters
- `launch_sim.launch.py` had hardcoded world path

**Files changed**:
- `docker/docker-compose.go2-gz.yml` - Added `GO2_WORLD`, `GO2_SENSORS` environment variables, fixed `GZ_SIM_RESOURCE_PATH`
- `docker/Dockerfile.go2-gz-sim` - Changed CMD to use `launch.py`
- `docker/.env` - Added `GO2_SIM_LAUNCH=launch.py`

**Usage**:
```sh
# Start with custom world file
GO2_WORLD=rmuc_2025_world.sdf docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# Start with sensors enabled
GO2_SENSORS=true docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# GUI mode (for local debugging)
GO2_GUI=true docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d
```

### Robot Adapter Skill

**Major addition**: Reusable skill for rapid robot/simulation adaptation to RosClaw.

**New documentation**:
- `docs/skills/robot-adapter.md` - Complete 7-step adaptation workflow (617 lines)
- `docs/skills/robot-adapter-quickref.md` - Quick reference card with checklists (224 lines)
- `docs/skills/rosclaw-robot-adapter.skill.md` - Skill definition (253 lines)
- `docs/skills/claude-code-skill.md` - Claude Code integration guide (95 lines)

**New commands**:
- `/robot-adapt` command in OpenClaw for interactive adaptation flow
- Claude Code skill: `@rosclaw-robot-adapter` for AI-assisted adaptation

**Installation**:
```sh
# Skill installed at: ~/.agents/skills/rosclaw-robot-adapter/
# Symlink: ~/.claude/skills/rosclaw-robot-adapter -> ~/.agents/skills/rosclaw-robot-adapter
```

### OpenClaw Plugin Enhancements

**New tools**:
- `extensions/openclaw-plugin/src/tools/go2-commands.ts` - GO2-specific commands (sit, stand, stop)
- `extensions/openclaw-plugin/src/commands/robot-adapter.ts` - Robot adaptation workflow (459 lines)

**Changes**:
- `extensions/openclaw-plugin/src/index.ts` - Registered robot-adapt command
- `extensions/openclaw-plugin/openclaw.plugin.json` - Updated defaults for GO2

### Docker & Build Improvements

**New scripts**:
- `agiros_ws/.docker_build.sh` - Docker build helper
- `docker/Makefile` - Added GO2 Gazebo targets (`make go2-gz-up`, `make go2-gz-logs`, etc.)
- `Makefile` - Root-level convenience targets

**Environment variables** (`.env`):
- `GO2_GZ_SIM_PATH` - Local path to go2_gz_sim source
- `GO2_WORLD` - World file selection (`empty.world`, `rmuc_2025_world.sdf`)
- `GO2_SENSORS` - Enable/disable sensor simulation

## Important Notes

### Gazebo GUI Mode vs Headless Mode

Gazebo 支持两种运行模式，通过 `GO2_GUI` 环境变量控制：

**无头模式（默认）** - 适合服务器部署：
```sh
GO2_GUI=false  # 或不设置
ign gazebo -r -s -v 4 "$GO2_WORLD"
```

- `-r`: 作为服务器运行
- `-s`: 禁用 GUI 渲染（纯服务器模式）
- 无需 X11 显示服务器

**GUI 模式** - 适合本地开发和调试：
```sh
GO2_GUI=true
ign gazebo -r -v 4 "$GO2_WORLD"
```

- 无 `-s` 参数，启动完整 GUI
- 需要 X11 显示服务器支持
- 容器内会打开 Gazebo 可视化窗口

**使用示例**：
```sh
# 无头模式（生产环境）
docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# GUI 模式（本地调试）
GO2_GUI=true docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d
```

### launch.py vs launch_sim.launch.py

RosClaw GO2 Gazebo 使用 `launch.py` 作为默认启动文件（而非 `launch_sim.launch.py`）：

| 特性 | launch.py | launch_sim.launch.py |
|------|-----------|---------------------|
| 参数支持 | `world`, `sensors` | 硬编码 `empty.world` |
| 控制器 | 支持 `gz_ros2_control` | 有限支持 |
| 推荐使用 | 是（默认） | 否 |

**使用方式**：
```sh
# 通过环境变量控制
GO2_WORLD=rmuc_2025_world.sdf GO2_SENSORS=true \
  docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d
```

### World File Discovery

When using custom world files (e.g., `rmuc_2025_world.sdf`), ensure `GZ_SIM_RESOURCE_PATH` includes all model and world directories:

```yaml
GZ_SIM_RESOURCE_PATH=/opt/go2_gz_sim/models:/opt/go2_gz_sim/src/gazebo_sim/models:/opt/go2_gz_sim/src/gazebo_sim/world
```

**Why all three paths?**
- `/opt/go2_gz_sim/models` - Pre-built models
- `/opt/go2_gz_sim/src/gazebo_sim/models` - Source models (e.g., `rmuc_2025/`)
- `/opt/go2_gz_sim/src/gazebo_sim/world` - World files (`*.world`, `*.sdf`)

World files reference models using `model://rmuc_2025` syntax. Gazebo searches all directories in `GZ_SIM_RESOURCE_PATH` to resolve these URIs.

### Multi-Workspace Builds

When sourcing multiple ROS2 workspaces, set `COLCON_CURRENT_PREFIX` before each source:

```sh
export COLCON_CURRENT_PREFIX=/opt/go2_gz_sim/install
source /opt/go2_gz_sim/install/local_setup.sh
export COLCON_CURRENT_PREFIX=/opt/rosclaw/install
source /opt/rosclaw/install/local_setup.sh
```

### GO2 Scene Modes

The GO2 Gazebo simulation supports different scene modes via the `GO2_SCENE` environment variable:

| Scene | Description | Additional Launch File |
|-------|-------------|------------------------|
| `none` (default) | Simulation only | None |
| `cartographer` | Simulation + Cartographer SLAM | `go2_cartographer.launch.py` |
| `navigation2` | Simulation + Nav2 Navigation | `go2_navigation2.launch.py` |

**Usage**:
```sh
# Simulation only
GO2_SCENE=none docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# Mapping mode (Simulation + Cartographer)
GO2_SCENE=cargo docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# Navigation mode (Simulation + Nav2)
GO2_SCENE=navigation2 docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d
```

### Transport Modes

The plugin supports three transport modes via `openclaw.plugin.json`:

| Mode | Config | Use Case |
|------|--------|----------|
| `rosbridge` | `"transport.mode": "rosbridge"` | Docker deployment (default) |
| `local` | `"transport.mode": "local"` | Same-machine development |
| `webrtc` | `"transport.mode": "webrtc"` | Remote robots with signaling server |


