import Foundation
import Supabase

// MARK: - Enum Mappings (Supabase ↔ iOS)

extension TaskPriority {
    /// Maps Supabase priority values to iOS enum
    init?(supabaseValue: String) {
        switch supabaseValue {
        case "low": self = .low
        case "medium": self = .medium
        case "high": self = .high
        case "urgent": self = .critical  // Supabase uses "urgent", iOS uses "critical"
        default: return nil
        }
    }
    
    /// Maps iOS enum to Supabase priority values
    var supabaseValue: String {
        switch self {
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        case .critical: return "urgent"  // iOS "critical" → Supabase "urgent"
        }
    }
}

extension TaskStatus {
    init?(supabaseValue: String) {
        switch supabaseValue {
        case "pending": self = .pending
        case "in_progress": self = .inProgress
        case "completed": self = .completed
        default:
            // Supabase doesn't have "blocked" — map to pending
            self = .pending
        }
    }
    
    var supabaseValue: String {
        switch self {
        case .pending: return "pending"
        case .inProgress: return "in_progress"
        case .completed: return "completed"
        case .blocked: return "pending"  // iOS "blocked" → Supabase "pending"
        }
    }
}

extension WorkerRole {
    init?(supabaseValue: String) {
        switch supabaseValue {
        case "labourer": self = .labourer
        case "carpenter": self = .carpenter
        case "electrician": self = .electrician
        case "plumber": self = .plumber
        case "supervisor": self = .supervisor
        case "foreman": self = .foreman
        case "engineer": self = .engineer
        case "safety_officer": self = .operator  // Supabase "safety_officer" → iOS "operator"
        default: self = .labourer
        }
    }
    
    var supabaseValue: String {
        switch self {
        case .labourer: return "labourer"
        case .carpenter: return "carpenter"
        case .electrician: return "electrician"
        case .plumber: return "plumber"
        case .supervisor: return "supervisor"
        case .foreman: return "foreman"
        case .engineer: return "engineer"
        case .operator: return "safety_officer"  // iOS "operator" → Supabase "safety_officer"
        }
    }
}

extension TimesheetStatus {
    init?(supabaseValue: String) {
        switch supabaseValue {
        case "draft": self = .draft
        case "submitted": self = .submitted
        case "approved": self = .approved
        case "rejected": self = .rejected
        default: return nil
        }
    }
    
    var supabaseValue: String {
        switch self {
        case .draft: return "draft"
        case .submitted: return "submitted"
        case .approved: return "approved"
        case .rejected: return "rejected"
        }
    }
}

// MARK: - Supabase Mappable Protocol

protocol SupabaseMappable {
    associatedtype SupabaseModel: Codable
    init(from supabase: SupabaseModel)
    func toSupabase() -> SupabaseModel
}

// MARK: - Supabase Schema Extensions

extension SupabaseProject {
    var toLocalProject: Project {
        Project(
            id: id,
            name: name,
            descriptionText: descriptionText ?? "",
            status: ProjectStatus(rawValue: statusRaw) ?? .planning,
            budget: budget,
            spentToDate: spentToDate ?? 0,
            progress: progress ?? 0,
            startDate: ISO8601DateFormatter().date(from: startDate) ?? Date(),
            endDate: endDate.flatMap { ISO8601DateFormatter().date(from: $0) },
            locationName: locationName ?? "",
            latitude: latitude,
            longitude: longitude,
            clientName: clientName ?? "",
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            updatedAt: ISO8601DateFormatter().date(from: updatedAt) ?? Date()
        )
    }
}

extension Project {
    func toSupabaseProject() -> SupabaseProject {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return SupabaseProject(
            id: id,
            name: name,
            descriptionText: descriptionText,
            statusRaw: statusRaw,
            budget: budget,
            spentToDate: spentToDate,
            progress: progress,
            startDate: formatter.string(from: startDate),
            endDate: endDate.map { formatter.string(from: $0) },
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            clientName: clientName,
            createdAt: formatter.string(from: createdAt),
            updatedAt: formatter.string(from: updatedAt),
            userId: nil
        )
    }
}

extension SupabaseTask {
    var toLocalTaskItem: TaskItem {
        TaskItem(
            id: id,
            title: title,
            descriptionText: descriptionText ?? "",
            priority: TaskPriority(supabaseValue: priorityRaw) ?? .medium,
            status: TaskStatus(supabaseValue: statusRaw) ?? .pending,
            dueDate: dueDate.flatMap { ISO8601DateFormatter().date(from: $0) },
            assignedTo: assignedTo ?? "",
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            updatedAt: ISO8601DateFormatter().date(from: updatedAt) ?? Date()
        )
    }
}

extension TaskItem {
    func toSupabaseTask() -> SupabaseTask {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return SupabaseTask(
            id: id,
            title: title,
            descriptionText: descriptionText,
            priorityRaw: priority.supabaseValue,
            statusRaw: status.supabaseValue,
            dueDate: dueDate.map { formatter.string(from: $0) },
            assignedTo: assignedTo,
            projectId: project?.id,
            createdAt: formatter.string(from: createdAt),
            updatedAt: formatter.string(from: updatedAt)
        )
    }
}
