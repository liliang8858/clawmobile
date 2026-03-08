# 产品需求文档（PRD）

> Claw Mobile - Your AI Agent Control Center
>
> Version: 1.0 | Status: MVP

## 1. 产品定义

### 1.1 产品名称

**Claw Mobile**

### 1.2 定位

OpenClaw 生态的 iOS 移动控制中心。

### 1.3 核心理念

Claw Mobile 不是一个 AI 聊天客户端，而是 AI Agent 的图形化控制界面：

| 概念 | 类比 |
|------|------|
| AI Agent | Digital Worker |
| Chat | Command Line |
| Claw Mobile | GUI / Control Panel |

一句话定义：**"Cursor for AI Agents."**

### 1.4 不是什么

- 不是 ChatGPT 客户端
- 不是通用 AI 聊天工具
- 不是 Telegram/Discord 的替代品

### 1.5 是什么

- Agent 的远程控制面板
- 任务自动化的管理器
- Agent 执行操作的安全审批层
- Agent 运行状态的监控仪表盘

---

## 2. 核心用户场景

### 场景 1：远程控制 Agent

用户在电脑上运行 OpenClaw Agent，通过手机随时随地：
- 查看 Agent 状态
- 发送指令
- 查看执行结果

```
User → "总结今天 GitHub issues"
Agent → 调用 GitHub API → 返回摘要
```

### 场景 2：任务自动化

通过手机创建和管理定时任务：

```
任务: Daily Research
提示词: 搜索 AI 新闻并生成摘要
计划: 每天 9:00
输出: 发送到 Telegram
```

手机端可以创建任务、查看运行状态、手动触发执行。

### 场景 3：安全审批

Agent 执行高风险操作时，手机端实时弹出审批请求：

```
Agent 请求执行:
  rm -rf temp/

[批准]  [拒绝]  [修改]
```

这是连接 Agent 强大能力与用户安全控制之间的关键桥梁。

### 场景 4：移动端 Chat

随时通过手机与 Agent 交互：

```
User → "帮我写一个 PR description"
Agent → 调用 git diff → 读取变更 → 生成 PR 描述
```

---

## 3. 信息架构

```
Claw Mobile
├── 会话 (Sessions)          ← Tab 1
│   ├── Startup
│   ├── Work
│   ├── Research
│   └── Personal
├── 任务 (Tasks)             ← Tab 2
│   ├── 运行中
│   ├── 已计划
│   └── 已完成
├── 记忆 (Memory)            ← Tab 3
│   ├── 已置顶
│   ├── 事实
│   ├── 偏好
│   └── 知识
└── 设置 (Settings)          ← Tab 4
    ├── Agent 信息
    ├── 仪表盘
    ├── 工具管理
    ├── 语言设置
    └── 断开连接
```

---

## 4. 核心功能模块

### 4.1 Agent Connect（认证连接）

| 项目 | 说明 |
|------|------|
| 连接方式 | QR 码扫描 / 手动输入 Token / Deep Link |
| 协议 | `claw://connect?token=xxxxx` |
| 安全 | JWT Token + Device ID 绑定 |
| 展示 | 连接后显示 Agent 名称、模型、工具列表、记忆大小 |

### 4.2 Session Chat（会话聊天）

每个 Session 拥有独立的 context、memory 和 history。

**聊天 UI 元素：**

| 元素 | 说明 |
|------|------|
| 用户消息 | 右侧蓝色气泡 |
| Agent 回复 | 左侧灰色气泡，支持流式逐字显示 |
| Tool Call | 独立卡片，显示工具名和命令，可展开查看结果 |
| 审批请求 | 底部横幅，包含批准/拒绝按钮 |

### 4.3 Tool Approval（工具审批）

当 Agent 调用高风险工具（Shell、文件系统、网络请求）时，App 拦截并请求用户确认。

审批流程：
```
Agent 发起 Tool Call
    ↓
Gateway 拦截高风险操作
    ↓
推送 approval_request 到 App
    ↓
用户选择 批准 / 拒绝
    ↓
Gateway 执行或取消
```

### 4.4 Tasks（任务自动化）

| 字段 | 说明 |
|------|------|
| 任务名称 | 简短描述 |
| 提示词 | Agent 执行的 Prompt |
| 计划 | Cron 表达式（如 `0 9 * * *`） |
| 状态 | 运行中 / 已计划 / 已完成 / 失败 |

支持手动立即运行已计划的任务。

### 4.5 Memory（记忆管理）

Agent 的长期记忆分为三类：

| 类别 | 示例 |
|------|------|
| 事实 (Fact) | "主仓库在 github.com/openclaw/openclaw" |
| 偏好 (Preference) | "用户偏好 Python" |
| 知识 (Knowledge) | "RAG 通过外部知识库提升 LLM 准确性" |

支持置顶、编辑和删除。

### 4.6 Agent Dashboard（状态仪表盘）

| 指标 | 说明 |
|------|------|
| 运行状态 | 在线 / 离线 / 忙碌 |
| 运行时间 | 如 "3天 7小时" |
| CPU 使用率 | 百分比 + 进度条 |
| 内存使用率 | 百分比 + 进度条 |
| Token 用量 | 累计消耗 Token 数 |
| 活跃任务 | 当前运行中的任务数 |
| 已启用工具 | Shell / Browser / Git 等 |

---

## 5. MVP 范围

### 5.1 MVP 包含

1. Agent Connect（QR / Token / Demo 模式）
2. Session Chat（流式响应 + Tool Call 展示）
3. Tool Approval（批准/拒绝审批）
4. Task List（查看 + 创建 + 手动运行）
5. Memory Management（查看 + 置顶 + 删除）
6. Agent Dashboard（状态监控）
7. 多语言支持（中文默认 / English）

### 5.2 MVP 不包含

- 语音控制
- Skill 市场
- 多 Agent 协同
- Branch Conversation（对话分支）
- Agent Sharing（Agent 分享）

---

## 6. 页面清单

| 页面 | 说明 |
|------|------|
| ConnectView | 启动页，Agent 连接 |
| MainTabView | Tab 导航容器 |
| SessionListView | 会话列表 |
| ChatView | 聊天界面 |
| TaskListView | 任务列表 |
| CreateTaskView | 创建任务表单 |
| MemoryListView | 记忆管理 |
| SettingsView | 设置页 |
| AgentStatusView | Agent 仪表盘 |

共 **9 个页面**。

---

## 7. 产品路线图

| 版本 | 核心功能 |
|------|---------|
| **V1.0 (MVP)** | Agent 连接、聊天、任务、记忆、仪表盘 |
| **V1.1** | 真实后端接入、推送通知、离线缓存 |
| **V2.0** | 语音 Agent 控制 |
| **V3.0** | 多 Agent 协同管理 |
| **V4.0** | Agent / Skill 市场 |

### Killer Feature 预研

**Agent Time Machine** — 回放 Agent 的推理过程：

```
Step 1: 搜索相关资料
Step 2: 读取代码文件
Step 3: 分析并生成方案
Step 4: 编写代码
```

类似 AI Debugger，让用户完全理解 Agent 的决策链路。

---

## 8. 成功指标

| KPI | 说明 |
|-----|------|
| 日活 Agent 连接数 | 每天有多少 Agent 被移动端连接 |
| 日均聊天会话数 | 用户与 Agent 的交互频率 |
| 任务创建数 | 自动化任务的使用率 |
| 审批响应时间 | 用户收到审批请求后的平均响应时间 |
