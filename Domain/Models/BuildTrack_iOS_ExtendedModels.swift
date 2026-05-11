import Foundation
import SwiftData
import UIKit

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
