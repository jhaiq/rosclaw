
# Unitree GO2 Gazebo 仿真示例

通过 RosClaw 和 OpenClaw 使用自然语言控制 Gazebo 仿真中的 GO2 机器狗。

## 前置条件

- Docker 和 Docker Compose
- NVIDIA GPU 和 Container Toolkit (可选，用于 GPU 加速)
- AGIROS loong (本地测试)

## 快速开始

### 1. 启动仿真

```sh
# GPU 模式
make go2-gz-start

# CPU 模式 (无 GPU 加速)
docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d
```

### 2. 验证仿真

```sh
./verify-simulation.sh
```

### 3. 控制机器人

通过 OpenClaw 发送自然语言命令：

- "向前走 1 米"
- "向左转 90 度"
- "站起来"
- "坐下"
- "电池电量多少？"

## 可用的 AGIROS 话题

| 话题 | 类型 | 说明 |
|------|------|------|
| `/cmd_vel` | `geometry_msgs/Twist` | 速度输入 |
| `/go2_command/stand` | `std_msgs/Empty` | 站立命令 |
| `/go2_command/sit` | `std_msgs/Empty` | 坐下命令 |
| `/go2_state/odom` | `nav_msgs/Odometry` | 里程计 |
| `/go2_state/battery` | `sensor_msgs/BatteryState` | 电池状态 |
| `/go2_state/imu` | `sensor_msgs/Imu` | IMU 数据 |
| `/scan` | `sensor_msgs/LaserScan` | 激光雷达 |

## 仿真架构

```
┌─────────────────┐
│  go2_gz_sim     │  Gazebo 仿真环境
│  (Gazebo)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  go2_gz_bridge  │  话题桥接节点
│  (ROS2 Node)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  rosbridge      │  WebSocket 桥接
│  (WebSocket)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  OpenClaw       │  AI 网关
│  (Node.js)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Messaging App  │  WhatsApp/Telegram
│  (User)         │
└─────────────────┘
```

## Make 命令

| 命令 | 说明 |
|------|------|
| `make go2-gz-start` | 启动仿真 |
| `make go2-gz-stop` | 停止仿真 |
| `make go2-gz-logs` | 查看日志 |
| `make go2-gz-status` | 查看状态 |
| `make go2-gz-clean` | 清理仿真数据 |

## 故障排查

### 仿真无法启动

```sh
# 查看日志
make go2-gz-logs

# 检查 GPU 支持
docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu22.04 nvidia-smi
```

### 话题不可用

```sh
# 列出所有节点
agiros node list

# 列出所有话题
agiros topic list

# 检查桥接节点
agiros run rqt_node rqt_node
```

### Docker 网络问题

```sh
# 重启网络
cd docker
docker compose down
docker compose up -d
```
