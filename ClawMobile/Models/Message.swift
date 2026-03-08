import Foundation

struct Message: Identifiable, Codable {
    let id: String
    var role: MessageRole
    var content: String
    var toolCall: ToolCall?
    var timestamp: Date
    var isStreaming: Bool

    enum MessageRole: String, Codable {
        case user
        case agent
        case tool
        case system
    }

    struct ToolCall: Codable {
        let tool: String
        let command: String
        var result: String?
        var status: ToolStatus
        var requiresApproval: Bool

        enum ToolStatus: String, Codable {
            case pending
            case running
            case completed
            case failed
            case awaitingApproval
        }
    }

    init(id: String = UUID().uuidString, role: MessageRole, content: String, toolCall: ToolCall? = nil, timestamp: Date = Date(), isStreaming: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.toolCall = toolCall
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }
}
