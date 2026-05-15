import Foundation
import Supabase

// MARK: - Material Repository

struct MaterialRepository {
    static let live = MaterialRepository(
        fetchAll: {
            let client = SupabaseManager.shared.client
            let response: [SupabaseMaterial] = try await client
                .from("materials")
                .select()
                .order("updated_at", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        fetchByProject: { projectId in
            let client = SupabaseManager.shared.client
            let response: [SupabaseMaterial] = try await client
                .from("materials")
                .select()
                .eq("project_id", value: projectId.uuidString)
                .order("updated_at", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        create: { item in
            let client = SupabaseManager.shared.client
            let payload = SupabaseMaterialPayload(from: item)
            let response: SupabaseMaterial = try await client
                .from("materials")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
            return response.toDomain()
        },
        update: { item in
            let client = SupabaseManager.shared.client
            let payload = SupabaseMaterialPayload(from: item)
            let _: SupabaseMaterial = try await client
                .from("materials")
                .update(payload)
                .eq("id", value: item.id.uuidString)
                .select()
                .single()
                .execute()
                .value
        },
        delete: { id in
            let client = SupabaseManager.shared.client
            let _ = try await client
                .from("materials")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        }
    )

    let fetchAll: () async throws -> [Material]
    let fetchByProject: (UUID) async throws -> [Material]
    let create: (Material) async throws -> Material
    let update: (Material) async throws -> Void
    let delete: (UUID) async throws -> Void
}

// MARK: - Supabase Payload

struct SupabaseMaterialPayload: Codable {
    let id: String
    let name: String
    let category: String
    let quantity: Double
    let unit: String
    let status: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, category, quantity, unit, status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from item: Material) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.id = item.id.uuidString
        self.name = item.name
        self.category = item.category
        self.quantity = item.quantity
        self.unit = item.unit
        self.status = item.statusRaw
        self.createdAt = formatter.string(from: item.createdAt)
        self.updatedAt = formatter.string(from: item.updatedAt)
    }
}
