import SwiftUI
import SwiftData

struct PermitsListView: View {
    @Query(sort: \Permit.expiryDate, order: .forward) private var permits: [Permit]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddPermit = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(permits) { permit in
                    NavigationLink {
                        PermitDetailView(permit: permit)
                    } label: {
                        PermitRow(permit: permit)
                    }
                }
                .onDelete(perform: deletePermit)
            }
            .listStyle(.plain)
            .navigationTitle("Permits")
            .toolbar {
                Button { showAddPermit = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddPermit) {
                PermitFormView()
            }
            .overlay {
                if permits.isEmpty {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "No Permits",
                        message: "Track planning permits and approvals"
                    )
                }
            }
        }
    }

    private func deletePermit(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(permits[index])
        }
    }
}

struct PermitRow: View {
    let permit: Permit

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(permit.permitType)
                    .font(.headline)
                Text(permit.permitNumber)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(permit.authority)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                PermitStatusBadge(status: permit.status)
                if let days = permit.daysUntilExpiry {
                    Text(days <= 0 ? "Expired" : "\(days)d left")
                        .font(.caption2)
                        .foregroundStyle(days <= 7 ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PermitStatusBadge: View {
    let status: PermitStatus

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
        case .applied: return .gray
        case .underReview: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .expired: return .red
        }
    }
}

struct PermitFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var permitNumber = ""
    @State private var permitType = ""
    @State private var authority = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Number", text: $permitNumber)
                    TextField("Type", text: $permitType)
                    TextField("Authority", text: $authority)
                }
            }
            .navigationTitle("New Permit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let permit = Permit(permitNumber: permitNumber, permitType: permitType, authority: authority)
                        modelContext.insert(permit)
                        dismiss()
                    }
                    .disabled(permitNumber.isEmpty)
                }
            }
        }
    }
}

#Preview {
    PermitsListView()
        .modelContainer(SwiftDataStack.previewContainer())
}
