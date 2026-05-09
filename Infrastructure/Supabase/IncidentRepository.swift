import Foundation
import Supabase

// MARK: - Incident Repository

struct IncidentRepository {
    static let live = IncidentRepository(
        fetchAll: {
            let client = SupabaseManager.shared.client
            let response: [SupabaseIncident] = try await client
                .from("incidents")
                .select()
                .order("incident_date", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        fetchByProject: { projectId in
            let client = SupabaseManager.shared.client
            let response: [SupabaseIncident] = try await client
                .from("incidents")
                .select()
                .eq("project_id", value: projectId.uuidString)
                .order("incident_date", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        create: { incident in
            let client = SupabaseManager.shared.client
            let payload = SupabaseIncidentPayload(from: incident)
            let response: SupabaseIncident = try await client
                .from("incidents")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
            return response.toDomain()
        },
        update: { incident in
            let client = SupabaseManager.shared.client
            let payload = SupabaseIncidentPayload(from: incident)
            let _: SupabaseIncident = try await client
                .from("incidents")
                .update(payload)
                .eq("id", value: incident.id.uuidString)
                .select()
                .single()
                .execute()
                .value
        },
        delete: { id in
            let client = SupabaseManager.shared.client
            let _ = try await client
                .from("incidents")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        }
    )
    
    let fetchAll: () async throws -> [Incident]
    let fetchByProject: (UUID) async throws -> [Incident]
    let create: (Incident) async throws -> Incident
    let update: (Incident) async throws -> Void
    let delete: (UUID) async throws -> Void
}

// MARK: - Incident Payload

struct SupabaseIncidentPayload: Codable {
    let id: String
    let title: String
    let description: String?
    let severity: String
    let projectId: String?
    let reportedBy: String?
    let incidentDate: String
    let injuries: Int?
    let photos: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, severity, injuries, photos
        case projectId = "project_id"
        case reportedBy = "reported_by"
        case incidentDate = "incident_date"
    }
    
    init(from incident: Incident) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        self.id = incident.id.uuidString
        self.title = incident.title
        self.description = incident.descriptionText.isEmpty ? nil : incident.descriptionText
        self.severity = incident.severityRaw
        self.projectId = incident.project?.id.uuidString
        self.reportedBy = incident.reportedBy.isEmpty ? nil : incident.reportedBy
        self.incidentDate = formatter.string(from: incident.date)
        self.injuries = 0
        self.photos = nil
    }
}
