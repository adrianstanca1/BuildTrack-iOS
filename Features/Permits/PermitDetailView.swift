import SwiftUI
import SwiftData

struct PermitDetailView: View {
    let permit: Permit
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
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(statusColor)
                    }

                    Text(permit.permitType)
                        .font(.title2.weight(.bold))

                    PermitStatusBadge(status: permit.status)

                    if let days = permit.daysUntilExpiry {
                        Text(days <= 0 ? "Expired \(abs(days)) days ago" : "\(days) days until expiry")
                            .font(.subheadline)
                            .foregroundStyle(days <= 7 ? .red : .secondary)
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)

                // Details
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(label: "Number", value: permit.permitNumber)
                    DetailRow(label: "Authority", value: permit.authority.isEmpty ? "—" : permit.authority)
                    DetailRow(label: "Status", value: permit.status.label)

                    if let issue = permit.issueDate {
                        DetailRow(label: "Issue Date", value: issue.formatted(date: .abbreviated, time: .omitted))
                    }

                    if let expiry = permit.expiryDate {
                        DetailRow(label: "Expiry Date", value: expiry.formatted(date: .abbreviated, time: .omitted))
                    }

                    if !permit.permitDescription.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(permit.permitDescription)
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
        .navigationTitle("Permit Details")
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
            PermitFormView(permit: permit)
        }
        .alert("Delete Permit?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(permit)
                dismiss()
            }
        }
    }

    var statusColor: Color {
        switch permit.status {
        case .applied: return .gray
        case .underReview: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .expired: return .red
        }
    }
}

#Preview {
    NavigationStack {
        PermitDetailView(permit: Permit(permitNumber: "PL-2024-0892", permitType: "Planning Permission", authority: "City Council", status: .approved, issueDate: Date().addingTimeInterval(-60 * 86400), expiryDate: Date().addingTimeInterval(300 * 86400), permitDescription: "Full planning permission for 45-storey residential tower"))
    }
}
