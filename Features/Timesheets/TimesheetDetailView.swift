import SwiftUI
import SwiftData

struct TimesheetDetailView: View {
    let entry: TimesheetEntry
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                CardView {
                    VStack(spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.workerName)
                                    .font(.title2.bold())
                                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            TimesheetStatusBadge(status: entry.status)
                        }
                        
                        HStack(spacing: 8) {
                            Text("\(entry.hoursWorked, specifier: "%.1f")h")
                                .font(.largeTitle.bold())
                                .foregroundStyle(BuildTrackColors.primary)
                            Text("worked")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
                
                // Task description
                if !entry.task.isEmpty {
                    CardView {
                        SectionHeader(title: "Task")
                        Text(entry.task)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Details
                CardView {
                    SectionHeader(title: "Details")
                    VStack(spacing: 12) {
                        DetailRow(icon: "person", label: "Worker", value: entry.workerName)
                        Divider()
                        DetailRow(icon: "clock", label: "Hours Worked", value: "\(String(format: "%.1f", entry.hoursWorked))")
                        Divider()
                        DetailRow(icon: "calendar", label: "Date", value: entry.date.formatted(date: .abbreviated, time: .omitted))
                        Divider()
                        DetailRow(icon: "flag", label: "Status", value: entry.status.label)
                        Divider()
                        DetailRow(icon: "calendar.badge.plus", label: "Created", value: entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                
                // Actions
                VStack(spacing: 12) {
                    Button {
                        showEdit = true
                    } label: {
                        Label("Edit Timesheet", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Timesheet", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Timesheet Detail")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            TimesheetFormView(entry: entry)
        }
        .alert("Delete Timesheet?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteEntry()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete this timesheet entry for \(entry.workerName).")
        }
        .overlay {
            if isDeleting {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func deleteEntry() {
        isDeleting = true
        
        modelContext.delete(entry)
        try? modelContext.save()
        
        Task {
            let viewModel = TimesheetViewModel(modelContext: modelContext)
            let success = await viewModel.delete(id: entry.id)
            await MainActor.run {
                isDeleting = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TimesheetDetailView(entry: TimesheetEntry(workerName: "Mike Chen", hoursWorked: 8.5, task: "Foundation pour — Phase 2", status: .submitted, date: Date()))
    }
    .modelContainer(SwiftDataStack.previewContainer())
}
