---
name: rosclaw-robot-adapter-skill
description: Claude Code Skill 配置 - 在 Claude Code 中调用 RosClaw 机器人适配专家
type: reference
---

# 在 Claude Code 中使用 RosClaw Robot Adapter Skill

## 安装 Skill

Skill 已安装在：`/home/jhq/.agents/skills/rosclaw-robot-adapter/`

符号链接已创建：`~/.claude/skills/rosclaw-robot-adapter -> ~/.agents/skills/rosclaw-robot-adapter`

## 使用方法

### 方式 1: 直接调用 Skill

在 Claude Code 对话中输入：

```
使用 rosclaw-robot-adapter skill 帮我适配一个新的机器人
```

或

```
@rosclaw-robot-adapter 如何配置 Gazebo 仿真？
```

### 方式 2: 通过项目文档参考

项目内的 skill 文档位于：

- `docs/skills/robot-adapter.md` - 完整适配流程
- `docs/skills/robot-adapter-quickref.md` - 快速参考卡
- `docs/skills/rosclaw-robot-adapter.skill.md` - Skill 定义

### 方式 3: 使用项目内 OpenClaw 命令

在 OpenClaw 中执行 `/robot-adapt` 命令：

```bash
/robot-adapt help
/robot-adapt start -n "MyRobot" -t simulation
/robot-adapt generate -n "MyRobot" -m rosbridge
```

## Skill 能力

当调用此 Skill 时，我会：

1. **分析机器人接口** - 帮你识别 ROS2 话题和消息类型
2. **设计话题映射** - 将机器人话题映射到 RosClaw 标准
3. **生成配置文件** - 创建 Docker Compose、桥接节点代码
4. **配置 OpenClaw** - 更新 plugin.json 配置
5. **验证测试** - 提供验证命令和测试流程

## 示例对话

```
用户：我要适配一个 Webero 移动机器人到 RosClaw

Skill: 好的，我来帮你适配 Webero 移动机器人。首先让我分析现有配置...

1. 请提供 Webero 的 ROS2 话题列表：
   ros2 topic list

2. 确认里程计话题类型：
   ros2 topic info /webero/odom --verbose

3. 我将生成话题映射和桥接节点代码...
```

## 相关配置

查看 `~/.claude/settings.json` 中的 `enabledPlugins` 确认相关插件已启用：

- `serena@claude-plugins-official` - 代码语义搜索
- `everything-claude-code` - 项目特定技能

## 故障排查

如果 Skill 无法加载：

```bash
# 检查符号链接
ls -la ~/.claude/skills/rosclaw-robot-adapter

# 重新创建链接
ln -sf /home/jhq/.agents/skills/rosclaw-robot-adapter ~/.claude/skills/rosclaw-robot-adapter

# 验证文件存在
cat ~/.claude/skills/rosclaw-robot-adapter/SKILL.md
```
