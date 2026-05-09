import SwiftUI
import OSLog

// MARK: - Admin Projects ViewModel

@MainActor
@Observable
final class AdminProjectsViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([Project])
        case error(String)
    }

    private(set) var state: State = .idle
    private(set) var operationError: String?
    var searchQuery: String = ""
    var selectedStatusFilter: ProjectStatus?

    private let repository: AdminRepository

    init(repository: AdminRepository = .live) {
        self.repository = repository
    }

    var projects: [Project] {
        guard case .loaded(let all) = state else { return [] }
        var result = all
        if let status = selectedStatusFilter {
            result = result.filter { $0.status == status }
        }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.clientName.localizedCaseInsensitiveContains(searchQuery) ||
                $0.locationName.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return result.sorted { $0.updatedAt > $1.updatedAt }
    }

    var totalProjects: Int {
        guard case .loaded(let all) = state else { return 0 }
        return all.count
    }

    var totalBudget: Double {
        guard case .loaded(let all) = state else { return 0 }
        return all.reduce(0) { $0 + $1.budget }
    }

    var totalSpent: Double {
        guard case .loaded(let all) = state else { return 0 }
        return all.reduce(0) { $0 + $1.spentToDate }
    }

    // MARK: - Actions

    func loadProjects() async {
        state = .loading
        do {
            let fetched = try await repository.fetchAllProjectsAdmin()
            state = .loaded(fetched)
        } catch {
            state = .error(mapError(error))
            Logger.admin.error("Failed to load admin projects: \(error)")
        }
    }

    func refresh() async {
        await loadProjects()
    }

    func updateStatus(for project: Project, to status: ProjectStatus) async {
        operationError = nil
        do {
            try await repository.updateProjectStatus(project.id, status)
            await refresh()
        } catch {
            operationError = mapError(error)
            Logger.admin.error("Failed to update project status: \(error)")
        }
    }

    func deleteProject(_ project: Project) async {
        operationError = nil
        do {
            try await repository.deleteProjectAdmin(project.id)
            await refresh()
        } catch {
            operationError = mapError(error)
            Logger.admin.error("Failed to delete project: \(error)")
        }
    }

    // MARK: - Error Mapping

    private func mapError(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case URLError.notConnectedToInternet.rawValue:
            return "No internet connection."
        case URLError.timedOut.rawValue:
            return "Request timed out."
        case 401:
            return "Session expired."
        case 403:
            return "You don't have permission to manage projects."
        case 500...599:
            return "Server error. Please try again later."
        default:
            return error.localizedDescription
        }
    }
}
