import Foundation
import Supabase

// MARK: - Incident Repository

protocol IncidentRepositoryProtocol {
    func fetchIncidents() async throws -> [Incident]
    func createIncident(_ incident: Incident) async throws
    func updateIncident(_ incident: Incident) async throws
    func deleteIncident(id: UUID) async throws
    func fetchIncidents(for projectId: UUID) async throws -> [Incident]
}

final class IncidentRepository: IncidentRepositoryProtocol {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    func fetchIncidents() async throws -> [Incident] {
        let response = try await client
            .from("safety_incidents")
            .select()
            .order("created_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let supabaseIncidents = try decoder.decode([SupabaseIncident].self, from: response.data)
        return supabaseIncidents.map { $0.toLocalIncident }
    }
    
    func fetchIncidents(for projectId: UUID) async throws -> [Incident] {
        let response = try await client
            .from("safety_incidents")
            .select()
            .eq("project_id", value: projectId.uuidString)
            .order("created_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let supabaseIncidents = try decoder.decode([SupabaseIncident].self, from: response.data)
        return supabaseIncidents.map { $0.toLocalIncident }
    }
    
    func createIncident(_ incident: Incident) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(incident.toSupabaseIncident())
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        try await client
            .from("safety_incidents")
            .insert(dict)
            .execute()
    }
    
    func updateIncident(_ incident: Incident) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(incident.toSupabaseIncident())
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        try await client
            .from("safety_incidents")
            .update(dict)
            .eq("id", value: incident.id.uuidString)
            .execute()
    }
    
    func deleteIncident(id: UUID) async throws {
        try await client
            .from("safety_incidents")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Supabase Incident Model

struct SupabaseIncident: Codable {
    let id: UUID
    let title: String
    let descriptionText: String?
    let severityRaw: String
    let statusRaw: String
    let reportedBy: String?
    let location: String?
    let date: String
    let createdAt: String
    let projectId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, title, severityRaw = "severity", statusRaw = "status"
        case descriptionText = "description"
        case reportedBy = "reported_by"
        case location, date
        case createdAt = "created_at"
        case projectId = "project_id"
    }
    
    var toLocalIncident: Incident {
        Incident(
            id: id,
            title: title,
            descriptionText: descriptionText ?? "",
            severity: IncidentSeverity(rawValue: severityRaw) ?? .low,
            incidentStatus: IncidentStatus(rawValue: statusRaw) ?? .open,
            reportedBy: reportedBy ?? "",
            location: location ?? "",
            date: ISO8601DateFormatter().date(from: date) ?? Date(),
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date()
        )
    }
}

extension Incident {
    func toSupabaseIncident() -> SupabaseIncident {
        let formatter = ISO8601DateFormatter()
        return SupabaseIncident(
            id: id,
            title: title,
            descriptionText: descriptionText,
            severityRaw: severityRaw,
            statusRaw: statusRaw,
            reportedBy: reportedBy,
            location: location,
            date: formatter.string(from: date),
            createdAt: formatter.string(from: createdAt),
            projectId: project?.id
        )
    }
}
