import Foundation

struct Agent: Identifiable, Codable {
    let id: String
    var name: String
    var model: String
    var status: AgentStatus
    var tools: [String]
    var memorySize: Int
    var activeTasks: Int
    var cpuUsage: Double
    var memoryUsage: Double
    var tokenUsage: Int
    var uptime: TimeInterval

    enum AgentStatus: String, Codable {
        case online
        case offline
        case busy
    }
}
