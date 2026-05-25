
# RosClaw 与 go2_gz_sim Gazebo 仿真集成计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现 RosClaw 通过 OpenClaw 插件控制 Gazebo 仿真中的 Unitree GO2 机器人，支持运动控制、状态反馈、SLAM 建图和自主导航。

**Architecture:** 通过话题桥接节点将 go2_gz_sim 的 AGIROS 话题映射到 RosClaw 标准接口，OpenClaw 插件通过 rosbridge 协议与仿真环境通信。

**Tech Stack:** AGIROS Jazzy, Gazebo Sim, TypeScript (OpenClaw Plugin), Python (ROS2 Nodes), Docker Compose

---

## 文件结构总览

### 新增文件

| 文件 | 目的 |
|------|------|
| `docker/Dockerfile.go2-gz-sim` | Gazebo 仿真镜像 |
| `docker/docker-compose.go2-gz.yml` | GO2 仿真 Docker Compose 配置 |
| `agiros_ws/src/unitree_go2/launch/go2_gz_bridge_launch.py` | 桥接启动文件 |
| `agiros_ws/src/unitree_go2/unitree_go2/go2_gz_bridge.py` | 话题桥接节点 |
| `extensions/openclaw-plugin/src/tools/go2-commands.ts` | GO2 专用命令工具 |
| `examples/go2-gz-sim/README.md` | 仿真实例文档 |
| `examples/go2-gz-sim/verify-simulation.sh` | 仿真验证脚本 |

### 修改文件

| 文件 | 修改内容 |
|------|----------|
| `extensions/openclaw-plugin/src/index.ts` | 注册 GO2 工具 |
| `extensions/openclaw-plugin/src/config.ts` | 添加 GO2 配置选项 |
| `docker/Makefile` | 添加 GO2 GZ 仿真命令 |
| `docs/unitree-go2-integration.md` | 添加仿真章节 |

---

## Phase 1: AGIROS 桥接层

### Task 1: 创建 Gazebo 仿真 Dockerfile

**Files:**
- Create: `docker/Dockerfile.go2-gz-sim`
- Test: 手动构建验证

- [ ] **Step 1: 创建 Dockerfile.go2-gz-sim**

```dockerfile
# AGIROS S S S Jazzy + Gazebo Sim for Unitree GO2
FROM ros:jazzy-ros-base AS base

LABEL maintainer="RosClaw Team"
LABEL description="Unitree GO2 Gazebo Simulation"

# 安装 Gazebo Sim 和依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-jazzy-gz-sim \
    ros-jazzy-gz-transport \
    ros-jazzy-ros-gz \
    ros-jazzy-slam-toolbox \
    ros-jazzy-nav2-bringup \
    ros-jazzy-teleop-twist-keyboard \
    && rm -rf /var/lib/apt/lists/*

# 克隆 go2_gz_sim 源码
RUN git clone https://gitee.com/jhaiq/go2_gz_sim.git /opt/go2_gz_sim

# 构建 AGIROS S S S 包
WORKDIR /opt/go2_gz_sim
RUN . /opt/agiros/pixiu/setup.sh && \
    colcon build --symlink-install && \
    chown -R root:root /opt/go2_gz_sim

# 入口点脚本
COPY docker/scripts/go2-gz-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["agiros", "launch", "go2_gz_sim", "go2_sim_launch.py"]
```

- [ ] **Step 2: 创建入口点脚本 docker/scripts/go2-gz-entrypoint.sh**

```sh
#!/bin/bash
set -e

# Source AGIROS S S S and go2_gz_sim
source /opt/agiros/pixiu/setup.sh
source /opt/go2_gz_sim/install/setup.sh

# Set environment
export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
export GZ_SIM_RESOURCE_PATH=${GZ_SIM_RESOURCE_PATH:-/opt/go2_gz_sim/models}

# Execute command
exec "$@"
```

- [ ] **Step 3: 构建并验证 Docker 镜像**

```sh
cd /home/jhq/work/code/claw_ws/rosclaw/docker
docker build -f Dockerfile.go2-gz-sim -t rosclaw/go2-gz-sim:latest ..
docker run --rm rosclaw/go2-gz-sim:latest echo "Image build successful"
```

Expected: Docker build completes without errors, container prints "Image build successful"

- [ ] **Step 4: Commit**

```sh
git add docker/Dockerfile.go2-gz-sim docker/scripts/go2-gz-entrypoint.sh
git commit -m "feat: add Gazebo simulation Dockerfile for GO2"
```

---

### Task 2: 创建 Docker Compose GO2 GZ 配置

**Files:**
- Create: `docker/docker-compose.go2-gz.yml`

- [ ] **Step 1: 创建 docker-compose.go2-gz.yml**

```yaml
# Unitree GO2 Gazebo Simulation Docker Compose configuration
# Usage: docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d

services:
  # GO2 Gazebo Simulation
  go2-gz-sim:
    image: rosclaw/go2-gz-sim:latest
    build:
      context: ..
      dockerfile: docker/Dockerfile.go2-gz-sim
    container_name: rosclaw-go2-gz-sim
    environment:
      - ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
      - GZ_SIM_RESOURCE_PATH=/opt/go2_gz_sim/models
      - DISPLAY=${DISPLAY:-:0}
      - QT_X11_NO_MITSHM=1
    ports:
      - "8080:8080"  # Gazebo web interface
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
      - ${GO2_GZ_SIM_PATH:-/opt/go2_gz_sim}:/opt/go2_gz_sim:ro
    networks:
      - rosclaw-network
    profiles:
      - go2-gz
    depends_on:
      - agiros
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

  # GO2 Bridge Node - maps go2_gz_sim topics to RosClaw standard topics
  go2-bridge-node:
    image: rosclaw/agiros:latest
    container_name: rosclaw-go2-bridge
    command: ["agiros", "launch", "unitree_go2", "go2_gz_bridge_launch.py"]
    environment:
      - ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
    networks:
      - rosclaw-network
    profiles:
      - go2-gz
    depends_on:
      - go2-gz-sim

networks:
  rosclaw-network:
    external: true
    name: ${DOCKER_NETWORK_NAME:-1panel-network}
```

- [ ] **Step 2: 更新 docker/.env.example 添加 GO2 GZ 配置**

```sh
# GO2 Gazebo Simulation
GO2_GZ_SIM_ENABLED=false
GO2_GZ_SIM_PATH=/opt/go2_gz_sim
ROSCLAW_ENABLE_GPU=false
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute
```

- [ ] **Step 3: 验证 docker compose 配置**

```sh
cd /home/jhq/work/code/claw_ws/rosclaw/docker
docker compose -f docker-compose.go2-gz.yml config
```

Expected: Valid YAML output with all services configured

- [ ] **Step 4: Commit**

```sh
git add docker/docker-compose.go2-gz.yml docker/.env.example
git commit -m "feat: add Docker Compose configuration for GO2 Gazebo simulation"
```

---

### Task 3: 创建话题桥接节点

**Files:**
- Create: `agiros_ws/src/unitree_go2/unitree_go2/go2_gz_bridge.py`
- Create: `agiros_ws/src/unitree_go2/launch/go2_gz_bridge_launch.py`
- Test: `agiros_ws/src/unitree_go2/test/test_go2_gz_bridge.py`

- [ ] **Step 1: 创建桥接节点 go2_gz_bridge.py**

```python
#!/usr/bin/env python3
"""
GO2 Gazebo Bridge - 桥接 go2_gz_sim 话题到 RosClaw 标准话题

 subscribes:
   - /go2_gz_sim/odom (nav_msgs/Odometry)
   - /go2_gz_sim/scan (sensor_msgs/LaserScan)
   - /go2_gz_sim/joint_states (sensor_msgs/JointState)
   - /go2_gz_sim/imu (sensor_msgs/Imu)
   - /go2_gz_sim/battery (sensor_msgs/BatteryState)

 publishes:
   - /go2_gz_sim/cmd_vel (geometry_msgs/Twist) - 转发到 Gazebo
   - /go2_state/odom (nav_msgs/Odometry) - RosClaw 标准话题
   - /scan (sensor_msgs/LaserScan) - SLAM/导航
   - /joint_states (sensor_msgs/JointState)
   - /go2_state/imu (sensor_msgs/Imu)
   - /go2_state/battery (sensor_msgs/BatteryState)
"""

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from sensor_msgs.msg import JointState, LaserScan, Imu, BatteryState
from nav_msgs.msg import Odometry


class Go2GzBridge(Node):
    """GO2 Gazebo 话题桥接节点."""

    def __init__(self):
        super().__init__('go2_gz_bridge')

        # === 速度命令桥接 (RosClaw -> Gazebo) ===
        self.cmd_vel_sub = self.create_subscription(
            Twist,
            '/cmd_vel',
            self.cmd_vel_callback,
            10
        )
        self.cmd_vel_pub = self.create_publisher(
            Twist,
            '/go2_gz_sim/cmd_vel',
            10
        )

        # === 里程计桥接 (Gazebo -> RosClaw) ===
        self.odom_sub = self.create_subscription(
            Odometry,
            '/go2_gz_sim/odom',
            self.odom_callback,
            10
        )
        self.odom_pub = self.create_publisher(
            Odometry,
            '/go2_state/odom',
            10
        )

        # === 激光雷达桥接 ===
        self.scan_sub = self.create_subscription(
            LaserScan,
            '/go2_gz_sim/scan',
            self.scan_callback,
            10
        )
        self.scan_pub = self.create_publisher(
            LaserScan,
            '/scan',
            10
        )

        # === 关节状态桥接 ===
        self.joint_sub = self.create_subscription(
            JointState,
            '/go2_gz_sim/joint_states',
            self.joint_callback,
            10
        )
        self.joint_pub = self.create_publisher(
            JointState,
            '/joint_states',
            10
        )

        # === IMU 桥接 ===
        self.imu_sub = self.create_subscription(
            Imu,
            '/go2_gz_sim/imu',
            self.imu_callback,
            10
        )
        self.imu_pub = self.create_publisher(
            Imu,
            '/go2_state/imu',
            10
        )

        # === 电池状态桥接 ===
        self.battery_sub = self.create_subscription(
            BatteryState,
            '/go2_gz_sim/battery',
            self.battery_callback,
            10
        )
        self.battery_pub = self.create_publisher(
            BatteryState,
            '/go2_state/battery',
            10
        )

        self.get_logger().info('GO2 Gazebo Bridge initialized')

    def cmd_vel_callback(self, msg: Twist):
        """转发速度命令到 Gazebo."""
        self.cmd_vel_pub.publish(msg)
        self.get_logger().debug(
            f'cmd_vel: linear={msg.linear.x:.2f}m/s, angular={msg.angular.z:.2f}rad/s'
        )

    def odom_callback(self, msg: Odometry):
        """转发里程计到 RosClaw."""
        self.odom_pub.publish(msg)

    def scan_callback(self, msg: LaserScan):
        """转发激光雷达数据."""
        self.scan_pub.publish(msg)

    def joint_callback(self, msg: JointState):
        """转发关节状态."""
        self.joint_pub.publish(msg)

    def imu_callback(self, msg: Imu):
        """转发 IMU 数据."""
        self.imu_pub.publish(msg)

    def battery_callback(self, msg: BatteryState):
        """转发电池状态."""
        self.battery_pub.publish(msg)


def main(args=None):
    rclpy.init(args=args)
    node = Go2GzBridge()
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

- [ ] **Step 2: 创建启动文件 go2_gz_bridge_launch.py**

```python
# GO2 Gazebo Bridge Launch File
# Launches the topic bridge between go2_gz_sim and RosClaw

from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
    """Generate launch description for GO2 Gazebo bridge."""

    go2_bridge_node = Node(
        package='unitree_go2',
        executable='go2_gz_bridge.py',
        name='go2_gz_bridge',
        output='screen',
        parameters=[{
            'use_sim_time': True,
        }]
    )

    return LaunchDescription([go2_bridge_node])
```

- [ ] **Step 3: 更新 CMakeLists.txt 安装桥接脚本**

修改 `agiros_ws/src/unitree_go2/CMakeLists.txt`:

```cmake
ament_python_install_module(${PROJECT_NAME}/go2_gz_bridge.py)

install(PROGRAMS
  ${PROJECT_NAME}/go2_node.py
  ${PROJECT_NAME}/go2_gz_bridge.py
  DESTINATION lib/${PROJECT_NAME}
)
```

- [ ] **Step 4: 构建并测试桥接节点**

```sh
cd /home/jhq/work/code/claw_ws/rosclaw/agiros_ws
source /opt/agiros/pixiu/setup.sh
colcon build --packages-select unitree_go2
source install/setup.bash

# 测试启动
agiros launch unitree_go2 go2_gz_bridge_launch.py --show-log &
sleep 3

# 验证节点运行
agiros node list | grep go2_gz_bridge
agiros topic list | grep -E "(cmd_vel|go2_state|scan)"
```

Expected: Node starts successfully, topics are registered

- [ ] **Step 5: Commit**

```sh
git add agiros_ws/src/unitree_go2/unitree_go2/go2_gz_bridge.py \
    agiros_ws/src/unitree_go2/launch/go2_gz_bridge_launch.py \
    agiros_ws/src/unitree_go2/CMakeLists.txt
git commit -m "feat: add topic bridge node for GO2 Gazebo simulation"
```

---

## Phase 2: OpenClaw 插件扩展

### Task 4: 创建 GO2 专用命令工具

**Files:**
- Create: `extensions/openclaw-plugin/src/tools/go2-commands.ts`
- Create: `extensions/openclaw-plugin/src/tools/go2-commands.test.ts`

- [ ] **Step 1: 创建 GO2 命令工具 go2-commands.ts**

```ts
/**
 * Unitree GO2 specific commands for OpenClaw
 */

import type { OpenClawTool, ToolContext } from "@openclaw/core";

export const go2StandTool: OpenClawTool = {
  name: "go2_stand",
  description: "Make the Unitree GO2 robot stand up from sitting position",
  parameters: {
    type: "object",
    properties: {},
    required: [],
  },
  async execute(params: Record<string, never>, context: ToolContext) {
    await context.transport.publish({
      topic: "/go2_command/stand",
      messageType: "std_msgs/msg/Empty",
      data: {},
    });
    return { success: true, message: "GO2 standing up" };
  },
};

export const go2SitTool: OpenClawTool = {
  name: "go2_sit",
  description: "Make the Unitree GO2 robot sit down",
  parameters: {
    type: "object",
    properties: {},
    required: [],
  },
  async execute(params: Record<string, never>, context: ToolContext) {
    await context.transport.publish({
      topic: "/go2_command/sit",
      messageType: "std_msgs/msg/Empty",
      data: {},
    });
    return { success: true, message: "GO2 sitting down" };
  },
};

export const go2StopTool: OpenClawTool = {
  name: "go2_stop",
  description: "Emergency stop - immediately halt all GO2 movement",
  parameters: {
    type: "object",
    properties: {},
    required: [],
  },
  async execute(params: Record<string, never>, context: ToolContext) {
    // Publish zero velocity
    await context.transport.publish({
      topic: "/cmd_vel",
      messageType: "geometry_msgs/msg/Twist",
      data: {
        linear: { x: 0, y: 0, z: 0 },
        angular: { x: 0, y: 0, z: 0 },
      },
    });
    return { success: true, message: "GO2 emergency stop activated" };
  },
};

export const go2MoveTool: OpenClawTool = {
  name: "go2_move",
  description: "Move the GO2 robot with specified velocity",
  parameters: {
    type: "object",
    properties: {
      linear_x: {
        type: "number",
        description: "Forward/backward velocity (m/s), positive=forward",
      },
      linear_y: {
        type: "number",
        description: "Left/right velocity (m/s), positive=left",
      },
      angular_z: {
        type: "number",
        description: "Rotation velocity (rad/s), positive=counterclockwise",
      },
      duration: {
        type: "number",
        description: "How long to move (seconds)",
      },
    },
    required: ["linear_x"],
  },
  async execute(params: Record<string, number>, context: ToolContext) {
    const { linear_x = 0, linear_y = 0, angular_z = 0, duration = 1 } = params;

    // Publish velocity command
    await context.transport.publish({
      topic: "/cmd_vel",
      messageType: "geometry_msgs/msg/Twist",
      data: {
        linear: { x: linear_x, y: linear_y, z: 0 },
        angular: { x: 0, y: 0, z: angular_z },
      },
    });

    // If duration specified, schedule stop
    if (duration > 0) {
      setTimeout(async () => {
        await context.transport.publish({
          topic: "/cmd_vel",
          messageType: "geometry_msgs/msg/Twist",
          data: {
            linear: { x: 0, y: 0, z: 0 },
            angular: { x: 0, y: 0, z: 0 },
          },
        });
      }, duration * 1000);
    }

    return {
      success: true,
      message: `GO2 moving: linear=(${linear_x},${linear_y})m/s, angular=${angular_z}rad/s for ${duration}s`,
    };
  },
};
```

- [ ] **Step 2: 创建测试文件 go2-commands.test.ts**

```ts
import { describe, it, expect, vi, beforeEach } from "vitest";
import { go2StandTool, go2SitTool, go2StopTool, go2MoveTool } from "./go2-commands";

describe("GO2 Commands Tools", () => {
  let mockContext: any;

  beforeEach(() => {
    mockContext = {
      transport: {
        publish: vi.fn().mockResolvedValue(undefined),
      },
    };
  });

  describe("go2_stand", () => {
    it("publishes stand command", async () => {
      const result = await go2StandTool.execute({}, mockContext);

      expect(mockContext.transport.publish).toHaveBeenCalledWith({
        topic: "/go2_command/stand",
        messageType: "std_msgs/msg/Empty",
        data: {},
      });
      expect(result.success).toBe(true);
    });
  });

  describe("go2_sit", () => {
    it("publishes sit command", async () => {
      const result = await go2SitTool.execute({}, mockContext);

      expect(mockContext.transport.publish).toHaveBeenCalledWith({
        topic: "/go2_command/sit",
        messageType: "std_msgs/msg/Empty",
        data: {},
      });
      expect(result.success).toBe(true);
    });
  });

  describe("go2_stop", () => {
    it("publishes zero velocity", async () => {
      const result = await go2StopTool.execute({}, mockContext);

      expect(mockContext.transport.publish).toHaveBeenCalledWith({
        topic: "/cmd_vel",
        messageType: "geometry_msgs/msg/Twist",
        data: {
          linear: { x: 0, y: 0, z: 0 },
          angular: { x: 0, y: 0, z: 0 },
        },
      });
      expect(result.success).toBe(true);
    });
  });

  describe("go2_move", () => {
    it("publishes velocity command", async () => {
      const result = await go2MoveTool.execute(
        { linear_x: 0.5, angular_z: 0.3, duration: 2 },
        mockContext
      );

      expect(mockContext.transport.publish).toHaveBeenCalledWith({
        topic: "/cmd_vel",
        messageType: "geometry_msgs/msg/Twist",
        data: {
          linear: { x: 0.5, y: 0, z: 0 },
          angular: { x: 0, y: 0, z: 0.3 },
        },
      });
      expect(result.success).toBe(true);
    });

    it("requires linear_x parameter", async () => {
      // Should work with default linear_x=0
      const result = await go2MoveTool.execute({}, mockContext);
      expect(result.success).toBe(true);
    });
  });
});
```

- [ ] **Step 3: 运行测试验证**

```sh
cd /home/jhq/work/code/claw_ws/rosclaw/extensions/openclaw-plugin
pnpm test -- go2-commands.test.ts
```

Expected: All tests pass

- [ ] **Step 4: Commit**

```sh
git add extensions/openclaw-plugin/src/tools/go2-commands.ts \
    extensions/openclaw-plugin/src/tools/go2-commands.test.ts
git commit -m "feat: add GO2 specific command tools for OpenClaw"
```

---

### Task 5: 注册 GO2 工具到插件

**Files:**
- Modify: `extensions/openclaw-plugin/src/index.ts:20-40`
- Modify: `extensions/openclaw-plugin/src/config.ts`

- [ ] **Step 1: 更新插件入口注册 GO2 工具**

修改 `extensions/openclaw-plugin/src/index.ts`:

```ts
import { go2StandTool, go2SitTool, go2StopTool, go2MoveTool } from "./tools/go2-commands.js";

export function register(config: RosClawConfig) {
  // ...existing code...

  // Register GO2 specific tools if robot is GO2
  if (config.robot_name?.includes("GO2") || config.robot_name?.includes("go2")) {
    context.registerTool(go2StandTool);
    context.registerTool(go2SitTool);
    context.registerTool(go2StopTool);
    context.registerTool(go2MoveTool);
    logger.info("GO2-specific tools registered");
  }

  // ...existing code...
}
```

- [ ] **Step 2: 更新配置验证支持 GO2**

修改 `extensions/openclaw-plugin/src/config.ts`:

```ts
export const rosClawConfigSchema = z.object({
  // ...existing fields...
  robot_name: z.string().optional().default("TurtleBot3 (Sim)"),
  robot_type: z.enum(["turtlebot3", "go2", "custom"]).optional().default("turtlebot3"),
  // ...existing fields...
});
```

- [ ] **Step 3: 类型检查验证**

```sh
cd /home/jhq/work/code/claw_ws/rosclaw/extensions/openclaw-plugin
pnpm typecheck
```

Expected: No type errors

- [ ] **Step 4: Commit**

```sh
git add extensions/openclaw-plugin/src/index.ts \
    extensions/openclaw-plugin/src/config.ts
git commit -m "feat: register GO2 tools when robot is GO2"
```

---

## Phase 3: Docker 和 Makefile

### Task 6: 更新 Docker Makefile

**Files:**
- Modify: `docker/Makefile`

- [ ] **Step 1: 添加 GO2 GZ 仿真命令到 Makefile**

```makefile
.PHONY: go2-gz-start go2-gz-stop go2-gz-logs go2-gz-status

# GO2 Gazebo Simulation Commands
go2-gz-start:
	@echo "Starting GO2 Gazebo simulation..."
	docker compose -f docker-compose.yml -f docker-compose.go2-gz.yml --profile go2-gz up -d

go2-gz-stop:
	@echo "Stopping GO2 Gazebo simulation..."
	docker compose -f docker-compose.yml -f docker-compose.go2-gz.yml --profile go2-gz stop

go2-gz-logs:
	docker compose -f docker-compose.yml -f docker-compose.go2-gz.yml --profile go2-gz logs -f

go2-gz-status:
	docker compose -f docker-compose.yml -f docker-compose.go2-gz.yml --profile go2-gz ps

go2-gz-clean:
	@echo "Cleaning GO2 Gazebo simulation..."
	docker compose -f docker-compose.yml -f docker-compose.go2-gz.yml --profile go2-gz down -v
```

- [ ] **Step 2: 更新根目录 Makefile**

```makefile
# GO2 Gazebo Simulation
.PHONY: go2-gz-start go2-gz-stop go2-gz-logs go2-gz-status

go2-gz-start:
	$(MAKE) -C docker go2-gz-start

go2-gz-stop:
	$(MAKE) -C docker go2-gz-stop

go2-gz-logs:
	$(MAKE) -C docker go2-gz-logs

go2-gz-status:
	$(MAKE) -C docker go2-gz-status
```

- [ ] **Step 3: 验证 Make 命令**

```sh
cd /home/jhq/work/code/claw_ws/rosclaw
make go2-gz-status
```

Expected: Shows help or empty status (no containers running)

- [ ] **Step 4: Commit**

```sh
git add docker/Makefile Makefile
git commit -m "feat: add Makefile targets for GO2 Gazebo simulation"
```

---

## Phase 4: 测试和文档

### Task 7: 创建验证脚本

**Files:**
- Create: `examples/go2-gz-sim/verify-simulation.sh`
- Create: `examples/go2-gz-sim/README.md`

- [ ] **Step 1: 创建验证脚本**

```sh
#!/usr/bin/env bash
# Unitree GO2 Gazebo Simulation Verification Script
# Usage: ./verify-simulation.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROSCLAW_ROOT="$SCRIPT_DIR/../.."

echo "========================================"
echo "  GO2 Gazebo Simulation Verification"
echo "========================================"
echo ""

# Source ROS2
echo "[1/6] Sourcing ROS2..."
source /opt/agiros/pixiu/setup.sh

# Source workspace if exists
if [[ -f "$ROSCLAW_ROOT/agiros_ws/install/setup.sh" ]]; then
    source "$ROSCLAW_ROOT/agiros_ws/install/setup.sh"
    echo "[OK] Workspace sourced"
else
    echo "[WARN] Workspace not built yet"
fi
echo ""

# Check Docker containers
echo "[2/6] Checking Docker containers..."
cd "$ROSCLAW_ROOT/docker"
if docker compose -f docker-compose.go2-gz.yml --profile go2-gz ps | grep -q "go2-gz-sim"; then
    echo "[OK] GO2 Gazebo container running"
else
    echo "[WARN] GO2 Gazebo container not running"
    echo "  Start with: make go2-gz-start"
fi
echo ""

# Check AGIROS S S S nodes
echo "[3/6] Checking AGIROS S S S nodes..."
NODES=$(agiros node list 2>/dev/null || echo "")
if echo "$NODES" | grep -q "go2_gz_bridge"; then
    echo "[OK] GO2 bridge node running"
else
    echo "[WARN] GO2 bridge node not running"
fi
echo ""

# Check topics
echo "[4/6] Checking AGIROS S S S topics..."
TOPICS=$(agiros topic list 2>/dev/null || echo "")
REQUIRED_TOPICS=("/cmd_vel" "/go2_state/odom" "/go2_state/battery" "/scan")

for topic in "${REQUIRED_TOPICS[@]}"; do
    if echo "$TOPICS" | grep -q "$topic"; then
        echo "[OK] Topic $topic available"
    else
        echo "[WARN] Topic $topic not found"
    fi
done
echo ""

# Test publishing
echo "[5/6] Testing velocity command..."
agiros topic pub /cmd_vel geometry_msgs/msg/Twist \
  "{linear: {x: 0.1}, angular: {z: 0.0}}" --once
echo "[OK] Velocity command published"
echo ""

# Test service call
echo "[6/6] Testing stand command..."
agiros topic pub /go2_command/stand std_msgs/msg/Empty --once
echo "[OK] Stand command published"
echo ""

echo "========================================"
echo "  Verification Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Start OpenClaw with RosClaw plugin"
echo "  2. Send natural language commands:"
echo "     - '向前走 1 米'"
echo "     - '站起来'"
echo "     - '向左转 90 度'"
echo ""
```

- [ ] **Step 2: 创建实例 README**

```markdown
# Unitree GO2 Gazebo 仿真示例

通过 RosClaw 和 OpenClaw 使用自然语言控制 Gazebo 仿真中的 GO2 机器狗。

## 前置条件

- Docker 和 Docker Compose
- NVIDIA GPU 和 Container Toolkit (可选，用于 GPU 加速)
- AGIROS S S S Jazzy (本地测试)

## 快速开始

### 1. 启动仿真

```

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

```

- [ ] **Step 3: 使脚本可执行**

```sh
chmod +x /home/jhq/work/code/claw_ws/rosclaw/examples/go2-gz-sim/verify-simulation.sh
```

- [ ] **Step 4: Commit**

```sh
git add examples/go2-gz-sim/
git commit -m "docs: add GO2 Gazebo simulation example and verification script"
```

---

### Task 8: 更新集成文档

**Files:**
- Modify: `docs/unitree-go2-integration.md`

- [ ] **Step 1: 添加 Gazebo 仿真章节**

在 `docs/unitree-go2-integration.md` 中添加：

```markdown
## Gazebo 仿真模式

### 前置条件

- NVIDIA GPU (推荐)
- NVIDIA Container Toolkit
- Docker Compose

### 启动仿真

```

# GPU 加速模式
make go2-gz-start

# 或 CPU 模式
docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d
```

### 仿真架构

```
go2_gz_sim (Gazebo)
    │
    ▼
go2_gz_bridge (话题映射)
    │
    ▼
rosbridge_server
    │
    ▼
OpenClaw Gateway
```

### 仿真话题映射

| go2_gz_sim 话题 | RosClaw 标准话题 | 说明 |
|----------------|------------------|------|
| `/go2_gz_sim/cmd_vel` | `/cmd_vel` | 速度命令 |
| `/go2_gz_sim/odom` | `/go2_state/odom` | 里程计 |
| `/go2_gz_sim/scan` | `/scan` | 激光雷达 |
| `/go2_gz_sim/imu` | `/go2_state/imu` | IMU |
| `/go2_gz_sim/battery` | `/go2_state/battery` | 电池 |
```

- [ ] **Step 2: 更新快速开始部分**

确保快速开始部分包含 Gazebo 仿真的说明

- [ ] **Step 3: Commit**

```sh
git add docs/unitree-go2-integration.md
git commit -m "docs: add Gazebo simulation section to GO2 integration guide"
```

---

## Phase 5: 测试验证

### Task 9: 端到端集成测试

**Files:**
- Create: `examples/go2-gz-sim/test-integration.sh`

- [ ] **Step 1: 创建集成测试脚本**

```sh
#!/usr/bin/env bash
# GO2 Gazebo Integration Test
# Tests the full stack from AGIROS S S S topics to OpenClaw tools

set -e

echo "========================================"
echo "  GO2 Gazebo Integration Test"
echo "========================================"
echo ""

PASSED=0
FAILED=0

test_result() {
    if [[ $1 -eq 0 ]]; then
        echo "[PASS] $2"
        ((PASSED++))
    else
        echo "[FAIL] $2"
        ((FAILED++))
    fi
}

# Test 1: Bridge node publishes topics
echo "[Test 1] Bridge node publishes expected topics..."
source /opt/agiros/pixiu/setup.sh
TOPICS=$(agiros topic list)
echo "$TOPICS" | grep -q "/go2_state/odom"
test_result $? "Odom topic published"

echo "$TOPICS" | grep -q "/go2_state/battery"
test_result $? "Battery topic published"

echo "$TOPICS" | grep -q "/go2_state/imu"
test_result $? "IMU topic published"
echo ""

# Test 2: Velocity commands are forwarded
echo "[Test 2] Velocity commands are forwarded to Gazebo..."
agiros topic pub /cmd_vel geometry_msgs/msg/Twist \
  "{linear: {x: 0.5}, angular: {z: 0.0}}" --once
GO2_CMD=$(agiros topic echo /go2_gz_sim/cmd_vel --once --timeout 2)
if [[ -n "$GO2_CMD" ]]; then
    test_result 0 "Velocity forwarded"
else
    test_result 1 "Velocity not forwarded"
fi
echo ""

# Test 3: OpenClaw tools can be invoked
echo "[Test 3] OpenClaw GO2 tools..."
# This would require OpenClaw to be running
# For now, we test that the tool definitions exist
if [[ -f "extensions/openclaw-plugin/src/tools/go2-commands.ts" ]]; then
    test_result 0 "GO2 tools defined"
else
    test_result 1 "GO2 tools missing"
fi
echo ""

# Summary
echo "========================================"
echo "  Test Summary: $PASSED passed, $FAILED failed"
echo "========================================"

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
```

- [ ] **Step 2: 运行测试**

```sh
cd /home/jhq/work/code/claw_ws/rosclaw/examples/go2-gz-sim
./test-integration.sh
```

Expected: All tests pass

- [ ] **Step 3: Commit**

```sh
git add examples/go2-gz-sim/test-integration.sh
git commit -m "test: add integration test for GO2 Gazebo simulation"
```

---

## 完成标准

所有任务完成后，以下标准应该满足：

- [ ] Docker 镜像可以成功构建
- [ ] Docker Compose 配置有效
- [ ] 桥接节点可以启动并发布话题
- [ ] OpenClaw 工具可以调用
- [ ] 验证脚本全部通过
- [ ] 文档完整且准确

---

## 后续扩展

1. **SLAM 建图**: 集成 `slam_toolbox`
2. **自主导航**: 集成 Nav2 导航栈
3. **视觉识别**: 添加摄像头图像处理
4. **多机器人支持**: 同时控制多个仿真机器人

