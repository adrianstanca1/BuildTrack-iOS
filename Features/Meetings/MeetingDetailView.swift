import SwiftUI
struct MeetingDetailView: View { let meeting: Meeting; var body: some View { Text("Meeting: \(meeting.title)").navigationTitle("Meeting") } }
