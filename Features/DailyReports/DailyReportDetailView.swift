import SwiftUI
import SwiftData

struct DailyReportDetailView: View {
    let report: DailyReport

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(report.date.formatted(date: .long, time: .omitted))
                    .font(.headline)
                HStack {
                    StatusBadge(status: report.status)
                    Spacer()
                    Text("\(report.workersOnSite) workers")
                        .font(.caption)
                }
                if !report.weatherRaw.isEmpty {
                    Label("\(report.weatherRaw)  \(Int(report.temperature))°C", systemImage: "cloud")
                        .font(.caption)
                }
                if !report.summary.isEmpty {
                    Text(report.summary)
                        .font(.body)
                }
                if !report.workCompleted.isEmpty {
                    Text("Work Completed:")
                        .font(.caption.weight(.semibold))
                    Text(report.workCompleted)
                        .font(.caption)
                }
                if !report.notes.isEmpty {
                    Text("Notes:")
                        .font(.caption.weight(.semibold))
                    Text(report.notes)
                        .font(.caption)
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Daily Report")
        .navigationBarTitleDisplayMode(.inline)
    }
}
