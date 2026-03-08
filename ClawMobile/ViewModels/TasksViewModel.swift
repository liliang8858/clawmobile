import SwiftUI

@MainActor
@Observable
final class TasksViewModel {
    var tasks: [AgentTask] = []
    var showingCreateTask = false
    var newTaskName = ""
    var newTaskPrompt = ""
    var newTaskSchedule = "0 9 * * *"
    var isLoading = false

    private let service = OpenClawService.shared

    var runningTasks: [AgentTask] { tasks.filter { $0.status == .running } }
    var scheduledTasks: [AgentTask] { tasks.filter { $0.status == .scheduled } }
    var completedTasks: [AgentTask] { tasks.filter { $0.status == .completed || $0.status == .failed } }

    func loadTasks(isDemoMode: Bool = false) {
        if isDemoMode || !service.isConnected {
            tasks = isDemoMode ? MockService.shared.tasks : []
            return
        }
        isLoading = true
        Task {
            do {
                let rawCrons = try await service.listCrons()
                var loaded: [AgentTask] = []
                for raw in rawCrons {
                    let id = raw["id"] as? String ?? UUID().uuidString
                    let label = raw["label"] as? String ?? raw["name"] as? String ?? "Task"
                    let prompt = raw["prompt"] as? String ?? ""
                    let schedule = raw["schedule"] as? String ?? raw["cron"] as? String ?? ""
                    let statusStr = raw["status"] as? String ?? "scheduled"
                    let enabled = raw["enabled"] as? Bool ?? true

                    let status: AgentTask.TaskStatus
                    if !enabled {
                        status = .completed
                    } else {
                        switch statusStr {
                        case "running": status = .running
                        case "completed", "done": status = .completed
                        case "failed", "error": status = .failed
                        default: status = .scheduled
                        }
                    }

                    var createdAt = Date()
                    if let ts = raw["createdAtMs"] as? Double {
                        createdAt = Date(timeIntervalSince1970: ts / 1000)
                    }

                    var lastRunAt: Date?
                    if let ts = raw["lastRunAtMs"] as? Double {
                        lastRunAt = Date(timeIntervalSince1970: ts / 1000)
                    } else if let ts = raw["lastRunAt"] as? String {
                        let f = ISO8601DateFormatter()
                        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        lastRunAt = f.date(from: ts)
                    }

                    loaded.append(AgentTask(
                        id: id,
                        name: label,
                        prompt: prompt,
                        schedule: schedule,
                        status: status,
                        createdAt: createdAt,
                        lastRunAt: lastRunAt
                    ))
                }
                self.tasks = loaded
            } catch {
                self.tasks = []
            }
            isLoading = false
        }
    }

    func createTask() {
        guard !newTaskName.isEmpty, !newTaskPrompt.isEmpty else { return }

        if service.isConnected {
            Task {
                do {
                    try await service.addCron(label: newTaskName, prompt: newTaskPrompt, schedule: newTaskSchedule)
                    loadTasks()
                } catch {
                    addLocalTask()
                }
            }
        } else {
            addLocalTask()
        }

        newTaskName = ""
        newTaskPrompt = ""
        newTaskSchedule = "0 9 * * *"
        showingCreateTask = false
    }

    private func addLocalTask() {
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
    }

    func deleteTask(_ task: AgentTask) {
        tasks.removeAll { $0.id == task.id }
        if service.isConnected {
            Task { try? await service.removeCron(id: task.id) }
        }
    }

    func runTask(_ task: AgentTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].status = .running
            tasks[index].lastRunAt = Date()
        }

        if service.isConnected {
            Task {
                try? await service.runCron(id: task.id)
                try? await Task.sleep(for: .seconds(2))
                loadTasks()
            }
        } else {
            Task {
                try? await Task.sleep(for: .seconds(3))
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[index].status = .completed
                }
            }
        }
    }
}
