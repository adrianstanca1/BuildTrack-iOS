import SwiftUI
import SwiftData

struct SubmittalDetailView: View {
    let submittal: Submittal
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
                                Text(submittal.title)
                                    .font(.title2.bold())
                                Text(submittal.type.label)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            SubmittalStatusBadge(status: submittal.status)
                        }

                        HStack(spacing: 8) {
                            if !submittal.submittedBy.isEmpty {
                                Label(submittal.submittedBy, systemImage: "person.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !submittal.descriptionText.isEmpty {
                    CardView {
                        SectionHeader(title: "Description")
                        Text(submittal.descriptionText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                CardView {
                    SectionHeader(title: "Details")
                    VStack(spacing: 12) {
                        DetailRow(icon: "calendar", label: "Created", value: submittal.createdAt.formatted(date: .abbreviated, time: .shortened))
                        if !submittal.reviewedBy.isEmpty {
                            Divider()
                            DetailRow(icon: "person.check", label: "Reviewed By", value: submittal.reviewedBy)
                        }
                        Divider()
                        DetailRow(icon: "doc", label: "Type", value: submittal.type.label)
                    }
                }

                VStack(spacing: 12) {
                    if submittal.status == .submitted || submittal.status == .underReview {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                submittal.status = .approved
                                submittal.updatedAt = Date()
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Approve", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(BuildTrackColors.success)

                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                submittal.status = .rejected
                                submittal.updatedAt = Date()
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Reject", systemImage: "xmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(BuildTrackColors.danger)
                    }

                    Button { showEdit = true } label: {
                        Label("Edit Submittal", systemImage: "pencil")
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
        .navigationTitle("Submittal")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            SubmittalFormView(submittal: submittal)
        }
        .confirmationDialog("Delete Submittal?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(submittal)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(submittal.title).")
        }
    }
}

struct SubmittalStatusBadge: View {
    let status: SubmittalStatus

    var body: some View {
        Text(status.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .draft: return .gray
        case .submitted: return .blue
        case .underReview: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .closed: return .gray
        }
    }
}

#Preview {
    SubmittalDetailView(submittal: Submittal(title: "Concrete Mix Design", type: .material, submittedBy: "John Smith"))
        .modelContainer(for: [Submittal.self])
}
