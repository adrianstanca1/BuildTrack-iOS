import SwiftUI
import SwiftData

struct MeetingDetailView: View {
    let meeting: Meeting
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showEdit = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CardView {
                    VStack(spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(meeting.title)
                                    .font(.title2.bold())
                                Text(meeting.meetingType.label)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }

                if !meeting.notes.isEmpty {
                    CardView {
                        SectionHeader(title: "Notes")
                        Text(meeting.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                CardView {
                    SectionHeader(title: "Details")
                    VStack(spacing: 12) {
                        DetailRow(icon: "calendar", label: "Date", value: meeting.date.formatted(date: .abbreviated, time: .shortened))
                        if !meeting.location.isEmpty {
                            Divider()
                            DetailRow(icon: "mappin", label: "Location", value: meeting.location)
                        }
                        Divider()
                        DetailRow(icon: "doc.text", label: "Type", value: meeting.meetingType.label)
                        Divider()
                        DetailRow(icon: "clock", label: "Created", value: meeting.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                VStack(spacing: 12) {
                    Button { showEdit = true } label: {
                        Label("Edit Meeting", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Meeting")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            MeetingFormView(meeting: meeting)
        }
        .confirmationDialog("Delete Meeting?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(meeting)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(meeting.title).")
        }
    }
}

#Preview {
    MeetingDetailView(meeting: Meeting(title: "Site Walkthrough", meetingType: .site, location: "Main Office"))
        .modelContainer(for: [Meeting.self])
}
