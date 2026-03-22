#!/bin/bash
# Build go2_gz_bridge in Docker container
# Usage: ./docker/build-go2-bridge.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROSCLAW_ROOT="$SCRIPT_DIR/.."

echo "========================================"
echo "  Building go2_gz_bridge in Docker"
echo "========================================"
echo ""

# Create build script inside container
cat > "$ROSCLAW_ROOT/ros2_ws/.docker_build.sh" << 'EOF'
#!/bin/bash
set -e

echo "Sourcing ROS2 Humble..."
source /opt/ros/humble/setup.sh

echo "Building unitree_go2 package..."
cd /opt/rosclaw/ros2_ws
colcon build --packages-select unitree_go2 --symlink-install

echo "Build complete!"
ls -la install/unitree_go2/lib/unitree_go2/
EOF

chmod +x "$ROSCLAW_ROOT/ros2_ws/.docker_build.sh"

# Run build in Docker container
docker run --rm -v "$ROSCLAW_ROOT/ros2_ws:/opt/rosclaw/ros2_ws" rosclaw/go2-gz-sim:latest \
    bash /opt/rosclaw/ros2_ws/.docker_build.sh

# Clean up
rm "$ROSCLAW_ROOT/ros2_ws/.docker_build.sh"

echo ""
echo "Build completed successfully!"
