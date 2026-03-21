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
