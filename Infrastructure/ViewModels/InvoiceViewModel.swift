import Foundation
import SwiftData
import Observation

@Observable
final class InvoiceViewModel {
    var invoices: [Invoice] = []
    var isLoading = false
    var errorMessage: String?

    func fetchInvoices(context: ModelContext) {
        isLoading = true
        errorMessage = nil
        let descriptor = FetchDescriptor<Invoice>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        do {
            invoices = try context.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createInvoice(
        invoiceNumber: String,
        vendor: String,
        amount: Double,
        dueDate: Date?,
        projectId: UUID?,
        context: ModelContext
    ) {
        let invoice = Invoice(
            invoiceNumber: invoiceNumber,
            vendor: vendor,
            amount: amount,
            dueDate: dueDate,
            projectId: projectId
        )
        context.insert(invoice)
        try? context.save()
        invoices.insert(invoice, at: 0)
    }

    func updateStatus(_ invoice: Invoice, to status: InvoiceStatus, context: ModelContext) {
        invoice.status = status
        invoice.updatedAt = Date()
        try? context.save()
    }

    func deleteInvoice(_ invoice: Invoice, context: ModelContext) {
        context.delete(invoice)
        try? context.save()
        invoices.removeAll { $0.id == invoice.id }
    }

    var totalOutstanding: Double {
        invoices.filter { $0.status == .pending || $0.status == .overdue }.reduce(0) { $0 + $1.amount }
    }

    var overdueInvoices: [Invoice] {
        invoices.filter { $0.status == .overdue }
    }
}
