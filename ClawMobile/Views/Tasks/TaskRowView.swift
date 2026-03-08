import SwiftUI

struct TaskRowView: View {
    let task: AgentTask
    let onRun: () -> Void

    var statusColor: Color {
        switch task.status {
        case .running: return .blue
        case .scheduled: return .orange
        case .completed: return .green
        case .failed: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: task.status.icon)
                    .foregroundStyle(statusColor)

                Text(task.name)
                    .font(.headline)

                Spacer()

                if task.status == .running {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            Text(task.prompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(task.schedule)
                    .font(.system(.caption, design: .monospaced))

                Spacer()

                if let lastRun = task.lastRunAt {
                    Text("Last: \(lastRun, style: .relative)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.secondary)

            if task.status == .scheduled {
                Button {
                    onRun()
                } label: {
                    Label("Run Now", systemImage: "play.fill")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}
