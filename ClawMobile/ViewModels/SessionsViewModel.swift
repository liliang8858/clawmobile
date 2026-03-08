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
        Task {
            do {
                let rawSessions = try await service.listSessions(limit: 50)
                var loaded: [Session] = []
                for raw in rawSessions {
                    let key = raw["sessionKey"] as? String ?? raw["key"] as? String ?? UUID().uuidString
                    let label = raw["label"] as? String ?? raw["sessionKey"] as? String ?? "Session"
                    let lastMsg = raw["lastMessage"] as? String ?? ""
                    let msgCount = raw["messageCount"] as? Int ?? 0
                    let isActive = raw["active"] as? Bool ?? false

                    var createdAt = Date()
                    if let ts = raw["createdAt"] as? String {
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        createdAt = formatter.date(from: ts) ?? Date()
                    } else if let ts = raw["createdAtMs"] as? Double {
                        createdAt = Date(timeIntervalSince1970: ts / 1000)
                    } else if let ts = raw["startedAt"] as? String {
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        createdAt = formatter.date(from: ts) ?? Date()
                    }

                    loaded.append(Session(
                        id: key,
                        name: label,
                        lastMessage: lastMsg,
                        createdAt: createdAt,
                        messageCount: msgCount,
                        isActive: isActive
                    ))
                }
                self.sessions = loaded
            } catch {
                self.sessions = []
            }
            isLoading = false
        }
    }

    func createSession() {
        guard !newSessionName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let session = Session(
            id: newSessionName.lowercased().replacingOccurrences(of: " ", with: "-"),
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
        if service.isConnected {
            Task {
                _ = try? await service.send(method: "sessions.delete", params: ["sessionKey": session.id])
            }
        }
    }
}
