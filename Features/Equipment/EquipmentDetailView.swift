import SwiftUI
import SwiftData

struct EquipmentDetailView: View {
    let equipment: Equipment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                detailsCard
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Equipment Details")
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
            EquipmentFormView(equipment: equipment)
        }
        .alert("Delete Equipment?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(equipment)
                dismiss()
            }
        }
    }

    private var headerCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(statusColor)
            }

            Text(equipment.name)
                .font(.title2.weight(.bold))

            if !equipment.make.isEmpty || !equipment.model.isEmpty {
                Text("\(equipment.make) \(equipment.model)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            EquipmentStatusBadge(status: equipment.status)

            if equipment.isServiceDue {
                Label("Service Due", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailRow(label: "Type", value: equipment.equipmentType.isEmpty ? "—" : equipment.equipmentType)
            DetailRow(label: "Serial Number", value: equipment.serialNumber.isEmpty ? "—" : equipment.serialNumber)
            DetailRow(label: "Assigned To", value: equipment.assignedTo.isEmpty ? "—" : equipment.assignedTo)
            DetailRow(label: "Location", value: equipment.location.isEmpty ? "—" : equipment.location)
            DetailRow(label: "Hours Used", value: String(format: "%.1f", equipment.hoursUsed))
            DetailRow(label: "Cost", value: equipment.cost > 0 ? "£" + String(format: "%.2f", equipment.cost) : "—")

            if let lastService = equipment.lastServiceDate {
                DetailRow(label: "Last Service", value: lastService.formatted(date: .abbreviated, time: .omitted))
            }

            if let nextService = equipment.nextServiceDate {
                DetailRow(label: "Next Service", value: nextService.formatted(date: .abbreviated, time: .omitted))
            }

            if !equipment.notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(equipment.notes)
                        .font(.body)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var statusColor: Color {
        switch equipment.status {
        case .available: return .green
        case .inUse: return .blue
        case .maintenance: return .orange
        case .retired: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        EquipmentDetailView(equipment: Equipment(name: "Excavator CAT 320", equipmentType: "Heavy Machinery", make: "Caterpillar", model: "320", serialNumber: "CAT320-2024-001", status: .inUse, assignedTo: "Mike Chen", location: "Site A", hoursUsed: 1245, nextServiceDate: Date().addingTimeInterval(30 * 86400)))
    }
}
