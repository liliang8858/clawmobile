import SwiftUI
import Combine

@MainActor
@Observable
final class SessionsViewModel {
    var sessions: [Session] = MockService.shared.sessions
    var showingNewSession = false
    var newSessionName = ""

    func createSession() {
        guard !newSessionName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let session = Session(
            id: UUID().uuidString,
            name: newSessionName,
            lastMessage: "New session",
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
