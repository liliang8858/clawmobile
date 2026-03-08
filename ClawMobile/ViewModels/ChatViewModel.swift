import SwiftUI

@MainActor
@Observable
final class ChatViewModel {
    var messages: [Message] = []
    var inputText: String = ""
    var isStreaming: Bool = false
    var showApproval: Bool = false
    var pendingApproval: Message?
    var sessionKey: String = ""

    private let service = OpenClawService.shared
    private var currentRunId: String?
    private var streamingMessageIndex: Int?
    private var isDemoMode = false

    init() {}

    func setup(sessionKey: String, isDemoMode: Bool = false) {
        self.sessionKey = sessionKey
        self.isDemoMode = isDemoMode
        loadHistory()
        setupEventListeners()
    }

    private func loadHistory() {
        if isDemoMode {
            messages = MockService.shared.sampleMessages
            checkForPendingApprovals()
            return
        }

        guard service.isConnected, !sessionKey.isEmpty else {
            messages = []
            return
        }

        Task {
            do {
                let rawMessages = try await service.getChatHistory(sessionKey: sessionKey, limit: 50)
                var loaded: [Message] = []
                for raw in rawMessages {
                    let role = raw["role"] as? String ?? "user"
                    var content = ""
                    if let c = raw["content"] as? String {
                        content = c
                    } else if let blocks = raw["content"] as? [[String: Any]] {
                        for block in blocks {
                            if block["type"] as? String == "text",
                               let t = block["text"] as? String {
                                content += t
                            }
                        }
                    }

                    let msgRole: Message.MessageRole = switch role {
                    case "user": .user
                    case "assistant": .agent
                    case "tool": .tool
                    default: .system
                    }

                    if !content.isEmpty {
                        loaded.append(Message(role: msgRole, content: content))
                    }
                }
                self.messages = loaded
            } catch {
                // Keep empty
            }
        }
    }

    private func setupEventListeners() {
        service.onChatEvent = { [weak self] event in
            Task { @MainActor in
                self?.handleChatEvent(event)
            }
        }

        service.onApprovalRequested = { [weak self] approval in
            Task { @MainActor in
                self?.handleApprovalRequest(approval)
            }
        }
    }

    private func handleChatEvent(_ event: OpenClawService.ChatEvent) {
        guard event.sessionKey == sessionKey || sessionKey.isEmpty else { return }

        switch event.state {
        case "delta":
            if let idx = streamingMessageIndex, idx < messages.count {
                messages[idx].content += event.text
            } else {
                let msg = Message(role: .agent, content: event.text, isStreaming: true)
                messages.append(msg)
                streamingMessageIndex = messages.count - 1
            }

        case "final":
            if let idx = streamingMessageIndex, idx < messages.count {
                if !event.text.isEmpty {
                    messages[idx].content = event.text
                }
                messages[idx].isStreaming = false
            } else if !event.text.isEmpty {
                messages.append(Message(role: .agent, content: event.text))
            }
            streamingMessageIndex = nil
            isStreaming = false

        case "error":
            if let idx = streamingMessageIndex, idx < messages.count {
                messages[idx].isStreaming = false
                messages[idx].content += "\n[Error]"
            }
            streamingMessageIndex = nil
            isStreaming = false

        case "aborted":
            if let idx = streamingMessageIndex, idx < messages.count {
                messages[idx].isStreaming = false
            }
            streamingMessageIndex = nil
            isStreaming = false

        default:
            break
        }
    }

    private func handleApprovalRequest(_ approval: OpenClawService.ApprovalRequest) {
        let toolCall = Message.ToolCall(
            tool: "shell",
            command: approval.command,
            result: nil,
            status: .awaitingApproval,
            requiresApproval: true
        )
        let msg = Message(id: approval.id, role: .tool, content: "", toolCall: toolCall)
        messages.append(msg)
        pendingApproval = msg
        showApproval = true
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isStreaming = true
        streamingMessageIndex = nil

        if service.isConnected && !isDemoMode {
            Task {
                do {
                    let key = sessionKey.isEmpty ? "mobile-\(UUID().uuidString.prefix(8))" : sessionKey
                    currentRunId = try await service.sendChat(sessionKey: key, message: text)
                } catch {
                    isStreaming = false
                    messages.append(Message(role: .system, content: "Failed to send: \(error.localizedDescription)"))
                }
            }
        } else {
            simulateResponse(to: text)
        }
    }

    func approveToolCall() {
        if let msg = pendingApproval {
            if let index = messages.firstIndex(where: { $0.id == msg.id }) {
                messages[index].toolCall?.status = .running
            }
            showApproval = false

            if service.isConnected && !isDemoMode {
                Task {
                    try? await service.resolveApproval(id: msg.id, decision: "approve")
                    if let index = messages.firstIndex(where: { $0.id == msg.id }) {
                        messages[index].toolCall?.status = .completed
                    }
                }
            } else {
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    if let index = messages.firstIndex(where: { $0.id == msg.id }) {
                        messages[index].toolCall?.status = .completed
                        messages[index].toolCall?.result = "Done."
                    }
                    messages.append(Message(role: .agent, content: "Operation completed successfully."))
                }
            }
            pendingApproval = nil
        }
    }

    func denyToolCall() {
        if let msg = pendingApproval {
            if let index = messages.firstIndex(where: { $0.id == msg.id }) {
                messages[index].toolCall?.status = .failed
                messages[index].toolCall?.result = "Denied by user"
            }
            showApproval = false
            pendingApproval = nil

            if service.isConnected && !isDemoMode {
                Task {
                    try? await service.resolveApproval(id: msg.id, decision: "reject")
                }
            }
            messages.append(Message(role: .agent, content: "Understood. I won't execute that command."))
        }
    }

    func abortChat() {
        if service.isConnected && !isDemoMode {
            service.abortChat(sessionKey: sessionKey)
        }
        isStreaming = false
        if let idx = streamingMessageIndex, idx < messages.count {
            messages[idx].isStreaming = false
        }
        streamingMessageIndex = nil
    }

    private func checkForPendingApprovals() {
        if let msg = messages.last(where: { $0.toolCall?.status == .awaitingApproval }) {
            pendingApproval = msg
            showApproval = true
        }
    }

    // Demo mode only
    private func simulateResponse(to text: String) {
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            let responses = MockService.shared.streamingResponses
            let fullText = responses.randomElement() ?? responses[0]

            messages.append(Message(role: .agent, content: "", isStreaming: true))
            let streamIndex = messages.count - 1

            for char in fullText {
                try? await Task.sleep(for: .milliseconds(15))
                if streamIndex < messages.count {
                    messages[streamIndex].content.append(char)
                }
            }

            if streamIndex < messages.count {
                messages[streamIndex].isStreaming = false
            }
            isStreaming = false
        }
    }
}
