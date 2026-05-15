import Foundation
import OSLog
import SwiftData
import Observation

@MainActor
@Observable
final class MaterialViewModel {
    var materialsState: LoadingState<[Material]> = .idle
    var operationState: LoadingState<Void> = .idle
    var searchQuery: String = ""
    var activeFilter: MaterialStatus? = nil

    private let repo: MaterialRepository
    private let modelContext: ModelContext?

    init(repo: MaterialRepository = .live, modelContext: ModelContext? = nil) {
        self.repo = repo
        self.modelContext = modelContext
    }

    var materials: [Material] { materialsState.value ?? [] }

    var filteredMaterials: [Material] {
        var result = materials
        if let status = activeFilter { result = result.filter { $0.status == status } }
        if !searchQuery.isEmpty { result = result.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) || $0.category.localizedCaseInsensitiveContains(searchQuery) } }
        return result
    }

    func loadAll() async {
        materialsState = .loading
        do {
            let fetched = try await repo.fetchAll()
            materialsState = .loaded(fetched)
            await syncToLocal(fetched)
        } catch { materialsState = .error(mapError(error)) }
    }

    func create(_ item: Material) async -> Material? {
        operationState = .loading
        insertLocalOptimistic(item)
        do {
            let created = try await repo.create(item)
            if created.id != item.id { removeLocalOptimistic(item.id); insertLocal(created) } else { updateLocal(created) }
            await loadAll(); operationState = .loaded(()); return created
        } catch { removeLocalOptimistic(item.id); operationState = .error(mapError(error)); return nil }
    }

    func update(_ item: Material) async -> Bool {
        operationState = .loading
        let snapshot = snapshotLocal(item.id)
        item.updatedAt = Date(); updateLocalOptimistic(item)
        do {
            try await repo.update(item); operationState = .loaded(()); return true
        } catch {
            if let snap = snapshot { rollbackLocal(item.id, snapshot: snap) }
            operationState = .error(mapError(error)); return false
        }
    }

    func delete(id: UUID) async -> Bool {
        operationState = .loading
        let snapshot = snapshotLocal(id); removeLocalOptimistic(id)
        do {
            try await repo.delete(id); operationState = .loaded(()); return true
        } catch {
            if let snap = snapshot { restoreLocal(snap) }
            operationState = .error(mapError(error)); return false
        }
    }

    func search(query: String) { searchQuery = query }
    func filter(by status: MaterialStatus?) { activeFilter = status }
    func clearSearch() { searchQuery = "" }
    func clearFilter() { activeFilter = nil }
    func reset() { materialsState = .idle; operationState = .idle; searchQuery = ""; activeFilter = nil }

    private func syncToLocal(_ items: [Material]) async {
        guard let ctx = modelContext else { return }
        do {
            let sids = Set(items.map(\.id))
            for l in try ctx.fetch(FetchDescriptor<Material>()) where !sids.contains(l.id) { ctx.delete(l) }
            for item in items {
                let pred = #Predicate<Material> { $0.id == item.id }
                if let ex = try ctx.fetch(FetchDescriptor<Material>(predicate: pred)).first {
                    ex.name = item.name; ex.category = item.category; ex.quantity = item.quantity; ex.unit = item.unit
                    ex.statusRaw = item.statusRaw; ex.updatedAt = item.updatedAt
                } else { ctx.insert(item) }
            }
            try ctx.save()
        } catch { Logger.materials.error("SwiftData sync error: \(error)") }
    }

    private func insertLocalOptimistic(_ item: Material) { guard let ctx = modelContext else { return }; ctx.insert(item); try? ctx.save() }
    private func insertLocal(_ item: Material) { guard let ctx = modelContext else { return }; ctx.insert(item); try? ctx.save() }
    private func updateLocal(_ item: Material) { guard let ctx = modelContext else { return }; try? ctx.save() }
    private func updateLocalOptimistic(_ item: Material) { guard let ctx = modelContext else { return }; try? ctx.save() }
    private func removeLocalOptimistic(_ id: UUID) {
        guard let ctx = modelContext else { return }
        let pred = #Predicate<Material> { $0.id == id }
        if let l = try? ctx.fetch(FetchDescriptor<Material>(predicate: pred)).first { ctx.delete(l); try? ctx.save() }
    }
    private func snapshotLocal(_ id: UUID) -> Material? {
        guard let ctx = modelContext else { return nil }
        let pred = #Predicate<Material> { $0.id == id }
        guard let local = try? ctx.fetch(FetchDescriptor<Material>(predicate: pred)).first else { return nil }
        return Material(id: local.id, name: local.name, category: local.category, quantity: local.quantity, unit: local.unit, status: local.status, createdAt: local.createdAt, updatedAt: local.updatedAt)
    }
    private func rollbackLocal(_ id: UUID, snapshot: Material) {
        guard let ctx = modelContext else { return }
        let pred = #Predicate<Material> { $0.id == id }
        if let l = try? ctx.fetch(FetchDescriptor<Material>(predicate: pred)).first {
            l.name = snapshot.name; l.category = snapshot.category; l.quantity = snapshot.quantity; l.unit = snapshot.unit
            l.statusRaw = snapshot.statusRaw; try? ctx.save()
        }
    }
    private func restoreLocal(_ snapshot: Material) { guard let ctx = modelContext else { return }; ctx.insert(snapshot); try? ctx.save() }

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
    static let materials = Logger(subsystem: "com.buildtrack", category: "Materials")
}
