import SwiftUI
import SwiftData

struct MeetingDetailView: View {
    let meeting: Meeting
    @Environment(\ .modelContext) private var modelContext
    @Environment(\ .dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(typeColor.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(typeColor)
                    }

                    Text(meeting.title)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)

                    MeetingTypeBadge(type: meeting.meetingType)

                    Text(meeting.date.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)

                // Details
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(label: "Time", value: "\(meeting.startTime) – \(meeting.endTime)")
                    DetailRow(label: "Location", value: meeting.location.isEmpty ? "—" : meeting.location)
                    DetailRow(label: "Created By", value: meeting.createdBy.isEmpty ? "—" : meeting.createdBy)

                    if !meeting.agenda.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Agenda")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(meeting.agenda)
                                .font(.body)
                        }
                    }

                    if !meeting.minutes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Minutes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(meeting.minutes)
                                .font(.body)
                        }
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Meeting Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            MeetingFormView(meeting: meeting)
        }
        .alert("Delete Meeting?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(meeting)
                dismiss()
            }
        }
    }

    var typeColor: Color {
        switch meeting.meetingType {
        case .site: return .blue
        case .progress: return .green
        case .safety: return .orange
        case .design: return .purple
        case .other: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        MeetingDetailView(meeting: Meeting(title: "Weekly Site Progress", meetingType: .progress, date: Date(), startTime: "09:00", endTime: "10:30", location: "Site Office A", agenda: "1. Foundation status\n2. Steel delivery schedule\n3. Safety observations"))
    }
}
