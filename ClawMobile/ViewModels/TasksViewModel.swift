import SwiftUI

@MainActor
@Observable
final class TasksViewModel {
    var tasks: [AgentTask] = MockService.shared.tasks
    var showingCreateTask = false
    var newTaskName = ""
    var newTaskPrompt = ""
    var newTaskSchedule = "0 9 * * *"

    var runningTasks: [AgentTask] {
        tasks.filter { $0.status == .running }
    }

    var scheduledTasks: [AgentTask] {
        tasks.filter { $0.status == .scheduled }
    }

    var completedTasks: [AgentTask] {
        tasks.filter { $0.status == .completed || $0.status == .failed }
    }

    func createTask() {
        guard !newTaskName.isEmpty, !newTaskPrompt.isEmpty else { return }
        let task = AgentTask(
            id: UUID().uuidString,
            name: newTaskName,
            prompt: newTaskPrompt,
            schedule: newTaskSchedule,
            status: .scheduled,
            createdAt: Date(),
            nextRunAt: Date().addingTimeInterval(3600)
        )
        tasks.insert(task, at: 0)
        newTaskName = ""
        newTaskPrompt = ""
        newTaskSchedule = "0 9 * * *"
        showingCreateTask = false
    }

    func deleteTask(_ task: AgentTask) {
        tasks.removeAll { $0.id == task.id }
    }

    func runTask(_ task: AgentTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].status = .running
            tasks[index].lastRunAt = Date()

            Task {
                try? await Task.sleep(for: .seconds(3))
                if index < tasks.count, tasks[index].id == task.id {
                    tasks[index].status = .completed
                }
            }
        }
    }
}
