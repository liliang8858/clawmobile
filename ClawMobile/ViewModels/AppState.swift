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
    var isDemoMode: Bool = false
    var debugLog: String = ""

    private let service = OpenClawService.shared

    private func log(_ msg: String) {
        print("[ClawMobile] \(msg)")
        NSLog("[ClawMobile] %@", msg)
        debugLog += msg + "\n"
    }

    func scanForAgent() {
        isScanning = true
        log("scan started")
        Task {
            await service.scanForAgent()
            self.discoveredAgent = service.discoveredAgent
            self.isScanning = false
            if let d = discoveredAgent {
                log("found: \(d.name) @ \(d.url), token=\(d.gatewayToken.isEmpty ? "EMPTY" : "ok(\(d.gatewayToken.prefix(8))...)")")
            } else {
                log("no agent found")
            }
            log("service log:\n\(service.connectionLog)")
        }
    }

    func connectToDiscovered() {
        guard discoveredAgent != nil else { return }
        isConnecting = true
        connectionError = nil
        isDemoMode = false
        log("connecting to discovered agent...")

        Task {
            do {
                try await service.connect()
                log("ws connected! sessions=\(service.cachedSessions.count)")
                log("service log:\n\(service.connectionLog)")

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

                if let identity = try? await service.getIdentity() {
                    if let name = identity["name"] as? String, !name.isEmpty {
                        self.connectedAgent?.name = name
                    }
                }

                self.isConnected = true
                self.isConnecting = false
                log("fully connected, sessions=\(service.cachedSessions.count)")
            } catch {
                log("connect error: \(error.localizedDescription)")
                log("service log:\n\(service.connectionLog)")
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

        isConnecting = true
        connectionError = nil
        isDemoMode = true
        log("demo mode")
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
        isDemoMode = false
        debugLog = ""
    }
}
