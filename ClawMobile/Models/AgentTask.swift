import Foundation

struct AgentTask: Identifiable, Codable {
    let id: String
    var name: String
    var prompt: String
    var schedule: String
    var status: TaskStatus
    var createdAt: Date
    var lastRunAt: Date?
    var nextRunAt: Date?

    enum TaskStatus: String, Codable, CaseIterable {
        case running
        case scheduled
        case completed
        case failed

        var icon: String {
            switch self {
            case .running: return "play.circle.fill"
            case .scheduled: return "clock.fill"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }

        var color: String {
            switch self {
            case .running: return "blue"
            case .scheduled: return "orange"
            case .completed: return "green"
            case .failed: return "red"
            }
        }
    }
}
