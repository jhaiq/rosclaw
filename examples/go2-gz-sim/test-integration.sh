#!/usr/bin/env bash
# GO2 Gazebo Integration Test
# Tests the full stack from ROS2 topics to OpenClaw tools

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROSCLAW_ROOT="$SCRIPT_DIR/../.."

echo "========================================"
echo "  GO2 Gazebo Integration Test"
echo "========================================"
echo ""

PASSED=0
FAILED=0

test_result() {
    if [[ $1 -eq 0 ]]; then
        echo "[PASS] $2"
        ((PASSED++))
    else
        echo "[FAIL] $2"
        ((FAILED++))
    fi
}

# Source ROS2
source /opt/ros/jazzy/setup.sh

# Source workspace if exists
if [[ -f "$ROSCLAW_ROOT/ros2_ws/install/setup.sh" ]]; then
    source "$ROSCLAW_ROOT/ros2_ws/install/setup.sh"
fi

# Test 1: Bridge node publishes expected topics
echo "[Test 1] Bridge node publishes expected topics..."
TOPICS=$(ros2 topic list 2>/dev/null || echo "")

echo "$TOPICS" | grep -q "/go2_state/odom"
test_result $? "Odom topic available"

echo "$TOPICS" | grep -q "/go2_state/battery"
test_result $? "Battery topic available"

echo "$TOPICS" | grep -q "/go2_state/imu"
test_result $? "IMU topic available"

echo "$TOPICS" | grep -q "/scan"
test_result $? "Scan topic available"

echo "$TOPICS" | grep -q "/joint_states"
test_result $? "Joint states topic available"
echo ""

# Test 2: Velocity commands are forwarded
echo "[Test 2] Velocity commands are forwarded to Gazebo..."
ros2 topic pub /cmd_vel geometry_msgs/msg/Twist \
  "{linear: {x: 0.5}, angular: {z: 0.0}}" --once

# Check if /go2_gz_sim/cmd_vel topic exists
GO2_CMD_TOPICS=$(ros2 topic list 2>/dev/null || echo "")
echo "$GO2_CMD_TOPICS" | grep -q "/go2_gz_sim/cmd_vel"
if [[ $? -eq 0 ]]; then
    test_result 0 "Velocity command topic available"
else
    test_result 1 "Velocity command topic not found"
fi

# Test publishing to go2_gz_sim/cmd_vel
ros2 topic pub /go2_gz_sim/cmd_vel geometry_msgs/msg/Twist \
  "{linear: {x: 0.3}, angular: {z: 0.1}}" --once 2>/dev/null
test_result $? "Can publish to go2_gz_sim/cmd_vel"
echo ""

# Test 3: OpenClaw GO2 tools are defined
echo "[Test 3] OpenClaw GO2 tools..."
if [[ -f "$ROSCLAW_ROOT/extensions/openclaw-plugin/src/tools/go2-commands.ts" ]]; then
    test_result 0 "GO2 tools file exists"

    # Check for expected tool definitions
    grep -q "go2StandTool" "$ROSCLAW_ROOT/extensions/openclaw-plugin/src/tools/go2-commands.ts"
    test_result $? "go2_stand tool defined"

    grep -q "go2SitTool" "$ROSCLAW_ROOT/extensions/openclaw-plugin/src/tools/go2-commands.ts"
    test_result $? "go2_sit tool defined"

    grep -q "go2StopTool" "$ROSCLAW_ROOT/extensions/openclaw-plugin/src/tools/go2-commands.ts"
    test_result $? "go2_stop tool defined"

    grep -q "go2MoveTool" "$ROSCLAW_ROOT/extensions/openclaw-plugin/src/tools/go2-commands.ts"
    test_result $? "go2_move tool defined"
else
    test_result 1 "GO2 tools file missing"
fi
echo ""

# Test 4: Docker Compose configuration
echo "[Test 4] Docker Compose configuration..."
cd "$ROSCLAW_ROOT/docker"
if [[ -f "docker-compose.go2-gz.yml" ]]; then
    test_result 0 "docker-compose.go2-gz.yml exists"

    # Validate YAML syntax
    docker compose -f docker-compose.go2-gz.yml config > /dev/null 2>&1
    test_result $? "docker-compose.go2-gz.yml is valid YAML"
else
    test_result 1 "docker-compose.go2-gz.yml missing"
fi

# Check Makefile targets
if grep -q "go2-gz-start" Makefile; then
    test_result 0 "Makefile has go2-gz-start target"
else
    test_result 1 "Makefile missing go2-gz-start target"
fi
echo ""

# Test 5: Verification script
echo "[Test 5] Verification script..."
if [[ -x "$ROSCLAW_ROOT/examples/go2-gz-sim/verify-simulation.sh" ]]; then
    test_result 0 "verify-simulation.sh is executable"
else
    test_result 1 "verify-simulation.sh not executable"
fi

if [[ -f "$ROSCLAW_ROOT/examples/go2-gz-sim/README.md" ]]; then
    test_result 0 "Example README exists"
else
    test_result 1 "Example README missing"
fi
echo ""

# Summary
echo "========================================"
echo "  Test Summary: $PASSED passed, $FAILED failed"
echo "========================================"

if [[ $FAILED -gt 0 ]]; then
    echo ""
    echo "Some tests failed. Please check the output above."
    exit 1
else
    echo ""
    echo "All tests passed!"
    exit 0
fi
