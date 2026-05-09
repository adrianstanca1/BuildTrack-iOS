import SwiftUI
import OSLog

// MARK: - Admin Users ViewModel

@MainActor
@Observable
final class AdminUsersViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([AppUser])
        case error(String)
    }

    private(set) var state: State = .idle
    private(set) var operationError: String?
    var searchQuery: String = ""
    var selectedRoleFilter: UserRole?

    private let repository: AdminRepository

    init(repository: AdminRepository = .live) {
        self.repository = repository
    }

    var users: [AppUser] {
        guard case .loaded(let all) = state else { return [] }
        var result = all
        if let role = selectedRoleFilter {
            result = result.filter { $0.role == role }
        }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.email.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return result
    }

    var totalUsers: Int {
        guard case .loaded(let all) = state else { return 0 }
        return all.count
    }

    var activeUsers: Int {
        guard case .loaded(let all) = state else { return 0 }
        return all.filter { $0.isActive }.count
    }

    // MARK: - Actions

    func loadUsers() async {
        state = .loading
        do {
            let fetched = try await repository.fetchAllUsers()
            state = .loaded(fetched)
        } catch {
            state = .error(mapError(error))
            Logger.admin.error("Failed to load users: \(error)")
        }
    }

    func refresh() async {
        await loadUsers()
    }

    func updateRole(for user: AppUser, to role: UserRole) async {
        operationError = nil
        do {
            try await repository.updateUserRole(user.id, role)
            await refresh()
        } catch {
            operationError = mapError(error)
            Logger.admin.error("Failed to update role: \(error)")
        }
    }

    func toggleActive(for user: AppUser) async {
        operationError = nil
        do {
            try await repository.toggleUserActive(user.id, !user.isActive)
            await refresh()
        } catch {
            operationError = mapError(error)
            Logger.admin.error("Failed to toggle user active state: \(error)")
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
            return "You don't have permission to manage users."
        case 500...599:
            return "Server error. Please try again later."
        default:
            return error.localizedDescription
        }
    }
}
