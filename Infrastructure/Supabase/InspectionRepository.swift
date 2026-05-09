import Foundation
import Supabase

// MARK: - Inspection Repository

struct InspectionRepository {
    static let live = InspectionRepository(
        fetchAll: {
            let client = SupabaseManager.shared.client
            let response: [SupabaseInspection] = try await client
                .from("inspections")
                .select()
                .order("inspection_date", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        fetchByProject: { projectId in
            let client = SupabaseManager.shared.client
            let response: [SupabaseInspection] = try await client
                .from("inspections")
                .select()
                .eq("project_id", value: projectId.uuidString)
                .order("inspection_date", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        create: { inspection in
            let client = SupabaseManager.shared.client
            let payload = SupabaseInspectionPayload(from: inspection)
            let response: SupabaseInspection = try await client
                .from("inspections")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
            return response.toDomain()
        },
        update: { inspection in
            let client = SupabaseManager.shared.client
            let payload = SupabaseInspectionPayload(from: inspection)
            let _: SupabaseInspection = try await client
                .from("inspections")
                .update(payload)
                .eq("id", value: inspection.id.uuidString)
                .select()
                .single()
                .execute()
                .value
        },
        delete: { id in
            let client = SupabaseManager.shared.client
            let _ = try await client
                .from("inspections")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        }
    )
    
    let fetchAll: () async throws -> [Inspection]
    let fetchByProject: (UUID) async throws -> [Inspection]
    let create: (Inspection) async throws -> Inspection
    let update: (Inspection) async throws -> Void
    let delete: (UUID) async throws -> Void
}

// MARK: - Inspection Payload

struct SupabaseInspectionPayload: Codable {
    let id: String
    let title: String
    let description: String?
    let status: String
    let projectId: String?
    let inspector: String?
    let inspectionDate: String
    let findings: [String]?
    let photos: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, status, inspector, findings, photos
        case projectId = "project_id"
        case inspectionDate = "inspection_date"
    }
    
    init(from inspection: Inspection) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let statusString: String = {
            switch inspection.result {
            case .pass: return "passed"
            case .fail: return "failed"
            case .conditional: return "pending"
            }
        }()
        
        self.id = inspection.id.uuidString
        self.title = inspection.title
        self.description = inspection.notes.isEmpty ? nil : inspection.notes
        self.status = statusString
        self.projectId = nil
        self.inspector = inspection.inspector.isEmpty ? nil : inspection.inspector
        self.inspectionDate = formatter.string(from: inspection.date)
        self.findings = nil
        self.photos = nil
    }
}
