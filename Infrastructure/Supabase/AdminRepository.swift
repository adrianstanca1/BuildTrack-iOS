import Foundation
import Supabase
// MARK: - Admin Repository
struct AdminRepository {
    static let live = AdminRepository(
        fetchDashboardStats: {
            let client = SupabaseManager.shared.client
            async let usersResponse: Int = client
                .from("profiles")
                .select("id", head: true)
                .execute()
                .count ?? 0
            
            async let projectsResponse: Int = client
                .from("projects")
                .select("id", head: true)
                .execute()
                .count ?? 0
            
            async let tasksResponse: Int = client
                .from("tasks")
                .select("id", head: true)
                .execute()
                .count ?? 0
            
            async let incidentsResponse: Int = client
                .from("incidents")
                .select("id", head: true)
                .execute()
                .count ?? 0
            
            async let workersResponse: Int = client
                .from("workers")
                .select("id", head: true)
                .execute()
                .count ?? 0
            
            let (totalUsers, totalProjects, totalTasks, totalIncidents, totalWorkers) = try await (
                usersResponse, projectsResponse, tasksResponse, incidentsResponse, workersResponse
            )
            
            return AdminDashboardStats(
                totalUsers: totalUsers,
                activeUsers: totalUsers,
                totalProjects: totalProjects,
                activeProjects: totalProjects,
                completedProjects: 0,
                totalTasks: totalTasks,
                pendingTasks: totalTasks,
                completedTasks: 0,
                openIncidents: totalIncidents,
                resolvedIncidents: 0,
                totalWorkers: totalWorkers,
                totalBudget: 0,
                totalSpent: 0
            )
        },
        fetchAllUsers: {
            let client = SupabaseManager.shared.client
            let response: [SupabaseUserProfile] = try await client
                .from("profiles")
                .select("""
                    id,
                    full_name,
                    email,
                    role,
                    is_active,
                    last_active_at,
                    created_at,
                    project_count:projects(count),
                    task_count:tasks(count)
                """)
                .order("created_at", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        updateUserRole: { userId, role in
            let client = SupabaseManager.shared.client
            let _ = try await client
                .from("profiles")
                .update(["role": role.rawValue])
                .eq("id", value: userId.uuidString)
                .execute()
        },
        toggleUserActive: { userId, isActive in
            let client = SupabaseManager.shared.client
            let _ = try await client
                .from("profiles")
                .update(["is_active": isActive])
                .eq("id", value: userId.uuidString)
                .execute()
        },
        fetchAllProjectsAdmin: {
            let client = SupabaseManager.shared.client
            let response: [SupabaseProject] = try await client
                .from("projects")
                .select("""
                    *,
                    task_count:tasks(count),
                    worker_count:workers(count)
                """)
                .order("updated_at", ascending: false)
                .execute()
                .value
            return response.map { $0.toDomain() }
        },
        updateProjectStatus: { projectId, status in
            let client = SupabaseManager.shared.client
            let _ = try await client
                .from("projects")
                .update(["status": status.rawValueForSupabase])
                .eq("id", value: projectId.uuidString)
                .execute()
        },
        deleteProjectAdmin: { projectId in
            let client = SupabaseManager.shared.client
            let _ = try await client
                .from("projects")
                .delete()
                .eq("id", value: projectId.uuidString)
                .execute()
        },
        fetchSubscription: {
            return SubscriptionTier.professional
        },
        updateSubscription: { _ in
            // Placeholder for Stripe/Billing integration
        }
    )
    
    let fetchDashboardStats: () async throws -> AdminDashboardStats
    let fetchAllUsers: () async throws -> [AppUser]
    let updateUserRole: (UUID, UserRole) async throws -> Void
    let toggleUserActive: (UUID, Bool) async throws -> Void
    let fetchAllProjectsAdmin: () async throws -> [Project]
    let updateProjectStatus: (UUID, ProjectStatus) async throws -> Void
    let deleteProjectAdmin: (UUID) async throws -> Void
    let fetchSubscription: () async throws -> SubscriptionTier
    let updateSubscription: (String) async throws -> Void
}
// MARK: - Supabase User Profile
struct SupabaseUserProfile: Codable {
    let id: UUID
    let fullName: String?
    let email: String?
    let role: String?
    let isActive: Bool?
    let lastActiveAt: String?
    let createdAt: String?
    let projectCount: Int?
    let taskCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
        case role
        case isActive = "is_active"
        case lastActiveAt = "last_active_at"
        case createdAt = "created_at"
        case projectCount = "project_count"
        case taskCount = "task_count"
    }
    
    func toDomain() -> AppUser {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return AppUser(
            id: id,
            name: fullName ?? email ?? "Unknown",
            email: email ?? "",
            role: UserRole(rawValue: role ?? "worker") ?? .worker,
            isActive: isActive ?? true,
            lastActiveAt: lastActiveAt.flatMap { formatter.date(from: $0) },
            createdAt: formatter.date(from: createdAt ?? "") ?? Date(),
            projectCount: projectCount ?? 0,
            taskCount: taskCount ?? 0
        )
    }
}
