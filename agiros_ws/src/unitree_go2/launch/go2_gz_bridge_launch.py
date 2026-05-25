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
