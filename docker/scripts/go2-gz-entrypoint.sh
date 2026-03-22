#!/bin/bash
set -e

export ROS_DISTRO=${ROS_DISTRO:-humble}

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
export GZ_SIM_RESOURCE_PATH=${GZ_SIM_RESOURCE_PATH:-/opt/go2_gz_sim/models}

# Execute command
exec "$@"
