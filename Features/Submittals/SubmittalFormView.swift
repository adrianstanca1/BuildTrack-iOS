import SwiftUI
import SwiftData

struct SubmittalFormView: View {
    var submittal: Submittal?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var type: SubmittalType = .other
    @State private var status: SubmittalStatus = .draft
    @State private var submittedBy: String = ""
    @State private var reviewedBy: String = ""
    @State private var selectedProject: Project?
    @State private var showProjectPicker = false

    init(submittal: Submittal? = nil) {
        self.submittal = submittal
        _title = State(initialValue: submittal?.title ?? "")
        _descriptionText = State(initialValue: submittal?.descriptionText ?? "")
        _type = State(initialValue: submittal?.type ?? .other)
        _status = State(initialValue: submittal?.status ?? .draft)
        _submittedBy = State(initialValue: submittal?.submittedBy ?? "")
        _reviewedBy = State(initialValue: submittal?.reviewedBy ?? "")
    }

    var isEditing: Bool { submittal != nil }
    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title").font(.caption).foregroundStyle(.secondary)
                        TextField("e.g. Concrete Mix Design", text: $title)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description").font(.caption).foregroundStyle(.secondary)
                        TextField("Add details...", text: $descriptionText, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }

                Section("Type & Status") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Type").font(.caption).foregroundStyle(.secondary)
                        Picker("Type", selection: $type) {
                            ForEach(SubmittalType.allCases, id: \.self) { t in
                                Text(t.label).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if isEditing {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Status").font(.caption).foregroundStyle(.secondary)
                            Picker("Status", selection: $status) {
                                ForEach(SubmittalStatus.allCases, id: \.self) { s in
                                    Text(s.label).tag(s)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }

                Section("People") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Submitted By").font(.caption).foregroundStyle(.secondary)
                        TextField("Name", text: $submittedBy)
                    }
                    if isEditing {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reviewed By").font(.caption).foregroundStyle(.secondary)
                            TextField("Name", text: $reviewedBy)
                        }
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
            .navigationTitle(isEditing ? "Edit Submittal" : "New Submittal")
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

        if let submittal {
            submittal.title = trimmedTitle
            submittal.descriptionText = trimmedDesc
            submittal.type = type
            submittal.status = status
            submittal.submittedBy = submittedBy
            submittal.reviewedBy = reviewedBy
            submittal.projectId = selectedProject?.id
            submittal.updatedAt = Date()
        } else {
            let newSubmittal = Submittal(
                title: trimmedTitle,
                descriptionText: trimmedDesc,
                type: type,
                submittedBy: submittedBy,
                projectId: selectedProject?.id
            )
            modelContext.insert(newSubmittal)
        }
        try? modelContext.save()
    }
}

#Preview {
    SubmittalFormView()
        .modelContainer(for: [Submittal.self, Project.self])
}
