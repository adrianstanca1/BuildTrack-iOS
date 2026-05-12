import SwiftUI
import SwiftData

struct MaterialDetailView: View {
    let material: Material
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showEdit = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CardView {
                    VStack(spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(material.name)
                                    .font(.title2.bold())
                                if !material.category.isEmpty {
                                    Text(material.category)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            MaterialStatusBadge(status: material.status)
                        }
                    }
                }

                CardView {
                    SectionHeader(title: "Quantity")
                    HStack {
                        Text("\(String(format: "%.2f", material.quantity)) \(material.unit)")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(BuildTrackColors.primary)
                        Spacer()
                    }
                }

                CardView {
                    SectionHeader(title: "Details")
                    VStack(spacing: 12) {
                        DetailRow(icon: "calendar", label: "Created", value: material.createdAt.formatted(date: .abbreviated, time: .shortened))
                        Divider()
                        DetailRow(icon: "pencil", label: "Updated", value: material.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                VStack(spacing: 12) {
                    Button { showEdit = true } label: {
                        Label("Edit Material", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Material")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            MaterialFormView(material: material)
        }
        .confirmationDialog("Delete Material?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(material)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(material.name).")
        }
    }
}

struct MaterialStatusBadge: View {
    let status: MaterialStatus
    var color: Color {
        switch status {
        case .ordered: return .blue
        case .delivered: return .orange
        case .inStock: return .green
        case .used: return .gray
        }
    }
    var body: some View {
        Text(status.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

#Preview {
    MaterialDetailView(material: Material(name: "Concrete", category: "Foundation", quantity: 150, unit: "m³"))
        .modelContainer(for: [Material.self])
}
