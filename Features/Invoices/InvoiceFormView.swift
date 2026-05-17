import SwiftUI

struct InvoiceFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var invoiceNumber = ""
    @State private var vendor = ""
    @State private var amount = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Invoice Number", text: $invoiceNumber)
                TextField("Vendor", text: $vendor)
                TextField("Amount", text: $amount)
            }
            .navigationTitle("New Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
