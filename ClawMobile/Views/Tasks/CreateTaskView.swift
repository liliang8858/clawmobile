import SwiftUI

struct CreateTaskView: View {
    @Bindable var viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Task name", text: $viewModel.newTaskName)
                    TextField("Prompt", text: $viewModel.newTaskPrompt, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Schedule (cron)") {
                    TextField("Cron expression", text: $viewModel.newTaskSchedule)
                        .font(.system(.body, design: .monospaced))

                    // Quick presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick presets")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            schedulePreset("Every hour", cron: "0 * * * *")
                            schedulePreset("Daily 9am", cron: "0 9 * * *")
                            schedulePreset("Weekly Mon", cron: "0 9 * * 1")
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
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
