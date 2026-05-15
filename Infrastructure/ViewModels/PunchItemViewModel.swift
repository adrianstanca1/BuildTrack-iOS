import Foundation
import OSLog
import SwiftData
import Observation

// MARK: - PunchItem ViewModel

@MainActor
@Observable
final class PunchItemViewModel {
    var punchItemsState: LoadingState<[PunchItem]> = .idle
    var operationState: LoadingState<Void> = .idle
    var searchQuery: String = ""
    var activeFilter: PunchItemStatus? = nil

    private let repo: PunchItemRepository
    private let modelContext: ModelContext?

    init(
        repo: PunchItemRepository = .live,
        modelContext: ModelContext? = nil
    ) {
        self.repo = repo
        self.modelContext = modelContext
    }

    var punchItems: [PunchItem] {
        punchItemsState.value ?? []
    }

    var filteredItems: [PunchItem] {
        var result = punchItems
        if let status = activeFilter {
            result = result.filter { $0.status == status }
        }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery)
                || $0.location.localizedCaseInsensitiveContains(searchQuery)
                || $0.assignee.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return result
    }

    var openCount: Int { punchItems.filter { $0.status == .open || $0.status == .inProgress }.count }
    var resolvedCount: Int { punchItems.filter { $0.status == .resolved || $0.status == .closed }.count }

    func loadAll() async {
        punchItemsState = .loading
        do {
            let fetched = try await repo.fetchAll()
            punchItemsState = .loaded(fetched)
            await syncToLocal(fetched)
        } catch {
            punchItemsState = .error(mapError(error))
        }
    }

    func loadForProject(_ id: UUID) async {
        punchItemsState = .loading
        do {
            let fetched = try await repo.fetchByProject(id)
            punchItemsState = .loaded(fetched)
            await syncToLocal(fetched)
        } catch {
            punchItemsState = .error(mapError(error))
        }
    }

    func create(_ item: PunchItem) async -> PunchItem? {
        operationState = .loading
        insertLocalOptimistic(item)
        do {
            let created = try await repo.create(item)
            if created.id != item.id {
                removeLocalOptimistic(item.id)
                insertLocal(created)
            } else {
                updateLocal(created)
            }
            await loadAll()
            operationState = .loaded(())
            return created
        } catch {
            removeLocalOptimistic(item.id)
            operationState = .error(mapError(error))
            return nil
        }
    }

    func update(_ item: PunchItem) async -> Bool {
        operationState = .loading
        let snapshot = snapshotLocal(item.id)
        item.updatedAt = Date()
        updateLocalOptimistic(item)
        do {
            try await repo.update(item)
            operationState = .loaded(())
            return true
        } catch {
            if let snap = snapshot { rollbackLocal(item.id, snapshot: snap) }
            operationState = .error(mapError(error))
            return false
        }
    }

    func delete(id: UUID) async -> Bool {
        operationState = .loading
        let snapshot = snapshotLocal(id)
        removeLocalOptimistic(id)
        do {
            try await repo.delete(id)
            operationState = .loaded(())
            return true
        } catch {
            if let snap = snapshot { restoreLocal(snap) }
            operationState = .error(mapError(error))
            return false
        }
    }

    func search(query: String) { searchQuery = query }
    func filter(by status: PunchItemStatus?) { activeFilter = status }
    func clearSearch() { searchQuery = "" }
    func clearFilter() { activeFilter = nil }

    func reset() {
        punchItemsState = .idle; operationState = .idle
        searchQuery = ""; activeFilter = nil
    }

    // MARK: - Local Storage

    private func syncToLocal(_ items: [PunchItem]) async {
        guard let ctx = modelContext else { return }
        do {
            let serverIds = Set(items.map(\.id))
            let local = try ctx.fetch(FetchDescriptor<PunchItem>())
            for l in local where !serverIds.contains(l.id) { ctx.delete(l) }
            for item in items {
                let pred = #Predicate<PunchItem> { $0.id == item.id }
                if let existing = try ctx.fetch(FetchDescriptor<PunchItem>(predicate: pred)).first {
                    existing.title = item.title
                    existing.descriptionText = item.descriptionText
                    existing.statusRaw = item.statusRaw
                    existing.severityRaw = item.severityRaw
                    existing.location = item.location
                    existing.assignee = item.assignee
                    existing.photoUrls = item.photoUrls
                    existing.projectId = item.projectId
                    existing.resolvedAt = item.resolvedAt
                    existing.updatedAt = item.updatedAt
                } else { ctx.insert(item) }
            }
            try ctx.save()
        } catch {
            Logger.punchItems.error("SwiftData sync error: \(error)")
        }
    }

    private func insertLocalOptimistic(_ item: PunchItem) {
        guard let ctx = modelContext else { return }
        ctx.insert(item); try? ctx.save()
    }
    private func insertLocal(_ item: PunchItem) {
        guard let ctx = modelContext else { return }
        ctx.insert(item); try? ctx.save()
    }
    private func updateLocal(_ item: PunchItem) {
        guard let ctx = modelContext else { return }; try? ctx.save()
    }
    private func updateLocalOptimistic(_ item: PunchItem) {
        guard let ctx = modelContext else { return }; try? ctx.save()
    }
    private func removeLocalOptimistic(_ id: UUID) {
        guard let ctx = modelContext else { return }
        let pred = #Predicate<PunchItem> { $0.id == id }
        if let l = try? ctx.fetch(FetchDescriptor<PunchItem>(predicate: pred)).first {
            ctx.delete(l); try? ctx.save()
        }
    }
    private func snapshotLocal(_ id: UUID) -> PunchItem? {
        guard let ctx = modelContext else { return nil }
        let pred = #Predicate<PunchItem> { $0.id == id }
        guard let local = try? ctx.fetch(FetchDescriptor<PunchItem>(predicate: pred)).first else { return nil }
        return PunchItem(id: local.id, title: local.title, descriptionText: local.descriptionText, status: local.status, severity: local.severity, location: local.location, assignee: local.assignee, photoUrls: local.photoUrls, projectId: local.projectId, createdAt: local.createdAt, resolvedAt: local.resolvedAt)
    }
    private func rollbackLocal(_ id: UUID, snapshot: PunchItem) {
        guard let ctx = modelContext else { return }
        let pred = #Predicate<PunchItem> { $0.id == id }
        if let l = try? ctx.fetch(FetchDescriptor<PunchItem>(predicate: pred)).first {
            l.title = snapshot.title; l.descriptionText = snapshot.descriptionText
            l.statusRaw = snapshot.statusRaw; l.severityRaw = snapshot.severityRaw
            l.location = snapshot.location; l.assignee = snapshot.assignee
            l.photoUrls = snapshot.photoUrls; l.projectId = snapshot.projectId
            l.resolvedAt = snapshot.resolvedAt; try? ctx.save()
        }
    }
    private func restoreLocal(_ snapshot: PunchItem) {
        guard let ctx = modelContext else { return }
        ctx.insert(snapshot); try? ctx.save()
    }

    private func mapError(_ error: Error) -> String {
        let ns = error as NSError
        switch ns.code {
        case URLError.notConnectedToInternet.rawValue, URLError.networkConnectionLost.rawValue:
            return "No internet connection. Changes saved locally and will sync when you're back online."
        case 401: return "Session expired. Please sign in again."
        case 403: return "You don't have permission to perform this action."
        case 500...599: return "Server error. Please try again later."
        default: return error.localizedDescription
        }
    }
}

extension Logger {
    static let punchItems = Logger(subsystem: "com.buildtrack", category: "PunchItems")
}
