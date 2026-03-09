import SwiftUI

struct ConnectView: View {
    @Environment(AppState.self) private var appState
    @Environment(L10n.self) private var l10n
    @State private var token = ""
    @State private var showTokenInput = false
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.accentColor.opacity(0.3), Color.clear],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)

                        Image(systemName: "cpu")
                            .font(.system(size: 60, weight: .light))
                            .foregroundStyle(Color.accentColor)
                    }

                    Text(l10n.appName)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(l10n.appSlogan)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Discovered Agent Card
                if let agent = appState.discoveredAgent {
                    discoveredAgentCard(agent)
                        .transition(.scale.combined(with: .opacity))
                }

                Spacer()

                VStack(spacing: 16) {
                    if appState.isConnecting {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.accentColor)
                        Text(l10n.connecting)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } else if appState.isScanning {
                        ProgressView()
                            .scaleEffect(1.0)
                            .tint(.accentColor)
                        Text(l10n.language == .zh ? "正在扫描本地 Agent..." : "Scanning for local Agent...")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } else if showTokenInput {
                        tokenInputView
                    } else {
                        connectionButtons
                    }

                    if let error = appState.connectionError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                }

                Spacer()
                    .frame(height: 40)
            }
        }
        .onAppear {
            pulseAnimation = true
            appState.scanForAgent()
        }
        .onChange(of: appState.discoveredAgent != nil) {
            // Auto-connect when agent is discovered
            if appState.discoveredAgent != nil && !appState.isConnecting && !appState.isConnected {
                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    appState.connectToDiscovered()
                }
            }
        }
    }

    // MARK: - Discovered Agent Card

    private func discoveredAgentCard(_ agent: DiscoveredAgent) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text(agent.avatar)
                    .font(.system(size: 36))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text(l10n.language == .zh ? "发现本地 Agent" : "Local Agent Found")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    Text(agent.name)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("v\(agent.serverVersion) | \(agent.url)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )

            Button {
                appState.connectToDiscovered()
            } label: {
                Label(l10n.language == .zh ? "连接此 Agent" : "Connect to Agent", systemImage: "link.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Token Input

    private var tokenInputView: some View {
        VStack(spacing: 12) {
            TextField(l10n.agentURLOrToken, text: $token)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Button {
                appState.connect(token: token)
            } label: {
                Text(l10n.connect)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button(l10n.back) {
                withAnimation { showTokenInput = false }
            }
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Connection Buttons

    private var connectionButtons: some View {
        VStack(spacing: 16) {
            if appState.discoveredAgent == nil {
                // No agent found - show scan + manual options
                Button {
                    appState.scanForAgent()
                } label: {
                    Label(l10n.language == .zh ? "重新扫描" : "Scan Again", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }

            Button {
                withAnimation { showTokenInput = true }
            } label: {
                Label(l10n.enterToken, systemImage: "keyboard")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
    }
}
