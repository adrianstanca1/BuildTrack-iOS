import SwiftUI
import SwiftData

@MainActor
@Observable
final class TaskViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([TaskItem])
        case error(String)
    }
    
    private(set) var state: State = .idle
    private let repository = TaskRepository.live
    private let modelContext: ModelContext?
    
    init() {
        let container = try? ModelContainer(for: TaskItem.self)
        self.modelContext = container?.mainContext
    }
    
    // MARK: - Fetch
    
    func loadAllTasks() async {
        state = .loading
        do {
            let fetched = try await repository.fetchAll()
            syncLocal(fetched)
            state = .loaded(fetched)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func loadTasksForProject(_ projectId: UUID) async -> [TaskItem] {
        do {
            let tasks = try await repository.fetchByProject(projectId)
            syncLocal(tasks)
            return tasks
        } catch {
            print("Load tasks error: \(error)")
            return []
        }
    }
    
    func searchTasks(query: String) -> [TaskItem] {
        guard case .loaded(let tasks) = state else { return [] }
        guard !query.isEmpty else { return tasks }
        return tasks.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }
    
    // MARK: - Filtering
    
    func filterByPriority(_ priority: TaskPriority?, tasks: [TaskItem]) -> [TaskItem] {
        guard let priority else { return tasks }
        return tasks.filter { $0.priority == priority }
    }
    
    func filterByStatus(_ status: TaskStatus?, tasks: [TaskItem]) -> [TaskItem] {
        guard let status else { return tasks }
        return tasks.filter { $0.status == status }
    }
    
    func getTodayTasks() -> [TaskItem] {
        guard case .loaded(let tasks) = state else { return [] }
        return tasks.filter { task in
            guard let due = task.dueDate else { return false }
            return Calendar.current.isDateInToday(due) && task.status != .completed
        }
    }
    
    func getOverdueTasks() -> [TaskItem] {
        guard case .loaded(let tasks) = state else { return [] }
        return tasks.filter { task in
            guard let due = task.dueDate, !Calendar.current.isDateInToday(due) else { return false }
            return due < Date() && task.status != .completed
        }
    }
    
    func groupedTasks(_ tasks: [TaskItem]) -> [(String, [TaskItem])] {
        let calendar = Calendar.current
        let now = Date()
        
        let overdue = tasks.filter { task in
            guard let due = task.dueDate, task.status != .completed else { return false }
            return due < now && !calendar.isDateInToday(due)
        }
        let today = tasks.filter { task in
            guard let due = task.dueDate, task.status != .completed else { return false }
            return calendar.isDateInToday(due)
        }
        let thisWeek = tasks.filter { task in
            guard let due = task.dueDate, task.status != .completed else { return false }
            return due > now && calendar.isDate(due, equalTo: now, toGranularity: .weekOfYear)
                && !calendar.isDateInToday(due)
        }
        let later = tasks.filter { task in
            guard let due = task.dueDate, task.status != .completed else { return false }
            return due > now && !calendar.isDate(due, equalTo: now, toGranularity: .weekOfYear)
        }
        let completed = tasks.filter { $0.status == .completed }
        
        var groups: [(String, [TaskItem])] = []
        if !overdue.isEmpty { groups.append(("Overdue", overdue.sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) })) }
        if !today.isEmpty { groups.append(("Today", today)) }
        if !thisWeek.isEmpty { groups.append(("This Week", thisWeek)) }
        if !later.isEmpty { groups.append(("Later", later)) }
        if !completed.isEmpty { groups.append(("Completed", completed)) }
        
        return groups
    }
    
    var completionRate: Double {
        guard case .loaded(let tasks) = state, !tasks.isEmpty else { return 0 }
        return Double(tasks.filter { $0.status == .completed }.count) / Double(tasks.count)
    }
    
    var totalCount: Int {
        guard case .loaded(let tasks) = state else { return 0 }
        return tasks.count
    }
    
    // MARK: - CRUD
    
    func createTask(
        title: String,
        description: String = "",
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        assignedTo: String = "",
        projectId: UUID? = nil
    ) async -> TaskItem? {
        do {
            let newTask = TaskItem(
                title: title,
                descriptionText: description,
                priority: priority,
                dueDate: dueDate,
                assignedTo: assignedTo
            )
            
            // Optimistic local insert
            modelContext?.insert(newTask)
            try? modelContext?.save()
            
            let created = try await repository.create(newTask, projectId)
            
            // Refresh state
            await loadAllTasks()
            return created
        } catch {
            print("Create task error: \(error)")
            return nil
        }
    }
    
    func updateTask(_ task: TaskItem, title: String, description: String, priority: TaskPriority, status: TaskStatus, dueDate: Date?, assignedTo: String) async {
        // Optimistic local update
        task.title = title
        task.descriptionText = description
        task.priority = priority
        task.status = status
        task.dueDate = dueDate
        task.assignedTo = assignedTo
        task.updatedAt = Date()
        try? modelContext?.save()
        
        do {
            try await repository.update(task)
        } catch {
            print("Update task error: \(error)")
            // Reload to resync
            await loadAllTasks()
        }
    }
    
    func toggleComplete(_ task: TaskItem) async {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            let newStatus: TaskStatus = task.status == .completed ? .pending : .completed
            task.status = newStatus
            task.updatedAt = Date()
        }
        try? modelContext?.save()
        
        do {
            try await repository.update(task)
        } catch {
            print("Toggle task error: \(error)")
            await loadAllTasks()
        }
    }
    
    func deleteTask(_ task: TaskItem) async {
        modelContext?.delete(task)
        try? modelContext?.save()
        
        do {
            try await repository.delete(task.id)
            await loadAllTasks()
        } catch {
            print("Delete task error: \(error)")
            await loadAllTasks()
        }
    }
    
    // MARK: - Bulk Operations
    
    func markAllComplete(_ tasks: [TaskItem]) async {
        withAnimation {
            for task in tasks where task.status != .completed {
                task.status = .completed
                task.updatedAt = Date()
            }
        }
        try? modelContext?.save()
        
        for task in tasks where task.status == .completed {
            try? await repository.update(task)
        }
        await loadAllTasks()
    }
    
    func deleteAllCompleted() async {
        guard case .loaded(let allTasks) = state else { return }
        let completed = allTasks.filter { $0.status == .completed }
        
        for task in completed {
            modelContext?.delete(task)
        }
        try? modelContext?.save()
        
        for task in completed {
            try? await repository.delete(task.id)
        }
        await loadAllTasks()
    }
    
    // MARK: - Sync
    
    private func syncLocal(_ tasks: [TaskItem]) {
        guard let context = modelContext else { return }
        // Remove stale, insert fresh
        for task in tasks {
            let predicate = #Predicate<TaskItem> { $0.id == task.id }
            try? context.delete(model: TaskItem.self, where: predicate)
            context.insert(task)
        }
        try? context.save()
    }
}
