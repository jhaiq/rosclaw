#!/bin/bash
set -e

export ROS_DISTRO=${ROS_DISTRO:-humble}

# Source ROS2 and go2_gz_sim
source /opt/ros/$ROS_DISTRO/setup.sh
source /opt/go2_gz_sim/install/setup.sh

# Set environment
export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
export GZ_SIM_RESOURCE_PATH=${GZ_SIM_RESOURCE_PATH:-/opt/go2_gz_sim/models}

# Execute command
exec "$@"
