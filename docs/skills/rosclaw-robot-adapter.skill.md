---
name: rosclaw-robot-adapter
description: RosClaw 机器人适配器技能 - 快速适配新机器人或仿真环境到 RosClaw 平台
type: reference
---

# RosClaw Robot Adapter Skill

**技能 ID:** `rosclaw:robot-adapter`
**版本:** 1.0.0
**基于:** Unitree GO2 Gazebo 仿真适配经验

---

## 技能目标

帮助开发者在 **3-12 小时** 内将新的机器人或仿真环境适配到 RosClaw 平台，支持通过自然语言控制。

---

## 适用场景

- ✅ 物理机器人集成 (机械臂、移动底盘、四足机器人等)
- ✅ 机器人仿真集成 (Gazebo、Webots、Isaac Sim 等)
- ✅ 新传感器集成 (激光雷达、相机、IMU 等)
- ✅ 多机器人系统配置

---

## 前置条件

```bash
# 必需
- ROS2 Humble 或更新版本
- Docker + Docker Compose
- Node.js + pnpm (OpenClaw 插件开发)
- 机器人/仿真的 ROS2 接口文档

# 可选 (仿真需要)
- NVIDIA GPU + 驱动 (GPU 加速仿真)
- X11 显示服务器 (GUI 应用)
```

---

## 使用方式

### 模式 1: 完整适配流程

按照 [`robot-adapter.md`](./robot-adapter.md) 的六个阶段执行:

```
1. 确定机器人类型和通信模式 (30 分钟)
2. ROS2 节点/话题分析 (30 分钟)
3. 话题映射设计 (15 分钟)
4. Docker 环境配置 (30 分钟)
5. OpenClaw 插件配置 (15 分钟)
6. 验证测试 (30 分钟)
```

### 模式 2: 快速参考

使用 [`robot-adapter-quickref.md`](./robot-adapter-quickref.md) 进行:
- 快速命令查询
- 常见问题排查
- 文件结构参考

### 模式 3: 示例驱动

参考 GO2 Gazebo 完整实现:
- `docker/docker-compose.go2-gz.yml` - Docker Compose 配置
- `ros2_ws/src/unitree_go2/unitree_go2/go2_gz_bridge.py` - 桥接节点
- `extensions/openclaw-plugin/src/tools/go2-commands.ts` - 机器人命令

---

## 核心产出物

### 1. Docker Compose 配置

```yaml
# docker/docker-compose.robot.yml
services:
  robot-sim:     # 机器人仿真/驱动
  robot-bridge:  # 话题桥接节点
  rosbridge:     # WebSocket 服务
```

### 2. ROS2 桥接节点

```python
# ros2_ws/src/robot_bringup/robot_bringup/bridge_node.py
# - 订阅机器人原生话题
# - 发布到 RosClaw 标准话题
```

### 3. OpenClaw 插件配置

```json
// extensions/openclaw-plugin/openclaw.plugin.json
{
  "rosbridge.url": "ws://localhost:9090",
  "robot.name": "Robot Name"
}
```

### 4. 机器人专用工具 (可选)

```typescript
// extensions/openclaw-plugin/src/tools/robot-commands.ts
// - 坐/站/停止等特定命令
// - 自然语言映射到 ROS2 动作
```

---

## 话题标准

### RosClaw 标准话题规范

| 话题名 | 消息类型 | 方向 | 必需 | 描述 |
|--------|----------|------|------|------|
| `/cmd_vel` | geometry_msgs/Twist | 输入 | ✅ | 速度命令 |
| `/scan` | sensor_msgs/LaserScan | 输入 | ❌ | 激光雷达 |
| `/joint_states` | sensor_msgs/JointState | 输入 | ❌ | 关节状态 |
| `/{robot}_state/odom` | nav_msgs/Odometry | 输入 | ❌ | 里程计 |
| `/{robot}_state/imu` | sensor_msgs/Imu | 输入 | ❌ | IMU |
| `/{robot}_state/battery` | sensor_msgs/BatteryState | 输入 | ❌ | 电池状态 |

### 话题命名约定

- **输入话题** (插件→机器人): 使用 ROS2 标准名称 (`/cmd_vel`, `/goal_pose`)
- **输出话题** (机器人→插件): 使用前缀 `/{robot}_state/` 或 `/scan`

---

## 通信模式

| 模式 | 名称 | 适用 | 配置 |
|------|------|------|------|
| **A** | Local DDS | 同机开发 | `transport.mode: "local"` |
| **B** | rosbridge | Docker 部署 | `transport.mode: "rosbridge"` |
| **C** | WebRTC | 远程机器人 | `transport.mode: "webrtc"` |

---

## 验证清单

```bash
# 基础验证
□ Docker 服务全部 Running
□ rosbridge WebSocket 可访问 (ws://localhost:9090)
□ 桥接话题存在 (ros2 topic list)
□ 话题频率正常 (>10Hz)

# 功能验证
□ OpenClaw 连接成功
□ 自然语言命令识别
□ 工具调用执行
□ 机器人响应正确

# 性能验证
□ 端到端延迟 < 200ms
□ 话题无丢失
□ 长时间运行稳定
```

---

## 故障排查

### 问题 1: 服务启动失败

```bash
# 查看详细日志
docker compose -f docker-compose.robot.yml logs robot-bridge

# 常见原因
- COLCON_CURRENT_PREFIX 未设置
- 工作空间路径错误
- 依赖包未安装
```

### 问题 2: OpenClaw 无法连接

```bash
# 检查 rosbridge 状态
docker compose -f docker-compose.robot.yml logs rosbridge

# 检查网络连通性
curl ws://localhost:9090

# 检查插件配置
cat extensions/openclaw-plugin/openclaw.plugin.json
```

### 问题 3: 话题无数据

```bash
# 检查话题列表
ros2 topic list

# 检查话题频率
ros2 topic hz /topic_name

# 检查桥接节点日志
docker compose -f docker-compose.robot.yml logs robot-bridge
```

---

## 示例命令

```bash
# 启动服务
docker compose -f docker/docker-compose.robot.yml --profile robot up -d

# 查看状态
docker compose -f docker/docker-compose.robot.yml ps

# 查看话题
docker compose -f docker/docker-compose.robot.yml exec rosbridge \
  bash -c "source /opt/ros/humble/setup.sh && ros2 topic list"

# 测试话题
docker compose -f docker/docker-compose.robot.yml exec rosbridge \
  bash -c "source /opt/ros/humble/setup.sh && ros2 topic hz /scan"

# 停止服务
docker compose -f docker/docker-compose.robot.yml --profile robot down
```

---

## 相关文档

- [完整适配流程](./robot-adapter.md) - 详细的七步流程
- [快速参考卡](./robot-adapter-quickref.md) - 速查表和模板
- [GO2 Gazebo 示例](../docker/docker-compose.go2-gz.yml) - 完整实现

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0.0 | 2026-03-23 | 初始版本，基于 GO2 Gazebo 适配经验 |

---

## 贡献者

基于 RosClaw 团队 Unitree GO2 Gazebo 集成经验编写
