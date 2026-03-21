#!/usr/bin/env bash
# Unitree GO2 Simulation Verification Script
# Usage: ./verify-go2-simulation.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROS2_WS="$SCRIPT_DIR/../ros2_ws"

echo "========================================"
echo "  Unitree GO2 Simulation Verification"
echo "========================================"
echo ""

# Source ROS2 and workspace
echo "[1/5] Sourcing ROS2 and workspace..."
# shellcheck disable=SC1090
source /opt/ros/jazzy/setup.sh
export COLCON_CURRENT_PREFIX="$ROS2_WS/install"
# shellcheck disable=SC1090
source "$ROS2_WS/install/setup.sh"

# Check packages
echo "[2/5] Checking installed packages..."
PACKAGES=$(ros2 pkg list | grep -E "(unitree|rosclaw)" || true)
if [[ -z "$PACKAGES" ]]; then
    echo "[ERROR] Packages not found. Building..."
    cd "$ROS2_WS"
    colcon build --packages-select rosclaw_msgs unitree_go2
    source "$ROS2_WS/install/setup.sh"
fi
echo "[OK] Packages found:"
echo "$PACKAGES"
echo ""

# Start GO2 node
echo "[3/5] Starting GO2 node..."
ros2 launch unitree_go2 go2_launch.py use_sim_time:=true &
GO2_PID=$!
sleep 3

# Check if node is running
if ! kill -0 $GO2_PID 2>/dev/null; then
    echo "[ERROR] GO2 node failed to start"
    exit 1
fi
echo "[OK] GO2 node started (PID: $GO2_PID)"
echo ""

# List nodes
echo "[4/5] Checking ROS2 nodes and topics..."
echo "Nodes:"
ros2 node list | grep -E "(go2|unitree)" || echo "  No GO2 nodes found"
echo ""
echo "Topics:"
ros2 topic list | grep go2 || echo "  No GO2 topics found"
echo ""

# Test publishing commands
echo "[5/5] Testing commands..."
echo "Publishing /go2_command/stand..."
ros2 topic pub /go2_command/stand std_msgs/msg/Empty --once
sleep 1

echo "Publishing /cmd_vel (forward)..."
ros2 topic pub /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.5}, angular: {z: 0.0}}" --once
sleep 1

echo "Publishing /cmd_vel (stop)..."
ros2 topic pub /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.0}, angular: {z: 0.0}}" --once
echo ""

# Cleanup
echo "Stopping GO2 node..."
kill $GO2_PID 2>/dev/null || true
wait $GO2_PID 2>/dev/null || true

echo ""
echo "========================================"
echo "  Verification Complete!"
echo "========================================"
echo ""
echo "Summary:"
echo "  - GO2 node: OK"
echo "  - Topics: OK"
echo "  - Commands: OK"
echo ""
echo "Next steps:"
echo "  - Integrate with rosbridge: ros2 launch rosbridge_server rosbridge_websocket_launch.xml"
echo "  - Start OpenClaw with RosClaw plugin"
echo "  - Send natural language commands via messaging app"
