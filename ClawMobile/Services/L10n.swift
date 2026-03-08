import SwiftUI

enum AppLanguage: String, CaseIterable, Codable {
    case zh = "zh"
    case en = "en"

    var displayName: String {
        switch self {
        case .zh: return "中文"
        case .en: return "English"
        }
    }
}

@MainActor
@Observable
final class L10n {
    static let shared = L10n()

    var language: AppLanguage = {
        if let saved = UserDefaults.standard.string(forKey: "app_language"),
           let lang = AppLanguage(rawValue: saved) {
            return lang
        }
        return .zh
    }() {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "app_language")
        }
    }

    // MARK: - Connect View
    var appName: String { language == .zh ? "Claw Mobile" : "Claw Mobile" }
    var appSlogan: String { language == .zh ? "你的 AI Agent 控制中心" : "Your AI Agent Control Center" }
    var scanQR: String { language == .zh ? "扫描二维码" : "Scan QR Code" }
    var enterToken: String { language == .zh ? "手动输入 Token" : "Enter Token Manually" }
    var tryDemo: String { language == .zh ? "体验演示模式" : "Try Demo Mode" }
    var connecting: String { language == .zh ? "正在连接 Agent..." : "Connecting to Agent..." }
    var agentURLOrToken: String { language == .zh ? "Agent 地址或 Token" : "Agent URL or Token" }
    var connect: String { language == .zh ? "连接" : "Connect" }
    var back: String { language == .zh ? "返回" : "Back" }

    // MARK: - Tab Bar
    var tabSessions: String { language == .zh ? "会话" : "Sessions" }
    var tabTasks: String { language == .zh ? "任务" : "Tasks" }
    var tabMemory: String { language == .zh ? "记忆" : "Memory" }
    var tabSettings: String { language == .zh ? "设置" : "Settings" }

    // MARK: - Sessions
    var sessions: String { language == .zh ? "会话" : "Sessions" }
    var newSession: String { language == .zh ? "新建会话" : "New Session" }
    var sessionName: String { language == .zh ? "会话名称" : "Session name" }
    var create: String { language == .zh ? "创建" : "Create" }
    var cancel: String { language == .zh ? "取消" : "Cancel" }
    var enterSessionName: String { language == .zh ? "请输入新会话的名称" : "Enter a name for the new session" }
    var online: String { language == .zh ? "在线" : "Online" }
    var offline: String { language == .zh ? "离线" : "Offline" }
    var busy: String { language == .zh ? "忙碌" : "Busy" }

    // MARK: - Chat
    var messageAgent: String { language == .zh ? "发送消息给 Agent..." : "Message agent..." }
    var clearChat: String { language == .zh ? "清空聊天" : "Clear Chat" }
    var sessionInfo: String { language == .zh ? "会话信息" : "Session Info" }
    var agent: String { language == .zh ? "Agent" : "Agent" }
    var tool: String { language == .zh ? "工具" : "Tool" }
    var requiresApproval: String { language == .zh ? "需要审批" : "Requires approval" }
    var agentWantsToRun: String { language == .zh ? "Agent 请求执行：" : "Agent wants to run:" }
    var approve: String { language == .zh ? "批准" : "Approve" }
    var deny: String { language == .zh ? "拒绝" : "Deny" }

    // MARK: - Tasks
    var tasks: String { language == .zh ? "任务" : "Tasks" }
    var running: String { language == .zh ? "运行中" : "Running" }
    var scheduled: String { language == .zh ? "已计划" : "Scheduled" }
    var completed: String { language == .zh ? "已完成" : "Completed" }
    var failed: String { language == .zh ? "失败" : "Failed" }
    var runNow: String { language == .zh ? "立即运行" : "Run Now" }
    var lastRun: String { language == .zh ? "上次" : "Last" }
    var newTask: String { language == .zh ? "新建任务" : "New Task" }
    var taskDetails: String { language == .zh ? "任务详情" : "Task Details" }
    var taskName: String { language == .zh ? "任务名称" : "Task name" }
    var prompt: String { language == .zh ? "提示词" : "Prompt" }
    var scheduleCron: String { language == .zh ? "计划（Cron 表达式）" : "Schedule (cron)" }
    var cronExpression: String { language == .zh ? "Cron 表达式" : "Cron expression" }
    var quickPresets: String { language == .zh ? "快捷设置" : "Quick presets" }
    var everyHour: String { language == .zh ? "每小时" : "Every hour" }
    var daily9am: String { language == .zh ? "每天9点" : "Daily 9am" }
    var weeklyMon: String { language == .zh ? "每周一" : "Weekly Mon" }

    // MARK: - Memory
    var memory: String { language == .zh ? "记忆" : "Memory" }
    var pinned: String { language == .zh ? "已置顶" : "Pinned" }
    var facts: String { language == .zh ? "事实" : "Facts" }
    var preferences: String { language == .zh ? "偏好" : "Preferences" }
    var knowledge: String { language == .zh ? "知识" : "Knowledge" }
    var addMemory: String { language == .zh ? "添加记忆" : "Add Memory" }
    var content: String { language == .zh ? "内容" : "Content" }
    var add: String { language == .zh ? "添加" : "Add" }
    var enterMemoryItem: String { language == .zh ? "请输入新的记忆条目" : "Enter a new memory item" }
    var delete: String { language == .zh ? "删除" : "Delete" }
    var pin: String { language == .zh ? "置顶" : "Pin" }
    var unpin: String { language == .zh ? "取消置顶" : "Unpin" }
    var factLabel: String { language == .zh ? "事实" : "Fact" }
    var preferenceLabel: String { language == .zh ? "偏好" : "Preference" }
    var knowledgeLabel: String { language == .zh ? "知识" : "Knowledge" }

    // MARK: - Settings
    var settings: String { language == .zh ? "设置" : "Settings" }
    var agentSection: String { language == .zh ? "Agent" : "Agent" }
    var name: String { language == .zh ? "名称" : "Name" }
    var model: String { language == .zh ? "模型" : "Model" }
    var status: String { language == .zh ? "状态" : "Status" }
    var dashboard: String { language == .zh ? "仪表盘" : "Dashboard" }
    var tools: String { language == .zh ? "工具" : "Tools" }
    var app: String { language == .zh ? "应用" : "App" }
    var version: String { language == .zh ? "版本" : "Version" }
    var build: String { language == .zh ? "构建号" : "Build" }
    var languageSetting: String { language == .zh ? "语言" : "Language" }
    var disconnectAgent: String { language == .zh ? "断开 Agent 连接" : "Disconnect Agent" }

    // MARK: - Agent Status
    var agentDashboard: String { language == .zh ? "Agent 仪表盘" : "Agent Dashboard" }
    var overview: String { language == .zh ? "概览" : "Overview" }
    var uptime: String { language == .zh ? "运行时间" : "Uptime" }
    var activeTasks: String { language == .zh ? "活跃任务" : "Active Tasks" }
    var resources: String { language == .zh ? "资源" : "Resources" }
    var usage: String { language == .zh ? "使用情况" : "Usage" }
    var tokensUsed: String { language == .zh ? "Token 用量" : "Tokens Used" }
    var memoryStore: String { language == .zh ? "记忆存储" : "Memory Store" }
    var items: String { language == .zh ? "条" : "items" }
    var activeTools: String { language == .zh ? "已启用工具" : "Active Tools" }
    var enabled: String { language == .zh ? "已启用" : "Enabled" }
    var day: String { language == .zh ? "天" : "d" }
    var hour: String { language == .zh ? "小时" : "h" }

    func agentStatus(_ s: Agent.AgentStatus) -> String {
        switch s {
        case .online: return online
        case .offline: return offline
        case .busy: return busy
        }
    }

    func taskStatus(_ s: AgentTask.TaskStatus) -> String {
        switch s {
        case .running: return running
        case .scheduled: return scheduled
        case .completed: return completed
        case .failed: return failed
        }
    }

    func formatUptime(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        return "\(days)\(day) \(hours)\(hour)"
    }
}
