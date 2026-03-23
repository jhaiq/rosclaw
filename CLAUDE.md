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
| `rosclaw_discovery` | `ros2_ws/src/rosclaw_discovery/` | ROS2 node for capability auto-discovery |
| `rosclaw_msgs` | `ros2_ws/src/rosclaw_msgs/` | Custom ROS2 message/service definitions |
| `rosclaw_agent` | `ros2_ws/src/rosclaw_agent/` | ROS2 agent node for WebRTC ↔ DDS bridge (Mode C robot-side) |

### Transport Layer

The transport abstraction lives inside the plugin at `extensions/openclaw-plugin/src/transport/`. It supports three modes:

| Mode | Adapter | Description |
|---|---|---|
| `rosbridge` (default) | `transport/rosbridge/` | WebSocket to rosbridge_server (Mode B) |
| `local` | `transport/local/` | Direct DDS on same machine (Mode A — stub) |
| `webrtc` | `transport/webrtc/` | WebRTC data channel via signaling server (Mode C — stub) |

## Monorepo Structure

- **`extensions/`** — OpenClaw plugin extensions (pnpm workspaces)
- **`ros2_ws/`** — ROS2 colcon workspace
- **`docker/`** — Docker Compose and Dockerfiles
- **`examples/`** — Demo projects
- **`docs/`** — Architecture and design docs

## Key Commands

```bash
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

- **完整流程**: [`docs/skills/robot-adapter.md`](docs/skills/robot-adapter.md)
- **快速参考**: [`docs/skills/robot-adapter-quickref.md`](docs/skills/robot-adapter-quickref.md)
- **技能定义**: [`docs/skills/rosclaw-robot-adapter.skill.md`](docs/skills/rosclaw-robot-adapter.skill.md)

#### 核心步骤

1. **分析话题** - 使用 `ros2 topic list/info/hz/echo` 分析机器人接口
2. **设计映射** - 映射到 RosClaw 标准话题 (`/cmd_vel`, `/scan`, `/joint_states` 等)
3. **编写桥接** - 创建 ROS2 桥接节点 (Python)
4. **Docker 封装** - 创建 Dockerfile 和 docker-compose.yml
5. **插件配置** - 更新 `openclaw.plugin.json` 默认值
6. **验证测试** - 话题频率、端到端命令执行

#### 参考实现

- GO2 Gazebo: `docker/docker-compose.go2-gz.yml`
- 桥接节点：`ros2_ws/src/unitree_go2/unitree_go2/go2_gz_bridge.py`
- 机器人命令：`extensions/openclaw-plugin/src/tools/go2-commands.ts`
