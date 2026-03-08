# 前期调研与分析

> OpenClaw 生态机会调研

---

## 1. OpenClaw 架构理解

OpenClaw 不是普通 Chatbot，而是**本地运行的 AI Agent Runtime**。

### 系统架构

```
User
  ↓
Chat Interface (Telegram / Discord / Terminal)
  ↓
OpenClaw Gateway (常驻运行)
  ↓
Agent Brain (LLM 推理)
  ↓
Tools / Skills / Local System
```

### 核心特性

| 特性 | 说明 |
|------|------|
| Self-hosted | 运行在用户自己的机器上 |
| 消息驱动 | 通过聊天接口控制 Agent |
| 可执行动作 | Shell、浏览器、文件系统、API 调用 |
| 长期记忆 | MEMORY.md / SOUL.md |
| 插件系统 | 可扩展的 Skill 技能体系 |

本质：**Chat 是控制 AI Agent 的 Control Plane。**

---

## 2. 市场机会分析

### 2.1 问题：UI 原始

当前用户通过 Telegram / Discord / Terminal 控制 AI Agent：

```
Agent 能力 = 强大
控制界面 = 原始
```

Agent 可以执行复杂任务（代码生成、自动化、数据分析），但控制方式停留在文本命令行级别。这是一个巨大的产品机会。

### 2.2 问题：Session / Memory 管理差

OpenClaw 的 SOUL.md、MEMORY.md、logs 对普通用户难以理解和管理。如果提供一个 **Session-first UI**，将极大提升可用性。

### 2.3 问题：安全控制缺失

OpenClaw Agent 可以运行 Shell、读写文件、执行脚本。没有可视化的审批机制，风险极高。**安全控制 UI** 是刚需。

---

## 3. 产品定位推演

### 3.1 从 "聊天客户端" 到 "控制中心"

最初想法：做一个移动端聊天客户端，通过认证链接连接 Agent。

升级方向：不只是 Chat，而是完整的 **Agent Control Center**：

| 维度 | 聊天客户端 | 控制中心 |
|------|----------|---------|
| 核心功能 | 聊天 | 管理 + 监控 + 聊天 + 审批 |
| 价值定位 | ChatGPT 替代 | Agent 操作系统 |
| 差异化 | 无 | 强 |
| 商业潜力 | 低 | 高 |

### 3.2 最终定位

```
产品: Claw Mobile
定位: Mission Control for your AI Agent
类比: Cursor for AI Agents
```

不是 ChatGPT Mobile，而是 **AI Agent 的 iOS 操作系统**。

---

## 4. 功能调研

### 4.1 核心功能清单

| 优先级 | 功能 | MVP |
|--------|------|-----|
| P0 | Agent Connect（认证连接） | 是 |
| P0 | Session Chat（流式聊天） | 是 |
| P0 | Tool Approval（操作审批） | 是 |
| P1 | Task Automation（任务管理） | 是 |
| P1 | Memory Management（记忆管理） | 是 |
| P1 | Agent Dashboard（状态监控） | 是 |
| P2 | Branch Conversation（对话分支） | 否 |
| P2 | Voice Agent（语音控制） | 否 |
| P3 | Skill Marketplace | 否 |
| P3 | Multi-Agent | 否 |
| P3 | Agent Sharing | 否 |

### 4.2 Killer Feature 预研

**Branch Conversation（对话分支）：**

```
用户提问
   ├─ 方案 A → 继续探索
   └─ 方案 B → 继续探索
```

类似 Git 分支，用户可以探索不同解决路径并回溯。这是 AI Agent UI 相比普通聊天 UI 的核心差异。

**Agent Time Machine（推理回放）：**

```
Step 1: 搜索资料
Step 2: 读取文件
Step 3: 分析代码
Step 4: 编写方案
```

像 AI Debugger 一样回放 Agent 的完整推理链路。

**Agent Sharing：**

```
用户生成分享链接 → 朋友通过链接与你的 Agent 对话
```

可催生 Agent Economy：Startup AI、Legal AI、Research AI...

---

## 5. 技术调研

### 5.1 iOS 技术选型

| 方案 | 优势 | 劣势 | 决策 |
|------|------|------|------|
| SwiftUI | 原生、声明式、动画流畅 | 低版本兼容性 | **采用** |
| UIKit | 成熟稳定 | 开发效率低 | 不采用 |
| React Native | 跨平台 | 性能妥协 | 不采用 |
| Flutter | 跨平台 | 生态有限 | 不采用 |

选择 SwiftUI 的原因：原生体验最佳，MVP 只需要支持 iOS 18+，不需要考虑低版本兼容。

### 5.2 实时通信

| 方案 | 适用场景 | 决策 |
|------|---------|------|
| WebSocket | 双向实时通信 | **采用**（流式 Token、工具事件、任务状态） |
| SSE | 单向推送 | 不采用（需要双向通信） |
| 轮询 | 简单但低效 | 不采用 |

### 5.3 认证方案

| 方案 | 安全性 | 复杂度 | 决策 |
|------|--------|--------|------|
| JWT + Device Binding | 高 | 中 | **采用** |
| OAuth 2.0 | 高 | 高 | 过度设计 |
| API Key | 低 | 低 | 安全不足 |

---

## 6. 商业化分析

### 6.1 商业模式

| 模式 | 说明 |
|------|------|
| 免费 + Pro | 基础功能免费，高级功能（多 Agent、团队协作）付费 |
| 订阅制 | $5/月 Pro 移动客户端 |
| 平台抽成 | Skill Marketplace 交易抽成 |

### 6.2 竞争优势

如果做得好，Claw Mobile 有机会成为 **OpenClaw 的官方移动客户端**，占据生态位。

关键壁垒：
- 深度集成 OpenClaw 协议
- Agent 控制层的安全设计
- 移动端原生体验
