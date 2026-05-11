import SwiftUI
struct DailyReportDetailView: View { let report: DailyReport; var body: some View { Text("Report: \(report.reportDate)").navigationTitle("Daily Report") } }
