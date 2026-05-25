
# Unitree GO2 机器狗控制 Demo

通过 RosClaw 和 OpenClaw 使用自然语言控制 Unitree GO2 机器狗。支持仿真模式和真实硬件控制。

## 功能特性

- **自然语言控制** - 通过 WhatsApp、Telegram、Discord 或 Slack 发送指令
- **运动控制** - 前后移动、转向、蹲下、站立
- **状态监测** - 电池电量、IMU 数据、足端力反馈
- **双模式支持** - 仿真模式和真实硬件控制

## 前置条件

### 仿真模式
- Docker 和 Docker Compose
- OpenClaw 实例（已配置通信渠道）

### 真实硬件模式
- Unitree GO2 机器狗
- Unitree 官方 SDK (`unitree_sdk2`)
- 机器人网络连接

## 快速开始

### 仿真模式

1. **启动 RosClaw 和 GO2 仿真**
```sh
   cd docker
   GO2_MODE=simulation docker compose up -d agiros go2-node
```

2. **配置 OpenClaw 插件**
   ```
   rosbridge URL: ws://localhost:9090
   机器人名称：Unitree GO2 (Sim)
   传输模式：rosbridge
   ```

3. **发送控制指令**
   - "向前走 1 米"
   - "向左转 90 度"
   - "站起来"
   - "坐下"
   - "电池电量还有多少？"

### 真实硬件模式

1. **配置机器人连接**
```sh
   export GO2_MODE=hardware
   export GO2_ROBOT_IP=192.168.123.2  # GO2 默认 IP
```

2. **启动 GO2 控制节点**
```sh
   agiros launch unitree_go2 go2_launch.py mode:=hardware
```

3. **启动 OpenClaw 和 RosClaw**
```sh
   cd docker
   docker compose up -d
```

## 可用命令

| 自然语言指令 | AGIROS 操作 | 说明 |
|-------------|----------|------|
| "向前走 1 米" | 发布 `/cmd_vel` | 线速度控制 |
| "向后移动" | 发布 `/cmd_vel` | 反向移动 |
| "向左转" | 发布 `/cmd_vel` | 角速度控制 |
| "向右转" | 发布 `/cmd_vel` | 角速度控制 |
| "站起来" | 调用 `/go2_command/stand` | 站立动作 |
| "坐下" | 调用 `/go2_command/sit` | 坐下动作 |
| "电池电量" | 读取 `/go2_state/battery` | 电池状态 |
| "平衡状态" | 读取 `/go2_state/imu` | IMU 数据 |

## AGIROS 接口

### 订阅的话题 (Subscribed Topics)

| 话题 | 类型 | 说明 |
|------|------|------|
| `/cmd_vel` | `geometry_msgs/Twist` | 速度指令 |
| `/go2_command/stand` | `std_msgs/Empty` | 站立命令 |
| `/go2_command/sit` | `std_msgs/Empty` | 坐下命令 |
| `/go2_command/stop` | `std_msgs/Empty` | 紧急停止 |

### 发布的话题 (Published Topics)

| 话题 | 类型 | 说明 |
|------|------|------|
| `/go2_state/battery` | `sensor_msgs/BatteryState` | 电池状态 |
| `/go2_state/imu` | `sensor_msgs/Imu` | IMU 数据 |
| `/go2_state/foot_force` | `geometry_msgs/WrenchStamped` | 足端力 |
| `/go2_state/odom` | `nav_msgs/Odometry` | 里程计 |

### 服务 (Services)

| 服务 | 类型 | 说明 |
|------|------|------|
| `/go2_command/estop` | `std_srvs/Trigger` | 紧急停止 |

## 参数配置

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `GO2_MODE` | `simulation` | 运行模式：`simulation` 或 `hardware` |
| `GO2_ROBOT_IP` | `192.168.123.2` | GO2 机器人 IP 地址 |
| `GO2_MAX_VELOCITY` | `1.0` | 最大线速度 (m/s) |
| `GO2_MAX_ANGULAR_VELOCITY` | `2.0` | 最大角速度 (rad/s) |

### AGIROS 参数

```yaml
/unitree_go2_node:
  ros__parameters:
    max_linear_velocity: 1.0    # m/s
    max_angular_velocity: 2.0   # rad/s
    state_publish_rate: 10.0    # Hz
    connection_timeout: 5.0     # seconds
```

## 架构

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
rosbridge_server (WebSocket)
    │
    ▼
unitree_go2_node (ROS2)
    │
    ├─► /cmd_vel ──► 运动控制
    ├─► /go2_command/* ──► 动作控制
    └─► /go2_state/* ◄── 状态反馈
```

## 故障排查

### 问题 1: 无法连接到 GO2

**症状**: 节点启动后显示连接超时

**解决方案**:
```sh
# 检查网络连接
ping 192.168.123.2

# 检查 AGIROS 域 ID
export ROS_DOMAIN_ID=0

# 查看节点日志
agiros node info /unitree_go2_node
```

### 问题 2: 仿真模式无响应

**症状**: 发送命令后机器人不移动

**解决方案**:
```sh
# 检查话题连接
agiros topic echo /cmd_vel

# 验证节点状态
agiros node list

# 查看日志
agiros launch unitree_go2 go2_launch.py --show-log
```

## 进阶使用

### 自定义动作序列

```python
# 示例：执行一个舞蹈动作序列
agiros topic pub /go2_command/stand std_msgs/Empty
sleep 1
agiros topic pub /cmd_vel geometry_msgs/Twist "{linear: {x: 0.5}, angular: {z: 0.5}}"
sleep 2
agiros topic pub /cmd_vel geometry_msgs/Twist "{linear: {x: 0.0}, angular: {z: 0.0}}"
```

### 集成激光雷达

如果 GO2 配备了激光雷达：

```sh
# 启动 SLAM
agiros launch slam_toolbox online_async_launch.py

# 导航
agiros launch nav2_bringup navigation_launch.py
```

## 相关资源

- [Unitree GO2 官方文档](https://www.unitree.com/go2/)
- [Unitree SDK 2](https://github.com/unitreerobotics/unitree_sdk2)
- [RosClaw 文档](../../docs/)

## 许可证

Apache-2.0

