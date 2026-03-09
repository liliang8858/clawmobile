import Foundation

struct Session: Identifiable, Codable {
    let id: String
    var name: String
    var lastMessage: String
    var createdAt: Date
    var messageCount: Int
    var isActive: Bool

    var icon: String {
        let n = name.lowercased()
        if n.contains("startup") { return "rocket" }
        if n.contains("personal") { return "person.fill" }
        if n.contains("research") { return "magnifyingglass" }
        if n.contains("coding") || n.contains("code") { return "chevron.left.forwardslash.chevron.right" }
        if n.contains("work") { return "briefcase.fill" }
        if n.contains("cron") { return "clock.fill" }
        if n.contains("feishu") { return "message.fill" }
        if n.contains("telegram") { return "paperplane.fill" }
        if n.contains("discord") { return "bubble.left.and.text.bubble.right.fill" }
        return "bubble.left.fill"
    }
}
