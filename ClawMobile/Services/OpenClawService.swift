import Foundation
import os

private let log = Logger(subsystem: "com.openclaw.ClawMobile", category: "OpenClawService")

// MARK: - AnyCodable

struct AnyCodable: Codable, @unchecked Sendable {
    let value: Any
    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { value = NSNull() }
        else if let b = try? c.decode(Bool.self) { value = b }
        else if let i = try? c.decode(Int.self) { value = i }
        else if let d = try? c.decode(Double.self) { value = d }
        else if let s = try? c.decode(String.self) { value = s }
        else if let a = try? c.decode([AnyCodable].self) { value = a.map { $0.value } }
        else if let o = try? c.decode([String: AnyCodable].self) { value = o.mapValues { $0.value } }
        else { value = NSNull() }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case is NSNull: try c.encodeNil()
        case let b as Bool: try c.encode(b)
        case let i as Int: try c.encode(i)
        case let d as Double: try c.encode(d)
        case let s as String: try c.encode(s)
        case let a as [Any]: try c.encode(a.map { AnyCodable($0) })
        case let o as [String: Any]: try c.encode(o.mapValues { AnyCodable($0) })
        default: try c.encodeNil()
        }
    }
    var stringValue: String? { value as? String }
    var dictValue: [String: Any]? { value as? [String: Any] }
    var arrayValue: [Any]? { value as? [Any] }
}

struct WSResponse: Decodable {
    let type: String; let id: String?; let ok: Bool?
    let payload: AnyCodable?; let error: WSError?; let event: String?
    struct WSError: Decodable { let message: String?; let code: String? }
}

// MARK: - Discovery

struct DiscoveredAgent: Sendable {
    let url: String; let name: String; let avatar: String
    let agentId: String; let serverVersion: String; let gatewayToken: String; let port: Int
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
    var cachedSessions: [[String: Any]] = []
    var connectionLog: String = ""

    var onChatEvent: ((ChatEvent) -> Void)?
    var onApprovalRequested: ((ApprovalRequest) -> Void)?

    private var webSocketTask: URLSessionWebSocketTask?
    private var pendingRequests: [String: CheckedContinuation<WSResponse, Error>] = [:]
    private let urlSession = URLSession(configuration: .default)
    private var port = 18789
    private var gatewayToken = ""

    struct ChatEvent: @unchecked Sendable {
        let sessionKey: String; let runId: String; let state: String; let text: String
    }
    struct ApprovalRequest: @unchecked Sendable {
        let id: String; let command: String; let sessionKey: String?
    }

    private func appendLog(_ msg: String) {
        log.info("\(msg)")
        NSLog("[OC] %@", msg)
        connectionLog += msg + "\n"
    }

    // MARK: - Discovery

    func scanForAgent() async {
        isScanning = true
        defer { isScanning = false }

        let token = readGatewayToken()
        appendLog("[scan] gateway token: \(token.isEmpty ? "EMPTY" : "found (\(token.prefix(8))...)")")

        for p in [18789, 3000, 8080] {
            let urlStr = "http://127.0.0.1:\(p)"
            guard let url = URL(string: "\(urlStr)/health") else { continue }
            var req = URLRequest(url: url)
            req.timeoutInterval = 3

            do {
                appendLog("[scan] trying \(urlStr)/health ...")
                let (data, resp) = try await urlSession.data(for: req)
                guard let http = resp as? HTTPURLResponse else {
                    appendLog("[scan] \(p): not HTTP response")
                    continue
                }
                appendLog("[scan] \(p): status \(http.statusCode)")
                guard http.statusCode == 200,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      json["ok"] as? Bool == true else { continue }

                appendLog("[scan] \(p): health OK! fetching config...")
                let configURL = URL(string: "\(urlStr)/__openclaw/control-ui-config.json")!
                let (configData, _) = try await urlSession.data(from: configURL)
                if let config = try? JSONSerialization.jsonObject(with: configData) as? [String: Any] {
                    let name = config["assistantName"] as? String ?? "OpenClaw Agent"
                    let ver = config["serverVersion"] as? String ?? "unknown"
                    appendLog("[scan] found agent: \(name) v\(ver)")
                    discoveredAgent = DiscoveredAgent(
                        url: urlStr, name: name,
                        avatar: config["assistantAvatar"] as? String ?? "🐾",
                        agentId: config["assistantAgentId"] as? String ?? "main",
                        serverVersion: ver, gatewayToken: token, port: p
                    )
                    self.port = p
                    self.gatewayToken = token
                    return
                }
            } catch {
                appendLog("[scan] \(p): error \(error.localizedDescription)")
                continue
            }
        }
        appendLog("[scan] no agent found")
    }

    private func readGatewayToken() -> String {
        // In iOS Simulator, NSHomeDirectory() is sandbox, not real Mac home.
        // Try multiple paths to find the config.
        let candidates = [
            "/Users/vincent/.openclaw/openclaw.json",          // Direct Mac path
            NSHomeDirectory() + "/.openclaw/openclaw.json",    // Sandbox (won't work but try)
            ProcessInfo.processInfo.environment["HOME"].map { $0 + "/.openclaw/openclaw.json" },
        ].compactMap { $0 }

        for path in candidates {
            appendLog("[token] trying \(path)")
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let gateway = json["gateway"] as? [String: Any],
               let auth = gateway["auth"] as? [String: Any],
               let token = auth["token"] as? String {
                appendLog("[token] found token from \(path)")
                return token
            }
        }
        appendLog("[token] no token found in any path")
        return ""
    }

    // MARK: - Connect

    func connect() async throws {
        isConnecting = true
        let wsURLStr = "ws://127.0.0.1:\(port)"
        appendLog("[ws] connecting to \(wsURLStr)")

        guard let url = URL(string: wsURLStr) else { throw NSError(domain: "OpenClaw", code: -1) }

        var request = URLRequest(url: url)
        request.setValue("http://127.0.0.1:\(port)", forHTTPHeaderField: "Origin")

        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()

        // 1. Wait for connect.challenge
        appendLog("[ws] waiting for challenge...")
        let challengeMsg = try await receiveOne()
        appendLog("[ws] got challenge: \(String(challengeMsg.prefix(100)))")

        // 2. Send connect handshake
        var authParams: [String: Any] = [:]
        if !gatewayToken.isEmpty {
            authParams["token"] = gatewayToken
        }
        appendLog("[ws] sending connect handshake (token: \(gatewayToken.isEmpty ? "none" : "present"))")

        let connectId = UUID().uuidString
        let connectReq: [String: Any] = [
            "type": "req", "id": connectId, "method": "connect",
            "params": [
                "minProtocol": 3, "maxProtocol": 3,
                "client": ["id": "webchat", "mode": "webchat", "version": "1.0.0", "platform": "ios"],
                "auth": authParams
            ] as [String: Any]
        ]
        try await sendRaw(connectReq)

        // 3. Wait for connect response
        var connected = false
        for i in 0..<20 {
            let msg = try await receiveOne()
            if let data = msg.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if json["id"] as? String == connectId {
                    if json["ok"] as? Bool == true {
                        connected = true
                        appendLog("[ws] handshake OK!")
                    } else {
                        let errMsg = (json["error"] as? [String: Any])?["message"] as? String ?? "Unknown"
                        appendLog("[ws] handshake FAILED: \(errMsg)")
                        isConnecting = false
                        throw NSError(domain: "OpenClaw", code: -2, userInfo: [NSLocalizedDescriptionKey: errMsg])
                    }
                    break
                } else {
                    appendLog("[ws] skipping event \(i) during handshake")
                }
            }
        }

        guard connected else {
            appendLog("[ws] handshake timeout")
            isConnecting = false
            throw NSError(domain: "OpenClaw", code: -3, userInfo: [NSLocalizedDescriptionKey: "Handshake timeout"])
        }

        // 4. Start event loop
        Task { await receiveMessages() }

        // 5. Fetch sessions from health
        appendLog("[ws] fetching sessions from health...")
        await fetchSessionsFromHealth()
        appendLog("[ws] got \(cachedSessions.count) sessions")

        isConnected = true
        isConnecting = false
    }

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        pendingRequests.removeAll()
        cachedSessions = []
        connectionLog = ""
    }

    // MARK: - Health-based Session Fetch

    func fetchSessionsFromHealth() async {
        do {
            let res = try await send(method: "health", params: [:])
            if let payload = res.payload?.dictValue,
               let agents = payload["agents"] as? [[String: Any]] {
                var sessions: [[String: Any]] = []
                for agent in agents {
                    if let sessInfo = agent["sessions"] as? [String: Any],
                       let recent = sessInfo["recent"] as? [[String: Any]] {
                        sessions.append(contentsOf: recent)
                    }
                }
                cachedSessions = sessions
                appendLog("[health] parsed \(sessions.count) sessions from \(agents.count) agents")
            } else {
                appendLog("[health] no agents/sessions in payload")
            }
        } catch {
            appendLog("[health] error: \(error.localizedDescription)")
        }
    }

    // MARK: - Send/Receive

    func send(method: String, params: [String: Any]? = nil) async throws -> WSResponse {
        let id = UUID().uuidString
        let request: [String: Any] = [
            "type": "req", "id": id, "method": method, "params": params ?? [:]
        ]

        // Register continuation BEFORE sending to avoid race condition
        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[id] = continuation

            Task {
                do {
                    try await sendRaw(request)
                } catch {
                    if let cont = pendingRequests.removeValue(forKey: id) {
                        cont.resume(throwing: error)
                    }
                }
            }

            // Timeout
            Task {
                try? await Task.sleep(for: .seconds(30))
                await MainActor.run {
                    if let cont = self.pendingRequests.removeValue(forKey: id) {
                        self.appendLog("[ws] request \(method) timed out")
                        cont.resume(throwing: NSError(domain: "OpenClaw", code: -1, userInfo: [NSLocalizedDescriptionKey: "Timeout: \(method)"]))
                    }
                }
            }
        }
    }

    func sendNoWait(method: String, params: [String: Any]? = nil) {
        let req: [String: Any] = ["type": "req", "id": UUID().uuidString, "method": method, "params": params ?? [:]]
        Task { try? await sendRaw(req) }
    }

    private func sendRaw(_ dict: [String: Any]) async throws {
        let data = try JSONSerialization.data(withJSONObject: dict)
        let str = String(data: data, encoding: .utf8)!
        try await webSocketTask?.send(.string(str))
    }

    private func receiveOne() async throws -> String {
        guard let ws = webSocketTask else { throw NSError(domain: "OpenClaw", code: -1) }
        let msg = try await ws.receive()
        switch msg {
        case .string(let text): return text
        case .data(let data): return String(data: data, encoding: .utf8) ?? ""
        @unknown default: return ""
        }
    }

    private func receiveMessages() async {
        guard let ws = webSocketTask else { return }
        do {
            while true {
                let msg = try await ws.receive()
                switch msg {
                case .string(let text): handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) { handleMessage(text) }
                @unknown default: break
                }
            }
        } catch {
            appendLog("[ws] receive loop ended: \(error.localizedDescription)")
            await MainActor.run { isConnected = false }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "res":
            if let id = json["id"] as? String, let cont = pendingRequests.removeValue(forKey: id) {
                if let respData = try? JSONSerialization.data(withJSONObject: json),
                   let response = try? JSONDecoder().decode(WSResponse.self, from: respData) {
                    cont.resume(returning: response)
                } else {
                    cont.resume(throwing: NSError(domain: "OpenClaw", code: -1))
                }
            }
        case "event":
            handleEvent(json)
        default: break
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
                    if block["type"] as? String == "text", let t = block["text"] as? String { text += t }
                }
            }
            onChatEvent?(ChatEvent(sessionKey: sessionKey, runId: runId, state: state, text: text))

        case "exec.approval.requested":
            if let req = payload["request"] as? [String: Any] {
                onApprovalRequested?(ApprovalRequest(
                    id: payload["id"] as? String ?? "",
                    command: req["command"] as? String ?? req["ask"] as? String ?? "Unknown command",
                    sessionKey: req["sessionKey"] as? String
                ))
            }
        default: break
        }
    }

    // MARK: - API Methods

    func getIdentity() async throws -> [String: Any] {
        let res = try await send(method: "agent.identity.get")
        return res.payload?.dictValue ?? [:]
    }

    func sendChat(sessionKey: String, message: String) async throws -> String {
        let res = try await send(method: "chat.send", params: [
            "sessionKey": sessionKey, "message": message,
            "deliver": false, "idempotencyKey": UUID().uuidString
        ])
        if res.ok == true {
            return res.payload?.dictValue?["runId"] as? String ?? ""
        }
        throw NSError(domain: "OpenClaw", code: -1,
                       userInfo: [NSLocalizedDescriptionKey: res.error?.message ?? "chat.send failed"])
    }

    func abortChat(sessionKey: String) { sendNoWait(method: "chat.abort", params: ["sessionKey": sessionKey]) }
    func listCrons() async throws -> [[String: Any]] {
        let res = try await send(method: "cron.list")
        return res.payload?.dictValue?["crons"] as? [[String: Any]]
            ?? res.payload?.dictValue?["jobs"] as? [[String: Any]] ?? []
    }
    func addCron(label: String, prompt: String, schedule: String) async throws {
        _ = try await send(method: "cron.add", params: ["label": label, "prompt": prompt, "schedule": schedule])
    }
    func runCron(id: String) async throws { _ = try await send(method: "cron.run", params: ["id": id]) }
    func removeCron(id: String) async throws { _ = try await send(method: "cron.remove", params: ["id": id]) }
    func resolveApproval(id: String, decision: String) async throws {
        _ = try await send(method: "exec.approval.resolve", params: ["id": id, "decision": decision])
    }
}
