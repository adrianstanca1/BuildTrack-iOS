import SwiftUI
import SwiftData

struct DailyReportsListView: View {
    @Query(sort: \DailyReport.reportDate, order: .reverse) private var reports: [DailyReport]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddReport = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(reports) { report in
                    NavigationLink {
                        DailyReportDetailView(report: report)
                    } label: {
                        DailyReportRow(report: report)
                    }
                }
                .onDelete(perform: deleteReport)
            }
            .listStyle(.plain)
            .navigationTitle("Daily Reports")
            .toolbar {
                Button { showAddReport = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddReport) {
                DailyReportFormView()
            }
            .overlay {
                if reports.isEmpty {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "No Daily Reports",
                        message: "Create daily site reports"
                    )
                }
            }
        }
    }

    private func deleteReport(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(reports[index])
        }
    }
}

struct DailyReportRow: View {
    let report: DailyReport

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(report.reportDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                Spacer()
                StatusBadge(status: report.status)
            }
            HStack {
                Label("\(report.workersOnSite) workers", systemImage: "person.2")
                Text("\u{00B7}")
                Text(report.weather.isEmpty ? "No weather" : report.weather)
                Text("\u{00B7}")
                Text("\(Int(report.temperature))\u{00B0}C")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if !report.workCompleted.isEmpty {
                Text(report.workCompleted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DailyReportsListView()
        .modelContainer(SwiftDataStack.previewContainer())
}
