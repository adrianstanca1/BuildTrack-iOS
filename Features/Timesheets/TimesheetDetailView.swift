import SwiftUI
import SwiftData

struct TimesheetDetailView: View {
    let entry: TimesheetEntry
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
                        Image(systemName: "clock.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(statusColor)
                    }

                    Text(entry.workerName)
                        .font(.title2.weight(.bold))

                    Text(entry.date.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TimesheetStatusBadge(status: entry.status)
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)

                // Hours Summary
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("\(entry.hoursWorked, specifier: "%.1f")")
                            .font(.title.weight(.bold))
                        Text("Hours Worked")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    VStack(spacing: 4) {
                        Text("\(entry.breakMinutes)")
                            .font(.title.weight(.bold))
                        Text("Break (min)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                // Details
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(label: "Time", value: "\(entry.startTime) – \(entry.endTime)")
                    DetailRow(label: "Task", value: entry.task.isEmpty ? "—" : entry.task)
                    DetailRow(label: "Status", value: entry.status.label)
                    DetailRow(label: "Approved By", value: entry.approvedBy.isEmpty ? "Pending" : entry.approvedBy)

                    if !entry.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(entry.notes)
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
        .navigationTitle("Timesheet Details")
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
            TimesheetFormView(entry: entry)
        }
        .alert("Delete Timesheet?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(entry)
                dismiss()
            }
        }
    }

    var statusColor: Color {
        switch entry.status {
        case .draft: return .gray
        case .submitted: return .blue
        case .approved: return .green
        case .rejected: return .red
        }
    }
}

#Preview {
    NavigationStack {
        TimesheetDetailView(entry: TimesheetEntry(workerName: "Mike Chen", date: Date(), startTime: "08:00", endTime: "16:30", breakMinutes: 30, hoursWorked: 8.0, task: "Foundation pour", status: .approved, approvedBy: "Sarah Johnson"))
    }
}
