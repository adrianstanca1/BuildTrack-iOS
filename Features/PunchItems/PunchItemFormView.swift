import SwiftUI
import SwiftData

struct PunchItemFormView: View {
    var punchItem: PunchItem?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var severity: PunchItemSeverity = .minor
    @State private var status: PunchItemStatus = .open
    @State private var location: String = ""
    @State private var assignee: String = ""
    @State private var selectedProject: Project?
    @State private var showProjectPicker = false

    init(punchItem: PunchItem? = nil) {
        self.punchItem = punchItem
        _title = State(initialValue: punchItem?.title ?? "")
        _descriptionText = State(initialValue: punchItem?.descriptionText ?? "")
        _severity = State(initialValue: punchItem?.severity ?? .minor)
        _status = State(initialValue: punchItem?.status ?? .open)
        _location = State(initialValue: punchItem?.location ?? "")
        _assignee = State(initialValue: punchItem?.assignee ?? "")
    }

    var isEditing: Bool { punchItem != nil }
    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title").font(.caption).foregroundStyle(.secondary)
                        TextField("What needs fixing?", text: $title)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description").font(.caption).foregroundStyle(.secondary)
                        TextField("Add details...", text: $descriptionText, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }

                Section("Severity & Status") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Severity").font(.caption).foregroundStyle(.secondary)
                        Picker("Severity", selection: $severity) {
                            ForEach(PunchItemSeverity.allCases, id: \.self) { s in
                                Text(s.label).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if isEditing {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Status").font(.caption).foregroundStyle(.secondary)
                            Picker("Status", selection: $status) {
                                ForEach(PunchItemStatus.allCases, id: \.self) { s in
                                    Text(s.label).tag(s)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }

                Section("Location & Assignment") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Location").font(.caption).foregroundStyle(.secondary)
                        TextField("Where is the defect?", text: $location)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Assignee").font(.caption).foregroundStyle(.secondary)
                        TextField("Who is responsible?", text: $assignee)
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
            .navigationTitle(isEditing ? "Edit Punch Item" : "New Punch Item")
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
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedDesc = descriptionText.trimmingCharacters(in: .whitespaces)

        if let punchItem {
            punchItem.title = trimmedTitle
            punchItem.descriptionText = trimmedDesc
            punchItem.severity = severity
            punchItem.status = status
            punchItem.location = location
            punchItem.assignee = assignee
            punchItem.projectId = selectedProject?.id
            if status == .resolved || status == .closed, punchItem.resolvedAt == nil {
                punchItem.resolvedAt = Date()
            }
        } else {
            let newItem = PunchItem(
                title: trimmedTitle,
                descriptionText: trimmedDesc,
                severity: severity,
                location: location,
                assignee: assignee,
                projectId: selectedProject?.id
            )
            modelContext.insert(newItem)
        }
        try? modelContext.save()
    }
}

#Preview {
    PunchItemFormView()
        .modelContainer(for: [PunchItem.self, Project.self])
}
