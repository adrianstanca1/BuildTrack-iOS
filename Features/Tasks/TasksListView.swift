import SwiftUI
import SwiftData

// MARK: - Tasks List View (Redesigned)

struct TasksListView: View {
    @Query(sort: \TaskItem.updatedAt, order: .reverse) private var tasks: [TaskItem]
    @State private var searchText = ""
    @State private var statusFilter: TaskStatus?
    @State private var priorityFilter: TaskPriority?
    @State private var showAddTask = false
    
    var filteredTasks: [TaskItem] {
        var result = tasks
        if let status = statusFilter {
            result = result.filter { $0.status == status }
        }
        if let priority = priorityFilter {
            result = result.filter { $0.priority == priority }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(BuildTrackColors.textTertiary)
                    TextField("Search tasks...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                // Status filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ModernFilterChip(
                            label: "All",
                            isSelected: statusFilter == nil
                        ) { statusFilter = nil }
                        
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            ModernFilterChip(
                                label: status.label,
                                isSelected: statusFilter == status,
                                color: statusColor(status)
                            ) {
                                statusFilter = status == statusFilter ? nil : status
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Priority filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ModernFilterChip(
                            label: "All Priorities",
                            isSelected: priorityFilter == nil
                        ) { priorityFilter = nil }
                        
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            ModernFilterChip(
                                label: priority.label,
                                isSelected: priorityFilter == priority,
                                color: BuildTrackColors.priorityColor(priority)
                            ) {
                                priorityFilter = priority == priorityFilter ? nil : priority
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Tasks
                LazyVStack(spacing: 12) {
                    if filteredTasks.isEmpty {
                        EmptyStateView(
                            icon: "checklist",
                            title: "No Tasks",
                            message: "Add tasks to track work progress"
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(filteredTasks) { task in
                            ModernTaskRow(task: task)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Tasks")
        .toolbar {
            Button { showAddTask = true } label: {
                Image(systemName: "plus")
                    .foregroundStyle(BuildTrackColors.primary)
            }
        }
        .sheet(isPresented: $showAddTask) {
            TaskFormView()
        }
    }
    
    private func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .pending: return BuildTrackColors.warning
        case .inProgress: return BuildTrackColors.info
        case .completed: return BuildTrackColors.success
        case .blocked: return BuildTrackColors.danger
        }
    }
}

// MARK: - Modern Task Row

struct ModernTaskRow: View {
    let task: TaskItem
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button {
                withAnimation(.spring(response: 0.3)) {
                    toggleComplete()
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(BuildTrackColors.priorityColor(task.priority), lineWidth: 2)
                        .frame(width: 26, height: 26)
                    
                    if task.status == .completed {
                        Circle()
                            .fill(BuildTrackColors.success)
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(task.status == .completed ? BuildTrackColors.textTertiary : BuildTrackColors.textPrimary)
                    .strikethrough(task.status == .completed)
                
                HStack(spacing: 8) {
                    PriorityBadge(priority: task.priority)
                    
                    if let dueDate = task.dueDate {
                        Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(dueDate < Date() ? BuildTrackColors.danger : BuildTrackColors.textTertiary)
                    }
                    
                    if !task.assignedTo.isEmpty {
                        Label(task.assignedTo, systemImage: "person.fill")
                            .font(.caption2)
                            .foregroundStyle(BuildTrackColors.textTertiary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
    
    private func toggleComplete() {
        task.status = task.status == .completed ? .pending : .completed
        task.updatedAt = Date()
    }
}

// MARK: - Modern Filter Chip

struct ModernFilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = BuildTrackColors.primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.08))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : color.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: isSelected)
    }
}

#Preview {
    TasksListView()
        .modelContainer(for: [TaskItem.self, Project.self])
}
