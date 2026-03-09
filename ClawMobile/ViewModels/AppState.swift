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
        guard !isScanning else { return }
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

                let discovered = self.discoveredAgent!
                self.connectedAgent = Agent(
                    id: discovered.agentId,
                    name: discovered.name,
                    model: "OpenClaw \(discovered.serverVersion)",
                    status: .online,
                    tools: extractTools(),
                    memorySize: 0,
                    activeTasks: service.cachedCrons.count,
                    cpuUsage: 0,
                    memoryUsage: 0,
                    tokenUsage: 0,
                    uptime: 0
                )

                // Try to get identity for better agent name
                if let identity = try? await service.getIdentity(),
                   let name = identity["name"] as? String, !name.isEmpty {
                    self.connectedAgent?.name = name
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
        if discoveredAgent != nil {
            connectToDiscovered()
            return
        }
        // No agent discovered and no demo mode - show error
        connectionError = "No agent found. Please ensure OpenClaw is running."
    }

    func disconnect() {
        service.disconnect()
        isConnected = false
        connectedAgent = nil
    }

    private func extractTools() -> [String] {
        var tools: [String] = ["Shell", "File System"]
        let channels = service.cachedChannels
        if channels["feishu"] != nil { tools.append("Feishu") }
        if channels["telegram"] != nil { tools.append("Telegram") }
        if channels["discord"] != nil { tools.append("Discord") }
        if let heartbeat = service.cachedAgentInfo["heartbeat"] as? [String: Any],
           heartbeat["enabled"] as? Bool == true {
            tools.append("Heartbeat")
        }
        return tools
    }
}
