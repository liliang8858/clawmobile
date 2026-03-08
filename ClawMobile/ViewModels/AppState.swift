import SwiftUI
import Combine

@MainActor
@Observable
final class AppState {
    var isConnected: Bool = false
    var connectedAgent: Agent?
    var isConnecting: Bool = false
    var connectionError: String?

    func connect(token: String) {
        isConnecting = true
        connectionError = nil

        // Simulate connection delay
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            self.connectedAgent = MockService.shared.agent
            self.isConnected = true
            self.isConnecting = false
        }
    }

    func disconnect() {
        isConnected = false
        connectedAgent = nil
    }
}
