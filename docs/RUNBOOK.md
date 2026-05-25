# RosClaw 运维手册

<!-- AUTO-GENERATED: Runbook generated from Docker and deployment configurations -->

本文档提供 RosClaw 系统的部署、监控和故障排查指南。

---

## 目录

- [系统架构](#系统架构)
- [部署程序](#部署程序)
- [健康检查](#健康检查)
- [监控指标](#监控指标)
- [常见问题](#常见问题)
- [回滚程序](#回滚程序)

---

## 系统架构

### 组件拓扑

```
用户 (WhatsApp/Telegram/Discord/Slack)
        │
        ▼
OpenClaw Gateway (AI 智能体 + 工具)
        │
        ▼  RosClaw 插件
rosbridge_server (WebSocket 端口 9090)
        │
        ▼  AGIROS DDS
机器人：Nav2, MoveIt2, 摄像头，传感器
```

### 容器清单

| 容器 | 服务 | 端口 | 网络 | 描述 |
|------|------|------|------|------|
| `rosclaw-agiros-gpu` | agiros-gpu | 9090, 11311 | 1panel-network | AGIROS + rosbridge + Gazebo |
| `1Panel-openclaw-*` | openclaw | 18789 | 1panel-network | OpenClaw Gateway |

---

## 部署程序

### 前置检查

```bash
# 1. 验证 Docker 安装
docker --version
docker network ls

# 2. 验证 NVIDIA Container Toolkit (GPU 模式)
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi

# 3. 验证网络存在
docker network inspect 1panel-network
```

### 标准部署（CPU 模式）

```bash
# 1. 进入 docker 目录
cd docker

# 2. 配置环境
cp .env.example .env
# 编辑 .env 文件

# 3. 生成配置
make gen-config

# 4. 启动服务
make start

# 5. 验证部署
make status
make logs-agiros
```

### GPU 部署

```bash
# 1. 验证 GPU 支持
make verify-gpu

# 2. 启动 GPU 容器
make gpu-start

# 3. 验证 GPU 访问
docker exec rosclaw-agiros-gpu nvidia-smi
```

### 1Panel 集成部署

```bash
# 1. 确保网络已创建
docker network create 1panel-network 2>/dev/null || true

# 2. 设置环境变量
export DOCKER_NETWORK_NAME=1panel-network
export DOCKER_NETWORK_EXTERNAL=true

# 3. 部署 AGIROS 容器
make start

# 4. 连接 1Panel 网络
make connect-1panel
```

---

## 健康检查

### 端点检查

| 端点 | 描述 | 预期响应 |
|------|------|----------|
| `http://localhost:9090/` | rosbridge WebSocket | HTTP 400 (WebSocket only) |
| `http://localhost:18789/` | OpenClaw Gateway | HTTP 200 |
| `ws://agiros:9090` | rosbridge WebSocket (容器内) | WebSocket 连接成功 |

### 健康检查脚本

```bash
#!/bin/bash
# 检查 rosbridge
if docker exec rosclaw-agiros-gpu curl -s http://localhost:9090/ 2>&1 | grep -q "WebSocket"; then
    echo "[OK] rosbridge is running"
else
    echo "[FAIL] rosbridge not responding"
    exit 1
fi

# 检查 OpenClaw 连接
if docker logs 1Panel-openclaw-SRjc 2>&1 | grep -q "ROS2 transport connected"; then
    echo "[OK] OpenClaw connected to ROS2"
else
    echo "[WARN] OpenClaw not connected"
fi
```

### Docker Compose 健康检查

```bash
# 查看容器状态
make ps

# 检查特定容器
docker inspect rosclaw-agiros-gpu --format='{{.State.Status}}'
docker inspect 1Panel-openclaw-SRjc --format='{{.State.Status}}'
```

---

## 监控指标

### 关键日志模式

| 日志模式 | 含义 | 处理 |
|----------|------|------|
| `ROS2 transport connected` | 连接成功 | 正常 |
| `ROS2 transport disconnected` | 连接断开 | 检查网络 |
| `WebSocket error connecting` | 连接失败 | 检查 rosbridge |
| `Rosbridge WebSocket server started` | rosbridge 启动 | 正常 |

### 性能指标

| 指标 | 阈值 | 告警 |
|------|------|------|
| rosbridge 响应时间 | < 100ms | > 500ms |
| OpenClaw 重连频率 | < 1 次/分钟 | > 5 次/分钟 |
| GPU 显存使用 | < 6GB | > 7GB |
| 容器 CPU 使用 | < 80% | > 90% |

### 监控命令

```bash
# 实时日志
make logs

# GPU 状态
docker exec rosclaw-agiros-gpu nvidia-smi

# 网络连接
docker network inspect 1panel-network

# 资源使用
docker stats rosclaw-agiros-gpu 1Panel-openclaw-SRjc
```

---

## 常见问题

### 问题 1: rosbridge 连接失败

**症状**: `WebSocket error connecting to ws://agiros:9090`

**诊断**:
```bash
# 检查 agiros 容器
docker compose ps agiros

# 检查 DNS 解析
docker exec 1Panel-openclaw-SRjc getent hosts agiros

# 检查 rosbridge 进程
docker exec rosclaw-agiros-gpu ps aux | grep rosbridge
```

**解决方案**:
```bash
# 重启 agiros 容器
make restart

# 或重新连接网络
docker network disconnect 1panel-network rosclaw-agiros-gpu
docker network connect 1panel-network rosclaw-agiros-gpu

# 重启 OpenClaw
docker restart 1Panel-openclaw-SRjc
```

### 问题 2: 端口冲突

**症状**: `Bind for 0.0.0.0:9090 failed: port is already allocated`

**诊断**:
```bash
netstat -tlnp | grep 9090
```

**解决方案**:
```bash
# 停止占用端口的容器
make stop

# 或修改端口
echo "ROSBRIDGE_PORT=9091" >> .env
make restart
```

### 问题 3: GPU 容器无法访问

**症状**: GPU 容器启动后立即退出

**诊断**:
```bash
make verify-gpu
docker logs rosclaw-agiros-gpu
```

**解决方案**:
```bash
# 切换回 CPU 模式
make gpu-stop
make start

# 或修复 NVIDIA Container Toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### 问题 4: X11 显示问题

**症状**: Gazebo 无法显示界面

**解决方案**:
```bash
# 允许 Docker 访问 X11
xhost +local:docker

# 检查环境变量
echo $DISPLAY

# 检查 volume 挂载
docker inspect rosclaw-agiros-gpu | grep -A5 "Mounts"
```

---

## 回滚程序

### 从 GPU 回滚到 CPU

```bash
# 1. 停止 GPU 容器
make gpu-stop

# 2. 启动 CPU 容器
make start

# 3. 重启 OpenClaw 以刷新连接
docker restart 1Panel-openclaw-SRjc

# 4. 验证连接
make logs | grep "ROS2 transport"
```

### 从新版本回滚

```bash
# 1. 停止当前服务
make stop

# 2. 拉取旧版本镜像
docker pull rosclaw/agiros:<previous-version>

# 3. 更新 docker-compose.yml 指定版本
# image: rosclaw/agiros:<previous-version>

# 4. 重启服务
make start
```

### 紧急停止

```bash
# 立即停止所有服务
make down

# 强制停止并清理
make clean

# 重启
make setup
make start
```

---

## 联系支持

- 项目仓库：https://github.com/PlaiPin/rosclaw
- 问题排查：[troubleshooting.md](troubleshooting.md)
- 架构文档：[architecture.md](architecture.md)

---

<!-- END AUTO-GENERATED -->
