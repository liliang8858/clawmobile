# 技术设计文档（TDD）

> Claw Mobile - Technical Design Document
>
> Version: 1.0 | Target: iOS App + OpenClaw Gateway

---

## 1. 概述

### 1.1 背景

OpenClaw 是一个本地运行的 AI Agent Runtime，支持 Shell 执行、文件系统操作、浏览器自动化和 API 调用。当前控制方式（Terminal / Telegram / Discord）缺乏完整的 GUI 控制层。

### 1.2 目标

开发 iOS 客户端 **Claw Mobile**，提供：

- 远程 Agent 控制
- 会话聊天（流式响应）
- 工具执行审批
- 任务自动化管理
- Agent 状态监控

### 1.3 设计原则

| 原则 | 说明 |
|------|------|
| 实时性 | WebSocket 流式通信，毫秒级响应 |
| 可观察性 | Agent 运行状态完全可视化 |
| 安全性 | Token 认证 + 设备绑定 + 操作审批 |
| 可扩展性 | 模块化架构，为 V2+ 预留接口 |

---

## 2. 系统架构

系统分为三层：

```
┌──────────────────────────┐
│      iOS Client          │
│   SwiftUI / MVVM         │
└────────────┬─────────────┘
             │ HTTPS / WebSocket
┌────────────▼─────────────┐
│    OpenClaw Gateway      │
│  Auth / Session / Tasks  │
└────────────┬─────────────┘
             │
┌────────────▼─────────────┐
│     OpenClaw Core        │
│  Agent / Tools / Memory  │
└──────────────────────────┘
```

### 核心组件

| 组件 | 职责 |
|------|------|
| iOS Client | UI 渲染、用户交互、本地缓存 |
| Gateway | API 抽象、认证、会话路由、WebSocket 流、任务调度 |
| Core | Agent 运行时、工具执行引擎、记忆存储 |

---

## 3. API 设计

### 3.1 认证

**POST /auth/connect**

```json
// Request
{
  "token": "xxxxx",
  "device_id": "iphone-uuid-123"
}

// Response
{
  "agent_id": "agent-001",
  "agent_name": "local-agent",
  "model": "claude-sonnet-4",
  "permissions": ["chat", "tasks", "tools"]
}
```

连接协议：`claw://connect?token=xxxxx`

### 3.2 会话管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /sessions | 获取会话列表 |
| POST | /sessions | 创建新会话 |
| DELETE | /sessions/{id} | 删除会话 |

**GET /sessions Response:**

```json
[
  {
    "id": "session-001",
    "name": "Startup",
    "created_at": "2024-01-15T10:00:00Z",
    "message_count": 24,
    "is_active": true
  }
]
```

### 3.3 聊天

**POST /chat**

```json
// Request
{
  "session_id": "session-001",
  "message": "Summarize today's GitHub issues"
}

// Response
{
  "stream_id": "stream-789"
}
```

消息通过 WebSocket 流式返回。

### 3.4 任务管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /tasks | 获取任务列表 |
| POST | /tasks | 创建任务 |
| POST | /tasks/{id}/run | 手动运行任务 |
| DELETE | /tasks/{id} | 删除任务 |

**POST /tasks Request:**

```json
{
  "name": "Daily Research",
  "prompt": "Find AI news and summarize",
  "schedule": "0 9 * * *"
}
```

### 3.5 工具审批

**POST /tool/approve**

```json
{
  "request_id": "req-123",
  "decision": "approve"  // or "deny"
}
```

### 3.6 记忆

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /memory | 获取记忆列表 |
| POST | /memory | 新增记忆 |
| DELETE | /memory/{id} | 删除记忆 |

### 3.7 Agent 状态

**GET /agent/status**

```json
{
  "status": "online",
  "model": "claude-sonnet-4",
  "cpu_usage": 23.5,
  "memory_usage": 45.2,
  "token_usage": 128450,
  "active_tasks": 3,
  "uptime": 273600
}
```

---

## 4. WebSocket 协议

连接地址：`ws://agent.local/ws`

### 事件类型

所有事件遵循统一格式：

```json
{
  "type": "event_type",
  "data": { }
}
```

| 事件类型 | 说明 | 方向 |
|---------|------|------|
| `chat_token` | 流式文本 Token | Server → Client |
| `tool_call` | Agent 调用工具 | Server → Client |
| `tool_result` | 工具执行结果 | Server → Client |
| `approval_request` | 请求用户审批 | Server → Client |
| `approval_response` | 用户审批结果 | Client → Server |
| `task_update` | 任务状态变更 | Server → Client |

### 示例

**chat_token** — 流式响应：
```json
{ "type": "chat_token", "data": { "token": "Hello" } }
{ "type": "chat_token", "data": { "token": " world" } }
```

**tool_call** — Agent 调用工具：
```json
{ "type": "tool_call", "data": { "tool": "shell", "command": "ls -la" } }
```

**approval_request** — 危险操作审批：
```json
{ "type": "approval_request", "data": { "request_id": "req-123", "tool": "shell", "command": "rm -rf /tmp" } }
```

---

## 5. 数据模型

### 5.1 Agent

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | Agent 唯一标识 |
| name | String | Agent 名称 |
| model | String | 使用的 LLM 模型 |
| status | Enum | online / offline / busy |
| tools | [String] | 已启用工具列表 |
| memorySize | Int | 记忆条目数 |
| cpuUsage | Double | CPU 使用率 (%) |
| memoryUsage | Double | 内存使用率 (%) |
| tokenUsage | Int | 累计 Token 消耗 |
| uptime | TimeInterval | 运行时长（秒） |

### 5.2 Session

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 会话唯一标识 |
| name | String | 会话名称 |
| lastMessage | String | 最后一条消息摘要 |
| createdAt | Date | 创建时间 |
| messageCount | Int | 消息总数 |
| isActive | Bool | 是否活跃 |

### 5.3 Message

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 消息唯一标识 |
| role | Enum | user / agent / tool / system |
| content | String | 消息文本内容 |
| toolCall | ToolCall? | 关联的工具调用（可选） |
| timestamp | Date | 消息时间戳 |
| isStreaming | Bool | 是否正在流式输出 |

**ToolCall 子结构：**

| 字段 | 类型 | 说明 |
|------|------|------|
| tool | String | 工具名称 |
| command | String | 执行命令 |
| result | String? | 执行结果 |
| status | Enum | pending / running / completed / failed / awaitingApproval |
| requiresApproval | Bool | 是否需要用户审批 |

### 5.4 AgentTask

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 任务唯一标识 |
| name | String | 任务名称 |
| prompt | String | 执行提示词 |
| schedule | String | Cron 表达式 |
| status | Enum | running / scheduled / completed / failed |
| createdAt | Date | 创建时间 |
| lastRunAt | Date? | 上次运行时间 |
| nextRunAt | Date? | 下次运行时间 |

### 5.5 MemoryItem

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 记忆唯一标识 |
| content | String | 记忆内容 |
| category | Enum | fact / preference / knowledge |
| createdAt | Date | 创建时间 |
| isPinned | Bool | 是否置顶 |

---

## 6. iOS 客户端架构

### 6.1 技术选型

| 项目 | 选择 | 说明 |
|------|------|------|
| UI 框架 | SwiftUI | 声明式 UI，原生支持 |
| 架构模式 | MVVM | View / ViewModel / Model 分离 |
| 状态管理 | @Observable | Swift 5.9+ Observation 框架 |
| 环境注入 | @Environment | 通过 SwiftUI Environment 传递依赖 |
| 构建工具 | XcodeGen | 通过 YAML 管理项目配置 |
| 国际化 | 自定义 L10n | @Observable 单例，运行时切换语言 |

### 6.2 模块结构

```
App
├── Models/           数据模型（Agent, Session, Message, AgentTask, MemoryItem）
├── ViewModels/       视图模型（AppState, ChatViewModel, SessionsViewModel...）
├── Views/            UI 视图（按功能模块分目录）
│   ├── Sessions/
│   ├── Chat/
│   ├── Tasks/
│   ├── Memory/
│   └── Settings/
└── Services/         服务层（MockService, L10n）
```

### 6.3 状态管理

```
AppState (@Observable)
├── isConnected: Bool
├── connectedAgent: Agent?
├── isConnecting: Bool
└── connectionError: String?

L10n (@Observable, Singleton)
├── language: AppLanguage (.zh | .en)
└── 所有 UI 字符串的计算属性
```

### 6.4 聊天流程

```
用户输入消息
    ↓
ChatViewModel.sendMessage()
    ↓
POST /chat（MVP 阶段使用 Mock）
    ↓
WebSocket 接收 chat_token 事件
    ↓
逐字追加到 Message.content
    ↓
SwiftUI 自动刷新 UI
```

---

## 7. 安全设计

### 7.1 认证

| 措施 | 说明 |
|------|------|
| JWT Token | 连接时生成，包含 agent_id、权限、过期时间 |
| Device Binding | Token 绑定 device_id，防止 Token 被盗用 |
| Token 过期 | 设定合理过期时间，需要定期重新认证 |

### 7.2 权限范围

| 权限 | 说明 |
|------|------|
| chat | 发送消息、查看会话 |
| tasks | 管理自动化任务 |
| tools | 查看工具日志 |
| admin | 修改 Agent 配置 |

### 7.3 工具审批

高风险工具必须经过用户审批：

| 工具类型 | 风险等级 | 需要审批 |
|---------|---------|---------|
| shell | 高 | 是 |
| filesystem (写/删) | 高 | 是 |
| network (外部请求) | 中 | 可配置 |
| read_file | 低 | 否 |
| search | 低 | 否 |

---

## 8. 错误处理

### WebSocket 断线重连

```
连接断开
    ↓
等待 1s → 第 1 次重试
    ↓
等待 2s → 第 2 次重试
    ↓
等待 4s → 第 3 次重试
    ↓
显示 "连接断开" 提示，提供手动重连按钮
```

策略：指数退避（Exponential Backoff），最多 3 次自动重试。

---

## 9. 本地缓存（V1.1 规划）

| 数据 | 存储方式 | 说明 |
|------|---------|------|
| 语言设置 | UserDefaults | 轻量配置 |
| 会话列表 | SQLite | 离线浏览 |
| 聊天记录 | SQLite | 历史消息查看 |
| 任务列表 | SQLite | 离线查看状态 |

---

## 10. 扩展架构（未来版本）

| 版本 | 扩展方向 | 技术考量 |
|------|---------|---------|
| V2 | 语音 Agent | iOS Speech Framework + 流式 STT/TTS |
| V3 | 多 Agent | Agent 路由层、Agent 间通信协议 |
| V4 | Skill 市场 | Plugin 注册表、沙箱执行环境 |
| V5 | 团队协作 | 多用户权限、共享 Session |
