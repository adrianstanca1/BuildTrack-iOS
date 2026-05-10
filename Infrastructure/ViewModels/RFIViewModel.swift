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
        let rfi = RFI(
            title: title,
            descriptionText: description,
            priority: priority,
            assignedTo: assignedTo,
            projectId: projectId
        )
        context.insert(rfi)
        try? context.save()
        rfis.insert(rfi, at: 0)
    }

    func updateStatus(_ rfi: RFI, to status: RFIStatus, context: ModelContext) {
        rfi.status = status
        if status == .approved || status == .rejected || status == .closed {
            rfi.respondedAt = Date()
        }
        try? context.save()
    }

    func addResponse(_ rfi: RFI, response: String, context: ModelContext) {
        rfi.response = response
        if rfi.status == .submitted || rfi.status == .underReview {
            rfi.status = .approved
        }
        rfi.respondedAt = Date()
        try? context.save()
    }

    func deleteRFI(_ rfi: RFI, context: ModelContext) {
        context.delete(rfi)
        try? context.save()
        rfis.removeAll { $0.id == rfi.id }
    }
}
