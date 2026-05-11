import SwiftUI
import SwiftData

struct DefectFormView: View {
    var defect: Defect?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var defectDescription = ""
    @State private var location = ""
    @State private var severity: DefectSeverity = .minor
    @State private var status: DefectStatus = .open
    @State private var assignedTo = ""
    @State private var dueDate = Date().addingTimeInterval(7 * 86400)
    var isEditing: Bool { defect != nil }
    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    init(defect: Defect? = nil) {
        self.defect = defect
        _title = State(initialValue: defect?.title ?? "")
        _defectDescription = State(initialValue: defect?.defectDescription ?? "")
        _location = State(initialValue: defect?.location ?? "")
        _severity = State(initialValue: defect?.severity ?? .minor)
        _status = State(initialValue: defect?.status ?? .open)
        _assignedTo = State(initialValue: defect?.assignedTo ?? "")
        _dueDate = State(initialValue: defect?.dueDate ?? Date().addingTimeInterval(7 * 86400))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $defectDescription, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Location", text: $location)
                }
                Section("Severity") {
                    Picker("Severity", selection: $severity) {
                        ForEach(DefectSeverity.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(DefectStatus.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Assignment") {
                    TextField("Assigned To", text: $assignedTo)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
            }
            .navigationTitle(isEditing ? "Edit Defect" : "New Defect")
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
        if let defect {
            defect.title = title
            defect.defectDescription = defectDescription
            defect.location = location
            defect.severity = severity
            defect.status = status
            defect.assignedTo = assignedTo
            defect.dueDate = dueDate
            defect.updatedAt = Date()
        } else {
            let newDefect = Defect(
                title: title,
                defectDescription: defectDescription,
                location: location,
                severity: severity,
                status: status,
                assignedTo: assignedTo,
                dueDate: dueDate
            )
            modelContext.insert(newDefect)
        }
        dismiss()
    }
}
