import Foundation
import SwiftData

// MARK: - Defect
@Model
final class Defect: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var title: String
    var defectDescription: String
    var location: String
    var severityRaw: String
    var statusRaw: String
    var assignedTo: String
    var dueDate: Date?
    var createdBy: String
    var projectId: UUID?
    var createdAt: Date
    var updatedAt: Date

    var severity: DefectSeverity {
        get { DefectSeverity(rawValue: severityRaw) ?? .minor }
        set { severityRaw = newValue.rawValue }
    }

    var status: DefectStatus {
        get { DefectStatus(rawValue: statusRaw) ?? .open }
        set { statusRaw = newValue.rawValue }
    }

    var isOverdue: Bool {
        guard let due = dueDate else { return false }
        return due < Date() && status != .closed
    }

    init(
        id: UUID = UUID(),
        title: String,
        defectDescription: String = "",
        location: String = "",
        severity: DefectSeverity = .minor,
        status: DefectStatus = .open,
        assignedTo: String = "",
        dueDate: Date? = nil,
        createdBy: String = "",
        projectId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.defectDescription = defectDescription
        self.location = location
        self.severityRaw = severity.rawValue
        self.statusRaw = status.rawValue
        self.assignedTo = assignedTo
        self.dueDate = dueDate
        self.createdBy = createdBy
        self.projectId = projectId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, defectDescription, location, severityRaw, statusRaw, assignedTo, dueDate, createdBy, projectId, createdAt, updatedAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.defectDescription = try container.decodeIfPresent(String.self, forKey: .defectDescription) ?? ""
        self.location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        self.severityRaw = try container.decode(String.self, forKey: .severityRaw)
        self.statusRaw = try container.decode(String.self, forKey: .statusRaw)
        self.assignedTo = try container.decodeIfPresent(String.self, forKey: .assignedTo) ?? ""
        self.dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy) ?? ""
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(defectDescription, forKey: .defectDescription)
        try container.encode(location, forKey: .location)
        try container.encode(severityRaw, forKey: .severityRaw)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encode(assignedTo, forKey: .assignedTo)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encode(createdBy, forKey: .createdBy)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

enum DefectSeverity: String, CaseIterable, Codable {
    case minor, major, critical
    var label: String {
        switch self {
        case .minor: return "Minor"
        case .major: return "Major"
        case .critical: return "Critical"
        }
    }
}

enum DefectStatus: String, CaseIterable, Codable {
    case open, inProgress, resolved, closed
    var label: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        case .closed: return "Closed"
        }
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
    var materialsUsed: String
    var equipmentUsed: String
    var issuesDelays: String
    var safetyObservations: String
    var nextDayPlan: String
    var submittedBy: String
    var statusRaw: String
    var projectId: UUID?
    var createdAt: Date
    var updatedAt: Date

    var status: DailyReportStatus {
        get { DailyReportStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        reportDate: Date = Date(),
        weather: String = "",
        temperature: Double = 0,
        workersOnSite: Int = 0,
        workCompleted: String = "",
        materialsUsed: String = "",
        equipmentUsed: String = "",
        issuesDelays: String = "",
        safetyObservations: String = "",
        nextDayPlan: String = "",
        submittedBy: String = "",
        status: DailyReportStatus = .draft,
        projectId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.reportDate = reportDate
        self.weather = weather
        self.temperature = temperature
        self.workersOnSite = workersOnSite
        self.workCompleted = workCompleted
        self.materialsUsed = materialsUsed
        self.equipmentUsed = equipmentUsed
        self.issuesDelays = issuesDelays
        self.safetyObservations = safetyObservations
        self.nextDayPlan = nextDayPlan
        self.submittedBy = submittedBy
        self.statusRaw = status.rawValue
        self.projectId = projectId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, reportDate, weather, temperature, workersOnSite, workCompleted
        case materialsUsed, equipmentUsed, issuesDelays, safetyObservations
        case nextDayPlan, submittedBy, statusRaw, projectId, createdAt, updatedAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.reportDate = try container.decode(Date.self, forKey: .reportDate)
        self.weather = try container.decodeIfPresent(String.self, forKey: .weather) ?? ""
        self.temperature = try container.decodeIfPresent(Double.self, forKey: .temperature) ?? 0
        self.workersOnSite = try container.decodeIfPresent(Int.self, forKey: .workersOnSite) ?? 0
        self.workCompleted = try container.decodeIfPresent(String.self, forKey: .workCompleted) ?? ""
        self.materialsUsed = try container.decodeIfPresent(String.self, forKey: .materialsUsed) ?? ""
        self.equipmentUsed = try container.decodeIfPresent(String.self, forKey: .equipmentUsed) ?? ""
        self.issuesDelays = try container.decodeIfPresent(String.self, forKey: .issuesDelays) ?? ""
        self.safetyObservations = try container.decodeIfPresent(String.self, forKey: .safetyObservations) ?? ""
        self.nextDayPlan = try container.decodeIfPresent(String.self, forKey: .nextDayPlan) ?? ""
        self.submittedBy = try container.decodeIfPresent(String.self, forKey: .submittedBy) ?? ""
        self.statusRaw = try container.decode(String.self, forKey: .statusRaw)
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(reportDate, forKey: .reportDate)
        try container.encode(weather, forKey: .weather)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(workersOnSite, forKey: .workersOnSite)
        try container.encode(workCompleted, forKey: .workCompleted)
        try container.encode(materialsUsed, forKey: .materialsUsed)
        try container.encode(equipmentUsed, forKey: .equipmentUsed)
        try container.encode(issuesDelays, forKey: .issuesDelays)
        try container.encode(safetyObservations, forKey: .safetyObservations)
        try container.encode(nextDayPlan, forKey: .nextDayPlan)
        try container.encode(submittedBy, forKey: .submittedBy)
        try container.encode(statusRaw, forKey: .statusRaw)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

