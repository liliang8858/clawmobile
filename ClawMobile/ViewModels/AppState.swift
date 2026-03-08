import SwiftUI

@MainActor
@Observable
final class AppState {
    var isConnected: Bool = false
    var connectedAgent: Agent?
    var isConnecting: Bool = false
    var connectionError: String?
    var discoveredAgent: DiscoveredAgent?
    var isScanning: Bool = false

    private let service = OpenClawService.shared

    func scanForAgent() {
        isScanning = true
        Task {
            await service.scanForAgent()
            self.discoveredAgent = service.discoveredAgent
            self.isScanning = false
        }
    }

    func connectToDiscovered() {
        guard discoveredAgent != nil else { return }
        isConnecting = true
        connectionError = nil

        Task {
            do {
                try await service.connect()

                // Build agent model from discovered info
                let discovered = self.discoveredAgent!
                self.connectedAgent = Agent(
                    id: discovered.agentId,
                    name: discovered.name,
                    model: "OpenClaw \(discovered.serverVersion)",
                    status: .online,
                    tools: ["Shell", "Browser", "Git", "File System"],
                    memorySize: 0,
                    activeTasks: 0,
                    cpuUsage: 0,
                    memoryUsage: 0,
                    tokenUsage: 0,
                    uptime: 0
                )

                // Try to get more details
                if let identity = try? await service.getIdentity() {
                    if let name = identity["name"] as? String, !name.isEmpty {
                        self.connectedAgent?.name = name
                    }
                }

                self.isConnected = true
                self.isConnecting = false
            } catch {
                self.connectionError = error.localizedDescription
                self.isConnecting = false
            }
        }
    }

    func connect(token: String) {
        // If we have a discovered agent, connect to it
        if discoveredAgent != nil {
            connectToDiscovered()
            return
        }

        // Demo mode fallback
        isConnecting = true
        connectionError = nil
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            self.connectedAgent = MockService.shared.agent
            self.isConnected = true
            self.isConnecting = false
        }
    }

    func disconnect() {
        service.disconnect()
        isConnected = false
        connectedAgent = nil
    }
}
