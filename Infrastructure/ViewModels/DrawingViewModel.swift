import Foundation
import SwiftData
import Observation

@Observable
final class DrawingViewModel {
    var drawings: [Drawing] = []
    var isLoading = false
    var errorMessage: String?

    func fetchDrawings(context: ModelContext) {
        isLoading = true
        errorMessage = nil
        let descriptor = FetchDescriptor<Drawing>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
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
        let drawing = Drawing(
            title: title,
            drawingNumber: drawingNumber,
            revision: revision,
            fileUrl: fileUrl,
            projectId: projectId
        )
        context.insert(drawing)
        try? context.save()
        drawings.insert(drawing, at: 0)
    }

    func updateStatus(_ drawing: Drawing, to status: DrawingStatus, context: ModelContext) {
        drawing.status = status
        drawing.updatedAt = Date()
        try? context.save()
    }

    func updateRevision(_ drawing: Drawing, revision: String, context: ModelContext) {
        drawing.revision = revision
        drawing.updatedAt = Date()
        try? context.save()
    }

    func deleteDrawing(_ drawing: Drawing, context: ModelContext) {
        context.delete(drawing)
        try? context.save()
        drawings.removeAll { $0.id == drawing.id }
    }
}
