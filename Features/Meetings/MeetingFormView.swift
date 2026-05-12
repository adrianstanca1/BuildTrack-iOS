import SwiftUI
import SwiftData

struct MeetingFormView: View {
    var meeting: Meeting?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var title: String = ""
    @State private var meetingType: MeetingType = .site
    @State private var date: Date = Date()
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var selectedProject: Project?
    @State private var showProjectPicker = false

    init(meeting: Meeting? = nil) {
        self.meeting = meeting
        _title = State(initialValue: meeting?.title ?? "")
        _meetingType = State(initialValue: meeting?.meetingType ?? .site)
        _date = State(initialValue: meeting?.date ?? Date())
        _location = State(initialValue: meeting?.location ?? "")
        _notes = State(initialValue: meeting?.notes ?? "")
    }

    var isEditing: Bool { meeting != nil }
    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title").font(.caption).foregroundStyle(.secondary)
                        TextField("Meeting title", text: $title)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Type").font(.caption).foregroundStyle(.secondary)
                        Picker("Type", selection: $meetingType) {
                            ForEach(MeetingType.allCases, id: \.self) { t in
                                Text(t.label).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Location").font(.caption).foregroundStyle(.secondary)
                        TextField("Where", text: $location)
                    }
                }

                Section("Notes") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes").font(.caption).foregroundStyle(.secondary)
                        TextField("Meeting notes...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
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
            .navigationTitle(isEditing ? "Edit Meeting" : "New Meeting")
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
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if let meeting {
            meeting.title = trimmed
            meeting.meetingType = meetingType
            meeting.date = date
            meeting.location = location
            meeting.notes = notes
            meeting.updatedAt = Date()
        } else {
            let newMeeting = Meeting(
                title: trimmed,
                meetingType: meetingType,
                date: date,
                location: location,
                notes: notes
            )
            modelContext.insert(newMeeting)
        }
        try? modelContext.save()
    }
}

#Preview {
    MeetingFormView()
        .modelContainer(for: [Meeting.self, Project.self])
}
