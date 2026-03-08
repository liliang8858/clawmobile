import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List {
                // Agent Status Section
                if let agent = appState.connectedAgent {
                    Section("Agent") {
                        HStack {
                            Label("Name", systemImage: "cpu")
                            Spacer()
                            Text(agent.name)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Label("Model", systemImage: "brain")
                            Spacer()
                            Text(agent.model)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Label("Status", systemImage: "circle.fill")
                            Spacer()
                            Text(agent.status.rawValue.capitalized)
                                .foregroundStyle(agent.status == .online ? .green : .orange)
                        }

                        NavigationLink {
                            AgentStatusView(agent: agent)
                        } label: {
                            Label("Dashboard", systemImage: "chart.bar.fill")
                        }
                    }

                    // Tools Section
                    Section("Tools") {
                        ForEach(agent.tools, id: \.self) { tool in
                            HStack {
                                Image(systemName: toolIcon(tool))
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 24)
                                Text(tool)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                // App Settings
                Section("App") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0 (MVP)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Build", systemImage: "hammer")
                        Spacer()
                        Text("2024.1")
                            .foregroundStyle(.secondary)
                    }
                }

                // Disconnect
                Section {
                    Button(role: .destructive) {
                        appState.disconnect()
                    } label: {
                        Label("Disconnect Agent", systemImage: "wifi.slash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func toolIcon(_ tool: String) -> String {
        switch tool.lowercased() {
        case "shell": return "terminal"
        case "browser": return "globe"
        case "git": return "arrow.triangle.branch"
        case "file system": return "folder"
        case "database": return "cylinder"
        default: return "wrench"
        }
    }
}
