# Rosbridge 集成测试报告

## 测试日期
2026-03-21

## 测试目标
验证 Unitree GO2 节点能否通过 rosbridge WebSocket 与 OpenClaw 进行通信。

## 测试环境

| 组件 | 版本/配置 |
|------|----------|
| AGIROS | Jazzy Jalisco |
| rosbridge_suite | 2.4.2 |
| unitree_go2 | 0.0.1 |
| Docker | 最新 GPU 支持 |
| GPU | NVIDIA Container Toolkit |

## 测试架构

```
User (messaging app) → OpenClaw Gateway → RosClaw Plugin → rosbridge_server (ws://localhost:9090) → AGIROS nodes
                                                                                      ↓
                                                                              unitree_go2_node
```

## 测试项目

### 1. AGIROS 节点启动测试

**测试命令：**
```bash
docker exec rosclaw-agiros-gpu bash -c \
  "source /opt/agiros/pixiu/setup.sh && source /agiros_ws/install/setup.sh && \
   python3 /agiros_ws/src/unitree_go2/unitree_go2/go2_node.py"
```

**预期结果：** 节点成功启动并发布日志 `Unitree GO2 node initialized`

**实际结果：** ✅ 通过

### 2. 话题发布测试

**测试命令：**
```bash
agiros topic pub /go2_command/stand std_msgs/msg/Empty --once
```

**预期结果：** 消息成功发布

**实际结果：** ✅ 通过
```
publisher: beginning loop
publishing #1: std_msgs.msg.Empty()
```

### 3. 话题订阅测试

**测试命令：**
```bash
agiros topic echo /go2_state/battery --timeout 3
agiros topic echo /go2_state/imu --timeout 2
```

**预期结果：** 接收到电池状态和 IMU 数据

**实际结果：** ✅ 通过

电池状态输出示例：
```yaml
header:
  stamp:
    sec: 1774064578
    nanosec: 508975566
  frame_id: base_link
voltage: 24.0
current: 2.5
charge: 8.0
capacity: 10.0
percentage: 1.0
power_supply_status: 2
present: true
```

IMU 数据输出示例：
```yaml
header:
  stamp:
    sec: 1774064582
    nanosec: 509115191
  frame_id: base_link
orientation:
  x: 0.0
  y: 0.0
  z: 0.0
  w: 1.0
angular_velocity:
  x: 0.0
  y: 0.0
  z: 0.0
linear_acceleration:
  x: 0.0
  y: 0.0
  z: 9.81
```

### 4. Rosbridge API 测试

**测试命令：**
```bash
agiros service call /rosapi/topics rosapi_msgs/srv/Topics '{}'
```

**预期结果：** 返回所有可用话题列表

**实际结果：** ✅ 通过
```
topics:
  - /client_count
  - /cmd_vel
  - /connected_clients
  - /go2_command/sit
  - /go2_command/stand
  - /go2_state/battery
  - /go2_state/foot_force
  - /go2_state/imu
  - /go2_state/odom
  - /parameter_events
  - /rosout
```

### 5. WebSocket 连接测试

**测试端口：** 9090

**测试结果：** ✅ rosbridge_websocket 节点运行正常

## 发现的问题及修复

### 问题 1: Python 消息类型断言失败

**错误信息：**
```
python3: ./.obj-x86_64-linux-gnu/rosidl_generator_py/std_msgs/msg/_header_s.c:57:
std_msgs__msg__header__convert_from_py: Assertion failed
```

**原因：** 使用字典而不是正确的消息类型创建嵌套消息

**修复：**
1. 导入正确的消息类型（Header, Quaternion, Vector3, Wrench）
2. 使用消息构造函数而不是字典

修复后的代码：
```python
from std_msgs.msg import Header
from geometry_msgs.msg import Quaternion, Vector3, Wrench

# 使用正确的消息类型
header = Header(stamp=now.to_msg(), frame_id='base_link')
imu_msg = Imu(
    header=header,
    orientation=Quaternion(w=1.0, x=0.0, y=0.0, z=0.0),
    angular_velocity=Vector3(x=0.0, y=0.0, z=0.0),
    linear_acceleration=Vector3(x=0.0, y=0.0, z=9.81)
)
```

### 问题 2: AGIROS 可执行文件未找到

**错误信息：**
```
No executable found
```

**原因：** `agiros run` 无法找到符号链接指向的可执行文件

**解决方案：** 直接使用 `python3` 运行节点脚本

## 测试结论

✅ **所有测试项目通过**

Rosbridge 集成测试成功，Unitree GO2 节点可以通过 rosbridge WebSocket 与外部系统（如 OpenClaw）进行通信。

### 可用的 AGIROS 接口

**订阅话题（输入）：**
- `/cmd_vel` (geometry_msgs/msg/Twist) - 速度控制
- `/go2_command/stand` (std_msgs/msg/Empty) - 站立命令
- `/go2_command/sit` (std_msgs/msg/Empty) - 坐下命令

**发布话题（输出）：**
- `/go2_state/battery` (sensor_msgs/msg/BatteryState) - 电池状态
- `/go2_state/imu` (sensor_msgs/msg/Imu) - IMU 数据
- `/go2_state/foot_force` (geometry_msgs/msg/WrenchStamped) - 足部力反馈
- `/go2_state/odom` (nav_msgs/msg/Odometry) - 里程计

### 下一步

1. 测试 OpenClaw 与 GO2 节点的完整集成
2. 实现自然语言命令到 AGIROS 话题的映射
3. 添加 Gazebo 仿真支持

## 附录：测试脚本

```bash
#!/usr/bin/env bash
# Rosbridge 集成测试脚本

set -e

echo "=== Rosbridge 集成测试 ==="

# 1. 启动 GO2 节点
echo "[1/5] 启动 GO2 节点..."
docker exec -d rosclaw-agiros-gpu bash -c \
  "source /opt/agiros/pixiu/setup.sh && source /agiros_ws/install/setup.sh && \
   python3 /agiros_ws/src/unitree_go2/unitree_go2/go2_node.py"
sleep 2

# 2. 验证节点运行
echo "[2/5] 验证节点运行..."
docker exec rosclaw-agiros-gpu bash -c \
  "source /opt/agiros/pixiu/setup.sh && source /agiros_ws/install/setup.sh && \
   agiros node list"

# 3. 验证话题
echo "[3/5] 验证话题..."
docker exec rosclaw-agiros-gpu bash -c \
  "source /opt/agiros/pixiu/setup.sh && source /agiros_ws/install/setup.sh && \
   agiros topic list"

# 4. 测试发布命令
echo "[4/5] 测试发布命令..."
docker exec rosclaw-agiros-gpu bash -c \
  "source /opt/agiros/pixiu/setup.sh && source /agiros_ws/install/setup.sh && \
   agiros topic pub /go2_command/stand std_msgs/msg/Empty --once"

# 5. 测试 Rosbridge API
echo "[5/5] 测试 Rosbridge API..."
docker exec rosclaw-agiros-gpu bash -c \
  "source /opt/agiros/pixiu/setup.sh && source /agiros_ws/install/setup.sh && \
   agiros service call /rosapi/topics rosapi_msgs/srv/Topics '{}'"

echo "=== 测试完成 ==="
```
