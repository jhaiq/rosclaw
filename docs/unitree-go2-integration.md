# Unitree GO2 机器狗集成指南

本文档介绍如何在 RosClaw 中集成和使用 Unitree GO2 四足机器人。

## 概述

RosClaw 支持通过自然语言控制 Unitree GO2 机器狗，包括：
- **仿真模式** - 在 Docker 容器中运行 GO2 控制节点（未来集成 Gazebo/Isaac Sim）
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
rosbridge_server (WebSocket: ws://ros2:9090)
    │
    ▼
unitree_go2_node (ROS2 Python 节点)
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

### ROS2 参数

在 `ros2_ws/src/unitree_go2/config/go2_params.yaml` 中配置：

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
| "站起来" | 调用 `/go2_command/stand` |
| "坐下" | 调用 `/go2_command/sit` |
| "趴下" | 调用 `/go2_command/sit` |

### 状态查询

| 用户输入 | 查询内容 |
|----------|----------|
| "电池电量多少？" | 读取 `/go2_state/battery` |
| "平衡状态如何？" | 读取 `/go2_state/imu` |
| "你的位置在哪？" | 读取 `/go2_state/odom` |

## ROS2 话题列表

### 订阅 (Subscribed)

```bash
# 查看订阅的话题
ros2 topic list | grep cmd_vel
ros2 topic list | grep go2_command

# 发布测试命令
ros2 topic pub /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.5}, angular: {z: 0.0}}"
ros2 topic pub /go2_command/stand std_msgs/msg/Empty
```

### 发布 (Published)

```bash
# 查看发布的话题
ros2 topic list | grep go2_state

# 监听状态
ros2 topic echo /go2_state/battery
ros2 topic echo /go2_state/imu
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

### 本地构建 ROS2 包

```bash
cd ros2_ws
source /opt/ros/jazzy/setup.sh
colcon build --packages-select unitree_go2
source install/setup.bash

# 测试启动
ros2 launch unitree_go2 go2_launch.py
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
# 检查 ROS2 包是否构建
ros2 pkg list | grep unitree_go2

# 重新构建
cd ros2_ws
colcon build --packages-select unitree_go2
source install/setup.bash

# 查看日志
ros2 launch unitree_go2 go2_launch.py --show-log
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
ros2 node list

# 检查话题
ros2 topic list

# 查看话题信息
ros2 topic info /go2_state/battery --verbose
```

## 进阶功能

### SLAM 建图

```bash
# 启动 SLAM
ros2 launch slam_toolbox online_async_launch.py

# 保存地图
ros2 run nav2_map_server map_saver_cli -f my_map
```

### 自主导航

```bash
# 启动 Nav2
ros2 launch nav2_bringup navigation_launch.py

# 发送导航目标
ros2 action send_goal /navigate_to_pose nav2_msgs/action/NavigateToPose \
  "{pose: {header: {frame_id: 'map'}, pose: {position: {x: 1.0, y: 2.0}}}}"
```

### 视觉集成

如果 GO2 配备了摄像头：

```bash
# 启动摄像头驱动
ros2 launch unitree_go2 camera_launch.py

# 查看图像
ros2 run image_view image_view --topic /go2/camera/image
```

## 相关资源

- [Unitree GO2 官方文档](https://www.unitree.com/go2/)
- [Unitree SDK 2 GitHub](https://github.com/unitreerobotics/unitree_sdk2)
- [ROS2 Nav2 文档](https://navigation.ros.org/)
- [RosClaw 示例](../examples/go2-control/)

## 更新日志

- **0.0.1** (2026-03-20) - 初始版本，仿真模式支持
