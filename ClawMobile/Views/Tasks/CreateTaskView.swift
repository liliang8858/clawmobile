import SwiftUI

struct CreateTaskView: View {
    @Bindable var viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(L10n.self) private var l10n

    var body: some View {
        NavigationStack {
            Form {
                Section(l10n.taskDetails) {
                    TextField(l10n.taskName, text: $viewModel.newTaskName)
                    TextField(l10n.prompt, text: $viewModel.newTaskPrompt, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section(l10n.scheduleCron) {
                    TextField(l10n.cronExpression, text: $viewModel.newTaskSchedule)
                        .font(.system(.body, design: .monospaced))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(l10n.quickPresets)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            schedulePreset(l10n.everyHour, cron: "0 * * * *")
                            schedulePreset(l10n.daily9am, cron: "0 9 * * *")
                            schedulePreset(l10n.weeklyMon, cron: "0 9 * * 1")
                        }
                    }
                }
            }
            .navigationTitle(l10n.newTask)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(l10n.cancel) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(l10n.create) {
                        viewModel.createTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.newTaskName.isEmpty || viewModel.newTaskPrompt.isEmpty)
                }
            }
        }
    }

    private func schedulePreset(_ label: String, cron: String) -> some View {
        Button {
            viewModel.newTaskSchedule = cron
        } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(viewModel.newTaskSchedule == cron ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(viewModel.newTaskSchedule == cron ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
