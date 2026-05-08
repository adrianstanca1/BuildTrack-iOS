import SwiftUI
import SwiftData

struct TasksListView: View {
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    @State private var searchText = ""
    @State private var statusFilter: TaskStatus?
    @State private var priorityFilter: TaskPriority?
    @State private var showAddTask = false
    
    var filteredTasks: [TaskItem] {
        var result = tasks
        if let s = statusFilter { result = result.filter { $0.status == s } }
        if let p = priorityFilter { result = result.filter { $0.priority == p } }
        if !searchText.isEmpty { result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) } }
        return result
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Priority filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: priorityFilter == nil) { priorityFilter = nil }
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            FilterChip(label: p.label, isSelected: priorityFilter == p) {
                                priorityFilter = p == priorityFilter ? nil : p
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                LazyVStack(spacing: 12) {
                    if filteredTasks.isEmpty {
                        EmptyStateView(icon: "checklist", title: "No Tasks", message: "Tap + to add your first task")
                    }
                    ForEach(filteredTasks) { task in
                        NavigationLink { TaskDetailView(task: task) } label: { TaskCard(task: task) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $searchText, prompt: "Search tasks...")
        .navigationTitle("Tasks")
        .toolbar { Button { showAddTask = true } label: { Image(systemName: "plus") } }
        .sheet(isPresented: $showAddTask) { TaskFormView() }
    }
}

struct TaskCard: View {
    let task: TaskItem
    
    var isOverdue: Bool {
        guard let due = task.dueDate else { return false }
        return due < Date() && task.status != .completed
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation {
                    task.status = task.status == .completed ? .pending : .completed
                    task.updatedAt = Date()
                }
            } label: {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.status == .completed ? .green : .gray.opacity(0.4))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(task.status == .completed)
                HStack(spacing: 8) {
                    PriorityBadge(priority: task.priority)
                    if let due = task.dueDate {
                        Text(due.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(isOverdue ? .red : .secondary)
                    }
                }
            }
            Spacer()
            if task.status == .completed {
                Image(systemName: "checkmark").font(.caption).foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .opacity(task.status == .completed ? 0.6 : 1)
    }
}

struct TaskDetailView: View {
    let task: TaskItem
    @State private var showEdit = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CardView {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title).font(.title3.bold())
                                if !task.descriptionText.isEmpty {
                                    Text(task.descriptionText).font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            PriorityBadge(priority: task.priority)
                        }
                        HStack {
                            StatusBadge(status: task.status == .completed ? .completed : (task.status == .inProgress ? .active : .planning))
                            Spacer()
                            Text("Due: \(task.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                
                if !task.assignedTo.isEmpty {
                    CardView {
                        DetailRow(label: "Assigned To", value: task.assignedTo)
                    }
                }
                
                VStack(spacing: 12) {
                    Button { showEdit = true } label: { Label("Edit Task", systemImage: "pencil").frame(maxWidth: .infinity) }
                        .buttonStyle(.bordered).controlSize(.large)
                    Button(role: .destructive) {
                        modelContext.delete(task)
                        dismiss()
                    } label: { Label("Delete Task", systemImage: "trash").frame(maxWidth: .infinity) }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Task Details")
        .sheet(isPresented: $showEdit) { TaskFormView(task: task) }
    }
}

#Preview {
    TasksListView().modelContainer(for: [TaskItem.self])
}
