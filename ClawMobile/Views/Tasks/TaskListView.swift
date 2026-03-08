import SwiftUI

struct TaskListView: View {
    @State private var viewModel = TasksViewModel()
    @Environment(L10n.self) private var l10n

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.runningTasks.isEmpty {
                    Section(l10n.running) {
                        ForEach(viewModel.runningTasks) { task in
                            TaskRowView(task: task, onRun: { viewModel.runTask(task) })
                        }
                    }
                }

                if !viewModel.scheduledTasks.isEmpty {
                    Section(l10n.scheduled) {
                        ForEach(viewModel.scheduledTasks) { task in
                            TaskRowView(task: task, onRun: { viewModel.runTask(task) })
                        }
                        .onDelete { indexSet in
                            let scheduled = viewModel.scheduledTasks
                            for index in indexSet {
                                viewModel.deleteTask(scheduled[index])
                            }
                        }
                    }
                }

                if !viewModel.completedTasks.isEmpty {
                    Section(l10n.completed) {
                        ForEach(viewModel.completedTasks) { task in
                            TaskRowView(task: task, onRun: { viewModel.runTask(task) })
                        }
                    }
                }
            }
            .navigationTitle(l10n.tasks)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingCreateTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateTask) {
                CreateTaskView(viewModel: viewModel)
            }
        }
    }
}
