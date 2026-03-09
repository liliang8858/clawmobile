import SwiftUI

@MainActor
@Observable
final class SessionsViewModel {
    var sessions: [Session] = []
    var showingNewSession = false
    var newSessionName = ""
    var isLoading = false

    private let service = OpenClawService.shared

    func loadSessions(isDemoMode: Bool = false) {
        if isDemoMode {
            sessions = MockService.shared.sessions
            return
        }
        if !service.isConnected {
            sessions = []
            return
        }

        isLoading = true

        // Use cached sessions from health endpoint
        var loaded: [Session] = []
        for raw in service.cachedSessions {
            let key = raw["key"] as? String ?? raw["sessionKey"] as? String ?? UUID().uuidString

            // Parse session key to create a human-readable name
            // Format: "agent:main:main" or "agent:main:feishu:group:xxx" or "agent:main:cron:xxx"
            let name = parseSessionName(key)

            var updatedAt = Date()
            if let ts = raw["updatedAt"] as? Double {
                updatedAt = Date(timeIntervalSince1970: ts / 1000)
            }

            // Skip cron run sub-sessions
            if key.contains(":run:") { continue }

            loaded.append(Session(
                id: key,
                name: name,
                lastMessage: "",
                createdAt: updatedAt,
                messageCount: 0,
                isActive: true
            ))
        }

        // Sort by createdAt descending
        loaded.sort { $0.createdAt > $1.createdAt }

        self.sessions = loaded

        // Also try to refresh from health
        Task {
            await service.fetchSessionsFromHealth()
            var refreshed: [Session] = []
            for raw in service.cachedSessions {
                let key = raw["key"] as? String ?? raw["sessionKey"] as? String ?? UUID().uuidString
                if key.contains(":run:") { continue }
                let name = parseSessionName(key)
                var updatedAt = Date()
                if let ts = raw["updatedAt"] as? Double {
                    updatedAt = Date(timeIntervalSince1970: ts / 1000)
                }
                refreshed.append(Session(id: key, name: name, lastMessage: "", createdAt: updatedAt, messageCount: 0, isActive: true))
            }
            refreshed.sort { $0.createdAt > $1.createdAt }
            if !refreshed.isEmpty { self.sessions = refreshed }
            isLoading = false
        }
    }

    private func parseSessionName(_ key: String) -> String {
        // "agent:main:main" -> "Main"
        // "agent:main:feishu:group:oc_xxx" -> "Feishu Group"
        // "agent:main:cron:uuid" -> "Cron Task"
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
