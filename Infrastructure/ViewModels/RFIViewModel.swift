import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class RFIViewModel {
    var rfis: [RFI] = []
    var isLoading = false
    var errorMessage: String?

    func fetchRFIs(context: ModelContext) {
        isLoading = true
        errorMessage = nil
        let descriptor = FetchDescriptor<RFI>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        do {
            rfis = try context.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createRFI(
        title: String,
        description: String,
        priority: RFIPriority,
        assignedTo: String,
        projectId: UUID?,
        context: ModelContext
    ) {
        let item = RFI(
            title: title,
            descriptionText: description,
            priority: priority,
            assignedTo: assignedTo,
            projectId: projectId
        )
        context.insert(item)
        try? context.save()
        rfis.insert(item, at: 0)
    }

    func updateStatus(_ item: RFI, to status: RFIStatus, context: ModelContext) {
        item.status = status
        if status == .approved || status == .rejected || status == .closed {
            item.respondedAt = Date()
        }
        try? context.save()
    }

    func addResponse(_ item: RFI, response: String, context: ModelContext) {
        item.response = response
        item.respondedAt = Date()
        try? context.save()
    }

    func deleteRFI(_ item: RFI, context: ModelContext) {
        context.delete(item)
        try? context.save()
        rfis.removeAll { $0.id == item.id }
    }
}
