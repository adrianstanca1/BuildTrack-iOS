import Foundation
import Supabase

// MARK: - Worker Repository

struct WorkerRepository {
    static let live = WorkerRepository(
        fetchAll: {
            let client = SupabaseManager.shared.client
            let response: [SupabaseWorker] = try await client
                .from("workers")
                .select()
                .order("name", ascending: true)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        fetchActive: {
            let client = SupabaseManager.shared.client
            let response: [SupabaseWorker] = try await client
                .from("workers")
                .select()
                .eq("status", value: "active")
                .order("name", ascending: true)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        create: { worker in
            let client = SupabaseManager.shared.client
            let payload = SupabaseWorkerPayload(from: worker)
            let response: SupabaseWorker = try await client
                .from("workers")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
            return response.toDomain()
        },
        update: { worker in
            let client = SupabaseManager.shared.client
            let payload = SupabaseWorkerPayload(from: worker)
            let _: SupabaseWorker = try await client
                .from("workers")
                .update(payload)
                .eq("id", value: worker.id.uuidString)
                .select()
                .single()
                .execute()
                .value
        },
        delete: { id in
            let client = SupabaseManager.shared.client
            let _ = try await client
                .from("workers")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        }
    )
    
    let fetchAll: () async throws -> [Worker]
    let fetchActive: () async throws -> [Worker]
    let create: (Worker) async throws -> Worker
    let update: (Worker) async throws -> Void
    let delete: (UUID) async throws -> Void
}

// MARK: - Worker Payload

struct SupabaseWorkerPayload: Codable {
    let id: String
    let name: String
    let role: String
    let status: String
    let phone: String?
    let email: String?
    let certifications: [String]?
    let hourlyRate: Double?
    let weeklyHours: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, role, status, phone, email, certifications
        case hourlyRate = "hourly_rate"
        case weeklyHours = "weekly_hours"
    }
    
    init(from worker: Worker) {
        self.id = worker.id.uuidString
        self.name = worker.name
        self.role = worker.role.rawValueForSupabase
        self.status = worker.isActive ? "active" : "off-duty"
        self.phone = worker.phone.isEmpty ? nil : worker.phone
        self.email = worker.email.isEmpty ? nil : worker.email
        self.certifications = worker.certifications.isEmpty ? nil : worker.certifications
        self.hourlyRate = nil
        self.weeklyHours = nil
    }
}
