import Foundation
import Supabase

// MARK: - PunchItem Repository

struct PunchItemRepository {
    static let live = PunchItemRepository(
        fetchAll: {
            let client = SupabaseManager.shared.client
            let response: [SupabasePunchItem] = try await client
                .from("punch_items")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        fetchByProject: { projectId in
            let client = SupabaseManager.shared.client
            let response: [SupabasePunchItem] = try await client
                .from("punch_items")
                .select()
                .eq("project_id", value: projectId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        create: { item in
            let client = SupabaseManager.shared.client
            let payload = SupabasePunchItemPayload(from: item)
            let response: SupabasePunchItem = try await client
                .from("punch_items")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
            return response.toDomain()
        },
        update: { item in
            let client = SupabaseManager.shared.client
            let payload = SupabasePunchItemPayload(from: item)
            let _: SupabasePunchItem = try await client
                .from("punch_items")
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
                .from("punch_items")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        }
    )

    let fetchAll: () async throws -> [PunchItem]
    let fetchByProject: (UUID) async throws -> [PunchItem]
    let create: (PunchItem) async throws -> PunchItem
    let update: (PunchItem) async throws -> Void
    let delete: (UUID) async throws -> Void
}

// MARK: - SupabasePayload

struct SupabasePunchItemPayload: Codable {
    let id: String
    let title: String
    let description: String?
    let status: String
    let severity: String
    let location: String
    let assignee: String
    let projectId: String?
    let resolvedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, status, severity, location, assignee
        case projectId = "project_id"
        case resolvedAt = "resolved_at"
    }

    init(from item: PunchItem) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.id = item.id.uuidString
        self.title = item.title
        self.description = item.descriptionText.isEmpty ? nil : item.descriptionText
        self.status = item.statusRaw
        self.severity = item.severityRaw
        self.location = item.location
        self.assignee = item.assignee
        self.projectId = item.projectId?.uuidString
        self.resolvedAt = item.resolvedAt.map { formatter.string(from: $0) }
    }
}
