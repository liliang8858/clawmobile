import SwiftUI

struct AgentStatusView: View {
    let agent: Agent

    var body: some View {
        List {
            // Status Overview
            Section("Overview") {
                statusRow(icon: "circle.fill", label: "Status", value: agent.status.rawValue.capitalized, color: agent.status == .online ? .green : .orange)
                statusRow(icon: "clock", label: "Uptime", value: formatUptime(agent.uptime), color: .blue)
                statusRow(icon: "checklist", label: "Active Tasks", value: "\(agent.activeTasks)", color: .purple)
            }

            // Resource Usage
            Section("Resources") {
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
                        Label("Memory", systemImage: "memorychip")
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

            // Token Usage
            Section("Usage") {
                HStack {
                    Label("Tokens Used", systemImage: "number")
                    Spacer()
                    Text(formatNumber(agent.tokenUsage))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Label("Memory Store", systemImage: "internaldrive")
                    Spacer()
                    Text("\(agent.memorySize) items")
                        .foregroundStyle(.secondary)
                }
            }

            // Tools
            Section("Active Tools") {
                ForEach(agent.tools, id: \.self) { tool in
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text(tool)
                        Spacer()
                        Text("Enabled")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .navigationTitle("Agent Dashboard")
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

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        return "\(days)d \(hours)h"
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
