import Foundation
import Supabase

// MARK: - Notification Repository

protocol NotificationRepositoryProtocol {
    func fetchNotifications() async throws -> [AppNotification]
    func markAsRead(id: UUID) async throws
    func deleteNotification(id: UUID) async throws
    func createNotification(_ notification: AppNotification) async throws
    func getUnreadCount() async throws -> Int
}

final class NotificationRepository: NotificationRepositoryProtocol {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    func fetchNotifications() async throws -> [AppNotification] {
        let response = try await client
            .from("notifications")
            .select()
            .order("created_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let supabaseNotifications = try decoder.decode([SupabaseNotification].self, from: response.data)
        return supabaseNotifications.map { $0.toLocalNotification }
    }
    
    func markAsRead(id: UUID) async throws {
        try await client
            .from("notifications")
            .update(["is_read": true])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    func deleteNotification(id: UUID) async throws {
        try await client
            .from("notifications")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    func createNotification(_ notification: AppNotification) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(notification.toSupabaseNotification())
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        try await client
            .from("notifications")
            .insert(dict)
            .execute()
    }
    
    func getUnreadCount() async throws -> Int {
        let response = try await client
            .from("notifications")
            .select("*", head: true, count: .exact)
            .eq("is_read", value: false)
            .execute()
        
        return response.count ?? 0
    }
}

// MARK: - Supabase Notification Model

struct SupabaseNotification: Codable {
    let id: UUID
    let title: String
    let body: String?
    let typeRaw: String?
    let isRead: Bool?
    let createdAt: String
    let relatedId: String?
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, body
        case typeRaw = "type"
        case isRead = "is_read"
        case createdAt = "created_at"
        case relatedId = "related_id"
        case userId = "user_id"
    }
    
    var toLocalNotification: AppNotification {
        AppNotification(
            id: id,
            title: title,
            body: body ?? "",
            type: NotificationType(rawValue: typeRaw ?? "info") ?? .info,
            isRead: isRead ?? false,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            relatedId: relatedId
        )
    }
}

extension AppNotification {
    func toSupabaseNotification() -> SupabaseNotification {
        let formatter = ISO8601DateFormatter()
        return SupabaseNotification(
            id: id,
            title: title,
            body: body,
            typeRaw: type.rawValue,
            isRead: isRead,
            createdAt: formatter.string(from: createdAt),
            relatedId: relatedId,
            userId: nil
        )
    }
}
