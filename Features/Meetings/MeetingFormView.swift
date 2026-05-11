import SwiftUI
import SwiftData

struct MeetingFormView: View {
    var meeting: Meeting?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var meetingType: MeetingType = .site
    @State private var date = Date()
    @State private var startTime = ""
    @State private var endTime = ""
    @State private var location = ""
    @State private var agenda = ""
    var isEditing: Bool { meeting != nil }
    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    init(meeting: Meeting? = nil) {
        self.meeting = meeting
        _title = State(initialValue: meeting?.title ?? "")
        _meetingType = State(initialValue: meeting?.meetingType ?? .site)
        _date = State(initialValue: meeting?.date ?? Date())
        _startTime = State(initialValue: meeting?.startTime ?? "")
        _endTime = State(initialValue: meeting?.endTime ?? "")
        _location = State(initialValue: meeting?.location ?? "")
        _agenda = State(initialValue: meeting?.agenda ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $meetingType) {
                        ForEach(MeetingType.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                }
                Section("Schedule") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Start Time", text: $startTime)
                    TextField("End Time", text: $endTime)
                    TextField("Location", text: $location)
                }
                Section("Agenda") {
                    TextField("Agenda items", text: $agenda, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(isEditing ? "Edit Meeting" : "New Meeting")
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
        if let meeting {
            meeting.title = title
            meeting.meetingType = meetingType
            meeting.date = date
            meeting.startTime = startTime
            meeting.endTime = endTime
            meeting.location = location
            meeting.agenda = agenda
            meeting.updatedAt = Date()
        } else {
            let newMeeting = Meeting(
                title: title,
                meetingType: meetingType,
                date: date,
                startTime: startTime,
                endTime: endTime,
                location: location,
                agenda: agenda
            )
            modelContext.insert(newMeeting)
        }
        dismiss()
    }
}
