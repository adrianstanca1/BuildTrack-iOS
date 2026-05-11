import SwiftUI
import SwiftData

struct TimesheetFormView: View {
    var entry: TimesheetEntry?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var workerName = ""
    @State private var date = Date()
    @State private var startTime = ""
    @State private var endTime = ""
    @State private var breakMinutes = ""
    @State private var hoursWorked = ""
    @State private var task = ""
    @State private var notes = ""
    @State private var status: TimesheetStatus = .draft
    var isEditing: Bool { entry != nil }
    var isValid: Bool { !workerName.trimmingCharacters(in: .whitespaces).isEmpty }

    init(entry: TimesheetEntry? = nil) {
        self.entry = entry
        _workerName = State(initialValue: entry?.workerName ?? "")
        _date = State(initialValue: entry?.date ?? Date())
        _startTime = State(initialValue: entry?.startTime ?? "")
        _endTime = State(initialValue: entry?.endTime ?? "")
        _breakMinutes = State(initialValue: entry.map { String($0.breakMinutes) } ?? "")
        _hoursWorked = State(initialValue: entry.map { String($0.hoursWorked) } ?? "")
        _task = State(initialValue: entry?.task ?? "")
        _notes = State(initialValue: entry?.notes ?? "")
        _status = State(initialValue: entry?.status ?? .draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Worker") {
                    TextField("Name", text: $workerName)
                }
                Section("Schedule") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Start Time", text: $startTime)
                    TextField("End Time", text: $endTime)
                    TextField("Break (min)", text: $breakMinutes)
                        .keyboardType(.numberPad)
                }
                Section("Hours") {
                    TextField("Hours Worked", text: $hoursWorked)
                        .keyboardType(.decimalPad)
                    TextField("Task", text: $task)
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
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
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        if let entry {
            entry.workerName = workerName
            entry.date = date
            entry.startTime = startTime
            entry.endTime = endTime
            entry.breakMinutes = Int(breakMinutes) ?? 0
            entry.hoursWorked = Double(hoursWorked) ?? 0
            entry.task = task
            entry.notes = notes
            entry.status = status
            entry.updatedAt = Date()
        } else {
            let newEntry = TimesheetEntry(
                workerName: workerName,
                date: date,
                startTime: startTime,
                endTime: endTime,
                breakMinutes: Int(breakMinutes) ?? 0,
                hoursWorked: Double(hoursWorked) ?? 0,
                task: task,
                notes: notes,
                status: status
            )
            modelContext.insert(newEntry)
        }
        dismiss()
    }
}
