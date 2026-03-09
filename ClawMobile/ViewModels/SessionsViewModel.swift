import SwiftUI

@MainActor
@Observable
final class SessionsViewModel {
    var sessions: [Session] = []
    var showingNewSession = false
    var newSessionName = ""
    var isLoading = false

    private let service = OpenClawService.shared

    func loadSessions() {
        if !service.isConnected {
            sessions = []
            return
        }

        isLoading = true

        // Always include a Main session for general chatting
        var loaded: [Session] = [
            Session(id: "agent:main:main", name: "Main", lastMessage: "",
                    createdAt: Date(), messageCount: 0, isActive: true)
        ]

        // Add sessions from health data
        for raw in service.cachedSessions {
            let key = raw["key"] as? String ?? raw["sessionKey"] as? String ?? UUID().uuidString

            // Skip cron run sub-sessions and the main session (already added)
            if key.contains(":run:") { continue }
            if key == "agent:main:main" { continue }

            let name = parseSessionName(key)

            var updatedAt = Date()
            if let ts = raw["updatedAt"] as? Double {
                updatedAt = Date(timeIntervalSince1970: ts / 1000)
            } else if let age = raw["age"] as? Int {
                updatedAt = Date().addingTimeInterval(Double(-age))
            }

            loaded.append(Session(
                id: key, name: name, lastMessage: "",
                createdAt: updatedAt, messageCount: 0, isActive: true
            ))
        }

        loaded.sort { $0.createdAt > $1.createdAt }
        self.sessions = loaded

        // Refresh from health in background
        Task {
            await service.fetchHealthData()
            var refreshed: [Session] = [
                Session(id: "agent:main:main", name: "Main", lastMessage: "",
                        createdAt: Date(), messageCount: 0, isActive: true)
            ]
            for raw in service.cachedSessions {
                let key = raw["key"] as? String ?? raw["sessionKey"] as? String ?? UUID().uuidString
                if key.contains(":run:") || key == "agent:main:main" { continue }
                let name = parseSessionName(key)
                var updatedAt = Date()
                if let ts = raw["updatedAt"] as? Double {
                    updatedAt = Date(timeIntervalSince1970: ts / 1000)
                } else if let age = raw["age"] as? Int {
                    updatedAt = Date().addingTimeInterval(Double(-age))
                }
                refreshed.append(Session(id: key, name: name, lastMessage: "",
                                        createdAt: updatedAt, messageCount: 0, isActive: true))
            }
            refreshed.sort { $0.createdAt > $1.createdAt }
            self.sessions = refreshed
            isLoading = false
        }
    }

    private func parseSessionName(_ key: String) -> String {
        let parts = key.split(separator: ":")
        if parts.count >= 3 {
            let segment = String(parts[2])
            switch segment {
            case "main": return "Main"
            case "feishu": return "Feishu"
            case "cron": return "Cron"
            case "telegram": return "Telegram"
            case "discord": return "Discord"
            case "whatsapp": return "WhatsApp"
            default: return segment.capitalized
            }
        }
        return key
    }

    func createSession() {
        guard !newSessionName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let sessionKey = "agent:main:\(newSessionName.lowercased().replacingOccurrences(of: " ", with: "-"))"
        let session = Session(
            id: sessionKey,
            name: newSessionName,
            lastMessage: "",
            createdAt: Date(),
            messageCount: 0,
            isActive: true
        )
        sessions.insert(session, at: 0)
        newSessionName = ""
        showingNewSession = false
    }

    func deleteSession(_ session: Session) {
        sessions.removeAll { $0.id == session.id }
    }
}
