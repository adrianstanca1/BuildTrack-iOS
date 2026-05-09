import Foundation
import Supabase

// MARK: - User Role

enum UserRole: String, CaseIterable, Codable, Sendable, Identifiable {
    case admin, manager, supervisor, worker, viewer
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .admin: return "Administrator"
        case .manager: return "Project Manager"
        case .supervisor: return "Site Supervisor"
        case .worker: return "Worker"
        case .viewer: return "Viewer"
        }
    }
    
    var icon: String {
        switch self {
        case .admin: return "shield.lefthalf.fill"
        case .manager: return "briefcase.fill"
        case .supervisor: return "person.fill.checkmark"
        case .worker: return "helmet.fill"
        case .viewer: return "eye.fill"
        }
    }
    
    var canAccessAdmin: Bool {
        self == .admin || self == .manager
    }
    
    var canManageUsers: Bool {
        self == .admin
    }
    
    var canManageBilling: Bool {
        self == .admin
    }
}

// MARK: - Subscription Tier

struct SubscriptionTier: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let monthlyPrice: Double
    let annualPrice: Double
    let maxProjects: Int
    let maxUsers: Int
    let features: [String]
    let isCurrent: Bool
    
    static let starter = SubscriptionTier(
        id: "starter",
        name: "Starter",
        monthlyPrice: 29.99,
        annualPrice: 299.99,
        maxProjects: 3,
        maxUsers: 5,
        features: ["3 Projects", "5 Team Members", "Basic Reporting", "Email Support"],
        isCurrent: false
    )
    
    static let professional = SubscriptionTier(
        id: "professional",
        name: "Professional",
        monthlyPrice: 99.99,
        annualPrice: 999.99,
        maxProjects: 15,
        maxUsers: 25,
        features: ["15 Projects", "25 Team Members", "Advanced Reporting", "Safety Modules", "Priority Support"],
        isCurrent: true
    )
    
    static let enterprise = SubscriptionTier(
        id: "enterprise",
        name: "Enterprise",
        monthlyPrice: 299.99,
        annualPrice: 2999.99,
        maxProjects: -1,
        maxUsers: -1,
        features: ["Unlimited Projects", "Unlimited Users", "Custom Integrations", "Dedicated Account Manager", "SLA Guarantee"],
        isCurrent: false
    )
}

// MARK: - App User (Admin user list)

struct AppUser: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var email: String
    var role: UserRole
    var isActive: Bool
    var lastActiveAt: Date?
    var createdAt: Date
    var projectCount: Int
    var taskCount: Int
}

// MARK: - Admin Dashboard Stats

struct AdminDashboardStats: Codable, Sendable {
    let totalUsers: Int
    let activeUsers: Int
    let totalProjects: Int
    let activeProjects: Int
    let completedProjects: Int
    let totalTasks: Int
    let pendingTasks: Int
    let completedTasks: Int
    let openIncidents: Int
    let resolvedIncidents: Int
    let totalWorkers: Int
    let totalBudget: Double
    let totalSpent: Double
}
