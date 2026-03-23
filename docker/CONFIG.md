# Docker Configuration Guide

## 快速开始

```bash
cd docker

# 1. 创建配置文件
cp .env.example .env

# 2. 验证配置
make validate

# 3. 启动服务
make start

# 4. 查看日志
make logs
```

## 使用 Makefile（推荐）

| 命令 | 说明 |
|------|------|
| `make help` | 显示所有可用命令 |
| `make setup` | 创建 .env 并生成配置 |
| `make start` | 启动所有服务 |
| `make stop` | 停止所有服务 |
| `make restart` | 重启所有服务 |
| `make down` | 停止并删除容器 |
| `make clean` | 删除所有状态（包括数据卷） |
| `make logs` | 跟踪日志 |
| `make ps` | 显示容器状态 |
| `make validate` | 验证 .env 配置 |
| `make gen-config` | 重新生成 openclaw.json |
| `make status` | 显示状态和配置 |
| `make build` | 从源码构建镜像 |
| `make pull` | 拉取最新镜像 |

## 配置文件说明

### 统一配置文件：`.env`

所有可配置的参数都集中在 `docker/.env` 文件中，修改此文件即可，无需修改其他地方。

```bash
# 从模板创建配置文件
cd docker
cp .env.example .env
```

### 配置项说明

#### 网络配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `DOCKER_NETWORK_NAME` | `1panel-network` | Docker 网络名称 |
| `DOCKER_NETWORK_EXTERNAL` | `true` | 是否使用外部网络 |

#### ROS2 配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `ROS_DOMAIN_ID` | `0` | ROS2 域 ID |
| `TURTLEBOT3_MODEL` | `burger` | TurtleBot3 型号 |
| `ROSBRIDGE_PORT` | `9090` | rosbridge WebSocket 端口 |
| `ROS_MASTER_PORT` | `11311` | ROS master 端口 |

#### OpenClaw 配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `OPENCLAW_PORT` | `18789` | OpenClaw Gateway 端口 |
| `OPENCLAW_LOG_LEVEL` | `info` | 日志级别 |
| `OPENCLAW_GATEWAY_TOKEN` | 自动生成 | 认证 token |

#### RosClaw 插件配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `ROSCLAW_TRANSPORT_MODE` | `rosbridge` | 传输模式 |
| `ROSCLAW_ROSBRIDGE_URL` | `ws://ros2:9090` | rosbridge URL |
| `ROSCLAW_ROBOT_NAME` | `TurtleBot3 (Sim)` | 机器人名称 |
| `ROSCLAW_RECONNECT` | `true` | 自动重连 |
| `ROSCLAW_RECONNECT_INTERVAL` | `3000` | 重连间隔 (ms) |

#### GO2 Gazebo 仿真配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `GO2_GZ_SIM_PATH` | `/home/jhq/work/code/go2_ws/go2_sim_ws/ROS2-Gazebo-GO2` | go2_gz_sim 源码路径 |
| `GO2_WORLD` | `empty.world` | 世界文件 (`empty.world` 或 `rmuc_2025_world.sdf`) |
| `GO2_SENSORS` | `false` | 传感器仿真 (`true` 或 `false`) |
| `GO2_GUI` | `false` | GUI 模式 (`true` 启用 GUI，`false` 无头模式) |
| `GO2_SIM_LAUNCH` | `launch.py` | 启动文件 (`launch.py` 或 `launch_sim.launch.py`) |
| `GO2_SCENE` | `none` | 场景模式 (`none`、`cartographer`、`navigation2`) |

**场景模式说明**：

| 场景模式 | 说明 | 启动的额外节点 |
|----------|------|---------------|
| `none` | 仅启动 Gazebo 仿真 | 无 |
| `cartographer` | 启动仿真 + Cartographer 建图 | `go2_cartographer.launch.py` |
| `navigation2` | 启动仿真 + Nav2 导航 | `go2_navigation2.launch.py` |

**使用示例**：
```bash
# 仅仿真
GO2_SCENE=none docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# 建图场景（仿真 + Cartographer）
GO2_SCENE=cargo docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# 导航场景（仿真 + Nav2）
GO2_SCENE=navigation2 docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d
```

### 世界文件加载要求

使用自定义世界文件（如 `rmuc_2025_world.sdf`）时，必须确保 `GZ_SIM_RESOURCE_PATH` 包含模型和世界文件的所有目录：

```bash
GZ_SIM_RESOURCE_PATH=/opt/go2_gz_sim/models:/opt/go2_gz_sim/src/gazebo_sim/models:/opt/go2_gz_sim/src/gazebo_sim/world
```

**模型 URI 解析**：
- 世界文件中使用 `model://rmuc_2025` 语法引用模型
- Gazebo 在 `GZ_SIM_RESOURCE_PATH` 指定的所有目录中查找模型
- 必须包含 `/opt/go2_gz_sim/src/gazebo_sim/models` 才能找到源码中的模型

**GUI 模式说明**：

- `GO2_GUI=false`（默认）：无头模式，适合服务器/容器部署
- `GO2_GUI=true`：GUI 模式，需要 X11 显示服务器支持，适合本地开发调试

使用示例：
```bash
# 无头模式
docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# GUI 模式
GO2_GUI=true docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d
```

## 使用方式

### 快速启动

```bash
cd docker
cp .env.example .env
# 按需编辑 .env 文件
./scripts/openclaw_docker_setup.sh
```

### 手动启动

```bash
cd docker

# 1. 生成配置文件
bash openclaw/generate-openclaw-config.sh

# 2. 启动服务
docker compose --env-file .env -f docker-compose.yml -f docker-compose.openclaw.yml up -d
```

### 查看日志

```bash
docker compose -f docker-compose.yml -f docker-compose.openclaw.yml logs -f
```

### 停止服务

```bash
docker compose --env-file .env -f docker-compose.yml -f docker-compose.openclaw.yml down
```

## 配置同步机制

所有配置文件都从 `docker/.env` 读取环境变量：

```
docker/.env  →  generate-openclaw-config.sh  →  openclaw/openclaw.json
          ↓
     docker-compose.yml
     docker-compose.openclaw.yml
          ↓
     容器启动时读取
```

修改 `.env` 后，重新运行 `openclaw_docker_setup.sh` 或手动执行以下步骤：

```bash
# 1. 重新生成 openclaw.json
bash docker/openclaw/generate-openclaw-config.sh

# 2. 重启容器
docker compose --env-file .env -f docker-compose.yml -f docker-compose.openclaw.yml up -d
```

## 常见配置场景

### 场景 1：使用 1Panel 网络（默认）

```env
DOCKER_NETWORK_NAME=1panel-network
DOCKER_NETWORK_EXTERNAL=true
```

### 场景 2：使用独立 Docker 网络

```env
DOCKER_NETWORK_NAME=rosclaw-network
DOCKER_NETWORK_EXTERNAL=false
```

### 场景 3：修改端口

```env
ROSBRIDGE_PORT=9091       # 修改 rosbridge 端口
OPENCLAW_PORT=18790       # 修改 OpenClaw 端口
```

### 场景 4：连接外部 ROS2

```env
ROSCLAW_TRANSPORT_MODE=rosbridge
ROSCLAW_ROSBRIDGE_URL=ws://192.168.1.100:9090  # 外部 ROS2 地址
```

### 场景 5：本地开发（无 Docker）

```env
ROSCLAW_ROSBRIDGE_URL=ws://localhost:9090
```

## 故障排除

### 检查配置是否生效

```bash
# 查看 openclaw.json
cat docker/openclaw/openclaw.json

# 查看容器环境变量
docker exec openclaw-gateway env | grep OPENCLAW

# 查看 ros2 服务
docker compose -f docker-compose.yml -f docker-compose.openclaw.yml ps
```

### 端口冲突

如果端口被占用，修改 `.env` 中的端口号：

```env
ROSBRIDGE_PORT=9091
OPENCLAW_PORT=18790
```

### 网络问题

确保两个容器在同一网络：

```bash
docker network inspect 1panel-network
```
