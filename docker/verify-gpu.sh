#!/bin/bash
# GPU 验证脚本 - 验证 Docker 容器中的 GPU 支持

set -e

echo "=== NVIDIA GPU 验证 ==="

# 1. 检查 NVIDIA 驱动
echo -e "\n[1/4] 检查 NVIDIA 驱动..."
if ! command -v nvidia-smi &> /dev/null; then
    echo "❌ nvidia-smi 未找到，请安装 NVIDIA 驱动"
    exit 1
fi
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
echo "✓ NVIDIA 驱动正常"

# 2. 检查 NVIDIA Container Toolkit
echo -e "\n[2/4] 检查 NVIDIA Container Toolkit..."
if ! command -v nvidia-container-toolkit &> /dev/null; then
    echo "❌ NVIDIA Container Toolkit 未安装"
    exit 1
fi
echo "✓ NVIDIA Container Toolkit 已安装"

# 3. 检查 Docker runtime
echo -e "\n[3/4] 检查 Docker runtime..."
if ! docker info 2>/dev/null | grep -q "nvidia"; then
    echo "⚠️  警告：Docker info 中未找到 nvidia runtime"
    echo "   请确保 /etc/docker/daemon.json 中包含:"
    echo '   {"default-runtime": "nvidia", "runtimes": {"nvidia": {"path": "nvidia-container-runtime", "runtimeArgs": []}}}'
else
    echo "✓ Docker nvidia runtime 已配置"
fi

# 4. 测试容器中的 GPU
echo -e "\n[4/4] 测试容器中的 GPU 访问..."
if docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi 2>/dev/null; then
    echo "✓ 容器 GPU 访问测试通过"
else
    echo "⚠️  容器 GPU 访问测试失败，尝试使用基础镜像测试..."
    if docker run --rm --gpus all ubuntu:22.04 nvidia-smi 2>/dev/null; then
        echo "✓ 容器 GPU 访问测试通过（ubuntu 镜像）"
    else
        echo "❌ 容器 GPU 访问失败"
        echo "   请检查:"
        echo "   1. NVIDIA Container Toolkit 配置：sudo nvidia-ctk runtime configure --runtime=docker"
        echo "   2. 重启 Docker: sudo systemctl restart docker"
        exit 1
    fi
fi

echo -e "\n=== GPU 验证完成 ==="
