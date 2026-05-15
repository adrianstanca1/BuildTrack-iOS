import Foundation
import OSLog
import SwiftData
import Observation

// MARK: - Timesheet ViewModel

@MainActor
@Observable
final class TimesheetViewModel {
    // MARK: - State

    var timesheetsState: LoadingState<[TimesheetEntry]> = .idle
    var operationState: LoadingState<Void> = .idle
    var searchQuery: String = ""
    var activeFilter: TimesheetStatus? = nil

    // MARK: - Dependencies

    private let timesheetRepo: TimesheetRepository
    private let modelContext: ModelContext?

    // MARK: - Init

    init(
        timesheetRepo: TimesheetRepository = .live,
        modelContext: ModelContext? = nil
    ) {
        self.timesheetRepo = timesheetRepo
        self.modelContext = modelContext
    }

    // MARK: - Computed Properties

    var timesheets: [TimesheetEntry] {
        timesheetsState.value ?? []
    }

    var filteredTimesheets: [TimesheetEntry] {
        var result = timesheets
        if let status = activeFilter {
            result = result.filter { $0.status == status }
        }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.workerName.localizedCaseInsensitiveContains(searchQuery)
                    || $0.task.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return result
    }

    var totalHours: Double {
        timesheets.reduce(0) { $0 + $1.hoursWorked }
    }

    var pendingCount: Int {
        timesheets.filter { $0.status == .draft || $0.status == .submitted }.count
    }

    var approvedCount: Int {
        timesheets.filter { $0.status == .approved }.count
    }

    var averageHours: Double {
        guard !timesheets.isEmpty else { return 0 }
        return timesheets.reduce(0) { $0 + $1.hoursWorked } / Double(timesheets.count)
    }

    // MARK: - Load All

    func loadAll() async {
        timesheetsState = .loading
        do {
            let fetched = try await timesheetRepo.fetchAll()
            timesheetsState = .loaded(fetched)
            await syncToLocal(fetched)
        } catch {
            timesheetsState = .error(mapUserFacingError(error))
        }
    }

    // MARK: - Load for Worker

    func loadForWorker(workerName: String) async {
        timesheetsState = .loading
        do {
            let fetched = try await timesheetRepo.fetchByWorker(workerName)
            timesheetsState = .loaded(fetched)
            await syncToLocal(fetched)
        } catch {
            timesheetsState = .error(mapUserFacingError(error))
        }
    }

    // MARK: - Load for Date Range

    func loadForDateRange(start: Date, end: Date) async {
        timesheetsState = .loading
        do {
            let fetched = try await timesheetRepo.fetchByDateRange(start, end)
            timesheetsState = .loaded(fetched)
            await syncToLocal(fetched)
        } catch {
            timesheetsState = .error(mapUserFacingError(error))
        }
    }

    // MARK: - Create

    func create(_ entry: TimesheetEntry) async -> TimesheetEntry? {
        operationState = .loading

        let optimisticId = entry.id

        // Optimistic local update
        insertLocalOptimistic(entry)

        do {
            let created = try await timesheetRepo.create(entry)

            // If the server-assigned id differs, remove optimistic and insert server version
            if created.id != optimisticId {
                removeLocalOptimistic(optimisticId)
                insertLocal(created)
            } else {
                updateLocal(created)
            }

            // Reload to ensure consistency
            await loadAll()
            operationState = .loaded(())
            return created
        } catch {
            // Rollback optimistic
            removeLocalOptimistic(optimisticId)
            operationState = .error(mapUserFacingError(error))
            return nil
        }
    }

    // MARK: - Update

    func update(_ entry: TimesheetEntry) async -> Bool {
        operationState = .loading

        // Snapshot for rollback
        let previousSnapshot = snapshotLocal(entry.id)

        // Optimistic update
        entry.updatedAt = Date()
        updateLocalOptimistic(entry)

        do {
            try await timesheetRepo.update(entry)
            operationState = .loaded(())
            return true
        } catch {
            // Rollback
            if let snap = previousSnapshot {
                rollbackLocal(entry.id, snapshot: snap)
            }
            operationState = .error(mapUserFacingError(error))
            return false
        }
    }

    // MARK: - Delete

    func delete(id: UUID) async -> Bool {
        operationState = .loading

        // Snapshot for rollback
        let snapshot = snapshotLocal(id)

        // Optimistic remove
        removeLocalOptimistic(id)

        do {
            try await timesheetRepo.delete(id)
            operationState = .loaded(())
            return true
        } catch {
            // Rollback
            if let snap = snapshot {
                restoreLocal(snap)
            }
            operationState = .error(mapUserFacingError(error))
            return false
        }
    }

    // MARK: - Search & Filter

    func search(query: String) {
        searchQuery = query
    }

    func filter(by status: TimesheetStatus?) {
        activeFilter = status
    }

    func clearSearch() {
        searchQuery = ""
    }

    func clearFilter() {
        activeFilter = nil
    }

    // MARK: - Reset

    func reset() {
        timesheetsState = .idle
        operationState = .idle
        searchQuery = ""
        activeFilter = nil
    }

    // MARK: - Local Storage Helpers

    private func syncToLocal(_ entries: [TimesheetEntry]) async {
        guard let ctx = modelContext else { return }
        do {
            // Delete stale entries not in the server response
            let serverIds = Set(entries.map(\.id))
            let descriptor = FetchDescriptor<TimesheetEntry>()
            let localEntries = try ctx.fetch(descriptor)
            for local in localEntries where !serverIds.contains(local.id) {
                ctx.delete(local)
            }

            // Upsert
            for entry in entries {
                let pred = #Predicate<TimesheetEntry> { $0.id == entry.id }
                let localDescriptor = FetchDescriptor<TimesheetEntry>(predicate: pred)
                if let existing = try ctx.fetch(localDescriptor).first {
                    existing.workerName = entry.workerName
                    existing.hoursWorked = entry.hoursWorked
                    existing.task = entry.task
                    existing.statusRaw = entry.statusRaw
                    existing.date = entry.date
                    existing.createdAt = entry.createdAt
                    existing.updatedAt = entry.updatedAt
                } else {
                    ctx.insert(entry)
                }
            }
            try ctx.save()
        } catch {
            Logger.timesheets.error("SwiftData sync error: \(error)")
        }
    }

    private func insertLocalOptimistic(_ entry: TimesheetEntry) {
        guard let ctx = modelContext else { return }
        ctx.insert(entry)
        try? ctx.save()
    }

    private func insertLocal(_ entry: TimesheetEntry) {
        guard let ctx = modelContext else { return }
        ctx.insert(entry)
        try? ctx.save()
    }

    private func updateLocal(_ entry: TimesheetEntry) {
        guard let ctx = modelContext else { return }
        try? ctx.save()
    }

    private func updateLocalOptimistic(_ entry: TimesheetEntry) {
        guard let ctx = modelContext else { return }
        try? ctx.save()
    }

    private func removeLocalOptimistic(_ id: UUID) {
        guard let ctx = modelContext else { return }
        let pred = #Predicate<TimesheetEntry> { $0.id == id }
        let descriptor = FetchDescriptor<TimesheetEntry>(predicate: pred)
        if let local = try? ctx.fetch(descriptor).first {
            ctx.delete(local)
            try? ctx.save()
        }
    }

    private func snapshotLocal(_ id: UUID) -> TimesheetEntry? {
        guard let ctx = modelContext else { return nil }
        let pred = #Predicate<TimesheetEntry> { $0.id == id }
        let descriptor = FetchDescriptor<TimesheetEntry>(predicate: pred)
        guard let local = try? ctx.fetch(descriptor).first else { return nil }
        // Deep-copy snapshot
        let snap = TimesheetEntry(
            id: local.id,
            workerName: local.workerName,
            hoursWorked: local.hoursWorked,
            task: local.task,
            status: local.status,
            date: local.date,
            createdAt: local.createdAt,
            updatedAt: local.updatedAt
        )
        return snap
    }

    private func rollbackLocal(_ id: UUID, snapshot: TimesheetEntry) {
        guard let ctx = modelContext else { return }
        let pred = #Predicate<TimesheetEntry> { $0.id == id }
        let descriptor = FetchDescriptor<TimesheetEntry>(predicate: pred)
        if let local = try? ctx.fetch(descriptor).first {
            local.workerName = snapshot.workerName
            local.hoursWorked = snapshot.hoursWorked
            local.task = snapshot.task
            local.statusRaw = snapshot.statusRaw
            local.date = snapshot.date
            local.createdAt = snapshot.createdAt
            local.updatedAt = snapshot.updatedAt
            try? ctx.save()
        }
    }

    private func restoreLocal(_ snapshot: TimesheetEntry) {
        guard let ctx = modelContext else { return }
        ctx.insert(snapshot)
        try? ctx.save()
    }

    // MARK: - Error Mapping

    private func mapUserFacingError(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case URLError.notConnectedToInternet.rawValue, URLError.networkConnectionLost.rawValue:
            return "No internet connection. Changes saved locally and will sync when you're back online."
        case URLError.timedOut.rawValue:
            return "Request timed out. Please try again."
        case 401:
            return "Session expired. Please sign in again."
        case 403:
            return "You don't have permission to perform this action."
        case 409:
            return "A conflict occurred. The data may have been updated by another user."
        case 500...599:
            return "Server error. Our team has been notified. Please try again later."
        default:
            return error.localizedDescription
        }
    }
}

// MARK: - Logger Extension

extension Logger {
    static let timesheets = Logger(subsystem: "com.buildtrack", category: "Timesheets")
}
