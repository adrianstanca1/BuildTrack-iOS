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
    
    var rawValueForSupabase: String {
        switch self {
        case .onHold: return "on-hold"
        default: return rawValue
        }
    }
    
    init?(fromSupabase value: String) {
        switch value {
        case "on-hold": self = .onHold
        default: self.init(rawValue: value)
        }
    }
    
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
    
    var rawValueForSupabase: String {
        switch self {
        case .critical: return "urgent"
        default: return rawValue
        }
    }
    
    init?(fromSupabase value: String) {
        switch value {
        case "urgent": self = .critical
        default:
            self.init(rawValue: value)
        }
    }
    
    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
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
    
    var rawValueForSupabase: String {
        switch self {
        case .blocked: return "pending"
        case .inProgress: return "in_progress"
        default: return rawValue
        }
    }
    
    init?(fromSupabase value: String) {
        switch value {
        case "pending", "blocked": self = .pending
        case "in_progress", "in-progress": self = .inProgress
        case "completed": self = .completed
        default: self.init(rawValue: value)
        }
    }
    
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
    case supervisor, foreman, engineer, `operator`, safetyOfficer = "safety-officer"
    
    var rawValueForSupabase: String {
        switch self {
        case .labourer: return "laborer"
        case .supervisor: return "foreman"
        case .operator: return "safety-officer"
        case .safetyOfficer: return "safety-officer"
        default: return rawValue
        }
    }
    
    init?(fromSupabase value: String) {
        switch value {
        case "laborer": self = .labourer
        case "safety-officer": self = .operator
        default: self.init(rawValue: value)
        }
    }
    
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
        case .safetyOfficer: "shield.lefthalf.fill"
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
// MARK: - PunchItem
@Model
final class PunchItem: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var title: String
    var descriptionText: String
    var statusRaw: String
    var severityRaw: String
    var location: String
    var assignee: String
    var photoUrls: [String]
    var projectId: UUID?
    var createdAt: Date
    var resolvedAt: Date?
    var status: PunchItemStatus {
        get { PunchItemStatus(rawValue: statusRaw) ?? .open }
        set { statusRaw = newValue.rawValue }
    }
    var severity: PunchItemSeverity {
        get { PunchItemSeverity(rawValue: severityRaw) ?? .minor }
        set { severityRaw = newValue.rawValue }
    }
    init(
        id: UUID = UUID(),
        title: String,
        descriptionText: String = "",
        status: PunchItemStatus = .open,
        severity: PunchItemSeverity = .minor,
        location: String = "",
        assignee: String = "",
        photoUrls: [String] = [],
        projectId: UUID? = nil,
        createdAt: Date = Date(),
        resolvedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.statusRaw = status.rawValue
        self.severityRaw = severity.rawValue
        self.location = location
        self.assignee = assignee
        self.photoUrls = photoUrls
        self.projectId = projectId
        self.createdAt = createdAt
        self.resolvedAt = resolvedAt
    }
    enum CodingKeys: String, CodingKey {
        case id, title, descriptionText, statusRaw, severityRaw
        case location, assignee, photoUrls, projectId, createdAt, resolvedAt
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.descriptionText = try container.decodeIfPresent(String.self, forKey: .descriptionText) ?? ""
        self.statusRaw = try container.decode(String.self, forKey: .statusRaw)
        self.severityRaw = try container.decode(String.self, forKey: .severityRaw)
        self.location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        self.assignee = try container.decodeIfPresent(String.self, forKey: .assignee) ?? ""
        self.photoUrls = try container.decodeIfPresent([String].self, forKey: .photoUrls) ?? []
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.resolvedAt = try container.decodeIfPresent(Date.self, forKey: .resolvedAt)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(descriptionText, forKey: .descriptionText)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encode(severityRaw, forKey: .severityRaw)
        try container.encode(location, forKey: .location)
        try container.encode(assignee, forKey: .assignee)
        try container.encode(photoUrls, forKey: .photoUrls)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(resolvedAt, forKey: .resolvedAt)
    }
}
enum PunchItemStatus: String, CaseIterable, Codable {
    case open = "open", inProgress = "in_progress", resolved = "resolved", closed = "closed"
    var label: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        case .closed: return "Closed"
        }
    }
    var color: String {
        switch self {
        case .open: return "red"
        case .inProgress: return "orange"
        case .resolved: return "green"
        case .closed: return "gray"
        }
    }
}
enum PunchItemSeverity: String, CaseIterable, Codable {
    case cosmetic, minor, major, critical
    var label: String {
        switch self {
        case .cosmetic: return "Cosmetic"
        case .minor: return "Minor"
        case .major: return "Major"
        case .critical: return "Critical"
        }
    }
}
// MARK: - RFI
@Model
final class RFI: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var title: String
    var descriptionText: String
    var statusRaw: String
    var priorityRaw: String
    var assignedTo: String
    var response: String
    var projectId: UUID?
    var createdAt: Date
    var respondedAt: Date?
    var status: RFIStatus {
        get { RFIStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }
    var priority: RFIPriority {
        get { RFIPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
    init(
        id: UUID = UUID(),
        title: String,
        descriptionText: String = "",
        status: RFIStatus = .draft,
        priority: RFIPriority = .medium,
        assignedTo: String = "",
        response: String = "",
        projectId: UUID? = nil,
        createdAt: Date = Date(),
        respondedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.statusRaw = status.rawValue
        self.priorityRaw = priority.rawValue
        self.assignedTo = assignedTo
        self.response = response
        self.projectId = projectId
        self.createdAt = createdAt
        self.respondedAt = respondedAt
    }
    enum CodingKeys: String, CodingKey {
        case id, title, descriptionText, statusRaw, priorityRaw
        case assignedTo, response, projectId, createdAt, respondedAt
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.descriptionText = try container.decodeIfPresent(String.self, forKey: .descriptionText) ?? ""
        self.statusRaw = try container.decode(String.self, forKey: .statusRaw)
        self.priorityRaw = try container.decode(String.self, forKey: .priorityRaw)
        self.assignedTo = try container.decodeIfPresent(String.self, forKey: .assignedTo) ?? ""
        self.response = try container.decodeIfPresent(String.self, forKey: .response) ?? ""
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.respondedAt = try container.decodeIfPresent(Date.self, forKey: .respondedAt)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(descriptionText, forKey: .descriptionText)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encode(priorityRaw, forKey: .priorityRaw)
        try container.encode(assignedTo, forKey: .assignedTo)
        try container.encode(response, forKey: .response)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(respondedAt, forKey: .respondedAt)
    }
}
enum RFIStatus: String, CaseIterable, Codable {
    case draft = "draft", submitted = "submitted", underReview = "under_review", approved = "approved", rejected = "rejected", closed = "closed"
    var label: String {
        switch self {
        case .draft: return "Draft"
        case .submitted: return "Submitted"
        case .underReview: return "Under Review"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .closed: return "Closed"
        }
    }
    var color: String {
        switch self {
        case .draft: return "gray"
        case .submitted: return "blue"
        case .underReview: return "orange"
        case .approved: return "green"
        case .rejected: return "red"
        case .closed: return "gray"
        }
    }
}
enum RFIPriority: String, CaseIterable, Codable {
    case low, medium, high, urgent
    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
}
// MARK: - Drawing
@Model
final class Drawing: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var title: String
    var drawingNumber: String
    var revision: String
    var statusRaw: String
    var fileUrl: String
    var projectId: UUID?
    var createdAt: Date
    var updatedAt: Date
    var status: DrawingStatus {
        get { DrawingStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }
    init(
        id: UUID = UUID(),
        title: String,
        drawingNumber: String = "",
        revision: String = "A",
        status: DrawingStatus = .active,
        fileUrl: String = "",
        projectId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.drawingNumber = drawingNumber
        self.revision = revision
        self.statusRaw = status.rawValue
        self.fileUrl = fileUrl
        self.projectId = projectId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    enum CodingKeys: String, CodingKey {
        case id, title, drawingNumber, revision, statusRaw, fileUrl, projectId, createdAt, updatedAt
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.drawingNumber = try container.decodeIfPresent(String.self, forKey: .drawingNumber) ?? ""
        self.revision = try container.decodeIfPresent(String.self, forKey: .revision) ?? "A"
        self.statusRaw = try container.decode(String.self, forKey: .statusRaw)
        self.fileUrl = try container.decodeIfPresent(String.self, forKey: .fileUrl) ?? ""
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(drawingNumber, forKey: .drawingNumber)
        try container.encode(revision, forKey: .revision)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encode(fileUrl, forKey: .fileUrl)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
enum DrawingStatus: String, CaseIterable, Codable {
    case active, superseded, archived
    var label: String {
        switch self {
        case .active: return "Active"
        case .superseded: return "Superseded"
        case .archived: return "Archived"
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
        case locationName = "location"
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
// MARK: - Supabase Incident
struct SupabaseIncident: Codable {
    let id: UUID
    let title: String
    let descriptionText: String?
    let severityRaw: String
    let projectId: UUID?
    let projectName: String?
    let reportedBy: String?
    let incidentDate: String
    let injuries: Int?
    let photos: [String]?
    let createdAt: String
    let updatedAt: String
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title
        case descriptionText = "description"
        case severityRaw = "severity"
        case projectId = "project_id"
        case projectName = "project_name"
        case reportedBy = "reported_by"
        case incidentDate = "incident_date"
        case injuries, photos
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
}
extension SupabaseIncident {
    func toDomain() -> Incident {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return Incident(
            id: id,
            title: title,
            descriptionText: descriptionText ?? "",
            severity: IncidentSeverity(rawValue: severityRaw) ?? .low,
            reportedBy: reportedBy ?? "",
            location: projectName ?? "",
            date: formatter.date(from: incidentDate) ?? Date(),
            createdAt: formatter.date(from: createdAt) ?? Date()
        )
    }
}
// MARK: - Supabase Inspection
struct SupabaseInspection: Codable {
    let id: UUID
    let title: String
    let descriptionText: String?
    let projectId: UUID?
    let projectName: String?
    let statusRaw: String
    let inspectionDate: String
    let inspector: String?
    let findings: [String]?
    let photos: [String]?
    let createdAt: String
    let updatedAt: String
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title
        case descriptionText = "description"
        case projectId = "project_id"
        case projectName = "project_name"
        case statusRaw = "status"
        case inspectionDate = "inspection_date"
        case inspector, findings, photos
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
}
extension SupabaseInspection {
    func toDomain() -> Inspection {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let result: InspectionResult = {
            switch statusRaw {
            case "passed": return .pass
            case "failed": return .fail
            default: return .pass
            }
        }()
        return Inspection(
            id: id,
            title: title,
            inspector: inspector ?? "",
            result: result,
            date: formatter.date(from: inspectionDate) ?? Date(),
            notes: descriptionText ?? "",
            createdAt: formatter.date(from: createdAt) ?? Date()
        )
    }
}
// MARK: - Supabase Worker
struct SupabaseWorker: Codable {
    let id: UUID
    let name: String
    let roleRaw: String
    let statusRaw: String
    let phone: String?
    let email: String?
    let hourlyRate: Double?
    let weeklyHours: Int?
    let certifications: [String]?
    let createdAt: String
    let updatedAt: String
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case roleRaw = "role"
        case statusRaw = "status"
        case phone, email
        case hourlyRate = "hourly_rate"
        case weeklyHours = "weekly_hours"
        case certifications
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
}
extension SupabaseWorker {
    func toDomain() -> Worker {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return Worker(
            id: id,
            name: name,
            role: WorkerRole(fromSupabase: roleRaw) ?? .labourer,
            phone: phone ?? "",
            email: email ?? "",
            certifications: certifications ?? [],
            isActive: statusRaw == "active",
            createdAt: formatter.date(from: createdAt) ?? Date()
        )
    }
}
// MARK: - Supabase Notification
struct SupabaseNotification: Codable {
    let id: UUID
    let title: String
    let body: String?
    let typeRaw: String
    let relatedId: UUID?
    let isRead: Bool
    let createdAt: String
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, body
        case typeRaw = "type"
        case relatedId = "related_id"
        case isRead = "read"
        case createdAt = "created_at"
        case userId = "user_id"
    }
}
extension SupabaseNotification {
    func toDomain() -> AppNotification {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let notifType: NotificationType = {
            switch typeRaw {
            case "task": return .task
            case "safety": return .incident
            case "project": return .info
            case "team": return .success
            case "general": return .info
            default: return .info
            }
        }()
        return AppNotification(
            id: id,
            title: title,
            body: body ?? "",
            type: notifType,
            isRead: isRead,
            createdAt: formatter.date(from: createdAt) ?? Date(),
            relatedId: relatedId?.uuidString
        )
    }
}

// MARK: - Budget
@Model
final class Budget: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var name: String
    var totalBudget: Double
    var totalSpent: Double
    var currency: String
    var statusRaw: String
    var createdAt: Date
    var updatedAt: Date
    
    var status: BudgetStatus {
        get { BudgetStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }
    var progress: Double { totalBudget > 0 ? totalSpent / totalBudget : 0 }
    
    init(id: UUID = UUID(), name: String, totalBudget: Double = 0, totalSpent: Double = 0, currency: String = "GBP", status: BudgetStatus = .draft, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.name = name; self.totalBudget = totalBudget; self.totalSpent = totalSpent
        self.currency = currency; self.statusRaw = status.rawValue; self.createdAt = createdAt; self.updatedAt = updatedAt
    }
    enum CodingKeys: String, CodingKey { case id, name, totalBudget, totalSpent, currency, statusRaw, createdAt, updatedAt }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id); self.name = try c.decode(String.self, forKey: .name)
        self.totalBudget = try c.decode(Double.self, forKey: .totalBudget); self.totalSpent = try c.decodeIfPresent(Double.self, forKey: .totalSpent) ?? 0
        self.currency = try c.decodeIfPresent(String.self, forKey: .currency) ?? "GBP"
        self.statusRaw = try c.decode(String.self, forKey: .statusRaw)
        self.createdAt = try c.decode(Date.self, forKey: .createdAt); self.updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }
    func encode(to e: Encoder) throws {
        var c = e.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(name, forKey: .name); try c.encode(totalBudget, forKey: .totalBudget)
        try c.encode(totalSpent, forKey: .totalSpent); try c.encode(currency, forKey: .currency)
        try c.encode(statusRaw, forKey: .statusRaw); try c.encode(createdAt, forKey: .createdAt); try c.encode(updatedAt, forKey: .updatedAt)
    }
}
enum BudgetStatus: String, CaseIterable, Codable { case draft, approved, inProgress = "in_progress", overBudget = "over_budget", completed, cancelled }
// MARK: - Material
@Model
final class Material: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String
    var quantity: Double
    var unit: String
    var statusRaw: String
    var createdAt: Date
    var updatedAt: Date
    
    var status: MaterialStatus {
        get { MaterialStatus(rawValue: statusRaw) ?? .ordered }
        set { statusRaw = newValue.rawValue }
    }
    
    init(id: UUID = UUID(), name: String, category: String = "", quantity: Double = 0, unit: String = "", status: MaterialStatus = .ordered, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.name = name; self.category = category; self.quantity = quantity; self.unit = unit
        self.statusRaw = status.rawValue; self.createdAt = createdAt; self.updatedAt = updatedAt
    }
    enum CodingKeys: String, CodingKey { case id, name, category, quantity, unit, statusRaw, createdAt, updatedAt }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id); self.name = try c.decode(String.self, forKey: .name)
        self.category = try c.decodeIfPresent(String.self, forKey: .category) ?? ""
        self.quantity = try c.decodeIfPresent(Double.self, forKey: .quantity) ?? 0
        self.unit = try c.decodeIfPresent(String.self, forKey: .unit) ?? ""
        self.statusRaw = try c.decode(String.self, forKey: .statusRaw)
        self.createdAt = try c.decode(Date.self, forKey: .createdAt); self.updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }
    func encode(to e: Encoder) throws {
        var c = e.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(name, forKey: .name); try c.encode(category, forKey: .category)
        try c.encode(quantity, forKey: .quantity); try c.encode(unit, forKey: .unit)
        try c.encode(statusRaw, forKey: .statusRaw); try c.encode(createdAt, forKey: .createdAt); try c.encode(updatedAt, forKey: .updatedAt)
    }
}
enum MaterialStatus: String, CaseIterable, Codable { case ordered, delivered, inStock = "in_stock", used }
// MARK: - Meeting
@Model
final class Meeting: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var title: String
    var meetingTypeRaw: String
    var date: Date
    var location: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    
    var meetingType: MeetingType {
        get { MeetingType(rawValue: meetingTypeRaw) ?? .site }
        set { meetingTypeRaw = newValue.rawValue }
    }
    
    init(id: UUID = UUID(), title: String, meetingType: MeetingType = .site, date: Date = Date(), location: String = "", notes: String = "", createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.title = title; self.meetingTypeRaw = meetingType.rawValue; self.date = date
        self.location = location; self.notes = notes; self.createdAt = createdAt; self.updatedAt = updatedAt
    }
    enum CodingKeys: String, CodingKey { case id, title, meetingTypeRaw, date, location, notes, createdAt, updatedAt }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id); self.title = try c.decode(String.self, forKey: .title)
        self.meetingTypeRaw = try c.decode(String.self, forKey: .meetingTypeRaw); self.date = try c.decode(Date.self, forKey: .date)
        self.location = try c.decodeIfPresent(String.self, forKey: .location) ?? ""
        self.notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.createdAt = try c.decode(Date.self, forKey: .createdAt); self.updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }
    func encode(to e: Encoder) throws {
        var c = e.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(title, forKey: .title); try c.encode(meetingTypeRaw, forKey: .meetingTypeRaw)
        try c.encode(date, forKey: .date); try c.encode(location, forKey: .location); try c.encode(notes, forKey: .notes)
        try c.encode(createdAt, forKey: .createdAt); try c.encode(updatedAt, forKey: .updatedAt)
    }
}
enum MeetingType: String, CaseIterable, Codable { case site, progress, safety, design, other }
// MARK: - TimesheetEntry
@Model
final class TimesheetEntry: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var workerName: String
    var hoursWorked: Double
    var task: String
    var statusRaw: String
    var date: Date
    var createdAt: Date
    var updatedAt: Date
    
    var status: TimesheetStatus {
        get { TimesheetStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }
    
    init(id: UUID = UUID(), workerName: String, hoursWorked: Double = 0, task: String = "", status: TimesheetStatus = .draft, date: Date = Date(), createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.workerName = workerName; self.hoursWorked = hoursWorked; self.task = task
        self.statusRaw = status.rawValue; self.date = date; self.createdAt = createdAt; self.updatedAt = updatedAt
    }
    enum CodingKeys: String, CodingKey { case id, workerName, hoursWorked, task, statusRaw, date, createdAt, updatedAt }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id); self.workerName = try c.decode(String.self, forKey: .workerName)
        self.hoursWorked = try c.decodeIfPresent(Double.self, forKey: .hoursWorked) ?? 0
        self.task = try c.decodeIfPresent(String.self, forKey: .task) ?? ""
        self.statusRaw = try c.decode(String.self, forKey: .statusRaw); self.date = try c.decode(Date.self, forKey: .date)
        self.createdAt = try c.decode(Date.self, forKey: .createdAt); self.updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }
    func encode(to e: Encoder) throws {
        var c = e.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(workerName, forKey: .workerName); try c.encode(hoursWorked, forKey: .hoursWorked)
        try c.encode(task, forKey: .task); try c.encode(statusRaw, forKey: .statusRaw); try c.encode(date, forKey: .date)
        try c.encode(createdAt, forKey: .createdAt); try c.encode(updatedAt, forKey: .updatedAt)
    }
}
enum TimesheetStatus: String, CaseIterable, Codable { case draft, submitted, approved, rejected }
enum PermitStatus: String, CaseIterable, Codable { case applied, underReview = "under_review", approved, rejected, expired }
enum DailyReportStatus: String, CaseIterable, Codable { case draft, submitted, approved }
enum Severity: String, CaseIterable, Codable { case minor, major, critical }

// MARK: - Permit
@Model
final class Permit: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var permitNumber: String
    var permitType: String
    var authority: String
    var statusRaw: String
    var expiryDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    var status: PermitStatus {
        get { PermitStatus(rawValue: statusRaw) ?? .applied }
        set { statusRaw = newValue.rawValue }
    }
    var daysUntilExpiry: Int? {
        guard let expiryDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day
    }
    
    init(id: UUID = UUID(), permitNumber: String, permitType: String = "", authority: String = "", status: PermitStatus = .applied, expiryDate: Date? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.permitNumber = permitNumber; self.permitType = permitType; self.authority = authority
        self.statusRaw = status.rawValue; self.expiryDate = expiryDate; self.createdAt = createdAt; self.updatedAt = updatedAt
    }
    enum CodingKeys: String, CodingKey { case id, permitNumber, permitType, authority, statusRaw, expiryDate, createdAt, updatedAt }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id); self.permitNumber = try c.decode(String.self, forKey: .permitNumber)
        self.permitType = try c.decodeIfPresent(String.self, forKey: .permitType) ?? ""
        self.authority = try c.decodeIfPresent(String.self, forKey: .authority) ?? ""
        self.statusRaw = try c.decode(String.self, forKey: .statusRaw); self.expiryDate = try c.decodeIfPresent(Date.self, forKey: .expiryDate)
        self.createdAt = try c.decode(Date.self, forKey: .createdAt); self.updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }
    func encode(to e: Encoder) throws {
        var c = e.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(permitNumber, forKey: .permitNumber); try c.encode(permitType, forKey: .permitType)
        try c.encode(authority, forKey: .authority); try c.encode(statusRaw, forKey: .statusRaw); try c.encodeIfPresent(expiryDate, forKey: .expiryDate)
        try c.encode(createdAt, forKey: .createdAt); try c.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - DailyReport
@Model
final class DailyReport: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var reportDate: Date
    var weather: String
    var temperature: Double
    var workersOnSite: Int
    var workCompleted: String
    var statusRaw: String
    var createdAt: Date
    var updatedAt: Date
    
    var status: DailyReportStatus {
        get { DailyReportStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }
    
    init(id: UUID = UUID(), reportDate: Date = Date(), weather: String = "", temperature: Double = 0, workersOnSite: Int = 0, workCompleted: String = "", status: DailyReportStatus = .draft, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.reportDate = reportDate; self.weather = weather; self.temperature = temperature
        self.workersOnSite = workersOnSite; self.workCompleted = workCompleted; self.statusRaw = status.rawValue
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }
    enum CodingKeys: String, CodingKey { case id, reportDate, weather, temperature, workersOnSite, workCompleted, statusRaw, createdAt, updatedAt }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id); self.reportDate = try c.decode(Date.self, forKey: .reportDate)
        self.weather = try c.decodeIfPresent(String.self, forKey: .weather) ?? ""
        self.temperature = try c.decodeIfPresent(Double.self, forKey: .temperature) ?? 0
        self.workersOnSite = try c.decodeIfPresent(Int.self, forKey: .workersOnSite) ?? 0
        self.workCompleted = try c.decodeIfPresent(String.self, forKey: .workCompleted) ?? ""
        self.statusRaw = try c.decode(String.self, forKey: .statusRaw)
        self.createdAt = try c.decode(Date.self, forKey: .createdAt); self.updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }
    func encode(to e: Encoder) throws {
        var c = e.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(reportDate, forKey: .reportDate); try c.encode(weather, forKey: .weather)
        try c.encode(temperature, forKey: .temperature); try c.encode(workersOnSite, forKey: .workersOnSite)
        try c.encode(workCompleted, forKey: .workCompleted); try c.encode(statusRaw, forKey: .statusRaw)
        try c.encode(createdAt, forKey: .createdAt); try c.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - BudgetCategory (referenced in SwiftDataStack)
@Model
final class BudgetCategory: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var name: String
    var budgetId: UUID?
    var allocated: Double
    var spent: Double
    var createdAt: Date
    init(id: UUID = UUID(), name: String, budgetId: UUID? = nil, allocated: Double = 0, spent: Double = 0, createdAt: Date = Date()) {
        self.id = id; self.name = name; self.budgetId = budgetId; self.allocated = allocated; self.spent = spent; self.createdAt = createdAt
    }
    enum CodingKeys: String, CodingKey { case id, name, budgetId, allocated, spent, createdAt }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id); self.name = try c.decode(String.self, forKey: .name)
        self.budgetId = try c.decodeIfPresent(UUID.self, forKey: .budgetId)
        self.allocated = try c.decodeIfPresent(Double.self, forKey: .allocated) ?? 0
        self.spent = try c.decodeIfPresent(Double.self, forKey: .spent) ?? 0
        self.createdAt = try c.decode(Date.self, forKey: .createdAt)
    }
    func encode(to e: Encoder) throws {
        var c = e.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(name, forKey: .name); try c.encodeIfPresent(budgetId, forKey: .budgetId)
        try c.encode(allocated, forKey: .allocated); try c.encode(spent, forKey: .spent); try c.encode(createdAt, forKey: .createdAt)
    }
}
// MARK: - Equipment (referenced in SwiftDataStack)
@Model
final class Equipment: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: String
    var statusRaw: String
    var createdAt: Date
    var updatedAt: Date
    init(id: UUID = UUID(), name: String, type: String = "", status: String = "available", createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.name = name; self.type = type; self.statusRaw = status; self.createdAt = createdAt; self.updatedAt = updatedAt
    }
    enum CodingKeys: String, CodingKey { case id, name, type, statusRaw, createdAt, updatedAt }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id); self.name = try c.decode(String.self, forKey: .name)
        self.type = try c.decodeIfPresent(String.self, forKey: .type) ?? ""
        self.statusRaw = try c.decodeIfPresent(String.self, forKey: .statusRaw) ?? "available"
        self.createdAt = try c.decode(Date.self, forKey: .createdAt); self.updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }
    func encode(to e: Encoder) throws {
        var c = e.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(name, forKey: .name); try c.encode(type, forKey: .type)
        try c.encode(statusRaw, forKey: .statusRaw); try c.encode(createdAt, forKey: .createdAt); try c.encode(updatedAt, forKey: .updatedAt)
    }
}

enum EquipmentStatus: String, CaseIterable {
    case available = "available"
    case inUse = "inUse"
    case maintenance = "maintenance"
    case retired = "retired"
}
