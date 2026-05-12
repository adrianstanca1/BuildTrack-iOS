import SwiftUI
struct TimesheetDetailView: View { let entry: TimesheetEntry; var body: some View { Text("Timesheet: \(entry.workerName)").navigationTitle("Timesheet") } }
