import SwiftUI

struct AgentStatusView: View {
    let agent: Agent
    @Environment(L10n.self) private var l10n

    var body: some View {
        List {
            Section(l10n.overview) {
                statusRow(icon: "circle.fill", label: l10n.status, value: l10n.agentStatus(agent.status), color: agent.status == .online ? .green : .orange)
                statusRow(icon: "clock", label: l10n.uptime, value: l10n.formatUptime(agent.uptime), color: .blue)
                statusRow(icon: "checklist", label: l10n.activeTasks, value: "\(agent.activeTasks)", color: .purple)
            }

            Section(l10n.resources) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("CPU", systemImage: "cpu")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f%%", agent.cpuUsage))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(cpuColor)
                    }
                    ProgressView(value: agent.cpuUsage, total: 100)
                        .tint(cpuColor)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(l10n.memory, systemImage: "memorychip")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f%%", agent.memoryUsage))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(memoryColor)
                    }
                    ProgressView(value: agent.memoryUsage, total: 100)
                        .tint(memoryColor)
                }
                .padding(.vertical, 4)
            }

            Section(l10n.usage) {
                HStack {
                    Label(l10n.tokensUsed, systemImage: "number")
                    Spacer()
                    Text(formatNumber(agent.tokenUsage))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Label(l10n.memoryStore, systemImage: "internaldrive")
                    Spacer()
                    Text("\(agent.memorySize) \(l10n.items)")
                        .foregroundStyle(.secondary)
                }
            }

            Section(l10n.activeTools) {
                ForEach(agent.tools, id: \.self) { tool in
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text(tool)
                        Spacer()
                        Text(l10n.enabled)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .navigationTitle(l10n.agentDashboard)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var cpuColor: Color {
        agent.cpuUsage > 80 ? .red : agent.cpuUsage > 50 ? .orange : .green
    }

    private var memoryColor: Color {
        agent.memoryUsage > 80 ? .red : agent.memoryUsage > 50 ? .orange : .blue
    }

    private func statusRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(color)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
