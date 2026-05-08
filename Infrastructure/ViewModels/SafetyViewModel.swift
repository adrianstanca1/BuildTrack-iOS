import Foundation
import SwiftUI
import Observation
import PhotosUI
import Supabase

// MARK: - Display Models

struct IncidentDisplay: Identifiable, Sendable {
    let id: UUID
    var title: String
    var descriptionText: String
    var severity: IncidentSeverity
    var status: IncidentStatus
    var reportedBy: String
    var location: String
    var date: Date
    var createdAt: Date
    var photoURLs: [String]
    var followUpActions: [String]
    var projectId: UUID?

    init(from model: Incident) {
        self.id = model.id
        self.title = model.title
        self.descriptionText = model.descriptionText
        self.severity = model.severity
        self.status = model.incidentStatus
        self.reportedBy = model.reportedBy
        self.location = model.location
        self.date = model.date
        self.createdAt = model.createdAt
        self.photoURLs = []
        self.followUpActions = []
        self.projectId = nil
    }

    init(
        id: UUID = UUID(),
        title: String,
        descriptionText: String = "",
        severity: IncidentSeverity = .low,
        status: IncidentStatus = .open,
        reportedBy: String = "",
        location: String = "",
        date: Date = Date(),
        createdAt: Date = Date(),
        photoURLs: [String] = [],
        followUpActions: [String] = [],
        projectId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.severity = severity
        self.status = status
        self.reportedBy = reportedBy
        self.location = location
        self.date = date
        self.createdAt = createdAt
        self.photoURLs = photoURLs
        self.followUpActions = followUpActions
        self.projectId = projectId
    }
}

struct InspectionDisplay: Identifiable, Sendable {
    let id: UUID
    var title: String
    var inspector: String
    var result: InspectionResult
    var date: Date
    var notes: String
    var createdAt: Date
    var checklistItems: [ChecklistItem]
    var photoURLs: [String]
    var projectId: UUID?

    init(from model: Inspection) {
        self.id = model.id
        self.title = model.title
        self.inspector = model.inspector
        self.result = model.result
        self.date = model.date
        self.notes = model.notes
        self.createdAt = model.createdAt
        self.checklistItems = []
        self.photoURLs = []
        self.projectId = nil
    }

    init(
        id: UUID = UUID(),
        title: String,
        inspector: String = "",
        result: InspectionResult = .pass,
        date: Date = Date(),
        notes: String = "",
        createdAt: Date = Date(),
        checklistItems: [ChecklistItem] = [],
        photoURLs: [String] = [],
        projectId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.inspector = inspector
        self.result = result
        self.date = date
        self.notes = notes
        self.createdAt = createdAt
        self.checklistItems = checklistItems
        self.photoURLs = photoURLs
        self.projectId = projectId
    }

    var overallStatus: ChecklistStatus {
        if checklistItems.isEmpty { return .notApplicable }
        let hasFail = checklistItems.contains { $0.status == .fail }
        let hasConditional = checklistItems.contains { $0.status == .conditional }
        if hasFail { return .fail }
        if hasConditional { return .conditional }
        return .pass
    }
}

struct ChecklistItem: Identifiable, Sendable, Codable {
    var id: UUID = UUID()
    var label: String
    var status: ChecklistStatus
}

enum ChecklistStatus: String, CaseIterable, Codable, Sendable {
    case pass, fail, conditional, notApplicable

    var label: String {
        switch self {
        case .pass: "Pass"
        case .fail: "Fail"
        case .conditional: "Conditional"
        case .notApplicable: "N/A"
        }
    }

    var icon: String {
        switch self {
        case .pass: "checkmark.circle.fill"
        case .fail: "xmark.circle.fill"
        case .conditional: "exclamationmark.triangle.fill"
        case .notApplicable: "minus.circle"
        }
    }

    var tint: Color {
        switch self {
        case .pass: .green
        case .fail: .red
        case .conditional: .orange
        case .notApplicable: .gray
        }
    }
}

// MARK: - Safety ViewModel

@MainActor
@Observable
final class SafetyViewModel {
    var incidents: [IncidentDisplay] = []
    var inspections: [InspectionDisplay] = []
    var selectedSeverityFilter: IncidentSeverity?
    var selectedResultFilter: InspectionResult?
    var isLoading = false
    var errorMessage: String?

    // MARK: Filtered Accessors

    var filteredIncidents: [IncidentDisplay] {
        guard let filter = selectedSeverityFilter else { return incidents }
        return incidents.filter { $0.severity == filter }
    }

    var filteredInspections: [InspectionDisplay] {
        guard let filter = selectedResultFilter else { return inspections }
        return inspections.filter { $0.result == filter }
    }

    // MARK: - Fetch

    func fetchIncidents() async {
        isLoading = true
        errorMessage = nil
        do {
            let client = SupabaseManager.shared.client
            let response: [SupabaseIncident] = try await client
                .from("incidents")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            incidents = response.map { $0.toDisplay() }
        } catch {
            errorMessage = "Failed to load incidents: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func fetchInspections() async {
        isLoading = true
        errorMessage = nil
        do {
            let client = SupabaseManager.shared.client
            let response: [SupabaseInspection] = try await client
                .from("inspections")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            inspections = response.map { $0.toDisplay() }
        } catch {
            errorMessage = "Failed to load inspections: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func fetchAll() async {
        async let inc: () = fetchIncidents()
        async let insp: () = fetchInspections()
        _ = await (inc, insp)
    }

    // MARK: - Incident CRUD

    func createIncident(
        title: String,
        descriptionText: String,
        severity: IncidentSeverity,
        reportedBy: String,
        location: String,
        date: Date,
        followUpActions: [String],
        photoData: [Data]
    ) async {
        isLoading = true
        errorMessage = nil
        do {
            let id = UUID()
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            var photoURLs: [String] = []
            for (index, data) in photoData.enumerated() {
                let path = "incidents/\(id.uuidString)/photo_\(index)_\(UUID().uuidString).jpg"
                let _ = try await SupabaseManager.shared.client.storage
                    .from("safety-photos")
                    .upload(path, data: data)
                    .execute()
                let publicURL = try SupabaseManager.shared.client.storage
                    .from("safety-photos")
                    .getPublicURL(path: path)
                photoURLs.append(publicURL.absoluteString)
            }

            let payload = SupabaseIncidentPayload(
                id: id.uuidString,
                title: title,
                description: descriptionText.isEmpty ? nil : descriptionText,
                severity: severity.rawValue,
                status: IncidentStatus.open.rawValue,
                reportedBy: reportedBy.isEmpty ? nil : reportedBy,
                location: location.isEmpty ? nil : location,
                date: iso.string(from: date),
                photoURLs: photoURLs,
                followUpActions: followUpActions,
                createdAt: iso.string(from: Date())
            )

            let _: SupabaseIncident = try await SupabaseManager.shared.client
                .from("incidents")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

            await fetchIncidents()
        } catch {
            errorMessage = "Failed to create incident: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func resolveIncident(_ incident: IncidentDisplay) async {
        await updateIncidentStatus(incident, status: .resolved)
    }

    func deleteIncident(_ incident: IncidentDisplay) async {
        isLoading = true
        errorMessage = nil
        do {
            let _ = try await SupabaseManager.shared.client
                .from("incidents")
                .delete()
                .eq("id", value: incident.id.uuidString)
                .execute()
            incidents.removeAll { $0.id == incident.id }
        } catch {
            errorMessage = "Failed to delete incident: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func updateIncidentStatus(_ incident: IncidentDisplay, status: IncidentStatus) async {
        isLoading = true
        errorMessage = nil
        do {
            let payload: [String: String] = ["status": status.rawValue]
            let _ = try await SupabaseManager.shared.client
                .from("incidents")
                .update(payload)
                .eq("id", value: incident.id.uuidString)
                .execute()
            await fetchIncidents()
        } catch {
            errorMessage = "Failed to update incident: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Inspection CRUD

    func createInspection(
        title: String,
        inspector: String,
        date: Date,
        notes: String,
        checklistItems: [ChecklistItem],
        photoData: [Data]
    ) async {
        isLoading = true
        errorMessage = nil
        do {
            let id = UUID()
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            // Calculate overall result from checklist
            let computedResult = computeResult(from: checklistItems)

            var photoURLs: [String] = []
            for (index, data) in photoData.enumerated() {
                let path = "inspections/\(id.uuidString)/photo_\(index)_\(UUID().uuidString).jpg"
                let _ = try await SupabaseManager.shared.client.storage
                    .from("safety-photos")
                    .upload(path, data: data)
                    .execute()
                let publicURL = try SupabaseManager.shared.client.storage
                    .from("safety-photos")
                    .getPublicURL(path: path)
                photoURLs.append(publicURL.absoluteString)
            }

            let checklistData = try JSONEncoder().encode(checklistItems)
            let checklistJSON = String(data: checklistData, encoding: .utf8)

            let payload = SupabaseInspectionPayload(
                id: id.uuidString,
                title: title,
                inspector: inspector.isEmpty ? nil : inspector,
                result: computedResult.rawValue,
                date: iso.string(from: date),
                notes: notes.isEmpty ? nil : notes,
                checklistJSON: checklistJSON,
                photoURLs: photoURLs,
                createdAt: iso.string(from: Date())
            )

            let _: SupabaseInspection = try await SupabaseManager.shared.client
                .from("inspections")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

            await fetchInspections()
        } catch {
            errorMessage = "Failed to create inspection: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func deleteInspection(_ inspection: InspectionDisplay) async {
        isLoading = true
        errorMessage = nil
        do {
            let _ = try await SupabaseManager.shared.client
                .from("inspections")
                .delete()
                .eq("id", value: inspection.id.uuidString)
                .execute()
            inspections.removeAll { $0.id == inspection.id }
        } catch {
            errorMessage = "Failed to delete inspection: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Checklist Scoring

    func computeResult(from items: [ChecklistItem]) -> InspectionResult {
        if items.isEmpty { return .pass }
        let hasFail = items.contains { $0.status == .fail }
        let hasConditional = items.contains { $0.status == .conditional }
        if hasFail { return .fail }
        if hasConditional { return .conditional }
        return .pass
    }

    // MARK: - Default Checklist Templates

    static let defaultSafetyChecklist: [ChecklistItem] = [
        ChecklistItem(label: "PPE worn by all workers", status: .notApplicable),
        ChecklistItem(label: "Scaffolding secure and inspected", status: .notApplicable),
        ChecklistItem(label: "Fire extinguishers accessible", status: .notApplicable),
        ChecklistItem(label: "First aid kit stocked and available", status: .notApplicable),
        ChecklistItem(label: "Emergency exits clearly marked", status: .notApplicable),
        ChecklistItem(label: "Electrical cords inspected, no damage", status: .notApplicable),
        ChecklistItem(label: "Fall protection in place above 2m", status: .notApplicable),
        ChecklistItem(label: "Site housekeeping acceptable", status: .notApplicable),
        ChecklistItem(label: "Hazardous materials stored properly", status: .notApplicable),
        ChecklistItem(label: "Toolbox talk conducted this week", status: .notApplicable),
    ]
}

// MARK: - Supabase Types

struct SupabaseIncident: Codable {
    let id: UUID
    let title: String
    let description: String?
    let severity: String
    let status: String
    let reportedBy: String?
    let location: String?
    let date: String
    let photoURLs: [String]?
    let followUpActions: [String]?
    let createdAt: String
    let projectId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, title, description, severity, status
        case reportedBy = "reported_by"
        case location, date
        case photoURLs = "photo_urls"
        case followUpActions = "follow_up_actions"
        case createdAt = "created_at"
        case projectId = "project_id"
    }

    func toDisplay() -> IncidentDisplay {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return IncidentDisplay(
            id: id,
            title: title,
            descriptionText: description ?? "",
            severity: IncidentSeverity(rawValue: severity) ?? .low,
            status: IncidentStatus(rawValue: status) ?? .open,
            reportedBy: reportedBy ?? "",
            location: location ?? "",
            date: iso.date(from: date) ?? Date(),
            createdAt: iso.date(from: createdAt) ?? Date(),
            photoURLs: photoURLs ?? [],
            followUpActions: followUpActions ?? [],
            projectId: projectId
        )
    }
}

struct SupabaseIncidentPayload: Codable {
    let id: String
    let title: String
    let description: String?
    let severity: String
    let status: String
    let reportedBy: String?
    let location: String?
    let date: String
    let photoURLs: [String]?
    let followUpActions: [String]?
    let createdAt: String
    let projectId: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, severity, status
        case reportedBy = "reported_by"
        case location, date
        case photoURLs = "photo_urls"
        case followUpActions = "follow_up_actions"
        case createdAt = "created_at"
        case projectId = "project_id"
    }
}

struct SupabaseInspection: Codable {
    let id: UUID
    let title: String
    let inspector: String?
    let result: String
    let date: String
    let notes: String?
    let checklistJSON: String?
    let photoURLs: [String]?
    let createdAt: String
    let projectId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, title, inspector, result, date, notes
        case checklistJSON = "checklist_json"
        case photoURLs = "photo_urls"
        case createdAt = "created_at"
        case projectId = "project_id"
    }

    func toDisplay() -> InspectionDisplay {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var items: [ChecklistItem] = []
        if let jsonStr = checklistJSON, let data = jsonStr.data(using: .utf8) {
            items = (try? JSONDecoder().decode([ChecklistItem].self, from: data)) ?? []
        }

        return InspectionDisplay(
            id: id,
            title: title,
            inspector: inspector ?? "",
            result: InspectionResult(rawValue: result) ?? .pass,
            date: iso.date(from: date) ?? Date(),
            notes: notes ?? "",
            createdAt: iso.date(from: createdAt) ?? Date(),
            checklistItems: items,
            photoURLs: photoURLs ?? [],
            projectId: projectId
        )
    }
}

struct SupabaseInspectionPayload: Codable {
    let id: String
    let title: String
    let inspector: String?
    let result: String
    let date: String
    let notes: String?
    let checklistJSON: String?
    let photoURLs: [String]?
    let createdAt: String
    let projectId: String?

    enum CodingKeys: String, CodingKey {
        case id, title, inspector, result, date, notes
        case checklistJSON = "checklist_json"
        case photoURLs = "photo_urls"
        case createdAt = "created_at"
        case projectId = "project_id"
    }
}
