import SwiftUI
import SwiftData

struct PunchItemDetailView: View {
    let punchItem: PunchItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showEdit = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                CardView {
                    VStack(spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(punchItem.title)
                                    .font(.title2.bold())
                                if !punchItem.location.isEmpty {
                                    Label(punchItem.location, systemImage: "mappin")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            PunchItemStatusBadge(status: punchItem.status)
                        }

                        HStack(spacing: 8) {
                            PunchItemSeverityBadge(severity: punchItem.severity)
                            if !punchItem.assignee.isEmpty {
                                Label(punchItem.assignee, systemImage: "person.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Description
                if !punchItem.descriptionText.isEmpty {
                    CardView {
                        SectionHeader(title: "Description")
                        Text(punchItem.descriptionText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Photos
                if !punchItem.photoUrls.isEmpty {
                    CardView {
                        SectionHeader(title: "Photos")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(punchItem.photoUrls, id: \.self) { url in
                                    AsyncImage(url: URL(string: url)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        case .failure, .empty:
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemGray5))
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .foregroundStyle(.secondary)
                                                )
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                }

                // Dates
                CardView {
                    SectionHeader(title: "Details")
                    VStack(spacing: 12) {
                        DetailRow(label: "Created", value: punchItem.createdAt.formatted(date: .abbreviated, time: .shortened))
                        if let resolved = punchItem.resolvedAt {
                            Divider()
                            DetailRow(label: "Resolved", value: resolved.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }

                // Quick actions
                VStack(spacing: 12) {
                    if punchItem.status != .resolved && punchItem.status != .closed {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                punchItem.status = .resolved
                                punchItem.resolvedAt = Date()
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Mark Resolved", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(BuildTrackColors.success)
                    }

                    Button { showEdit = true } label: {
                        Label("Edit Punch Item", systemImage: "pencil")
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
        .navigationTitle("Punch Item")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            PunchItemFormView(punchItem: punchItem)
        }
        .confirmationDialog("Delete Punch Item?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(punchItem)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(punchItem.title).")
        }
    }
}

#Preview {
    PunchItemDetailView(punchItem: PunchItem(title: "Demo Defect"))
        .modelContainer(for: [PunchItem.self])
}
