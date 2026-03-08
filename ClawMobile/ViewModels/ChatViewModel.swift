import SwiftUI
import Combine

@MainActor
@Observable
final class ChatViewModel {
    var messages: [Message] = MockService.shared.sampleMessages
    var inputText: String = ""
    var isStreaming: Bool = false
    var showApproval: Bool = false
    var pendingApproval: Message?

    init() {
        checkForPendingApprovals()
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""

        simulateResponse(to: text)
    }

    func approveToolCall() {
        if let index = messages.lastIndex(where: { $0.toolCall?.status == .awaitingApproval }) {
            messages[index].toolCall?.status = .running
            showApproval = false
            pendingApproval = nil

            // Simulate tool completion
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                if index < messages.count {
                    messages[index].toolCall?.status = .completed
                    messages[index].toolCall?.result = "Done. Removed 12 files (3.2 MB freed)"
                }

                let response = Message(role: .agent, content: "The temp directory has been cleaned up. 12 files were removed, freeing 3.2 MB of disk space.")
                messages.append(response)
            }
        }
    }

    func denyToolCall() {
        if let index = messages.lastIndex(where: { $0.toolCall?.status == .awaitingApproval }) {
            messages[index].toolCall?.status = .failed
            messages[index].toolCall?.result = "Denied by user"
            showApproval = false
            pendingApproval = nil

            let response = Message(role: .agent, content: "Understood. I won't execute that command. Is there something else you'd like me to do instead?")
            messages.append(response)
        }
    }

    private func checkForPendingApprovals() {
        if let msg = messages.last(where: { $0.toolCall?.status == .awaitingApproval }) {
            pendingApproval = msg
            showApproval = true
        }
    }

    private func simulateResponse(to text: String) {
        isStreaming = true

        // Decide if we should show a tool call
        let shouldShowTool = text.lowercased().contains("file") || text.lowercased().contains("run") || text.lowercased().contains("search") || text.lowercased().contains("git")

        Task {
            if shouldShowTool {
                try? await Task.sleep(for: .seconds(0.5))
                let toolName = text.lowercased().contains("git") ? "git" : "shell"
                let command = text.lowercased().contains("git") ? "git log --oneline -5" : "ls -la"
                let toolMessage = Message(
                    role: .tool,
                    content: "",
                    toolCall: Message.ToolCall(tool: toolName, command: command, result: nil, status: .running, requiresApproval: false)
                )
                messages.append(toolMessage)

                try? await Task.sleep(for: .seconds(1.0))
                if let lastToolIndex = messages.lastIndex(where: { $0.role == .tool }) {
                    messages[lastToolIndex].toolCall?.status = .completed
                    messages[lastToolIndex].toolCall?.result = "abc1234 Fix auth bug\ndef5678 Add tests\nghi9012 Update README"
                }
            }

            try? await Task.sleep(for: .seconds(0.3))

            let responses = MockService.shared.streamingResponses
            let fullText = responses.randomElement() ?? responses[0]

            let streamingMessage = Message(role: .agent, content: "", isStreaming: true)
            messages.append(streamingMessage)
            let streamIndex = messages.count - 1

            // Stream character by character
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
