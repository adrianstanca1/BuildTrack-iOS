import SwiftUI
import SwiftData
struct TaskFormView: View {
    var task: TaskItem?
    var preselectedProject: Project?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Worker.name) private var workers: [Worker]
    @Query(sort: \Project.name) private var projects: [Project]
    
    @State private var title: String
    @State private var descriptionText: String
    @State private var priority: TaskPriority
    @State private var status: TaskStatus
    @State private var assignedTo: Worker?
    @State private var selectedProject: Project?
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var hasDueTime: Bool
    @State private var dueTime: Date
    @State private var showWorkerPicker = false
    @State private var showProjectPicker = false
    
    init(task: TaskItem? = nil, preselectedProject: Project? = nil) {
        self.task = task
        self.preselectedProject = preselectedProject
        _title = State(initialValue: task?.title ?? "")
        _descriptionText = State(initialValue: task?.descriptionText ?? "")
        _priority = State(initialValue: task?.priority ?? .medium)
        _status = State(initialValue: task?.status ?? .pending)
        _selectedProject = State(initialValue: preselectedProject ?? task?.project)
        _hasDueDate = State(initialValue: task?.dueDate != nil)
        _dueDate = State(initialValue: task?.dueDate ?? Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        _hasDueTime = State(initialValue: task?.dueDate.map { Calendar.current.component(.hour, from: $0) > 0 } ?? false)
        _dueTime = State(initialValue: task?.dueDate ?? Date())
    }
    
    var isEditing: Bool { task != nil }
    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }
    
    var effectiveDueDate: Date? {
        guard hasDueDate else { return nil }
        if hasDueTime {
            let cal = Calendar.current
            var comps = cal.dateComponents([.year, .month, .day], from: dueDate)
            let timeComps = cal.dateComponents([.hour, .minute], from: dueTime)
            comps.hour = timeComps.hour
            comps.minute = timeComps.minute
            return cal.date(from: comps)
        }
        return Calendar.current.startOfDay(for: dueDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title").font(.caption).foregroundStyle(.secondary)
                        TextField("What needs to be done?", text: $title)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description").font(.caption).foregroundStyle(.secondary)
                        TextField("Add details...", text: $descriptionText, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                
                Section("Priority & Status") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority").font(.caption).foregroundStyle(.secondary)
                        Picker("Priority", selection: $priority) {
                            ForEach(TaskPriority.allCases, id: \.self) { p in
                                HStack {
                                    Circle()
                                        .fill(BuildTrackColors.priorityColor(p))
                                        .frame(width: 10, height: 10)
                                    Text(p.label)
                                }
                                .tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status").font(.caption).foregroundStyle(.secondary)
                        Picker("Status", selection: $status) {
                            ForEach(TaskStatus.allCases, id: \.self) { s in
                                HStack {
                                    Image(systemName: s.icon)
                                    Text(s.label)
                                }
                                .tag(s)
                            }
                        }
                    }
                }
                
                Section("Assignment & Project") {
                    Button {
                        showWorkerPicker = true
                    } label: {
                        HStack {
                            Text("Assign To")
                            Spacer()
                            if let worker = assignedTo {
                                Text(worker.name)
                                    .foregroundStyle(BuildTrackColors.primary)
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(BuildTrackColors.primary)
                            } else {
                                Text("Not assigned")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    
                    if preselectedProject == nil {
                        Button {
                            showProjectPicker = true
                        } label: {
                            HStack {
                                Text("Project")
                                Spacer()
                                if let project = selectedProject {
                                    Text(project.name)
                                        .foregroundStyle(BuildTrackColors.primary)
                                    Image(systemName: "building.2.fill")
                                        .foregroundStyle(BuildTrackColors.primary)
                                } else {
                                    Text("None")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }
                
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Date", selection: $dueDate, displayedComponents: .date)
                        
                        Toggle("Set time", isOn: $hasDueTime)
                        if hasDueTime {
                            DatePicker("Time", selection: $dueTime, displayedComponents: .hourAndMinute)
                        }
                        
                        if let due = effectiveDueDate, due < Date() {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("This date is in the past")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showWorkerPicker) {
                WorkerPickerView(selectedWorker: $assignedTo)
            }
            .sheet(isPresented: $showProjectPicker) {
                ProjectPicker(selectedProject: $selectedProject)
            }
        }
    }
    
    func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedDesc = descriptionText.trimmingCharacters(in: .whitespaces)
        
        if let task {
            // Edit existing
            task.title = trimmedTitle
            task.descriptionText = trimmedDesc
            task.priority = priority
            task.status = status
            task.assignedTo = assignedTo?.name ?? ""
            task.dueDate = effectiveDueDate
            task.project = selectedProject ?? preselectedProject
            task.updatedAt = Date()
        } else {
            // Create new
            let newTask = TaskItem(
                title: trimmedTitle,
                descriptionText: trimmedDesc,
                priority: priority,
                status: status,
                dueDate: effectiveDueDate,
                assignedTo: assignedTo?.name ?? ""
            )
            newTask.project = selectedProject ?? preselectedProject
            modelContext.insert(newTask)
        }
        
        try? modelContext.save()
    }
}
// MARK: - Worker Picker
struct WorkerPickerView: View {
    @Binding var selectedWorker: Worker?
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Worker.name) private var workers: [Worker]
    @State private var searchText = ""
    
    var filteredWorkers: [Worker] {
        workers.filter { $0.isActive }.filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredWorkers) { worker in
                Button {
                    selectedWorker = worker
                    dismiss()
                } label: {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(BuildTrackColors.primary.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Text(String(worker.name.prefix(2)))
                                .font(.caption.bold())
                                .foregroundStyle(BuildTrackColors.primary)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(worker.name)
                            Text(worker.role.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedWorker?.id == worker.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(BuildTrackColors.primary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search workers...")
            .navigationTitle("Assign To")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
// MARK: - Project Picker
