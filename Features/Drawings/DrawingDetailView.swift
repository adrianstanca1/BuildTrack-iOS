import SwiftUI
import SwiftData

struct DrawingDetailView: View {
    let drawing: Drawing
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = DrawingViewModel()
    @State private var showEditSheet = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                detailSection
                if !drawing.fileUrl.isEmpty { fileSection }
                actionButtons
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Drawing Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showEditSheet = true } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) {
                        viewModel.deleteDrawing(drawing, context: modelContext)
                        dismiss()
                    } label: { Label("Delete", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            DrawingFormView(drawing: drawing)
        }
    }
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatusBadge(text: drawing.status.label, color: statusColor(drawing.status))
                Spacer()
                Text("Rev \(drawing.revision)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            }
            Text(drawing.title)
                .font(.title2.weight(.bold))
            if !drawing.drawingNumber.isEmpty {
                Text("Drawing #\(drawing.drawingNumber)")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    var detailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailRow(label: "Status", value: drawing.status.label, icon: "doc")
            DetailRow(label: "Drawing Number", value: drawing.drawingNumber.isEmpty ? "—" : drawing.drawingNumber, icon: "number")
            DetailRow(label: "Revision", value: drawing.revision, icon: "arrow.counterclockwise")
            DetailRow(label: "Created", value: drawing.createdAt.formatted(date: .abbreviated, time: .shortened), icon: "calendar")
            DetailRow(label: "Updated", value: drawing.updatedAt.formatted(date: .abbreviated, time: .shortened), icon: "arrow.clockwise")
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    var fileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("File")
                .font(.headline)
            Link(destination: URL(string: drawing.fileUrl)!) {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("View Drawing")
                            .font(.body.weight(.semibold))
                        Text(drawing.fileUrl)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    var actionButtons: some View {
        VStack(spacing: 12) {
            if drawing.status == .active {
                Button {
                    viewModel.updateStatus(drawing, to: .superseded, context: modelContext)
                } label: {
                    Label("Supersede Drawing", systemImage: "arrow.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            if drawing.status != .archived {
                Button {
                    viewModel.updateStatus(drawing, to: .archived, context: modelContext)
                } label: {
                    Label("Archive Drawing", systemImage: "archivebox")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            if drawing.status != .active {
                Button {
                    viewModel.updateStatus(drawing, to: .active, context: modelContext)
                } label: {
                    Label("Activate Drawing", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    func statusColor(_ status: DrawingStatus) -> Color {
        switch status {
        case .active: return .green
        case .superseded: return .orange
        case .archived: return .gray
        }
    }
}
