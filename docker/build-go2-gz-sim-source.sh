#!/bin/bash
# Build go2_gz_sim in Docker container
# Usage: ./docker-build-go2-gz-sim-source.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GO2_GZ_SIM_PATH="${GO2_GZ_SIM_PATH:-/home/jhq/work/code/go2_ws/go2_sim_ws/ROS2-Gazebo-GO2}"

echo "========================================"
echo "  Building go2_gz_sim in Docker"
echo "========================================"
echo "Source path: $GO2_GZ_SIM_PATH"
echo ""

# Create build script inside container
cat > "$GO2_GZ_SIM_PATH/.docker_build.sh" << 'EOF'
#!/bin/bash
set -e

echo "Installing dependencies..."
apt-get update && apt-get install -y \
    agiros-loong-xacro \
    agiros-loong-joint-state-publisher \
    agiros-loong-joint-state-broadcaster \
    agiros-loong-robot-state-publisher \
    agiros-loong-urdf \
    agiros-loong-controller-manager \
    agiros-loong-ros2-control \
    agiros-loong-ros2-controllers \
    agiros-loong-gazebo-ros-pkgs \
    && rm -rf /var/lib/apt/lists/*

echo "Sourcing AGIROS Humble..."
source /opt/agiros/loong/setup.sh

echo "Building go2_gz_sim..."
cd /opt/go2_gz_sim
colcon build --symlink-install

echo "Build complete!"
ls -la install/
EOF

chmod +x "$GO2_GZ_SIM_PATH/.docker_build.sh"

# Run build in Docker container
docker run --rm -v "$GO2_GZ_SIM_PATH:/opt/go2_gz_sim" ros:loong-ros-base \
    bash /opt/go2_gz_sim/.docker_build.sh

# Clean up
rm "$GO2_GZ_SIM_PATH/.docker_build.sh"

echo ""
echo "Build completed successfully!"
echo "You can now run: docker compose -f docker-compose.go2-gz.yml --profile go2-gz up -d"
