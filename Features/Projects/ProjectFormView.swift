import SwiftUI
import SwiftData

struct ProjectFormView: View {
    enum Mode {
        case create
        case edit(Project)
    }
    
    var mode: Mode = .create
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String
    @State private var clientName: String
    @State private var descriptionText: String
    @State private var status: ProjectStatus
    @State private var budget: String
    @State private var locationName: String
    @State private var startDate: Date
    @State private var endDate: Date?
    @State private var hasEndDate: Bool
    @State private var progress: Double
    
    var project: Project? {
        if case .edit(let p) = mode { return p }
        return nil
    }
    
    init(mode: Mode = .create) {
        self.mode = mode
        let p = mode.project
        _name = State(initialValue: p?.name ?? "")
        _clientName = State(initialValue: p?.clientName ?? "")
        _descriptionText = State(initialValue: p?.descriptionText ?? "")
        _status = State(initialValue: p?.status ?? .planning)
        _budget = State(initialValue: p != nil && p!.budget > 0 ? "\(Int(p!.budget))" : "")
        _locationName = State(initialValue: p?.locationName ?? "")
        _startDate = State(initialValue: p?.startDate ?? Date())
        _endDate = State(initialValue: p?.endDate)
        _hasEndDate = State(initialValue: p?.endDate != nil)
        _progress = State(initialValue: p?.progress ?? 0)
    }
    
    var isEditing: Bool { project != nil }
    var isValid: Bool { !name.isEmpty }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Project Info") {
                    TextField("Project Name", text: $name)
                    TextField("Client Name", text: $clientName)
                    TextField("Description", text: $descriptionText, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(ProjectStatus.allCases) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    VStack {
                        HStack {
                            Text("Progress: \(Int(progress))%")
                            Spacer()
                        }
                        Slider(value: $progress, in: 0...100, step: 5)
                            .tint(BuildTrackColors.primary)
                    }
                }
                
                Section("Budget") {
                    TextField("Total Budget ($)", text: $budget)
                        .keyboardType(.numberPad)
                }
                
                Section("Location & Dates") {
                    TextField("Location", text: $locationName)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    Toggle("Has End Date", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("End Date", selection: Binding(
                            get: { endDate ?? Date() },
                            set: { endDate = $0 }
                        ), displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Project" : "New Project")
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
        }
    }
    
    func save() {
        let budgetVal = Double(budget) ?? 0
        if let project {
            project.name = name
            project.clientName = clientName
            project.descriptionText = descriptionText
            project.status = status
            project.budget = budgetVal
            project.locationName = locationName
            project.startDate = startDate
            project.endDate = hasEndDate ? endDate : nil
            project.progress = progress
            project.updatedAt = Date()
        } else {
            let new = Project(
                name: name,
                descriptionText: descriptionText,
                status: status,
                budget: budgetVal,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                locationName: locationName,
                clientName: clientName
            )
            modelContext.insert(new)
        }
    }
}

#Preview {
    ProjectFormView()
        .modelContainer(for: [Project.self])
}
extension ProjectFormView.Mode {
    var project: Project? {
        if case .edit(let p) = self { return p }
        return nil
    }
}
