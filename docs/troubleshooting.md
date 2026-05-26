# RosClaw 问题排查指南

本文档记录在部署和使用 RosClaw 过程中遇到的常见问题及解决方案。

---

## 目录

- [Docker 网络问题](#docker-网络问题)
- [容器启动问题](#容器启动问题)
- [GPU 加速问题](#gpu-加速问题)
- [OpenClaw 插件问题](#openclaw-插件问题)
- [rosbridge 连接问题](#rosbridge-连接问题)
- [X11 显示问题](#x11-显示问题)
- [配置管理问题](#配置管理问题)

---

## Docker 网络问题

### 问题 1: 服务引用未定义的网络

**错误信息:**
```
service "agiros" refers to undefined network 1panel-network: invalid compose project
```

**原因:**
Docker Compose 中定义外部网络时，使用了变量作为网络名称键，导致网络无法正确识别。

**解决方案:**
```yaml
# 错误的配置
networks:
  ${DOCKER_NETWORK_NAME:-1panel-network}:
    external: ${DOCKER_NETWORK_EXTERNAL:-true}

# 正确的配置
networks:
  agirosclaw-network:
    external: true
    name: ${DOCKER_NETWORK_NAME:-1panel-network}
```

在服务引用中使用固定的网络名称：
```yaml
services:
  agiros:
    networks:
      - agirosclaw-network
```

**验证:**
```bash
docker compose config
docker network ls | grep 1panel-network
```

---

### 问题 2: 容器无法跨网络通信

**错误信息:**
```
WebSocket connection to 'ws://agiros:9090' failed
Error: connect ECONNREFUSED
```

**原因:**
OpenClaw 容器和 AGIROS 容器不在同一个 Docker 网络中。

**解决方案:**
1. 确保两个容器使用相同的外部网络：
```yaml
networks:
  agirosclaw-network:
    external: true
    name: 1panel-network
```

2. 或者手动将容器连接到现有网络：
```bash
docker network connect 1panel-network <container-name>
```

---

## 容器启动问题

### 问题 3: rosbridge 端口被占用

**错误信息:**
```
Bind for 0.0.0.0:9090 failed: port is already allocated
```

**原因:**
多个容器尝试绑定相同的端口。

**解决方案:**
```bash
# 停止占用端口的容器
docker compose stop agiros

# 启动新容器
docker compose --profile gpu up -d agiros-gpu
```

或者修改 `.env` 中的端口配置：
```bash
ROSBRIDGE_PORT=9091
```

---

### 问题 4: 容器创建后立即退出

**错误信息:**
容器状态显示 `Exited (0)` 或 `Exited (1)`

**原因:**
- 入口点脚本执行失败
- 必需的依赖服务未就绪
- 配置参数错误

**排查步骤:**
```bash
# 查看容器日志
docker compose logs agiros

# 检查容器退出码
docker ps -a | grep agiros

# 进入容器调试
docker run --rm -it agirosclaw/agiros:latest /bin/bash
```

---

## GPU 加速问题

### 问题 5: NVIDIA Container Toolkit 未安装

**错误信息:**
```
docker: Error response from daemon: could not select device driver "" with capabilities: [[gpu]]
```

**原因:**
系统未安装 NVIDIA Container Toolkit 或 Docker runtime 未配置。

**解决方案:**
```bash
# 安装 NVIDIA Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# 配置 Docker runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# 验证安装
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

---

### 问题 6: 容器内无法访问 GPU

**错误信息:**
```bash
docker exec agirosclaw-agiros-gpu nvidia-smi
# 命令失败或无输出
```

**原因:**
- 容器未正确配置 GPU 资源
- NVIDIA 可见设备未设置

**解决方案:**
确保 docker-compose.yml 包含：
```yaml
services:
  agiros-gpu:
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu, graphics, compute, utility]
```

---

## OpenClaw 插件问题

### 问题 7: 插件配置未生成

**错误信息:**
```
Plugin 'agirosclaw' not found in configuration
```

**原因:**
`openclaw.plugin.json` 文件未生成或路径错误。

**解决方案:**
```bash
# 重新生成插件配置
cd docker
make gen-plugin-config

# 或手动执行
bash ../extensions/openclaw-plugin/generate-plugin-config.sh

# 验证生成的文件
cat extensions/openclaw-plugin/openclaw.plugin.json
```

---

### 问题 8: 插件已注册但网关启动时不加载

**症状:**
```
http server listening (2 plugins: browser, memory-core)
# 预期：3 plugins: browser, memory-core, agirosclaw
```

CLI 显示插件已启用（`openclaw plugins list`），但 `http server listening` 日志中不包含 agirosclaw。

**原因:**
`openclaw.plugin.json` 缺少 `activation.onStartup` 字段。OpenClaw 的 `shouldConsiderForGatewayStartup` 函数检查插件 manifest 中的 `activation.onStartup`，非内置插件（`origin === "config"`）如果未设置此字段，会被排除在 `startup.pluginIds` 之外。

**解决方案:**
在 `extensions/openclaw-plugin/openclaw.plugin.json` 中添加：

```json
{
  "activation": {
    "onStartup": true
  }
}
```

**验证:**
```bash
# 重启容器后检查
docker logs 1Panel-openclaw-SRjc | grep "http server listening"
# 应显示 3 plugins: browser, memory-core, agirosclaw
```

---

### 问题 9: 插件加载失败

**错误信息:**
```
Failed to load plugin agirosclaw: Cannot find module '@agirosclaw/openclaw-plugin'
```

**原因:**
- 插件未构建
- 依赖未安装

**解决方案:**
```bash
# 安装依赖
pnpm install

# 构建插件
pnpm build

# 验证构建产物
ls -la extensions/openclaw-plugin/dist/
```

---

## rosbridge 连接问题

### 问题 9: WebSocket 连接失败

**错误信息:**
```
WebSocket connection to 'ws://localhost:9090' failed
Error in 'agirosclaw' service: Connection closed
```

**原因:**
- rosbridge_server 未启动
- 防火墙阻止连接
- URL 配置错误

**解决方案:**
```bash
# 检查 rosbridge 服务状态
docker compose ps agiros

# 查看 rosbridge 日志
docker compose logs agiros | grep rosbridge

# 测试 WebSocket 连接
wscat -c ws://localhost:9090

# 检查防火墙
sudo ufw status
sudo ufw allow 9090/tcp
```

---

### 问题 10: rosbridge 连接后断开

**错误信息:**
```
AGIROS transport disconnected
```

**原因:**
- 网络不稳定
- ROS_DOMAIN_ID 不匹配
- 心跳超时

**解决方案:**
1. 确保所有容器使用相同的 `ROS_DOMAIN_ID`：
```bash
# 在 .env 中设置
ROS_DOMAIN_ID=0
```

2. 启用重连机制：
```bash
ROSCLAW_RECONNECT=true
ROSCLAW_RECONNECT_INTERVAL=3000
```

---

## X11 显示问题

### 问题 11: Gazebo 无法显示

**错误信息:**
```
Error: Cannot open display: :0
```

**原因:**
- DISPLAY 环境变量未设置
- X11 socket 未挂载
- X11 权限不足

**解决方案:**
```bash
# 允许 Docker 访问 X11
xhost +local:docker

# 确保 docker-compose.yml 包含
environment:
  - DISPLAY=${DISPLAY:-:0}
  - QT_X11_NO_MITSHM=1
volumes:
  - /tmp/.X11-unix:/tmp/.X11-unix:rw
```

---

### 问题 12: Gazebo 渲染缓慢

**症状:**
Gazebo 仿真帧率低，卡顿明显。

**原因:**
- 使用 CPU 渲染而非 GPU
- 模型路径配置错误

**解决方案:**
```bash
# 使用 GPU 加速启动
make gpu-start

# 验证 GPU 使用
docker exec agirosclaw-agiros-gpu glxinfo | grep "OpenGL renderer"

# 设置正确的模型路径
GAZEBO_MODEL_PATH=/opt/agiros/pixiu/share/turtlebot3_gazebo/models
```

---

## 配置管理问题

### 问题 13: 环境变量未生效

**症状:**
修改 `.env` 后配置未变化。

**原因:**
- 容器未重启
- 配置文件未重新生成

**解决方案:**
```bash
# 重新生成配置
make gen-config

# 重启容器
docker compose down
docker compose up -d

# 验证环境变量
docker exec <container> env | grep ROSCLAW
```

---

### 问题 14: 配置文件格式错误

**错误信息:**
```
JSON parsing error in openclaw.json
```

**原因:**
- JSON 语法错误
- 缺少必需的字段

**解决方案:**
```bash
# 验证 JSON 格式
jq . docker/openclaw/openclaw.json
jq . extensions/openclaw-plugin/openclaw.plugin.json

# 重新生成配置
make gen-config
```

---

## 快速诊断命令

```bash
# 检查所有容器状态
docker compose ps

# 查看服务日志
docker compose logs -f

# 验证配置
docker compose config

# 检查网络连接
docker network inspect 1panel-network

# 测试 rosbridge
wscat -c ws://localhost:9090

# 验证 GPU
make verify-gpu

# 检查端口占用
netstat -tlnp | grep 9090
```

---

## 联系支持

如遇到未在此文档中列出的问题，请：
1. 收集相关日志：`docker compose logs > logs.txt`
2. 记录复现步骤
3. 提交 GitHub Issue
