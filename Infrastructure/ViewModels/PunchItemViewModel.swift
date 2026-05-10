import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class PunchItemViewModel {
    var punchItems: [PunchItem] = []
    var isLoading = false
    var errorMessage: String?

    func fetchPunchItems(context: ModelContext) {
        isLoading = true
        errorMessage = nil
        let descriptor = FetchDescriptor<PunchItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        do {
            punchItems = try context.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createPunchItem(
        title: String,
        description: String,
        severity: PunchItemSeverity,
        location: String,
        assignee: String,
        projectId: UUID?,
        context: ModelContext
    ) {
        let item = PunchItem(
            title: title,
            descriptionText: description,
            severity: severity,
            location: location,
            assignee: assignee,
            projectId: projectId
        )
        context.insert(item)
        try? context.save()
        punchItems.insert(item, at: 0)
    }

    func updateStatus(_ item: PunchItem, to status: PunchItemStatus, context: ModelContext) {
        item.status = status
        if status == .resolved || status == .closed {
            item.resolvedAt = Date()
        }
        try? context.save()
    }

    func deletePunchItem(_ item: PunchItem, context: ModelContext) {
        context.delete(item)
        try? context.save()
        punchItems.removeAll { $0.id == item.id }
    }
}
