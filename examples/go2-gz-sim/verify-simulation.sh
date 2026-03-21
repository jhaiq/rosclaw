#!/usr/bin/env bash
# Unitree GO2 humble Simulation Verification Script
# Usage: ./verify-simulation.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROSCLAW_ROOT="$SCRIPT_DIR/../.."

echo "========================================"
echo "  GO2 Gazebo Simulation Verification"
echo "========================================"
echo ""

# Source ROS2
echo "[1/6] Sourcing ROS2..."
source /opt/ros/humble/setup.sh

# Source workspace if exists
if [[ -f "$ROSCLAW_ROOT/ros2_ws/install/setup.sh" ]]; then
    source "$ROSCLAW_ROOT/ros2_ws/install/setup.sh"
    echo "[OK] Workspace sourced"
else
    echo "[WARN] Workspace not built yet"
fi
echo ""

# Check Docker containers
echo "[2/6] Checking Docker containers..."
cd "$ROSCLAW_ROOT/docker"
if docker compose -f docker-compose.go2-gz.yml --profile go2-gz ps | grep -q "go2-gz-sim"; then
    echo "[OK] GO2 Gazebo container running"
else
    echo "[WARN] GO2 Gazebo container not running"
    echo "  Start with: make go2-gz-start"
fi
echo ""

# Check ROS2 nodes
echo "[3/6] Checking ROS2 nodes..."
NODES=$(ros2 node list 2>/dev/null || echo "")
if echo "$NODES" | grep -q "go2_gz_bridge"; then
    echo "[OK] GO2 bridge node running"
else
    echo "[WARN] GO2 bridge node not running"
fi
echo ""

# Check topics
echo "[4/6] Checking ROS2 topics..."
TOPICS=$(ros2 topic list 2>/dev/null || echo "")
REQUIRED_TOPICS=("/cmd_vel" "/go2_state/odom" "/go2_state/battery" "/scan")

for topic in "${REQUIRED_TOPICS[@]}"; do
    if echo "$TOPICS" | grep -q "$topic"; then
        echo "[OK] Topic $topic available"
    else
        echo "[WARN] Topic $topic not found"
    fi
done
echo ""

# Test publishing
echo "[5/6] Testing velocity command..."
ros2 topic pub /cmd_vel geometry_msgs/msg/Twist \
  "{linear: {x: 0.1}, angular: {z: 0.0}}" --once
echo "[OK] Velocity command published"
echo ""

# Test service call
echo "[6/6] Testing stand command..."
ros2 topic pub /go2_command/stand std_msgs/msg/Empty --once
echo "[OK] Stand command published"
echo ""

echo "========================================"
echo "  Verification Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Start OpenClaw with RosClaw plugin"
echo "  2. Send natural language commands:"
echo "     - '向前走 1 米'"
echo "     - '站起来'"
echo "     - '向左转 90 度'"
echo ""
