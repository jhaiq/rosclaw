
# OpenClaw 集成指南

本文说明如何将 RosClaw 插件集成到 OpenClaw 中（包括 1Panel 容器化部署）。

---

## 架构概览

```
用户 (WhatsApp / Telegram / Discord / Slack / Control UI)
        |
        v
OpenClaw Gateway (AI Agent + 工具 + 记忆)
        |
        v  RosClaw 插件
rosbridge (WebSocket, 默认 ws://localhost:9090 或 ws://ros2:9090)
        |
        v  ROS2 DDS
机器人：Nav2、MoveIt2、相机、传感器等
```

---

## 集成方式对比

| 方式 | 适用场景 | 复杂度 |
|------|----------|--------|
| 方式一：`openclaw plugin add` | 本地开发，已有 OpenClaw 实例 | 低 |
| 方式二：docker-compose + 卷挂载 | 1Panel 容器化部署 | 中 |
| 方式三：使用 `openclaw_docker_setup.sh` | 快速本地测试 | 低 |

---

## 方式一：使用 `openclaw plugin add` 命令

适合已有 OpenClaw 实例（本地安装或 1Panel 部署）。

### 步骤 1：构建 RosClaw 插件

```sh
cd /path/to/rosclaw
pnpm install
pnpm build
```

### 步骤 2：添加插件到 OpenClaw

```sh
# 从本地路径安装
openclaw plugins install /opt/rosclaw/extensions/openclaw-plugin

# 或从 npm 安装（如果已发布）
openclaw plugins install @rosclaw/rosclaw

```

### 步骤 3：配置 `openclaw.json`

编辑 OpenClaw 配置文件（通常位于 `~/.openclaw/openclaw.json`）：

```json
{
  "plugins": {
    "enabled": true,
    "allow": ["rosclaw"],
    "entries": {
      "rosclaw": {
        "enabled": true,
        "config": {
          "transport": { "mode": "rosbridge" },
          "rosbridge": {
            "url": "ws://localhost:9090",
            "reconnect": true,
            "reconnectInterval": 3000
          },
          "robot": { "name": "TurtleBot3 (Sim)" }
        }
      }
    }
  }
}
```

### 步骤 4：重启 OpenClaw

```sh
openclaw gateway restart
```

---

## 方式二：1Panel 容器化部署

适合使用 1Panel 管理 Docker 容器的生产环境。

### 前置条件

- 1Panel 已安装并运行
- RosClaw 仓库已克隆到服务器（例如 `/opt/rosclaw`）

### 场景 A：RosClaw 代码在 1Panel 服务器上（推荐）

如果 RosClaw 代码已经在 1Panel 服务器上（例如 `/home/1panel/workspace/rosclaw`），直接挂载即可。

#### 步骤 1：准备目录结构

```sh
# 在 1Panel 服务器上
mkdir -p /opt/rosclaw-stack
cd /opt/rosclaw-stack

# 克隆或复制 RosClaw 仓库（如果尚未存在）
git clone https://github.com/PlaiPin/rosclaw.git /opt/rosclaw
```

#### 步骤 2：创建 docker-compose.yml

在 1Panel **容器 > 编排 > 创建** 中，填写以下内容：

```yaml
version: "3.8"

services:
  # ROS2 + rosbridge_server + Gazebo 仿真
  ros2:
    image: rosclaw/ros2:latest
    ports:
      - "9090:9090"
      - "11311:11311"
    environment:
      - ROS_DOMAIN_ID=0
      - GAZEBO_MODEL_PATH=/opt/ros/jazzy/share/turtlebot3_gazebo/models
      - TURTLEBOT3_MODEL=burger
    networks:
      - rosclaw
    restart: unless-stopped

  # OpenClaw Gateway with RosClaw plugin
  openclaw-gateway:
    image: ghcr.io/openclaw/openclaw:latest
    container_name: openclaw-gateway
    ports:
      - "18789:18789"
    environment:
      - OPENCLAW_STATE_DIR=/home/node/.openclaw
      - OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN}
      - OPENCLAW_LOG_LEVEL=info
    volumes:
      # 持久化 OpenClaw 状态
      - openclaw_state:/home/node/.openclaw
      # 挂载 RosClaw 插件代码（服务器路径 -> 容器内路径）
      - /opt/rosclaw:/home/node/rosclaw:ro
      # 挂载配置文件
      - ./openclaw.json:/home/node/.openclaw/openclaw.json:ro
    command: ["openclaw", "gateway", "run", "--allow-unconfigured", "--port", "18789"]
    depends_on:
      - ros2
    networks:
      - rosclaw
    restart: unless-stopped

networks:
  rosclaw:
    driver: bridge

volumes:
  openclaw_state:
```

---

### 场景 B：RosClaw 代码在本地电脑，需要挂载到 1Panel 容器

如果 RosClaw 代码在你的本地电脑上，而 1Panel 在远程服务器上，有以下几种方案：

#### 方案 1：先上传代码到服务器（推荐）

使用 `scp` 或 `rsync` 将 RosClaw 代码上传到 1Panel 服务器：

```sh
# 在本地电脑执行
cd /path/to/rosclaw

# 方式 A: 使用 scp 打包上传
tar czf rosclaw.tar.gz extensions/ package.json pnpm-workspace.yaml tsconfig.base.json
scp rosclaw.tar.gz user@1panel-server:/opt/rosclaw/
ssh user@1panel-server "cd /opt/rosclaw && tar xzf rosclaw.tar.gz"

# 方式 B: 使用 rsync 同步
rsync -avz --exclude 'node_modules' --exclude 'dist' ./ user@1panel-server:/opt/rosclaw/
```

然后在 1Panel 中按 **场景 A** 配置挂载路径 `/opt/rosclaw`。

#### 方案 2：使用 1Panel 的文件管理功能

1. 登录 1Panel 控制台
2. 进入 **文件** 模块
3. 创建一个目录（如 `/opt/rosclaw`）
4. 通过 Web 界面上传 RosClaw 的 `extensions/` 目录和相关配置文件
5. 在编排配置中挂载该目录

#### 方案 3：使用 Git 在服务器拉取

在 1Panel 中创建一个 **定时任务** 或 **脚本**，在部署前自动拉取代码：

```sh
#!/bin/bash
set -euo pipefail

ROSCLAW_DIR="/opt/rosclaw"

if [ -d "$ROSCLAW_DIR" ]; then
  echo "更新现有仓库..."
  cd "$ROSCLAW_DIR"
  git pull origin main
else
  echo "克隆新仓库..."
  git clone https://github.com/PlaiPin/rosclaw.git "$ROSCLAW_DIR"
fi

# 如果插件需要构建
cd "$ROSCLAW_DIR"
pnpm install --frozen-lockfile
pnpm build
```

然后在 docker-compose.yml 中挂载 `/opt/rosclaw`。

#### 方案 4：使用开发模式 - 本地构建 + 远程镜像

如果你在本地开发 RosClaw 插件，可以构建镜像后推送到远程：

```sh
# 在本地构建插件镜像
cd /path/to/rosclaw
pnpm install
pnpm build

# 构建包含插件的自定义 OpenClaw 镜像
docker build -f docker/Dockerfile.rosclaw -t your-registry/rosclaw-plugin:latest .

# 推送到远程仓库（或使用 docker save/load）
docker push your-registry/rosclaw-plugin:latest
```

然后在 docker-compose.yml 中使用自定义镜像：

```yaml
services:
  openclaw-gateway:
    image: ghcr.io/openclaw/openclaw:latest
    # 或者使用包含插件的自定义镜像
    # image: your-registry/rosclaw-openclaw:latest
    volumes:
      - ./openclaw.json:/home/node/.openclaw/openclaw.json:ro
```

### 步骤 3：创建 openclaw.json 配置文件

在 `/opt/rosclaw-stack/openclaw.json` 创建：

```json
{
  "gateway": {
    "mode": "local",
    "port": 18789,
    "bind": "lan",
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_GATEWAY_TOKEN}"
    }
  },
  "plugins": {
    "enabled": true,
    "allow": ["rosclaw"],
    "load": {
      "paths": ["/home/node/rosclaw/extensions/openclaw-plugin"]
    },
    "entries": {
      "rosclaw": {
        "enabled": true,
        "config": {
          "transport": { "mode": "rosbridge" },
          "rosbridge": {
            "url": "ws://ros2:9090",
            "reconnect": true,
            "reconnectInterval": 3000
          },
          "robot": { "name": "TurtleBot3 (Sim)" }
        }
      }
    }
  },
  "agents": {
    "defaults": {
      "workspace": "~/.openclaw/workspace"
    }
  }
}
```

### 步骤 4：设置环境变量

在 1Panel 创建编排时，添加环境变量：

| 变量名 | 值 |
|--------|-----|
| `OPENCLAW_GATEWAY_TOKEN` | 随机安全字符串（例如 `openssl rand -hex 32`） |

### 步骤 5：部署并验证

1. 在 1Panel **容器 > 编排** 中点击 **创建**
2. 等待容器启动
3. 访问 `http://<服务器 IP>:18789/`
4. 使用设置的 token 登录 Control UI

---

## 方式三：使用快速启动脚本

适合本地快速测试（Docker + OpenClaw + RosClaw 一键启动）。

### 步骤

```sh
cd /path/to/rosclaw

# 一键启动（交互式 onboard）
./scripts/openclaw_docker_setup.sh

# 或跳过 onboard（非交互）
OPENCLAW_SKIP_ONBOARD=1 ./scripts/openclaw_docker_setup.sh
```

### 脚本自动完成：

- 生成 `docker/openclaw/.env`（包含 `OPENCLAW_GATEWAY_TOKEN`）
- 运行 OpenClaw onboarding 向导（可选）
- 启动 `ros2 + openclaw-gateway` 容器
- 输出 Control UI 地址和 token

### 访问

```
Control UI: http://127.0.0.1:18789/
Token: 见 docker/openclaw/.env
```

---

## 配置说明

### `openclaw.json` 关键字段

| 字段 | 说明 |
|------|------|
| `plugins.enabled` | 是否启用插件系统 |
| `plugins.allow` | 允许加载的插件白名单 |
| `plugins.load.paths` | 插件源码路径（容器内路径） |
| `plugins.entries.rosclaw.enabled` | 是否启用 RosClaw 插件 |
| `plugins.entries.rosclaw.config.transport.mode` | 传输模式：`rosbridge` / `local` / `webrtc` |
| `plugins.entries.rosclaw.config.rosbridge.url` | rosbridge WebSocket 地址 |

### 传输模式

| 模式 | 描述 | 适用场景 |
|------|------|----------|
| `rosbridge` | WebSocket 连接 rosbridge_server | 默认推荐，容器/本地通用 |
| `local` | 直接 DDS 通信 | 本机 ROS2 + OpenClaw 同机 |
| `webrtc` | WebRTC 数据通道 | 远程/真机机器人（开发中） |

---

## 常见问题

### 1. 插件加载失败

```
Error: Cannot find module '/home/node/rosclaw/extensions/openclaw-plugin'
```

**原因**：卷挂载路径不正确或目录不存在。

**解决**：确认 RosClaw 仓库已克隆到服务器，且 compose 文件中的挂载路径与实际一致。

---

### 2. 无法连接 rosbridge

```
WebSocket connection failed: ws://ros2:9090
```

**原因**：
- `ros2` 服务未启动
- 网络配置错误（两个容器不在同一网络）

**解决**：
```sh
docker compose ps          # 检查容器状态
docker compose logs ros2   # 查看 ros2 日志
docker network ls          # 确认网络存在
```

---

### 3. 端口冲突

```
Error: bind: address already in use
```

**解决**：修改 compose 文件中的端口映射：

```yaml
ports:
  - "9091:9090"  # 将 9090 改为 9091
```

并在 `openclaw.json` 中更新 rosbridge URL 为 `ws://localhost:9091`。

---

### 4. 1Panel 编排不显示

某些 1Panel 版本需要手动刷新浏览器或重新登录才能看到新创建的编排。

---

## 验证集成

在 OpenClaw Control UI 中尝试以下命令：

| 命令 | 预期结果 |
|------|----------|
| "Move forward 1 meter" | 发布 `/cmd_vel` 速度指令 |
| "What do you see?" | 获取相机画面 |
| "Check the battery" | 读取 `/battery_state` |
| `/estop` | 紧急停止 |

---

## 参考文档

- [本地部署说明](./local-deployment.md)
- [RosClaw 架构](../CLAUDE.md)
- [OpenClaw 官方文档](https://openclaw.ai/docs/)
- [1Panel 容器文档](https://1panel.cn/docs/v2/)

