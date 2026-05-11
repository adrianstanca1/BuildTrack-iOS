import SwiftUI
import SwiftData

struct MaterialFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var category = ""
    @State private var quantity = ""
    @State private var unit = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Category", text: $category)
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.decimalPad)
                    TextField("Unit", text: $unit)
                }
            }
            .navigationTitle("New Material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let material = Material(name: name, category: category, quantity: Double(quantity) ?? 0, unit: unit)
                        modelContext.insert(material)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
