/**
 * Robot Adapter Skill - 帮助开发者快速适配新机器人到 RosClaw 平台
 * 提供交互式指导、命令生成和配置模板
 */

import type { OpenClawPluginApi } from "../plugin-api.js";
import type { RosClawConfig } from "../config.js";

/**
 * Robot Adapter Skill 配置
 */
interface RobotAdapterConfig {
  /** 机器人名称 */
  robotName: string;
  /** 机器人类型 */
  robotType: "simulation" | "physical";
  /** 通信模式 */
  transportMode: "rosbridge" | "local" | "webrtc";
  /** 是否生成配置文件 */
  generateConfig: boolean;
}

/**
 * 注册 robot-adapt 命令
 * 提供交互式机器人适配指导
 */
export function registerRobotAdapterCommand(api: OpenClawPluginApi, config: RosClawConfig): void {
  api.registerCommand({
    name: "robot-adapt",
    description: "Robot Adapter Skill - 交互式指导新机器人适配流程",

    async handler(ctx) {
      const args = ctx.args?.trim();

      // 显示帮助信息
      if (!args || args === "help" || args === "--help" || args === "-h") {
        return {
          text: formatHelp(),
        };
      }

      // 解析命令参数
      const parsedArgs = parseArgs(args);

      if (parsedArgs.action === "start") {
        return await startAdaptationFlow(api, parsedArgs);
      }

      if (parsedArgs.action === "analyze") {
        return await analyzeRobotTopics(api, parsedArgs);
      }

      if (parsedArgs.action === "generate") {
        return await generateConfigFiles(api, parsedArgs);
      }

      if (parsedArgs.action === "validate") {
        return await validateConfiguration(api, parsedArgs);
      }

      return {
        text: `未知操作：${parsedArgs.action}\n使用 /robot-adapt help 查看可用命令`,
      };
    },
  });
}

/**
 * 解析命令行参数
 */
function parseArgs(args: string): Record<string, string> {
  const result: Record<string, string> = { action: "" };
  const parts = args.split(/\s+/);

  if (parts.length > 0) {
    result.action = parts[0];
  }

  for (let i = 1; i < parts.length; i++) {
    const part = parts[i];
    if (part.startsWith("--")) {
      const [key, value] = part.slice(2).split("=");
      result[key] = value || "true";
    } else if (part.startsWith("-")) {
      const shortOpt = part.slice(1);
      if (shortOpt === "n" && parts[i + 1]) {
        result.name = parts[++i];
      } else if (shortOpt === "t" && parts[i + 1]) {
        result.type = parts[++i];
      } else if (shortOpt === "m" && parts[i + 1]) {
        result.mode = parts[++i];
      }
    }
  }

  return result;
}

/**
 * 显示帮助信息
 */
function formatHelp(): string {
  return `
╔═══════════════════════════════════════════════════════════╗
║         RosClaw Robot Adapter Skill v1.0                  ║
║     快速适配新机器人或仿真环境到 RosClaw 平台                ║
╚═══════════════════════════════════════════════════════════╝

使用方法：/robot-adapt <command> [options]

可用命令:
  start       启动交互式适配流程
  analyze     分析机器人话题
  generate    生成配置文件模板
  validate    验证配置有效性

选项:
  -n, --name      机器人名称
  -t, --type      机器人类型 (simulation|physical)
  -m, --mode      通信模式 (rosbridge|local|webrtc)
  --robot-path    机器人工作空间路径
  --output        输出目录

示例:
  /robot-adapt start -n "MyRobot" -t simulation
  /robot-adapt analyze --robot-path /path/to/robot
  /robot-adapt generate -n "MyRobot" -m rosbridge
  /robot-adapt validate --config /path/to/config

───────────────────────────────────────────────────────────

适配流程 6 步骤:
  1. 分析话题      ros2 topic list/info/hz/echo
  2. 设计映射      映射到 RosClaw 标准话题
  3. 编写桥接      Python 桥接节点实现
  4. Docker 封装    Dockerfile + docker-compose
  5. 插件配置      更新 openclaw.plugin.json
  6. 验证测试      话题频率、端到端测试

参考文档：docs/skills/robot-adapter.md
  `;
}

/**
 * 启动交互式适配流程
 */
async function startAdaptationFlow(
  api: OpenClawPluginApi,
  args: Record<string, string>,
): Promise<{ text: string }> {
  const robotName = args.name || args.robotName || "UnknownRobot";

  return {
    text: `
╔═══════════════════════════════════════════════════════════╗
║  启动 ${robotName} 适配流程                                 ║
╚═══════════════════════════════════════════════════════════╝

步骤 1/6: 分析机器人话题
───────────────────────────────────────────────────────────

请在终端执行以下命令分析机器人话题：

  # 启动机器人/仿真
  ros2 launch ${robotName.toLowerCase()}_bringup ${robotName.toLowerCase()}_launch.py

  # 列出所有话题
  ros2 topic list

  # 查看话题类型和频率
  ros2 topic info /topic_name --verbose
  ros2 topic hz /topic_name

  # 查看消息内容
  ros2 topic echo /topic_name --once

请记录以下信息：
  □ 发布的话题（机器人→外部）
  □ 订阅的话题（外部→机器人）
  □ 消息类型
  □ 发布频率

完成后执行：/robot-adapt analyze --name "${robotName}"
    `,
  };
}

/**
 * 分析机器人话题
 */
async function analyzeRobotTopics(
  api: OpenClawPluginApi,
  args: Record<string, string>,
): Promise<{ text: string }> {
  const robotName = args.name || "UnknownRobot";

  return {
    text: `
╔═══════════════════════════════════════════════════════════╗
║  步骤 2/6: 设计话题映射 (${robotName})                       ║
╚═══════════════════════════════════════════════════════════╝

RosClaw 标准话题对照表:
───────────────────────────────────────────────────────────

| 功能       | RosClaw 标准话题        | 消息类型              |
|------------|------------------------|----------------------|
| 速度命令   | /cmd_vel               | geometry_msgs/Twist  |
| 里程计     | /${robotName.toLowerCase()}_state/odom | nav_msgs/Odometry    |
| 激光雷达   | /scan                  | sensor_msgs/LaserScan|
| 关节状态   | /joint_states          | sensor_msgs/JointState|
| IMU        | /${robotName.toLowerCase()}_state/imu  | sensor_msgs/Imu      |
| 电池状态   | /${robotName.toLowerCase()}_state/battery| sensor_msgs/BatteryState|

请将机器人原生话题映射到上述标准话题：

  机器人原生话题          →  RosClaw 标准话题
  ───────────────────────────────────────────
  /robot/odom           →  /${robotName.toLowerCase()}_state/odom
  /robot/scan           →  /scan
  /robot/cmd_vel        →  /cmd_vel

完成后执行：/robot-adapt generate --name "${robotName}"
    `,
  };
}

/**
 * 生成配置文件
 */
async function generateConfigFiles(
  api: OpenClawPluginApi,
  args: Record<string, string>,
): Promise<{ text: string }> {
  const robotName = args.name || "UnknownRobot";
  const transportMode = args.mode || "rosbridge";
  const robotPath = args.robotPath || "/path/to/robot/workspace";

  const dockerComposeContent = generateDockerCompose(robotName, transportMode, robotPath);
  const bridgeNodeContent = generateBridgeNode(robotName);

  return {
    text: `
╔═══════════════════════════════════════════════════════════╗
║  步骤 3-4/6: 生成配置文件 (${robotName})                    ║
╚═══════════════════════════════════════════════════════════╝

已生成以下配置文件模板:

───────────────────────────────────────────────────────────
📁 docker/docker-compose.${robotName.toLowerCase()}.yml
───────────────────────────────────────────────────────────

${dockerComposeContent}

───────────────────────────────────────────────────────────
📁 ros2_ws/src/${robotName.toLowerCase()}_bringup/${robotName.toLowerCase()}_bringup/bridge_node.py
───────────────────────────────────────────────────────────

${bridgeNodeContent}

───────────────────────────────────────────────────────────

下一步:
  1. 将上述内容保存到对应文件
  2. 根据实际情况修改话题名称和路径
  3. 执行：/robot-adapt validate --name "${robotName}"
    `,
  };
}

/**
 * 生成 Docker Compose 配置
 */
function generateDockerCompose(
  robotName: string,
  transportMode: string,
  robotPath: string,
): string {
  const robotId = robotName.toLowerCase().replace(/\s+/g, "_");

  return `services:
  # ${robotName} 仿真/驱动
  ${robotId}-sim:
    image: rosclaw/${robotId}:latest
    container_name: rosclaw-${robotId}-sim
    environment:
      - ROS_DOMAIN_ID=\${ROS_DOMAIN_ID:-0}
      - DISPLAY=\${DISPLAY:-:0}
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
      - ${robotPath}:/opt/${robotId}:ro
    networks:
      - rosclaw-network
    profiles:
      - ${robotId}

  # 桥接节点
  ${robotId}-bridge:
    image: rosclaw/${robotId}:latest
    container_name: rosclaw-${robotId}-bridge
    command: >
      bash -c "source /opt/ros/humble/setup.sh &&
               source /opt/${robotId}/install/local_setup.sh &&
               ros2 launch ${robotId}_bringup bridge_launch.py"
    volumes:
      - ${robotPath}:/opt/${robotId}:ro
      - /path/to/rosclaw/ros2_ws/install:/opt/rosclaw/install:ro
    networks:
      - rosclaw-network
    profiles:
      - ${robotId}
    depends_on:
      - ${robotId}-sim

  # ROSBridge 服务
  rosbridge:
    image: rosclaw/${robotId}:latest
    container_name: rosclaw-rosbridge
    ports:
      - "9090:9090"
    command: >
      bash -c "source /opt/ros/humble/setup.sh &&
               source /opt/rosclaw/install/setup.sh &&
               ros2 launch rosbridge_server rosbridge_websocket_launch.xml"
    volumes:
      - /path/to/rosclaw/ros2_ws/install:/opt/rosclaw/install:ro
    networks:
      - rosclaw-network
    profiles:
      - ${robotId}

networks:
  rosclaw-network:
    external: true
    name: \${DOCKER_NETWORK_NAME:-1panel-network}`;
}

/**
 * 生成桥接节点代码
 */
function generateBridgeNode(robotName: string): string {
  const robotId = robotName.toLowerCase().replace(/\s+/g, "_");
  const className = robotName.replace(/\s+/g, "") + "Bridge";

  return `#!/usr/bin/env python3
"""
${robotName} 桥接节点 - 桥接机器人原生话题到 RosClaw 标准话题
"""

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from nav_msgs.msg import Odometry


class ${className}(Node):
    """${robotName} 话题桥接节点."""

    def __init__(self):
        super().__init__('${robotId}_bridge')

        # 速度命令桥接 (RosClaw -> 机器人)
        self.cmd_vel_sub = self.create_subscription(
            Twist,
            '/cmd_vel',  # RosClaw 标准输入
            self.cmd_vel_callback,
            10
        )
        self.cmd_vel_pub = self.create_publisher(
            Twist,
            '/${robotId}/cmd_vel',  # 机器人原生话题
            10
        )

        # 里程计桥接 (机器人 -> RosClaw)
        self.odom_sub = self.create_subscription(
            Odometry,
            '/${robotId}/odom',  # 机器人原生话题
            self.odom_callback,
            10
        )
        self.odom_pub = self.create_publisher(
            Odometry,
            '/${robotId}_state/odom',  # RosClaw 标准输出
            10
        )

        self.get_logger().info('${robotName} Bridge initialized')

    def cmd_vel_callback(self, msg: Twist):
        """转发速度命令到机器人."""
        self.cmd_vel_pub.publish(msg)

    def odom_callback(self, msg: Odometry):
        """转发里程计到 RosClaw."""
        self.odom_pub.publish(msg)


def main(args=None):
    rclpy.init(args=args)
    node = ${className}()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()`;
}

/**
 * 验证配置
 */
async function validateConfiguration(
  api: OpenClawPluginApi,
  args: Record<string, string>,
): Promise<{ text: string }> {
  const robotName = args.name || "UnknownRobot";

  return {
    text: `
╔═══════════════════════════════════════════════════════════╗
║  步骤 5-6/6: 验证配置 (${robotName})                        ║
╚═══════════════════════════════════════════════════════════╝

验证检查清单:
───────────────────────────────────────────────────────────

□ 1. Docker 服务启动
   docker compose -f docker/docker-compose.${robotName.toLowerCase()}.yml --profile ${robotName.toLowerCase()} up -d

□ 2. 检查服务状态
   docker compose -f docker/docker-compose.${robotName.toLowerCase()}.yml ps

□ 3. 验证话题存在
   docker compose -f docker/docker-compose.${robotName.toLowerCase()}.yml exec rosbridge \\
     bash -c "ros2 topic list | grep ${robotName.toLowerCase()}"

□ 4. 验证话题频率
   ros2 topic hz /${robotName.toLowerCase()}_state/odom
   ros2 topic hz /scan

□ 5. OpenClaw 连接测试
   在 OpenClaw 中输入："请${robotName}向前移动 1 米"

□ 6. 端到端响应测试
   观察机器人是否响应命令

───────────────────────────────────────────────────────────

如所有检查通过，适配完成！🎉
    `,
  };
}
