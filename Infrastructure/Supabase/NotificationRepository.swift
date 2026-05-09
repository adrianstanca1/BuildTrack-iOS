import Foundation
import Supabase

// MARK: - Notification Repository

struct NotificationRepository {
    static let live = NotificationRepository(
        fetchAll: {
            let client = SupabaseManager.shared.client
            let response: [SupabaseNotification] = try await client
                .from("notifications")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        fetchUnread: {
            let client = SupabaseManager.shared.client
            let response: [SupabaseNotification] = try await client
                .from("notifications")
                .select()
                .eq("read", value: false)
                .order("created_at", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        markAsRead: { id in
            let client = SupabaseManager.shared.client
            let _ = try await client
                .from("notifications")
                .update(["read": true])
                .eq("id", value: id.uuidString)
                .execute()
        },
        delete: { id in
            let client = SupabaseManager.shared.client
            let _ = try await client
                .from("notifications")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        },
        clearAll: {
            let client = SupabaseManager.shared.client
            let _ = try await client
                .from("notifications")
                .delete()
                .neq("id", value: "00000000-0000-0000-0000-000000000000")
                .execute()
        }
    )
    
    let fetchAll: () async throws -> [AppNotification]
    let fetchUnread: () async throws -> [AppNotification]
    let markAsRead: (UUID) async throws -> Void
    let delete: (UUID) async throws -> Void
    let clearAll: () async throws -> Void
}
