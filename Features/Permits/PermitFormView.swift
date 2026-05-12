import SwiftUI
import SwiftData

struct PermitFormView: View {
    var permit: Permit?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var permitNumber: String = ""
    @State private var permitType: String = ""
    @State private var authority: String = ""
    @State private var status: PermitStatus = .draft
    @State private var hasExpiryDate = false
    @State private var expiryDate: Date = Date().addingTimeInterval(86400 * 90)
    @State private var selectedProject: Project?
    @State private var showProjectPicker = false

    init(permit: Permit? = nil) {
        self.permit = permit
        _permitNumber = State(initialValue: permit?.permitNumber ?? "")
        _permitType = State(initialValue: permit?.permitType ?? "")
        _authority = State(initialValue: permit?.authority ?? "")
        _status = State(initialValue: permit?.status ?? .draft)
        _hasExpiryDate = State(initialValue: permit?.expiryDate != nil)
        _expiryDate = State(initialValue: permit?.expiryDate ?? Date().addingTimeInterval(86400 * 90))
    }

    var isEditing: Bool { permit != nil }
    var isValid: Bool { !permitNumber.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Permit Number").font(.caption).foregroundStyle(.secondary)
                        TextField("e.g. BLD-2024-001", text: $permitNumber)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Type").font(.caption).foregroundStyle(.secondary)
                        TextField("e.g. Building, Electrical", text: $permitType)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Authority").font(.caption).foregroundStyle(.secondary)
                        TextField("e.g. City Council", text: $authority)
                    }
                }

                Section("Status & Dates") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status").font(.caption).foregroundStyle(.secondary)
                        Picker("Status", selection: $status) {
                            ForEach(PermitStatus.allCases, id: \.self) { s in
                                Text(s.label).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Toggle("Set Expiry Date", isOn: $hasExpiryDate)
                    if hasExpiryDate {
                        DatePicker("Expires", selection: $expiryDate, displayedComponents: .date)
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
            .navigationTitle(isEditing ? "Edit Permit" : "New Permit")
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
        let trimmed = permitNumber.trimmingCharacters(in: .whitespaces)
        if let permit {
            permit.permitNumber = trimmed
            permit.permitType = permitType
            permit.authority = authority
            permit.status = status
            permit.expiryDate = hasExpiryDate ? expiryDate : nil
            permit.updatedAt = Date()
        } else {
            let newPermit = Permit(
                permitNumber: trimmed,
                permitType: permitType,
                authority: authority,
                status: status,
                expiryDate: hasExpiryDate ? expiryDate : nil
            )
            modelContext.insert(newPermit)
        }
        try? modelContext.save()
    }
}

#Preview {
    PermitFormView()
        .modelContainer(for: [Permit.self, Project.self])
}
