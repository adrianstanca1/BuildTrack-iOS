import Foundation
import OSLog
import SwiftData
import Observation

@MainActor
@Observable
final class EquipmentViewModel {
    var equipmentState: LoadingState<[Equipment]> = .idle
    var operationState: LoadingState<Void> = .idle
    var searchQuery: String = ""
    var activeFilter: EquipmentStatus? = nil

    private let repo: EquipmentRepository
    private let modelContext: ModelContext?

    init(repo: EquipmentRepository = .live, modelContext: ModelContext? = nil) {
        self.repo = repo
        self.modelContext = modelContext
    }

    var equipment: [Equipment] { equipmentState.value ?? [] }

    var filteredEquipment: [Equipment] {
        var result = equipment
        if let status = activeFilter { result = result.filter { $0.status == status } }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery)
                || $0.make.localizedCaseInsensitiveContains(searchQuery)
                || $0.model.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return result
    }

    var serviceDueCount: Int { equipment.filter { $0.isServiceDue }.count }

    func loadAll() async {
        equipmentState = .loading
        do {
            let fetched = try await repo.fetchAll()
            equipmentState = .loaded(fetched)
            await syncToLocal(fetched)
        } catch { equipmentState = .error(mapError(error)) }
    }

    func create(_ item: Equipment) async -> Equipment? {
        operationState = .loading
        insertLocalOptimistic(item)
        do {
            let created = try await repo.create(item)
            if created.id != item.id { removeLocalOptimistic(item.id); insertLocal(created) }
            else { updateLocal(created) }
            await loadAll(); operationState = .loaded(()); return created
        } catch { removeLocalOptimistic(item.id); operationState = .error(mapError(error)); return nil }
    }

    func update(_ item: Equipment) async -> Bool {
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
    func filter(by status: EquipmentStatus?) { activeFilter = status }
    func clearSearch() { searchQuery = "" }
    func clearFilter() { activeFilter = nil }
    func reset() { equipmentState = .idle; operationState = .idle; searchQuery = ""; activeFilter = nil }

    private func syncToLocal(_ items: [Equipment]) async {
        guard let ctx = modelContext else { return }
        do {
            let sids = Set(items.map(\.id))
            for l in try ctx.fetch(FetchDescriptor<Equipment>()) where !sids.contains(l.id) { ctx.delete(l) }
            for item in items {
                let pred = #Predicate<Equipment> { $0.id == item.id }
                if let ex = try ctx.fetch(FetchDescriptor<Equipment>(predicate: pred)).first {
                    ex.name = item.name; ex.equipmentType = item.equipmentType; ex.make = item.make; ex.model = item.model
                    ex.serialNumber = item.serialNumber; ex.statusRaw = item.statusRaw; ex.assignedTo = item.assignedTo
                    ex.location = item.location; ex.hoursUsed = item.hoursUsed; ex.nextServiceDate = item.nextServiceDate
                    ex.notes = item.notes; ex.cost = item.cost; ex.lastServiceDate = item.lastServiceDate; ex.updatedAt = item.updatedAt
                } else { ctx.insert(item) }
            }
            try ctx.save()
        } catch { Logger.equipment.error("SwiftData sync error: \(error)") }
    }

    private func insertLocalOptimistic(_ item: Equipment) { guard let ctx = modelContext else { return }; ctx.insert(item); try? ctx.save() }
    private func insertLocal(_ item: Equipment) { guard let ctx = modelContext else { return }; ctx.insert(item); try? ctx.save() }
    private func updateLocal(_ item: Equipment) { guard let ctx = modelContext else { return }; try? ctx.save() }
    private func updateLocalOptimistic(_ item: Equipment) { guard let ctx = modelContext else { return }; try? ctx.save() }
    private func removeLocalOptimistic(_ id: UUID) {
        guard let ctx = modelContext else { return }
        let pred = #Predicate<Equipment> { $0.id == id }
        if let l = try? ctx.fetch(FetchDescriptor<Equipment>(predicate: pred)).first { ctx.delete(l); try? ctx.save() }
    }
    private func snapshotLocal(_ id: UUID) -> Equipment? {
        guard let ctx = modelContext else { return nil }
        let pred = #Predicate<Equipment> { $0.id == id }
        guard let local = try? ctx.fetch(FetchDescriptor<Equipment>(predicate: pred)).first else { return nil }
        return Equipment(id: local.id, name: local.name, equipmentType: local.equipmentType, make: local.make, model: local.model, serialNumber: local.serialNumber, status: local.status, assignedTo: local.assignedTo, location: local.location, hoursUsed: local.hoursUsed, nextServiceDate: local.nextServiceDate, notes: local.notes, cost: local.cost, lastServiceDate: local.lastServiceDate, createdAt: local.createdAt, updatedAt: local.updatedAt)
    }
    private func rollbackLocal(_ id: UUID, snapshot: Equipment) {
        guard let ctx = modelContext else { return }
        let pred = #Predicate<Equipment> { $0.id == id }
        if let l = try? ctx.fetch(FetchDescriptor<Equipment>(predicate: pred)).first {
            l.name = snapshot.name; l.equipmentType = snapshot.equipmentType; l.make = snapshot.make; l.model = snapshot.model
            l.serialNumber = snapshot.serialNumber; l.statusRaw = snapshot.statusRaw; l.assignedTo = snapshot.assignedTo
            l.location = snapshot.location; l.hoursUsed = snapshot.hoursUsed; l.nextServiceDate = snapshot.nextServiceDate
            l.notes = snapshot.notes; l.cost = snapshot.cost; l.lastServiceDate = snapshot.lastServiceDate; l.updatedAt = snapshot.updatedAt
            try? ctx.save()
        }
    }
    private func restoreLocal(_ snapshot: Equipment) { guard let ctx = modelContext else { return }; ctx.insert(snapshot); try? ctx.save() }

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
    static let equipment = Logger(subsystem: "com.buildtrack", category: "Equipment")
}
