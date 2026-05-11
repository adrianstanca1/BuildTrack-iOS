import SwiftUI
import SwiftData

struct RFIDetailView: View {
    let rfi: RFI
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
                                Text(rfi.title)
                                    .font(.title2.bold())
                                if !rfi.assignedTo.isEmpty {
                                    Label(rfi.assignedTo, systemImage: "person.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            RFIStatusBadge(status: rfi.status)
                        }
                        HStack(spacing: 8) {
                            PriorityBadge(priority: rfi.priority)
                            if let responded = rfi.respondedAt {
                                Label("Responded", systemImage: "checkmark.circle")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                if !rfi.descriptionText.isEmpty {
                    CardView {
                        SectionHeader(title: "Description")
                        Text(rfi.descriptionText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if !rfi.response.isEmpty {
                    CardView {
                        SectionHeader(title: "Response")
                        Text(rfi.response)
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }

                CardView {
                    SectionHeader(title: "Details")
                    VStack(spacing: 12) {
                        DetailRow(icon: "calendar", label: "Created", value: rfi.createdAt.formatted(date: .abbreviated, time: .shortened))
                        if let responded = rfi.respondedAt {
                            Divider()
                            DetailRow(icon: "checkmark.circle", label: "Responded", value: responded.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }

                VStack(spacing: 12) {
                    if rfi.status != .approved && rfi.status != .closed {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                rfi.status = .approved
                                rfi.respondedAt = Date()
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Approve", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(BuildTrackColors.success)
                    }

                    Button { showEdit = true } label: {
                        Label("Edit RFI", systemImage: "pencil")
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
        .navigationTitle("RFI Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            RFIFormView(rfi: rfi)
        }
        .confirmationDialog("Delete RFI?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(rfi)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(rfi.title).")
        }
    }
}

#Preview {
    RFIDetailView(rfi: RFI(title: "Clarification needed on foundation depth"))
        .modelContainer(for: [RFI.self])
}
