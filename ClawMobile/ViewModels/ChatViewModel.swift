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

    private var handlerId: String?

    init() {}

    func setup(sessionKey: String) {
        self.sessionKey = sessionKey
        loadHistory()
        setupEventListeners()
    }

    private func loadHistory() {
        guard service.isConnected, !sessionKey.isEmpty else {
            messages = []
            return
        }
        messages = []
    }

    private func setupEventListeners() {
        if let id = handlerId {
            service.removeChatHandler(id: id)
        }
        let id = UUID().uuidString
        handlerId = id

        service.addChatHandler(id: id) { [weak self] event in
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

    func cleanup() {
        if let id = handlerId {
            service.removeChatHandler(id: id)
            handlerId = nil
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

        guard service.isConnected else {
            isStreaming = false
            messages.append(Message(role: .system, content: "Not connected to agent"))
            return
        }

        Task {
            do {
                let key = sessionKey.isEmpty ? "mobile-\(UUID().uuidString.prefix(8))" : sessionKey
                currentRunId = try await service.sendChat(sessionKey: key, message: text)
            } catch {
                isStreaming = false
                messages.append(Message(role: .system, content: "Failed to send: \(error.localizedDescription)"))
            }
        }
    }

    func approveToolCall() {
        guard let msg = pendingApproval else { return }
        if let index = messages.firstIndex(where: { $0.id == msg.id }) {
            messages[index].toolCall?.status = .running
        }
        showApproval = false

        Task {
            try? await service.resolveApproval(id: msg.id, decision: "approve")
            if let index = messages.firstIndex(where: { $0.id == msg.id }) {
                messages[index].toolCall?.status = .completed
            }
        }
        pendingApproval = nil
    }

    func denyToolCall() {
        guard let msg = pendingApproval else { return }
        if let index = messages.firstIndex(where: { $0.id == msg.id }) {
            messages[index].toolCall?.status = .failed
            messages[index].toolCall?.result = "Denied by user"
        }
        showApproval = false
        pendingApproval = nil

        Task {
            try? await service.resolveApproval(id: msg.id, decision: "reject")
        }
        messages.append(Message(role: .agent, content: "Understood. I won't execute that command."))
    }

    func abortChat() {
        service.abortChat(sessionKey: sessionKey)
        isStreaming = false
        if let idx = streamingMessageIndex, idx < messages.count {
            messages[idx].isStreaming = false
        }
        streamingMessageIndex = nil
    }
}
