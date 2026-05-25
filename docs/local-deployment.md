# 本地部署说明

本文说明如何在本地部署并运行 RosClaw 项目（ROS2 + OpenClaw 插件 + rosbridge）。

## 前置条件

- **Node.js 20+**
- **pnpm 9+**（`corepack enable && corepack prepare pnpm@9.15.4 --activate`）
- **Docker 与 Docker Compose**（用于运行 AGIROS + rosbridge 仿真）

## 方式一：推荐 — 本机插件 + Docker 跑 ROS2

适合日常开发：ROS2 和 Gazebo 在 Docker 里跑，OpenClaw 和 RosClaw 插件在本机跑，通过 `ws://localhost:9090` 连接。

### 1. 安装依赖并构建

在仓库根目录执行：

```bash
pnpm install
pnpm build
```

### 2. 启动 AGIROS + rosbridge（Docker）

```bash
cd docker
docker compose up
```

或后台运行：

```bash
cd docker
docker compose up -d
```

这会：

- 构建并启动 **agiros** 服务：ROS2 Jazzy + rosbridge WebSocket（端口 **9090**）+ TurtleBot3 Gazebo 仿真
- 端口映射：`9090`（rosbridge）、`11311`（ROS）

首次构建镜像可能需几分钟。

### 3. 配置 OpenClaw 使用 RosClaw 插件

- 在你的 OpenClaw 实例中安装/启用 **RosClaw** 插件（指向本仓库的 `extensions/openclaw-plugin`）。
- 插件默认连接：**`ws://localhost:9090`**（与上面 Docker 暴露的 rosbridge 一致）。

若需修改连接地址或重连策略，可在 OpenClaw 的插件配置中设置（参见插件内的 `config` / 环境变量）。

### 4. 验证

在 OpenClaw 对话中可尝试：

- **「Move forward 1 meter」** — 向 `/cmd_vel` 发布速度
- **「What do you see?」** — 抓取相机画面
- **「Check the battery」** — 读取 `/battery_state`
- **`/estop`** — 紧急停止

---

## 方式二：仅本机（无 Docker）

若本机已安装 **ROS2 Jazzy** 和 **rosbridge_suite**，可以不用 Docker，直接在本机启动 rosbridge，插件同样连 `ws://localhost:9090`。

### 1. 安装 AGIROS 与 rosbridge（Ubuntu 示例）

```bash
# 安装 AGIROS Jazzy 后
sudo apt install ros-jazzy-rosbridge-suite
```

### 2. 启动 rosbridge

```bash
source /opt/agiros/pixiu/setup.bash
agiros launch rosbridge_server rosbridge_websocket_launch.xml
```

### 3. 本机构建并配置插件

与方式一相同：

```bash
pnpm install
pnpm build
```

在 OpenClaw 中配置 RosClaw 插件，连接 `ws://localhost:9090`。

---

## Docker Compose 说明

| 文件 | 用途 |
|------|------|
| `docker-compose.yml` | 默认：agiros 服务 + rosclaw 插件镜像（插件镜像为可选） |
| `docker-compose.local.yml` | 本机模式（Mode A）：同一机器上 LocalTransport，无网络 |
| `docker-compose.dev.yml` | 开发用 |
| `docker-compose.robot.yml` | 真机/机器人场景 |
| `docker-compose.cloud.yml` | 云/远程场景 |

只跑 AGIROS + rosbridge 时，只需：

```bash
cd docker
docker compose up agiros
```

仅启动 `agiros` 服务，不构建/启动 `rosclaw` 容器。

---

## 常见问题

- **端口 9090 被占用**：修改 `docker-compose.yml` 中 `agiros` 的端口映射，例如 `"9091:9090"`，并在插件配置中改为 `ws://localhost:9091`。
- **插件连不上**：确认 Docker 中 rosbridge 已启动（`docker compose logs agiros`），且本机防火墙未拦截 9090。
- **ROS2 镜像构建失败**：确保从仓库根目录作为构建上下文（当前 `docker-compose.yml` 已使用 `context: ..`、`dockerfile: docker/Dockerfile.agiros`）。

---

## 架构简图

```
用户 (WhatsApp / Telegram / Discord / Slack)
        |
        v
OpenClaw Gateway（AI Agent + 工具 + 记忆）
        |
        v  RosClaw 插件
rosbridge (WebSocket, 默认 ws://localhost:9090)
        |
        v  AGIROS DDS
机器人：Nav2、MoveIt2、相机、传感器等
```

完成以上任一种方式后，即可在本地用自然语言通过 OpenClaw 控制 AGIROS 机器人（仿真或真机）。

---

## 方式三：全容器化 — Docker 跑 OpenClaw + ROS2（已集成 RosClaw）

适合你已经确认 OpenClaw 容器化没问题，希望直接把 RosClaw 插件挂载进 OpenClaw 容器，并自动启用配置。

### 1. 一键启动（推荐）

在仓库根目录执行：

```bash
./scripts/openclaw_docker_setup.sh
```

它会：

- 生成 `docker/openclaw/.env`（包含 `OPENCLAW_GATEWAY_TOKEN`）
- （默认）运行一次 `openclaw onboard` 交互式向导
- 启动 `agiros + openclaw-gateway` 两个容器

然后打开 Control UI：`http://127.0.0.1:18789/`，使用 `docker/openclaw/.env` 里的 token 登录。

### 2. 跳过 onboard（非交互）

```bash
OPENCLAW_SKIP_ONBOARD=1 ./scripts/openclaw_docker_setup.sh
```

### 3. 手动启动（可选）

```bash
cd docker
docker compose --env-file openclaw/.env -f docker-compose.yml -f docker-compose.openclaw.yml up -d
```

### 配置在哪里？

- OpenClaw 配置模板：`docker/openclaw/openclaw.json`
  - 使用 `plugins.load.paths` 加载：`/home/node/rosclaw/extensions/openclaw-plugin`（容器内挂载的本仓库路径）
  - 启用 `plugins.entries.rosclaw`，并将 rosbridge 指向：`ws://agiros:9090`

