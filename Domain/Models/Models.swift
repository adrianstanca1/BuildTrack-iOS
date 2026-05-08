import Foundation
import SwiftData

// MARK: - Project
@Model
final class Project: Identifiable, Codable {
    @Attribute(.unique)
    var id: UUID
    var name: String
    var descriptionText: String
    var statusRaw: String
    var budget: Double
    var spentToDate: Double
    var progress: Double
    var startDate: Date
    var endDate: Date?
    var locationName: String
    var latitude: Double?
    var longitude: Double?
    var clientName: String
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade)
    var tasks: [TaskItem]? = []
    @Relationship(deleteRule: .cascade)
    var incidents: [Incident]? = []
    @Relationship(deleteRule: .cascade)
    var workers: [Worker]? = []
    
    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRaw) ?? .planning }
        set { statusRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        descriptionText: String = "",
        status: ProjectStatus = .planning,
        budget: Double = 0,
        spentToDate: Double = 0,
        progress: Double = 0,
        startDate: Date = Date(),
        endDate: Date? = nil,
        locationName: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        clientName: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.statusRaw = status.rawValue
        self.budget = budget
        self.spentToDate = spentToDate
        self.progress = progress
        self.startDate = startDate
        self.endDate = endDate
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.clientName = clientName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, descriptionText, statusRaw, budget, spentToDate
        case progress, startDate, endDate, locationName
        case latitude, longitude, clientName, createdAt, updatedAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.descriptionText = try container.decodeIfPresent(String.self, forKey: .descriptionText) ?? ""
        self.statusRaw = try container.decode(String.self, forKey: .statusRaw)
        self.budget = try container.decode(Double.self, forKey: .budget)
        self.spentToDate = try container.decodeIfPresent(Double.self, forKey: .spentToDate) ?? 0
        self.progress = try container.decodeIfPresent(Double.self, forKey: .progress) ?? 0
        self.startDate = try container.decode(Date.self, forKey: .startDate)
        self.endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        self.locationName = try container.decodeIfPresent(String.self, forKey: .locationName) ?? ""
        self.latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        self.longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        self.clientName = try container.decodeIfPresent(String.self, forKey: .clientName) ?? ""
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(descriptionText, forKey: .descriptionText)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encode(budget, forKey: .budget)
        try container.encode(spentToDate, forKey: .spentToDate)
        try container.encode(progress, forKey: .progress)
        try container.encode(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encode(locationName, forKey: .locationName)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
        try container.encode(clientName, forKey: .clientName)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

enum ProjectStatus: String, CaseIterable, Codable, Identifiable {
    case planning, active, onHold = "on_hold", completed, cancelled
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .planning: "Planning"
        case .active: "Active"
        case .onHold: "On Hold"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        }
    }
    
    var icon: String {
        switch self {
        case .planning: "blueprint"
        case .active: "hammer.fill"
        case .onHold: "pause.circle.fill"
        case .completed: "checkmark.circle.fill"
        case .cancelled: "xmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .planning: "blue"
        case .active: "green"
        case .onHold: "orange"
        case .completed: "gray"
        case .cancelled: "red"
        }
    }
}

// MARK: - TaskItem
@Model
final class TaskItem: Identifiable, Codable {
    @Attribute(.unique)
    var id: UUID
    var title: String
    var descriptionText: String
    var priorityRaw: String
    var statusRaw: String
    var dueDate: Date?
    var assignedTo: String
    var createdAt: Date
    var updatedAt: Date
    
    var project: Project?
    
    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
    
    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        descriptionText: String = "",
        priority: TaskPriority = .medium,
        status: TaskStatus = .pending,
        dueDate: Date? = nil,
        assignedTo: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.priorityRaw = priority.rawValue
        self.statusRaw = status.rawValue
        self.dueDate = dueDate
        self.assignedTo = assignedTo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, descriptionText, priorityRaw, statusRaw
        case dueDate, assignedTo, createdAt, updatedAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.descriptionText = try container.decodeIfPresent(String.self, forKey: .descriptionText) ?? ""
        self.priorityRaw = try container.decode(String.self, forKey: .priorityRaw)
        self.statusRaw = try container.decode(String.self, forKey: .statusRaw)
        self.dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        self.assignedTo = try container.decodeIfPresent(String.self, forKey: .assignedTo) ?? ""
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(descriptionText, forKey: .descriptionText)
        try container.encode(priorityRaw, forKey: .priorityRaw)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encode(assignedTo, forKey: .assignedTo)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low, medium, high, critical
    
    var label: String { rawValue.capitalized }
    var color: String {
        switch self {
        case .low: "gray"
        case .medium: "blue"
        case .high: "orange"
        case .critical: "red"
        }
    }
}

enum TaskStatus: String, CaseIterable, Codable {
    case pending, inProgress = "in_progress", completed, blocked
    
    var label: String {
        switch self {
        case .pending: "Pending"
        case .inProgress: "In Progress"
        case .completed: "Completed"
        case .blocked: "Blocked"
        }
    }
}

// MARK: - Safety Models
@Model
final class Incident: Identifiable, Codable {
    @Attribute(.unique)
    var id: UUID
    var title: String
    var descriptionText: String
    var severityRaw: String
    var statusRaw: String
    var reportedBy: String
    var location: String
    var date: Date
    var createdAt: Date
    @Relationship
    var project: Project?
    
    var severity: IncidentSeverity {
        get { IncidentSeverity(rawValue: severityRaw) ?? .low }
        set { severityRaw = newValue.rawValue }
    }
    
    var incidentStatus: IncidentStatus {
        get { IncidentStatus(rawValue: statusRaw) ?? .open }
        set { statusRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        descriptionText: String = "",
        severity: IncidentSeverity = .low,
        incidentStatus: IncidentStatus = .open,
        reportedBy: String = "",
        location: String = "",
        date: Date = Date(),
        createdAt: Date = Date(),
        project: Project? = nil
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.severityRaw = severity.rawValue
        self.statusRaw = incidentStatus.rawValue
        self.reportedBy = reportedBy
        self.location = location
        self.date = date
        self.createdAt = createdAt
        self.project = project
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, descriptionText, severityRaw, statusRaw
        case reportedBy, location, date, createdAt, project
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.descriptionText = try container.decodeIfPresent(String.self, forKey: .descriptionText) ?? ""
        self.severityRaw = try container.decode(String.self, forKey: .severityRaw)
        self.statusRaw = try container.decode(String.self, forKey: .statusRaw)
        self.reportedBy = try container.decodeIfPresent(String.self, forKey: .reportedBy) ?? ""
        self.location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        self.date = try container.decode(Date.self, forKey: .date)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.project = try container.decodeIfPresent(Project.self, forKey: .project)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(descriptionText, forKey: .descriptionText)
        try container.encode(severityRaw, forKey: .severityRaw)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encode(reportedBy, forKey: .reportedBy)
        try container.encode(location, forKey: .location)
        try container.encode(date, forKey: .date)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(project, forKey: .project)
    }
}

enum IncidentSeverity: String, CaseIterable, Codable {
    case low, medium, high, critical
    
    var label: String { rawValue.capitalized }
    var color: String {
        switch self {
        case .low: "yellow"
        case .medium: "orange"
        case .high: "red"
        case .critical: "purple"
        }
    }
}

enum IncidentStatus: String, CaseIterable, Codable {
    case open, investigating, resolved, closed
    var label: String { rawValue.capitalized }
}

@Model
final class Inspection: Identifiable, Codable {
    @Attribute(.unique)
    var id: UUID
    var title: String
    var inspector: String
    var resultRaw: String
    var date: Date
    var notes: String
    var createdAt: Date
    
    var result: InspectionResult {
        get { InspectionResult(rawValue: resultRaw) ?? .pass }
        set { resultRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        inspector: String = "",
        result: InspectionResult = .pass,
        date: Date = Date(),
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.inspector = inspector
        self.resultRaw = result.rawValue
        self.date = date
        self.notes = notes
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, inspector, resultRaw, date, notes, createdAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.inspector = try container.decodeIfPresent(String.self, forKey: .inspector) ?? ""
        self.resultRaw = try container.decode(String.self, forKey: .resultRaw)
        self.date = try container.decode(Date.self, forKey: .date)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(inspector, forKey: .inspector)
        try container.encode(resultRaw, forKey: .resultRaw)
        try container.encode(date, forKey: .date)
        try container.encode(notes, forKey: .notes)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

enum InspectionResult: String, CaseIterable, Codable {
    case pass, fail, conditional
    var label: String { rawValue.capitalized }
}

// MARK: - Worker
@Model
final class Worker: Identifiable, Codable {
    @Attribute(.unique)
    var id: UUID
    var name: String
    var roleRaw: String
    var phone: String
    var email: String
    var certifications: [String]
    var isActive: Bool
    var createdAt: Date
    
    var role: WorkerRole {
        get { WorkerRole(rawValue: roleRaw) ?? .labourer }
        set { roleRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        role: WorkerRole = .labourer,
        phone: String = "",
        email: String = "",
        certifications: [String] = [],
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.roleRaw = role.rawValue
        self.phone = phone
        self.email = email
        self.certifications = certifications
        self.isActive = isActive
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, roleRaw, phone, email, certifications, isActive, createdAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.roleRaw = try container.decode(String.self, forKey: .roleRaw)
        self.phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        self.email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        self.certifications = try container.decodeIfPresent([String].self, forKey: .certifications) ?? []
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(roleRaw, forKey: .roleRaw)
        try container.encode(phone, forKey: .phone)
        try container.encode(email, forKey: .email)
        try container.encode(certifications, forKey: .certifications)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

enum WorkerRole: String, CaseIterable, Codable {
    case labourer, carpenter, electrician, plumber
    case supervisor, foreman, engineer, `operator`
    
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .labourer: "figure.construction"
        case .carpenter: "hammer.fill"
        case .electrician: "bolt.fill"
        case .plumber: "drop.fill"
        case .supervisor: "person.fill.checkmark"
        case .foreman: "person.2.fill"
        case .engineer: "ruler.fill"
        case .operator: "wrench.fill"
        }
    }
}

// MARK: - Notification
struct AppNotification: Identifiable, Codable, Sendable {
    let id: UUID
    let title: String
    let body: String
    let type: NotificationType
    let isRead: Bool
    let createdAt: Date
    let relatedId: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        type: NotificationType = .info,
        isRead: Bool = false,
        createdAt: Date = Date(),
        relatedId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.type = type
        self.isRead = isRead
        self.createdAt = createdAt
        self.relatedId = relatedId
    }
}

enum NotificationType: String, Codable, Sendable {
    case info, warning, success, error, task, incident
    
    var icon: String {
        switch self {
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .success: "checkmark.circle.fill"
        case .error: "xmark.circle.fill"
        case .task: "list.clipboard.fill"
        case .incident: "shield.exclamation"
        }
    }
}

// MARK: - Supabase Models for Decoding

struct SupabaseProject: Codable {
    let id: UUID
    let name: String
    let descriptionText: String?
    let statusRaw: String
    let budget: Double
    let spentToDate: Double?
    let progress: Double?
    let startDate: String
    let endDate: String?
    let locationName: String?
    let latitude: Double?
    let longitude: Double?
    let clientName: String?
    let createdAt: String
    let updatedAt: String
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, budget, progress, latitude, longitude
        case descriptionText = "description"
        case statusRaw = "status"
        case spentToDate = "spent_to_date"
        case startDate = "start_date"
        case endDate = "end_date"
        case locationName = "location_name"
        case clientName = "client_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
}

struct SupabaseTask: Codable {
    let id: UUID
    let title: String
    let descriptionText: String?
    let priorityRaw: String
    let statusRaw: String
    let dueDate: String?
    let assignedTo: String?
    let projectId: UUID?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, title
        case descriptionText = "description"
        case priorityRaw = "priority"
        case statusRaw = "status"
        case dueDate = "due_date"
        case assignedTo = "assigned_to"
        case projectId = "project_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
