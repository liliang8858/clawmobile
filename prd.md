# 一、产品定义（最重要）

产品名：

**Claw Mobile**

定位：

**“Your AI Agent Control Center”**

不是：

* ChatGPT 客户端
* AI 聊天工具

而是：

**管理、控制、监控 AI Agent 的移动端。**

核心理念：

```
AI Agent ≠ Chatbot
AI Agent = Digital Worker
Chat = Command Line
```

所以你的 App 是：

**Agent 的 GUI。**

---

# 二、核心用户场景（决定功能）

## 场景1：远程控制 Agent

用户在电脑运行 OpenClaw。

手机可以：

* 查看 agent
* 发指令
* 查看执行结果

例：

```
User: 总结今天 GitHub issues
Agent: 已完成
```

---

## 场景2：任务自动化

Agent 可以执行任务：

```
每天 9:00
抓取新闻
生成总结
发到 Telegram
```

手机可以：

* 创建任务
* 查看状态
* 手动运行

---

## 场景3：随时 Chat

用户在手机：

```
"帮我写一个 PR description"
```

Agent 会：

* 调用 git
* 读取 diff
* 生成 PR

---

# 三、App 信息架构（IA）

建议结构：

```
Home
│
├── Sessions
│     ├── Personal
│     ├── Work
│     └── Research
│
├── Tasks
│     ├── Scheduled
│     └── Running
│
├── Memory
│
├── Tools
│
└── Agent Status
```

---

# 四、核心模块设计

## 1 Agent Connect

用户第一次使用：

**方式1**

扫描 QR

```
openclaw://connect?token=xxxxx
```

**方式2**

输入地址

```
https://agent.local:3000
```

---

连接后：

显示 Agent 信息：

```
Agent Name
Model
Tools
Memory size
```

---

## 2 Session Chat（核心）

每个 session 是：

```
context + memory + history
```

例如：

```
Startup
Personal
Coding
```

聊天 UI：

```
User
Agent
Tool Call
Result
```

例：

```
User: 帮我总结 README

Agent:
正在读取文件...

Tool: read_file
file: README.md

Result: ...
```

---

## 3 Tool Execution UI（超级重要）

当 agent 执行危险操作：

```
shell
file delete
network
```

App 会提示：

```
Agent wants to run:

rm -rf temp/

[Approve]
[Deny]
[Modify]
```

这是 **安全层**。

---

## 4 Tasks（自动化）

用户可以创建：

```
Task name
Prompt
Schedule
```

例如：

```
Task:
Daily Research

Prompt:
Search AI news and summarize

Schedule:
Every day 9:00
```

UI：

```
Tasks
├ Running
├ Scheduled
└ Completed
```

---

## 5 Memory 管理

OpenClaw memory：

```
memory.md
```

App 可以做成：

```
Facts
Preferences
Knowledge
```

用户可以：

```
Edit
Delete
Pin
```

例如：

```
User prefers Python
Working on startup
```

---

## 6 Tools / Skills

Agent 工具列表：

```
Shell
Browser
Git
File system
```

UI：

```
Tools
├ Git
├ Browser
├ Shell
└ Database
```

用户可以：

* enable
* disable
* inspect logs

---

## 7 Agent Status

一个 dashboard：

```
Agent status
```

显示：

```
Model: Claude / GPT
CPU usage
Memory
Active tasks
Tool calls
```

类似：

**DevOps 面板。**

---

# 五、Chat UI Wireframe（关键）

大概结构：

```
------------------------
Session: Startup
------------------------

User
帮我写 landing page 文案

------------------------

Agent
Thinking...

------------------------

Tool Call
browser.search("AI startup landing page")

------------------------

Result
10 results found

------------------------

Agent
Here is the draft:

------------------------
```

Tool Call 需要特殊 UI。

---

# 六、技术架构

## Mobile

推荐：

```
SwiftUI
Combine
WebSocket
```

---

## 网络层

OpenClaw 需要一个：

**Gateway API**

例如：

```
POST /chat
GET /sessions
GET /tasks
POST /task
```

实时通信：

```
WebSocket
```

用于：

```
token stream
tool events
task status
```

---

## Auth

连接 token：

```
JWT
```

示例：

```
claw://connect?token=xxxxx
```

token：

```
device_id
expiry
permissions
```

---

# 七、MVP 功能（建议第一版）

第一版不要复杂。

MVP：

### 必须有

1️⃣ Agent Connect
2️⃣ Session Chat
3️⃣ Streaming response
4️⃣ Tool execution log
5️⃣ Basic task list

---

### 不做

先不做：

* Skill marketplace
* Voice
* Multi-agent

---

# 八、MVP UI 页面

只需要：

```
Login
Agent connect
Session list
Chat
Tasks
Settings
```

6个页面。

---

# 九、未来升级路线

### V2

```
Voice agent
```

---

### V3

```
Multi-agent collaboration
```

---

### V4

```
Agent marketplace
```

---

# 十、一个真正的 Killer Feature

如果你要让这个 App **出圈**，我建议做：

**Agent Time Machine**

用户可以：

```
回放 agent 的 reasoning
```

例如：

```
Step1 search
Step2 read file
Step3 write code
```

像：

**AI Debugger**

---

# 十一、产品一句话

这个 App 的本质：

**“Cursor for AI agents.”**

