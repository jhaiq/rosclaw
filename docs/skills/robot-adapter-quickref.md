# RosClaw 机器人适配快速参考卡

## 一句话流程

**分析话题** → **设计映射** → **编写桥接** → **Docker 封装** → **插件配置** → **验证测试**

---

## 快速检查清单

### 阶段 1: 分析 (30 分钟)

```bash
# 启动机器人/仿真后执行
agiros topic list                    # 列出所有话题
agiros topic info /topic --verbose   # 查看话题类型
agiros topic hz /topic               # 测量发布频率
agiros topic echo /topic --once      # 查看消息内容
```

输出记录模板:
| 话题名 | 消息类型 | 频率 | 方向 | 用途 |
|--------|----------|------|------|------|
| /robot/odom | nav_msgs/Odometry | 30Hz | 机器人→ | 里程计 |
| /robot/cmd_vel | geometry_msgs/Twist | - | →机器人 | 速度控制 |

---

### 阶段 2: 设计映射 (15 分钟)

RosClaw 标准话题对照表:

| 功能 | RosClaw 标准话题 | 消息类型 |
|------|-----------------|----------|
| 里程计 | `/go2_state/odom` | nav_msgs/Odometry |
| 激光雷达 | `/scan` | sensor_msgs/LaserScan |
| 关节状态 | `/joint_states` | sensor_msgs/JointState |
| IMU | `/go2_state/imu` | sensor_msgs/Imu |
| 电池 | `/go2_state/battery` | sensor_msgs/BatteryState |
| 速度命令 | `/cmd_vel` | geometry_msgs/Twist |

---

### 阶段 3: 桥接节点 (60 分钟)

最小可用桥接节点模板 (`bridge_node.py`):

```python
#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from nav_msgs.msg import Odometry

class RobotBridge(Node):
    def __init__(self):
        super().__init__('robot_bridge')

        # 订阅: 机器人原生话题 → 转发到 RosClaw 标准话题
        self.odom_sub = self.create_subscription(
            Odometry, '/robot/odom', self.odom_callback, 10)
        self.odom_pub = self.create_publisher(
            Odometry, '/rosclaw/odom', 10)

        # 订阅：RosClaw 标准话题 → 转发到机器人
        self.cmd_vel_sub = self.create_subscription(
            Twist, '/cmd_vel', self.cmd_vel_callback, 10)
        self.cmd_vel_pub = self.create_publisher(
            Twist, '/robot/cmd_vel', 10)

    def odom_callback(self, msg): self.odom_pub.publish(msg)
    def cmd_vel_callback(self, msg): self.cmd_vel_pub.publish(msg)

def main():
    rclpy.init()
    node = RobotBridge()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__': main()
```

---

### 阶段 4: Docker 封装 (30 分钟)

最小可用 docker-compose.yml:

```yaml
services:
  robot:
    image: ros:loong-ros-base
    command: >
      bash -c "source /opt/agiros/loong/setup.sh &&
               agiros launch robot_bringup robot_launch.py"
    network_mode: host  # 或使用 networks
    environment:
      - ROS_DOMAIN_ID=0

  rosbridge:
    image: ros:loong-ros-base
    ports:
      - "9090:9090"
    command: >
      bash -c "source /opt/agiros/loong/setup.sh &&
               agiros launch rosbridge_server rosbridge_websocket_launch.xml"
    network_mode: host
```

---

### 阶段 5: 插件配置 (15 分钟)

更新 `openclaw.plugin.json`:

```json
{
  "rosbridge": {
    "url": { "default": "ws://localhost:9090" }
  },
  "robot": {
    "name": { "default": "Robot Name" }
  }
}
```

---

### 阶段 6: 验证 (30 分钟)

```bash
# 1. 检查话题是否存在
agiros topic list | grep rosclaw

# 2. 检查话题频率
agiros topic hz /rosclaw/odom

# 3. 检查数据类型
agiros topic info /rosclaw/odom --verbose

# 4. OpenClaw 测试命令
"请机器人向前移动 1 米"
```

---

## 常见问题速查

| 错误 | 快速解决 |
|------|----------|
| `package not found` | `export COLCON_CURRENT_PREFIX=/opt/workspace/install` |
| `无法连接到 rosbridge` | 检查 URL 是 `ws://localhost:9090` 不是内部 hostname |
| `malformed launch argument` | 使用 `arg:=value` 格式 |
| GUI 不显示 | 挂载 `/tmp/.X11-unix` 和设置 `DISPLAY` |

---

## 文件结构模板

```
robot-integration/
├── docker/
│   ├── Dockerfile.robot
│   ├── docker-compose.robot.yml
│   └── scripts/
│       └── entrypoint.sh
├── agiros_ws/
│   └── src/robot_bringup/
│       ├── CMakeLists.txt
│       ├── package.xml
│       ├── launch/
│       │   └── robot_launch.py
│       └── robot_bringup/
│           ├── __init__.py
│           └── bridge_node.py
└── extensions/
    └── openclaw-plugin/
        ├── openclaw.plugin.json
        └── src/tools/
            └── robot-commands.ts
```

---

## 时间估算

| 阶段 | 简单机器人 | 复杂机器人 |
|------|-----------|-----------|
| 分析 | 30 分钟 | 2 小时 |
| 设计映射 | 15 分钟 | 30 分钟 |
| 桥接节点 | 1 小时 | 4 小时 |
| Docker 封装 | 30 分钟 | 2 小时 |
| 插件配置 | 15 分钟 | 1 小时 |
| 验证测试 | 30 分钟 | 2 小时 |
| **总计** | **~3 小时** | **~12 小时** |

---

## GO2 Gazebo 参考值

```bash
# 话题频率参考
/go2_state/odom    → 29.5 Hz
/scan              → 10 Hz
/joint_states      → 50 Hz
/go2_state/imu     → 100 Hz
/go2_state/battery → 1 Hz

# Docker 服务
rosclaw-go2-gz-sim   (Gazebo 仿真)
rosclaw-go2-bridge   (话题桥接)
rosclaw-rosbridge    (WebSocket 服务)
```

---

## 核心原则

1. **不修改原始机器人代码** - 通过桥接层隔离
2. **使用标准话题** - 遵循 RosClaw 话题规范
3. **Docker 隔离** - 避免污染主机环境
4. **配置驱动** - 通过 plugin.json 管理差异
5. **验证优先** - 每步完成后立即验证
