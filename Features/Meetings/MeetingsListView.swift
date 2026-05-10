import SwiftUI
import SwiftData

struct MeetingsListView: View {
    @Query(sort: \Meeting.date, order: .reverse) private var meetings: [Meeting]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddMeeting = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(meetings) { meeting in
                    MeetingRow(meeting: meeting)
                }
                .onDelete(perform: deleteMeeting)
            }
            .listStyle(.plain)
            .navigationTitle("Meetings")
            .toolbar {
                Button { showAddMeeting = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddMeeting) {
                MeetingFormView()
            }
            .overlay {
                if meetings.isEmpty {
                    EmptyStateView(
                        icon: "person.3",
                        title: "No Meetings",
                        message: "Record site meetings and minutes"
                    )
                }
            }
        }
    }

    private func deleteMeeting(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(meetings[index])
        }
    }
}

struct MeetingRow: View {
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(meeting.title)
                    .font(.headline)
                Spacer()
                MeetingTypeBadge(type: meeting.meetingType)
            }
            Text(meeting.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
            if !meeting.location.isEmpty {
                Label(meeting.location, systemImage: "mappin")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MeetingTypeBadge: View {
    let type: MeetingType

    var body: some View {
        Text(type.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(typeColor.opacity(0.12))
            .foregroundStyle(typeColor)
            .clipShape(Capsule())
    }

    var typeColor: Color {
        switch type {
        case .site: return .blue
        case .progress: return .green
        case .safety: return .orange
        case .design: return .purple
        case .other: return .gray
        }
    }
}

struct MeetingFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var meetingType: MeetingType = .site
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $meetingType) {
                        ForEach(MeetingType.allCases, id: \.self) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("New Meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let meeting = Meeting(title: title, meetingType: meetingType, date: date)
                        modelContext.insert(meeting)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    MeetingsListView()
        .modelContainer(SwiftDataStack.previewContainer())
}
