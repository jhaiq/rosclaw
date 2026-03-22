#!/bin/bash
set -e

echo "Sourcing ROS2 Humble..."
source /opt/ros/humble/setup.sh

echo "Building unitree_go2 package..."
cd /opt/rosclaw/ros2_ws
colcon build --packages-select unitree_go2 --symlink-install

echo "Build complete!"
ls -la install/unitree_go2/lib/unitree_go2/
