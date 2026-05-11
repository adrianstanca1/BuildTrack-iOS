import SwiftUI
import SwiftData

struct BudgetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var totalBudget = ""
    @State private var currency = "GBP"

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Total Budget", text: $totalBudget)
                        .keyboardType(.decimalPad)
                    Picker("Currency", selection: $currency) {
                        Text("GBP").tag("GBP")
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                    }
                }
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let budget = Budget(name: name, totalBudget: Double(totalBudget) ?? 0, currency: currency)
                        modelContext.insert(budget)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
