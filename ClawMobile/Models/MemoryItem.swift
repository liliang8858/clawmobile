import Foundation

struct MemoryItem: Identifiable, Codable {
    let id: String
    var content: String
    var category: MemoryCategory
    var createdAt: Date
    var isPinned: Bool

    enum MemoryCategory: String, Codable, CaseIterable {
        case fact
        case preference
        case knowledge

        var icon: String {
            switch self {
            case .fact: return "info.circle.fill"
            case .preference: return "heart.fill"
            case .knowledge: return "book.fill"
            }
        }

        var label: String {
            switch self {
            case .fact: return "Fact"
            case .preference: return "Preference"
            case .knowledge: return "Knowledge"
            }
        }
    }
}
