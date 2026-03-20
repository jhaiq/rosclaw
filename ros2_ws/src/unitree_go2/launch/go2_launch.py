# Unitree GO2 Launch File
# Launches the GO2 control node for simulation or hardware

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    """Generate launch description for Unitree GO2."""

    # Declare arguments
    use_sim_time_arg = DeclareLaunchArgument(
        'use_sim_time',
        default_value='false',
        description='Use simulation (Gazebo) time if true'
    )

    mode_arg = DeclareLaunchArgument(
        'mode',
        default_value='simulation',
        description='Operating mode: simulation or hardware',
        choices=['simulation', 'hardware']
    )

    # GO2 control node
    go2_node = Node(
        package='unitree_go2',
        executable='go2_node',
        name='unitree_go2_node',
        output='screen',
        parameters=[{
            'use_sim_time': LaunchConfiguration('use_sim_time'),
            'mode': LaunchConfiguration('mode'),
        }]
    )

    return LaunchDescription([
        use_sim_time_arg,
        mode_arg,
        go2_node,
    ])
