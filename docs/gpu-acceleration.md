# RosClaw GPU 加速配置指南

## 概述

RosClaw 支持使用 NVIDIA GPU 加速 Gazebo 仿真。默认情况下使用 CPU 渲染，启用 GPU 加速需要系统安装 NVIDIA Container Toolkit。

## 前提条件

### 1. 安装 NVIDIA 驱动

```bash
# 检查 NVIDIA 驱动
nvidia-smi
```

预期输出显示 GPU 信息和驱动版本。

### 2. 安装 NVIDIA Container Toolkit

```bash
# Ubuntu/Debian
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
```

### 3. 配置 Docker runtime

```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### 4. 验证安装

```bash
# 运行测试容器
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

如果显示 GPU 信息，说明安装成功。

## 启用 GPU 加速

### 方法一：使用 GPU profile（推荐）

```bash
# 停止 CPU 版本容器
cd docker
docker compose stop ros2

# 启动 GPU 版本容器
docker compose --profile gpu up -d ros2-gpu
```

### 方法二：修改 .env 配置

在 `docker/.env` 中设置：

```bash
ROSCLAW_ENABLE_GPU=true
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute
```

然后使用：

```bash
docker compose --profile gpu up -d
```

## 验证 GPU 加速

### 1. 运行验证脚本

```bash
cd docker
bash verify-gpu.sh
```

### 2. 检查容器内 GPU 状态

```bash
docker exec -it rosclaw-ros2-gpu nvidia-smi
```

### 3. 检查 Gazebo 渲染器

```bash
docker exec -it rosclaw-ros2-gpu glxinfo | grep "OpenGL renderer"
```

应该显示 NVIDIA GPU 而不是 llvmpipe。

## 性能对比

| 场景 | CPU 渲染 | GPU 渲染 |
|------|----------|----------|
| Gazebo 启动时间 | ~10-15 秒 | ~3-5 秒 |
| 仿真帧率 | 15-30 FPS | 60+ FPS |
| 多机器人仿真 | 卡顿 | 流畅 |
| 激光雷达扫描 | 延迟明显 | 实时 |

## 故障排除

### 问题 1: 容器启动失败

```bash
# 查看日志
docker compose logs ros2-gpu

# 常见错误：找不到 nvidia runtime
# 解决：确保已运行 sudo nvidia-ctk runtime configure --runtime=docker
```

### 问题 2: Gazebo 黑屏

```bash
# 检查 DISPLAY 环境变量
docker exec rosclaw-ros2-gpu echo $DISPLAY

# 确保 X11 权限开放
xhost +local:docker
```

### 问题 3: GPU 未被使用

```bash
# 检查容器内 NVIDIA 状态
docker exec rosclaw-ros2-gpu nvidia-smi

# 如果没有输出，检查 .env 中的 NVIDIA_VISIBLE_DEVICES 设置
```

### 问题 4: Docker Compose 警告

```
WARN: The "profiles" key is deprecated
```

这是正常警告，`profiles` 功能仍可使用。或者使用 `docker compose up -d ros2-gpu` 直接指定服务。

## 切换回 CPU 模式

```bash
# 停止 GPU 容器
docker compose --profile gpu stop ros2-gpu

# 启动 CPU 容器
docker compose up -d ros2
```

## 注意事项

1. **X11 转发**: Gazebo 需要 X11 显示，确保 `/tmp/.X11-unix` 挂载正确
2. **GPU 内存**: 建议至少 4GB 显存用于 3D 仿真
3. **多 GPU 系统**: 设置 `NVIDIA_VISIBLE_DEVICES=0` 指定使用 GPU 0
4. **WSL2**: WSL2 需要额外配置才能支持 GPU 加速

## 相关链接

- [NVIDIA Container Toolkit 文档](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/)
- [Docker GPU 支持](https://docs.docker.com/config/containers/resource_constraints/#gpu)
- [Gazebo 性能优化](https://gazebosim.org/docs/latest/graphics)
