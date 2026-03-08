import Foundation

struct Session: Identifiable, Codable {
    let id: String
    var name: String
    var lastMessage: String
    var createdAt: Date
    var messageCount: Int
    var isActive: Bool

    var icon: String {
        switch name.lowercased() {
        case let n where n.contains("startup"): return "rocket"
        case let n where n.contains("personal"): return "person.fill"
        case let n where n.contains("research"): return "magnifyingglass"
        case let n where n.contains("coding"), let n where n.contains("code"): return "chevron.left.forwardslash.chevron.right"
        case let n where n.contains("work"): return "briefcase.fill"
        default: return "bubble.left.fill"
        }
    }
}
