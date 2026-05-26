# RosClaw 开发文档

<!-- AUTO-GENERATED: This file is generated from source code. Do not edit manually. -->

本文档由源代码自动生成，包含 RosClaw 项目的开发、部署和运维信息。

---

## 目录

- [项目概述](#项目概述)
- [命令参考](#命令参考)
- [环境变量](#环境变量)
- [Docker 服务](#docker-服务)
- [架构组件](#架构组件)

---

## 项目概述

**RosClaw** 是一个 AGIROS + OpenClaw 集成项目，通过 AI 智能体实现消息应用对 AGIROS 机器人的自然语言控制。

| 属性 | 值 |
|------|-----|
| 名称 | `agirosclaw` |
| 版本 | 0.0.1 |
| 类型 | ESM (Node.js 20+) |
| 包管理器 | pnpm 9.15.4 |
| 许可证 | Apache-2.0 |

---

## 命令参考

<!-- AUTO-GENERATED: Commands table -->

### 根目录命令 (pnpm)

| 命令 | 描述 |
|------|------|
| `pnpm build` | 构建所有 TypeScript 包 |
| `pnpm clean` | 清理构建产物 (dist, tsconfig.tsbuildinfo) |
| `pnpm lint` | 运行所有包的 lint 检查 |
| `pnpm typecheck` | TypeScript 类型检查（不输出文件） |

### Make 命令 (项目根目录)

| 命令 | 描述 |
|------|------|
| `make setup` | 安装依赖并创建 .env 配置文件 |
| `make build` | 构建所有 TypeScript 包 |
| `make typecheck` | TypeScript 类型检查 |
| `make clean` | 清理构建产物 |
| `make gen-config` | 从 docker/.env 生成所有配置文件 |
| `make gen-docker-config` | 仅生成 docker/openclaw.json |
| `make gen-plugin-config` | 仅生成插件配置文件 |
| `make docker-*` | 委托到 docker/Makefile 执行 Docker 操作 |

### Make 命令 (docker 目录)

| 命令 | 描述 |
|------|------|
| `make setup` | 创建 .env 并生成所有配置文件 |
| `make start` | 启动所有服务 (agiros + openclaw-gateway) |
| `make stop` | 停止所有服务 |
| `make restart` | 重启所有服务 |
| `make down` | 停止并移除容器和网络 |
| `make clean` | 停止并移除 volumes（重置所有状态） |
| `make logs` | 跟踪所有服务的日志 |
| `make logs-agiros` | 跟踪 agiros 服务日志 |
| `make logs-openclaw` | 跟踪 openclaw-gateway 日志 |
| `make gen-config` | 从 .env 重新生成 openclaw.json |
| `make gen-plugin-config` | 重新生成 openclaw.plugin.json |
| `make validate` | 验证 .env 配置 |
| `make ps` | 显示运行中的容器 |
| `make pull` | 拉取最新镜像 |
| `make build` | 从源码构建镜像 |
| `make gpu-start` | 启动 GPU 加速的 agiros 容器 |
| `make gpu-stop` | 停止 GPU 加速的 agiros 容器 |
| `make verify-gpu` | 验证 GPU 支持和配置 |
| `make status` | 显示状态和配置信息 |

<!-- END AUTO-GENERATED -->

---

## 环境变量

<!-- AUTO-GENERATED: Environment variables table -->

### 网络配置

| 变量 | 必填 | 默认值 | 描述 | 示例 |
|------|------|--------|------|------|
| `DOCKER_NETWORK_NAME` | 否 | `1panel-network` | Docker 网络名称 | `1panel-network` |
| `DOCKER_NETWORK_EXTERNAL` | 否 | `true` | 是否使用外部网络 | `true` |

### AGIROS 配置

| 变量 | 必填 | 默认值 | 描述 | 示例 |
|------|------|--------|------|------|
| `ROS_DOMAIN_ID` | 否 | `0` | AGIROS 域 ID | `0` |
| `TURTLEBOT3_MODEL` | 否 | `burger` | TurtleBot3 模型 | `burger`, `waffle`, `waffle_pi` |
| `ROSBRIDGE_PORT` | 否 | `9090` | rosbridge WebSocket 端口 | `9090` |
| `ROS_MASTER_PORT` | 否 | `11311` | ROS master 端口 | `11311` |
| `GAZEBO_MODEL_PATH` | - | `/opt/agiros/pixiu/share/turtlebot3_gazebo/models` | Gazebo 模型路径（容器内） | - |

### Unitree GO2 Gazebo 仿真配置

| 变量 | 必填 | 默认值 | 描述 | 示例 |
|------|------|--------|------|------|
| `GO2_GZ_SIM_ENABLED` | 否 | `false` | 启用 GO2 Gazebo 仿真 | `true`, `false` |
| `GO2_GZ_SIM_PATH` | 否 | `/opt/go2_gz_sim` | GO2 仿真源码路径 | `/home/user/AGIROS-Gazebo-GO2` |
| `GO2_WORLD` | 否 | `empty.world` | Gazebo 世界文件 | `empty.world`, `rmuc_2025_world.sdf` |
| `GO2_SENSORS` | 否 | `false` | 启用传感器（激光雷达、相机） | `true`, `false` |
| `DISPLAY` | 否 | `:0` | X11 显示变量（GUI 模式） | `:0` |
| `QT_X11_NO_MITSHM` | 否 | `1` | 禁用 MIT-SHM 扩展 | `1` |

### OpenClaw Gateway 配置

| 变量 | 必填 | 默认值 | 描述 | 示例 |
|------|------|--------|------|------|
| `OPENCLAW_PORT` | 否 | `18789` | OpenClaw Gateway 端口 | `18789` |
| `OPENCLAW_LOG_LEVEL` | 否 | `info` | 日志级别 | `debug`, `info`, `warn`, `error` |
| `OPENCLAW_STATE_DIR` | 否 | `/home/node/.openclaw` | 状态目录（容器内） | - |
| `OPENCLAW_GATEWAY_TOKEN` | 否 | (自动生成) | Gateway 认证令牌 | 留空自动生成 |

### RosClaw 插件配置

| 变量 | 必填 | 默认值 | 描述 | 示例 |
|------|------|--------|------|------|
| `ROSCLAW_TRANSPORT_MODE` | 否 | `rosbridge` | 传输模式 | `rosbridge`, `local`, `webrtc` |
| `ROSCLAW_ROSBRIDGE_URL` | 否 | `ws://agiros:9090` | rosbridge WebSocket URL | `ws://localhost:9090` |
| `ROSCLAW_ROBOT_NAME` | 否 | `TurtleBot3 (Sim)` | 机器人名称 | `TurtleBot3 (Sim)` |
| `ROSCLAW_RECONNECT` | 否 | `true` | 启用重连 | `true`, `false` |
| `ROSCLAW_RECONNECT_INTERVAL` | 否 | `3000` | 重连间隔 (ms) | `3000` |

### GPU 配置（Gazebo 仿真）

| 变量 | 必填 | 默认值 | 描述 | 示例 |
|------|------|--------|------|------|
| `ROSCLAW_ENABLE_GPU` | 否 | `false` | 启用 GPU 加速 | `true`, `false` |
| `NVIDIA_VISIBLE_DEVICES` | 否 | `all` | NVIDIA 可见设备 | `all`, `none`, `0` |
| `NVIDIA_DRIVER_CAPABILITIES` | 否 | `graphics,utility,compute` | NVIDIA 驱动能力 | `graphics,utility,compute` |

### X11 显示配置

| 变量 | 必填 | 默认值 | 描述 | 示例 |
|------|------|--------|------|------|
| `DISPLAY` | - | `:0` | X11 显示变量 | `:0` |
| `QT_X11_NO_MITSHM` | - | `1` | 禁用 MIT-SHM 扩展 | `1` |

<!-- END AUTO-GENERATED -->

---

## Docker 服务

### agiros (CPU 模式)

默认的 CPU-only AGIROS 容器，运行 rosbridge_server 和 Gazebo 仿真。

```yaml
服务名：agiros
镜像：agirosclaw/agiros:latest
端口：9090 (rosbridge), 11311 (ROS master)
网络：agirosclaw-network (外部)
```

### agiros-gpu (GPU 模式)

GPU 加速的 AGIROS 容器，需要 NVIDIA Container Toolkit。

```yaml
服务名：agiros-gpu
镜像：agirosclaw/agiros:latest
容器名：agirosclaw-agiros-gpu
网络别名：agiros
启动命令：docker compose --profile gpu up -d agiros-gpu
```

### GO2 Gazebo 仿真 (Unitree GO2)

Unitree GO2 机器狗的 Gazebo 仿真环境，包含三个服务：

| 服务 | 描述 | 端口 |
|------|------|------|
| `go2-gz-sim` | Gazebo 仿真服务器 | 8080 |
| `go2-bridge-node` | AGIROS 话题桥接节点 | - |
| `agiros` | rosbridge WebSocket 服务器 | 9090 |

**启动命令：**

```bash
# 启动 GO2 Gazebo 仿真
docker compose -f docker/docker-compose.go2-gz.yml --profile go2-gz up -d

# 指定世界文件（可选）
GO2_WORLD=empty.world docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# 启用传感器（激光雷达、相机）
GO2_SENSORS=true docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# 查看日志
docker compose -f docker-compose.go2-gz.yml --profile go2-gz logs -f

# 停止服务
docker compose -f docker-compose.go2-gz.yml --profile go2-gz down
```

**话题桥接：**

| Gazebo 话题 | RosClaw 标准话题 | 消息类型 |
|------------|-----------------|----------|
| `/robot1/odometry/filtered` | `/go2_state/odom` | nav_msgs/Odometry |
| `/robot1/scan` | `/scan` | sensor_msgs/LaserScan |
| `/robot1/joint_states` | `/joint_states` | sensor_msgs/JointState |
| `/robot1/imu_plugin/out` | `/go2_state/imu` | sensor_msgs/Imu |
| `/robot1/battery_state` | `/go2_state/battery` | sensor_msgs/BatteryState |
| `/cmd_vel` | `/robot1/cmd_vel` | geometry_msgs/Twist |

**环境要求：**

- 需要挂载 AGIROS-Gazebo-GO2 源码路径
- X11 显示服务器（GUI 模式可选）
- NVIDIA GPU 和 Container Toolkit（可选，用于 GPU 加速）

---

## 架构组件

### 扩展 (extensions/)

| 包 | 版本 | 描述 | 入口 |
|------|------|------|------|
| `@agirosclaw/openclaw-plugin` | 0.0.1 | OpenClaw 扩展，用于 AGIROS 机器人控制 | `./src/index.ts` |
| `@agirosclaw/openclaw-canvas` | 0.0.1 | 实时机器人仪表盘（Phase 3） | `./dist/index.js` |

### 依赖项

#### 核心依赖

| 包 | 用途 |
|------|------|
| `@sinclair/typebox` | JSON Schema 类型定义 |
| `node-datachannel` | WebRTC 数据通道支持 |
| `ws` | WebSocket 客户端/服务器 |
| `zod` | TypeScript 配置验证 |

#### 可选依赖

| 包 | 用途 |
|------|------|
| `rclnodejs` | AGIROS Node.js 客户端（本地模式） |

### AGIROS 包 (agiros_ws/src/)

| 包 | 描述 |
|------|------|
| `agirosclaw_discovery` | AGIROS 能力自动发现节点 |
| `agirosclaw_msgs` | 自定义 AGIROS 消息/服务定义 |
| `agirosclaw_agent` | AGIROS 代理节点（WebRTC ↔ DDS 桥接） |

---

## 快速开始

### 1. 环境准备

```bash
# 安装 Node.js 20+ 和 pnpm 9+
# 安装 Docker 和 NVIDIA Container Toolkit (GPU 模式可选)
```

### 2. 安装依赖

```bash
pnpm install
```

### 3. 配置环境

```bash
cd docker
cp .env.example .env
# 编辑 .env 文件配置环境变量
```

### 4. 生成配置

```bash
make gen-config
```

### 5. 启动服务

```bash
# CPU 模式
make start

# GPU 模式
make gpu-start
```

### 6. 验证连接

```bash
make status
docker logs 1Panel-openclaw-SRjc | grep "AGIROS transport connected"
```

---

## 相关文档

- [架构设计](architecture.md)
- [本地部署](local-deployment.md)
- [OpenClaw 集成](openclaw-integration.md)
- [GPU 加速](gpu-acceleration.md)
- [问题排查](troubleshooting.md)
