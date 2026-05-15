import SwiftUI
import SwiftData

struct TimesheetFormView: View {
    var entry: TimesheetEntry?
    var preselectedWorker: Worker?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Worker.name) private var workers: [Worker]
    
    @State private var selectedWorker: Worker?
    @State private var hoursWorked: String = ""
    @State private var task: String = ""
    @State private var date: Date = Date()
    @State private var status: TimesheetStatus = .draft
    @State private var showWorkerPicker = false
    @State private var isSaving = false
    
    init(entry: TimesheetEntry? = nil, preselectedWorker: Worker? = nil) {
        self.entry = entry
        self.preselectedWorker = preselectedWorker
        _selectedWorker = State(initialValue: preselectedWorker)
        if let entry {
            _hoursWorked = State(initialValue: String(entry.hoursWorked))
            _task = State(initialValue: entry.task)
            _date = State(initialValue: entry.date)
            _status = State(initialValue: entry.status)
        }
    }
    
    var isEditing: Bool { entry != nil }
    
    var isValid: Bool {
        selectedWorker != nil && !hoursWorked.isEmpty && (Double(hoursWorked) ?? 0) > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Worker") {
                    Button {
                        showWorkerPicker = true
                    } label: {
                        HStack {
                            Text("Worker")
                            Spacer()
                            if let worker = selectedWorker {
                                Text(worker.name)
                                    .foregroundStyle(BuildTrackColors.primary)
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(BuildTrackColors.primary)
                            } else {
                                Text("Select worker")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                
                Section("Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hours Worked").font(.caption).foregroundStyle(.secondary)
                        TextField("Enter hours...", text: $hoursWorked)
                            .keyboardType(.decimalPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Task Description").font(.caption).foregroundStyle(.secondary)
                        TextField("What was worked on?", text: $task, axis: .vertical)
                            .lineLimit(2...4)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(TimesheetStatus.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(isEditing ? "Edit Timesheet" : "New Timesheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") {
                        save()
                    }
                    .disabled(!isValid || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showWorkerPicker) {
                WorkerPickerView(selectedWorker: $selectedWorker)
            }
            .overlay {
                if isSaving {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private func save() {
        guard let worker = selectedWorker, let hours = Double(hoursWorked), hours > 0 else { return }
        
        isSaving = true
        
        if let entry {
            // Update existing
            entry.workerName = worker.name
            entry.hoursWorked = hours
            entry.task = task.trimmingCharacters(in: .whitespaces)
            entry.date = date
            entry.status = status
            entry.updatedAt = Date()
            
            try? modelContext.save()
            
            Task {
                let viewModel = TimesheetViewModel(modelContext: modelContext)
                _ = await viewModel.update(entry)
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            }
        } else {
            // Create new
            let newEntry = TimesheetEntry(
                workerName: worker.name,
                hoursWorked: hours,
                task: task.trimmingCharacters(in: .whitespaces),
                status: status,
                date: date
            )
            
            modelContext.insert(newEntry)
            try? modelContext.save()
            
            Task {
                let viewModel = TimesheetViewModel(modelContext: modelContext)
                _ = await viewModel.create(newEntry)
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    TimesheetFormView()
        .modelContainer(SwiftDataStack.previewContainer())
}
