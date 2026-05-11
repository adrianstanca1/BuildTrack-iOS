import SwiftUI
import SwiftData

// MARK: - Tasks List View

@MainActor
struct TasksListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.updatedAt, order: .reverse) private var allTasks: [TaskItem]
    @State private var viewModel = TaskViewModel()
    @State private var showNewTask = false
    @State private var searchQuery = ""
    @State private var statusFilter: TaskStatus? = nil
    @State private var priorityFilter: TaskPriority? = nil

    var filteredTasks: [TaskItem] {
        var result = allTasks
        if let status = statusFilter {
            result = result.filter { $0.status == status }
        }
        if let priority = priorityFilter {
            result = result.filter { $0.priority == priority }
        }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.assignedTo.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return result
    }

    var groupedTasks: [(String, [TaskItem])] {
        let calendar = Calendar.current
        let now = Date()

        let overdue = filteredTasks.filter { task in
            guard let due = task.dueDate, task.status != .completed else { return false }
            return due < now && !calendar.isDateInToday(due)
        }
        let today = filteredTasks.filter { task in
            guard let due = task.dueDate, task.status != .completed else { return false }
            return calendar.isDateInToday(due)
        }
        let thisWeek = filteredTasks.filter { task in
            guard let due = task.dueDate, task.status != .completed else { return false }
            return due > now && calendar.isDate(due, equalTo: now, toGranularity: .weekOfYear) && !calendar.isDateInToday(due)
        }
        let later = filteredTasks.filter { task in
            guard let due = task.dueDate, task.status != .completed else { return false }
            return due > now && !calendar.isDate(due, equalTo: now, toGranularity: .weekOfYear)
        }
        let completed = filteredTasks.filter { $0.status == .completed }
        let noDueDate = filteredTasks.filter { $0.dueDate == nil && $0.status != .completed }

        var groups: [(String, [TaskItem])] = []
        if !overdue.isEmpty { groups.append(("Overdue", overdue.sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) })) }
        if !today.isEmpty { groups.append(("Today", today)) }
        if !thisWeek.isEmpty { groups.append(("This Week", thisWeek)) }
        if !later.isEmpty { groups.append(("Later", later)) }
        if !noDueDate.isEmpty { groups.append(("No Due Date", noDueDate)) }
        if !completed.isEmpty { groups.append(("Completed", completed)) }

        return groups
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Search
                    SearchBar(query: $searchQuery, placeholder: "Search tasks...")

                    // Filter chips
                    filterChips

                    // Stats
                    HStack(spacing: 12) {
                        SummaryCard(title: "Total", value: "\(filteredTasks.count)", icon: "checklist", color: BuildTrackColors.primary)
                        SummaryCard(title: "Done", value: "\(filteredTasks.filter { $0.status == .completed }.count)", icon: "checkmark.circle", color: .green)
                        SummaryCard(title: "Pending", value: "\(filteredTasks.filter { $0.status != .completed }.count)", icon: "clock", color: .orange)
                    }

                    // Task groups
                    if filteredTasks.isEmpty {
                        EmptyStateView(
                            icon: "checklist",
                            title: "No Tasks",
                            message: "Create your first task to get started."
                        )
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(groupedTasks, id: \.0) { group in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(group.0)
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(groupColor(group.0))
                                        .padding(.horizontal, 4)

                                    LazyVStack(spacing: 8) {
                                        ForEach(group.1) { task in
                                            NavigationLink {
                                                TaskDetailView(task: task)
                                            } label: {
                                                TaskRowCard(task: task)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewTask = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(BuildTrackColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showNewTask) {
                TaskFormView()
            }
        }
    }

    private var filterChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "All", isSelected: statusFilter == nil) { statusFilter = nil }
                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        FilterChip(label: status.label, isSelected: statusFilter == status) { statusFilter = status }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Priority filters (only show if no status filter)
            if statusFilter == nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All Priorities", isSelected: priorityFilter == nil) { priorityFilter = nil }
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            FilterChip(label: priority.label, isSelected: priorityFilter == priority) { priorityFilter = priority }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func groupColor(_ group: String) -> Color {
        switch group {
        case "Overdue": return .red
        case "Today": return .orange
        case "This Week": return .blue
        case "Later": return .green
        case "Completed": return .gray
        default: return BuildTrackColors.textSecondary
        }
    }
}

// MARK: - Task Detail View

struct TaskDetailView: View {
    let task: TaskItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CardView {
                    VStack(spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(.title2.bold())
                                if !task.assignedTo.isEmpty {
                                    Label(task.assignedTo, systemImage: "person.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            PriorityBadge(priority: task.priority)
                        }

                        HStack(spacing: 8) {
                            Text(task.status.label)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(statusColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(statusColor.opacity(0.12))
                                .clipShape(Capsule())

                            if let due = task.dueDate {
                                Label(due.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                    .font(.caption2)
                                    .foregroundStyle(isOverdue ? .red : BuildTrackColors.textTertiary)
                            }
                        }
                    }
                }

                if !task.descriptionText.isEmpty {
                    CardView {
                        SectionHeader(title: "Description")
                        Text(task.descriptionText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                CardView {
                    SectionHeader(title: "Details")
                    VStack(spacing: 12) {
                        DetailRow(icon: "calendar", label: "Created", value: task.createdAt.formatted(date: .abbreviated, time: .shortened))
                        Divider()
                        DetailRow(icon: "flag", label: "Status", value: task.status.label)
                        Divider()
                        DetailRow(icon: "exclamationmark.circle", label: "Priority", value: task.priority.label)
                        if !task.assignedTo.isEmpty {
                            Divider()
                            DetailRow(icon: "person", label: "Assigned To", value: task.assignedTo)
                        }
                        if let due = task.dueDate {
                            Divider()
                            DetailRow(icon: "calendar.badge.clock", label: "Due Date", value: due.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }

                if task.project != nil {
                    CardView {
                        SectionHeader(title: "Project")
                        HStack {
                            Image(systemName: "building.2.fill")
                                .foregroundStyle(BuildTrackColors.primary)
                            Text(task.project!.name)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                        }
                    }
                }

                VStack(spacing: 12) {
                    if task.status != .completed {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                task.status = .completed
                                task.updatedAt = Date()
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Mark Complete", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(BuildTrackColors.success)
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                task.status = .pending
                                task.updatedAt = Date()
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Reopen Task", systemImage: "arrow.uturn.backward.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.orange)
                    }

                    Button { showEdit = true } label: {
                        Label("Edit Task", systemImage: "pencil")
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
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            TaskFormView(task: task)
        }
        .confirmationDialog("Delete Task?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(task)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(task.title).")
        }
    }

    private var statusColor: Color {
        switch task.status {
        case .pending: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .blocked: return .red
        }
    }

    private var isOverdue: Bool {
        guard let due = task.dueDate else { return false }
        return due < Date() && task.status != .completed
    }
}

#Preview {
    TasksListView()
        .modelContainer(for: [TaskItem.self, Project.self])
}
