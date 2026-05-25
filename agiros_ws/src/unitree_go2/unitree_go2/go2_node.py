#!/usr/bin/env python3
"""
Unitree GO2 Control Node

This node provides a bridge between RosClaw and the Unitree GO2 quadruped robot.
It subscribes to cmd_vel for movement control and publishes robot state.

Subscribed Topics:
    - /cmd_vel (geometry_msgs/Twist): Linear and angular velocity commands
    - /go2_command/stand (std_msgs/Empty): Stand up command
    - /go2_command/sit (std_msgs/Empty): Sit down command

Published Topics:
    - /go2_state/battery (sensor_msgs/BatteryState): Battery status
    - /go2_state/imu (sensor_msgs/Imu): IMU data
    - /go2_state/foot_force (geometry_msgs/WrenchStamped): Foot force feedback
"""

import rclpy
from rclpy.node import Node
from std_msgs.msg import Empty, String, Header
from geometry_msgs.msg import Twist, WrenchStamped, Wrench, Vector3, Quaternion
from sensor_msgs.msg import BatteryState, Imu
from nav_msgs.msg import Odometry


class UnitreeGO2Node(Node):
    """Unitree GO2 control node."""

    def __init__(self):
        super().__init__('unitree_go2_node')

        # Robot state
        self.is_standing = False
        self.battery_percent = 100.0
        self.is_connected = False

        # Subscribers
        self.cmd_vel_sub = self.create_subscription(
            Twist,
            'cmd_vel',
            self.cmd_vel_callback,
            10
        )

        self.stand_sub = self.create_subscription(
            Empty,
            'go2_command/stand',
            self.stand_callback,
            10
        )

        self.sit_sub = self.create_subscription(
            Empty,
            'go2_command/sit',
            self.sit_callback,
            10
        )

        # Publishers
        self.battery_pub = self.create_publisher(
            BatteryState,
            'go2_state/battery',
            10
        )

        self.imu_pub = self.create_publisher(
            Imu,
            'go2_state/imu',
            10
        )

        self.foot_force_pub = self.create_publisher(
            WrenchStamped,
            'go2_state/foot_force',
            10
        )

        self.odom_pub = self.create_publisher(
            Odometry,
            'go2_state/odom',
            10
        )

        # Timer for state updates
        self.timer = self.create_timer(1.0, self.publish_state)

        self.get_logger().info('Unitree GO2 node initialized')

    def cmd_vel_callback(self, msg: Twist):
        """Handle velocity commands."""
        # In a real implementation, this would send commands to the robot
        self.get_logger().debug(
            f'Velocity command: linear={msg.linear.x:.2f}m/s, '
            f'angular={msg.angular.z:.2f}rad/s'
        )

    def stand_callback(self, msg: Empty):
        """Handle stand up command."""
        self.is_standing = True
        self.get_logger().info('GO2 standing up')

    def sit_callback(self, msg: Empty):
        """Handle sit down command."""
        self.is_standing = False
        self.get_logger().info('GO2 sitting down')

    def publish_state(self):
        """Publish robot state."""
        now = self.get_clock().now()
        header = Header(stamp=now.to_msg(), frame_id='base_link')

        # Publish battery state
        battery_msg = BatteryState(
            header=header,
            voltage=24.0,
            current=2.5,
            charge=8.0,
            capacity=10.0,
            percentage=self.battery_percent / 100.0,
            present=True,
            power_supply_status=BatteryState.POWER_SUPPLY_STATUS_DISCHARGING
        )
        self.battery_pub.publish(battery_msg)

        # Publish dummy IMU data
        imu_msg = Imu(
            header=header,
            orientation=Quaternion(w=1.0, x=0.0, y=0.0, z=0.0),
            angular_velocity=Vector3(x=0.0, y=0.0, z=0.0),
            linear_acceleration=Vector3(x=0.0, y=0.0, z=9.81)
        )
        self.imu_pub.publish(imu_msg)

        # Publish dummy foot force data
        foot_force_msg = WrenchStamped(
            header=header,
            wrench=Wrench(
                force=Vector3(x=0.0, y=0.0, z=-50.0),
                torque=Vector3(x=0.0, y=0.0, z=0.0)
            )
        )
        self.foot_force_pub.publish(foot_force_msg)


def main(args=None):
    """Entry point for the node."""
    rclpy.init(args=args)
    node = UnitreeGO2Node()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
