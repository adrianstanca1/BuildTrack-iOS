import SwiftUI
import SwiftData

struct MaterialsListView: View {
    @Query(sort: \Material.updatedAt, order: .reverse) private var materials: [Material]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddMaterial = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(materials) { material in
                    MaterialRow(material: material)
                }
                .onDelete(perform: deleteMaterial)
            }
            .listStyle(.plain)
            .navigationTitle("Materials")
            .toolbar {
                Button { showAddMaterial = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddMaterial) {
                MaterialFormView()
            }
            .overlay {
                if materials.isEmpty {
                    EmptyStateView(
                        icon: "cube.box",
                        title: "No Materials",
                        message: "Track deliveries and inventory"
                    )
                }
            }
        }
    }

    private func deleteMaterial(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(materials[index])
        }
    }
}

struct MaterialRow: View {
    let material: Material

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(material.name)
                    .font(.headline)
                Text(material.category)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(material.quantity, specifier: "%.1f") \(material.unit)")
                    .font(.caption)
            }
            Spacer()
            MaterialStatusBadge(status: material.status)
        }
        .padding(.vertical, 4)
    }
}

struct MaterialStatusBadge: View {
    let status: MaterialStatus

    var body: some View {
        Text(status.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.12))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    var statusColor: Color {
        switch status {
        case .ordered: return .orange
        case .delivered: return .blue
        case .in_stock: return .green
        case .used: return .gray
        }
    }
}

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
                        let material = Material(
                            name: name,
                            category: category,
                            quantity: Double(quantity) ?? 0,
                            unit: unit
                        )
                        modelContext.insert(material)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    MaterialsListView()
        .modelContainer(SwiftDataStack.previewContainer())
}
