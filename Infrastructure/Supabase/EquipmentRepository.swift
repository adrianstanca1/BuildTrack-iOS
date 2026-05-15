import Foundation
import Supabase

// MARK: - Equipment Repository

struct EquipmentRepository {
    static let live = EquipmentRepository(
        fetchAll: {
            let client = SupabaseManager.shared.client
            let response: [SupabaseEquipment] = try await client
                .from("equipment")
                .select()
                .order("updated_at", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        fetchByProject: { projectId in
            let client = SupabaseManager.shared.client
            let response: [SupabaseEquipment] = try await client
                .from("equipment")
                .select()
                .eq("project_id", value: projectId.uuidString)
                .order("updated_at", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        create: { item in
            let client = SupabaseManager.shared.client
            let payload = SupabaseEquipmentPayload(from: item)
            let response: SupabaseEquipment = try await client
                .from("equipment")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
            return response.toDomain()
        },
        update: { item in
            let client = SupabaseManager.shared.client
            let payload = SupabaseEquipmentPayload(from: item)
            let _: SupabaseEquipment = try await client
                .from("equipment")
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
                .from("equipment")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        }
    )

    let fetchAll: () async throws -> [Equipment]
    let fetchByProject: (UUID) async throws -> [Equipment]
    let create: (Equipment) async throws -> Equipment
    let update: (Equipment) async throws -> Void
    let delete: (UUID) async throws -> Void
}

// MARK: - Supabase Payload

struct SupabaseEquipmentPayload: Codable {
    let id: String
    let name: String
    let equipmentType: String
    let make: String
    let model: String
    let serialNumber: String
    let status: String
    let assignedTo: String
    let location: String
    let hoursUsed: Double
    let notes: String
    let cost: Double
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, make, model, status, notes, cost
        case equipmentType = "equipment_type"
        case serialNumber = "serial_number"
        case assignedTo = "assigned_to"
        case location
        case hoursUsed = "hours_used"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from item: Equipment) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.id = item.id.uuidString
        self.name = item.name
        self.equipmentType = item.equipmentType
        self.make = item.make
        self.model = item.model
        self.serialNumber = item.serialNumber
        self.status = item.statusRaw
        self.assignedTo = item.assignedTo
        self.location = item.location
        self.hoursUsed = item.hoursUsed
        self.notes = item.notes
        self.cost = item.cost
        self.createdAt = formatter.string(from: item.createdAt)
        self.updatedAt = formatter.string(from: item.updatedAt)
    }
}
