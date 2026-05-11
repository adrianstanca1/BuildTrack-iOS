import SwiftUI
import SwiftData

struct DrawingDetailView: View {
    let drawing: Drawing
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
                                Text(drawing.title)
                                    .font(.title2.bold())
                                if !drawing.drawingNumber.isEmpty {
                                    Label(drawing.drawingNumber, systemImage: "number")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            DrawingStatusBadge(status: drawing.status)
                        }
                        HStack(spacing: 8) {
                            if !drawing.revision.isEmpty {
                                Text("Rev \(drawing.revision)")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                if !drawing.fileUrl.isEmpty {
                    CardView {
                        SectionHeader(title: "File")
                        if let url = URL(string: drawing.fileUrl) {
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundStyle(BuildTrackColors.primary)
                                    Text("Open Drawing")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(BuildTrackColors.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundStyle(BuildTrackColors.primary)
                                }
                            }
                        }
                    }
                }

                CardView {
                    SectionHeader(title: "Details")
                    VStack(spacing: 12) {
                        DetailRow(icon: "calendar", label: "Created", value: drawing.createdAt.formatted(date: .abbreviated, time: .shortened))
                        Divider()
                        DetailRow(icon: "pencil", label: "Updated", value: drawing.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                VStack(spacing: 12) {
                    Button { showEdit = true } label: {
                        Label("Edit Drawing", systemImage: "pencil")
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
        .navigationTitle("Drawing")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            DrawingFormView(drawing: drawing)
        }
        .confirmationDialog("Delete Drawing?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(drawing)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(drawing.title).")
        }
    }
}

#Preview {
    DrawingDetailView(drawing: Drawing(title: "Foundation Plan A", drawingNumber: "A-101"))
        .modelContainer(for: [Drawing.self])
}
