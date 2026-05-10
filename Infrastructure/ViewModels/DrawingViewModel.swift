import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class DrawingViewModel {
    var drawings: [Drawing] = []
    var isLoading = false
    var errorMessage: String?

    func fetchDrawings(context: ModelContext) {
        isLoading = true
        errorMessage = nil
        let descriptor = FetchDescriptor<Drawing>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        do {
            drawings = try context.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createDrawing(
        title: String,
        drawingNumber: String,
        revision: String,
        fileUrl: String,
        projectId: UUID?,
        context: ModelContext
    ) {
        let item = Drawing(
            title: title,
            drawingNumber: drawingNumber,
            revision: revision,
            fileUrl: fileUrl,
            projectId: projectId
        )
        context.insert(item)
        try? context.save()
        drawings.insert(item, at: 0)
    }

    func updateStatus(_ item: Drawing, to status: DrawingStatus, context: ModelContext) {
        item.status = status
        item.updatedAt = Date()
        try? context.save()
    }

    func deleteDrawing(_ item: Drawing, context: ModelContext) {
        context.delete(item)
        try? context.save()
        drawings.removeAll { $0.id == item.id }
    }
}
