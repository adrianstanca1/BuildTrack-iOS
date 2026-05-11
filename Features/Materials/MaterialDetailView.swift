import SwiftUI
import SwiftData

struct MaterialDetailView: View {
    let material: Material
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "cube.box.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(statusColor)
                    }

                    Text(material.name)
                        .font(.title2.weight(.bold))

                    Text(material.category)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    MaterialStatusBadge(status: material.status)
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)

                // Details
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(label: "Quantity", value: "\(material.quantity, specifier: "%.1f") \(material.unit)")
                    DetailRow(label: "Status", value: material.status.label)
                    DetailRow(label: "Supplier", value: material.supplier.isEmpty ? "—" : material.supplier)
                    DetailRow(label: "Cost", value: material.cost > 0 ? "£\(material.cost, specifier: "%.2f")" : "—")

                    if let delivery = material.deliveryDate {
                        DetailRow(label: "Delivery", value: delivery.formatted(date: .abbreviated, time: .omitted))
                    }

                    if !material.materialDescription.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(material.materialDescription)
                                .font(.body)
                        }
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Material Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            MaterialFormView(material: material)
        }
        .alert("Delete Material?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(material)
                dismiss()
            }
        }
    }

    var statusColor: Color {
        switch material.status {
        case .ordered: return .orange
        case .delivered: return .blue
        case .in_stock: return .green
        case .used: return .gray
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}

#Preview {
    NavigationStack {
        MaterialDetailView(material: Material(name: "Rebar 16mm", category: "Steel", quantity: 500, unit: "m", status: .delivered, supplier: "SteelTech Ltd", cost: 2500))
    }
}
