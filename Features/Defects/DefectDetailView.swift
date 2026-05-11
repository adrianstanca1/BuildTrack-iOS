import SwiftUI
import SwiftData

struct DefectDetailView: View {
    let defect: Defect
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(severityColor.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(severityColor)
                    }

                    Text(defect.title)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        DefectSeverityBadge(severity: defect.severity)
                        DefectStatusBadge(status: defect.status)
                    }

                    if defect.isOverdue {
                        Label("Overdue", systemImage: "exclamationmark.circle.fill")
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

                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(label: "Location", value: defect.location.isEmpty ? "—" : defect.location)
                    DetailRow(label: "Severity", value: defect.severity.label)
                    DetailRow(label: "Status", value: defect.status.label)
                    DetailRow(label: "Assigned To", value: defect.assignedTo.isEmpty ? "—" : defect.assignedTo)
                    DetailRow(label: "Created By", value: defect.createdBy.isEmpty ? "—" : defect.createdBy)

                    if let due = defect.dueDate {
                        DetailRow(label: "Due Date", value: due.formatted(date: .abbreviated, time: .omitted))
                    }

                    if !defect.defectDescription.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(defect.defectDescription)
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
        .navigationTitle("Defect Details")
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
            DefectFormView(defect: defect)
        }
        .alert("Delete Defect?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(defect)
                dismiss()
            }
        }
    }

    var severityColor: Color {
        switch defect.severity {
        case .minor: return .gray
        case .major: return .orange
        case .critical: return .red
        }
    }
}

#Preview {
    let d = Defect(title: "Crack", location: "Foundation", severity: .major, status: .inProgress)
    return NavigationStack { DefectDetailView(defect: d) }
}
