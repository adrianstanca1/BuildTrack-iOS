import SwiftUI
import SwiftData

struct TimesheetFormView: View {
    var entry: TimesheetEntry?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var workerName: String = ""
    @State private var hoursWorked: String = ""
    @State private var task: String = ""
    @State private var status: TimesheetStatus = .draft
    @State private var date: Date = Date()
    @State private var selectedProject: Project?
    @State private var showProjectPicker = false

    init(entry: TimesheetEntry? = nil) {
        self.entry = entry
        _workerName = State(initialValue: entry?.workerName ?? "")
        _hoursWorked = State(initialValue: entry != nil ? String(entry!.hoursWorked) : "")
        _task = State(initialValue: entry?.task ?? "")
        _status = State(initialValue: entry?.status ?? .draft)
        _date = State(initialValue: entry?.date ?? Date())
    }

    var isEditing: Bool { entry != nil }
    var isValid: Bool {
        !workerName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !hoursWorked.isEmpty &&
        Double(hoursWorked) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Worker") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name").font(.caption).foregroundStyle(.secondary)
                        TextField("Worker name", text: $workerName)
                    }
                }

                Section("Hours & Task") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hours Worked").font(.caption).foregroundStyle(.secondary)
                        TextField("0.0", text: $hoursWorked)
                            .keyboardType(.decimalPad)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Task").font(.caption).foregroundStyle(.secondary)
                        TextField("What was worked on?", text: $task)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                }

                Section("Status") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status").font(.caption).foregroundStyle(.secondary)
                        Picker("Status", selection: $status) {
                            ForEach(TimesheetStatus.allCases, id: \.self) { s in
                                Text(s.label).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("Project") {
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
            .navigationTitle(isEditing ? "Edit Timesheet" : "New Timesheet")
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
            .sheet(isPresented: $showProjectPicker) {
                ProjectPicker(selectedProject: $selectedProject, projects: projects)
            }
        }
    }

    private func save() {
        let trimmedName = workerName.trimmingCharacters(in: .whitespaces)
        let hrs = Double(hoursWorked) ?? 0
        if let entry {
            entry.workerName = trimmedName
            entry.hoursWorked = hrs
            entry.task = task
            entry.status = status
            entry.date = date
            entry.updatedAt = Date()
        } else {
            let newEntry = TimesheetEntry(
                workerName: trimmedName,
                hoursWorked: hrs,
                task: task,
                status: status,
                date: date
            )
            modelContext.insert(newEntry)
        }
        try? modelContext.save()
    }
}

#Preview {
    TimesheetFormView()
        .modelContainer(for: [TimesheetEntry.self, Project.self])
}
