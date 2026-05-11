import SwiftUI
import SwiftData

struct MaterialFormView: View {
    var material: Material?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var category = ""
    @State private var materialDescription = ""
    @State private var quantity = ""
    @State private var unit = ""
    @State private var status: MaterialStatus = .ordered
    @State private var supplier = ""
    @State private var cost = ""
    var isEditing: Bool { material != nil }
    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    init(material: Material? = nil) {
        self.material = material
        _name = State(initialValue: material?.name ?? "")
        _category = State(initialValue: material?.category ?? "")
        _materialDescription = State(initialValue: material?.materialDescription ?? "")
        _quantity = State(initialValue: material.map { String($0.quantity) } ?? "")
        _unit = State(initialValue: material?.unit ?? "")
        _status = State(initialValue: material?.status ?? .ordered)
        _supplier = State(initialValue: material?.supplier ?? "")
        _cost = State(initialValue: material.map { String($0.cost) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Category", text: $category)
                    TextField("Description", text: $materialDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Quantity") {
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.decimalPad)
                    TextField("Unit", text: $unit)
                }
                Section("Supplier") {
                    TextField("Supplier", text: $supplier)
                    TextField("Cost", text: $cost)
                        .keyboardType(.decimalPad)
                }
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(MaterialStatus.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(isEditing ? "Edit Material" : "New Material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        if let material {
            material.name = name
            material.category = category
            material.materialDescription = materialDescription
            material.quantity = Double(quantity) ?? 0
            material.unit = unit
            material.status = status
            material.supplier = supplier
            material.cost = Double(cost) ?? 0
            material.updatedAt = Date()
        } else {
            let newMaterial = Material(
                name: name,
                category: category,
                materialDescription: materialDescription,
                quantity: Double(quantity) ?? 0,
                unit: unit,
                status: status,
                supplier: supplier,
                cost: Double(cost) ?? 0
            )
            modelContext.insert(newMaterial)
        }
        dismiss()
    }
}
