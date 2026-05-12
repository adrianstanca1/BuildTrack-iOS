import SwiftUI
import SwiftData

struct TimesheetDetailView: View {
    let entry: TimesheetEntry
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
                                Text(entry.workerName)
                                    .font(.title2.bold())
                                if !entry.task.isEmpty {
                                    Text(entry.task)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            TimesheetStatusBadge(status: entry.status)
                        }
                    }
                }

                CardView {
                    SectionHeader(title: "Hours")
                    HStack {
                        Text("\(String(format: "%.1f", entry.hoursWorked)) hrs")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(BuildTrackColors.primary)
                        Spacer()
                    }
                }

                CardView {
                    SectionHeader(title: "Details")
                    VStack(spacing: 12) {
                        DetailRow(icon: "calendar", label: "Date", value: entry.date.formatted(date: .abbreviated, time: .omitted))
                        Divider()
                        DetailRow(icon: "clock", label: "Hours", value: String(format: "%.1f", entry.hoursWorked))
                        if !entry.task.isEmpty {
                            Divider()
                            DetailRow(icon: "checklist", label: "Task", value: entry.task)
                        }
                        Divider()
                        DetailRow(icon: "doc.text", label: "Status", value: entry.status.label)
                        Divider()
                        DetailRow(icon: "calendar.badge.clock", label: "Created", value: entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                VStack(spacing: 12) {
                    if entry.status != .approved {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                entry.status = .approved
                                entry.updatedAt = Date()
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
                        Label("Edit Timesheet", systemImage: "pencil")
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
        .navigationTitle("Timesheet")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            TimesheetFormView(entry: entry)
        }
        .confirmationDialog("Delete Timesheet?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(entry)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete this timesheet entry.")
        }
    }
}

struct TimesheetStatusBadge: View {
    let status: TimesheetStatus
    var color: Color {
        switch status {
        case .draft: return .gray
        case .submitted: return .blue
        case .approved: return .green
        case .rejected: return .red
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
    TimesheetDetailView(entry: TimesheetEntry(workerName: "John Smith", hoursWorked: 8.5, task: "Foundation pour", status: .approved))
        .modelContainer(for: [TimesheetEntry.self])
}
