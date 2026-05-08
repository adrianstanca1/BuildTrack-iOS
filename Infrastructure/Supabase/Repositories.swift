import Foundation
import Supabase

// MARK: - Project Repository

struct ProjectRepository {
    static let live = ProjectRepository(
        fetchAll: {
            let client = SupabaseManager.shared.client
            let response: [SupabaseProject] = try await client
                .from("projects")
                .select()
                .order("updated_at", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        fetchById: { id in
            let client = SupabaseManager.shared.client
            let response: SupabaseProject = try await client
                .from("projects")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value
            return response.toDomain()
        },
        create: { project in
            let client = SupabaseManager.shared.client
            let payload = SupabaseProjectPayload(from: project)
            let response: SupabaseProject = try await client
                .from("projects")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
            return response.toDomain()
        },
        update: { project in
            let client = SupabaseManager.shared.client
            let payload = SupabaseProjectPayload(from: project)
            let _: SupabaseProject = try await client
                .from("projects")
                .update(payload)
                .eq("id", value: project.id.uuidString)
                .select()
                .single()
                .execute()
                .value
        },
        delete: { id in
            let client = SupabaseManager.shared.client
            let _ = try await client
                .from("projects")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        }
    )
    
    let fetchAll: () async throws -> [Project]
    let fetchById: (UUID) async throws -> Project
    let create: (Project) async throws -> Project
    let update: (Project) async throws -> Void
    let delete: (UUID) async throws -> Void
}

// MARK: - Task Repository

struct TaskRepository {
    static let live = TaskRepository(
        fetchAll: {
            let client = SupabaseManager.shared.client
            let response: [SupabaseTask] = try await client
                .from("tasks")
                .select()
                .order("due_date", ascending: true)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        fetchByProject: { projectId in
            let client = SupabaseManager.shared.client
            let response: [SupabaseTask] = try await client
                .from("tasks")
                .select()
                .eq("project_id", value: projectId.uuidString)
                .order("due_date", ascending: true)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        create: { task, projectId in
            let client = SupabaseManager.shared.client
            let payload = SupabaseTaskPayload(from: task, projectId: projectId)
            let response: SupabaseTask = try await client
                .from("tasks")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
            return response.toDomain()
        },
        update: { task in
            let client = SupabaseManager.shared.client
            let payload = SupabaseTaskPayload(from: task, projectId: task.project?.id)
            let _: SupabaseTask = try await client
                .from("tasks")
                .update(payload)
                .eq("id", value: task.id.uuidString)
                .select()
                .single()
                .execute()
                .value
        },
        delete: { id in
            let client = SupabaseManager.shared.client
            let _ = try await client
                .from("tasks")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        }
    )
    
    let fetchAll: () async throws -> [TaskItem]
    let fetchByProject: (UUID) async throws -> [TaskItem]
    let create: (TaskItem, UUID?) async throws -> TaskItem
    let update: (TaskItem) async throws -> Void
    let delete: (UUID) async throws -> Void
}

// MARK: - Conversions

extension SupabaseProject {
    func toDomain() -> Project {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return Project(
            id: id,
            name: name,
            descriptionText: descriptionText ?? "",
            status: ProjectStatus(rawValue: statusRaw) ?? .planning,
            budget: budget,
            spentToDate: spentToDate ?? 0,
            progress: progress ?? 0,
            startDate: formatter.date(from: startDate) ?? Date(),
            endDate: endDate.flatMap { formatter.date(from: $0) },
            locationName: locationName ?? "",
            latitude: latitude,
            longitude: longitude,
            clientName: clientName ?? "",
            createdAt: formatter.date(from: createdAt) ?? Date(),
            updatedAt: formatter.date(from: updatedAt) ?? Date()
        )
    }
}

extension SupabaseTask {
    func toDomain() -> TaskItem {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return TaskItem(
            id: id,
            title: title,
            descriptionText: descriptionText ?? "",
            priority: TaskPriority(rawValue: priorityRaw) ?? .medium,
            status: TaskStatus(rawValue: statusRaw) ?? .pending,
            dueDate: dueDate.flatMap { formatter.date(from: $0) },
            assignedTo: assignedTo ?? "",
            createdAt: formatter.date(from: createdAt) ?? Date(),
            updatedAt: formatter.date(from: updatedAt) ?? Date()
        )
    }
}

// MARK: - Payloads

struct SupabaseProjectPayload: Codable {
    let id: String
    let name: String
    let description: String?
    let status: String
    let budget: Double
    let spentToDate: Double?
    let progress: Double?
    let startDate: String
    let endDate: String?
    let locationName: String?
    let latitude: Double?
    let longitude: Double?
    let clientName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, status, budget, progress, latitude, longitude
        case spentToDate = "spent_to_date"
        case startDate = "start_date"
        case endDate = "end_date"
        case locationName = "location_name"
        case clientName = "client_name"
    }
    
    init(from project: Project) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        self.id = project.id.uuidString
        self.name = project.name
        self.description = project.descriptionText.isEmpty ? nil : project.descriptionText
        self.status = project.statusRaw
        self.budget = project.budget
        self.spentToDate = project.spentToDate
        self.progress = project.progress
        self.startDate = formatter.string(from: project.startDate)
        self.endDate = project.endDate.map { formatter.string(from: $0) }
        self.locationName = project.locationName.isEmpty ? nil : project.locationName
        self.latitude = project.latitude
        self.longitude = project.longitude
        self.clientName = project.clientName.isEmpty ? nil : project.clientName
    }
}

struct SupabaseTaskPayload: Codable {
    let id: String
    let title: String
    let description: String?
    let priority: String
    let status: String
    let dueDate: String?
    let assignedTo: String?
    let projectId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, priority, status
        case dueDate = "due_date"
        case assignedTo = "assigned_to"
        case projectId = "project_id"
    }
    
    init(from task: TaskItem, projectId: UUID?) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        self.id = task.id.uuidString
        self.title = task.title
        self.description = task.descriptionText.isEmpty ? nil : task.descriptionText
        self.priority = task.priorityRaw
        self.status = task.statusRaw
        self.dueDate = task.dueDate.map { formatter.string(from: $0) }
        self.assignedTo = task.assignedTo.isEmpty ? nil : task.assignedTo
        self.projectId = projectId?.uuidString
    }
}
