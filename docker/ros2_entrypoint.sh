#!/bin/bash
set -e

# Source AGIROS and workspace
source /opt/agiros/pixiu/setup.bash
if [ -f /agiros_ws/install/setup.bash ]; then
  source /agiros_ws/install/setup.bash
fi

exec "$@"
