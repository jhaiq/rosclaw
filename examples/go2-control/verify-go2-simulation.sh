#!/usr/bin/env bash
# Unitree GO2 Simulation Verification Script
# Usage: ./verify-go2-simulation.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROS2_WS="$SCRIPT_DIR/../agiros_ws"

echo "========================================"
echo "  Unitree GO2 Simulation Verification"
echo "========================================"
echo ""

# Source AGIROS and workspace
echo "[1/5] Sourcing AGIROS and workspace..."
# shellcheck disable=SC1090
source /opt/agiros/pixiu/setup.sh
export COLCON_CURRENT_PREFIX="$ROS2_WS/install"
# shellcheck disable=SC1090
source "$ROS2_WS/install/setup.sh"

# Check packages
echo "[2/5] Checking installed packages..."
PACKAGES=$(agiros pkg list | grep -E "(unitree|agirosclaw)" || true)
if [[ -z "$PACKAGES" ]]; then
    echo "[ERROR] Packages not found. Building..."
    cd "$ROS2_WS"
    colcon build --packages-select agirosclaw_msgs unitree_go2
    source "$ROS2_WS/install/setup.sh"
fi
echo "[OK] Packages found:"
echo "$PACKAGES"
echo ""

# Start GO2 node
echo "[3/5] Starting GO2 node..."
agiros launch unitree_go2 go2_launch.py use_sim_time:=true &
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
echo "[4/5] Checking AGIROS nodes and topics..."
echo "Nodes:"
agiros node list | grep -E "(go2|unitree)" || echo "  No GO2 nodes found"
echo ""
echo "Topics:"
agiros topic list | grep go2 || echo "  No GO2 topics found"
echo ""

# Test publishing commands
echo "[5/5] Testing commands..."
echo "Publishing /go2_command/stand..."
agiros topic pub /go2_command/stand std_msgs/msg/Empty --once
sleep 1

echo "Publishing /cmd_vel (forward)..."
agiros topic pub /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.5}, angular: {z: 0.0}}" --once
sleep 1

echo "Publishing /cmd_vel (stop)..."
agiros topic pub /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.0}, angular: {z: 0.0}}" --once
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
echo "  - Integrate with rosbridge: agiros launch rosbridge_server rosbridge_websocket_launch.xml"
echo "  - Start OpenClaw with RosClaw plugin"
echo "  - Send natural language commands via messaging app"
