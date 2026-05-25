#!/bin/bash
set -e

export ROS_DISTRO=${ROS_DISTRO:-loong}

# Source ROS2
source /opt/ros/$ROS_DISTRO/setup.sh

# Source go2_gz_sim if available
if [[ -f "/opt/go2_gz_sim/install/local_setup.sh" ]]; then
    source /opt/go2_gz_sim/install/local_setup.sh
    echo "Sourced go2_gz_sim: /opt/go2_gz_sim/install/local_setup.sh"
else
    echo "Warning: /opt/go2_gz_sim/install/local_setup.sh not found"
fi

# Source rosclaw install if available
if [[ -f "/opt/rosclaw/install/local_setup.sh" ]]; then
    source /opt/rosclaw/install/local_setup.sh
    echo "Sourced rosclaw: /opt/rosclaw/install/local_setup.sh"
else
    echo "Warning: /opt/rosclaw/install/local_setup.sh not found"
fi

# Set environment
export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
export GZ_SIM_RESOURCE_PATH=${GZ_SIM_RESOURCE_PATH:-/opt/go2_gz_sim/models:/opt/go2_gz_sim/src/gazebo_sim/world}

# GUI 模式配置
# GO2_GUI=true: 启动 Gazebo GUI（需要 X11 显示服务器）
# GO2_GUI=false（默认）：无头模式，仅运行 Gazebo 服务器
if [[ "${GO2_GUI}" == "true" ]]; then
    echo "Starting Gazebo in GUI mode..."
    export QT_X11_NO_MITSHM=${QT_X11_NO_MITSHM:-1}
    export DISPLAY=${DISPLAY:-:0}
else
    echo "Starting Gazebo in headless mode (server-only)..."
fi

# Execute command
exec "$@"
