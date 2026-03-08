import Foundation

// MARK: - WebSocket Protocol Types

struct WSRequest: Encodable {
    let type = "req"
    let id: String
    let method: String
    let params: [String: AnyCodable]?

    init(method: String, params: [String: AnyCodable]? = nil) {
        self.id = UUID().uuidString
        self.method = method
        self.params = params
    }
}

struct WSResponse: Decodable {
    let type: String
    let id: String?
    let ok: Bool?
    let payload: AnyCodable?
    let error: WSError?
    let event: String?
    let seq: Int?

    struct WSError: Decodable {
        let message: String?
        let type: String?
    }
}

// MARK: - AnyCodable (for dynamic JSON)

struct AnyCodable: Codable, @unchecked Sendable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { value = NSNull() }
        else if let b = try? container.decode(Bool.self) { value = b }
        else if let i = try? container.decode(Int.self) { value = i }
        else if let d = try? container.decode(Double.self) { value = d }
        else if let s = try? container.decode(String.self) { value = s }
        else if let a = try? container.decode([AnyCodable].self) { value = a.map { $0.value } }
        else if let o = try? container.decode([String: AnyCodable].self) { value = o.mapValues { $0.value } }
        else { value = NSNull() }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull: try container.encodeNil()
        case let b as Bool: try container.encode(b)
        case let i as Int: try container.encode(i)
        case let d as Double: try container.encode(d)
        case let s as String: try container.encode(s)
        case let a as [Any]: try container.encode(a.map { AnyCodable($0) })
        case let o as [String: Any]: try container.encode(o.mapValues { AnyCodable($0) })
        default: try container.encodeNil()
        }
    }

    var stringValue: String? { value as? String }
    var intValue: Int? { value as? Int }
    var doubleValue: Double? { value as? Double }
    var boolValue: Bool? { value as? Bool }
    var dictValue: [String: Any]? { value as? [String: Any] }
    var arrayValue: [Any]? { value as? [Any] }
}

// MARK: - Discovery

struct DiscoveredAgent: Sendable {
    let url: String
    let name: String
    let avatar: String
    let agentId: String
    let serverVersion: String
}

// MARK: - OpenClaw Service

@MainActor
@Observable
final class OpenClawService {
    static let shared = OpenClawService()

    var isConnected = false
    var isConnecting = false
    var discoveredAgent: DiscoveredAgent?
    var isScanning = false

    // Callbacks
    var onChatEvent: ((ChatEvent) -> Void)?
    var onApprovalRequested: ((ApprovalRequest) -> Void)?

    private var webSocketTask: URLSessionWebSocketTask?
    private var pendingRequests: [String: CheckedContinuation<WSResponse, Error>] = [:]
    private let session = URLSession(configuration: .default)
    private var baseURL = "http://127.0.0.1:18789"
    private var wsURL = "ws://127.0.0.1:18789"

    struct ChatEvent: @unchecked Sendable {
        let sessionKey: String
        let runId: String
        let state: String // delta, final, error, aborted
        let text: String
        let toolCalls: [[String: Any]]?
    }

    struct ApprovalRequest: @unchecked Sendable {
        let id: String
        let command: String
        let cwd: String?
        let security: String?
        let ask: String?
        let sessionKey: String?
        let createdAtMs: Double
        let expiresAtMs: Double
    }

    // MARK: - Discovery

    func scanForAgent() async {
        isScanning = true
        defer { isScanning = false }

        let ports = [18789, 3000, 8080]
        for port in ports {
            let urlStr = "http://127.0.0.1:\(port)"
            guard let url = URL(string: "\(urlStr)/health") else { continue }

            var request = URLRequest(url: url)
            request.timeoutInterval = 2

            do {
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      json["ok"] as? Bool == true else { continue }

                // Found! Get config
                let configURL = URL(string: "\(urlStr)/__openclaw/control-ui-config.json")!
                let (configData, _) = try await session.data(from: configURL)
                if let config = try? JSONSerialization.jsonObject(with: configData) as? [String: Any] {
                    discoveredAgent = DiscoveredAgent(
                        url: urlStr,
                        name: config["assistantName"] as? String ?? "OpenClaw Agent",
                        avatar: config["assistantAvatar"] as? String ?? "🐾",
                        agentId: config["assistantAgentId"] as? String ?? "main",
                        serverVersion: config["serverVersion"] as? String ?? "unknown"
                    )
                    baseURL = urlStr
                    wsURL = "ws://127.0.0.1:\(port)"
                    return
                }
            } catch {
                continue
            }
        }
    }

    // MARK: - WebSocket Connection

    func connect() async throws {
        guard let url = URL(string: wsURL) else { return }
        isConnecting = true

        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()

        // Start listening
        Task { await receiveMessages() }

        isConnected = true
        isConnecting = false
    }

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        pendingRequests.removeAll()
    }

    // MARK: - Send Request

    func send(method: String, params: [String: Any]? = nil) async throws -> WSResponse {
        let id = UUID().uuidString
        let request: [String: Any] = [
            "type": "req",
            "id": id,
            "method": method,
            "params": params ?? [:]
        ]

        let data = try JSONSerialization.data(withJSONObject: request)
        let message = URLSessionWebSocketTask.Message.string(String(data: data, encoding: .utf8)!)

        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[id] = continuation
            webSocketTask?.send(message) { [weak self] error in
                if let error {
                    Task { @MainActor in
                        self?.pendingRequests.removeValue(forKey: id)
                    }
                    continuation.resume(throwing: error)
                }
            }

            // Timeout after 30s
            Task {
                try? await Task.sleep(for: .seconds(30))
                await MainActor.run {
                    if let cont = self.pendingRequests.removeValue(forKey: id) {
                        cont.resume(throwing: NSError(domain: "OpenClaw", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request timeout"]))
                    }
                }
            }
        }
    }

    // Fire-and-forget send (no response needed)
    func sendNoWait(method: String, params: [String: Any]? = nil) {
        let id = UUID().uuidString
        let request: [String: Any] = [
            "type": "req",
            "id": id,
            "method": method,
            "params": params ?? [:]
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: request),
              let str = String(data: data, encoding: .utf8) else { return }
        webSocketTask?.send(.string(str)) { _ in }
    }

    // MARK: - Receive Messages

    private func receiveMessages() async {
        guard let ws = webSocketTask else { return }
        do {
            while true {
                let message = try await ws.receive()
                switch message {
                case .string(let text):
                    handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        handleMessage(text)
                    }
                @unknown default:
                    break
                }
            }
        } catch {
            await MainActor.run {
                isConnected = false
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "res":
            handleResponse(json)
        case "event":
            handleEvent(json)
        default:
            break
        }
    }

    private func handleResponse(_ json: [String: Any]) {
        guard let id = json["id"] as? String,
              let continuation = pendingRequests.removeValue(forKey: id) else { return }

        do {
            let data = try JSONSerialization.data(withJSONObject: json)
            let response = try JSONDecoder().decode(WSResponse.self, from: data)
            continuation.resume(returning: response)
        } catch {
            continuation.resume(throwing: error)
        }
    }

    private func handleEvent(_ json: [String: Any]) {
        guard let event = json["event"] as? String else { return }
        let payload = json["payload"] as? [String: Any] ?? [:]

        switch event {
        case "chat":
            let sessionKey = payload["sessionKey"] as? String ?? ""
            let runId = payload["runId"] as? String ?? ""
            let state = payload["state"] as? String ?? ""

            var text = ""
            if let message = payload["message"] as? [String: Any],
               let content = message["content"] as? [[String: Any]] {
                for block in content {
                    if block["type"] as? String == "text",
                       let t = block["text"] as? String {
                        text += t
                    }
                }
            }

            let chatEvent = ChatEvent(
                sessionKey: sessionKey,
                runId: runId,
                state: state,
                text: text,
                toolCalls: nil
            )
            onChatEvent?(chatEvent)

        case "exec.approval.requested":
            if let request = payload["request"] as? [String: Any] {
                let approval = ApprovalRequest(
                    id: payload["id"] as? String ?? "",
                    command: request["command"] as? String ?? request["ask"] as? String ?? "",
                    cwd: request["cwd"] as? String,
                    security: request["security"] as? String,
                    ask: request["ask"] as? String,
                    sessionKey: request["sessionKey"] as? String,
                    createdAtMs: payload["createdAtMs"] as? Double ?? 0,
                    expiresAtMs: payload["expiresAtMs"] as? Double ?? 0
                )
                onApprovalRequested?(approval)
            }

        default:
            break
        }
    }

    // MARK: - API Convenience Methods

    func getIdentity() async throws -> [String: Any] {
        let res = try await send(method: "agent.identity.get")
        return res.payload?.dictValue ?? [:]
    }

    func listSessions(limit: Int = 100) async throws -> [[String: Any]] {
        let res = try await send(method: "sessions.list", params: ["limit": limit])
        if let payload = res.payload?.dictValue,
           let sessions = payload["sessions"] as? [[String: Any]] {
            return sessions
        }
        return res.payload?.arrayValue as? [[String: Any]] ?? []
    }

    func getChatHistory(sessionKey: String, limit: Int = 100) async throws -> [[String: Any]] {
        let res = try await send(method: "chat.history", params: ["sessionKey": sessionKey, "limit": limit])
        if let payload = res.payload?.dictValue,
           let messages = payload["messages"] as? [[String: Any]] {
            return messages
        }
        return res.payload?.arrayValue as? [[String: Any]] ?? []
    }

    func sendChat(sessionKey: String, message: String) async throws -> String {
        let res = try await send(method: "chat.send", params: [
            "sessionKey": sessionKey,
            "message": message,
            "deliver": false,
            "idempotencyKey": UUID().uuidString
        ])
        return res.payload?.dictValue?["runId"] as? String ?? ""
    }

    func abortChat(sessionKey: String) {
        sendNoWait(method: "chat.abort", params: ["sessionKey": sessionKey])
    }

    func listCrons() async throws -> [[String: Any]] {
        let res = try await send(method: "cron.list")
        if let payload = res.payload?.dictValue,
           let crons = payload["crons"] as? [[String: Any]] {
            return crons
        }
        return res.payload?.arrayValue as? [[String: Any]] ?? []
    }

    func addCron(label: String, prompt: String, schedule: String) async throws {
        _ = try await send(method: "cron.add", params: [
            "label": label,
            "prompt": prompt,
            "schedule": schedule
        ])
    }

    func runCron(id: String) async throws {
        _ = try await send(method: "cron.run", params: ["id": id])
    }

    func removeCron(id: String) async throws {
        _ = try await send(method: "cron.remove", params: ["id": id])
    }

    func getPendingApprovals() async throws -> [[String: Any]] {
        let res = try await send(method: "exec.approvals.get")
        if let payload = res.payload?.dictValue,
           let approvals = payload["approvals"] as? [[String: Any]] {
            return approvals
        }
        return []
    }

    func resolveApproval(id: String, decision: String) async throws {
        _ = try await send(method: "exec.approval.resolve", params: [
            "id": id,
            "decision": decision
        ])
    }

    func getStatus() async throws -> [String: Any] {
        let res = try await send(method: "status")
        return res.payload?.dictValue ?? [:]
    }
}
