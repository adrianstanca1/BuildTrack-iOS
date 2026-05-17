import SwiftUI

struct InvoiceDetailView: View {
    let invoice: Invoice
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(invoice.invoiceNumber)
                    .font(.title2)
                Text(invoice.vendor)
                    .font(.headline)
                Text(String(format: "£%.2f", invoice.amount))
                    .font(.title3)
            }
            .padding()
        }
        .navigationTitle("Invoice Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}
