import SwiftUI
import OSLog

// MARK: - Admin Dashboard ViewModel

@MainActor
@Observable
final class AdminDashboardViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(AdminDashboardStats)
        case error(String)
    }
    
    private(set) var state: State = .idle
    private let repository: AdminRepository
    
    init(repository: AdminRepository = .live) {
        self.repository = repository
    }
    
    var stats: AdminDashboardStats? {
        if case .loaded(let s) = state { return s }
        return nil
    }
    
    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let msg) = state { return msg }
        return nil
    }
    
    // MARK: - Actions
    
    func loadStats() async {
        state = .loading
        do {
            let fetched = try await repository.fetchDashboardStats()
            state = .loaded(fetched)
        } catch {
            state = .error(mapError(error))
            Logger.admin.error("Failed to load admin stats: \(error)")
        }
    }
    
    func refresh() async {
        await loadStats()
    }
    
    // MARK: - Computed Helpers
    
    var budgetUtilisation: Double {
        guard let stats, stats.totalBudget > 0 else { return 0 }
        return (stats.totalSpent / stats.totalBudget) * 100
    }
    
    var projectCompletionRate: Double {
        guard let stats, stats.totalProjects > 0 else { return 0 }
        return (Double(stats.completedProjects) / Double(stats.totalProjects)) * 100
    }
    
    var taskCompletionRate: Double {
        guard let stats, stats.totalTasks > 0 else { return 0 }
        return (Double(stats.completedTasks) / Double(stats.totalTasks)) * 100
    }
    
    var incidentResolutionRate: Double {
        guard let stats, stats.openIncidents + stats.resolvedIncidents > 0 else { return 0 }
        return (Double(stats.resolvedIncidents) / Double(stats.openIncidents + stats.resolvedIncidents)) * 100
    }
    
    // MARK: - Error Mapping
    
    private func mapError(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case URLError.notConnectedToInternet.rawValue:
            return "No internet connection. Please check your network and try again."
        case URLError.timedOut.rawValue:
            return "Request timed out. Please try again."
        case 401:
            return "Session expired. Please sign in again."
        case 403:
            return "You don't have permission to access admin data."
        case 500...599:
            return "Server error. Please try again later."
        default:
            return error.localizedDescription
        }
    }
}

// MARK: - Logger Extension

