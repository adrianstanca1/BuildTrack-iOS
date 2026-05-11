import SwiftUI
import SwiftData

struct EquipmentListView: View {
    @Query(sort: \Equipment.updatedAt, order: .reverse) private var equipment: [Equipment]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddEquipment = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(equipment) { item in
                    NavigationLink {
                        EquipmentDetailView(equipment: item)
                    } label: {
                        EquipmentRow(item: item)
                    }
                }
                .onDelete(perform: deleteEquipment)
            }
            .listStyle(.plain)
            .navigationTitle("Equipment")
            .toolbar {
                Button { showAddEquipment = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddEquipment) {
                EquipmentFormView()
            }
            .overlay {
                if equipment.isEmpty {
                    EmptyStateView(
                        icon: "wrench.and.screwdriver",
                        title: "No Equipment",
                        message: "Track plant and machinery"
                    )
                }
            }
        }
    }

    private func deleteEquipment(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(equipment[index])
        }
    }
}

struct EquipmentRow: View {
    let item: Equipment

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                Text(item.equipmentType)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !item.make.isEmpty || !item.model.isEmpty {
                    Text("\(item.make) \(item.model)")
                        .font(.caption)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                EquipmentStatusBadge(status: item.status)
                if item.isServiceDue {
                    Text("Service Due")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct EquipmentStatusBadge: View {
    let status: EquipmentStatus

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
        case .available: return .green
        case .inUse: return .blue
        case .maintenance: return .orange
        case .retired: return .gray
        }
    }
}

#Preview {
    EquipmentListView()
        .modelContainer(SwiftDataStack.previewContainer())
}
