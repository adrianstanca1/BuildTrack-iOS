import Foundation
import SwiftData
import Observation

@Observable
final class SubmittalViewModel {
    var submittals: [Submittal] = []
    var isLoading = false
    var errorMessage: String?

    func fetchSubmittals(context: ModelContext) {
        isLoading = true
        errorMessage = nil
        let descriptor = FetchDescriptor<Submittal>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        do {
            submittals = try context.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createSubmittal(
        title: String,
        description: String,
        type: SubmittalType,
        submittedBy: String,
        projectId: UUID?,
        context: ModelContext
    ) {
        let submittal = Submittal(
            title: title,
            descriptionText: description,
            type: type,
            submittedBy: submittedBy,
            projectId: projectId
        )
        context.insert(submittal)
        try? context.save()
        submittals.insert(submittal, at: 0)
    }

    func updateStatus(_ submittal: Submittal, to status: SubmittalStatus, context: ModelContext) {
        submittal.status = status
        submittal.updatedAt = Date()
        try? context.save()
    }

    func deleteSubmittal(_ submittal: Submittal, context: ModelContext) {
        context.delete(submittal)
        try? context.save()
        submittals.removeAll { $0.id == submittal.id }
    }

    var pendingCount: Int {
        submittals.filter { $0.status == .submitted || $0.status == .underReview }.count
    }
}
