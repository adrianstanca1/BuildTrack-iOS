import SwiftUI
import SwiftData

struct TasksListView: View {
    @Query(sort: \TaskItem.dueDate)
    private var tasks: [TaskItem]
    @State
    private var searchText = ""
    @State
    private var statusFilter: TaskStatus?
    @State
    private var priorityFilter: TaskPriority?
    @State
    private var showAddTask = false
    
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
                // Priority filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            label: "All",
                            isSelected: priorityFilter == nil
                        ) { priorityFilter = nil }
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            FilterChip(
                                label: priority.label,
                                isSelected: priorityFilter == priority
                            ) {
                                priorityFilter = priority == priorityFilter ? nil : priority
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Search
                TextField("Search tasks...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                // Tasks list
                LazyVStack(spacing: 12) {
                    ForEach(filteredTasks) { task in
                        TaskRow(task: task)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddTask = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            TaskFormView(mode: .create)
        }
    }
}

struct TaskRow: View {
    let task: TaskItem
    @Environment(\.modelContext)
    private var modelContext
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                Text(task.project?.name ?? "No project")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            PriorityBadge(priority: task.priority)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}

struct TaskDetailView: View {
    let task: TaskItem
    @State
    private var showEdit = false
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.modelContext)
    private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CardView {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title).font(.title3.bold())
                                if !task.descriptionText.isEmpty {
                                    Text(task.descriptionText)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            PriorityBadge(priority: task.priority)
                        }
                        HStack {
                            StatusBadge(
                                status: task.status == .completed
                                ? .completed
                                : (task.status == .inProgress ? .active : .planning)
                            )
                            Spacer()
                            Text("Due: \(task.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assignment")
                            .font(.headline)
                        if let assignee = task.assignee {
                            HStack {
                                Image(systemName: "person.circle")
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text(assignee.name)
                                        .font(.subheadline)
                                    Text(assignee.role)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            Text("Unassigned")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Timeline")
                            .font(.headline)
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Created")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(task.createdAt.formatted())
                                    .font(.subheadline)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Task Details")
        .toolbar {
            Button("Edit") { showEdit = true }
        }
        .sheet(isPresented: $showEdit) {
            TaskFormView(mode: .edit(task))
        }
    }
}

#Preview {
    TasksListView()
        .modelContainer(SwiftDataStack.previewContainer())
}
