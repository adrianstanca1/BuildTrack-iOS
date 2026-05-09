import Foundation
import Supabase

// MARK: - Inspection Repository

protocol InspectionRepositoryProtocol {
    func fetchInspections() async throws -> [Inspection]
    func createInspection(_ inspection: Inspection) async throws
    func updateInspection(_ inspection: Inspection) async throws
    func deleteInspection(id: UUID) async throws
    func fetchInspections(for projectId: UUID) async throws -> [Inspection]
}

final class InspectionRepository: InspectionRepositoryProtocol {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    func fetchInspections() async throws -> [Inspection] {
        let response = try await client
            .from("inspections")
            .select()
            .order("date", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let supabaseInspections = try decoder.decode([SupabaseInspection].self, from: response.data)
        return supabaseInspections.map { $0.toLocalInspection }
    }
    
    func fetchInspections(for projectId: UUID) async throws -> [Inspection] {
        let response = try await client
            .from("inspections")
            .select()
            .eq("project_id", value: projectId.uuidString)
            .order("date", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let supabaseInspections = try decoder.decode([SupabaseInspection].self, from: response.data)
        return supabaseInspections.map { $0.toLocalInspection }
    }
    
    func createInspection(_ inspection: Inspection) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(inspection.toSupabaseInspection())
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        try await client
            .from("inspections")
            .insert(dict)
            .execute()
    }
    
    func updateInspection(_ inspection: Inspection) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(inspection.toSupabaseInspection())
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        try await client
            .from("inspections")
            .update(dict)
            .eq("id", value: inspection.id.uuidString)
            .execute()
    }
    
    func deleteInspection(id: UUID) async throws {
        try await client
            .from("inspections")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Supabase Inspection Model

struct SupabaseInspection: Codable {
    let id: UUID
    let title: String
    let inspector: String?
    let resultRaw: String
    let date: String
    let notes: String?
    let createdAt: String
    let projectId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, title, inspector, notes, date
        case resultRaw = "result"
        case createdAt = "created_at"
        case projectId = "project_id"
    }
    
    var toLocalInspection: Inspection {
        Inspection(
            id: id,
            title: title,
            inspector: inspector ?? "",
            result: InspectionResult(rawValue: resultRaw) ?? .pass,
            date: ISO8601DateFormatter().date(from: date) ?? Date(),
            notes: notes ?? "",
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date()
        )
    }
}

extension Inspection {
    func toSupabaseInspection() -> SupabaseInspection {
        let formatter = ISO8601DateFormatter()
        return SupabaseInspection(
            id: id,
            title: title,
            inspector: inspector,
            resultRaw: resultRaw,
            date: formatter.string(from: date),
            notes: notes,
            createdAt: formatter.string(from: createdAt),
            projectId: nil
        )
    }
}
