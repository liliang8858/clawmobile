import Foundation

@MainActor
final class MockService {
    static let shared = MockService()

    let agent = Agent(
        id: "agent-001",
        name: "local-agent",
        model: "Claude Sonnet 4",
        status: .online,
        tools: ["Shell", "Browser", "Git", "File System", "Database"],
        memorySize: 2048,
        activeTasks: 3,
        cpuUsage: 23.5,
        memoryUsage: 45.2,
        tokenUsage: 128_450,
        uptime: 86400 * 3 + 3600 * 7
    )

    let sessions: [Session] = [
        Session(id: "s-1", name: "Startup", lastMessage: "Landing page draft is ready", createdAt: Date().addingTimeInterval(-3600), messageCount: 24, isActive: true),
        Session(id: "s-2", name: "Coding", lastMessage: "Refactored the auth module", createdAt: Date().addingTimeInterval(-7200), messageCount: 58, isActive: false),
        Session(id: "s-3", name: "Research", lastMessage: "Found 5 relevant papers on RAG", createdAt: Date().addingTimeInterval(-86400), messageCount: 12, isActive: false),
        Session(id: "s-4", name: "Personal", lastMessage: "Your schedule for tomorrow", createdAt: Date().addingTimeInterval(-172800), messageCount: 7, isActive: false),
    ]

    let sampleMessages: [Message] = [
        Message(role: .user, content: "Help me summarize the README", timestamp: Date().addingTimeInterval(-300)),
        Message(role: .agent, content: "I'll read the README file first.", timestamp: Date().addingTimeInterval(-295), isStreaming: false),
        Message(role: .tool, content: "", toolCall: Message.ToolCall(tool: "read_file", command: "README.md", result: "# OpenClaw\nAI Agent Runtime...", status: .completed, requiresApproval: false), timestamp: Date().addingTimeInterval(-290)),
        Message(role: .agent, content: "Here's a summary of the README:\n\n**OpenClaw** is an AI Agent runtime that allows AI to execute shell commands, manage files, browse the web, and automate tasks.\n\nKey features:\n- Local agent execution\n- Tool integration (Shell, Git, Browser)\n- Memory management\n- Task automation\n- Multi-channel control (Terminal, Telegram, Discord)", timestamp: Date().addingTimeInterval(-280)),
        Message(role: .user, content: "Now clean up the temp directory", timestamp: Date().addingTimeInterval(-200)),
        Message(role: .tool, content: "", toolCall: Message.ToolCall(tool: "shell", command: "rm -rf temp/", result: nil, status: .awaitingApproval, requiresApproval: true), timestamp: Date().addingTimeInterval(-195)),
    ]

    let tasks: [AgentTask] = [
        AgentTask(id: "t-1", name: "Daily Research", prompt: "Search AI news and summarize top 5 stories", schedule: "0 9 * * *", status: .scheduled, createdAt: Date().addingTimeInterval(-86400 * 3), lastRunAt: Date().addingTimeInterval(-86400), nextRunAt: Date().addingTimeInterval(3600)),
        AgentTask(id: "t-2", name: "GitHub Issues Digest", prompt: "Summarize all new GitHub issues from today", schedule: "0 18 * * *", status: .running, createdAt: Date().addingTimeInterval(-86400 * 7), lastRunAt: Date().addingTimeInterval(-1800)),
        AgentTask(id: "t-3", name: "Code Review", prompt: "Review all open PRs and provide feedback", schedule: "0 10 * * 1-5", status: .completed, createdAt: Date().addingTimeInterval(-86400 * 14), lastRunAt: Date().addingTimeInterval(-7200)),
        AgentTask(id: "t-4", name: "Security Scan", prompt: "Run security audit on the main repository", schedule: "0 2 * * 0", status: .scheduled, createdAt: Date().addingTimeInterval(-86400 * 2), nextRunAt: Date().addingTimeInterval(86400 * 2)),
        AgentTask(id: "t-5", name: "Backup Logs", prompt: "Compress and archive server logs older than 7 days", schedule: "0 3 * * *", status: .failed, createdAt: Date().addingTimeInterval(-86400 * 5), lastRunAt: Date().addingTimeInterval(-43200)),
    ]

    let memoryItems: [MemoryItem] = [
        MemoryItem(id: "m-1", content: "User prefers Python over JavaScript", category: .preference, createdAt: Date().addingTimeInterval(-86400 * 10), isPinned: true),
        MemoryItem(id: "m-2", content: "Working on a startup called OpenClaw", category: .fact, createdAt: Date().addingTimeInterval(-86400 * 30), isPinned: true),
        MemoryItem(id: "m-3", content: "Main repo is at github.com/openclaw/openclaw", category: .fact, createdAt: Date().addingTimeInterval(-86400 * 25), isPinned: false),
        MemoryItem(id: "m-4", content: "RAG (Retrieval-Augmented Generation) improves LLM accuracy by fetching relevant context from external knowledge bases", category: .knowledge, createdAt: Date().addingTimeInterval(-86400 * 5), isPinned: false),
        MemoryItem(id: "m-5", content: "User prefers dark mode in all tools", category: .preference, createdAt: Date().addingTimeInterval(-86400 * 15), isPinned: false),
        MemoryItem(id: "m-6", content: "Deployment target is AWS with Terraform", category: .fact, createdAt: Date().addingTimeInterval(-86400 * 8), isPinned: false),
        MemoryItem(id: "m-7", content: "MCP (Model Context Protocol) enables tool integration for LLMs via a standardized JSON-RPC protocol", category: .knowledge, createdAt: Date().addingTimeInterval(-86400 * 3), isPinned: true),
    ]

    // Simulated streaming responses
    let streamingResponses: [String] = [
        "I'll help you with that. Let me analyze the codebase first.\n\nAfter reviewing the project structure, here are my findings:\n\n1. **Architecture**: The project follows a clean MVVM pattern\n2. **Dependencies**: Minimal external dependencies\n3. **Test Coverage**: Currently at 72%\n\nWould you like me to dive deeper into any specific area?",
        "Here's what I found:\n\nThe authentication module uses JWT tokens with a 24-hour expiry. The refresh token mechanism is implemented but needs error handling for edge cases.\n\n```swift\nfunc refreshToken() async throws -> Token {\n    let response = try await api.refresh()\n    return response.token\n}\n```\n\nShall I fix the error handling?",
        "Task completed successfully!\n\nI've summarized today's top AI news:\n\n- **OpenAI** released a new reasoning model\n- **Anthropic** expanded Claude's tool use capabilities\n- **Google** announced improvements to Gemini Pro\n- **Meta** open-sourced a new LLaMA variant\n- **Microsoft** integrated AI deeper into VS Code\n\nThe full report has been sent to your Telegram.",
    ]
}
