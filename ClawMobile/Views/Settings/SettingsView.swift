import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(L10n.self) private var l10n

    var body: some View {
        NavigationStack {
            List {
                if let agent = appState.connectedAgent {
                    Section(l10n.agentSection) {
                        HStack {
                            Label(l10n.name, systemImage: "cpu")
                            Spacer()
                            Text(agent.name)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Label(l10n.model, systemImage: "brain")
                            Spacer()
                            Text(agent.model)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Label(l10n.status, systemImage: "circle.fill")
                            Spacer()
                            Text(l10n.agentStatus(agent.status))
                                .foregroundStyle(agent.status == .online ? .green : .orange)
                        }

                        NavigationLink {
                            AgentStatusView(agent: agent)
                        } label: {
                            Label(l10n.dashboard, systemImage: "chart.bar.fill")
                        }
                    }

                    Section(l10n.tools) {
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

                // Language Setting
                Section(l10n.app) {
                    Picker(l10n.languageSetting, selection: Bindable(l10n).language) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }

                    HStack {
                        Label(l10n.version, systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0 (MVP)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label(l10n.build, systemImage: "hammer")
                        Spacer()
                        Text("2024.1")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        appState.disconnect()
                    } label: {
                        Label(l10n.disconnectAgent, systemImage: "wifi.slash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(l10n.settings)
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
