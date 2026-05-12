import SwiftUI
import SwiftData

struct PermitDetailView: View {
    let permit: Permit
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
                                Text(permit.permitNumber)
                                    .font(.title2.bold())
                                if !permit.permitType.isEmpty {
                                    Text(permit.permitType)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                if !permit.authority.isEmpty {
                                    Label(permit.authority, systemImage: "building.columns")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            PermitStatusBadge(status: permit.status)
                        }
                    }
                }

                CardView {
                    SectionHeader(title: "Details")
                    VStack(spacing: 12) {
                        DetailRow(icon: "number", label: "Permit Number", value: permit.permitNumber)
                        Divider()
                        DetailRow(icon: "doc.text", label: "Type", value: permit.permitType.isEmpty ? "Not set" : permit.permitType)
                        Divider()
                        DetailRow(icon: "building.columns", label: "Authority", value: permit.authority.isEmpty ? "Not set" : permit.authority)
                        if let expiry = permit.expiryDate {
                            Divider()
                            DetailRow(icon: "calendar.badge.clock", label: "Expires", value: expiry.formatted(date: .abbreviated, time: .omitted), valueColor: isExpiringSoon ? .red : .green)
                        }
                        Divider()
                        DetailRow(icon: "calendar", label: "Created", value: permit.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                VStack(spacing: 12) {
                    if permit.status != .approved {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                permit.status = .approved
                                permit.updatedAt = Date()
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Approve Permit", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(BuildTrackColors.success)
                    }

                    Button { showEdit = true } label: {
                        Label("Edit Permit", systemImage: "pencil")
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
        .navigationTitle("Permit")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            PermitFormView(permit: permit)
        }
        .confirmationDialog("Delete Permit?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(permit)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(permit.permitNumber).")
        }
    }

    private var isExpiringSoon: Bool {
        guard let expiry = permit.expiryDate else { return false }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
        return days < 30
    }
}

struct PermitStatusBadge: View {
    let status: PermitStatus
    var color: Color {
        switch status {
        case .draft: return .gray
        case .submitted: return .blue
        case .underReview: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .expired: return .red
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
    PermitDetailView(permit: Permit(permitNumber: "BLD-2024-001", permitType: "Building", authority: "City Council"))
        .modelContainer(for: [Permit.self])
}
