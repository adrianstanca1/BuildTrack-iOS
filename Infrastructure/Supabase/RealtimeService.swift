import Foundation
import OSLog
import SwiftData
import Supabase

// MARK: - Realtime Change Types

enum RealtimeOperation: String, Sendable {
    case insert = "INSERT"
    case update = "UPDATE"
    case delete = "DELETE"
}

enum ConnectionState: Sendable {
    case connected
    case disconnected
    case reconnecting(attempt: Int)
    
    var label: String {
        switch self {
        case .connected: "Connected"
        case .disconnected: "Disconnected"
        case .reconnecting(let n): "Reconnecting (attempt \(n))"
        }
    }
}

// MARK: - Realtime Service

@MainActor
@Observable
final class RealtimeService {
    static let shared = RealtimeService()
    
    private(set) var connectionState: ConnectionState = .disconnected
    private(set) var lastSync: Date?
    
    private let client: SupabaseClient
    private var channels: [RealtimeChannel] = []
    private var changeBuffer: [String: Date] = [:]
    private let debounceInterval: TimeInterval = 0.3
    private var reconnectAttempt = 0
    private let maxReconnectBackoff: TimeInterval = 8
    private let modelContext: ModelContext?
    
    var onProjectChange: (@Sendable (RealtimeOperation, UUID) -> Void)?
    var onTaskChange: (@Sendable (RealtimeOperation, UUID) -> Void)?
    
    private init() {
        self.client = SupabaseManager.shared.client
        
        let schema = Schema([Project.self, TaskItem.self, Incident.self, Inspection.self, Worker.self])
        let container = try? ModelContainer(for: schema)
        self.modelContext = container?.mainContext
    }
    
    // MARK: - Subscribe
    
    func subscribeAll() async {
        await subscribeToProjects()
        await subscribeToTasks()
    }
    
    func subscribeToProjects() async {
        let channel = client.channel("projects-changes")
        channels.append(channel)
        
        let insertStream = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "projects"
        )
        let updateStream = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "projects"
        )
        let deleteStream = channel.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "projects"
        )
        
        // Consume insertions
        Task {
            for await change in insertStream {
                await handleProjectInsert(change)
            }
        }
        
        // Consume updates
        Task {
            for await change in updateStream {
                await handleProjectUpdate(change)
            }
        }
        
        // Consume deletions
        Task {
            for await change in deleteStream {
                await handleProjectDelete(change)
            }
        }
        
        do {
            try await channel.subscribe()
            connectionState = .connected
            reconnectAttempt = 0
            lastSync = Date()
        } catch {
            Logger.realtime.error("Project subscribe error: \(error)")
            await scheduleReconnect()
        }
    }
    
    func subscribeToTasks() async {
        let channel = client.channel("tasks-changes")
        channels.append(channel)
        
        let insertStream = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "tasks"
        )
        let updateStream = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "tasks"
        )
        let deleteStream = channel.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "tasks"
        )
        
        Task {
            for await change in insertStream {
                await handleTaskInsert(change)
            }
        }
        
        Task {
            for await change in updateStream {
                await handleTaskUpdate(change)
            }
        }
        
        Task {
            for await change in deleteStream {
                await handleTaskDelete(change)
            }
        }
        
        do {
            try await channel.subscribe()
            connectionState = .connected
            reconnectAttempt = 0
        } catch {
            Logger.realtime.error("Task subscribe error: \(error)")
            await scheduleReconnect()
        }
    }
    
    func unsubscribeAll() {
        for channel in channels {
            Task { await channel.unsubscribe() }
        }
        channels.removeAll()
        connectionState = .disconnected
    }
    
    // MARK: - Change Handlers
    
    private func handleProjectInsert(_ change: InsertAction) async {
        await debounce(key: "project-insert") {
            if let id = UUID(uuidString: change.record["id"]?.stringValue ?? "") {
                try? await self.refreshProject(id: id)
                self.onProjectChange?(.insert, id)
                self.lastSync = Date()
            }
        }
    }
    
    private func handleProjectUpdate(_ change: UpdateAction) async {
        await debounce(key: "project-update") {
            if let id = UUID(uuidString: change.record["id"]?.stringValue ?? "") {
                try? await self.refreshProject(id: id)
                self.onProjectChange?(.update, id)
                self.lastSync = Date()
            }
        }
    }
    
    private func handleProjectDelete(_ change: DeleteAction) async {
        if let id = UUID(uuidString: change.oldRecord["id"]?.stringValue ?? "") {
            self.removeLocalProject(id: id)
            self.onProjectChange?(.delete, id)
            self.lastSync = Date()
        }
    }
    
    private func handleTaskInsert(_ change: InsertAction) async {
        await debounce(key: "task-insert") {
            if let id = UUID(uuidString: change.record["id"]?.stringValue ?? "") {
                try? await self.refreshTask(id: id)
                self.onTaskChange?(.insert, id)
                self.lastSync = Date()
            }
        }
    }
    
    private func handleTaskUpdate(_ change: UpdateAction) async {
        await debounce(key: "task-update") {
            if let id = UUID(uuidString: change.record["id"]?.stringValue ?? "") {
                try? await self.refreshTask(id: id)
                self.onTaskChange?(.update, id)
                self.lastSync = Date()
            }
        }
    }
    
    private func handleTaskDelete(_ change: DeleteAction) async {
        if let id = UUID(uuidString: change.oldRecord["id"]?.stringValue ?? "") {
            self.removeLocalTask(id: id)
            self.onTaskChange?(.delete, id)
            self.lastSync = Date()
        }
    }
    
    // MARK: - Debounce
    
    private func debounce(key: String, action: @escaping () async throws -> Void) async {
        let uniqueKey = "\(key)-\(UUID().uuidString)"
        changeBuffer[uniqueKey] = Date()
        
        try? await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))
        guard changeBuffer.removeValue(forKey: uniqueKey) != nil else { return }
        
        try? await action()
    }
    
    // MARK: - Local Sync
    
    private func refreshProject(id: UUID) async throws {
        guard let context = modelContext else { return }
        
        let response: SupabaseProject = try await client
            .from("projects")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        let project = response.toDomain()
        
        let predicate = #Predicate<Project> { $0.id == id }
        let descriptor = FetchDescriptor<Project>(predicate: predicate)
        if let existing = try? context.fetch(descriptor).first {
            existing.name = project.name
            existing.descriptionText = project.descriptionText
            existing.status = project.status
            existing.budget = project.budget
            existing.spentToDate = project.spentToDate
            existing.progress = project.progress
            existing.startDate = project.startDate
            existing.endDate = project.endDate
            existing.locationName = project.locationName
            existing.latitude = project.latitude
            existing.longitude = project.longitude
            existing.clientName = project.clientName
            existing.updatedAt = project.updatedAt
        } else {
            context.insert(project)
        }
        try? context.save()
    }
    
    private func refreshTask(id: UUID) async throws {
        guard let context = modelContext else { return }
        
        let response: SupabaseTask = try await client
            .from("tasks")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        let taskItem = response.toDomain()
        let predicate = #Predicate<TaskItem> { $0.id == id }
        let descriptor = FetchDescriptor<TaskItem>(predicate: predicate)
        if let existing = try? context.fetch(descriptor).first {
            existing.title = taskItem.title
            existing.descriptionText = taskItem.descriptionText
            existing.priority = taskItem.priority
            existing.status = taskItem.status
            existing.dueDate = taskItem.dueDate
            existing.assignedTo = taskItem.assignedTo
            existing.updatedAt = taskItem.updatedAt
        } else {
            context.insert(taskItem)
        }
        try? context.save()
    }
    
    private func removeLocalProject(id: UUID) {
        guard let context = modelContext else { return }
        let predicate = #Predicate<Project> { $0.id == id }
        try? context.delete(model: Project.self, where: predicate)
        try? context.save()
    }
    
    private func removeLocalTask(id: UUID) {
        guard let context = modelContext else { return }
        let predicate = #Predicate<TaskItem> { $0.id == id }
        try? context.delete(model: TaskItem.self, where: predicate)
        try? context.save()
    }
    
    // MARK: - Reconnect
    
    private func scheduleReconnect() async {
        let backoff = min(pow(2.0, Double(reconnectAttempt)), maxReconnectBackoff)
        reconnectAttempt += 1
        
        connectionState = .reconnecting(attempt: reconnectAttempt)
        
        try? await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
        await subscribeAll()
    }
}
