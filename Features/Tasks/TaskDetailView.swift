import SwiftUI
import SwiftData

@MainActor
struct TaskDetailView: View {
    let task: TaskItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        StatusBadge(status: task.status)
                        PriorityBadge(priority: task.priority)
                        Spacer()
                    }
                    Text(task.title)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 16)

                // Details Card
                DetailCard(title: "Details") {
                    VStack(alignment: .leading, spacing: 12) {
                        if !task.assignedTo.isEmpty {
                            DetailRow(icon: "person", label: "Assigned To", value: task.assignedTo)
                        }
                        if let dueDate = task.dueDate {
                            DetailRow(icon: "calendar", label: "Due Date", value: dueDate.formatted(date: .abbreviated, time: .shortened))
                        }
                        DetailRow(icon: "tag", label: "Priority", value: task.priority.label)
                        DetailRow(icon: "checkmark.circle", label: "Status", value: task.status.label)
                    }
                }
                .padding(.horizontal, 16)

                // Description
                if !task.notes.isEmpty {
                    DetailCard(title: "Notes") {
                        Text(task.notes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                }

                // Actions
                VStack(spacing: 12) {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit Task", systemImage: "pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(BuildTrackColors.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Task", systemImage: "trash")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Task Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEditSheet = true } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(BuildTrackColors.primary)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            TaskFormView(task: task)
        }
        .alert("Delete Task?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }

    private func deleteTask() {
        modelContext.delete(task)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Supporting Views

struct StatusBadge: View {
    let status: TaskStatus

    var body: some View {
        Text(status.label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        case .onHold: return .gray
        }
    }
}

struct PriorityBadge: View {
    let priority: TaskPriority

    var body: some View {
        Text(priority.label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(priorityColor.opacity(0.15))
            .foregroundStyle(priorityColor)
            .clipShape(Capsule())
    }

    private var priorityColor: Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct DetailCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            content
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(BuildTrackColors.primary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TaskItem.self, configurations: config)
    let task = TaskItem(
        title: "Foundation pour",
        notes: "Pour concrete for foundation slab. Ensure rebar is in place.",
        status: .inProgress,
        priority: .high,
        assignedTo: "Mike Chen",
        dueDate: Date().addingTimeInterval(2 * 86400)
    )
    return NavigationStack {
        TaskDetailView(task: task)
    }
    .modelContainer(container)
}
