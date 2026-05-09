import Foundation
import Supabase

// MARK: - Worker Repository

protocol WorkerRepositoryProtocol {
    func fetchWorkers() async throws -> [Worker]
    func createWorker(_ worker: Worker) async throws
    func updateWorker(_ worker: Worker) async throws
    func deleteWorker(id: UUID) async throws
    func fetchWorkers(for projectId: UUID) async throws -> [Worker]
}

final class WorkerRepository: WorkerRepositoryProtocol {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    func fetchWorkers() async throws -> [Worker] {
        let response = try await client
            .from("workers")
            .select()
            .order("created_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let supabaseWorkers = try decoder.decode([SupabaseWorker].self, from: response.data)
        return supabaseWorkers.map { $0.toLocalWorker }
    }
    
    func fetchWorkers(for projectId: UUID) async throws -> [Worker] {
        let response = try await client
            .from("workers")
            .select()
            .eq("project_id", value: projectId.uuidString)
            .order("created_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let supabaseWorkers = try decoder.decode([SupabaseWorker].self, from: response.data)
        return supabaseWorkers.map { $0.toLocalWorker }
    }
    
    func createWorker(_ worker: Worker) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(worker.toSupabaseWorker())
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        try await client
            .from("workers")
            .insert(dict)
            .execute()
    }
    
    func updateWorker(_ worker: Worker) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(worker.toSupabaseWorker())
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        try await client
            .from("workers")
            .update(dict)
            .eq("id", value: worker.id.uuidString)
            .execute()
    }
    
    func deleteWorker(id: UUID) async throws {
        try await client
            .from("workers")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Supabase Worker Model

struct SupabaseWorker: Codable {
    let id: UUID
    let name: String
    let roleRaw: String
    let phone: String?
    let email: String?
    let certifications: [String]?
    let isActive: Bool?
    let createdAt: String
    let projectId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, name, phone, email, certifications
        case roleRaw = "role"
        case isActive = "is_active"
        case createdAt = "created_at"
        case projectId = "project_id"
    }
    
    var toLocalWorker: Worker {
        Worker(
            id: id,
            name: name,
            role: WorkerRole(supabaseValue: roleRaw) ?? .labourer,
            phone: phone ?? "",
            email: email ?? "",
            certifications: certifications ?? [],
            isActive: isActive ?? true,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date()
        )
    }
}

extension Worker {
    func toSupabaseWorker() -> SupabaseWorker {
        let formatter = ISO8601DateFormatter()
        return SupabaseWorker(
            id: id,
            name: name,
            roleRaw: role.supabaseValue,
            phone: phone,
            email: email,
            certifications: certifications,
            isActive: isActive,
            createdAt: formatter.string(from: createdAt),
            projectId: nil
        )
    }
}
