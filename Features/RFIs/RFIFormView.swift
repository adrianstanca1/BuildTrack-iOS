import SwiftUI
import SwiftData

struct RFIFormView: View {
    var rfi: RFI?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]
    @State private var viewModel = RFIViewModel()
    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var priority: RFIPriority = .medium
    @State private var assignedTo: String = ""
    @State private var selectedProject: Project?
    @State private var showProjectPicker = false
    var isEditing: Bool { rfi != nil }
    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    init(rfi: RFI? = nil) {
        self.rfi = rfi
        _title = State(initialValue: rfi?.title ?? "")
        _descriptionText = State(initialValue: rfi?.descriptionText ?? "")
        _priority = State(initialValue: rfi?.priority ?? .medium)
        _assignedTo = State(initialValue: rfi?.assignedTo ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title").font(.caption).foregroundStyle(.secondary)
                        TextField("What is your question?", text: $title)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description").font(.caption).foregroundStyle(.secondary)
                        TextField("Add details...", text: $descriptionText, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                Section("Priority & Assignment") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority").font(.caption).foregroundStyle(.secondary)
                        Picker("Priority", selection: $priority) {
                            ForEach(RFIPriority.allCases, id: \self) { p in
                                Text(p.label).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Assigned To").font(.caption).foregroundStyle(.secondary)
                        TextField("Name or email", text: $assignedTo)
                    }
                }
                Section("Project") {
                    Button {
                        showProjectPicker = true
                    } label: {
                        HStack {
                            Text(selectedProject?.name ?? rfi?.projectId.map { _ in "Linked" } ?? "Select Project")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit RFI" : "New RFI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        if isEditing {
                            rfi?.title = title
                            rfi?.descriptionText = descriptionText
                            rfi?.priority = priority
                            rfi?.assignedTo = assignedTo
                            try? modelContext.save()
                        } else {
                            viewModel.createRFI(
                                title: title,
                                description: descriptionText,
                                priority: priority,
                                assignedTo: assignedTo,
                                projectId: selectedProject?.id,
                                context: modelContext
                            )
                        }
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showProjectPicker) {
                ProjectPicker(selectedProject: $selectedProject, projects: projects)
            }
        }
    }
}
