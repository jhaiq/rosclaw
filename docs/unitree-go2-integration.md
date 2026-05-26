# Unitree GO2 机器狗集成指南

本文档介绍如何在 RosClaw 中集成和使用 Unitree GO2 四足机器人。

## 概述

RosClaw 支持通过自然语言控制 Unitree GO2 机器狗，包括：
- **仿真模式** - 在 Docker 容器中运行 GO2 控制节点
- **Gazebo 仿真模式** - 在 Gazebo Sim 中运行完整的物理仿真（需要 GPU）
- **硬件模式** - 直接控制真实的 GO2 机器狗

## 快速开始

### 仿真模式

```bash
# 1. 启动 GO2 控制节点
cd docker
make go2-start

# 2. 查看日志
make go2-logs

# 3. 停止节点
make go2-stop
```

### Gazebo 仿真模式

Gazebo 仿真模式提供完整的物理仿真环境，包括激光雷达、IMU、关节状态等传感器数据。

#### 前置条件

- Docker 和 Docker Compose
- NVIDIA GPU（推荐，用于 GPU 加速仿真）
- NVIDIA Container Toolkit

#### 环境变量配置

Gazebo 仿真支持以下环境变量：

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `GO2_WORLD` | `empty.world` | 世界文件 (`empty.world` 或 `rmuc_2025_world.sdf`) |
| `GO2_SENSORS` | `false` | 传感器仿真 (`true` 或 `false`) |
| `GO2_GUI` | `false` | GUI 模式 (`true` 启用 GUI，`false` 无头模式) |

**GUI 模式 vs 无头模式**：

- **无头模式**（`GO2_GUI=false`，默认）：适合服务器/容器部署，无需 X11 显示服务器
- **GUI 模式**（`GO2_GUI=true`）：适合本地开发调试，需要 X11 显示服务器支持

使用示例：
```bash
# 无头模式（默认）
docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# GUI 模式（本地调试）
GO2_GUI=true docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# 指定世界文件
GO2_WORLD=rmuc_2025_world.sdf docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

# 启用传感器仿真
GO2_SENSORS=true docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d
```

#### 启动仿真

```bash
# GPU 加速模式
make go2-gz-start

# CPU 模式（无 GPU 加速）
docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d
```

#### 验证仿真

```bash
# 运行验证脚本
./examples/go2-gz-sim/verify-simulation.sh

# 或手动检查
make go2-gz-status
make go2-gz-logs
```

#### 停止仿真

```bash
make go2-gz-stop

# 清理仿真数据
make go2-gz-clean
```

#### 仿真架构

```
┌─────────────────────────────────────────────────────┐
│                   go2_gz_sim                        │
│                  (Gazebo Sim)                       │
│  - 物理引擎                                         │
│  - 传感器仿真（激光雷达、IMU、关节编码器）              │
│  - 渲染引擎                                         │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│              go2_gz_bridge                          │
│              (AGIROS Python Node)                     │
│  - 话题映射：go2_gz_sim → RosClaw 标准话题           │
│  - /go2_gz_sim/odom → /go2_state/odom              │
│  - /go2_gz_sim/scan → /scan                        │
│  - /go2_gz_sim/imu → /go2_state/imu                │
│  - /cmd_vel → /go2_gz_sim/cmd_vel                  │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│              rosbridge_server                       │
│              (WebSocket Bridge)                     │
│  - ws://agiros:9090                                   │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│              OpenClaw Gateway                       │
│              (AI Agent)                             │
│  - 自然语言理解                                     │
│  - 工具调用：go2_stand, go2_sit, go2_move, ...     │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│              Messaging App                          │
│              (WhatsApp/Telegram/Discord)            │
└─────────────────────────────────────────────────────┘
```

#### 仿真话题映射表

| go2_gz_sim 话题 | RosClaw 标准话题 | 消息类型 | 说明 |
|----------------|-----------------|----------|------|
| `/robot1/cmd_vel` | `/cmd_vel` | `geometry_msgs/Twist` | 速度命令输入 |
| `/robot1/odom` | `/go2_state/odom` | `nav_msgs/Odometry` | 里程计数据 |
| `/robot1/scan` | `/scan` | `sensor_msgs/LaserScan` | 激光雷达数据 |
| `/robot1/imu_plugin/out` | `/go2_state/imu` | `sensor_msgs/Imu` | IMU 数据 |
| `/robot1/battery_state` | `/go2_state/battery` | `sensor_msgs/BatteryState` | 电池状态 |
| `/robot1/joint_states` | `/joint_states` | `sensor_msgs/JointState` | 关节状态 |

### 硬件模式

```bash
# 1. 配置机器人 IP
export GO2_MODE=hardware
export GO2_ROBOT_IP=192.168.123.2

# 2. 启动控制节点
make go2-hardware

# 或直接使用
GO2_MODE=hardware make go2-start
```

## 系统架构

```
用户 (消息应用)
    │
    ▼
OpenClaw Gateway (AI 智能体)
    │
    ▼
RosClaw 插件
    │
    ▼
rosbridge_server (WebSocket: ws://agiros:9090)
    │
    ▼
unitree_go2_node (AGIROS Python 节点)
    │
    ├──► /cmd_vel ──────────► 速度控制
    ├──► /go2_command/stand ─► 站立
    ├──► /go2_command/sit ───► 坐下
    │
    └──◄ /go2_state/battery ◄── 电池状态
    └──◄ /go2_state/imu ◄────── IMU 数据
    └──◄ /go2_state/foot_force ◄ 足端力
```

## 配置选项

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `GO2_MODE` | `simulation` | 运行模式：`simulation` 或 `hardware` |
| `GO2_ROBOT_IP` | `192.168.123.2` | GO2 机器人 IP 地址 |
| `GO2_MAX_LINEAR_VELOCITY` | `1.0` | 最大线速度 (m/s) |
| `GO2_MAX_ANGULAR_VELOCITY` | `2.0` | 最大角速度 (rad/s) |
| `GO2_ENABLED` | `false` | 是否在 docker compose 中启用 GO2 profile |

### AGIROS 参数

在 `agiros_ws/src/unitree_go2/config/go2_params.yaml` 中配置：

```yaml
/unitree_go2_node:
  ros__parameters:
    robot_name: "GO2"
    max_linear_velocity: 1.0
    max_angular_velocity: 2.0
    state_publish_rate: 10.0
    connection_timeout: 5.0
```

## 自然语言命令示例

### 基本运动

| 用户输入 | 执行操作 |
|----------|----------|
| "向前走 1 米" | 发布 `/cmd_vel` (x=0.5, z=0) 持续 2 秒 |
| "向后移动" | 发布 `/cmd_vel` (x=-0.3, z=0) |
| "向左转 90 度" | 发布 `/cmd_vel` (z=0.5) 直到转向完成 |
| "向右转" | 发布 `/cmd_vel` (z=-0.5) |
| "停止" | 发布 `/cmd_vel` (x=0, z=0) |

### 动作控制

| 用户输入 | 执行操作 |
|----------|----------|
| "站起来" | 调用 `/robot1/robot_behavior_command` (command: "up") |
| "坐下" | 调用 `/robot1/robot_behavior_command` (command: "sit") |
| "趴下" | 调用 `/robot1/robot_behavior_command` (command: "sit") |
| "开始走" | 调用 `/robot1/robot_behavior_command` (command: "walk") |

### GO2 行为命令详解

AGIROS-Gazebo-GO2 仿真支持官方行为命令接口，通过服务调用实现：

**服务名称**: `/robot1/robot_behavior_command`
**服务类型**: `quadropted_msgs/srv/RobotBehaviorCommand`

**支持的动作**:
| 命令 | 说明 | 控制器模式 | 身体高度 |
|------|------|-----------|---------|
| `sit` | 坐下/趴下 | REST 模式 | -0.15m |
| `up` | 站立 | STAND 模式 | 0.0m |
| `walk` | 行走模式 | TROT 模式 | 0.0m |

**使用示例**:
```bash
# 坐下
agiros service call /robot1/robot_behavior_command quadropted_msgs/srv/RobotBehaviorCommand "{command: 'sit'}"

# 站起
agiros service call /robot1/robot_behavior_command quadropted_msgs/srv/RobotBehaviorCommand "{command: 'up'}"

# 开始行走
agiros service call /robot1/robot_behavior_command quadropted_msgs/srv/RobotBehaviorCommand "{command: 'walk'}"
```

**在 OpenClaw 中使用**:
```
/robot-adapt start -n "GO2" -t simulation
# 然后使用自然语言命令：
"让机器人坐下"
"站起来"
"开始行走"
"向前移动 1 米"
```

### 状态查询

| 用户输入 | 查询内容 |
|----------|----------|
| "电池电量多少？" | 读取 `/go2_state/battery` |
| "平衡状态如何？" | 读取 `/go2_state/imu` |
| "你的位置在哪？" | 读取 `/go2_state/odom` |

## AGIROS 话题列表

### 订阅 (Subscribed)

```bash
# 查看订阅的话题
agiros topic list | grep cmd_vel
agiros topic list | grep go2_command

# 发布测试命令
agiros topic pub /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.5}, angular: {z: 0.0}}"
agiros topic pub /go2_command/stand std_msgs/msg/Empty
```

### 发布 (Published)

```bash
# 查看发布的话题
agiros topic list | grep go2_state

# 监听状态
agiros topic echo /go2_state/battery
agiros topic echo /go2_state/imu
```

## 部署

### Docker Compose

使用 `--profile go2` 启动 GO2 服务：

```bash
# 启动所有服务包括 GO2
docker compose --profile go2 up -d

# 仅启动 GO2 节点
docker compose --profile go2 up -d go2-node

# 查看状态
docker compose --profile go2 ps
```

### 本地构建 AGIROS 包

```bash
cd agiros_ws
source /opt/agiros/pixiu/setup.sh
colcon build --packages-select unitree_go2
source install/setup.bash

# 测试启动
agiros launch unitree_go2 go2_launch.py
```

## 硬件集成

### 网络连接

GO2 机器狗默认配置：
- IP 地址：`192.168.123.2`
- 子网掩码：`255.255.255.0`
- 端口：`8080` (API), `8081` (Sport 模式)

### 控制机配置

确保控制机和 GO2 在同一网络：

```bash
# 设置控制机 IP (示例)
sudo ip addr add 192.168.123.100/24 dev eth0

# 测试连接
ping 192.168.123.2
```

### Unitree SDK 安装

对于真实硬件控制，需要安装 Unitree SDK2：

```bash
# 克隆 SDK
git clone https://github.com/unitreerobotics/unitree_sdk2.git
cd unitree_sdk2

# 构建
mkdir build && cd build
cmake ..
make -j4
sudo make install
```

## 故障排查

### 问题 1: GO2 节点无法启动

```bash
# 检查 AGIROS 包是否构建
agiros pkg list | grep unitree_go2

# 重新构建
cd agiros_ws
colcon build --packages-select unitree_go2
source install/setup.bash

# 查看日志
agiros launch unitree_go2 go2_launch.py --show-log
```

### 问题 2: 无法连接到 GO2 硬件

```bash
# 检查网络
ping 192.168.123.2

# 检查端口
nc -zv 192.168.123.2 8080

# 确认 IP 配置
echo $GO2_ROBOT_IP
```

### 问题 3: 话题没有数据

```bash
# 列出所有节点
agiros node list

# 检查话题
agiros topic list

# 查看话题信息
agiros topic info /go2_state/battery --verbose
```

## 进阶功能

### SLAM 建图

```bash
# 启动 SLAM
agiros launch slam_toolbox online_async_launch.py

# 保存地图
agiros run nav2_map_server map_saver_cli -f my_map
```

### 自主导航

```bash
# 启动 Nav2
agiros launch nav2_bringup navigation_launch.py

# 发送导航目标
agiros action send_goal /navigate_to_pose nav2_msgs/action/NavigateToPose \
  "{pose: {header: {frame_id: 'map'}, pose: {position: {x: 1.0, y: 2.0}}}}"
```

### 视觉集成

如果 GO2 配备了摄像头：

```bash
# 启动摄像头驱动
agiros launch unitree_go2 camera_launch.py

# 查看图像
agiros run image_view image_view --topic /go2/camera/image
```

## 相关资源

- [Unitree GO2 官方文档](https://www.unitree.com/go2/)
- [Unitree SDK 2 GitHub](https://github.com/unitreerobotics/unitree_sdk2)
- [AGIROS Nav2 文档](https://navigation.ros.org/)
- [RosClaw 示例](../examples/go2-control/)

## 更新日志

- **0.0.1** (2026-03-20) - 初始版本，仿真模式支持
