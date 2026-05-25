# RosClaw 贡献指南

<!-- AUTO-GENERATED: Contributing guide generated from project structure -->

欢迎为 RosClaw 项目做出贡献！本文档提供开发环境设置、测试流程和代码提交指南。

---

## 目录

- [开发环境设置](#开发环境设置)
- [可用命令](#可用命令)
- [测试流程](#测试流程)
- [代码风格](#代码风格)
- [提交指南](#提交指南)
- [PR 提交清单](#pr-提交清单)

---

## 开发环境设置

### 前置要求

| 工具 | 版本 | 用途 |
|------|------|------|
| Node.js | >= 20.0.0 | TypeScript 运行环境 |
| pnpm | >= 9.0.0 | 包管理器 |
| Docker | 最新版 | AGIROS 容器化部署 |
| NVIDIA Container Toolkit | 可选 | GPU 加速支持 |

### 安装步骤

```bash
# 1. 克隆仓库
git clone https://github.com/PlaiPin/rosclaw.git
cd rosclaw

# 2. 安装依赖
pnpm install

# 3. 创建环境配置
cd docker
cp .env.example .env

# 4. 生成配置文件
make gen-config

# 5. 验证类型检查
cd ..
pnpm typecheck
```

### 目录结构

```
rosclaw/
├── extensions/
│   ├── openclaw-plugin/    # 核心 OpenClaw 扩展
│   └── openclaw-canvas/    # 实时仪表盘 (Phase 3)
├── agiros_ws/src/
│   ├── rosclaw_discovery/  # AGIROS 发现节点
│   ├── rosclaw_msgs/       # AGIROS 消息定义
│   └── rosclaw_agent/      # AGIROS 代理节点
├── docker/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── Makefile
├── docs/                   # 项目文档
└── Makefile               # 项目构建脚本
```

---

## 可用命令

### 开发命令

```bash
# 构建所有包
pnpm build

# 类型检查
pnpm typecheck

# 清理构建产物
pnpm clean

# Docker 操作
make docker-start      # 启动服务
make docker-stop       # 停止服务
make docker-logs       # 查看日志
make gpu-start         # GPU 模式启动
```

### Makefile 命令

| 命令 | 描述 |
|------|------|
| `make setup` | 设置开发环境 |
| `make gen-config` | 生成配置文件 |
| `make build` | 构建所有包 |
| `make typecheck` | 类型检查 |
| `make clean` | 清理构建产物 |
| `make docker-start` | 启动 Docker 服务 |
| `make docker-stop` | 停止 Docker 服务 |

---

## 测试流程

### 运行测试

```bash
# TypeScript 类型检查（主要测试方式）
pnpm typecheck

# 构建验证
pnpm build

# Docker 容器测试
make docker-start
make docker-logs
```

### 编写新测试

目前项目使用 TypeScript 类型检查作为主要质量保证手段。添加新功能时：

1. 确保类型定义完整
2. 使用 Zod 进行运行时验证
3. 在 `docker/` 目录中进行集成测试

### 集成测试流程

```bash
# 1. 构建插件
pnpm build

# 2. 生成配置
make gen-config

# 3. 启动服务
make docker-start

# 4. 验证连接
docker logs 1Panel-openclaw-SRjc | grep "connected"

# 5. 测试功能
# 通过 OpenClaw WebUI 发送测试命令
```

---

## 代码风格

### TypeScript 配置

- **模块系统**: ESM (`"type": "module"`)
- **目标版本**: ES2022
- **模块解析**: NodeNext
- **严格模式**: 启用

### 命名约定

| 类型 | 约定 | 示例 |
|------|------|------|
| AGIROS 包 | `rosclaw_*` 前缀 | `rosclaw_discovery` |
| npm 包 | `@rosclaw/` 作用域 | `@rosclaw/openclaw-plugin` |
| TypeScript 类 | PascalCase | `RosbridgeClient` |
| 函数/变量 | camelCase | `sendMessage` |
| 常量 | UPPER_SNAKE_CASE | `DEFAULT_PORT` |
| 文件 | kebab-case | `generate-plugin-config.sh` |

### 代码组织

```typescript
// 1. 导入顺序
import { z } from 'zod'              // 第三方依赖
import { utils } from './utils'       // 内部模块
import type { Config } from './types' // 类型导入

// 2. 配置验证使用 Zod
const configSchema = z.object({
  rosbridge: z.object({
    url: z.string().url()
  })
})

// 3. 导出顺序
export type { Config }    // 类型导出
export { parseConfig }    // 函数导出
export default RosClaw    // 默认导出
```

### Git 提交规范

遵循 Conventional Commits：

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**类型**:
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `chore`: 构建/工具配置
- `refactor`: 代码重构
- `test`: 测试相关

**示例**:
```
feat(plugin): add WebRTC transport support
fix(docker): correct X11 volume mount path
docs: update GPU acceleration guide
chore: update pnpm lockfile
```

---

## PR 提交清单

在提交 Pull Request 之前，请确保：

### 代码质量

- [ ] 代码通过 `pnpm typecheck` 类型检查
- [ ] 代码通过 `pnpm build` 构建成功
- [ ] 遵循项目代码风格
- [ ] 添加了必要的类型定义

### 测试验证

- [ ] 本地 Docker 环境测试通过
- [ ] 与 OpenClaw 集成测试通过
- [ ] 相关功能手动验证通过

### 文档更新

- [ ] 更新了 `docs/README.md` 中的命令/环境变量表
- [ ] 添加了新功能的使用示例
- [ ] 如有必要，更新了 `CLAUDE.md`

### Git 规范

- [ ] 提交信息符合 Conventional Commits
- [ ] 分支命名清晰（如 `feature/gpu-support`, `fix/conn-error`）
- [ ] PR 描述包含变更说明和测试步骤

---

## 问题排查

如遇到问题，请先查看 [troubleshooting.md](troubleshooting.md)：

```bash
# 诊断命令
make status           # 查看状态
make docker-logs      # 查看日志
make validate         # 验证配置
docker compose ps     # 容器状态
```

---

## 联系方式

- 项目仓库：https://github.com/PlaiPin/rosclaw
- 作者：PlaiPin
- 许可证：Apache-2.0

---

<!-- END AUTO-GENERATED -->
