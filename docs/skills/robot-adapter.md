
---
name: robot-adapter
description: RosClaw 适配新机器人或仿真环境的完整流程与方法论
type: reference
---

# RosClaw 机器人适配 Skill

基于 Unitree GO2 Gazebo 仿真适配经验提炼的标准化适配流程。

## 一、适配流程图

```
┌─────────────────────────────────────────────────────────────────┐
│                    RosClaw 机器人适配流程                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  Step 1: 确定机器人类型和通信模式        │
        │  - 物理机器人 vs 仿真                    │
        │  - Mode A(本地 DDS) / B(rosbridge) / C(WebRTC) │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  Step 2: AGIROS 节点/话题分析              │
        │  - 列出所有发布的话题                   │
        │  - 列出所有订阅的话题                   │
        │  - 识别消息类型                         │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  Step 3: 话题映射设计                    │
        │  - 机器人原生话题 → RosClaw 标准话题     │
        │  - 设计桥接节点                         │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  Step 4: Docker 环境配置                 │
        │  - 创建 Dockerfile                      │
        │  - 创建 docker-compose.yml              │
        │  - 配置启动脚本                         │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  Step 5: OpenClaw 插件配置              │
        │  - 更新 plugin.json 默认值              │
        │  - 创建机器人专用工具 (可选)            │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  Step 6: 验证测试                        │
        │  - 话题频率测试                         │
        │  - 命令执行测试                         │
        │  - 端到端流程测试                       │
        └─────────────────────────────────────────┘
```

## 二、详细步骤

### Step 1: 确定机器人类型和通信模式

#### 通信模式选择

| 模式 | 名称 | 适用场景 | 配置位置 |
|------|------|----------|----------|
| **Mode A** | Local DDS | 开发机与 AGIROS 在同一机器 | `transport.mode: "local"` |
| **Mode B** | rosbridge | Docker 容器化部署 | `transport.mode: "rosbridge"` |
| **Mode C** | WebRTC | 远程机器人、低延迟需求 | `transport.mode: "webrtc"` |

#### GO2 Gazebo 案例

```yaml
# 使用 Mode B (rosbridge) - Docker 容器化部署
transport:
  mode: "rosbridge"
rosbridge:
  url: "ws://localhost:9090"  # OpenClaw 连接到此地址
```

### Step 2: AGIROS 节点/话题分析

#### 分析方法

```sh
# 1. 列出所有活跃话题
agiros topic list

# 2. 查看话题类型
agiros topic info /topic_name --verbose

# 3. 查看消息发布频率
agiros topic hz /topic_name

# 4. 查看消息内容示例
agiros topic echo /topic_name --once
```

#### GO2 Gazebo 话题清单

**Gazebo 仿真原生话题:**
```
/robot1/odometry/filtered    → nav_msgs/Odometry      (里程计)
/robot1/scan                 → sensor_msgs/LaserScan  (激光雷达)
/robot1/joint_states         → sensor_msgs/JointState (关节状态)
/robot1/imu_plugin/out       → sensor_msgs/Imu        (IMU)
/robot1/battery_state        → sensor_msgs/BatteryState (电池)
/robot1/cmd_vel              → geometry_msgs/Twist    (速度输入)
```

### Step 3: 话题映射设计

#### RosClaw 标准话题规范

| RosClaw 标准话题 | 消息类型 | 方向 | 描述 |
|-----------------|----------|------|------|
| `/go2_state/odom` | nav_msgs/Odometry | 机器人 → 插件 | 里程计状态 |
| `/scan` | sensor_msgs/LaserScan | 机器人 → 插件 | 激光雷达数据 |
| `/joint_states` | sensor_msgs/JointState | 机器人 → 插件 | 关节状态 |
| `/go2_state/imu` | sensor_msgs/Imu | 机器人 → 插件 | IMU 数据 |
| `/go2_state/battery` | sensor_msgs/BatteryState | 机器人 → 插件 | 电池状态 |
| `/cmd_vel` | geometry_msgs/Twist | 插件 → 机器人 | 速度命令 |

#### 桥接节点实现模板

```python
#!/usr/bin/env python3
"""
{机器人名称} 桥接节点 - 桥接机器人原生话题到 RosClaw 标准话题

subscribes:
  - /robot_native/topic1 (消息类型) - 描述
  - /robot_native/topic2 (消息类型) - 描述

publishes:
  - /agirosclaw/standard/topic1 (消息类型) - 描述
  - /agirosclaw/standard/topic2 (消息类型) - 描述
"""

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from nav_msgs.msg import Odometry
# 导入其他需要的消息类型


class {RobotName}Bridge(Node):
    """{机器人名称} 话题桥接节点."""

    def __init__(self):
        super().__init__('robot_bridge')

        # === 桥接订阅 (机器人 → RosClaw) ===
        self.odom_sub = self.create_subscription(
            Odometry,
            '/robot_native/odometry',  # 原生话题
            self.odom_callback,
            10
        )
        self.odom_pub = self.create_publisher(
            Odometry,
            '/agirosclaw/odom',  # RosClaw 标准话题
            10
        )

        # === 桥接发布 (RosClaw → 机器人) ===
        self.cmd_vel_sub = self.create_subscription(
            Twist,
            '/cmd_vel',  # RosClaw 标准输入
            self.cmd_vel_callback,
            10
        )
        self.cmd_vel_pub = self.create_publisher(
            Twist,
            '/robot_native/cmd_vel',  # 原生话题
            10
        )

        self.get_logger().info('{机器人名称} Bridge initialized')

    def cmd_vel_callback(self, msg: Twist):
        """转发速度命令到机器人."""
        self.cmd_vel_pub.publish(msg)

    def odom_callback(self, msg: Odometry):
        """转发里程计到 RosClaw."""
        self.odom_pub.publish(msg)


def main(args=None):
    rclpy.init(args=args)
    node = {RobotName}Bridge()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
```

### Step 4: Docker 环境配置

#### 4.1 创建 Dockerfile

```dockerfile
FROM agiros:loong-ros-base

# 安装依赖
RUN apt-get update && apt-get install -y \
    agiros-loong-rosbridge-server \
    agiros-loong-nav-msgs \
    agiros-loong-sensor-msgs \
    agiros-loong-geometry-msgs \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /opt/robot_workspace

# 复制桥接节点
COPY bridge_node.py /opt/robot_workspace/
COPY launch/ /opt/robot_workspace/launch/

# 创建入口脚本
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

#### 4.2 创建入口脚本

```sh
#!/bin/bash
set -e

export ROS_DISTRO=${ROS_DISTRO:-loong}

# Source AGIROS
source /opt/agiros/$ROS_DISTRO/setup.sh

# Source 机器人工作空间 (如果存在)
if [[ -f "/opt/robot_workspace/install/local_setup.sh" ]]; then
    source /opt/robot_workspace/install/local_setup.sh
    echo "Sourced robot workspace"
fi

# 设置环境变量
export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}

# 执行命令
exec "$@"
```

#### 4.3 创建 docker-compose.yml

```yaml
services:
  # 机器人仿真/驱动服务
  robot-sim:
    image: agirosclaw/robot-sim:latest
    container_name: agirosclaw-robot-sim
    environment:
      - ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
      - DISPLAY=${DISPLAY:-:0}
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
      - ${ROBOT_WORKSPACE_PATH:-/path/to/robot}:/opt/robot_workspace:ro
    networks:
      - agirosclaw-network
    profiles:
      - robot

  # 桥接节点服务
  robot-bridge:
    image: agirosclaw/robot-sim:latest
    container_name: agirosclaw-robot-bridge
    command: >
      bash -c "source /opt/agiros/loong/setup.sh &&
               source /opt/robot_workspace/install/local_setup.sh &&
               agiros launch robot_bridge bridge_launch.py"
    volumes:
      - ${ROBOT_WORKSPACE_PATH}:/opt/robot_workspace:ro
      - /path/to/agirosclaw/agiros_ws/install:/opt/agirosclaw/install:ro
    networks:
      - agirosclaw-network
    profiles:
      - robot
    depends_on:
      - robot-sim

  # ROSBridge 服务
  rosbridge:
    image: agirosclaw/robot-sim:latest
    container_name: agirosclaw-rosbridge
    ports:
      - "${ROSBRIDGE_PORT:-9090}:${ROSBRIDGE_PORT:-9090}"
    command: >
      bash -c "source /opt/agiros/loong/setup.sh &&
               source /opt/agirosclaw/install/setup.sh &&
               agiros launch rosbridge_server rosbridge_websocket_launch.xml"
    volumes:
      - /path/to/agirosclaw/agiros_ws/install:/opt/agirosclaw/install:ro
    networks:
      - agirosclaw-network
    profiles:
      - robot

networks:
  agirosclaw-network:
    external: true
    name: ${DOCKER_NETWORK_NAME:-1panel-network}
```

#### 4.4 关键问题解决方案

| 问题 | 症状 | 解决方案 |
|------|------|----------|
| COLCON_CURRENT_PREFIX | `package not found` 错误 | 在 sourcing 前设置 `export COLCON_CURRENT_PREFIX=/opt/workspace/install` |
| 硬编码路径 | local_setup.sh 包含开发机路径 | 使用 `local_setup.sh` 而非 `setup.sh`，避免硬编码 |
| 多工作空间 | 需要 source 多个工作空间 | 在 sourcing 之间切换 COLCON_CURRENT_PREFIX |
| X11 显示 | GUI 应用无法显示 | 挂载 `/tmp/.X11-unix` 并设置 `DISPLAY` 环境变量 |

### Step 5: OpenClaw 插件配置

#### 5.1 更新 plugin.json 默认值

```json
{
  "rosbridge": {
    "url": {
      "default": "ws://localhost:9090"  // Docker 外部访问地址
    }
  },
  "robot": {
    "name": {
      "default": "Robot Name (Simulation)"
    },
    "namespace": {
      "default": "/robot"
    }
  }
}
```

#### 5.2 创建机器人专用工具

在 `extensions/openclaw-plugin/src/tools/` 创建 `{robot}-commands.ts`:

```ts
import { Type } from "@sinclair/typebox";
import type { OpenClawPluginApi } from "../plugin-api.js";
import { getTransport } from "../service.js";

export function registerRobotCommand(api: OpenClawPluginApi): void {
  api.registerTool({
    name: "robot_command",
    label: "Robot Command",
    description: "Execute robot specific command",
    parameters: Type.Object({
      param: Type.Number({
        description: "Parameter description",
        default: 0,
      }),
    }),

    async execute(_toolCallId, params) {
      const transport = getTransport();

      // 发布到机器人特定话题
      await transport.publish({
        topic: "/robot/specific/topic",
        type: "std_msgs/msg/Float64",
        msg: { data: params.param },
      });

      const result = { success: true, message: "Command executed" };
      return {
        content: [{ type: "text", text: JSON.stringify(result) }],
        details: result,
      };
    },
  });
}
```

#### 5.3 在 tools/index.ts 中注册

```ts
import { registerRobotCommand } from "./robot-commands.js";

export function registerTools(api: OpenClawPluginApi): void {
  // ... 通用工具注册

  // 注册机器人专用工具
  const robotName = (api.pluginConfig?.robot?.name as string) ?? "";
  if (robotName.toLowerCase().includes("robot")) {
    registerRobotCommand(api);
  }
}
```

### Step 6: 验证测试

#### 6.1 话题频率测试

```sh
# 验证桥接节点发布的话题
agiros topic hz /go2_state/odom
agiros topic hz /scan
```

预期输出:
```
average rate: 29.500
  min: 0.030s max: 0.040s std dev: 0.005s window: 100 messages
```

#### 6.2 话题数据验证

```sh
# 查看话题数据类型
agiros topic info /go2_state/odom --verbose

# 查看实际数据
agiros topic echo /go2_state/odom --once
```

#### 6.3 端到端测试

```sh
# 1. 启动所有服务
docker compose -f docker-compose.robot.yml --profile robot up -d

# 2. 检查服务状态
docker compose -f docker-compose.robot.yml ps

# 3. 查看日志
docker compose -f docker-compose.robot.yml logs -f robot-bridge

# 4. 测试命令执行
# 在 OpenClaw 中输入自然语言命令观察机器人响应
```

## 三、GO2 Gazebo 适配实例

### 3.1 话题映射表

| Gazebo 原生话题 | RosClaw 标准话题 | 消息类型 | 方向 |
|----------------|-----------------|----------|------|
| `/robot1/odometry/filtered` | `/go2_state/odom` | nav_msgs/Odometry | Gazebo → RosClaw |
| `/robot1/scan` | `/scan` | sensor_msgs/LaserScan | Gazebo → RosClaw |
| `/robot1/joint_states` | `/joint_states` | sensor_msgs/JointState | Gazebo → RosClaw |
| `/robot1/imu_plugin/out` | `/go2_state/imu` | sensor_msgs/Imu | Gazebo → RosClaw |
| `/robot1/battery_state` | `/go2_state/battery` | sensor_msgs/BatteryState | Gazebo → RosClaw |
| `/cmd_vel` | `/robot1/cmd_vel` | geometry_msgs/Twist | RosClaw → Gazebo |

### 3.2 遇到的问题及解决方案

#### 问题 1: COLCON_CURRENT_PREFIX 不生效

**症状:**
```
Package 'gazebo_sim' not found: "package 'gazebo_sim' not found, searching: ['/opt/agiros/loong']"
```

**原因:** local_setup.sh 中硬编码了构建时的路径 `/home/ROS2/ROS2-Gazebo-GO2/install`

**解决方案:**
```sh
# 在 source 之前设置
export COLCON_CURRENT_PREFIX=/opt/go2_gz_sim/install
source /opt/go2_gz_sim/install/local_setup.sh
```

#### 问题 2: OpenClaw 无法连接到 rosbridge

**症状:**
```
⚠️ 无法连接到 TurtleBot3 模拟器 - 当前没有连接到 AGIROS 桥接服务器
```

**原因:** 默认 rosbridge URL 是 `ws://agiros:9090` (Docker 内部 hostname)

**解决方案:** 更新 openclaw.plugin.json:
```json
"rosbridge": {
  "url": {
    "default": "ws://localhost:9090"
  }
}
```

#### 问题 3: 启动参数格式错误

**症状:**
```
malformed launch argument 'world=rmuc_2025_world.sdf', expected format '<name>:=<value>'
```

**解决方案:** docker-compose command 中使用 `:=` 语法:
```yaml
command: agiros launch gazebo_sim launch.py world:=$$GO2_WORLD sensors:=$$GO2_SENSORS
```

#### 问题 4: 模型文件找不到

**症状:**
```
Unable to find uri[model://rmuc_2025]
```

**原因:** 世界文件引用的模型不在 GZ_SIM_RESOURCE_PATH 中

**解决方案:** 使用基础世界文件:
```yaml
environment:
  GO2_WORLD: "empty.world"  # 使用基础世界
```

## 四、检查清单

适配新机器人时，按以下清单逐项检查:

### 4.1 AGIROS 层

- [ ] 列出所有机器人发布的话题
- [ ] 列出所有机器人订阅的话题
- [ ] 确认所有消息类型
- [ ] 验证话题发布频率
- [ ] 确定是否需要桥接节点

### 4.2 Docker 层

- [ ] 创建 Dockerfile (或使用现有镜像)
- [ ] 创建 docker-compose.yml
- [ ] 配置入口脚本
- [ ] 设置正确的环境变量
- [ ] 配置 X11 显示 (如需 GUI)
- [ ] 配置 GPU 支持 (如需要)

### 4.3 话题桥接

- [ ] 桥接节点代码实现
- [ ] 话题映射正确
- [ ] 消息类型匹配
- [ ] 测试话题频率

### 4.4 OpenClaw 插件层

- [ ] 更新 plugin.json 默认配置
- [ ] 创建机器人专用工具 (可选)
- [ ] 配置 rosbridge URL
- [ ] 配置机器人名称

### 4.5 验证测试

- [ ] Docker 服务全部启动
- [ ] rosbridge WebSocket 可访问
- [ ] 话题频率正常 (>10Hz)
- [ ] 自然语言命令执行成功
- [ ] 机器人响应正确

## 五、环境变量规范

```sh
# 通用环境变量
export ROS_DOMAIN_ID=0              # AGIROS 域 ID
export ROSBRIDGE_PORT=9090          # rosbridge 端口

# 机器人特定环境变量
export ROBOT_WORKSPACE_PATH=/path/to/robot  # 机器人工作空间路径
export ROBOT_NAME="Robot Name"              # 机器人显示名称
export ROBOT_NAMESPACE="/robot"             # AGIROS 命名空间

# 仿真特定环境变量
export SIM_WORLD="world.sdf"        # 仿真世界文件
export SIM_SENSORS="true"           # 是否启用传感器
export DISPLAY=:0                   # X11 显示
```

## 六、快速启动命令

```sh
# 1. 构建镜像
docker compose -f docker-compose.robot.yml build

# 2. 启动服务
docker compose -f docker-compose.robot.yml --profile robot up -d

# 3. 查看状态
docker compose -f docker-compose.robot.yml ps

# 4. 查看日志
docker compose -f docker-compose.robot.yml logs -f

# 5. 停止服务
docker compose -f docker-compose.robot.yml --profile robot down
```

## 七、参考文件

- GO2 Gazebo 示例:
  - `docker/docker-compose.go2-gz.yml` - Docker Compose 配置
  - `docker/Dockerfile.go2-gz-sim` - Dockerfile
  - `docker/scripts/go2-gz-entrypoint.sh` - 入口脚本
  - `agiros_ws/src/unitree_go2/unitree_go2/go2_gz_bridge.py` - 桥接节点
  - `extensions/openclaw-plugin/src/tools/go2-commands.ts` - 机器人命令


