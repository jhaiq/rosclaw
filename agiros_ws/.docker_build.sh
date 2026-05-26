#!/bin/bash
set -e

echo "Sourcing AGIROS Loong..."
source /opt/agiros/loong/setup.sh

echo "Building unitree_go2 package..."
cd /opt/agirosclaw/agiros_ws
colcon build --packages-select unitree_go2 --symlink-install

echo "Build complete!"
ls -la install/unitree_go2/lib/unitree_go2/
