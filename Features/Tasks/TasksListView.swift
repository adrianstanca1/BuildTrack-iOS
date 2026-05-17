import SwiftUI
import SwiftData

// MARK: - Professional Tasks List View

@MainActor
struct TasksListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.updatedAt, order: .reverse) private var allTasks: [TaskItem]
    @State private var showNewTask = false
    @State private var searchQuery = ""
    @State private var statusFilter: TaskStatus? = nil
    @State private var priorityFilter: TaskPriority? = nil
    @State private var selectedTask: TaskItem?
    @State private var animateCards = false

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
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Search
                    ProSearchBar(text: $searchQuery, placeholder: "Search tasks...")
                        .fadeIn(delay: 0)

                    // Stats Row
                    statsRow
                        .fadeIn(delay: 0.1)

                    // Filter Chips
                    filterChips
                        .fadeIn(delay: 0.15)

                    // Task Groups
                    if filteredTasks.isEmpty {
                        ProEmptyState(
                            icon: "checklist",
                            title: "No Tasks",
                            message: "Create your first task to get started with project management.",
                            actionTitle: "Add Task"
                        ) {
                            DesignTokens.Haptic.medium()
                            showNewTask = true
                        }
                        .padding(.top, DesignTokens.Spacing.xl)
                    } else {
                        LazyVStack(spacing: DesignTokens.Spacing.lg) {
                            ForEach(Array(groupedTasks.enumerated()), id: \.element.0) { index, group in
                                taskGroupSection(title: group.0, tasks: group.1, delay: Double(index) * 0.1)
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                .padding(.vertical, DesignTokens.Spacing.md)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        DesignTokens.Haptic.medium()
                        showNewTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(BuildTrackColors.primary)
                            .frame(width: DesignTokens.Spacing.minTapTarget, height: DesignTokens.Spacing.minTapTarget)
                            .background(BuildTrackColors.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibleTapTarget(label: "Add new task", hint: "Double tap to create a new task")
                }
            }
            .sheet(isPresented: $showNewTask) {
                TaskFormView()
            }
            .sheet(item: $selectedTask) { task in
                NavigationStack {
                    TaskDetailView(task: task)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { selectedTask = nil }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            StatMiniCard(
                icon: "checklist",
                value: "\(filteredTasks.count)",
                label: "Total",
                color: BuildTrackColors.primary
            )
            StatMiniCard(
                icon: "checkmark.circle.fill",
                value: "\(filteredTasks.filter { $0.status == .completed }.count)",
                label: "Done",
                color: BuildTrackColors.success
            )
            StatMiniCard(
                icon: "clock.fill",
                value: "\(filteredTasks.filter { $0.status != .completed }.count)",
                label: "Pending",
                color: BuildTrackColors.warning
            )
        }
    }

    // MARK: - Filter Chips
    private var filterChips: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Status filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    FilterChipPro(label: "All", isSelected: statusFilter == nil) {
                        withAnimation(.spring(response: 0.3)) {
                            DesignTokens.Haptic.selection()
                            statusFilter = nil
                        }
                    }
                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        FilterChipPro(label: status.label, isSelected: statusFilter == status) {
                            withAnimation(.spring(response: 0.3)) {
                                DesignTokens.Haptic.selection()
                                statusFilter = status
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
            }
            .padding(.horizontal, -DesignTokens.Spacing.sectionPadding)

            // Priority filters
            if statusFilter == nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        FilterChipPro(label: "All Priorities", isSelected: priorityFilter == nil) {
                            withAnimation(.spring(response: 0.3)) {
                                DesignTokens.Haptic.selection()
                                priorityFilter = nil
                            }
                        }
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            FilterChipPro(label: priority.label, isSelected: priorityFilter == priority) {
                                withAnimation(.spring(response: 0.3)) {
                                    DesignTokens.Haptic.selection()
                                    priorityFilter = priority
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                }
                .padding(.horizontal, -DesignTokens.Spacing.sectionPadding)
            }
        }
    }

    // MARK: - Task Group Section
    private func taskGroupSection(title: String, tasks: [TaskItem], delay: Double) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text(title)
                    .font(DesignTokens.Typography.title3)
                    .foregroundStyle(groupColor(title))
                
                Spacer()
                
                Text("\(tasks.count)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(BuildTrackColors.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(BuildTrackColors.textTertiary.opacity(0.12))
                    .clipShape(Capsule())
            }

            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    TaskRowCardPro(task: task)
                        .contentTransition(.opacity)
                        .onTapGesture {
                            DesignTokens.Haptic.light()
                            selectedTask = task
                        }
                        .fadeIn(delay: delay + Double(index) * 0.05)
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

// MARK: - Task Row Card Pro

struct TaskRowCardPro: View {
    let task: TaskItem
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Priority indicator
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(priorityColor)
                .frame(width: 4, height: 44)
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(task.title)
                    .font(DesignTokens.Typography.callout.weight(.semibold))
                    .foregroundStyle(BuildTrackColors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ProBadge(text: task.status.label, color: statusColor)
                    
                    if !task.assignedTo.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "person")
                                .font(.caption2)
                            Text(task.assignedTo)
                                .font(.caption2)
                        }
                        .foregroundStyle(BuildTrackColors.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            // Due date or checkmark
            if task.status == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(BuildTrackColors.success)
                    .font(.system(size: 20))
            } else if let due = task.dueDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(due, style: .date)
                        .font(.caption2)
                        .foregroundStyle(isOverdue ? .red : BuildTrackColors.textTertiary)
                    
                    if isOverdue {
                        Text("Overdue")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.cardPadding)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
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

// MARK: - Stat Mini Card

struct StatMiniCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))
            
            Text(value)
                .font(DesignTokens.Typography.title3)
                .foregroundStyle(BuildTrackColors.textPrimary)
            
            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(BuildTrackColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
    }
}

// MARK: - Filter Chip Pro

struct FilterChipPro: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : BuildTrackColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? BuildTrackColors.primary : Color(.tertiarySystemFill))
                .clipShape(Capsule())
                .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Professional Tasks List") {
    TasksListView()
        .modelContainer(for: [TaskItem.self, Project.self])
}

// MARK: - Embedded Task Detail View

@MainActor
struct TaskDetailView: View {
    let task: TaskItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        ProBadge(text: task.priority.label, color: task.priority == .high ? .red : task.priority == .medium ? .orange : .gray)
                        ProBadge(text: task.status.label, color: task.status == .completed ? .green : .blue)
                        Spacer()
                    }
                    
                    Text(task.title)
                        .font(DesignTokens.Typography.title2)
                        .foregroundStyle(BuildTrackColors.textPrimary)
                    
                    if let projectName = task.project?.name {
                        Text(projectName)
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(BuildTrackColors.textSecondary)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)

                // Details Card
                VStack(alignment: .leading, spacing: 0) {
                    Text("Details")
                        .font(DesignTokens.Typography.callout.weight(.semibold))
                        .foregroundStyle(BuildTrackColors.textSecondary)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.top, DesignTokens.Spacing.md)
                    
                    DetailRowPro(label: "Priority", value: task.priority.label, icon: "flag")
                    Divider().padding(.leading, 44)
                    DetailRowPro(label: "Status", value: task.status.label, icon: "checkmark.circle")
                    Divider().padding(.leading, 44)
                    if let dueDate = task.dueDate {
                        DetailRowPro(label: "Due Date", value: dueDate.formatted(date: .abbreviated, time: .shortened), icon: "calendar")
                    }
                    if let assignedTo = task.assignedTo, !assignedTo.isEmpty {
                        Divider().padding(.leading, 44)
                        DetailRowPro(label: "Assigned To", value: assignedTo, icon: "person")
                    }
                }
                .professionalCard(padding: DesignTokens.Spacing.sm)
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)

                // Description
                if !task.notes.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Notes")
                            .font(DesignTokens.Typography.callout.weight(.semibold))
                            .foregroundStyle(BuildTrackColors.textSecondary)
                        
                        Text(task.notes)
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(BuildTrackColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(DesignTokens.Spacing.md)
                    .professionalCard()
                    .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                }

                // Actions
                HStack(spacing: DesignTokens.Spacing.md) {
                    Button {
                        showEditSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .font(DesignTokens.Typography.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignTokens.Spacing.buttonHeight)
                        .background(BuildTrackColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    }
                    
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .font(DesignTokens.Typography.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignTokens.Spacing.buttonHeight)
                        .background(BuildTrackColors.danger)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sectionPadding)
                .padding(.top, DesignTokens.Spacing.md)
            }
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                TaskFormView(task: task)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showEditSheet = false }
                        }
                    }
            }
        }
        .alert("Delete Task?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                modelContext.delete(task)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This task will be permanently deleted.")
        }
    }
}
